import React from "react"
import { Github, Mail } from "lucide-react"

const Footer: React.FC = () => {
  return (
    <footer className="bg-gray-900 text-white mt-20">
      <div className="container mx-auto px-4 py-12">
        <div className="text-center">
          <h3 className="text-lg font-semibold mb-4">研究室ファインダー</h3>
          <p className="text-gray-400 text-sm">
            中学生向け研究室検索システム
          </p>
        </div>
      </div>
    </footer>
  )
}

export default Footer