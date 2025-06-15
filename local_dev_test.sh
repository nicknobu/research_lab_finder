#!/bin/bash

echo "🧪 ローカル開発環境をテスト中..."
echo ""

# 1. フロントエンドテスト
echo "📱 フロントエンドテスト:"
if [ -d "frontend" ]; then
    cd frontend
    echo "  📂 frontend ディレクトリに移動"
    
    if [ -f "package.json" ]; then
        echo "  ✅ package.json 確認"
        
        # npm がインストールされているか確認
        if command -v npm &> /dev/null; then
            echo "  ✅ npm が利用可能"
            
            # node_modules が存在するか確認
            if [ -d "node_modules" ]; then
                echo "  ✅ node_modules が存在"
            else
                echo "  ⚠️  node_modules が見つかりません。インストール中..."
                npm install
            fi
            
            # type-check テスト
            echo "  🔍 TypeScript型チェック実行中..."
            if npm run type-check; then
                echo "  ✅ TypeScript型チェック成功"
            else
                echo "  ❌ TypeScript型チェックでエラー"
            fi
            
            # ビルドテスト
            echo "  🏗️  ビルドテスト実行中..."
            if npm run build; then
                echo "  ✅ ビルド成功"
            else
                echo "  ❌ ビルドでエラー"
            fi
            
        else
            echo "  ❌ npm が見つかりません"
        fi
    else
        echo "  ❌ package.json が見つかりません"
    fi
    cd ..
else
    echo "  ❌ frontend ディレクトリが見つかりません"
fi

echo ""

# 2. バックエンドテスト
echo "🐍 バックエンドテスト:"
if [ -d "backend" ]; then
    cd backend
    echo "  📂 backend ディレクトリに移動"
    
    if [ -f "app/main.py" ]; then
        echo "  ✅ app/main.py 確認"
        
        # Python がインストールされているか確認
        if command -v python &> /dev/null; then
            echo "  ✅ Python が利用可能"
            echo "  🐍 Python バージョン: $(python --version)"
            
            # 依存関係確認
            if [ -f "requirements.txt" ]; then
                echo "  ✅ requirements.txt 確認"
                
                # 主要パッケージの確認
                echo "  🔍 主要パッケージの確認中..."
                python -c "
import sys
packages = ['fastapi', 'uvicorn', 'sqlalchemy', 'psycopg2', 'openai']
missing = []
for pkg in packages:
    try:
        __import__(pkg)
        print(f'  ✅ {pkg}')
    except ImportError:
        print(f'  ❌ {pkg} (未インストール)')
        missing.append(pkg)
        
if missing:
    print(f'\\n  ⚠️  不足パッケージ: {missing}')
    print(f'  💡 インストールコマンド: pip install {\" \".join(missing)}')
else:
    print('\\n  🎉 すべての主要パッケージがインストール済み')
"
                
            else
                echo "  ❌ requirements.txt が見つかりません"
            fi
            
        else
            echo "  ❌ Python が見つかりません"
        fi
    else
        echo "  ❌ app/main.py が見つかりません"
    fi
    cd ..
else
    echo "  ❌ backend ディレクトリが見つかりません"
fi

echo ""

# 3. 環境変数確認
echo "🔧 環境変数確認:"
if [ -f ".env" ]; then
    echo "  ✅ .env ファイルが存在"
    
    # OpenAI API Key の確認（値は表示しない）
    if grep -q "OPENAI_API_KEY" .env; then
        if grep "OPENAI_API_KEY=" .env | grep -q "sk-"; then
            echo "  ✅ OPENAI_API_KEY が設定済み"
        else
            echo "  ⚠️  OPENAI_API_KEY が未設定または無効"
        fi
    else
        echo "  ❌ OPENAI_API_KEY が見つかりません"
    fi
    
    # DATABASE_URL の確認
    if grep -q "DATABASE_URL" .env; then
        echo "  ✅ DATABASE_URL が設定済み"
    else
        echo "  ❌ DATABASE_URL が見つかりません"
    fi
    
else
    echo "  ❌ .env ファイルが見つかりません"
    if [ -f ".env.example" ]; then
        echo "  💡 .env.example をコピーして .env を作成してください:"
        echo "     cp .env.example .env"
    fi
fi

echo ""

# 4. Docker環境の詳細確認
echo "🐳 Docker環境詳細確認:"
echo "  📊 コンテナ状態:"
docker ps --filter "name=research_lab" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  ❌ Docker が起動していません"

echo ""
echo "  🔍 バックエンドログ確認 (最新10行):"
docker logs research_lab_backend --tail 10 2>/dev/null || echo "  ❌ バックエンドコンテナのログを取得できません"

echo ""

# 5. APIテスト
echo "🌐 API接続テスト:"
if command -v curl &> /dev/null; then
    echo "  🔍 バックエンドヘルスチェック..."
    if curl -s http://localhost:8000/health > /dev/null; then
        echo "  ✅ バックエンドAPI (http://localhost:8000) 応答"
        curl -s http://localhost:8000/health | head -3
    else
        echo "  ❌ バックエンドAPI (http://localhost:8000) 応答なし"
    fi
    
    echo "  🔍 フロントエンド接続確認..."
    if curl -s http://localhost:3000 > /dev/null; then
        echo "  ✅ フロントエンド (http://localhost:3000) 応答"
    else
        echo "  ❌ フロントエンド (http://localhost:3000) 応答なし"
    fi
else
    echo "  ⚠️  curl が見つかりません。手動でブラウザ確認してください:"
    echo "     http://localhost:3000 (フロントエンド)"
    echo "     http://localhost:8000/health (バックエンドAPI)"
fi

echo ""
echo "🎯 推奨対応順序:"
echo "1. ブラウザで http://localhost:3000 を確認"
echo "2. バックエンドの問題があれば Docker ログを確認"
echo "3. ローカル開発は frontend ディレクトリで 'npm run dev'"