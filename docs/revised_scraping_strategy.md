# 免疫研究室データベース拡充戦略（効率・品質重視版）🔬

## 🎯 目標
- **対象**: 日本の国公立・私立大学の免疫関係研究室（農学部含む）
- **規模**: 500-1000研究室（現在の9研究室から大幅拡張）
- **品質**: 高い可読性・保守性・拡張性を持つコードベース + 正確な研究情報

## 🏗️ 効率重視アーキテクチャ設計

### 1. 依存関係最適化プロジェクト構造
```
research_lab_scraper/
├── config/                             # 設定・契約定義層
│   ├── interfaces.py                   # 型安全な契約定義
│   ├── settings.py                     # Pydantic設定管理  
│   ├── university_configs.yaml         # 大学別設定（90校）
│   └── keywords/                       # キーワード管理
│       ├── medical_keywords.yaml       
│       ├── agriculture_keywords.yaml   ★新規
│       └── admission_keywords.yaml     ★新規
├── domain/                             # ドメイン層（ビジネスロジック）
│   ├── research_lab.py                 # 研究室ドメインオブジェクト
│   ├── university.py                   # 大学ドメインオブジェクト
│   ├── admission_info.py               # 総合型選抜ドメイン ★新規
│   └── keyword_analyzer.py             # 免疫関連度解析
├── infrastructure/                      # インフラ層
│   ├── database/
│   │   ├── models.py                   # SQLAlchemy ORM
│   │   ├── repository.py               # データアクセス抽象化
│   │   └── migrations/                 # DB変更管理
│   ├── http/
│   │   ├── rate_limiter.py             # 非同期レート制限
│   │   ├── http_client.py              # aiohttp ラッパー
│   │   └── retry_handler.py            # 堅牢な再試行機構
│   └── parsers/                        # HTML解析層
│       ├── base_parser.py              # パーサー基底クラス
│       ├── content_parser.py           # 研究内容解析
│       ├── contact_parser.py           # 連絡先情報解析
│       ├── agriculture_parser.py       # 農学系専用 ★新規
│       └── admission_parser.py         # 入試情報解析 ★新規
├── application/                        # アプリケーション層
│   ├── scrapers/                       # スクレイピング実装
│   │   ├── university_scraper_base.py  # 基底クラス
│   │   ├── medical_scraper.py          # 医学部専用
│   │   ├── agriculture_scraper.py      # 農学部専用 ★新規
│   │   ├── veterinary_scraper.py       # 獣医学部専用 ★新規
│   │   └── admission_scraper.py        # 総合型選抜専用 ★新規
│   ├── pipelines/                      # データ処理パイプライン
│   │   ├── lab_processing.py           # 研究室データ処理
│   │   ├── data_validation.py          # データ品質管理
│   │   └── enrichment.py               # 外部DB連携強化
│   └── orchestration/                  # プロセス調整
│       ├── scraper_factory.py          # ファクトリパターン
│       ├── pipeline_orchestrator.py    # 並行処理制御
│       └── monitoring.py               # パフォーマンス監視
├── utils/                              # 共通ユーティリティ
│   ├── logger.py                       # 構造化ログ
│   ├── functional.py                   # 関数型プログラミング
│   ├── validators.py                   # データバリデーション
│   └── url_discovery.py               # URL自動発見
└── tests/                              # テスト階層
    ├── unit/                           # 単体テスト
    ├── integration/                    # 統合テスト
    └── e2e/                           # エンドツーエンドテスト
```

### 2. 型安全な契約定義（interfaces.py）
```python
from abc import ABC, abstractmethod
from typing import List, Dict, Optional, Protocol
from dataclasses import dataclass
from datetime import datetime

@dataclass
class ResearchLabData:
    """研究室データの標準形式"""
    name: str
    professor_name: str
    department: str
    faculty: str
    research_content: str
    university_id: int
    lab_type: str = "general"
    animal_species: Optional[str] = None
    plant_species: Optional[str] = None
    research_techniques: Optional[str] = None
    immune_relevance_score: Optional[float] = None
    metadata: Dict = None

@dataclass  
class AdmissionData:
    """総合型選抜データの標準形式"""
    university_id: int
    faculty: str
    department: Optional[str]
    is_available: bool
    quota: str  # "10名", "若干名", "-"
    info_url: Optional[str]
    application_period: Optional[str]
    selection_method: Optional[str]
    last_updated: datetime

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

class DataRepositoryInterface(Protocol):
    """データリポジトリの契約"""
    
    async def save_research_lab(self, lab_data: ResearchLabData) -> int:
        """研究室データ保存"""
        ...
    
    async def save_admission_info(self, admission_data: AdmissionData) -> int:
        """入試情報保存"""
        ...
```

