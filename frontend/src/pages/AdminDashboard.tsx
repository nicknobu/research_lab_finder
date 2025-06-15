// frontend/src/pages/AdminDashboard.tsx
import React, { useState, useEffect } from 'react'
import { useQuery } from 'react-query'
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend,
  LineChart, Line, PieChart, Pie, Cell, ResponsiveContainer
} from 'recharts'
import {
  Activity, Users, Search, Database, AlertTriangle,
  TrendingUp, Clock, Globe, Server, Zap
} from 'lucide-react'

import { getSearchStats, getSystemStats, getPerformanceMetrics } from '../utils/adminApi'
import LoadingSpinner from '../components/LoadingSpinner'

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

  const { data: performanceMetrics, isLoading: performanceLoading } = useQuery(
    ['performanceMetrics'],
    getPerformanceMetrics,
    {
      refetchInterval: 10000 // 10秒間隔
    }
  )

  const { data: popularQueries } = useQuery<PopularQuery[]>(
    ['popularQueries', timeRange],
    () => getPopularQueries(timeRange)
  )

  // グラフ用カラーパレット
  const colors = ['#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6']

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      {/* ヘッダー */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">
              研究室ファインダー 管理ダッシュボード
            </h1>
            <p className="text-gray-600 mt-1">
              システム状況とパフォーマンスの監視
            </p>
          </div>
          
          {/* 時間範囲選択 */}
          <div className="flex items-center gap-4">
            <select
              value={timeRange}
              onChange={(e) => setTimeRange(e.target.value as any)}
              className="bg-white border border-gray-300 rounded-lg px-4 py-2 text-sm"
            >
              <option value="24h">過去24時間</option>
              <option value="7d">過去7日</option>
              <option value="30d">過去30日</option>
            </select>
            
            <div className="flex items-center gap-2 text-sm text-gray-500">
              <Activity className="h-4 w-4" />
              <span>自動更新: {refreshInterval / 1000}秒</span>
            </div>
          </div>
        </div>
      </div>

      {/* KPI カード */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <DashboardCard
          title="総検索数"
          value={dashboardStats?.totalSearches || 0}
          icon={<Search className="h-6 w-6" />}
          color="blue"
          loading={statsLoading}
        />
        
        <DashboardCard
          title="アクティブユーザー"
          value={dashboardStats?.totalUsers || 0}
          icon={<Users className="h-6 w-6" />}
          color="green"
          loading={statsLoading}
        />
        
        <DashboardCard
          title="研究室データ"
          value={dashboardStats?.totalLabs || 0}
          icon={<Database className="h-6 w-6" />}
          color="purple"
          loading={statsLoading}
        />
        
        <DashboardCard
          title="平均応答時間"
          value={`${dashboardStats?.avgResponseTime || 0}ms`}
          icon={<Zap className="h-6 w-6" />}
          color="orange"
          loading={statsLoading}
        />
      </div>

      {/* システムヘルス */}
      <div className="bg-white rounded-lg shadow-sm p-6 mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">
          システムヘルス
        </h2>
        <SystemHealthPanel health={dashboardStats?.systemHealth || 'healthy'} />
      </div>

      {/* グラフセクション */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
        {/* 検索トレンド */}
        <div className="bg-white rounded-lg shadow-sm p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">
            検索トレンド
          </h2>
          {trendsLoading ? (
            <div className="h-64 flex items-center justify-center">
              <LoadingSpinner />
            </div>
          ) : (
            <ResponsiveContainer width="100%" height={250}>
              <LineChart data={searchTrends}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line
                  type="monotone"
                  dataKey="searches"
                  stroke="#3B82F6"
                  strokeWidth={2}
                  name="検索数"
                />
              </LineChart>
            </ResponsiveContainer>
          )}
        </div>

        {/* パフォーマンス */}
        <div className="bg-white rounded-lg shadow-sm p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">
            応答時間トレンド
          </h2>
          {trendsLoading ? (
            <div className="h-64 flex items-center justify-center">
              <LoadingSpinner />
            </div>
          ) : (
            <ResponsiveContainer width="100%" height={250}>
              <LineChart data={searchTrends}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line
                  type="monotone"
                  dataKey="avgResponseTime"
                  stroke="#10B981"
                  strokeWidth={2}
                  name="応答時間(ms)"
                />
              </LineChart>
            </ResponsiveContainer>
          )}
        </div>
      </div>

      {/* 人気検索クエリ */}
      <div className="bg-white rounded-lg shadow-sm p-6 mb-8">
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
      </div>

      {/* リアルタイム活動 */}
      <RealtimeActivity />
    </div>
  )
}

// ダッシュボードカードコンポーネント
interface DashboardCardProps {
  title: string
  value: string | number
  icon: React.ReactNode
  color: 'blue' | 'green' | 'purple' | 'orange'
  loading?: boolean
}

const DashboardCard: React.FC<DashboardCardProps> = ({
  title, value, icon, color, loading
}) => {
  const colorClasses = {
    blue: 'bg-blue-50 text-blue-600',
    green: 'bg-green-50 text-green-600',
    purple: 'bg-purple-50 text-purple-600',
    orange: 'bg-orange-50 text-orange-600'
  }

  return (
    <div className="bg-white rounded-lg shadow-sm p-6">
      <div className="flex items-center">
        <div className={`p-2 rounded-lg ${colorClasses[color]}`}>
          {icon}
        </div>
        <div className="ml-4">
          <p className="text-sm font-medium text-gray-600">{title}</p>
          {loading ? (
            <div className="h-8 w-16 bg-gray-200 rounded animate-pulse mt-1" />
          ) : (
            <p className="text-2xl font-bold text-gray-900">
              {typeof value === 'number' ? value.toLocaleString() : value}
            </p>
          )}
        </div>
      </div>
    </div>
  )
}

// システムヘルスパネル
interface SystemHealthPanelProps {
  health: 'healthy' | 'warning' | 'critical'
}

const SystemHealthPanel: React.FC<SystemHealthPanelProps> = ({ health }) => {
  const healthConfig = {
    healthy: {
      color: 'text-green-600',
      bgColor: 'bg-green-50',
      icon: <Activity className="h-5 w-5" />,
      message: 'すべてのシステムが正常に動作しています'
    },
    warning: {
      color: 'text-yellow-600',
      bgColor: 'bg-yellow-50',
      icon: <AlertTriangle className="h-5 w-5" />,
      message: '一部のシステムで軽微な問題が発生しています'
    },
    critical: {
      color: 'text-red-600',
      bgColor: 'bg-red-50',
      icon: <AlertTriangle className="h-5 w-5" />,
      message: '重要なシステムで問題が発生しています'
    }
  }

  const config = healthConfig[health]

  return (
    <div className={`${config.bgColor} rounded-lg p-4`}>
      <div className="flex items-center">
        <div className={config.color}>
          {config.icon}
        </div>
        <div className="ml-3">
          <p className={`font-medium ${config.color}`}>
            システム状況: {health.toUpperCase()}
          </p>
          <p className="text-sm text-gray-600 mt-1">
            {config.message}
          </p>
        </div>
      </div>
    </div>
  )
}

// リアルタイム活動コンポーネント
const RealtimeActivity: React.FC = () => {
  const [activities, setActivities] = useState<any[]>([])

  useEffect(() => {
    // WebSocket接続でリアルタイム活動を取得
    // 実装は簡略化
    const interval = setInterval(() => {
      const newActivity = {
        id: Date.now(),
        type: 'search',
        query: '最新の検索クエリ',
        timestamp: new Date(),
        responseTime: Math.random() * 1000 + 200
      }
      setActivities(prev => [newActivity, ...prev.slice(0, 9)])
    }, 5000)

    return () => clearInterval(interval)
  }, [])

  return (
    <div className="bg-white rounded-lg shadow-sm p-6">
      <h2 className="text-xl font-semibold text-gray-900 mb-4">
        リアルタイム活動
      </h2>
      <div className="space-y-3">
        {activities.map((activity) => (
          <div key={activity.id} className="flex items-center justify-between py-2 border-b border-gray-100 last:border-b-0">
            <div className="flex items-center">
              <div className="p-1 bg-blue-100 rounded-full mr-3">
                <Search className="h-3 w-3 text-blue-600" />
              </div>
              <div>
                <p className="text-sm font-medium text-gray-900">
                  {activity.query}
                </p>
                <p className="text-xs text-gray-500">
                  {activity.timestamp.toLocaleTimeString()}
                </p>
              </div>
            </div>
            <div className="text-xs text-gray-500">
              {activity.responseTime.toFixed(0)}ms
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

export default AdminDashboard

// frontend/src/utils/adminApi.ts
import apiClient from './api'

export const getSystemStats = async (timeRange: string) => {
  const response = await apiClient.get(`/api/admin/stats?range=${timeRange}`)
  return response.data
}

export const getSearchStats = async (timeRange: string) => {
  const response = await apiClient.get(`/api/admin/search-trends?range=${timeRange}`)
  return response.data
}

export const getPerformanceMetrics = async () => {
  const response = await apiClient.get('/api/admin/performance')
  return response.data
}

export const getPopularQueries = async (timeRange: string) => {
  const response = await apiClient.get(`/api/admin/popular-queries?range=${timeRange}`)
  return response.data
}

// backend/app/api/endpoints/admin.py
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, text
from typing import List, Dict, Any
from datetime import datetime, timedelta
import logging

from app.database import get_db
from app.models import SearchLog, ResearchLab, University

logger = logging.getLogger(__name__)

router = APIRouter()

@router.get("/stats")
async def get_system_stats(
    range: str = Query("24h", description="時間範囲: 24h, 7d, 30d"),
    db: Session = Depends(get_db)
):
    """システム統計情報取得"""
    try:
        # 時間範囲の設定
        time_delta = {
            "24h": timedelta(hours=24),
            "7d": timedelta(days=7),
            "30d": timedelta(days=30)
        }.get(range, timedelta(hours=24))
        
        start_time = datetime.utcnow() - time_delta
        
        # 検索統計
        total_searches = db.query(func.count(SearchLog.id))\
            .filter(SearchLog.timestamp >= start_time)\
            .scalar()
        
        # ユニークユーザー数（セッションベース）
        total_users = db.query(func.count(func.distinct(SearchLog.session_id)))\
            .filter(SearchLog.timestamp >= start_time)\
            .scalar()
        
        # 総研究室数
        total_labs = db.query(func.count(ResearchLab.id)).scalar()
        
        # 平均応答時間
        avg_response_time = db.query(func.avg(SearchLog.search_time_ms))\
            .filter(SearchLog.timestamp >= start_time)\
            .scalar()
        
        # システムヘルス判定
        system_health = "healthy"
        if avg_response_time and avg_response_time > 2000:
            system_health = "warning"
        if avg_response_time and avg_response_time > 5000:
            system_health = "critical"
        
        return {
            "totalSearches": total_searches or 0,
            "totalUsers": total_users or 0,
            "totalLabs": total_labs or 0,
            "avgResponseTime": round(avg_response_time or 0, 1),
            "systemHealth": system_health
        }
        
    except Exception as e:
        logger.error(f"Failed to get system stats: {e}")
        raise HTTPException(status_code=500, detail="統計情報の取得に失敗しました")

@router.get("/search-trends")
async def get_search_trends(
    range: str = Query("24h"),
    db: Session = Depends(get_db)
):
    """検索トレンド取得"""
    try:
        time_delta = {
            "24h": timedelta(hours=24),
            "7d": timedelta(days=7),
            "30d": timedelta(days=30)
        }.get(range, timedelta(hours=24))
        
        start_time = datetime.utcnow() - time_delta
        
        # 時間間隔の設定
        interval = "1 hour" if range == "24h" else "1 day"
        
        query = text(f"""
            SELECT 
                date_trunc('{interval}', timestamp) as date,
                COUNT(*) as searches,
                AVG(search_time_ms) as avg_response_time
            FROM search_logs 
            WHERE timestamp >= :start_time
            GROUP BY date_trunc('{interval}', timestamp)
            ORDER BY date
        """)
        
        result = db.execute(query, {"start_time": start_time})
        
        trends = []
        for row in result:
            trends.append({
                "date": row.date.strftime("%Y-%m-%d %H:%M" if range == "24h" else "%Y-%m-%d"),
                "searches": row.searches,
                "avgResponseTime": round(row.avg_response_time or 0, 1)
            })
        
        return trends
        
    except Exception as e:
        logger.error(f"Failed to get search trends: {e}")
        raise HTTPException(status_code=500, detail="検索トレンドの取得に失敗しました")

@router.get("/performance")
async def get_performance_metrics(db: Session = Depends(get_db)):
    """パフォーマンスメトリクス取得"""
    try:
        # 直近の検索パフォーマンス
        recent_searches = db.query(
            func.count(SearchLog.id).label("count"),
            func.avg(SearchLog.search_time_ms).label("avg_time"),
            func.max(SearchLog.search_time_ms).label("max_time"),
            func.min(SearchLog.search_time_ms).label("min_time")
        ).filter(
            SearchLog.timestamp >= datetime.utcnow() - timedelta(minutes=5)
        ).first()
        
        return {
            "recentSearches": recent_searches.count or 0,
            "avgResponseTime": round(recent_searches.avg_time or 0, 1),
            "maxResponseTime": round(recent_searches.max_time or 0, 1),
            "minResponseTime": round(recent_searches.min_time or 0, 1),
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Failed to get performance metrics: {e}")
        raise HTTPException(status_code=500, detail="パフォーマンス情報の取得に失敗しました")

@router.get("/popular-queries")
async def get_popular_queries(
    range: str = Query("24h"),
    limit: int = Query(10, le=50),
    db: Session = Depends(get_db)
):
    """人気検索クエリ取得"""
    try:
        time_delta = {
            "24h": timedelta(hours=24),
            "7d": timedelta(days=7),
            "30d": timedelta(days=30)
        }.get(range, timedelta(hours=24))
        
        start_time = datetime.utcnow() - time_delta
        
        popular_queries = db.query(
            SearchLog.query,
            func.count(SearchLog.id).label("count"),
            func.avg(SearchLog.search_quality_score).label("avg_similarity")
        ).filter(
            SearchLog.timestamp >= start_time,
            SearchLog.results_count > 0
        ).group_by(
            SearchLog.query
        ).order_by(
            func.count(SearchLog.id).desc()
        ).limit(limit).all()
        
        return [
            {
                "query": q.query,
                "count": q.count,
                "avgSimilarity": round(q.avg_similarity or 0.5, 3)
            }
            for q in popular_queries
        ]
        
    except Exception as e:
        logger.error(f"Failed to get popular queries: {e}")
        raise HTTPException(status_code=500, detail="人気検索クエリの取得に失敗しました")