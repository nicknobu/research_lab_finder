import React from "react"
import { TrendingUp } from "lucide-react"

interface PopularSearchesProps {
  onSearchClick: (query: string) => void
}

const PopularSearches: React.FC<PopularSearchesProps> = ({ onSearchClick }) => {
  const searches = [
    "がん治療の研究をしたい",
    "アレルギーで苦しむ人を助けたい", 
    "ワクチンで感染症を予防したい",
    "新しい薬を開発したい",
    "免疫学の研究",
  ]

  return (
    <div className="bg-white rounded-xl p-6 shadow-sm border">
      <div className="flex items-center gap-2 mb-4">
        <TrendingUp className="h-5 w-5 text-blue-600" />
        <h3 className="text-lg font-semibold">人気の検索</h3>
      </div>
      
      <div className="flex flex-wrap gap-2">
        {searches.map((search, index) => (
          <button
            key={index}
            onClick={() => onSearchClick(search)}
            className="bg-gray-100 hover:bg-blue-100 text-gray-700 px-3 py-2 rounded-full text-sm"
          >
            {search}
          </button>
        ))}
      </div>
    </div>
  )
}

export default PopularSearches