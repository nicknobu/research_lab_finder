import React from 'react'
import { MapPin, User, ExternalLink } from 'lucide-react'
import type { ResearchLabSearchResult } from '../types'

interface LabCardProps {
  lab: ResearchLabSearchResult
  onClick?: (lab: ResearchLabSearchResult) => void
}

const LabCard: React.FC<LabCardProps> = ({ lab, onClick }) => {
  return (
    <div 
      className="border border-gray-200 rounded-lg p-6 hover:shadow-md transition-shadow cursor-pointer"
      onClick={() => onClick?.(lab)}
    >
      <div className="flex justify-between items-start mb-3">
        <h3 className="text-xl font-semibold text-gray-900">{lab.name}</h3>
        <span className="bg-blue-100 text-blue-800 px-3 py-1 rounded-full text-sm font-medium">
          {Math.round((lab.similarity_score || 0) * 100)}% マッチ
        </span>
      </div>
      
      <div className="mb-3">
        <p className="text-gray-700 flex items-center">
          <User className="h-4 w-4 mr-1" />
          {lab.professor_name}
        </p>
        <p className="text-gray-700 flex items-center mt-1">
          <MapPin className="h-4 w-4 mr-1" />
          {lab.university_name}, {lab.region}
        </p>
      </div>
      
      <div className="mb-3">
        <h4 className="font-semibold text-gray-800 mb-1">研究テーマ:</h4>
        <p className="text-gray-700">{lab.research_theme}</p>
      </div>
      
      <div className="flex items-center justify-between">
        <span className="bg-gray-100 text-gray-700 px-3 py-1 rounded-full text-sm">
          {lab.research_field}
        </span>
        {lab.lab_url && (
          <ExternalLink className="h-4 w-4 text-blue-600" />
        )}
      </div>
    </div>
  )
}

export default LabCard
