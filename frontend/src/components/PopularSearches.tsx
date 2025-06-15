import React from "react"
import { TrendingUp } from "lucide-react"

interface PopularSearchesProps {
  onSearchClick: (query: string) => void
}

const PopularSearches: React.FC<PopularSearchesProps> = ({ onSearchClick }) => {
  const popularQueries = [
    "機械学習 研究",
    "がん治療 免疫療法", 
    "AI 自然言語処理",
    "再生医療 幹細胞",
    "ロボット工学"
  ]

  return (
    <div className="bg-white rounded-lg shadow-sm p-6 mb-8">
      <h2 className="text-xl font-semibold text-gray-900 mb-4 flex items-center">
        <TrendingUp className="h-5 w-5 mr-2 text-blue-600" />
        人気の検索キーワード
      </h2>
      <div className="flex flex-wrap gap-3">
        {popularQueries.map((query) => (
          <button
            key={query}
            onClick={() => onSearchClick(query)}
            className="bg-gray-100 hover:bg-blue-100 text-gray-700 hover:text-blue-700 px-4 py-2 rounded-full text-sm font-medium transition-colors"
          >
            {query}
          </button>
        ))}
      </div>
    </div>
  )
}

export default PopularSearches
