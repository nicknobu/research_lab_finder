// frontend/src/types/index.ts

export interface University {
  id: number
  name: string
  type: string
  prefecture: string
  region: string
  created_at: string
}

export interface ResearchLab {
  id: number
  name: string
  professor_name: string
  department: string
  research_theme: string
  research_content: string
  research_field: string
  speciality: string
  keywords: string
  lab_url?: string
  university: University
  created_at: string
  updated_at: string
}

export interface ResearchLabSearchResult {
  id: number
  name: string
  professor_name: string
  department: string
  research_theme: string
  research_content: string
  research_field: string
  speciality: string
  keywords: string
  lab_url?: string
  university_name: string
  prefecture: string
  region: string
  similarity_score: number
}

export interface SearchRequest {
  query: string
  limit?: number
  region_filter?: string[]
  field_filter?: string[]
  min_similarity?: number
}

export interface SearchResponse {
  query: string
  total_results: number
  search_time_ms: number
  results: ResearchLabSearchResult[]
}

export interface SearchSuggestion {
  text: string
  category: string
}

export interface ApiError {
  error: string
  message: string
  details?: Record<string, any>
}