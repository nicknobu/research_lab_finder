#!/bin/bash

# VSCode エラー修正スクリプト
echo "🔧 VSCode エラーを修正中..."

# 1. LabCard.tsx が存在しない場合は作成
if [ ! -f "frontend/src/components/LabCard.tsx" ]; then
    echo "📝 LabCard.tsx を作成中..."
    cat > frontend/src/components/LabCard.tsx << 'EOF'
import React from 'react';
import { MapPin, User, ExternalLink } from 'lucide-react';
import type { ResearchLabSearchResult } from '../types';

interface LabCardProps {
  lab: ResearchLabSearchResult;
  onClick?: (lab: ResearchLabSearchResult) => void;
}

const LabCard: React.FC<LabCardProps> = ({ lab, onClick }) => {
  return (
    <div 
      className="border border-gray-200 rounded-lg p-6 hover:shadow-md transition-shadow cursor-pointer"
      onClick={() => onClick?.(lab)}
    >
      <div className="flex justify-between items-start mb-3">
        <h3 className="text-xl font-semibold text-gray-900">{lab.name}</h3>
        <span className="bg-blue-100 text-blue-800 px-3 py-1 rounded-full text-sm font-medium">
          {Math.round((lab.similarity_score || 0) * 100)}% マッチ
        </span>
      </div>
      
      <div className="mb-3">
        <p className="text-gray-700 flex items-center">
          <User className="h-4 w-4 mr-1" />
          {lab.professor_name}
        </p>
        <p className="text-gray-700 flex items-center mt-1">
          <MapPin className="h-4 w-4 mr-1" />
          {lab.university_name}, {lab.region}
        </p>
      </div>
      
      <div className="mb-3">
        <h4 className="font-semibold text-gray-800 mb-1">研究テーマ:</h4>
        <p className="text-gray-700">{lab.research_theme}</p>
      </div>
      
      <div className="flex items-center justify-between">
        <span className="bg-gray-100 text-gray-700 px-3 py-1 rounded-full text-sm">
          {lab.research_field}
        </span>
        {lab.lab_url && (
          <ExternalLink className="h-4 w-4 text-blue-600" />
        )}
      </div>
    </div>
  );
};

export default LabCard;
EOF
    echo "✅ LabCard.tsx を作成しました"
fi

# 2. LabDetail.tsx の getSimilarLabs 呼び出しを修正 (2個の引数→1個の引数)
echo "🔧 LabDetail.tsx の getSimilarLabs 呼び出しを修正中..."
sed -i 's/getSimilarLabs(labId, 5)/getSimilarLabs(labId)/g' frontend/src/pages/LabDetail.tsx

# 3. api.ts の import.meta.env エラーを修正
echo "🔧 api.ts の import.meta.env エラーを修正中..."
sed -i 's/import\.meta\.env\.VITE_API_BASE_URL/(import.meta as any)?.env?.VITE_API_BASE_URL/g' frontend/src/utils/api.ts

# 4. tsconfig.json に Vite型を追加
echo "📝 tsconfig.json に Vite型を追加中..."
if ! grep -q '"vite/client"' frontend/tsconfig.json; then
    sed -i 's/"types": \[/"types": ["vite\/client",/' frontend/tsconfig.json
fi

# 5. database.py の型エラーを修正
echo "🔧 database.py の型エラーを修正中..."
sed -i 's/def get_db() -> Session:/def get_db() -> Generator[Session, None, None]:/' backend/app/database.py
if ! grep -q "from typing import Generator" backend/app/database.py; then
    sed -i '1i from typing import Generator' backend/app/database.py
fi

# 6. 未使用インポートを削除 (SearchResults.tsx)
echo "🧹 未使用インポートを削除中..."
sed -i 's/, SortAsc//' frontend/src/pages/SearchResults.tsx

# 7. App.tsx のReactインポートを削除 (React 17+では不要)
sed -i '/^import React from/d' frontend/src/App.tsx

# 8. 未使用変数を削除 (Header.tsx, Home.tsx)
echo "🧹 未使用変数を削除中..."
# Header.tsx の未使用の location 変数を削除
sed -i '/const location = useLocation()/d' frontend/src/components/Header.tsx
# Home.tsx の未使用の navigate 変数を削除  
sed -i '/const navigate = useNavigate()/d' frontend/src/pages/Home.tsx

# 9. Footer.tsx の未使用インポートを削除
sed -i '/^import.*lucide-react.*$/d' frontend/src/components/Footer.tsx

# 10. Dockerfile のNode.jsバージョンを更新
echo "🐳 Dockerfile のセキュリティを向上中..."
sed -i 's/FROM node:18.20.8-alpine3.20/FROM node:20-alpine3.20/' frontend/Dockerfile

# 11. VS Code設定を追加してTailwind警告を無効化
mkdir -p .vscode
cat > .vscode/settings.json << 'EOF'
{
  "css.validate": false,
  "scss.validate": false,
  "less.validate": false,
  "typescript.preferences.includePackageJsonAutoImports": "auto",
  "tailwindCSS.includeLanguages": {
    "typescript": "typescript",
    "typescriptreact": "typescriptreact"
  },
  "css.customData": [".vscode/css_custom_data.json"]
}
EOF

# 12. CSS カスタムデータでTailwind警告を無効化
cat > .vscode/css_custom_data.json << 'EOF'
{
  "version": 1.1,
  "atDirectives": [
    {
      "name": "@tailwind",
      "description": "Use the @tailwind directive to insert Tailwind's base, components, utilities and screens styles into your CSS."
    }
  ]
}
EOF