### 3. 設定駆動開発（university_configs.yaml）
```yaml
# 大学別設定の一元管理
universities:
  tokyo_university:
    name: "東京大学"
    base_url: "https://www.u-tokyo.ac.jp"
    rate_limit: 2.0  # 秒
    timeout: 30
    faculties:
      medical:
        urls:
          - "/faculty/medicine/research/"
          - "/graduate/medicine/laboratory/"
        selectors:
          lab_name: "h3.lab-title, .laboratory-name"
          professor: ".professor-name, .staff-name"
          content: ".research-content, .research-summary"
        keywords: ["免疫", "ワクチン", "アレルギー"]
      agriculture:
        urls:
          - "/faculty/agriculture/research/"
        selectors:
          lab_name: "h2.research-group"
          professor: ".leader-name"
          content: ".research-theme"
        keywords: ["動物免疫", "植物病理", "食品免疫"]
    admission:
      base_paths: ["/admission/", "/nyushi/"]
      comprehensive_keywords: ["総合型選抜", "AO入試"]
      
  kyoto_university:
    name: "京都大学"  
    base_url: "https://www.kyoto-u.ac.jp"
    rate_limit: 1.5
    # 京都大学固有の設定...

  tokyo_agriculture_university:
    name: "東京農工大学"
    base_url: "https://www.tuat.ac.jp"
    rate_limit: 1.0
    faculties:
      agriculture:
        urls:
          - "/faculty/agriculture/departments/"
          - "/graduate/agriculture/research/"
        selectors:
          lab_name: ".laboratory-title"
          professor: ".professor-info"
          content: ".research-outline"
        keywords: ["動物", "畜産", "獣医", "免疫"]
      veterinary:
        urls:
          - "/faculty/agriculture/veterinary/"
        selectors:
          lab_name: ".vet-lab-name"
          professor: ".vet-professor"
          content: ".vet-research"
        keywords: ["獣医免疫", "動物病理", "感染症"]
```

## 🚀 効率重視実装戦略

### Phase 0: 基盤設計・契約定義（1-2日）

#### 実装優先度1: 型安全な基盤
```python
# 1. config/interfaces.py     - 契約定義
# 2. config/settings.py       - Pydantic設定管理
# 3. domain/research_lab.py   - ドメインオブジェクト
# 4. pyproject.toml          - 依存関係・品質管理設定
```

### Phase 1: 並行開発基盤（3-5日）

#### 開発チーム分担
```python
# Team A: データ層 + バリデーション
├── infrastructure/database/models.py      # SQLAlchemy ORM
├── infrastructure/database/repository.py  # データアクセス
├── application/pipelines/data_validation.py
└── tests/unit/test_models.py              # 単体テスト

# Team B: HTTP基盤 + レート制限
├── infrastructure/http/rate_limiter.py    # 非同期レート制限
├── infrastructure/http/http_client.py     # aiohttp ラッパー
├── infrastructure/http/retry_handler.py   # 再試行機構
└── tests/unit/test_http.py                # HTTP層テスト

# Team C: パーサー基盤 + 解析
├── infrastructure/parsers/base_parser.py  # パーサー基底
├── infrastructure/parsers/content_parser.py
├── domain/keyword_analyzer.py             # 免疫関連度解析
└── tests/unit/test_parsers.py             # パーサーテスト
```

### Phase 2: 統合・医学部検証（2-3日）

#### 依存性注入による統合
```python
# application/orchestration/scraper_factory.py
class ScraperFactory:
    """依存性注入コンテナ"""
    
    def __init__(self):
        self.container = DIContainer()
        self._register_dependencies()
    
    def _register_dependencies(self):
        # HTTP層
        self.container.register(HttpClientInterface, AsyncHttpClient)
        self.container.register(RateLimiterInterface, TokenBucketLimiter)
        
        # パーサー層
        self.container.register(ContentParserInterface, UniversityContentParser)
        
        # データ層
        self.container.register(DataRepositoryInterface, SQLAlchemyRepository)
    
    def create_medical_scraper(self, university_name: str) -> MedicalScraper:
        config = ConfigLoader.load_university_config(university_name)
        
        return MedicalScraper(
            config=config,
            http_client=self.container.get(HttpClientInterface),
            parser=self.container.get(ContentParserInterface),
            repository=self.container.get(DataRepositoryInterface)
        )

# 医学部スクレイパーで最初の動作検証
# ├── application/scrapers/medical_scraper.py
# ├── tests/integration/test_medical_scraping.py  
# └── 既存9研究室データでの回帰テスト
```

