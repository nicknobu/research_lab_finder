import React, { useState } from 'react'
import { Search, X } from 'lucide-react'

interface SearchBoxProps {
  onSearch: (query: string) => void
  initialQuery?: string
  placeholder?: string
}

const SearchBox: React.FC<SearchBoxProps> = ({
  onSearch,
  initialQuery = '',
  placeholder = "研究したい分野や興味のあることを入力してください..."
}) => {
  const [value, setValue] = useState(initialQuery)

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (value.trim()) {
      onSearch(value.trim())
    }
  }

  const clearInput = () => {
    setValue('')
  }

  return (
    <div className="relative w-full">
      <form onSubmit={handleSubmit}>
        <div className="relative">
          <input
            type="text"
            value={value}
            onChange={(e) => setValue(e.target.value)}
            placeholder={placeholder}
            className="w-full pl-12 pr-20 py-4 text-lg border-2 border-gray-200 rounded-xl focus:border-blue-500 focus:outline-none transition-colors"
          />
          <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 h-6 w-6 text-gray-400" />
          
          {value && (
            <button
              type="button"
              onClick={clearInput}
              className="absolute right-16 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
            >
              <X className="h-5 w-5" />
            </button>
          )}
          
          <button
            type="submit"
            className="absolute right-2 top-1/2 transform -translate-y-1/2 bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg transition-colors font-medium"
          >
            検索
          </button>
        </div>
      </form>
    </div>
  )
}

export default SearchBox