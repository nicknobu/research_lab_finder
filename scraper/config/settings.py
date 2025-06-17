"""
Pydantic設定管理システム
型安全で環境別設定を統合管理
"""

import os
from pathlib import Path
from typing import Any, Dict, List, Optional, Set
from functools import lru_cache

from pydantic import BaseSettings, Field, validator, root_validator
from pydantic.types import PositiveInt, PositiveFloat

from research_lab_scraper.config.interfaces import FacultyType, ResearchField


class DatabaseSettings(BaseSettings):
    """データベース設定"""
    
    host: str = Field(default="localhost", env="DB_HOST")
    port: PositiveInt = Field(default=5432, env="DB_PORT")
    name: str = Field(default="research_labs", env="DB_NAME")
    user: str = Field(default="postgres", env="DB_USER")
    password: str = Field(default="", env="DB_PASSWORD")
    
    # 接続プール設定
    pool_size: PositiveInt = Field(default=5, env="DB_POOL_SIZE")
    max_overflow: PositiveInt = Field(default=10, env="DB_MAX_OVERFLOW")
    pool_timeout: PositiveFloat = Field(default=30.0, env="DB_POOL_TIMEOUT")
    
    # SSL設定
    ssl_mode: str = Field(default="prefer", env="DB_SSL_MODE")
    
    @property
    def database_url(self) -> str:
        """データベース接続URL生成"""
        return (
            f"postgresql://{self.user}:{self.password}"
            f"@{self.host}:{self.port}/{self.name}"
            f"?sslmode={self.ssl_mode}"
        )
    
    @property
    def async_database_url(self) -> str:
        """非同期データベース接続URL生成"""
        return self.database_url.replace("postgresql://", "postgresql+asyncpg://")
    
    class Config:
        env_prefix = "DB_"
        case_sensitive = False


class ScrapingSettings(BaseSettings):
    """スクレイピング設定"""
    
    # レート制限設定
    requests_per_second: PositiveFloat = Field(default=0.5, env="SCRAPING_RPS")
    requests_per_minute: PositiveInt = Field(default=20, env="SCRAPING_RPM")
    concurrent_requests: PositiveInt = Field(default=3, env="SCRAPING_CONCURRENT")
    
    # リトライ設定
    max_retries: PositiveInt = Field(default=3, env="SCRAPING_MAX_RETRIES")
    retry_delay: PositiveFloat = Field(default=2.0, env="SCRAPING_RETRY_DELAY")
    backoff_factor: PositiveFloat = Field(default=2.0, env="SCRAPING_BACKOFF_FACTOR")
    
    # タイムアウト設定
    request_timeout: PositiveFloat = Field(default=30.0, env="SCRAPING_TIMEOUT")
    connection_timeout: PositiveFloat = Field(default=10.0, env="SCRAPING_CONN_TIMEOUT")
    
    # ユーザーエージェント設定
    user_agent: str = Field(
        default="ResearchLabScraper/1.0 (Educational Purpose; contact@example.com)",
        env="SCRAPING_USER_AGENT"
    )
    
    # リスペクト設定
    respect_robots_txt: bool = Field(default=True, env="SCRAPING_RESPECT_ROBOTS")
    honor_crawl_delay: bool = Field(default=True, env="SCRAPING_HONOR_DELAY")
    
    # キャッシュ設定
    cache_enabled: bool = Field(default=True, env="SCRAPING_CACHE_ENABLED")
    cache_ttl: PositiveInt = Field(default=3600, env="SCRAPING_CACHE_TTL")  # 1時間
    
    @validator('requests_per_second')
    def validate_rps(cls, v):
        if v > 2.0:  # 過度な負荷防止
            raise ValueError("requests_per_secondは2.0以下に設定してください")
        return v
    
    class Config:
        env_prefix = "SCRAPING_"
        case_sensitive = False


