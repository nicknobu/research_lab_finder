#!/bin/bash

set -e

echo "��� 研究室ファインダー - セットアップ開始"

# カラーコード
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 必要なツールの確認
check_requirements() {
    echo -e "${BLUE}��� 必要なツールの確認中...${NC}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Dockerがインストールされていません${NC}"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ Docker Composeがインストールされていません${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 必要なツールが揃っています${NC}"
}

# 環境変数ファイルの確認・作成
setup_env() {
    echo -e "${BLUE}��� 環境変数の設定中...${NC}"
    
    if [ ! -f .env ]; then
        echo -e "${YELLOW}⚠️ .envファイルが見つかりません。.env.exampleからコピーしています...${NC}"
        cp .env.example .env
        echo -e "${YELLOW}��� .envファイルを編集してOpenAI APIキーを設定してください${NC}"
        
        read -p "今すぐOpenAI APIキーを入力しますか？ (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -p "OpenAI APIキーを入力してください: " api_key
            if [ ! -z "$api_key" ]; then
                sed -i.bak "s/your_openai_api_key_here/$api_key/" .env
                echo -e "${GREEN}✅ OpenAI APIキーが設定されました${NC}"
            fi
        fi
    else
        echo -e "${GREEN}✅ .envファイルが存在します${NC}"
    fi
}

# Docker環境の構築
build_docker() {
    echo -e "${BLUE}��� Docker環境の構築中...${NC}"
    
    echo "既存のコンテナを停止中..."
    docker-compose down -v 2>/dev/null || true
    
    echo "Dockerイメージをビルド中..."
    docker-compose build --no-cache
    
    echo -e "${GREEN}✅ Docker環境の構築完了${NC}"
}

# データベースの初期化
init_database() {
    echo -e "${BLUE}��� データベースの初期化中...${NC}"
    
    echo "データベースコンテナを起動中..."
    docker-compose up -d db
    
    echo "データベースの起動を待機中..."
    sleep 10
    
    max_attempts=30
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if docker-compose exec -T db pg_isready -U postgres > /dev/null 2>&1; then
            echo -e "${GREEN}✅ データベースに接続できました${NC}"
            break
        fi
        echo "データベース接続試行 $attempt/$max_attempts..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        echo -e "${RED}❌ データベースへの接続がタイムアウトしました${NC}"
        exit 1
    fi
}

# アプリケーションの起動
start_application() {
    echo -e "${BLUE}��� アプリケーションの起動中...${NC}"
    
    docker-compose up -d
    
    echo "サービスの起動確認中..."
    sleep 15
    
    max_attempts=20
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost:8000/health > /dev/null 2>&1; then
            echo -e "${GREEN}✅ バックエンドAPIが起動しました${NC}"
            break
        fi
        echo "バックエンドAPI起動確認 $attempt/$max_attempts..."
        sleep 3
        attempt=$((attempt + 1))
    done
    
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost:3000 > /dev/null 2>&1; then
            echo -e "${GREEN}✅ フロントエンドが起動しました${NC}"
            break
        fi
        echo "フロントエンド起動確認 $attempt/$max_attempts..."
        sleep 3
        attempt=$((attempt + 1))
    done
}

# 成功メッセージの表示
show_success() {
    echo -e "${GREEN}"
    echo "��� セットアップ完了！"
    echo "==============================================="
    echo "��� フロントエンド: http://localhost:3000"
    echo "��� バックエンドAPI: http://localhost:8000"
    echo "��� API文書: http://localhost:8000/docs"
    echo "==============================================="
    echo ""
    echo "��� 使用方法:"
    echo "  • ブラウザで http://localhost:3000 にアクセス"
    echo "  • 興味のある分野を自由に入力して検索"
    echo "  • AI推奨システムが関連研究室を表示"
    echo ""
    echo "��️ 管理コマンド:"
    echo "  • 停止: docker-compose down"
    echo "  • 再起動: docker-compose restart"
    echo "  • ログ確認: docker-compose logs -f"
    echo "${NC}"
}

# エラーハンドリング
error_handler() {
    echo -e "${RED}❌ セットアップ中にエラーが発生しました${NC}"
    echo "ログを確認してください: docker-compose logs"
    exit 1
}

trap error_handler ERR

# メイン実行
main() {
    echo -e "${BLUE}研究室ファインダー 自動セットアップスクリプト${NC}"
    echo "============================================="
    
    check_requirements
    setup_env
    build_docker
    init_database
    start_application
    show_success
}

# スクリプト実行
main "$@"
