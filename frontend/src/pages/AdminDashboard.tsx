import React, { useState, useEffect } from 'react'
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

const AdminDashboard: React.FC = () => {
  const [timeRange, setTimeRange] = useState<'24h' | '7d' | '30d'>('24h')
  const [dashboardStats, setDashboardStats] = useState<DashboardStats | null>(null)
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

        {/* 簡易統計情報 */}
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">
            システム統計 (過去{timeRange})
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="text-center p-4 bg-blue-50 rounded-lg">
              <p className="text-2xl font-bold text-blue-600">
                {dashboardStats?.totalSearches || 0}
              </p>
              <p className="text-sm text-gray-600">総検索数</p>
            </div>
            <div className="text-center p-4 bg-green-50 rounded-lg">
              <p className="text-2xl font-bold text-green-600">
                {dashboardStats?.totalUsers || 0}
              </p>
              <p className="text-sm text-gray-600">アクティブユーザー</p>
            </div>
            <div className="text-center p-4 bg-purple-50 rounded-lg">
              <p className="text-2xl font-bold text-purple-600">
                {dashboardStats?.avgResponseTime?.toFixed(0) || 0}ms
              </p>
              <p className="text-sm text-gray-600">平均応答時間</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default AdminDashboard
