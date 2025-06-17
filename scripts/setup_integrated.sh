#!/bin/bash

# 🔬 研究室ファインダー - 統合プロジェクトセットアップスクリプト
# 既存のresearch_lab_finderにスクレイピング機能を統合

set -e  # エラー時に終了

# 色付き出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ロゴ表示
echo -e "${BLUE}"
echo "🔬 =============================================="
echo "   研究室ファインダー統合プロジェクト"
echo "   スクレイピング機能拡張セットアップ"
echo "============================================== 🔬"
echo -e "${NC}"

# 前提条件チェック
echo -e "${YELLOW}📋 前提条件チェック${NC}"

# Python バージョンチェック
python_version=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
required_version="3.11"

if ! python3 -c "import sys; exit(0 if sys.version_info >= (3, 11) else 1)" 2>/dev/null; then
    echo -e "${RED}❌ Python 3.11以上が必要です。現在: ${python_version}${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Python ${python_version}${NC}"

# Node.js チェック
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js が見つかりません${NC}"
    exit 1
fi
node_version=$(node --version)
echo -e "${GREEN}✅ Node.js ${node_version}${NC}"

# Docker チェック
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠️ Docker が見つかりません（オプション）${NC}"
else
    echo -e "${GREEN}✅ Docker 利用可能${NC}"
fi

echo ""

# ==================== ディレクトリ構造作成 ====================
echo -e "${BLUE}📁 統合プロジェクト構造作成${NC}"

# 新しいディレクトリ作成
mkdir -p requirements
mkdir -p scraper/{config,domain,infrastructure,application,utils,cli,tests}
mkdir -p scraper/config/keywords
mkdir -p scraper/infrastructure/{database,http,parsers}
mkdir -p scraper/application/{scrapers,pipelines,orchestration}
mkdir -p scraper/tests/{unit,integration,e2e}
mkdir -p config
mkdir -p docs

# __init__.py ファイル作成
find scraper -type d -exec touch {}/__init__.py \;

echo -e "${GREEN}✅ ディレクトリ構造作成完了${NC}"

# ==================== 依存関係ファイル配置 ====================
echo -e "${BLUE}📦 依存関係ファイル配置${NC}"

# 既存のbackend/requirements.txtをバックアップ
if [ -f "backend/requirements.txt" ]; then
    cp backend/requirements.txt backend/requirements.txt.backup
    echo -e "${YELLOW}📄 既存backend/requirements.txtをバックアップしました${NC}"
fi

# 新しいrequirements構造のメッセージ
echo -e "${YELLOW}📝 新しい依存関係構造:${NC}"
echo "  requirements/"
echo "  ├── base.txt     # 共通依存関係"
echo "  ├── backend.txt  # FastAPI + セマンティック検索"
echo "  ├── scraper.txt  # スクレイピング専用"
echo "  ├── dev.txt      # 開発・テスト用"
echo "  └── frontend.txt # フロントエンド管理（参考用）"
echo ""

# ==================== Python仮想環境 ====================
echo -e "${BLUE}🐍 Python仮想環境セットアップ${NC}"

# 既存の仮想環境チェック
if [ -d "venv" ]; then
    echo -e "${YELLOW}⚠️ 既存の仮想環境が見つかりました${NC}"
    read -p "既存の仮想環境を削除して再作成しますか？ (y/N): " recreate_venv
    if [[ $recreate_venv =~ ^[Yy]$ ]]; then
        rm -rf venv
        echo -e "${GREEN}✅ 既存仮想環境を削除しました${NC}"
    else
        echo -e "${YELLOW}📦 既存仮想環境を使用します${NC}"
    fi
fi

# 仮想環境作成（存在しない場合）
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo -e "${GREEN}✅ 新しい仮想環境を作成しました${NC}"
fi

# 仮想環境有効化の案内
echo -e "${YELLOW}📋 次のコマンドで仮想環境を有効化してください:${NC}"
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    echo "  source venv/Scripts/activate"
else
    echo "  source venv/bin/activate"
fi
echo ""

# ==================== 基本設定ファイル作成 ====================
echo -e "${BLUE}⚙️ 設定ファイル作成${NC}"

# .env.integrated.example 作成
cat > .env.integrated.example << 'EOF'
# 🔬 研究室ファインダー統合プロジェクト設定

