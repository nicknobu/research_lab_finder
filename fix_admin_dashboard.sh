#!/bin/bash

echo "🔧 AdminDashboard.tsx を完全に修正中..."

# 既存のAdminDashboard.tsxを削除
rm -f frontend/src/pages/AdminDashboard.tsx

# 新しいAdminDashboard.tsxを作成
cat > frontend/src/pages/AdminDashboard.tsx << 'EOF'
// frontend/src/pages/AdminDashboard.tsx
import React, { useState, useEffect } from 'react'
import { useQuery } from 'react-query'
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend,
  ResponsiveContainer
} from 'recharts'
import {
  Activity, Users, Search, Database, AlertTriangle,
  Clock, Zap
} from 'lucide-react'

// 型定義
interface DashboardStats {
  totalSearches: number
  totalUsers: number
  totalLabs: number
  avgResponseTime: number
  systemHealth: 'healthy' | 'warning' | 'critical'
}

interface SearchTrend {
  date: string
  searches: number
  avgResponseTime: number
}

interface PopularQuery {
  query: string
  count: number
  avgSimilarity: number
}

// モックAPI関数（実際のAPIが未実装の場合）
const getSystemStats = async (timeRange: string): Promise<DashboardStats> => {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        totalSearches: Math.floor(Math.random() * 10000) + 1000,
        totalUsers: Math.floor(Math.random() * 500) + 100,
        totalLabs: Math.floor(Math.random() * 50) + 20,
        avgResponseTime: Math.floor(Math.random() * 1000) + 200,
        systemHealth: 'healthy'
      })
    }, 500)
  })
}

const getSearchStats = async (timeRange: string): Promise<SearchTrend[]> => {
  return new Promise((resolve) => {
    setTimeout(() => {
      const data = Array.from({ length: 24 }, (_, i) => ({
        date: `${23 - i}:00`,
        searches: Math.floor(Math.random() * 100) + 10,
        avgResponseTime: Math.floor(Math.random() * 500) + 200
      })).reverse()
      resolve(data)
    }, 500)
  })
}

const getPopularQueries = async (timeRange: string): Promise<PopularQuery[]> => {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve([
        { query: '機械学習 研究', count: 156, avgSimilarity: 0.85 },
        { query: 'がん治療 免疫療法', count: 142, avgSimilarity: 0.82 },
        { query: 'AI 自然言語処理', count: 128, avgSimilarity: 0.79 },
        { query: '再生医療 幹細胞', count: 98, avgSimilarity: 0.76 },
        { query: 'ロボット工学', count: 87, avgSimilarity: 0.73 }
      ])
    }, 500)
  })
}

