#!/bin/bash

# 🔬 研究室ファインダー - 統合プロジェクトセットアップスクリプト（Python 3.9対応版）
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
echo "   (Python 3.9対応版)"
echo "============================================== 🔬"
echo -e "${NC}"

# 前提条件チェック
echo -e "${YELLOW}📋 前提条件チェック${NC}"

# Python バージョンチェック（3.9以上に変更）
python_version=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
required_version="3.9"

if ! python3 -c "import sys; exit(0 if sys.version_info >= (3, 9) else 1)" 2>/dev/null; then
    echo -e "${RED}❌ Python 3.9以上が必要です。現在: ${python_version}${NC}"
    echo -e "${YELLOW}💡 Python アップグレード手順については後述します${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Python ${python_version}${NC}"

# Python 3.11推奨の案内
if ! python3 -c "import sys; exit(0 if sys.version_info >= (3, 11) else 1)" 2>/dev/null; then
    echo -e "${YELLOW}⚠️ Python 3.11以上を推奨します（現在: ${python_version}）${NC}"
    echo -e "${YELLOW}💡 一部の最新機能が制限される可能性があります${NC}"
    read -p "Python 3.9で続行しますか？ (y/N): " continue_with_39
    if [[ ! $continue_with_39 =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Python 3.11のインストール手順を表示します${NC}"
        show_python_upgrade_guide
        exit 0
    fi
    echo -e "${GREEN}✅ Python 3.9で続行します${NC}"
fi

# Node.js チェック
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js が見つかりません${NC}"
    echo -e "${YELLOW}💡 Node.js インストール手順については後述します${NC}"
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
mkdir -p logs

# __init__.py ファイル作成
find scraper -type d -exec touch {}/__init__.py \;

echo -e "${GREEN}✅ ディレクトリ構造作成完了${NC}"

# ==================== 依存関係ファイル配置案内 ====================
echo -e "${BLUE}📦 依存関係ファイル配置案内${NC}"

# 既存のbackend/requirements.txtをバックアップ
if [ -f "backend/requirements.txt" ]; then
    cp backend/requirements.txt backend/requirements.txt.backup
    echo -e "${YELLOW}📄 既存backend/requirements.txtをバックアップしました${NC}"
fi

echo -e "${YELLOW}📝 requirements/ ディレクトリを作成しました${NC}"
echo -e "${YELLOW}💡 Claude が作成した依存関係ファイルを以下に配置してください:${NC}"
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
# 🔬 研究室ファインダー統合プロジェクト設定（Python 3.9対応）

# ==================== 環境設定 ====================
ENVIRONMENT=development
DEBUG=true
TESTING=false
PYTHON_VERSION=3.9

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

# ==================== Python 3.9 互換性設定 ====================
# 型ヒント互換性
PYTHONPATH=${PYTHONPATH}:./scraper
MYPY_PYTHON_VERSION=3.9
EOF

# .env作成（開発用）
if [ ! -f ".env" ]; then
    cp .env.integrated.example .env
    echo -e "${GREEN}✅ 開発用.envファイルを作成しました${NC}"
else
    echo -e "${YELLOW}⚠️ 既存の.envファイルが存在します${NC}"
fi

# ==================== Git設定更新 ====================
echo -e "${BLUE}📝 Git設定更新${NC}"

# .gitignore更新
if ! grep -q "# スクレイピング関連" .gitignore 2>/dev/null; then
    echo "
# スクレイピング関連
scraper/logs/
scraper/cache/
scraped_data/
*.scraped

# 統合プロジェクト
requirements/*.lock
.coverage
htmlcov/
.python-version" >> .gitignore
    echo -e "${GREEN}✅ .gitignore を更新しました${NC}"
else
    echo -e "${YELLOW}📄 .gitignore は既に更新済みです${NC}"
fi

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
echo -e "${BLUE}2. 依存関係ファイル配置:${NC}"
echo "   Claude が作成した requirements/*.txt ファイルを配置"
echo ""
echo -e "${BLUE}3. 依存関係インストール:${NC}"
echo "   # 基本的な依存関係"
echo "   pip install --upgrade pip"
echo "   pip install -r requirements/base.txt"
echo "   pip install -r requirements/backend.txt"
echo "   pip install -r requirements/scraper.txt"
echo ""
echo -e "${BLUE}4. フロントエンド依存関係:${NC}"
echo "   cd frontend && npm install && cd .."
echo ""
echo -e "${BLUE}5. 環境変数設定:${NC}"
echo "   .envファイルを編集してOpenAI APIキーを設定"
echo ""
echo -e "${BLUE}6. 既存システム確認:${NC}"
echo "   docker-compose up -d"
echo "   curl http://localhost:8000/health"
echo ""
echo -e "${YELLOW}💡 Python 3.9での制限事項:${NC}"
echo "   • 一部の最新型ヒント機能が使用できません"
echo "   • パフォーマンスが若干劣る可能性があります"
echo "   • 将来的にPython 3.11以上への更新を推奨します"
echo ""
echo -e "${GREEN}✨ 準備完了！Claude の作成したファイルを配置してください${NC}"

# ==================== Python アップグレードガイド関数 ====================
show_python_upgrade_guide() {
    echo ""
    echo -e "${BLUE}🐍 Python 3.11 インストール手順${NC}"
    echo ""
    
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo -e "${YELLOW}Windows (Git Bash):${NC}"
        echo "1. https://www.python.org/downloads/ から Python 3.11 をダウンロード"
        echo "2. インストーラーを実行"
        echo "3. 「Add Python to PATH」にチェック"
        echo "4. Git Bash を再起動"
        echo "5. python3 --version で確認"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${YELLOW}macOS:${NC}"
        echo "# Homebrew使用"
        echo "brew install python@3.11"
        echo "brew link python@3.11"
        echo ""
        echo "# または pyenv使用"
        echo "brew install pyenv"
        echo "pyenv install 3.11.6"
        echo "pyenv global 3.11.6"
    else
        echo -e "${YELLOW}Linux (Ubuntu/Debian):${NC}"
        echo "# APT使用"
        echo "sudo apt update"
        echo "sudo apt install python3.11 python3.11-venv python3.11-pip"
        echo ""
        echo "# または pyenv使用"
        echo "curl https://pyenv.run | bash"
        echo "pyenv install 3.11.6"
        echo "pyenv global 3.11.6"
    fi
    echo ""
}

# スクリプト実行確認
echo -e "${GREEN}🔧 セットアップスクリプト実行完了${NC}"