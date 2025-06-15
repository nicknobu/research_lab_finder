# backend/app/api/endpoints/labs.py

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List, Optional
import logging

from app.database import get_db
from app.models import ResearchLab as ResearchLabModel, University as UniversityModel
from app.schemas import ResearchLab, University, ResearchLabSearchResult

router = APIRouter()
logger = logging.getLogger(__name__)


@router.get("/similar/{lab_id}", response_model=List[ResearchLabSearchResult])
async def get_similar_labs(
    lab_id: int,
    limit: int = Query(5, ge=1, le=20, description="類似研究室数"),
    db: Session = Depends(get_db)
):
    """
    類似研究室取得API（大学情報付き完全版）
    
    指定された研究室と類似する研究室を取得します。
    """
    try:
        # 対象研究室の存在確認
        target_lab = db.query(ResearchLabModel)\
            .filter(ResearchLabModel.id == lab_id)\
            .first()
        
        if not target_lab:
            raise HTTPException(
                status_code=404,
                detail=f"研究室ID {lab_id} が見つかりません"
            )
        
        # 埋め込みベクトルの存在確認
        if target_lab.embedding is None:
            logger.warning(f"研究室ID {lab_id} の埋め込みベクトルが生成されていません")
            raise HTTPException(
                status_code=400,
                detail="対象研究室の埋め込みベクトルが生成されていません"
            )
        
        # 類似研究室を検索（大学情報を含む完全版）
        sql_query = text("""
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
                1 - (rl.embedding <=> (
                    SELECT embedding 
                    FROM research_labs 
                    WHERE id = :target_id
                )) as similarity_score
            FROM research_labs rl
            JOIN universities u ON rl.university_id = u.id
            WHERE rl.id != :target_id 
            AND rl.embedding IS NOT NULL
            ORDER BY rl.embedding <=> (
                SELECT embedding 
                FROM research_labs 
                WHERE id = :target_id
            )
            LIMIT :limit
        """)
        
        result = db.execute(sql_query, {
            "target_id": lab_id,
            "limit": limit
        })
        
        similar_labs_data = result.fetchall()
        
        if not similar_labs_data:
            logger.info(f"研究室ID {lab_id} の類似研究室が見つかりませんでした")
            return []
        
        # ResearchLabSearchResult形式に変換
        similar_labs = []
        for row in similar_labs_data:
            lab_result = ResearchLabSearchResult(
                id=row.id,
                name=row.name,
                professor_name=row.professor_name or '',
                department=row.department or '',
                research_theme=row.research_theme,
                research_content=row.research_content,
                research_field=row.research_field,
                speciality=row.speciality or '',
                keywords=row.keywords or '',
                lab_url=row.lab_url,
                university_name=row.university_name,  # 大学名を確実に設定
                prefecture=row.prefecture,            # 都道府県を確実に設定
                region=row.region,                   # 地域を確実に設定
                similarity_score=float(row.similarity_score)
            )
            similar_labs.append(lab_result)
        
        logger.info(f"研究室ID {lab_id} に類似する {len(similar_labs)} 件の研究室を取得しました")
        return similar_labs
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"類似研究室取得エラー: {e}")
        raise HTTPException(
            status_code=500,
            detail="類似研究室の取得中にエラーが発生しました"
        )


@router.get("/{lab_id}", response_model=ResearchLab)
async def get_lab_detail(
    lab_id: int,
    db: Session = Depends(get_db)
):
    """研究室詳細取得API"""
    try:
        lab = db.query(ResearchLabModel)\
            .filter(ResearchLabModel.id == lab_id)\
            .first()
        
        if not lab:
            raise HTTPException(
                status_code=404,
                detail=f"研究室ID {lab_id} が見つかりません"
            )
        
        return lab
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"研究室詳細取得エラー: {e}")
        raise HTTPException(
            status_code=500,
            detail="研究室詳細の取得中にエラーが発生しました"
        )


@router.get("/", response_model=List[ResearchLab])
async def get_labs(
    skip: int = Query(0, ge=0, description="スキップする件数"),
    limit: int = Query(50, ge=1, le=100, description="取得件数"),
    research_field: Optional[str] = Query(None, description="研究分野フィルター"),
    region: Optional[str] = Query(None, description="地域フィルター"),
    university_name: Optional[str] = Query(None, description="大学名フィルター"),
    db: Session = Depends(get_db)
):
    """研究室一覧取得API"""
    try:
        query = db.query(ResearchLabModel)
        
        # フィルター適用
        if research_field:
            query = query.filter(ResearchLabModel.research_field == research_field)
        
        if region:
            query = query.join(UniversityModel)\
                .filter(UniversityModel.region == region)
        
        if university_name:
            query = query.join(UniversityModel)\
                .filter(UniversityModel.name.ilike(f"%{university_name}%"))
        
        # ページネーション
        labs = query.offset(skip).limit(limit).all()
        
        return labs
        
    except Exception as e:
        logger.error(f"研究室一覧取得エラー: {e}")
        raise HTTPException(
            status_code=500,
            detail="研究室一覧の取得中にエラーが発生しました"
        )


# === 大学情報API ===

@router.get("/universities/", response_model=List[University])
async def get_universities(
    skip: int = Query(0, ge=0, description="スキップする件数"),
    limit: int = Query(50, ge=1, le=100, description="取得件数"),
    region: Optional[str] = Query(None, description="地域フィルター"),
    university_type: Optional[str] = Query(None, description="大学種別フィルター"),
    db: Session = Depends(get_db)
):
    """大学一覧取得API"""
    try:
        query = db.query(UniversityModel)
        
        # フィルター適用
        if region:
            query = query.filter(UniversityModel.region == region)
        
        if university_type:
            query = query.filter(UniversityModel.type == university_type)
        
        # ページネーション
        universities = query.offset(skip).limit(limit).all()
        
        return universities
        
    except Exception as e:
        logger.error(f"大学一覧取得エラー: {e}")
        raise HTTPException(
            status_code=500,
            detail="大学一覧の取得中にエラーが発生しました"
        )
