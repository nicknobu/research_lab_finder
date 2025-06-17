# 🔬 研究室ファインダー - 統合プロジェクト構造

research_lab_finder/  # 既存のルートプロジェクト
├── README.md
├── docker-compose.yml
├── .env.example
├── .gitignore
│
# ==================== 既存コンポーネント（保持） ====================
├── backend/                     # 既存FastAPIアプリ（保持）
│   ├── app/
│   │   ├── main.py             # 既存API
│   │   ├── api/endpoints/      # 既存エンドポイント
│   │   ├── core/               # セマンティック検索
│   │   └── utils/              # 既存ユーティリティ
│   └── data/                   # 既存データ（50件）
│
├── frontend/                   # 既存React UI（保持）
│   ├── src/
│   │   ├── pages/              # 既存ページ
│   │   ├── components/         # 既存コンポーネント
│   │   └── utils/              # 既存ユーティリティ
│   └── package.json
│
# ==================== 新規追加: スクレイピングシステム ====================
├── scraper/                    # 新規: スクレイピングモジュール
│   ├── __init__.py
│   ├── config/                 # スクレイピング設定
│   │   ├── __init__.py
│   │   ├── interfaces.py       # 型安全な契約定義
│   │   ├── settings.py         # Pydantic設定管理
│   │   ├── university_configs.yaml  # 90大学設定
│   │   └── keywords/           # キーワード管理
│   │       ├── immune_keywords.yaml
│   │       ├── agriculture_keywords.yaml    # 新規
│   │       ├── veterinary_keywords.yaml     # 新規
│   │       └── admission_keywords.yaml      # 新規
│   │
│   ├── domain/                 # ドメイン層
│   │   ├── __init__.py
│   │   ├── research_lab.py     # 研究室ドメインオブジェクト
│   │   ├── university.py       # 大学ドメインオブジェクト
│   │   ├── admission_info.py   # 総合型選抜ドメイン（新規）
│   │   └── keyword_analyzer.py # 免疫関連度解析
│   │
│   ├── infrastructure/         # インフラ層
│   │   ├── __init__.py
│   │   ├── database/
│   │   │   ├── __init__.py
│   │   │   ├── models.py       # 拡張SQLAlchemyモデル
│   │   │   ├── repository.py   # データアクセス抽象化
│   │   │   └── migrations/     # DB拡張マイグレーション
│   │   ├── http/
│   │   │   ├── __init__.py
│   │   │   ├── rate_limiter.py # 非同期レート制限
│   │   │   ├── http_client.py  # aiohttp ラッパー
│   │   │   └── retry_handler.py # 堅牢な再試行機構
│   │   └── parsers/            # HTML解析層
│   │       ├── __init__.py
│   │       ├── base_parser.py  # パーサー基底クラス
│   │       ├── content_parser.py # 研究内容解析
│   │       ├── agriculture_parser.py # 農学系専用（新規）
│   │       ├── veterinary_parser.py  # 獣医学系専用（新規）
│   │       └── admission_parser.py   # 入試情報解析（新規）
│   │
│   ├── application/            # アプリケーション層
│   │   ├── __init__.py
│   │   ├── scrapers/           # スクレイピング実装
│   │   │   ├── __init__.py
│   │   │   ├── university_scraper_base.py # 基底クラス
│   │   │   ├── medical_scraper.py      # 医学部専用
│   │   │   ├── agriculture_scraper.py  # 農学部専用（新規）
│   │   │   ├── veterinary_scraper.py   # 獣医学部専用（新規）
│   │   │   └── admission_scraper.py    # 総合型選抜専用（新規）
│   │   ├── pipelines/          # データ処理パイプライン
│   │   │   ├── __init__.py
│   │   │   ├── lab_processing.py   # 研究室データ処理
│   │   │   ├── data_validation.py  # データ品質管理
│   │   │   └── enrichment.py       # 外部DB連携強化
│   │   └── orchestration/      # プロセス調整
│   │       ├── __init__.py
│   │       ├── scraper_factory.py     # ファクトリパターン
│   │       ├── pipeline_orchestrator.py # 並行処理制御
│   │       └── monitoring.py          # パフォーマンス監視
│   │
│   ├── utils/                  # 共通ユーティリティ
│   │   ├── __init__.py
│   │   ├── logger.py           # 構造化ログ
│   │   ├── functional.py       # 関数型プログラミング
│   │   ├── validators.py       # データバリデーション
│   │   └── url_discovery.py    # URL自動発見
│   │
│   ├── cli/                    # CLIインターフェース（新規）
│   │   ├── __init__.py
│   │   ├── main.py             # メインCLI
│   │   ├── commands/
│   │   │   ├── __init__.py
│   │   │   ├── scrape.py       # スクレイピング実行
│   │   │   ├── validate.py     # データ検証
│   │   │   └── export.py       # データエクスポート
│   │   └── ui/
│   │       ├── __init__.py
│   │       ├── progress.py     # プログレス表示
│   │       └── report.py       # レポート生成
│   │
│   └── tests/                  # スクレイピング専用テスト
│       ├── __init__.py
│       ├── unit/               # 単体テスト
│       ├── integration/        # 統合テスト
│       └── e2e/               # エンドツーエンドテスト
│
# ==================== 統合管理ファイル ====================
├── scripts/                   # 統合管理スクリプト
│   ├── setup.sh              # 既存: 開発環境セットアップ
│   ├── run_dev.sh             # 既存: 開発サーバー起動
│   ├── run_scraper.sh         # 新規: スクレイピング実行
│   ├── data_pipeline.sh       # 新規: データパイプライン実行
│   ├── full_update.sh         # 新規: フルデータ更新
│   └── monitoring.sh          # 新規: システム監視
│
├── requirements/              # 統合依存関係管理
│   ├── base.txt              # 共通依存関係
│   ├── backend.txt           # 既存バックエンド
│   ├── frontend.txt          # 既存フロントエンド
│   ├── scraper.txt           # 新規スクレイピング
│   └── dev.txt               # 開発環境専用
│
├── config/                   # 統合設定管理
│   ├── development.env       # 開発環境設定
│   ├── production.env        # 本番環境設定
│   ├── scraper.env          # スクレイピング専用設定
│   └── logging.conf         # ログ設定
│
├── database/                 # 拡張データベース設計
│   ├── init.sql             # 既存: 基本スキーマ
│   ├── scraper_schema.sql   # 新規: スクレイピング拡張スキーマ
│   ├── agriculture_schema.sql # 新規: 農学系テーブル
│   ├── admission_schema.sql  # 新規: 入試情報テーブル
│   └── indexes.sql          # 新規: パフォーマンス最適化
│
├── docs/                    # 統合ドキュメント
│   ├── README.md           # プロジェクト概要
│   ├── DEVELOPMENT.md      # 開発ガイド
│   ├── SCRAPER_GUIDE.md    # スクレイピングガイド
│   ├── API_REFERENCE.md    # API仕様書
│   └── DEPLOYMENT.md       # デプロイガイド
│
# ==================== 統合設定ファイル ====================
├── pyproject.toml           # 統合Python設定
├── docker-compose.scraper.yml # スクレイピング専用Docker設定
├── Makefile                 # 統合タスク管理
└── .github/                 # 統合CI/CD
    └── workflows/
        ├── api_tests.yml    # 既存: API テスト
        ├── frontend_tests.yml # 既存: フロントエンドテスト
        ├── scraper_tests.yml  # 新規: スクレイピングテスト
        └── data_pipeline.yml  # 新規: データパイプライン