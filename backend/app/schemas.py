# backend/app/schemas.py
from pydantic import BaseModel, Field, validator
from typing import List, Optional
from datetime import datetime
from enum import Enum


# === 基本スキーマ ===

class UniversityType(str, Enum):
    """大学種別"""
    NATIONAL = "national"
    PUBLIC = "public"
    PRIVATE = "private"


class Region(str, Enum):
    """地域"""
    HOKKAIDO = "北海道"
    TOHOKU = "東北"
    KANTO = "関東"
    CHUBU = "中部"
    HOKURIKU = "北陸"
    TOKAI = "東海"
    KANSAI = "関西"
    CHUGOKU = "中国"
    SHIKOKU = "四国"
    KYUSHU = "九州"


# === レスポンススキーマ ===

class UniversityBase(BaseModel):
    """大学基本情報"""
    name: str
    type: UniversityType
    prefecture: str
    region: Region


class UniversityCreate(UniversityBase):
    """大学作成用"""
    pass


class University(UniversityBase):
    """大学情報（完全版）"""
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True


class ResearchLabBase(BaseModel):
    """研究室基本情報"""
    name: str
    professor_name: Optional[str] = None
    department: Optional[str] = None
    research_theme: str
    research_content: str
    research_field: str
    speciality: Optional[str] = None
    keywords: Optional[str] = None
    lab_url: Optional[str] = None


class ResearchLabCreate(ResearchLabBase):
    """研究室作成用"""
    university_id: int


class ResearchLab(ResearchLabBase):
    """研究室情報（完全版）"""
    id: int
    university_id: int
    university: University
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class ResearchLabSearchResult(BaseModel):
    """検索結果用研究室情報"""
    id: int
    name: str
    professor_name: Optional[str]
    department: Optional[str]
    research_theme: str
    research_content: str
    research_field: str
    speciality: Optional[str]
    keywords: Optional[str]
    lab_url: Optional[str]
    university_name: str
    prefecture: str
    region: str
    similarity_score: float = Field(..., description="類似度スコア（0-1）")
    
    class Config:
        from_attributes = True


# === 検索関連スキーマ ===

class SearchRequest(BaseModel):
    """検索リクエスト"""
    query: str = Field(..., min_length=1, max_length=500, description="検索クエリ")
    limit: int = Field(20, ge=1, le=100, description="結果件数（最大100件）")
    region_filter: Optional[List[str]] = Field(None, description="地域フィルター")
    field_filter: Optional[List[str]] = Field(None, description="研究分野フィルター")
    min_similarity: float = Field(0.2, ge=0.0, le=1.0, description="最小類似度（0-1）")
    
    @validator('query')
    def validate_query(cls, v):
        """クエリのバリデーション"""
        v = v.strip()
        if not v:
            raise ValueError("検索クエリが空です")
        return v


class SearchResponse(BaseModel):
    """検索レスポンス"""
    query: str
    total_results: int
    search_time_ms: float
    results: List[ResearchLabSearchResult]
    
    class Config:
        from_attributes = True


class SearchSuggestion(BaseModel):
    """検索候補"""
    text: str
    category: str  # 'keyword', 'field', 'university'


# === その他のスキーマ ===

class HealthCheck(BaseModel):
    """ヘルスチェック"""
    status: str
    message: str
    version: str


class StatisticsResponse(BaseModel):
    """統計情報"""
    total_universities: int
    total_labs: int
    labs_by_region: dict
    labs_by_field: dict
    latest_update: datetime


class ErrorResponse(BaseModel):
    """エラーレスポンス"""
    error: str
    message: str
    details: Optional[dict] = None