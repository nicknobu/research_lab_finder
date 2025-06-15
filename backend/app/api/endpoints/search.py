# backend/app/api/endpoints/search.py
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
import logging

from app.database import get_db
from app.schemas import SearchRequest, SearchResponse, SearchSuggestion
from app.core.semantic_search import search_engine
from app.models import SearchLog

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/", response_model=SearchResponse)
async def semantic_search(
    search_request: SearchRequest,
    db: Session = Depends(get_db)
):
    """
    セマンティック検索API
    
    中学生の興味・関心から関連する研究室を検索します。
    """
    try:
        # セマンティック検索実行
        results, search_time = await search_engine.search_labs(
            db=db,
            query=search_request.query,
            limit=search_request.limit,
            region_filter=search_request.region_filter,
            field_filter=search_request.field_filter,
            min_similarity=search_request.min_similarity
        )
        
        # 検索ログを記録
        search_log = SearchLog(
            query=search_request.query,
            results_count=len(results),
            search_time_ms=search_time
        )
        db.add(search_log)
        db.commit()
        
        # レスポンスを構築
        response = SearchResponse(
            query=search_request.query,
            total_results=len(results),
            search_time_ms=search_time,
            results=results
        )
        
        logger.info(f"Search completed: '{search_request.query}' -> {len(results)} results")
        
        return response
        
    except Exception as e:
        logger.error(f"Search failed: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"検索処理中にエラーが発生しました: {str(e)}"
        )


@router.get("/suggestions", response_model=List[SearchSuggestion])
async def get_search_suggestions(
    q: str = Query(..., min_length=1, description="検索候補を取得するためのクエリ"),
    limit: int = Query(10, ge=1, le=20, description="候補数"),
    db: Session = Depends(get_db)
):
    """
    検索候補取得API
    
    入力途中の文字列から検索候補を提案します。
    """
    try:
        suggestions = []
        
        # 研究分野からの候補
        field_suggestions = [
            "免疫学", "生物学", "医学", "薬学", "工学", "情報科学",
            "化学", "物理学", "数学", "心理学", "社会学"
        ]
        
        for field in field_suggestions:
            if q.lower() in field.lower():
                suggestions.append(SearchSuggestion(
                    text=field,
                    category="field"
                ))
        
        # キーワードからの候補
        keyword_suggestions = [
            "がん治療", "感染症", "アレルギー", "ワクチン", "再生医療",
            "人工知能", "ロボット", "宇宙", "環境問題", "エネルギー",
            "食品安全", "新薬開発", "遺伝子治療"
        ]
        
        for keyword in keyword_suggestions:
            if q.lower() in keyword.lower():
                suggestions.append(SearchSuggestion(
                    text=keyword,
                    category="keyword"
                ))
        
        # 候補数を制限
        suggestions = suggestions[:limit]
        
        return suggestions
        
    except Exception as e:
        logger.error(f"Failed to get suggestions: {e}")
        raise HTTPException(
            status_code=500,
            detail="検索候補の取得中にエラーが発生しました"
        )


@router.get("/popular", response_model=List[str])
async def get_popular_searches(
    limit: int = Query(10, ge=1, le=50, description="人気検索数"),
    db: Session = Depends(get_db)
):
    """
    人気検索クエリ取得API
    
    よく検索されているクエリを取得します。
    """
    try:
        # 検索ログから人気のクエリを取得
        popular_queries = db.query(SearchLog.query)\
            .filter(SearchLog.results_count > 0)\
            .group_by(SearchLog.query)\
            .order_by(SearchLog.query)\
            .limit(limit)\
            .all()
        
        # デフォルトの人気検索（検索ログが少ない場合）
        default_popular = [
            "がん治療の研究をしたい",
            "人工知能とロボットに興味がある",
            "地球温暖化を解決したい",
            "新しい薬を開発したい",
            "宇宙の研究がしたい",
            "感染症の予防研究",
            "食品の安全性研究",
            "再生医療に興味がある",
            "アレルギーの治療法開発",
            "環境にやさしいエネルギー開発"
        ]
        
        # 検索ログがある場合はそれを、ない場合はデフォルトを返す
        if popular_queries:
            return [query[0] for query in popular_queries]
        else:
            return default_popular[:limit]
            
    except Exception as e:
        logger.error(f"Failed to get popular searches: {e}")
        raise HTTPException(
            status_code=500,
            detail="人気検索の取得中にエラーが発生しました"
        )


@router.get("/stats")
async def get_search_stats(db: Session = Depends(get_db)):
    """
    検索統計情報取得API
    
    検索の統計情報を取得します。
    """
    try:
        from sqlalchemy import func
        from app.models import University, ResearchLab
        
        # 基本統計
        total_searches = db.query(func.count(SearchLog.id)).scalar()
        avg_results = db.query(func.avg(SearchLog.results_count)).scalar()
        avg_search_time = db.query(func.avg(SearchLog.search_time_ms)).scalar()
        
        # データベース統計
        total_universities = db.query(func.count(University.id)).scalar()
        total_labs = db.query(func.count(ResearchLab.id)).scalar()
        
        stats = {
            "search_statistics": {
                "total_searches": total_searches or 0,
                "average_results_per_search": round(avg_results or 0, 2),
                "average_search_time_ms": round(avg_search_time or 0, 2)
            },
            "database_statistics": {
                "total_universities": total_universities or 0,
                "total_research_labs": total_labs or 0
            }
        }
        
        return stats
        
    except Exception as e:
        logger.error(f"Failed to get search stats: {e}")
        raise HTTPException(
            status_code=500,
            detail="統計情報の取得中にエラーが発生しました"
        )