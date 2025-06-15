import React from "react"
import { Link, useLocation } from "react-router-dom"
import { Home, Search } from "lucide-react"

const Header: React.FC = () => {
  const location = useLocation()

  return (
    <header className="bg-white shadow-sm border-b">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          <Link to="/" className="flex items-center gap-3">
            <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
              <Search className="h-5 w-5 text-white" />
            </div>
            <span className="text-xl font-bold text-gray-900">
              研究室ファインダー
            </span>
          </Link>

          <nav className="flex items-center gap-6">
            <Link
              to="/"
              className="flex items-center gap-2 px-3 py-2 rounded-lg transition-colors"
            >
              <Home className="h-4 w-4" />
              <span>ホーム</span>
            </Link>
          </nav>
        </div>
      </div>
    </header>
  )
}

export default Header