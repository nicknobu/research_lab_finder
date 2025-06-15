# backend/app/utils/data_loader.py
import pandas as pd
import logging
from sqlalchemy.orm import Session
from pathlib import Path
from typing import Dict, List
import asyncio

from app.models import University, ResearchLab
from app.core.semantic_search import search_engine

logger = logging.getLogger(__name__)


class DataLoader:
    """データ読み込みクラス"""
    
    def __init__(self):
        self.data_dir = Path(__file__).parent.parent / "data"
    
    async def load_initial_data(self, db: Session):
        """初期データの読み込み"""
        logger.info("Starting initial data loading...")
        
        try:
            # CSVファイルの読み込み
            csv_file = self.data_dir / "immune_research_labs_50.csv"
            
            if not csv_file.exists():
                # ファイルが存在しない場合はサンプルデータを生成
                logger.warning(f"CSV file not found: {csv_file}")
                logger.info("Generating sample data...")
                await self.generate_sample_data(db)
                return
            
            # CSVデータの読み込み
            df = pd.read_csv(csv_file, encoding='utf-8')
            logger.info(f"Loaded {len(df)} records from CSV")
            
            # データ型の確認・変換
            df = df.fillna('')  # NaN値を空文字列に変換
            
            # 大学データの登録
            await self.load_universities(db, df)
            
            # 研究室データの登録
            await self.load_research_labs(db, df)
            
            # 埋め込みベクトルの生成
            await self.generate_embeddings(db)
            
            logger.info("✅ Initial data loading completed successfully")
            
        except Exception as e:
            logger.error(f"❌ Failed to load initial data: {e}")
            raise
    
    async def load_universities(self, db: Session, df: pd.DataFrame):
        """大学データの読み込み"""
        logger.info("Loading universities...")
        
        # ユニークな大学リストを作成
        university_data = df[['university_name', 'prefecture', 'region']].drop_duplicates()
        
        universities_created = 0
        for _, row in university_data.iterrows():
            # 既存チェック
            existing = db.query(University)\
                .filter(University.name == row['university_name'])\
                .first()
            
            if not existing:
                # 大学種別を推定
                university_type = self.determine_university_type(row['university_name'])
                
                university = University(
                    name=row['university_name'],
                    type=university_type,
                    prefecture=row['prefecture'],
                    region=row['region']
                )
                
                db.add(university)
                universities_created += 1
        
        db.commit()
        logger.info(f"Created {universities_created} universities")
    
    async def load_research_labs(self, db: Session, df: pd.DataFrame):
        """研究室データの読み込み"""
        logger.info("Loading research labs...")
        
        labs_created = 0
        for _, row in df.iterrows():
            # 大学IDを取得
            university = db.query(University)\
                .filter(University.name == row['university_name'])\
                .first()
            
            if not university:
                logger.error(f"University not found: {row['university_name']}")
                continue
            
            # 既存チェック
            existing = db.query(ResearchLab)\
                .filter(
                    ResearchLab.university_id == university.id,
                    ResearchLab.name == row['lab_name']
                )\
                .first()
            
            if not existing:
                research_lab = ResearchLab(
                    university_id=university.id,
                    name=row['lab_name'],
                    professor_name=row.get('professor_name', ''),
                    department=row.get('department', ''),
                    research_theme=row['research_theme'],
                    research_content=row['research_content'],
                    research_field=row.get('research_field', '免疫学'),
                    speciality=row.get('speciality', ''),
                    keywords=row.get('keywords', ''),
                    lab_url=row.get('lab_url', '')
                )
                
                db.add(research_lab)
                labs_created += 1
        
        db.commit()
        logger.info(f"Created {labs_created} research labs")
    
    async def generate_embeddings(self, db: Session):
        """埋め込みベクトルの生成"""
        logger.info("Generating embeddings for research labs...")
        
        # 埋め込みベクトルが未生成の研究室を取得
        labs_without_embeddings = db.query(ResearchLab)\
            .filter(ResearchLab.embedding.is_(None))\
            .all()
        
        if not labs_without_embeddings:
            logger.info("All labs already have embeddings")
            return
        
        logger.info(f"Generating embeddings for {len(labs_without_embeddings)} labs...")
        
        # バッチ処理で埋め込みベクトルを生成
        await search_engine.batch_update_embeddings(db, batch_size=5)
        
        logger.info("✅ Embeddings generation completed")
    
    def determine_university_type(self, university_name: str) -> str:
        """大学名から大学種別を判定"""
        if any(keyword in university_name for keyword in ['国立', '東京大学', '京都大学', '大阪大学', '北海道大学', '東北大学', '名古屋大学', '九州大学']):
            return 'national'
        elif any(keyword in university_name for keyword in ['県立', '市立', '都立', '府立']):
            return 'public'
        else:
            return 'private'
    
    async def generate_sample_data(self, db: Session):
        """サンプルデータの生成"""
        logger.info("Generating sample data...")
        
        # サンプル大学データ
        sample_universities = [
            {"name": "東京大学", "type": "national", "prefecture": "東京都", "region": "関東"},
            {"name": "京都大学", "type": "national", "prefecture": "京都府", "region": "関西"},
            {"name": "大阪大学", "type": "national", "prefecture": "大阪府", "region": "関西"},
            {"name": "横浜市立大学", "type": "public", "prefecture": "神奈川県", "region": "関東"},
            {"name": "東京理科大学", "type": "private", "prefecture": "東京都", "region": "関東"},
        ]
        
        # 大学の作成
        for univ_data in sample_universities:
            existing = db.query(University).filter(University.name == univ_data["name"]).first()
            if not existing:
                university = University(**univ_data)
                db.add(university)
        
        db.commit()
        
        # サンプル研究室データ
        sample_labs = [
            {
                "university_name": "東京大学",
                "name": "免疫制御学教室",
                "professor_name": "田中太郎",
                "department": "医学部",
                "research_theme": "T細胞免疫応答の制御機構",
                "research_content": "T細胞の分化と機能制御、特に制御性T細胞（Treg）の機能解析を通じて、自己免疫疾患やアレルギー疾患の病態解明と治療法開発を目指しています。",
                "research_field": "免疫学",
                "speciality": "T細胞、制御性T細胞、自己免疫疾患",
                "keywords": "T細胞,制御性T細胞,自己免疫疾患,アレルギー,免疫制御",
                "lab_url": "https://example.com/lab1"
            },
            {
                "university_name": "京都大学",
                "name": "感染免疫学分野",
                "professor_name": "佐藤花子",
                "department": "医学部",
                "research_theme": "感染症に対する免疫応答機構",
                "research_content": "ウイルス感染に対する自然免疫および獲得免疫の応答機構を解析し、新しいワクチン開発や抗ウイルス療法の基盤となる研究を行っています。",
                "research_field": "免疫学",
                "speciality": "感染免疫、ウイルス免疫、ワクチン開発",
                "keywords": "感染免疫,ウイルス,ワクチン,抗ウイルス療法,免疫応答",
                "lab_url": "https://example.com/lab2"
            }
        ]
        
        # 研究室の作成
        for lab_data in sample_labs:
            university = db.query(University).filter(University.name == lab_data["university_name"]).first()
            if university:
                existing = db.query(ResearchLab).filter(
                    ResearchLab.university_id == university.id,
                    ResearchLab.name == lab_data["name"]
                ).first()
                
                if not existing:
                    research_lab = ResearchLab(
                        university_id=university.id,
                        name=lab_data["name"],
                        professor_name=lab_data["professor_name"],
                        department=lab_data["department"],
                        research_theme=lab_data["research_theme"],
                        research_content=lab_data["research_content"],
                        research_field=lab_data["research_field"],
                        speciality=lab_data["speciality"],
                        keywords=lab_data["keywords"],
                        lab_url=lab_data["lab_url"]
                    )
                    db.add(research_lab)
        
        db.commit()
        
        # 埋め込みベクトルの生成
        await self.generate_embeddings(db)
        
        logger.info("✅ Sample data generation completed")


# データローダーのインスタンス
data_loader = DataLoader()

# エクスポート用の関数
async def load_initial_data(db: Session):
    """初期データ読み込みのメイン関数"""
    await data_loader.load_initial_data(db)