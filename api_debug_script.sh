# 🔍 API詳細エラー診断スクリプト

echo "🔍 API詳細エラー診断開始"

# ==================== 1. バックエンドログ確認 ====================
echo "=== バックエンドログ確認 ==="
echo "最新の20行のログ："
docker-compose logs backend | tail -20

echo ""

# ==================== 2. 詳細エラー情報取得 ====================
echo "=== 詳細APIエラー情報 ==="
curl -X POST http://localhost:8000/api/search/ \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"query":"test","limit":3}' \
  -w "\nHTTP Status: %{http_code}\nTotal time: %{time_total}s\n" \
  -s -S 2>&1

echo ""

# ==================== 3. APIドキュメント確認 ====================
echo "=== API仕様確認 ==="
echo "Swagger UIを確認してください: http://localhost:8000/docs"
curl -s http://localhost:8000/docs | grep -o '<title>[^<]*</title>' || echo "Swagger UI確認必要"

echo ""

# ==================== 4. Python経由での安全なテスト ====================
echo "=== Python経由でのAPIテスト ==="
python3 -c "
import requests
import json

# 安全なテストデータ
test_data = {'query': 'immunology', 'limit': 3}

try:
    # POSTリクエスト送信
    response = requests.post(
        'http://localhost:8000/api/search/', 
        json=test_data,
        headers={'Content-Type': 'application/json'},
        timeout=10
    )
    
    print(f'Status Code: {response.status_code}')
    print(f'Response Headers: {dict(response.headers)}')
    print(f'Response Text: {response.text[:500]}')  # 最初の500文字
    
    if response.status_code == 200:
        print('✅ API動作確認成功')
        try:
            data = response.json()
            print(f'結果数: {len(data.get(\"results\", []))}')
        except:
            print('JSON解析できませんでした')
    else:
        print(f'❌ APIエラー: {response.status_code}')
        
except requests.exceptions.RequestException as e:
    print(f'❌ 接続エラー: {e}')
except Exception as e:
    print(f'❌ 予期しないエラー: {e}')
"

echo ""

# ==================== 5. 動作中のAPIエンドポイント一覧 ====================
echo "=== 利用可能なAPIエンドポイント ==="
echo "以下のエンドポイントをテスト："

# ヘルスチェック
echo "1. ヘルスチェック:"
curl -s http://localhost:8000/health | jq . 2>/dev/null || curl -s http://localhost:8000/health

echo ""

# 大学一覧
echo "2. 大学一覧:"
curl -s http://localhost:8000/api/universities/ | head -200 | jq . 2>/dev/null || echo "大学APIテスト"

echo ""

# 研究室詳細（ID=1）
echo "3. 研究室詳細（ID=1）:"
curl -s http://localhost:8000/api/labs/1 | jq . 2>/dev/null || curl -s http://localhost:8000/api/labs/1

echo ""

# ==================== 6. OpenAI API設定確認 ====================
echo "=== OpenAI API設定確認 ==="
python3 -c "
import os
api_key = os.getenv('OPENAI_API_KEY', 'Not Set')
if api_key and api_key != 'Not Set':
    print(f'✅ OpenAI API Key設定済み (長さ: {len(api_key)}文字)')
    print(f'キープレフィックス: {api_key[:10]}...')
else:
    print('❌ OpenAI API Key未設定')
    print('環境変数OPENAI_API_KEYを設定してください')
"

echo ""

# ==================== 7. セマンティック検索可能性診断 ====================
echo "=== セマンティック検索診断 ==="
echo "問題の可能性:"
echo "1. OpenAI APIキー未設定"
echo "2. JSONリクエスト形式の問題"
echo "3. 日本語文字エンコーディング"
echo "4. APIエンドポイント仕様変更"

echo ""
echo "✨ 診断完了。上記の結果を確認してください。"