#!/bin/bash

echo "🏗️ 効率重視プロジェクト構造を実装中..."

# ==================== 1. 新しいディレクトリ構造作成 ====================
echo "📁 ディレクトリ構造を作成中..."

# メインディレクトリ構造
mkdir -p scraper/{config,domain,infrastructure,application,utils,tests}

# 詳細ディレクトリ
mkdir -p scraper/config/keywords
mkdir -p scraper/infrastructure/{database,http,parsers}
mkdir -p scraper/application/{scrapers,pipelines,orchestration}
mkdir -p scraper/tests/{unit,integration,e2e}

echo "✅ ディレクトリ構造作成完了"

# ==================== 2. 型安全な契約定義（interfaces.py） ====================
echo "📝 型安全な契約定義を作成中..."

cat > scraper/config/interfaces.py << 'EOF'
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
EOF

echo "✅ 型安全な契約定義完了"

# ==================== 3. Pydantic設定管理 ====================
echo "⚙️ Pydantic設定管理を作成中..."

cat > scraper/config/settings.py << 'EOF'
"""
Pydantic設定管理
環境変数とアプリケーション設定の一元管理
"""

from pydantic import BaseSettings, Field, validator
from typing import List, Optional
from pathlib import Path


class ScrapingSettings(BaseSettings):
    """スクレイピング設定"""
    
    # レート制限設定
    requests_per_second: float = Field(0.5, description="1秒あたりのリクエスト数")
    concurrent_requests: int = Field(3, description="同時リクエスト数")
    request_timeout: int = Field(30, description="リクエストタイムアウト（秒）")
    retry_attempts: int = Field(3, description="再試行回数")
    retry_delay: float = Field(1.0, description="再試行間隔（秒）")
    
    # データベース設定
    database_url: str = Field("postgresql://postgres:postgres@db:5432/research_lab_finder")
    
    # ログ設定
    log_level: str = Field("INFO", description="ログレベル")
    log_format: str = Field("json", description="ログ形式")
    
    # ファイルパス設定
    config_dir: Path = Field(Path("scraper/config"))
    keywords_dir: Path = Field(Path("scraper/config/keywords"))
    university_configs_file: Path = Field(Path("scraper/config/university_configs.yaml"))
    
    @validator('requests_per_second')
    def validate_rate_limit(cls, v):
        if v <= 0 or v > 10:
            raise ValueError('requests_per_second must be between 0 and 10')
        return v
    
    @validator('concurrent_requests')
    def validate_concurrency(cls, v):
        if v <= 0 or v > 10:
            raise ValueError('concurrent_requests must be between 1 and 10')
        return v
    
    class Config:
        env_prefix = "SCRAPER_"
        env_file = ".env"


class QualitySettings(BaseSettings):
    """データ品質設定"""
    
    min_content_length: int = Field(50, description="研究内容の最小文字数")
    min_immune_relevance_score: float = Field(0.3, description="免疫関連度の最小スコア")
    required_fields: List[str] = Field([
        "name", "professor_name", "research_content", "university_id"
    ], description="必須フィールド")
    
    # 農学系品質設定（新規）
    min_animal_species_count: int = Field(1, description="動物種の最小記載数")
    animal_research_keywords: List[str] = Field([
        "動物", "家畜", "牛", "豚", "鶏", "魚", "獣医"
    ], description="動物研究キーワード")


class UniversityTierSettings(BaseSettings):
    """大学ティア設定"""
    
    tier1_universities: List[str] = Field([
        "東京大学", "京都大学", "大阪大学", "東北大学",
        "東京農工大学", "北海道大学", "帯広畜産大学"
    ], description="Tier1大学（医学・農学強豪）")
    
    tier2_universities: List[str] = Field([
        "名古屋大学", "九州大学", "神戸大学", "筑波大学",
        "千葉大学", "新潟大学", "金沢大学", "岡山大学"
    ], description="Tier2大学（旧帝大・難関国立）")
    
    target_faculties: List[str] = Field([
        "医学部", "理学部", "工学部", "薬学部", 
        "農学部", "獣医学部", "歯学部"
    ], description="対象学部")


# グローバル設定インスタンス
scraping_settings = ScrapingSettings()
quality_settings = QualitySettings()
university_tier_settings = UniversityTierSettings()
EOF

echo "✅ Pydantic設定管理完了"

# ==================== 4. キーワード管理ファイル ====================
echo "🔑 キーワード管理ファイルを作成中..."

# 医学系キーワード
cat > scraper/config/keywords/medical_keywords.yaml << 'EOF'
# 医学系免疫学キーワード
basic_immunology:
  - "免疫"
  - "immunology" 
  - "immunity"
  - "immune system"
  - "自然免疫"
  - "innate immunity"
  - "獲得免疫"
  - "adaptive immunity"