class AnalysisSettings(BaseSettings):
    """分析・AI設定"""
    
    # 免疫関連度分析
    immune_keywords_file: Path = Field(
        default=Path("config/keywords/immune_keywords.yaml"),
        env="ANALYSIS_IMMUNE_KEYWORDS_FILE"
    )
    
    # 農学系キーワード（新規追加）
    agriculture_keywords_file: Path = Field(
        default=Path("config/keywords/agriculture_keywords.yaml"),
        env="ANALYSIS_AGRICULTURE_KEYWORDS_FILE"
    )
    
    # 獣医学系キーワード（新規追加）
    veterinary_keywords_file: Path = Field(
        default=Path("config/keywords/veterinary_keywords.yaml"),
        env="ANALYSIS_VETERINARY_KEYWORDS_FILE"
    )
    
    # 入試キーワード（新規追加）
    admission_keywords_file: Path = Field(
        default=Path("config/keywords/admission_keywords.yaml"),
        env="ANALYSIS_ADMISSION_KEYWORDS_FILE"
    )
    
    # スコアリング設定
    minimum_immune_score: float = Field(default=0.3, env="ANALYSIS_MIN_IMMUNE_SCORE")
    keyword_weight_multiplier: float = Field(default=1.5, env="ANALYSIS_KEYWORD_WEIGHT")
    
    # テキスト処理設定
    max_text_length: PositiveInt = Field(default=10000, env="ANALYSIS_MAX_TEXT_LENGTH")
    enable_text_preprocessing: bool = Field(default=True, env="ANALYSIS_PREPROCESS")
    
    @validator('minimum_immune_score')
    def validate_immune_score(cls, v):
        if not 0.0 <= v <= 1.0:
            raise ValueError("minimum_immune_scoreは0.0-1.0の範囲で設定してください")
        return v
    
    class Config:
        env_prefix = "ANALYSIS_"
        case_sensitive = False


class UniversityFilterSettings(BaseSettings):
    """大学フィルタリング設定"""
    
    # 対象大学種別
    target_university_types: Set[str] = Field(
        default={"national", "public", "private"},
        env="UNIVERSITY_TARGET_TYPES"
    )
    
    # 対象学部
    target_faculties: Set[FacultyType] = Field(
        default={
            FacultyType.MEDICINE,
            FacultyType.SCIENCE, 
            FacultyType.ENGINEERING,
            FacultyType.PHARMACY,
            FacultyType.AGRICULTURE,      # 新規追加
            FacultyType.VETERINARY,       # 新規追加
            FacultyType.DENTISTRY,
            FacultyType.GRADUATE_SCHOOL
        },
        env="UNIVERSITY_TARGET_FACULTIES"
    )
    
    # 地域フィルタ
    target_regions: Set[str] = Field(
        default={"関東", "関西", "東海", "九州", "東北", "中国", "四国", "北海道"},
        env="UNIVERSITY_TARGET_REGIONS"
    )
    
    # 除外大学（ID指定）
    excluded_university_ids: Set[int] = Field(default=set(), env="UNIVERSITY_EXCLUDED_IDS")
    
    # 優先大学（重要度順）
    high_priority_universities: List[int] = Field(
        default=[1, 2, 3, 4, 5],  # 旧帝大など
        env="UNIVERSITY_HIGH_PRIORITY"
    )
    
    class Config:
        env_prefix = "UNIVERSITY_"
        case_sensitive = False


class LoggingSettings(BaseSettings):
    """ログ設定"""
    
    level: str = Field(default="INFO", env="LOG_LEVEL")
    format: str = Field(
        default="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        env="LOG_FORMAT"
    )
    
    # 構造化ログ設定
    structured_logging: bool = Field(default=True, env="LOG_STRUCTURED")
    log_file_path: Optional[Path] = Field(default=None, env="LOG_FILE_PATH")
    
    # ファイルローテーション
    max_file_size: str = Field(default="10MB", env="LOG_MAX_FILE_SIZE")
    backup_count: PositiveInt = Field(default=5, env="LOG_BACKUP_COUNT")
    
    # 開発環境設定
    console_output: bool = Field(default=True, env="LOG_CONSOLE")
    color_output: bool = Field(default=True, env="LOG_COLOR")
    
    @validator('level')
    def validate_log_level(cls, v):
        valid_levels = {'DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'}
        if v.upper() not in valid_levels:
            raise ValueError(f"ログレベルは {valid_levels} のいずれかを指定してください")
        return v.upper()
    
    class Config:
        env_prefix = "LOG_"
        case_sensitive = False


class SecuritySettings(BaseSettings):
    """セキュリティ設定"""
    
    # APIキー設定
    openai_api_key: Optional[str] = Field(default=None, env="OPENAI_API_KEY")
    
    # データ保護
    encrypt_sensitive_data: bool = Field(default=True, env="SECURITY_ENCRYPT_DATA")
    data_retention_days: PositiveInt = Field(default=365, env="SECURITY_RETENTION_DAYS")
    
    # アクセス制御
    allowed_ip_ranges: List[str] = Field(
        default=["127.0.0.1", "::1"],
        env="SECURITY_ALLOWED_IPS"
    )
    
    # リクエスト制限
    max_concurrent_scraping: PositiveInt = Field(
        default=5,
        env="SECURITY_MAX_CONCURRENT"
    )
    
    class Config:
        env_prefix = "SECURITY_"
        case_sensitive = False


