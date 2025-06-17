"""
型安全な契約定義とインターフェース
研究室スクレイピングシステムの全コンポーネント間の契約を定義
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from enum import Enum
from typing import Any, Dict, List, Optional, Set, Union
from datetime import datetime
from pathlib import Path


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
    MOLECULAR_BIOLOGY = "molecular_biology" # 分子生物学  
    CELL_BIOLOGY = "cell_biology"          # 細胞生物学
    BIOCHEMISTRY = "biochemistry"          # 生化学
    MICROBIOLOGY = "microbiology"          # 微生物学
    GENETICS = "genetics"                  # 遺伝学
    PHARMACOLOGY = "pharmacology"          # 薬理学
    PATHOLOGY = "pathology"               # 病理学
    CANCER_RESEARCH = "cancer_research"    # がん研究
    INFECTIOUS_DISEASE = "infectious_disease"  # 感染症学
    ALLERGY_RESEARCH = "allergy_research"  # アレルギー研究
    AUTOIMMUNE_DISEASE = "autoimmune_disease"  # 自己免疫疾患


class AdmissionType(str, Enum):
    """入試種別（新規追加）"""
    GENERAL = "general"                    # 一般選抜
    SCHOOL_RECOMMENDATION = "school_recommendation"  # 学校推薦型
    COMPREHENSIVE = "comprehensive"        # 総合型選抜
    AO = "ao"                             # AO入試  
    SPECIAL = "special"                   # 特別選抜


class ScrapingStatus(str, Enum):
    """スクレイピング状態"""
    PENDING = "pending"        # 待機中
    PROCESSING = "processing"  # 処理中
    SUCCESS = "success"        # 成功
    FAILED = "failed"          # 失敗
    RETRY = "retry"           # 再試行中


# ==================== データクラス定義 ====================

@dataclass(frozen=True)
class UniversityInfo:
    """大学基本情報"""
    id: int
    name: str
    type: UniversityType
    prefecture: str
    region: str
    established_year: Optional[int] = None
    website_url: Optional[str] = None
    logo_url: Optional[str] = None
    
    def __post_init__(self) -> None:
        if not self.name.strip():
            raise ValueError("大学名は必須です")


@dataclass(frozen=True)  
class ResearchLabData:
    """研究室データ（中核ドメインオブジェクト）"""
    name: str
    professor_name: str  
    department: str
    faculty: FacultyType
    research_content: str
    research_theme: str
    research_field: ResearchField
    university_id: int
    
    # オプショナル情報
    speciality: Optional[str] = None
    keywords: Optional[str] = None  
    lab_url: Optional[str] = None
    contact_email: Optional[str] = None
    phone_number: Optional[str] = None
    immune_relevance_score: Optional[float] = None
    last_updated: Optional[datetime] = None
    
    # 新規追加: 農学・獣医学系情報
    animal_research: bool = False
    veterinary_focus: bool = False
    
    def __post_init__(self) -> None:
        if not all([self.name.strip(), self.professor_name.strip(), 
                   self.research_content.strip()]):
            raise ValueError("必須フィールドが不足しています")
        
        if self.immune_relevance_score is not None:
            if not 0.0 <= self.immune_relevance_score <= 1.0:
                raise ValueError("免疫関連度スコアは0.0-1.0の範囲である必要があります")


@dataclass(frozen=True)
class AdmissionInfo:
    """総合型選抜情報（新規追加）"""
    university_id: int
    faculty: FacultyType
    admission_type: AdmissionType
    name: str
    description: str
    
    # 選抜詳細
    application_period: Optional[str] = None
    exam_date: Optional[str] = None
    requirements: Optional[str] = None
    selection_method: Optional[str] = None
    capacity: Optional[int] = None
    
    # URLs
    details_url: Optional[str] = None
    application_guide_url: Optional[str] = None
    
    last_updated: Optional[datetime] = None


@dataclass(frozen=True)
class ScrapingResult:
    """スクレイピング結果"""
    university_id: int
    status: ScrapingStatus
    labs_collected: List[ResearchLabData]
    admission_info: List[AdmissionInfo]
    errors: List[str]
    processing_time: float
    timestamp: datetime
    
    @property
    def success_rate(self) -> float:
        """成功率計算"""
        total = len(self.labs_collected) + len(self.errors)
        return len(self.labs_collected) / total if total > 0 else 0.0


# ==================== スクレイパーインターフェース ====================

class UniversityScraperInterface(ABC):
    """大学スクレイパーの契約インターフェース"""
    
    @abstractmethod
    async def scrape_research_labs(self) -> List[ResearchLabData]:
        """研究室データを収集"""
        pass
    
    @abstractmethod
    async def scrape_admission_info(self) -> List[AdmissionInfo]:
        """総合型選抜情報を収集（新規追加）"""
        pass
    
    @abstractmethod
    async def validate_urls(self, urls: List[str]) -> List[str]:
        """URL妥当性チェック"""
        pass
    
    @property
    @abstractmethod
    def university_id(self) -> int:
        """対象大学ID"""
        pass
    
    @property
    @abstractmethod  
    def supported_faculties(self) -> Set[FacultyType]:
        """対応学部種別"""
        pass


class DataRepositoryInterface(ABC):
    """データリポジトリの契約インターフェース"""
    
    @abstractmethod
    async def save_research_lab(self, lab: ResearchLabData) -> int:
        """研究室データ保存"""
        pass
    
    @abstractmethod
    async def save_admission_info(self, admission: AdmissionInfo) -> int:
        """入試情報保存（新規追加）"""
        pass
    
    @abstractmethod
    async def get_research_labs_by_university(self, university_id: int) -> List[ResearchLabData]:
        """大学別研究室取得"""
        pass
    
    @abstractmethod
    async def search_labs_by_keywords(self, keywords: List[str]) -> List[ResearchLabData]:
        """キーワード検索"""
        pass
    
    @abstractmethod
    async def update_immune_scores(self, lab_id: int, score: float) -> None:
        """免疫関連度スコア更新"""
        pass


class KeywordAnalyzerInterface(ABC):
    """キーワード分析器の契約インターフェース"""
    
    @abstractmethod
    async def analyze_immune_relevance(self, research_content: str) -> float:
        """免疫関連度解析"""
        pass
    
    @abstractmethod
    async def extract_keywords(self, text: str) -> List[str]:
        """キーワード抽出"""
        pass
    
    @abstractmethod
    async def categorize_research_field(self, research_content: str) -> ResearchField:
        """研究分野分類"""
        pass


class RateLimiterInterface(ABC):
    """レート制限器の契約インターフェース"""
    
    @abstractmethod
    async def acquire(self, resource_id: str) -> None:
        """リソース取得（レート制限適用）"""
        pass
    
    @abstractmethod
    async def release(self, resource_id: str) -> None:
        """リソース解放"""
        pass
    
    @abstractmethod
    def get_current_rate(self, resource_id: str) -> float:
        """現在の実行レート取得"""
        pass


class HTMLParserInterface(ABC):
    """HTML解析器の契約インターフェース"""
    
    @abstractmethod
    async def parse_research_lab_info(self, html: str, base_url: str) -> Optional[ResearchLabData]:
        """研究室情報解析"""
        pass
    
    @abstractmethod  
    async def parse_admission_info(self, html: str, base_url: str) -> List[AdmissionInfo]:
        """入試情報解析（新規追加）"""
        pass
    
    @abstractmethod
    async def extract_contact_info(self, html: str) -> Dict[str, str]:
        """連絡先情報抽出"""
        pass
    
    @abstractmethod
    async def discover_related_urls(self, html: str, base_url: str) -> List[str]:
        """関連URL発見"""
        pass


# ==================== 設定インターフェース ====================

class ConfigurationInterface(ABC):
    """設定管理の契約インターフェース"""
    
    @abstractmethod
    def get_university_config(self, university_id: int) -> Dict[str, Any]:
        """大学別設定取得"""
        pass
    
    @abstractmethod
    def get_scraping_config(self) -> Dict[str, Any]:
        """スクレイピング設定取得"""
        pass
    
    @abstractmethod
    def get_rate_limit_config(self) -> Dict[str, Any]:
        """レート制限設定取得"""
        pass
    
    @abstractmethod
    def get_keyword_config(self, research_field: ResearchField) -> Dict[str, Any]:
        """キーワード設定取得"""
        pass


# ==================== オーケストレーションインターフェース ====================

class ScraperOrchestratorInterface(ABC):
    """スクレイピングオーケストレーターの契約インターフェース"""
    
    @abstractmethod
    async def execute_scraping_pipeline(
        self, 
        university_ids: List[int],
        faculties: Optional[Set[FacultyType]] = None
    ) -> List[ScrapingResult]:
        """スクレイピングパイプライン実行"""
        pass
    
    @abstractmethod
    async def monitor_progress(self) -> Dict[str, Any]:
        """進捗監視"""
        pass
    
    @abstractmethod
    async def handle_failures(self, failed_results: List[ScrapingResult]) -> None:
        """失敗処理"""
        pass


# ==================== ユーティリティ型定義 ====================

# URL関連
URLString = str
HTMLContent = str  

# 設定関連
ConfigDict = Dict[str, Any]
KeywordList = List[str]

# スクレイピング関連  
ScrapingResults = List[ScrapingResult]
ErrorList = List[str]