### Phase 3: 農学・獣医学部拡張（3-4日）

#### 設定駆動による効率的拡張
```python
# 新しい大学追加は設定ファイルの更新のみ
# config/university_configs.yaml に追加

# 農学系専用機能
├── infrastructure/parsers/agriculture_parser.py
├── application/scrapers/agriculture_scraper.py
├── domain/species_extractor.py            # 動植物種抽出
└── tests/unit/test_agriculture_features.py

# 総合型選抜機能
├── infrastructure/parsers/admission_parser.py
├── application/scrapers/admission_scraper.py  
├── domain/admission_info.py
└── tests/unit/test_admission_scraping.py
```

### Phase 4: 大規模展開・品質管理（2-3日）

#### 自動品質管理・監視
```python
# 90校への展開
├── application/orchestration/pipeline_orchestrator.py  # 並行処理制御
├── application/orchestration/monitoring.py             # パフォーマンス監視
├── utils/logger.py                                     # 構造化ログ
└── tests/e2e/test_full_pipeline.py                    # エンドツーエンドテスト

# データ品質管理
├── application/pipelines/enrichment.py                # 外部DB連携
├── application/pipelines/deduplication.py             # 重複排除
└── utils/validators.py                                 # データ品質チェック
```

## 🔧 開発効率化ツール設定

### 1. プロジェクト初期化（pyproject.toml）
```toml
[tool.poetry]
name = "research-lab-scraper"
version = "0.1.0"
description = "効率的な免疫研究室データベース構築システム"

[tool.poetry.dependencies]
python = "^3.11"
# 非同期・HTTP
aiohttp = "^3.9"
asyncio-throttle = "^1.0.2"
# データ・ORM
pydantic = "^2.5"
sqlalchemy = "^2.0"
alembic = "^1.13"
# パーシング・解析
beautifulsoup4 = "^4.12"
lxml = "^4.9"
# 設定管理
pyyaml = "^6.0"
# ログ・監視
structlog = "^23.2"

[tool.poetry.group.dev.dependencies]
# テスト
pytest = "^7.4"
pytest-asyncio = "^0.21"
pytest-cov = "^4.1"
# 品質管理
black = "^23.11"
isort = "^5.12"
mypy = "^1.7"
flake8 = "^6.1"
pre-commit = "^3.5"

[tool.black]
line-length = 88
target-version = ['py311']
include = '\.pyi?$'

[tool.isort]
profile = "black"
multi_line_output = 3

[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_configs = true

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
addopts = "--cov=src --cov-report=html --cov-report=term-missing"
```

### 2. 自動品質管理（.pre-commit-config.yaml）
```yaml
repos:
  - repo: https://github.com/psf/black
    rev: 23.11.0
    hooks:
      - id: black

  - repo: https://github.com/pycqa/isort  
    rev: 5.12.0
    hooks:
      - id: isort

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.7.1
    hooks:
      - id: mypy
        additional_dependencies: [pydantic, sqlalchemy]

  - repo: https://github.com/pycqa/flake8
    rev: 6.1.0
    hooks:
      - id: flake8

  - repo: local
    hooks:
      - id: tests
        name: Run tests
        entry: poetry run pytest
        language: system
        pass_filenames: false
        always_run: true
```

### 3. 開発効率化 Makefile
```makefile
.PHONY: setup test lint format clean

# 開発環境セットアップ
setup:
	poetry install
	poetry run pre-commit install
	poetry run alembic upgrade head

# テスト実行
test:
	poetry run pytest tests/ -v --cov=src/

test-unit:
	poetry run pytest tests/unit/ -v

test-integration:
	poetry run pytest tests/integration/ -v

test-e2e:
	poetry run pytest tests/e2e/ -v

# 品質管理
lint:
	poetry run mypy src/
	poetry run flake8 src/

format:
	poetry run black src/ tests/
	poetry run isort src/ tests/

# 本番実行
scrape-medical:
	poetry run python -m src.main --faculties medical --universities tokyo,kyoto,osaka

scrape-agriculture:
	poetry run python -m src.main --faculties agriculture,veterinary --universities tokyo_agriculture,hokkaido

scrape-admission:
	poetry run python -m src.main --mode admission --all-universities

# クリーンアップ
clean:
	find . -type d -name __pycache__ -delete
	find . -name "*.pyc" -delete
	rm -rf .coverage htmlcov/ .pytest_cache/
```

