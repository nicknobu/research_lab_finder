#!/bin/bash
# 研究室ファインダー API テストスクリプト

echo "🔬 研究室ファインダー API テスト開始"
echo "=================================="

# Python環境の確認
echo "📍 Python環境の確認中..."
echo "Python version: $(python --version 2>&1)"
echo "Python3 version: $(python3 --version 2>&1)"
echo "pip version: $(pip --version 2>&1)"

# requestsライブラリの確認
echo -e "\n📦 requestsライブラリの確認中..."

# 方法1: pipで正しいPython環境にインストール
echo "正しいPython環境にrequestsをインストール中..."
python -m pip install requests

# 方法2: 念のためpython3でも試行
python3 -m pip install requests

echo -e "\n🧪 APIテスト実行中..."

# テストケース1: ヘルスチェック
echo "1. ヘルスチェック..."
curl -f http://localhost:8000/health && echo " ✅ ヘルスチェック成功" || echo " ❌ ヘルスチェック失敗"

# テストケース2: セマンティック検索（修正版）
echo -e "\n2. セマンティック検索テスト..."

# Python環境を特定してテスト実行
python -c "
import sys
print(f'Using Python: {sys.executable}')

try:
    import requests
    print('✅ requests module imported successfully')
    
    # がん治療研究のテスト
    print('\n🔍 がん治療研究の検索テスト...')
    response = requests.post(
        'http://localhost:8000/api/search/', 
        json={'query': 'がん治療', 'limit': 3},
        timeout=10
    )
    
    print(f'Status Code: {response.status_code}')
    
    if response.status_code == 200:
        data = response.json()
        print(f'✅ 検索成功!')
        print(f'   総結果数: {data.get(\"total_results\", 0)}')
        print(f'   検索時間: {data.get(\"search_time_ms\", 0):.2f}ms')
        
        if data.get('results'):
            print(f'   最初の結果:')
            first_result = data['results'][0]
            print(f'     研究室名: {first_result.get(\"name\", \"N/A\")}')
            print(f'     教授名: {first_result.get(\"professor_name\", \"N/A\")}')
            print(f'     大学: {first_result.get(\"university_name\", \"N/A\")}')
            print(f'     類似度: {first_result.get(\"similarity_score\", 0):.3f}')
        else:
            print('   結果なし')
    else:
        print(f'❌ エラー: {response.status_code}')
        print(f'   Response: {response.text}')
        
except ImportError as e:
    print(f'❌ Import Error: {e}')
    print('requests module not found. Please install it with:')
    print('  python -m pip install requests')
except requests.exceptions.ConnectionError:
    print('❌ Connection Error: APIサーバーが起動していません')
    print('以下のコマンドでサーバーを起動してください:')
    print('  docker-compose up -d')
except Exception as e:
    print(f'❌ Unexpected Error: {e}')
" 2>/dev/null

# python3でも試行（フォールバック）
if [ $? -ne 0 ]; then
    echo -e "\npython失敗、python3で再試行..."
    python3 -c "
import sys
print(f'Using Python3: {sys.executable}')

try:
    import requests
    print('✅ requests module imported successfully with python3')
    
    response = requests.post(
        'http://localhost:8000/api/search/', 
        json={'query': 'がん治療', 'limit': 3},
        timeout=10
    )
    
    print(f'Status Code: {response.status_code}')
    
    if response.status_code == 200:
        data = response.json()
        print(f'✅ 検索成功!')
        print(f'   総結果数: {data.get(\"total_results\", 0)}')
        
except ImportError as e:
    print(f'❌ Import Error with python3: {e}')
except Exception as e:
    print(f'❌ Error with python3: {e}')
"
fi

echo -e "\n🌐 追加テスト: cURLでの直接テスト"
echo "3. cURLでのセマンティック検索..."
curl -X POST http://localhost:8000/api/search/ \
  -H "Content-Type: application/json" \
  -d '{"query":"がん治療","limit":3}' \
  -w "\nResponse time: %{time_total}s\n" 2>/dev/null && echo "✅ cURL test successful" || echo "❌ cURL test failed"

echo -e "\n4. 研究室詳細取得テスト..."
curl -f http://localhost:8000/api/labs/1 2>/dev/null && echo " ✅ 研究室詳細取得成功" || echo " ❌ 研究室詳細取得失敗"

echo -e "\n🎯 テスト完了"
echo "=================================="
echo "💡 ヒント:"
echo "  - APIが動作しない場合: docker-compose up -d"
echo "  - フロントエンド確認: http://localhost:3000"
echo "  - API文書確認: http://localhost:8000/docs"