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
