#!/bin/bash

echo "🔧 検索API JSONパースエラーを修正中..."

# 1. 検索APIエンドポイントのスキーマを確認・修正
echo "📝 schemas.pyを確認中..."
docker-compose exec backend python -c "
from app.schemas import SearchRequest
import json

# 現在のSearchRequestスキーマを確認
print('現在のSearchRequestスキーマ:')
print(SearchRequest.schema())

# テストデータでバリデーション
test_data = {'query': '免疫', 'limit': 3}
try:
    request = SearchRequest(**test_data)
    print('✅ スキーマバリデーション成功')
    print(f'パース結果: {request}')
except Exception as e:
    print(f'❌ スキーマバリデーションエラー: {e}')
"

echo ""

# 2. 検索エンドポイントを直接テスト（詳細エラー情報付き）
echo "📡 詳細エラー情報を取得中..."
curl -X POST "http://localhost:8000/api/search/" \
     -H "Content-Type: application/json" \
     -d '{"query":"test","limit":3}' \
     -w "\nHTTP Status: %{http_code}\nTotal time: %{time_total}s\n" \
     -v 2>&1 | head -30

echo ""

# 3. 修正版検索APIテスト（シンプルなクエリ）
echo "🧪 修正版APIテスト..."
echo "シンプルなクエリでテスト:"

# 英語クエリでテスト
curl -X POST "http://localhost:8000/api/search/" \
     -H "Content-Type: application/json; charset=utf-8" \
     -d '{"query":"research","limit":3}' \
     2>/dev/null | jq . 2>/dev/null || echo "エラー: JSON解析不可"

echo ""

# 4. 最小限のAPIデバッグ
echo "🔍 APIエンドポイント最小テスト..."
python3 -c "
import requests
import json

# 最小限のテストデータ
test_data = {'query': 'test', 'limit': 3}

try:
    response = requests.post(
        'http://localhost:8000/api/search/', 
        json=test_data,
        headers={'Content-Type': 'application/json'},
        timeout=10
    )
    
    print(f'Status: {response.status_code}')
    print(f'Headers: {dict(response.headers)}')
    print(f'Response: {response.text[:200]}')
    
    if response.status_code == 200:
        print('✅ API動作確認')
    else:
        print(f'❌ APIエラー: {response.status_code}')
        
except Exception as e:
    print(f'❌ 接続エラー: {e}')
"

echo ""

# 5. バックエンド再起動による修正試行
echo "🔄 バックエンド再起動..."
docker-compose restart backend

echo "⏳ バックエンド起動待機（15秒）..."
sleep 15

# 6. 再起動後のAPIテスト
echo "🧪 再起動後のAPIテスト..."
curl -X POST "http://localhost:8000/api/search/" \
     -H "Content-Type: application/json" \
     -d '{"query":"immune","limit":2}' \
     -w "\nStatus: %{http_code}\n" \
     2>/dev/null | head -10

echo ""

# 7. OpenAI API設定確認
echo "🔑 OpenAI API設定確認..."
docker-compose exec backend python -c "
import os
api_key = os.getenv('OPENAI_API_KEY', 'Not Set')
if api_key and api_key != 'Not Set':
    print(f'✅ OpenAI API Key設定済み (長さ: {len(api_key)}文字)')
else:
    print('❌ OpenAI API Key未設定')
    print('環境変数OPENAI_API_KEYを.envファイルで設定してください')
"

echo ""
echo "✨ 修正完了。結果を確認してください。"