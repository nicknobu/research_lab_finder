import React from 'react'

const SearchResults: React.FC = () => {
  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-3xl font-bold text-gray-900 mb-8">検索結果</h1>
        <div className="bg-white rounded-lg p-8 shadow-md">
          <p className="text-lg text-gray-600">検索結果がここに表示されます。</p>
          <p className="text-sm text-gray-500 mt-4">
            現在はシンプルバージョンです。API連携後に検索機能が有効になります。
          </p>
        </div>
      </div>
    </div>
  )
}

export default SearchResults