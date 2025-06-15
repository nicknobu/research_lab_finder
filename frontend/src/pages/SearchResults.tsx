import React, { useState, useEffect } from 'react'
import { useLocation, useNavigate, Link } from 'react-router-dom'
import { Search, ArrowLeft, Filter, SortAsc } from 'lucide-react'
import LabCard from '../components/LabCard'
import { searchLabs } from '../utils/api'
import type { SearchResponse, ResearchLabSearchResult, SearchRequest } from '../types'

const SearchResults: React.FC = () => {
  const location = useLocation()
  const navigate = useNavigate()
  
  const [results, setResults] = useState<SearchResponse | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string>('')
  const [query, setQuery] = useState('')
  const [sortBy, setSortBy] = useState<'relevance' | 'name'>('relevance')
  const [filterField, setFilterField] = useState<string>('')
  const [filterRegion, setFilterRegion] = useState<string>('')

  // URLパラメータまたはlocation.stateから初期データを取得
  useEffect(() => {
    if (location.state?.results && location.state?.query) {
      // Home画面からの遷移の場合
      setResults(location.state.results)
      setQuery(location.state.query)
    } else {
      // URLパラメータからクエリを取得
      const params = new URLSearchParams(location.search)
      const queryParam = params.get('q')
      if (queryParam) {
        setQuery(queryParam)
        handleSearch(queryParam)
      } else {
        // クエリが無い場合はホームに戻る
        navigate('/')
      }
    }
  }, [location, navigate])

  const handleSearch = async (searchQuery: string) => {
    if (!searchQuery.trim()) return

    setIsLoading(true)
    setError('')

    try {
      const searchRequest: SearchRequest = {
        query: searchQuery,
        limit: 20,
        ...(filterField && { field_filter: [filterField] }),
        ...(filterRegion && { region_filter: [filterRegion] })
      }

      const searchResults = await searchLabs(searchRequest)
      setResults(searchResults)
    } catch (err) {
      console.error('検索エラー:', err)
      setError('検索中にエラーが発生しました。')
    } finally {
      setIsLoading(false)
    }
  }

  const handleNewSearch = async (e: React.FormEvent) => {
    e.preventDefault()
    if (query.trim()) {
      await handleSearch(query)
      // URLも更新
      navigate(`/search?q=${encodeURIComponent(query)}`, { replace: true })
    }
  }

  const handleLabClick = (lab: ResearchLabSearchResult) => {
    navigate(`/lab/${lab.id}`)
  }

  const getSortedResults = () => {
    if (!results?.results) return []

    let sortedResults = [...results.results]

    if (sortBy === 'name') {
      sortedResults.sort((a, b) => a.name.localeCompare(b.name, 'ja'))
    }
    // 'relevance'の場合はそのまま（既にスコア順）

    return sortedResults
  }

  const getUniqueFields = () => {
    if (!results?.results) return []
    const fields = new Set(results.results.map(lab => lab.research_field))
    return Array.from(fields).sort()
  }

  const getUniqueRegions = () => {
    if (!results?.results) return []
    const regions = new Set(results.results.map(lab => lab.region))
    return Array.from(regions).sort()
  }

  if (isLoading && !results) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">検索中...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* ヘッダー */}
      <div className="bg-white border-b">
        <div className="max-w-6xl mx-auto p-6">
          <div className="flex items-center mb-4">
            <Link 
              to="/" 
              className="flex items-center text-blue-600 hover:text-blue-800 mr-6"
            >
              <ArrowLeft className="h-5 w-5 mr-2" />
              戻る
            </Link>
            <h1 className="text-2xl font-bold text-gray-900">検索結果</h1>
          </div>
          
          {/* 再検索フォーム */}
          <form onSubmit={handleNewSearch} className="mb-4">
            <div className="relative max-w-2xl">
              <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
              <input
                type="text"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="新しいキーワードで検索..."
                className="w-full pl-12 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              <button
                type="submit"
                className="absolute right-2 top-1/2 transform -translate-y-1/2 bg-blue-600 text-white px-4 py-1.5 rounded-md hover:bg-blue-700 transition-colors"
              >
                検索
              </button>
            </div>
          </form>
        </div>
      </div>

      <div className="max-w-6xl mx-auto p-6">
        <div className="flex gap-6">
          {/* サイドバー（フィルター） */}
          <div className="w-80 flex-shrink-0">
            <div className="bg-white rounded-lg p-6 sticky top-6">
              <div className="flex items-center mb-4">
                <Filter className="h-5 w-5 mr-2 text-gray-600" />
                <h3 className="font-semibold text-gray-900">フィルター</h3>
              </div>

              {/* ソート */}
              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  並び順
                </label>
                <select
                  value={sortBy}
                  onChange={(e) => setSortBy(e.target.value as 'relevance' | 'name')}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
                >
                  <option value="relevance">関連度順</option>
                  <option value="name">研究室名順</option>
                </select>
              </div>

              {/* 研究分野フィルター */}
              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  研究分野
                </label>
                <select
                  value={filterField}
                  onChange={(e) => setFilterField(e.target.value)}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
                >
                  <option value="">すべて</option>
                  {getUniqueFields().map(field => (
                    <option key={field} value={field}>{field}</option>
                  ))}
                </select>
              </div>

              {/* 地域フィルター */}
              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  地域
                </label>
                <select
                  value={filterRegion}
                  onChange={(e) => setFilterRegion(e.target.value)}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
                >
                  <option value="">すべて</option>
                  {getUniqueRegions().map(region => (
                    <option key={region} value={region}>{region}</option>
                  ))}
                </select>
              </div>

              {/* フィルタークリア */}
              {(filterField || filterRegion) && (
                <button
                  onClick={() => {
                    setFilterField('')
                    setFilterRegion('')
                  }}
                  className="text-blue-600 hover:text-blue-800 text-sm font-medium"
                >
                  フィルターをクリア
                </button>
              )}
            </div>
          </div>

          {/* メインコンテンツ */}
          <div className="flex-1">
            {error && (
              <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
                <p className="text-red-600">{error}</p>
              </div>
            )}

            {results && (
              <div className="mb-6">
                <p className="text-gray-600">
                  <span className="font-semibold">{results.total_results}</span> 件の研究室が見つかりました
                  （検索時間: {results.search_time_ms.toFixed(1)}ms）
                </p>
              </div>
            )}

            {isLoading ? (
              <div className="text-center py-8">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
                <p className="text-gray-600">検索中...</p>
              </div>
            ) : results && results.results.length > 0 ? (
              <div className="space-y-4">
                {getSortedResults().map((lab) => (
                  <LabCard
                    key={lab.id}
                    lab={lab}
                    onClick={handleLabClick}
                  />
                ))}
              </div>
            ) : (
              <div className="text-center py-12">
                <div className="text-gray-400 mb-4">
                  <Search className="h-16 w-16 mx-auto" />
                </div>
                <h3 className="text-lg font-medium text-gray-900 mb-2">
                  検索結果が見つかりませんでした
                </h3>
                <p className="text-gray-600 mb-4">
                  別のキーワードで検索してみてください
                </p>
                <Link 
                  to="/"
                  className="inline-flex items-center text-blue-600 hover:text-blue-800 font-medium"
                >
                  <ArrowLeft className="h-4 w-4 mr-2" />
                  ホームに戻る
                </Link>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

export default SearchResults