cells_and_molecules:
  - "T細胞"
  - "B細胞"
  - "樹状細胞"
  - "dendritic cell"
  - "マクロファージ"
  - "macrophage"
  - "NK細胞"
  - "natural killer"
  - "抗体"
  - "antibody"
  - "抗原"
  - "antigen"
  - "サイトカイン"
  - "cytokine"

advanced_research:
  - "免疫チェックポイント"
  - "immune checkpoint"
  - "CAR-T細胞"
  - "CAR-T cell therapy"
  - "単クローン抗体"
  - "monoclonal antibody"
  - "オートファジー"
  - "autophagy"

diseases_and_therapy:
  - "がん免疫"
  - "cancer immunology"
  - "免疫療法"
  - "immunotherapy"
  - "アレルギー"
  - "allergy"
  - "自己免疫"
  - "autoimmune"
  - "ワクチン"
  - "vaccine"
  - "感染症"
  - "infectious disease"
EOF

# 農学系キーワード（新規）
cat > scraper/config/keywords/agriculture_keywords.yaml << 'EOF'
# 農学系免疫学キーワード（新規追加）
animal_immunity:
  - "動物免疫"
  - "veterinary immunology"
  - "家畜免疫"
  - "livestock immunity"
  - "魚類免疫"
  - "fish immunology"
  - "水産免疫"
  - "aquatic immunology"
  - "比較免疫学"
  - "comparative immunology"

animal_species:
  - "牛"
  - "cattle"
  - "bovine"
  - "豚"
  - "porcine"
  - "swine"
  - "鶏"
  - "chicken"
  - "poultry"
  - "魚"
  - "fish"
  - "犬"
  - "canine"
  - "猫"
  - "feline"
  - "馬"
  - "equine"
  - "羊"
  - "sheep"
  - "ovine"

plant_immunity:
  - "植物免疫"
  - "plant immunity"
  - "植物病理"
  - "plant pathology"
  - "植物防御"
  - "plant defense"
  - "病害抵抗性"
  - "disease resistance"
  - "植物ワクチン"
  - "plant vaccine"

food_immunity:
  - "食品免疫"
  - "food immunology"
  - "栄養免疫"
  - "nutritional immunology"
  - "機能性食品"
  - "functional food"
  - "プロバイオティクス"
  - "probiotics"
  - "発酵食品"
  - "fermented food"
  - "腸内細菌"
  - "gut microbiota"

veterinary_medicine:
  - "獣医療"
  - "veterinary medicine"
  - "動物ワクチン"
  - "animal vaccine"
  - "人獣共通感染症"
  - "zoonosis"
  - "家畜衛生"
  - "livestock health"
  - "水産防疫"
  - "aquaculture disease prevention"
EOF

# 総合型選抜キーワード（新規）
cat > scraper/config/keywords/admission_keywords.yaml << 'EOF'
# 総合型選抜関連キーワード（新規追加）
selection_types:
  - "総合型選抜"
  - "AO入試"
  - "総合選抜"
  - "特別選抜"
  - "総合型"
  - "AO"

quota_patterns:
  - "\\d+名"
  - "若干名"
  - "数名"
  - "\\d+名程度"
  - "\\d+人"
  - "若干人"

faculties:
  - "医学部"
  - "農学部"
  - "獣医学部"
  - "理学部"
  - "工学部"
  - "薬学部"
  - "歯学部"

selection_criteria:
  - "面接"
  - "小論文"
  - "プレゼンテーション"
  - "実技"
  - "グループディスカッション"
  - "志望理由書"
  - "活動実績"
EOF

echo "✅ キーワード管理ファイル完了"

# ==================== 5. __init__.py ファイル作成 ====================
echo "📦 __init__.py ファイルを作成中..."

find scraper -type d -exec touch {}/__init__.py \;

echo "✅ __init__.py ファイル作成完了"

# ==================== 6. 権限設定 ====================
echo "🔒 権限設定中..."

chmod -R 755 scraper/
find scraper -name "*.py" -exec chmod 644 {} \;

echo "✅ 権限設定完了"

echo ""
echo "🎉 効率重視プロジェクト構造実装完了！"
echo ""
echo "📋 作成された構造:"
echo "├── scraper/"
echo "│   ├── config/"
echo "│   │   ├── interfaces.py          # 型安全な契約定義"
echo "│   │   ├── settings.py            # Pydantic設定管理"
echo "│   │   └── keywords/              # キーワード管理"
echo "│   │       ├── medical_keywords.yaml"
echo "│   │       ├── agriculture_keywords.yaml  ★新規"
echo "│   │       └── admission_keywords.yaml    ★新規"
echo "│   ├── domain/                    # ドメイン層（次フェーズ）"
echo "│   ├── infrastructure/            # インフラ層（次フェーズ）"
echo "│   ├── application/               # アプリケーション層（次フェーズ）"
echo "│   ├── utils/                     # 共通ユーティリティ"
echo "│   └── tests/                     # テスト階層"
echo ""
echo "⚡ 次のアクション:"
echo "1. Domain層の実装"
echo "2. Infrastructure層の実装"
echo "3. Application層の実装"