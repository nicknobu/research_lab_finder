# backend/app/core/semantic_search.py
import openai
import numpy as np
from typing import List, Dict, Optional, Tuple
import logging
import time
from sqlalchemy.orm import Session
from sqlalchemy import text

from app.config import settings
from app.models import ResearchLab, University
from app.schemas import ResearchLabSearchResult

logger = logging.getLogger(__name__)

# OpenAI クライアント初期化
openai.api_key = settings.OPENAI_API_KEY


class SemanticSearchEngine:
    """セマンティック検索エンジン"""
    
    def __init__(self):
        self.model = settings.OPENAI_MODEL
        self.dimension = settings.EMBEDDING_DIMENSION
    
    async def get_embedding(self, text: str) -> List[float]:
        """テキストの埋め込みベクトルを取得"""
        try:
            # テキストの前処理
            text = text.strip().replace('\n', ' ')
            if not text:
                raise ValueError("Empty text provided")
            
            # OpenAI API呼び出し
            response = openai.Embedding.create(
                model=self.model,
                input=text
            )
            
            embedding = response['data'][0]['embedding']
            logger.debug(f"Generated embedding for text: {text[:50]}...")
            
            return embedding
            
        except Exception as e:
            logger.error(f"Failed to generate embedding: {e}")
            raise
    
    async def search_labs(
        self,
        db: Session,
        query: str,
        limit: int = 20,
        region_filter: Optional[List[str]] = None,
        field_filter: Optional[List[str]] = None,
        min_similarity: float = 0.5
    ) -> Tuple[List[ResearchLabSearchResult], float]:
        """研究室のセマンティック検索"""
        start_time = time.time()
        
        try:
            # クエリの埋め込みベクトルを生成
            query_embedding = await self.get_embedding(query)
            
            # ベクトル検索SQLの構築
            sql_query = """
                SELECT 
                    rl.id,
                    rl.name,
                    rl.professor_name,
                    rl.department,
                    rl.research_theme,
                    rl.research_content,
                    rl.research_field,
                    rl.speciality,
                    rl.keywords,
                    rl.lab_url,
                    u.name as university_name,
                    u.prefecture,
                    u.region,
                    1 - (rl.embedding <=> :query_embedding) as similarity_score
                FROM research_labs rl
                JOIN universities u ON rl.university_id = u.id
                WHERE rl.embedding IS NOT NULL
            """
            
            # フィルター条件の追加
            params = {"query_embedding": str(query_embedding)}
            
            if region_filter:
                sql_query += " AND u.region = ANY(:region_filter)"
                params["region_filter"] = region_filter
            
            if field_filter:
                sql_query += " AND rl.research_field = ANY(:field_filter)"
                params["field_filter"] = field_filter
            
            # 類似度の閾値
            sql_query += " AND (1 - (rl.embedding <=> :query_embedding)) >= :min_similarity"
            params["min_similarity"] = min_similarity
            
            # 類似度順でソート・制限
            sql_query += """
                ORDER BY rl.embedding <=> :query_embedding
                LIMIT :limit
            """
            params["limit"] = limit
            
            # クエリ実行
            result = db.execute(text(sql_query), params)
            rows = result.fetchall()
            
            # 結果をPydanticモデルに変換
            search_results = []
            for row in rows:
                lab_result = ResearchLabSearchResult(
                    id=row.id,
                    name=row.name,
                    professor_name=row.professor_name,
                    department=row.department,
                    research_theme=row.research_theme,
                    research_content=row.research_content,
                    research_field=row.research_field,
                    speciality=row.speciality,
                    keywords=row.keywords,
                    lab_url=row.lab_url,
                    university_name=row.university_name,
                    prefecture=row.prefecture,
                    region=row.region,
                    similarity_score=float(row.similarity_score)
                )
                search_results.append(lab_result)
            
            search_time = (time.time() - start_time) * 1000  # ミリ秒
            
            logger.info(f"Search completed: {len(search_results)} results in {search_time:.2f}ms")
            
            return search_results, search_time
            
        except Exception as e:
            logger.error(f"Search failed: {e}")
            raise
    
    async def generate_research_content_embedding(self, lab: ResearchLab) -> List[float]:
        """研究室の内容から埋め込みベクトルを生成"""
        # 研究室の情報を結合してテキストを作成
        content_parts = [
            lab.name,
            lab.research_theme,
            lab.research_content,
            lab.research_field,
            lab.speciality or "",
            lab.keywords or ""
        ]
        
        # None値を除去して結合
        combined_text = " ".join([part for part in content_parts if part])
        
        return await self.get_embedding(combined_text)
    
    async def update_lab_embedding(self, db: Session, lab_id: int):
        """研究室の埋め込みベクトルを更新"""
        lab = db.query(ResearchLab).filter(ResearchLab.id == lab_id).first()
        if not lab:
            raise ValueError(f"Lab with id {lab_id} not found")
        
        # 埋め込みベクトルを生成
        embedding = await self.generate_research_content_embedding(lab)
        
        # データベースを更新
        lab.embedding = embedding
        db.commit()
        
        logger.info(f"Updated embedding for lab: {lab.name}")
    
    async def batch_update_embeddings(self, db: Session, batch_size: int = 10):
        """全研究室の埋め込みベクトルを一括更新"""
        labs = db.query(ResearchLab).filter(ResearchLab.embedding.is_(None)).all()
        
        logger.info(f"Updating embeddings for {len(labs)} labs...")
        
        for i in range(0, len(labs), batch_size):
            batch = labs[i:i + batch_size]
            
            for lab in batch:
                try:
                    embedding = await self.generate_research_content_embedding(lab)
                    lab.embedding = embedding
                    logger.info(f"Generated embedding for: {lab.name}")
                except Exception as e:
                    logger.error(f"Failed to generate embedding for {lab.name}: {e}")
            
            # バッチごとにコミット
            db.commit()
            
            # API制限対策（少し待機）
            if i + batch_size < len(labs):
                time.sleep(1)
        
        logger.info("Batch embedding update completed")


# セマンティック検索エンジンのインスタンス
search_engine = SemanticSearchEngine()