const AdminDashboard: React.FC = () => {
  const [timeRange, setTimeRange] = useState<'24h' | '7d' | '30d'>('24h')
  const [refreshInterval, setRefreshInterval] = useState(30000) // 30秒

  // リアルタイムデータ取得
  const { data: dashboardStats, isLoading: statsLoading } = useQuery<DashboardStats>(
    ['dashboardStats', timeRange],
    () => getSystemStats(timeRange),
    {
      refetchInterval: refreshInterval,
      refetchIntervalInBackground: true
    }
  )

  const { data: searchTrends, isLoading: trendsLoading } = useQuery<SearchTrend[]>(
    ['searchTrends', timeRange],
    () => getSearchStats(timeRange),
    {
      refetchInterval: refreshInterval
    }
  )

  const { data: popularQueries, isLoading: queriesLoading } = useQuery<PopularQuery[]>(
    ['popularQueries', timeRange],
    () => getPopularQueries(timeRange),
    {
      refetchInterval: refreshInterval
    }
  )

  // レスポンス時間の色分け
  const getResponseTimeColor = (time: number) => {
    if (time < 1000) return 'text-green-600'
    if (time < 2000) return 'text-yellow-600'
    return 'text-red-600'
  }

  const getSystemHealthColor = (health: string) => {
    switch (health) {
      case 'healthy': return 'text-green-600 bg-green-50'
      case 'warning': return 'text-yellow-600 bg-yellow-50'
      case 'critical': return 'text-red-600 bg-red-50'
      default: return 'text-gray-600 bg-gray-50'
    }
  }

  const getSystemHealthText = (health: string) => {
    switch (health) {
      case 'healthy': return '正常'
      case 'warning': return '注意'
      case 'critical': return '警告'
      default: return '不明'
    }
  }

  if (statsLoading && !dashboardStats) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">ダッシュボードを読み込み中...</p>
        </div>
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
                className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                  timeRange === range
                    ? 'bg-blue-600 text-white'
                    : 'bg-white text-gray-700 hover:bg-gray-50 border border-gray-300'
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
                  {statsLoading ? '...' : dashboardStats?.totalSearches?.toLocaleString() || 0}
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
                  {statsLoading ? '...' : dashboardStats?.totalUsers?.toLocaleString() || 0}
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
                  {statsLoading ? '...' : dashboardStats?.totalLabs?.toLocaleString() || 0}
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
                  {statsLoading ? '...' : `${dashboardStats?.avgResponseTime?.toFixed(0) || 0}ms`}
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* システムヘルス */}
        <div className="bg-white rounded-lg shadow p-6 mb-8">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">
            システムヘルス
          </h2>
          <div className={`rounded-lg p-4 ${getSystemHealthColor(dashboardStats?.systemHealth || 'healthy')}`}>
            <div className="flex items-center">
              <Activity className="h-6 w-6 mr-3" />
              <div>
                <p className="font-medium">
                  システム状況: {getSystemHealthText(dashboardStats?.systemHealth || 'healthy')}
                </p>
                <p className="text-sm mt-1">
                  {dashboardStats?.systemHealth === 'healthy' && 'すべてのシステムが正常に動作しています'}
                  {dashboardStats?.systemHealth === 'warning' && '一部のシステムで軽微な問題が発生しています'}
                  {dashboardStats?.systemHealth === 'critical' && '重要なシステムで問題が発生しています'}
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* チャート */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          {/* 検索トレンド */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">検索トレンド</h2>
            {trendsLoading ? (
              <div className="h-64 flex items-center justify-center">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
              </div>
            ) : (
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

          {/* 応答時間トレンド */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">応答時間トレンド</h2>
            {trendsLoading ? (
              <div className="h-64 flex items-center justify-center">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-green-600"></div>
              </div>
            ) : (
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={searchTrends}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Line type="monotone" dataKey="avgResponseTime" stroke="#10B981" name="応答時間(ms)" />
                </LineChart>
              </ResponsiveContainer>
            )}
          </div>
        </div>

        {/* 人気検索クエリ */}
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">
            人気検索クエリ (過去{timeRange})
          </h2>
          {queriesLoading ? (
            <div className="animate-pulse">
              {Array.from({ length: 5 }).map((_, i) => (
                <div key={i} className="h-12 bg-gray-200 rounded mb-2"></div>
              ))}
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      検索クエリ
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      検索回数
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      平均類似度
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {popularQueries?.map((query, index) => (
                    <tr key={index}>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {query.query}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {query.count}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {(query.avgSimilarity * 100).toFixed(1)}%
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

export default AdminDashboard
EOF

echo "✅ AdminDashboard.tsx を完全に修正しました"

# react-queryが未インストールの場合はuseState/useEffectで代替
if ! npm list react-query > /dev/null 2>&1; then
    echo "⚠️  react-query が見つかりません。代替版を作成中..."
    
    cat > frontend/src/pages/AdminDashboard.tsx << 'EOF'
// frontend/src/pages/AdminDashboard.tsx (react-query なし版)
import React, { useState, useEffect } from 'react'
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend,
  ResponsiveContainer
} from 'recharts'
import {
  Activity, Users, Search, Database,
  Clock
} from 'lucide-react'

// 型定義
interface DashboardStats {
  totalSearches: number
  totalUsers: number
  totalLabs: number
  avgResponseTime: number
  systemHealth: 'healthy' | 'warning' | 'critical'
}

interface SearchTrend {
  date: string
  searches: number
  avgResponseTime: number
}

interface PopularQuery {
  query: string
  count: number
  avgSimilarity: number
}

const AdminDashboard: React.FC = () => {
  const [timeRange, setTimeRange] = useState<'24h' | '7d' | '30d'>('24h')
  const [dashboardStats, setDashboardStats] = useState<DashboardStats | null>(null)
  const [searchTrends, setSearchTrends] = useState<SearchTrend[]>([])
  const [popularQueries, setPopularQueries] = useState<PopularQuery[]>([])
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    const loadData = async () => {
      setIsLoading(true)
      
      // モックデータの生成
      setTimeout(() => {
        setDashboardStats({
          totalSearches: Math.floor(Math.random() * 10000) + 1000,
          totalUsers: Math.floor(Math.random() * 500) + 100,
          totalLabs: Math.floor(Math.random() * 50) + 20,
          avgResponseTime: Math.floor(Math.random() * 1000) + 200,
          systemHealth: 'healthy'
        })

        const trends = Array.from({ length: 24 }, (_, i) => ({
          date: `${23 - i}:00`,
          searches: Math.floor(Math.random() * 100) + 10,
          avgResponseTime: Math.floor(Math.random() * 500) + 200
        })).reverse()
        setSearchTrends(trends)

        setPopularQueries([
          { query: '機械学習 研究', count: 156, avgSimilarity: 0.85 },
          { query: 'がん治療 免疫療法', count: 142, avgSimilarity: 0.82 },
          { query: 'AI 自然言語処理', count: 128, avgSimilarity: 0.79 },
          { query: '再生医療 幹細胞', count: 98, avgSimilarity: 0.76 },
          { query: 'ロボット工学', count: 87, avgSimilarity: 0.73 }
        ])

        setIsLoading(false)
      }, 1000)
    }

    loadData()
  }, [timeRange])

  // レスポンス時間の色分け
  const getResponseTimeColor = (time: number) => {
    if (time < 1000) return 'text-green-600'
    if (time < 2000) return 'text-yellow-600'
    return 'text-red-600'
  }

  const getSystemHealthColor = (health: string) => {
    switch (health) {
      case 'healthy': return 'text-green-600 bg-green-50'
      case 'warning': return 'text-yellow-600 bg-yellow-50'
      case 'critical': return 'text-red-600 bg-red-50'
      default: return 'text-gray-600 bg-gray-50'
    }
  }

  const getSystemHealthText = (health: string) => {
    switch (health) {
      case 'healthy': return '正常'
      case 'warning': return '注意'
      case 'critical': return '警告'
      default: return '不明'
    }
  }

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">ダッシュボードを読み込み中...</p>
        </div>
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
                className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                  timeRange === range
                    ? 'bg-blue-600 text-white'
                    : 'bg-white text-gray-700 hover:bg-gray-50 border border-gray-300'
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

        {/* システムヘルス */}
        <div className="bg-white rounded-lg shadow p-6 mb-8">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">
            システムヘルス
          </h2>
          <div className={`rounded-lg p-4 ${getSystemHealthColor(dashboardStats?.systemHealth || 'healthy')}`}>
            <div className="flex items-center">
              <Activity className="h-6 w-6 mr-3" />
              <div>
                <p className="font-medium">
                  システム状況: {getSystemHealthText(dashboardStats?.systemHealth || 'healthy')}
                </p>
                <p className="text-sm mt-1">
                  すべてのシステムが正常に動作しています
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* チャート */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          {/* 検索トレンド */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">検索トレンド</h2>
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
          </div>

          {/* 応答時間トレンド */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">応答時間トレンド</h2>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={searchTrends}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line type="monotone" dataKey="avgResponseTime" stroke="#10B981" name="応答時間(ms)" />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* 人気検索クエリ */}
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">
            人気検索クエリ (過去{timeRange})
          </h2>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    検索クエリ
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    検索回数
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    平均類似度
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {popularQueries.map((query, index) => (
                  <tr key={index}>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {query.query}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {query.count}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {(query.avgSimilarity * 100).toFixed(1)}%
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  )
}

export default AdminDashboard
EOF
    
    echo "✅ react-query なし版のAdminDashboard.tsx を作成しました"
fi

echo "🎉 AdminDashboard.tsx の修正が完了しました！"