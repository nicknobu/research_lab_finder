# backend/app/api/endpoints/labs.py
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
import logging

from app.database import get_db
from app.schemas import ResearchLab, University, StatisticsResponse
from app.models import ResearchLab as ResearchLabModel, University as UniversityModel

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/{lab_id}", response_model=ResearchLab)
async def get_lab_detail(
    lab_id: int,
    db: Session = Depends(get_db)
):
    """
    研究室詳細情報取得API
    
    指定されたIDの研究室の詳細情報を取得します。
    """
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
        logger.error(f"Failed to get lab detail: {e}")
        raise HTTPException(
            status_code=500,
            detail="研究室情報の取得中にエラーが発生しました"
        )


@router.get("/", response_model=List[ResearchLab])
async def get_labs(
    skip: int = Query(0, ge=0, description="スキップする件数"),
    limit: int = Query(20, ge=1, le=100, description="取得件数"),
    research_field: Optional[str] = Query(None, description="研究分野フィルター"),
    region: Optional[str] = Query(None, description="地域フィルター"),
    university_name: Optional[str] = Query(None, description="大学名フィルター"),
    db: Session = Depends(get_db)
):
    """
    研究室一覧取得API
    
    条件を指定して研究室の一覧を取得します。
    """
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
        logger.error(f"Failed to get labs: {e}")
        raise HTTPException(
            status_code=500,
            detail="研究室一覧の取得中にエラーが発生しました"
        )


@router.get("/similar/{lab_id}", response_model=List[ResearchLab])
async def get_similar_labs(
    lab_id: int,
    limit: int = Query(5, ge=1, le=20, description="類似研究室数"),
    db: Session = Depends(get_db)
):
    """
    類似研究室取得API
    
    指定された研究室と類似する研究室を取得します。
    """
    try:
        from sqlalchemy import text
        
        # 対象研究室の存在確認
        target_lab = db.query(ResearchLabModel)\
            .filter(ResearchLabModel.id == lab_id)\
            .first()
        
        if not target_lab:
            raise HTTPException(
                status_code=404,
                detail=f"研究室ID {lab_id} が見つかりません"
            )
        
        if not target_lab.embedding:
            raise HTTPException(
                status_code=400,
                detail="対象研究室の埋め込みベクトルが生成されていません"
            )
        
        # 類似研究室を検索
        sql_query = """
            SELECT *
            FROM research_labs rl
            WHERE rl.id != :target_id 
            AND rl.embedding IS NOT NULL
            ORDER BY rl.embedding <=> (
                SELECT embedding 
                FROM research_labs 
                WHERE id = :target_id
            )
            LIMIT :limit
        """
        
        result = db.execute(text(sql_query), {
            "target_id": lab_id,
            "limit": limit
        })
        
        similar_lab_ids = [row.id for row in result.fetchall()]
        
        # 研究室詳細情報を取得
        similar_labs = db.query(ResearchLabModel)\
            .filter(ResearchLabModel.id.in_(similar_lab_ids))\
            .all()
        
        return similar_labs
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get similar labs: {e}")
        raise HTTPException(
            status_code=500,
            detail="類似研究室の取得中にエラーが発生しました"
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
    """
    大学一覧取得API
    
    条件を指定して大学の一覧を取得します。
    """
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
        logger.error(f"Failed to get universities: {e}")
        raise HTTPException(
            status_code=500,
            detail="大学一覧の取得中にエラーが発生しました"
        )


@router.get("/universities/{university_id}", response_model=University)
async def get_university_detail(
    university_id: int,
    db: Session = Depends(get_db)
):
    """
    大学詳細情報取得API
    
    指定されたIDの大学の詳細情報を取得します。
    """
    try:
        university = db.query(UniversityModel)\
            .filter(UniversityModel.id == university_id)\
            .first()
        
        if not university:
            raise HTTPException(
                status_code=404,
                detail=f"大学ID {university_id} が見つかりません"
            )
        
        return university
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get university detail: {e}")
        raise HTTPException(
            status_code=500,
            detail="大学情報の取得中にエラーが発生しました"
        )


@router.get("/universities/{university_id}/labs", response_model=List[ResearchLab])
async def get_university_labs(
    university_id: int,
    skip: int = Query(0, ge=0, description="スキップする件数"),
    limit: int = Query(20, ge=1, le=100, description="取得件数"),
    db: Session = Depends(get_db)
):
    """
    大学所属研究室取得API
    
    指定された大学に所属する研究室の一覧を取得します。
    """
    try:
        # 大学の存在確認
        university = db.query(UniversityModel)\
            .filter(UniversityModel.id == university_id)\
            .first()
        
        if not university:
            raise HTTPException(
                status_code=404,
                detail=f"大学ID {university_id} が見つかりません"
            )
        
        # 研究室一覧取得
        labs = db.query(ResearchLabModel)\
            .filter(ResearchLabModel.university_id == university_id)\
            .offset(skip)\
            .limit(limit)\
            .all()
        
        return labs
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get university labs: {e}")
        raise HTTPException(
            status_code=500,
            detail="大学所属研究室の取得中にエラーが発生しました"
        )