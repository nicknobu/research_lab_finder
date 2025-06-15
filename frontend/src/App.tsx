import React from 'react'
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import './index.css'

import Home from './pages/Home'
import SearchResults from './pages/SearchResults'
import LabDetail from './pages/LabDetail'

function App() {
  return (
    <Router>
      <div className="min-h-screen">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/search" element={<SearchResults />} />
          <Route path="/lab/:id" element={<LabDetail />} />
        </Routes>
      </div>
    </Router>
  )
}

export default App