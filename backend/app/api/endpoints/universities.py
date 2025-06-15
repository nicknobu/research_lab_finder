# backend/app/api/endpoints/universities.py
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional, Dict, Any
import logging

from app.database import get_db
from app.schemas import University, StatisticsResponse
from app.models import University as UniversityModel, ResearchLab as ResearchLabModel

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/", response_model=List[University])
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


@router.get("/regions")
async def get_regions(db: Session = Depends(get_db)):
    """
    地域一覧取得API
    
    データベースに登録されている地域の一覧を取得します。
    """
    try:
        regions = db.query(UniversityModel.region)\
            .distinct()\
            .order_by(UniversityModel.region)\
            .all()
        
        return [region[0] for region in regions]
        
    except Exception as e:
        logger.error(f"Failed to get regions: {e}")
        raise HTTPException(
            status_code=500,
            detail="地域一覧の取得中にエラーが発生しました"
        )


@router.get("/research-fields")
async def get_research_fields(db: Session = Depends(get_db)):
    """
    研究分野一覧取得API
    
    データベースに登録されている研究分野の一覧を取得します。
    """
    try:
        fields = db.query(ResearchLabModel.research_field)\
            .distinct()\
            .order_by(ResearchLabModel.research_field)\
            .all()
        
        return [field[0] for field in fields]
        
    except Exception as e:
        logger.error(f"Failed to get research fields: {e}")
        raise HTTPException(
            status_code=500,
            detail="研究分野一覧の取得中にエラーが発生しました"
        )


@router.get("/statistics", response_model=StatisticsResponse)
async def get_statistics(db: Session = Depends(get_db)):
    """
    統計情報取得API
    
    大学・研究室の統計情報を取得します。
    """
    try:
        # 基本統計
        total_universities = db.query(func.count(UniversityModel.id)).scalar()
        total_labs = db.query(func.count(ResearchLabModel.id)).scalar()
        
        # 地域別研究室数
        labs_by_region = dict(
            db.query(
                UniversityModel.region,
                func.count(ResearchLabModel.id)
            )\
            .join(ResearchLabModel)\
            .group_by(UniversityModel.region)\
            .all()
        )
        
        # 研究分野別研究室数
        labs_by_field = dict(
            db.query(
                ResearchLabModel.research_field,
                func.count(ResearchLabModel.id)
            )\
            .group_by(ResearchLabModel.research_field)\
            .all()
        )
        
        # 最新更新日時
        latest_update = db.query(func.max(ResearchLabModel.updated_at)).scalar()
        
        return StatisticsResponse(
            total_universities=total_universities or 0,
            total_labs=total_labs or 0,
            labs_by_region=labs_by_region,
            labs_by_field=labs_by_field,
            latest_update=latest_update
        )
        
    except Exception as e:
        logger.error(f"Failed to get statistics: {e}")
        raise HTTPException(
            status_code=500,
            detail="統計情報の取得中にエラーが発生しました"
        )


@router.get("/university-types")
async def get_university_types():
    """
    大学種別一覧取得API
    
    大学種別の一覧を取得します。
    """
    return [
        {"value": "national", "label": "国立大学"},
        {"value": "public", "label": "公立大学"},
        {"value": "private", "label": "私立大学"}
    ]


@router.get("/{university_id}/stats")
async def get_university_stats(
    university_id: int,
    db: Session = Depends(get_db)
):
    """
    大学別統計情報取得API
    
    指定された大学の統計情報を取得します。
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
        
        # 統計情報取得
        total_labs = db.query(func.count(ResearchLabModel.id))\
            .filter(ResearchLabModel.university_id == university_id)\
            .scalar()
        
        labs_by_field = dict(
            db.query(
                ResearchLabModel.research_field,
                func.count(ResearchLabModel.id)
            )\
            .filter(ResearchLabModel.university_id == university_id)\
            .group_by(ResearchLabModel.research_field)\
            .all()
        )
        
        return {
            "university": university,
            "total_labs": total_labs or 0,
            "labs_by_field": labs_by_field
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get university stats: {e}")
        raise HTTPException(
            status_code=500,
            detail="大学統計情報の取得中にエラーが発生しました"
        )