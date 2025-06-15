import React, { useState } from 'react'
import { Search } from 'lucide-react'

const Home: React.FC = () => {
  const [query, setQuery] = useState('')

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    alert(`検索クエリ: ${query}`)
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 p-8">
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-12">
          <h1 className="text-5xl font-bold text-gray-900 mb-4">
            研究室<span className="text-blue-600">ファインダー</span>
          </h1>
          <p className="text-xl text-gray-600 mb-8">
            中学生の興味・関心から、全国の大学研究室をAIが推奨
          </p>
        </div>

        <div className="bg-white rounded-2xl shadow-lg p-8 mb-8">
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="relative">
              <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 h-6 w-6 text-gray-400" />
              <input
                type="text"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="研究したい分野を入力してください（例：がん治療、AI、環境問題）"
                className="w-full pl-12 pr-4 py-4 text-lg border-2 border-gray-200 rounded-xl focus:border-blue-500 focus:outline-none"
              />
            </div>
            <button
              type="submit"
              className="w-full bg-blue-600 hover:bg-blue-700 text-white py-4 rounded-xl font-semibold text-lg transition-colors"
            >
              研究室を検索
            </button>
          </form>
        </div>

        <div className="grid md:grid-cols-3 gap-6">
          <div className="bg-white rounded-xl p-6 shadow-md">
            <h3 className="text-xl font-semibold mb-2">50+ 研究室</h3>
            <p className="text-gray-600">豊富な研究室データベース</p>
          </div>
          <div className="bg-white rounded-xl p-6 shadow-md">
            <h3 className="text-xl font-semibold mb-2">AI 推奨</h3>
            <p className="text-gray-600">あなたの興味に最適な研究室を発見</p>
          </div>
          <div className="bg-white rounded-xl p-6 shadow-md">
            <h3 className="text-xl font-semibold mb-2">簡単検索</h3>
            <p className="text-gray-600">自然な言葉で検索可能</p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Home