## 📊 拡張データソース戦略

### 1. 対象大学（90校）- 段階的展開

#### Tier 1: 医学・農学強豪（20校）
```yaml
medical_powerhouses:
  - 東京大学、京都大学、大阪大学、東北大学
  - 東京医科歯科大学、慶應義塾大学、順天堂大学

agriculture_powerhouses:  
  - 東京農工大学、北海道大学、帯広畜産大学
  - 岐阜大学、鳥取大学、宮崎大学、鹿児島大学
```

#### Tier 2: 旧帝大・難関国立（30校）
```yaml
national_universities:
  - 名古屋大学、九州大学、神戸大学、筑波大学
  - 千葉大学、新潟大学、金沢大学、岡山大学
  - 広島大学、熊本大学、長崎大学、鹿児島大学
```

#### Tier 3: 地方国立・私立拡張（40校）
```yaml
regional_expansion:
  - 弘前大学、岩手大学、秋田大学、山形大学
  - 群馬大学、富山大学、福井大学、山梨大学
  - 信州大学、静岡大学、三重大学、滋賀大学
```

### 2. 拡張キーワード戦略

#### 医学系（既存強化）
```yaml
medical_keywords:
  basic: ["免疫", "immunology", "ワクチン", "vaccine"]
  advanced: ["免疫チェックポイント", "CAR-T", "オートファジー"]
  diseases: ["がん免疫", "自己免疫", "アレルギー", "感染症"]
  techniques: ["単クローン抗体", "細胞療法", "遺伝子治療"]
```

#### 農学系（新規）★
```yaml
agriculture_keywords:
  animal_immunity: ["動物免疫", "家畜免疫", "魚類免疫", "水産免疫"]
  plant_immunity: ["植物免疫", "植物病理", "病害抵抗性"] 
  food_immunity: ["食品免疫", "栄養免疫", "プロバイオティクス"]
  species: ["牛", "豚", "鶏", "魚", "マウス", "ラット"]
```

#### 総合型選抜（新規）★
```yaml
admission_keywords:
  selection_types: ["総合型選抜", "AO入試", "総合選抜", "特別選抜"]
  quota_patterns: ["\\d+名", "若干名", "数名", "\\d+名程度"]
  faculties: ["医学部", "農学部", "獣医学部", "理学部", "工学部"]
```

## 📈 期待される成果

### 定量目標
- **研究室数**: 500-1000件（既存9件の55-110倍）
- **大学数**: 90校（既存3校の30倍）
- **データ品質**: 95%以上の精度（自動バリデーション）
- **更新頻度**: 月次自動更新
- **検索速度**: 100ms以下（インデックス最適化）

### 新機能
- **農学・獣医学検索**: 動物・植物免疫研究の包括的発見
- **総合型選抜フィルタ**: 入試方式による絞り込み
- **類似研究室推薦**: ベクトル検索による関連研究発見
- **研究動向分析**: キーワードトレンド可視化

### 技術的成果
- **拡張性**: 新大学追加は設定ファイル更新のみ
- **保守性**: 型安全性による実行時エラー99%削減
- **監視可能性**: 構造化ログによる運用課題の即座検出
- **テスト網羅率**: 90%以上のコードカバレッジ

## 🔄 継続的改善戦略

### 1. データ品質監視
```python
# 週次データ品質レポート
- 新規研究室発見数
- データ完全性スコア
- 重複率・欠損率
- 免疫関連度分布
```

### 2. 機能拡張ロードマップ
```python
# Phase 5 (4-6ヶ月後): AI強化
- 研究内容の自動要約
- 共同研究提案システム
- 研究室マッチング機能

# Phase 6 (6-12ヶ月後): 国際展開  
- 海外大学データベース連携
- 多言語対応
- 国際共同研究支援
```

この効率・品質重視の戦略で、**開発期間の短縮**と**長期的な保守性確保**を両立できます。