// frontend/src/pages/SearchResults.tsx
import React, { useState, useEffect } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useQuery } from 'react-query'
import { Search, Filter, SortAsc, ChevronDown, AlertCircle } from 'lucide-react'

import { LabCard, LabCardData } from '../components/SearchBox'
import SearchBox from '../components/SearchBox'
import LoadingSpinner from '../components/LoadingSpinner'
import ErrorMessage from '../components/ErrorMessage'
import FilterPanel from '../components/FilterPanel'
import { searchLabs } from '../utils/api'
import type { SearchResponse } from '../types'

const SearchResults: React.FC = () => {
  const navigate = useNavigate()
  const [searchParams, setSearchParams] = useSearchParams()
  const [searchQuery, setSearchQuery] = useState(searchParams.get('q') || '')
  const [showFilters, setShowFilters] = useState(false)
  const [filters, setFilters] = useState({
    region: [] as string[],
    field: [] as string[],
    minSimilarity: 0.5
  })

  // 検索クエリを取得
  const query = searchParams.get('q') || ''

  // 検索API呼び出し
  const {
    data: searchResults,
    isLoading,
    error,
    refetch
  } = useQuery<SearchResponse>(
    ['search', query, filters],
    () => searchLabs({
      query,
      limit: 50,
      region_filter: filters.region.length > 0 ? filters.region : undefined,
      field_filter: filters.field.length > 0 ? filters.field : undefined,
      min_similarity: filters.minSimilarity
    }),
    {
      enabled: !!query,
      retry: 2,
      staleTime: 2 * 60 * 1000, // 2分間キャッシュ
    }
  )

  // URLパラメータの変更を監視
  useEffect(() => {
    const newQuery = searchParams.get('q') || ''
    setSearchQuery(newQuery)
  }, [searchParams])

  // 新しい検索実行
  const handleSearch = (newQuery: string) => {
    if (newQuery.trim()) {
      setSearchParams({ q: newQuery })
    }
  }

  // 研究室詳細ページへ遷移
  const handleLabClick = (lab: LabCardData) => {
    navigate(`/lab/${lab.id}`)
  }

  // フィルター適用
  const handleFilterChange = (newFilters: typeof filters) => {
    setFilters(newFilters)
  }

  return (
    <div className="space-y-6">
      {/* 検索ヘッダー */}
      <div className="bg-white rounded-lg shadow-sm p-6">
        <div className="space-y-4">
          {/* 検索ボックス */}
          <SearchBox 
            value={searchQuery}
            onChange={setSearchQuery}
            onSearch={handleSearch}
            placeholder="研究したい分野や興味のあることを入力してください..."
          />

          {/* 検索結果ヘッダー */}
          {searchResults && (
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <h1 className="text-2xl font-bold text-gray-900">
                  検索結果
                </h1>
                <div className="text-gray-600">
                  「<span className="font-medium">{query}</span>」の検索結果：
                  <span className="font-medium text-blue-600 ml-1">
                    {searchResults.total_results}件
                  </span>
                  （{searchResults.search_time_ms.toFixed(1)}ms）
                </div>
              </div>

              {/* フィルター・ソートボタン */}
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setShowFilters(!showFilters)}
                  className={`flex items-center gap-2 px-4 py-2 rounded-lg border transition-colors ${
                    showFilters 
                      ? 'bg-blue-50 border-blue-200 text-blue-700' 
                      : 'bg-white border-gray-200 text-gray-700 hover:bg-gray-50'
                  }`}
                >
                  <Filter className="h-4 w-4" />
                  <span>フィルター</span>
                  <ChevronDown className={`h-4 w-4 transition-transform ${showFilters ? 'rotate-180' : ''}`} />
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      <div className="flex gap-6">
        {/* フィルターパネル */}
        {showFilters && (
          <div className="w-80 flex-shrink-0">
            <FilterPanel
              filters={filters}
              onChange={handleFilterChange}
            />
          </div>
        )}

        {/* メインコンテンツ */}
        <div className="flex-1">
          {/* ローディング状態 */}
          {isLoading && (
            <div className="flex justify-center py-12">
              <LoadingSpinner size="large" />
            </div>
          )}

          {/* エラー状態 */}
          {error && (
            <ErrorMessage 
              title="検索エラー"
              message="検索中にエラーが発生しました。しばらく時間をおいて再度お試しください。"
              onRetry={() => refetch()}
            />
          )}

          {/* 検索結果なし */}
          {searchResults && searchResults.total_results === 0 && (
            <div className="text-center py-12 bg-white rounded-lg shadow-sm">
              <AlertCircle className="h-12 w-12 text-gray-400 mx-auto mb-4" />
              <h3 className="text-xl font-semibold text-gray-900 mb-2">
                検索結果が見つかりませんでした
              </h3>
              <p className="text-gray-600 mb-6 max-w-md mx-auto">
                検索キーワードを変更するか、フィルター条件を緩めて再度お試しください
              </p>
              <button
                onClick={() => setFilters({ region: [], field: [], minSimilarity: 0.3 })}
                className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg transition-colors"
              >
                フィルターをリセット
              </button>
            </div>
          )}

          {/* 検索結果リスト */}
          {searchResults && searchResults.total_results > 0 && (
            <div className="space-y-6">
              {/* 結果の概要 */}
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <div className="flex items-start gap-3">
                  <Search className="h-5 w-5 text-blue-600 mt-0.5" />
                  <div>
                    <h3 className="font-medium text-blue-900 mb-1">
                      AI推奨システムによる検索結果
                    </h3>
                    <p className="text-sm text-blue-700">
                      あなたの興味「{query}」に関連度の高い順に研究室を表示しています。
                      推奨度スコアが高いほど、あなたの興味により適合しています。
                    </p>
                  </div>
                </div>
              </div>

              {/* 研究室カードリスト */}
              <div className="grid gap-6">
                {searchResults.results.map((lab) => (
                  <LabCard 
                    key={lab.id}
                    lab={lab}
                    onClick={handleLabClick}
                  />
                ))}
              </div>

              {/* ページネーション（将来の拡張用） */}
              {searchResults.total_results > 50 && (
                <div className="text-center py-8">
                  <p className="text-gray-600">
                    さらに詳細な検索をご希望の場合は、検索キーワードを具体的にしてください
                  </p>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

export default SearchResults