class MonitoringSettings(BaseSettings):
    """監視・メトリクス設定"""
    
    # メトリクス収集
    enable_metrics: bool = Field(default=True, env="MONITORING_ENABLE_METRICS")
    metrics_port: PositiveInt = Field(default=8080, env="MONITORING_METRICS_PORT")
    
    # ヘルスチェック
    health_check_interval: PositiveInt = Field(default=30, env="MONITORING_HEALTH_INTERVAL")
    
    # アラート設定
    alert_on_failure_rate: float = Field(default=0.1, env="MONITORING_ALERT_FAILURE_RATE")
    alert_email: Optional[str] = Field(default=None, env="MONITORING_ALERT_EMAIL")
    
    # パフォーマンス監視
    slow_request_threshold: PositiveFloat = Field(
        default=5.0,
        env="MONITORING_SLOW_THRESHOLD"
    )
    
    class Config:
        env_prefix = "MONITORING_"
        case_sensitive = False


class Settings(BaseSettings):
    """統合設定クラス"""
    
    # 環境設定
    environment: str = Field(default="development", env="ENVIRONMENT")
    debug: bool = Field(default=False, env="DEBUG")
    testing: bool = Field(default=False, env="TESTING")
    
    # 各種設定
    database: DatabaseSettings = DatabaseSettings()
    scraping: ScrapingSettings = ScrapingSettings()
    analysis: AnalysisSettings = AnalysisSettings()
    university: UniversityFilterSettings = UniversityFilterSettings()
    logging: LoggingSettings = LoggingSettings()
    security: SecuritySettings = SecuritySettings()
    monitoring: MonitoringSettings = MonitoringSettings()
    
    # プロジェクト基本設定
    project_name: str = Field(default="Research Lab Scraper", env="PROJECT_NAME")
    version: str = Field(default="0.1.0", env="PROJECT_VERSION")
    
    # ファイルパス設定
    config_dir: Path = Field(default=Path("config"), env="CONFIG_DIR")
    data_dir: Path = Field(default=Path("data"), env="DATA_DIR")
    logs_dir: Path = Field(default=Path("logs"), env="LOGS_DIR")
    
    @root_validator
    def validate_environment_consistency(cls, values):
        """環境設定の整合性チェック"""
        env = values.get('environment', 'development')
        debug = values.get('debug', False)
        testing = values.get('testing', False)
        
        if env == 'production' and debug:
            raise ValueError("本番環境ではデバッグモードを無効にしてください")
        
        if testing and env == 'production':
            raise ValueError("本番環境でテストモードは使用できません")
        
        return values
    
    @validator('environment')
    def validate_environment(cls, v):
        valid_envs = {'development', 'testing', 'staging', 'production'}
        if v not in valid_envs:
            raise ValueError(f"環境は {valid_envs} のいずれかを指定してください")
        return v
    
    def create_directories(self) -> None:
        """必要なディレクトリを作成"""
        directories = [self.config_dir, self.data_dir, self.logs_dir]
        for directory in directories:
            directory.mkdir(parents=True, exist_ok=True)
    
    @property
    def is_development(self) -> bool:
        """開発環境判定"""
        return self.environment == "development"
    
    @property
    def is_production(self) -> bool:
        """本番環境判定"""
        return self.environment == "production"
    
    @property
    def is_testing(self) -> bool:
        """テスト環境判定"""
        return self.environment == "testing"
    
    class Config:
        case_sensitive = False
        env_file = ".env"
        env_file_encoding = "utf-8"
        validate_assignment = True
        
        # 設定の変更を許可しない（Immutable）
        allow_mutation = False


@lru_cache()
def get_settings() -> Settings:
    """
    設定インスタンスを取得（キャッシュ有効）
    
    Returns:
        Settings: 設定インスタンス
    """
    settings = Settings()
    settings.create_directories()
    return settings


# 開発用ヘルパー関数
def get_database_url() -> str:
    """データベースURL取得"""
    return get_settings().database.database_url


def get_async_database_url() -> str:
    """非同期データベースURL取得"""
    return get_settings().database.async_database_url


def is_debug_mode() -> bool:
    """デバッグモード判定"""
    return get_settings().debug


def get_log_level() -> str:
    """ログレベル取得"""
    return get_settings().logging.level