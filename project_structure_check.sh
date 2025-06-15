#!/bin/bash

echo "🔍 プロジェクト構造を確認中..."
echo "📂 現在のディレクトリ: $(pwd)"
echo ""

echo "📋 プロジェクト構造:"
ls -la

echo ""
echo "🔧 正しいコマンド実行方法:"
echo ""

# フロントエンドの確認
if [ -d "frontend" ]; then
    echo "✅ frontend ディレクトリが存在"
    if [ -f "frontend/package.json" ]; then
        echo "✅ frontend/package.json が存在"
        echo "   🚀 フロントエンド開発サーバー起動:"
        echo "   cd frontend && npm run dev"
    else
        echo "❌ frontend/package.json が見つかりません"
    fi
else
    echo "❌ frontend ディレクトリが見つかりません"
fi

echo ""

# バックエンドの確認
if [ -d "backend" ]; then
    echo "✅ backend ディレクトリが存在"
    if [ -f "backend/app/main.py" ]; then
        echo "✅ backend/app/main.py が存在"
        echo "   🚀 バックエンド開発サーバー起動:"
        echo "   cd backend && python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"
    else
        echo "❌ backend/app/main.py が見つかりません"
    fi
else
    echo "❌ backend ディレクトリが見つかりません"
fi

echo ""

# Docker Composeの確認
if [ -f "docker-compose.yml" ]; then
    echo "✅ docker-compose.yml が存在"
    echo "   🐳 Docker環境起動:"
    echo "   docker-compose up --build"
    echo ""
    echo "📡 Docker環境のアクセス先:"
    echo "   http://localhost:3000  (フロントエンド)"
    echo "   http://localhost:8000  (バックエンド API)"
    echo "   http://localhost:8080  (Adminer データベース管理)"
else
    echo "❌ docker-compose.yml が見つかりません"
fi

echo ""
echo "🎯 推奨開発手順:"
echo ""
echo "1. Docker環境で動作確認:"
echo "   docker-compose up --build"
echo "   ブラウザで http://localhost:3000 を確認"
echo ""
echo "2. ローカル開発環境:"
echo "   # フロントエンド"
echo "   cd frontend"
echo "   npm run dev"
echo ""
echo "   # バックエンド（別ターミナル）"
echo "   cd backend"  
echo "   python -m uvicorn app.main:app --reload"
echo ""

# Docker コンテナの状態確認
echo "🐳 現在のDockerコンテナ状態:"
docker ps --filter "name=research_lab" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "Dockerコンテナが起動していません"