import React, { useState, useEffect } from 'react'
import { useLocation, useNavigate, Link } from 'react-router-dom'
import { Search, ArrowLeft, Filter } from 'lucide-react'
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

  console.log('🔍 SearchResults mounted, location:', location)
  console.log('📊 location.state:', location.state)

  // URLパラメータまたはlocation.stateから初期データを取得
  useEffect(() => {
    if (location.state?.results && location.state?.query) {
      // Home画面からの遷移の場合
      console.log('✅ Home からの遷移データを受信:', location.state)
      setResults(location.state.results)
      setQuery(location.state.query)
    } else {
      // URLパラメータからクエリを取得
      const params = new URLSearchParams(location.search)
      const queryParam = params.get('q')
      console.log('🔗 URL パラメータから取得:', queryParam)
      
      if (queryParam) {
        setQuery(queryParam)
        handleSearch(queryParam)
      } else {
        // クエリが無い場合はホームに戻る
        console.log('❌ クエリが見つからないため、ホームに戻ります')
        navigate('/')
      }
    }
  }, [location, navigate])

  const handleSearch = async (searchQuery: string) => {
    if (!searchQuery.trim()) return

    console.log('🔍 再検索実行:', searchQuery)
    setIsLoading(true)
    setError('')

    try {
      const searchRequest: SearchRequest = {
        query: searchQuery,
        limit: 20
      }

      const searchResults = await searchLabs(searchRequest)
      console.log('✅ 再検索結果:', searchResults)
      setResults(searchResults)
    } catch (err) {
      console.error('❌ 再検索エラー:', err)
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
    console.log('🏢 研究室クリック:', lab)
    console.log('🔗 遷移先:', `/lab/${lab.id}`)
    navigate(`/lab/${lab.id}`)
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
                placeholder="検索キーワードを入力..."
                className="w-full pl-12 pr-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:border-blue-500"
              />
              <button
                type="submit"
                className="absolute right-2 top-1/2 transform -translate-y-1/2 bg-blue-600 text-white px-4 py-1.5 rounded hover:bg-blue-700"
              >
                検索
              </button>
            </div>
          </form>

          {/* 検索結果サマリー */}
          {results && (
            <div className="text-sm text-gray-600">
              <p>
                「<strong>{results.query}</strong>」の検索結果: 
                <strong className="text-blue-600 ml-1">{results.total_results}件</strong>
                <span className="ml-2">({results.search_time_ms}ms)</span>
              </p>
            </div>
          )}
        </div>
      </div>

      {/* メインコンテンツ */}
      <div className="max-w-6xl mx-auto p-6">
        <div className="flex gap-8">
          {/* 検索結果 */}
          <div className="flex-1">
            {error && (
              <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
                <p className="text-red-700">{error}</p>
              </div>
            )}

            {isLoading ? (
              <div className="text-center py-8">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
                <p className="text-gray-600">検索中...</p>
              </div>
            ) : results && results.results.length > 0 ? (
              <div className="space-y-4">
                <p className="text-gray-600 mb-4">
                  💡 デバッグ: 研究室カードをクリックすると詳細画面に遷移します
                </p>
                {results.results.map((lab) => (
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