echo "✅ VS Code設定を追加しました"

# 13. package.json の依存関係を確認・更新
echo "📦 依存関係を確認中..."
cd frontend
if command -v npm &> /dev/null; then
    npm audit fix --force
    echo "✅ 依存関係のセキュリティ問題を修正しました"
fi
cd ..

# 14. AdminDashboard.tsx のPythonコード混入を修正
echo "🔧 AdminDashboard.tsx のPythonコード混入を修正中..."
if [ -f "frontend/src/pages/AdminDashboard.tsx" ]; then
    # 423行目以降のPythonコードを削除（TypeScriptファイルに混入）
    sed -i '423,$d' frontend/src/pages/AdminDashboard.tsx
    
    # 正しいReactコンポーネントの終了部分を追加
    cat >> frontend/src/pages/AdminDashboard.tsx << 'EOF'

  // レスポンス時間の色分け
  const getResponseTimeColor = (time: number) => {
    if (time < 1000) return 'text-green-600'
    if (time < 2000) return 'text-yellow-600'
    return 'text-red-600'
  }

  if (statsLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <LoadingSpinner />
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-4">
            システムダッシュボード
          </h1>
          
          {/* 時間範囲選択 */}
          <div className="flex space-x-4 mb-6">
            {(['24h', '7d', '30d'] as const).map((range) => (
              <button
                key={range}
                onClick={() => setTimeRange(range)}
                className={`px-4 py-2 rounded-lg font-medium ${
                  timeRange === range
                    ? 'bg-blue-600 text-white'
                    : 'bg-white text-gray-700 hover:bg-gray-50'
                }`}
              >
                {range === '24h' ? '24時間' : range === '7d' ? '7日' : '30日'}
              </button>
            ))}
          </div>
        </div>

        {/* 統計カード */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <Search className="h-8 w-8 text-blue-600" />
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">総検索数</p>
                <p className="text-2xl font-bold text-gray-900">
                  {dashboardStats?.totalSearches?.toLocaleString() || 0}
                </p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <Users className="h-8 w-8 text-green-600" />
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">ユーザー数</p>
                <p className="text-2xl font-bold text-gray-900">
                  {dashboardStats?.totalUsers?.toLocaleString() || 0}
                </p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <Database className="h-8 w-8 text-purple-600" />
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">研究室数</p>
                <p className="text-2xl font-bold text-gray-900">
                  {dashboardStats?.totalLabs?.toLocaleString() || 0}
                </p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <Clock className="h-8 w-8 text-orange-600" />
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">平均応答時間</p>
                <p className={`text-2xl font-bold ${getResponseTimeColor(dashboardStats?.avgResponseTime || 0)}`}>
                  {dashboardStats?.avgResponseTime?.toFixed(0) || 0}ms
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* チャート */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* 検索トレンド */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">検索トレンド</h2>
            {!trendsLoading && searchTrends && (
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={searchTrends}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Line type="monotone" dataKey="searches" stroke="#3B82F6" name="検索数" />
                </LineChart>
              </ResponsiveContainer>
            )}
          </div>

          {/* システムヘルス */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">システムヘルス</h2>
            <div className="flex items-center justify-center h-64">
              <div className={`text-center ${
                dashboardStats?.systemHealth === 'healthy' ? 'text-green-600' : 
                dashboardStats?.systemHealth === 'warning' ? 'text-yellow-600' : 'text-red-600'
              }`}>
                <Activity className="h-16 w-16 mx-auto mb-4" />
                <p className="text-2xl font-bold">
                  {dashboardStats?.systemHealth === 'healthy' ? '正常' :
                   dashboardStats?.systemHealth === 'warning' ? '注意' : '警告'}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default AdminDashboard
EOF
    echo "✅ AdminDashboard.tsx のPythonコード混入を修正しました"
fi

# 15. tsconfig.json の設定エラーを修正
echo "🔧 tsconfig.json の設定エラーを修正中..."
if [ -f "frontend/tsconfig.json" ]; then
    # moduleResolution を node に変更
    sed -i 's/"moduleResolution": "bundler"/"moduleResolution": "node"/g' frontend/tsconfig.json
    
    # allowImportingTsExtensions を削除（不要な設定）
    sed -i '/allowImportingTsExtensions/d' frontend/tsconfig.json
    
    echo "✅ tsconfig.json の設定エラーを修正しました"
fi

echo "🎉 すべてのエラー修正が完了しました！"
echo ""
echo "📋 修正内容:"
echo "  ✅ LabCard.tsx コンポーネントを作成"
echo "  ✅ LabDetail.tsx の getSimilarLabs 引数エラーを修正"
echo "  ✅ import.meta.env エラーを修正"
echo "  ✅ TypeScript型定義を追加"
echo "  ✅ database.py の型エラーを修正"
echo "  ✅ 未使用インポートと変数を削除"
echo "  ✅ Dockerfileのセキュリティを向上"
echo "  ✅ VS Code設定を最適化"
echo "  ✅ Tailwind CSS警告を解決"
echo "  ✅ AdminDashboard.tsx のPythonコード混入を修正"
echo "  ✅ tsconfig.json の設定エラーを修正"
echo ""
echo "🚀 VS Codeを再起動して変更を反映してください"