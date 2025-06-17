# 🔬 研究室ファインダー - Python 3.9 クイックスタート

# ==================== Step 1: セットアップスクリプト実行 ====================
# Python 3.9対応版セットアップ（上記作成済み）
chmod +x scripts/setup_python39_compatible.sh
./scripts/setup_python39_compatible.sh

# ==================== Step 2: 仮想環境有効化 ====================
# Windows (Git Bash)
source venv/Scripts/activate

# Linux/macOS (参考)
# source venv/bin/activate

# ==================== Step 3: Python 3.9対応依存関係作成 ====================
# requirements/ ディレクトリは作成済み
# 以下のファイルを手動で作成（Claudeが提供）

# ---- requirements/base.txt (Python 3.9版) ----
cat > requirements/base.txt << 'EOF'
# 🔬 Python 3.9対応版 - 共通依存関係
pydantic>=1.10,<2.0
pydantic[dotenv]>=1.10,<2.0
pandas>=1.5,<2.0
numpy>=1.21,<2.0
python-dateutil>=2.8,<3.0
python-dotenv>=0.20,<1.0
structlog>=22.3,<24.0
click>=8.0,<9.0
rich>=12.0,<14.0
sqlalchemy>=1.4,<2.0
alembic>=1.8,<2.0
httpx>=0.23,<1.0
cryptography>=3.4,<42.0
tqdm>=4.60,<5.0
colorama>=0.4,<1.0
typing-extensions>=4.0,<5.0
pyyaml>=6.0,<7.0
ujson>=5.4,<6.0
EOF

# ---- requirements/backend.txt (Python 3.9版) ----
cat > requirements/backend.txt << 'EOF'
# 🔬 Python 3.9対応版 - バックエンド依存関係
-r base.txt

# Web Framework
fastapi>=0.95,<1.0
uvicorn[standard]>=0.20,<1.0
gunicorn>=20.1,<22.0

# Database Specific
psycopg2-binary>=2.9,<3.0
pgvector>=0.1.6,<1.0
asyncpg>=0.27,<1.0

# AI & Machine Learning
openai>=0.28,<1.0
scikit-learn>=1.2,<2.0

# HTTP & API
python-multipart>=0.0.5,<1.0
python-jose[cryptography]>=3.3,<4.0
passlib[bcrypt]>=1.7,<2.0

# Performance
aiofiles>=22.1,<24.0
prometheus-client>=0.16,<1.0
EOF

# ---- requirements/scraper.txt (Python 3.9版) ----
cat > requirements/scraper.txt << 'EOF'
# 🔬 Python 3.9対応版 - スクレイピング依存関係
-r base.txt

# HTTP & Web Scraping
aiohttp>=3.8,<4.0
asyncio-throttle>=1.0.2,<2.0
tenacity>=8.0,<9.0
fake-useragent>=1.4,<2.0

# HTML Parsing
beautifulsoup4>=4.11,<5.0
lxml>=4.6,<5.0
pyquery>=1.4,<3.0

# Async & Concurrency
aiofiles>=22.1,<24.0
schedule>=1.2,<2.0

# Dependency Injection
dependency-injector>=4.40,<5.0

# Monitoring & Metrics
psutil>=5.9,<6.0
memory-profiler>=0.60,<1.0

# Data Storage & Export
openpyxl>=3.0,<4.0
jsonlines>=3.1,<5.0

# Caching
diskcache>=5.4,<6.0
cachetools>=5.0,<6.0

# Text Processing
spacy>=3.4,<4.0
fuzzywuzzy>=0.18,<1.0

# CLI
typer>=0.7,<1.0
EOF

# ---- requirements/dev.txt (Python 3.9版) ----
cat > requirements/dev.txt << 'EOF'
# 🔬 Python 3.9対応版 - 開発・テスト依存関係
-r base.txt
-r backend.txt
-r scraper.txt

# Testing Framework
pytest>=7.1,<8.0
pytest-asyncio>=0.20,<1.0
pytest-cov>=4.0,<5.0
pytest-mock>=3.10,<4.0
hypothesis>=6.60,<7.0

# Code Quality
mypy>=0.991,<2.0
black>=22.0,<24.0
isort>=5.10,<6.0
flake8>=5.0,<7.0
bandit>=1.7,<2.0

# Development Tools
pre-commit>=2.20,<4.0
ipython>=8.5,<9.0
jupyter>=1.0,<2.0

# Documentation
sphinx>=5.0,<8.0
sphinx-rtd-theme>=1.0,<2.0
EOF

# ==================== Step 4: 依存関係インストール ====================
# pip アップグレード
pip install --upgrade pip

# 基本依存関係インストール
pip install -r requirements/base.txt

# バックエンド依存関係インストール
pip install -r requirements/backend.txt

# スクレイピング依存関係インストール
pip install -r requirements/scraper.txt

# 開発依存関係インストール（オプション）
# pip install -r requirements/dev.txt

# ==================== Step 5: フロントエンド依存関係 ====================
cd frontend
npm install
cd ..

# ==================== Step 6: 環境変数設定 ====================
# .env ファイルを編集
echo "📝 .env ファイルでOpenAI APIキーを設定してください"
echo "OPENAI_API_KEY=sk-your_actual_api_key_here"

# ==================== Step 7: 既存システム確認 ====================
# Docker コンテナ起動
docker-compose up -d

# ヘルスチェック
sleep 10
curl http://localhost:8000/health

# ==================== Step 8: スクレイピングモジュール初期化 ====================
# 基本的なPythonファイル作成
mkdir -p scraper/config scraper/domain

# 設定ファイル作成（Claude提供のファイルを配置）
echo "📁 scraper/ ディレクトリ構造が作成されました"
echo "💡 Claude が作成した以下のファイルを配置してください："
echo "  - scraper/config/interfaces.py"
echo "  - scraper/config/settings.py"
echo "  - scraper/domain/research_lab.py"

# ==================== 完了メッセージ ====================
echo ""
echo "🎉 Python 3.9対応セットアップ完了！"
echo ""
echo "次のステップ："
echo "1. Claude作成の scraper/ モジュールファイルを配置"
echo "2. .env ファイルでAPIキー設定"
echo "3. スクレイピング機能開発開始"