# ==================== 環境設定 ====================
ENVIRONMENT=development
DEBUG=true
TESTING=false

# ==================== データベース設定 ====================
DB_HOST=localhost
DB_PORT=5432
DB_NAME=research_lab_finder
DB_USER=postgres
DB_PASSWORD=your_password_here

# 本番環境用（自動生成）
DATABASE_URL=postgresql://postgres:your_password_here@localhost:5432/research_lab_finder

# ==================== AI・API設定 ====================
OPENAI_API_KEY=sk-your_openai_api_key_here

# ==================== スクレイピング設定 ====================
SCRAPING_RPS=0.5
SCRAPING_CONCURRENT=3
SCRAPING_MAX_RETRIES=3
SCRAPING_USER_AGENT=ResearchLabScraper/2.0 (Educational Purpose; contact@example.com)

# ==================== ログ設定 ====================
LOG_LEVEL=INFO
LOG_STRUCTURED=true
LOG_FILE_PATH=logs/scraper.log

# ==================== セキュリティ設定 ====================
SECURITY_ENCRYPT_DATA=true
SECURITY_MAX_CONCURRENT=5

# ==================== 監視設定 ====================
MONITORING_ENABLE_METRICS=true
MONITORING_METRICS_PORT=8080

# ==================== フロントエンド設定 ====================
VITE_API_BASE_URL=http://localhost:8000
ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
EOF

# .env作成（開発用）
if [ ! -f ".env" ]; then
    cp .env.integrated.example .env
    echo -e "${GREEN}✅ 開発用.envファイルを作成しました${NC}"
else
    echo -e "${YELLOW}⚠️ 既存の.envファイルが存在します${NC}"
fi

# Makefile配置案内
echo -e "${YELLOW}📄 Makefile を配置してください（統合プロジェクト管理用）${NC}"

# ==================== Git設定更新 ====================
echo -e "${BLUE}📝 Git設定更新${NC}"

# .gitignore更新
echo "
# スクレイピング関連
scraper/logs/
scraper/cache/
scraped_data/
*.scraped

# 統合プロジェクト
requirements/*.lock
.coverage
htmlcov/" >> .gitignore

echo -e "${GREEN}✅ .gitignore を更新しました${NC}"

# ==================== 次のステップ案内 ====================
echo ""
echo -e "${GREEN}🎉 統合プロジェクトセットアップ完了！${NC}"
echo ""
echo -e "${YELLOW}📋 次のステップ:${NC}"
echo ""
echo -e "${BLUE}1. 仮想環境有効化:${NC}"
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    echo "   source venv/Scripts/activate"
else
    echo "   source venv/bin/activate"
fi
echo ""
echo -e "${BLUE}2. 依存関係インストール:${NC}"
echo "   # Makefileを使用（推奨）"
echo "   make install-all"
echo ""
echo "   # または手動インストール"
echo "   pip install -r requirements/base.txt"
echo "   pip install -r requirements/backend.txt"
echo "   pip install -r requirements/scraper.txt"
echo "   pip install -r requirements/dev.txt"
echo ""
echo -e "${BLUE}3. フロントエンド依存関係:${NC}"
echo "   cd frontend && npm install"
echo ""
echo -e "${BLUE}4. 環境変数設定:${NC}"
echo "   .envファイルを編集してOpenAI APIキーを設定"
echo ""
echo -e "${BLUE}5. データベース初期化:${NC}"
echo "   docker-compose up -d db"
echo "   make db-migrate"
echo ""
echo -e "${BLUE}6. 開発サーバー起動:${NC}"
echo "   make dev              # フルシステム"
echo "   make dev-backend      # バックエンドのみ"
echo "   make dev-frontend     # フロントエンドのみ"
echo ""
echo -e "${BLUE}7. スクレイピング実行:${NC}"
echo "   make scrape-test      # テスト実行"
echo "   make scrape          # 本格実行"
echo ""
echo -e "${BLUE}8. コード品質チェック:${NC}"
echo "   make quality         # 全品質チェック"
echo "   make test           # 全テスト実行"
echo ""
echo -e "${YELLOW}💡 ヘルプ:${NC}"
echo "   make help           # 利用可能コマンド一覧"
echo ""
echo -e "${GREEN}✨ 統合開発環境の準備が完了しました！${NC}"