"""
型安全な契約定義とインターフェース
研究室スクレイピングシステムの全コンポーネント間の契約を定義
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from enum import Enum
from typing import Any, Dict, List, Optional, Protocol
from datetime import datetime


# ==================== エンタープライズ列挙型 ====================

class UniversityType(str, Enum):
    """大学種別"""
    NATIONAL = "national"          # 国立大学
    PUBLIC = "public"              # 公立大学  
    PRIVATE = "private"            # 私立大学


class FacultyType(str, Enum):
    """学部種別"""
    MEDICINE = "medicine"          # 医学部
    SCIENCE = "science"            # 理学部
    ENGINEERING = "engineering"    # 工学部
    PHARMACY = "pharmacy"          # 薬学部
    AGRICULTURE = "agriculture"    # 農学部（新規追加）
    VETERINARY = "veterinary"      # 獣医学部（新規追加）
    DENTISTRY = "dentistry"        # 歯学部
    GRADUATE_SCHOOL = "graduate_school"  # 大学院


class ResearchField(str, Enum):
    """研究分野"""
    IMMUNOLOGY = "immunology"              # 免疫学
    CANCER_IMMUNOLOGY = "cancer_immunology"  # がん免疫学
    ALLERGY_IMMUNOLOGY = "allergy_immunology"  # アレルギー免疫学
    INFECTION_IMMUNOLOGY = "infection_immunology"  # 感染免疫学
    AUTOIMMUNE_DISEASE = "autoimmune_disease"  # 自己免疫疾患
    ANIMAL_IMMUNOLOGY = "animal_immunology"    # 動物免疫学（新規）
    FOOD_IMMUNOLOGY = "food_immunology"        # 食品免疫学（新規）
    PLANT_IMMUNOLOGY = "plant_immunology"      # 植物免疫学（新規）


class AdmissionType(str, Enum):
    """入試種別（新規追加）"""
    GENERAL = "general"                    # 一般選抜
    SCHOOL_RECOMMENDATION = "school_recommendation"  # 学校推薦型
    COMPREHENSIVE = "comprehensive"        # 総合型選抜
    AO = "ao"                             # AO入試  


# ==================== データクラス ====================

@dataclass
class ResearchLabData:
    """研究室データの標準形式"""
    name: str
    professor_name: str
    department: str
    faculty: str
    research_content: str
    university_id: int
    research_field: str = "immunology"
    lab_type: str = "medical"
    animal_species: Optional[str] = None      # 動物種（農学・獣医学用）
    plant_species: Optional[str] = None       # 植物種（農学用）
    research_techniques: Optional[str] = None
    immune_relevance_score: Optional[float] = None
    keywords: Optional[str] = None
    lab_url: Optional[str] = None
    contact_email: Optional[str] = None
    phone: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None


@dataclass  
class AdmissionData:
    """総合型選抜データの標準形式（新機能）"""
    university_id: int
    faculty: str
    department: Optional[str]
    is_available: bool
    quota: str  # "10名", "若干名", "-"
    info_url: Optional[str] = None
    application_period: Optional[str] = None
    selection_method: Optional[str] = None
    last_updated: datetime = None


@dataclass
class UniversityInfo:
    """大学情報"""
    id: int
    name: str
    type: UniversityType
    prefecture: str
    region: str
    website_url: Optional[str] = None


# ==================== インターフェース ====================

class UniversityScraperInterface(ABC):
    """大学スクレイパーの契約"""
    
    @abstractmethod
    async def scrape_research_labs(self) -> List[ResearchLabData]:
        """研究室データの取得"""
        pass
    
    @abstractmethod
    async def scrape_admission_info(self) -> List[AdmissionData]:
        """総合型選抜情報の取得"""
        pass
    
    @abstractmethod
    def validate_data(self, data: ResearchLabData) -> bool:
        """データバリデーション"""
        pass


class ContentParserInterface(Protocol):
    """コンテンツパーサーの契約"""
    
    def parse_research_content(self, html: str) -> Dict[str, str]:
        """研究内容の解析"""
        ...
    
    def extract_keywords(self, content: str) -> List[str]:
        """キーワード抽出"""
        ...
    
    def extract_contact_info(self, html: str) -> Dict[str, str]:
        """連絡先情報の抽出"""
        ...


class DataRepositoryInterface(Protocol):
    """データリポジトリの契約"""
    
    async def save_research_lab(self, lab_data: ResearchLabData) -> int:
        """研究室データ保存"""
        ...
    
    async def save_admission_info(self, admission_data: AdmissionData) -> int:
        """入試情報保存"""
        ...
    
    async def get_university_by_name(self, name: str) -> Optional[UniversityInfo]:
        """大学情報取得"""
        ...


class RateLimiterInterface(Protocol):
    """レート制限の契約"""
    
    async def acquire(self) -> None:
        """リクエスト許可を取得"""
        ...
    
    def get_delay(self) -> float:
        """次のリクエストまでの待機時間"""
        ...


# ==================== 例外クラス ====================

class ScrapingError(Exception):
    """スクレイピング関連の例外"""
    pass


class DataValidationError(Exception):
    """データバリデーション例外"""
    pass


class RateLimitExceededError(Exception):
    """レート制限超過例外"""
    pass
