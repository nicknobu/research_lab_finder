// frontend/src/App.tsx
import React from 'react'
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from 'react-query'
import './index.css'

// Pages
import Home from './pages/Home'
import SearchResults from './pages/SearchResults'
import LabDetail from './pages/LabDetail'

// Components
import Header from './components/Header'
import Footer from './components/Footer'
import ErrorBoundary from './components/ErrorBoundary'

// React Query設定
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 2,
      refetchOnWindowFocus: false,
      staleTime: 5 * 60 * 1000, // 5分間キャッシュ
    },
  },
})

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Router>
        <ErrorBoundary>
          <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-indigo-50">
            <Header />
            
            <main className="container mx-auto px-4 py-8">
              <Routes>
                <Route 
                  path="/" 
                  element={<Home />} 
                />
                <Route 
                  path="/search" 
                  element={<SearchResults />} 
                />
                <Route 
                  path="/lab/:id" 
                  element={<LabDetail />} 
                />
                <Route 
                  path="*" 
                  element={
                    <div className="text-center py-20">
                      <h1 className="text-4xl font-bold text-gray-700 mb-4">
                        ページが見つかりません
                      </h1>
                      <p className="text-gray-500 mb-8">
                        お探しのページは存在しないか、移動された可能性があります。
                      </p>
                      <a 
                        href="/" 
                        className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg transition-colors"
                      >
                        ホームに戻る
                      </a>
                    </div>
                  } 
                />
              </Routes>
            </main>
            
            <Footer />
          </div>
        </ErrorBoundary>
      </Router>
    </QueryClientProvider>
  )
}

export default App