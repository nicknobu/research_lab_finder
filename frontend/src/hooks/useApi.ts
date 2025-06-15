import { useState, useEffect } from 'react'

export const useApi = <T>(apiFunction: () => Promise<T>, deps: any[] = []) => {
  const [data, setData] = useState<T | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true)
        setError(null)
        const result = await apiFunction()
        setData(result)
      } catch (err) {
        setError(err instanceof Error ? err.message : '不明なエラーが発生しました')
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, deps)

  return { data, loading, error }
}

export const useSearch = () => {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const search = async (searchFunction: () => Promise<any>) => {
    try {
      setLoading(true)
      setError(null)
      const result = await searchFunction()
      return result
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : '検索エラーが発生しました'
      setError(errorMessage)
      throw err
    } finally {
      setLoading(false)
    }
  }

  return { search, loading, error }
}