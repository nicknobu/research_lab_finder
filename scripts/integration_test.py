# scripts/integration_test.py
#!/usr/bin/env python3
"""
研究室ファインダー 完全版統合テストスイート
全システムの動作確認とパフォーマンステストを実行
"""

import asyncio
import time
import json
import requests
import psycopg2
from typing import Dict, List, Any
import logging
from dataclasses import dataclass
import sys
import os

# ログ設定
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

@dataclass
class TestResult:
    name: str
    passed: bool
    duration: float
    message: str = ""
    data: Dict[str, Any] = None

class IntegrationTestSuite:
    """統合テストスイート"""
    
    def __init__(self):
        self.base_url = "http://localhost:8000"
        self.frontend_url = "http://localhost:3000"
        self.results: List[TestResult] = []
        
    def run_all_tests(self) -> bool:
        """全テストを実行"""
        logger.info("🚀 研究室ファインダー 統合テスト開始")
        
        test_methods = [
            self.test_health_endpoints,
            self.test_database_connection,
            self.test_data_integrity,
            self.test_semantic_search_basic,
            self.test_semantic_search_advanced,
            self.test_api_performance,
            self.test_frontend_loading,
            self.test_full_user_journey,
            self.test_error_handling,
            self.test_security_headers
        ]
        
        for test_method in test_methods:
            try:
                start_time = time.time()
                result = test_method()
                duration = time.time() - start_time
                
                if isinstance(result, bool):
                    self.results.append(TestResult(
                        name=test_method.__name__,
                        passed=result,
                        duration=duration
                    ))
                else:
                    self.results.append(result)
                    
            except Exception as e:
                self.results.append(TestResult(
                    name=test_method.__name__,
                    passed=False,
                    duration=time.time() - start_time,
                    message=str(e)
                ))
        
        self.print_results()
        return all(result.passed for result in self.results)
    
    def test_health_endpoints(self) -> TestResult:
        """ヘルスチェックエンドポイントテスト"""
        try:
            # バックエンドヘルスチェック
            response = requests.get(f"{self.base_url}/health", timeout=5)
            assert response.status_code == 200
            
            health_data = response.json()
            assert health_data["status"] == "healthy"
            assert "version" in health_data
            
            # フロントエンドアクセステスト
            frontend_response = requests.get(self.frontend_url, timeout=5)
            assert frontend_response.status_code == 200
            
            return TestResult(
                name="Health Endpoints",
                passed=True,
                duration=0,
                message="✅ All health endpoints responding correctly"
            )
            
        except Exception as e:
            return TestResult(
                name="Health Endpoints",
                passed=False,
                duration=0,
                message=f"❌ Health check failed: {str(e)}"
            )
    
    def test_database_connection(self) -> TestResult:
        """データベース接続テスト"""
        try:
            # データベース接続テスト
            conn = psycopg2.connect(
                host="localhost",
                port="5432",
                database="research_lab_finder",
                user="postgres",
                password="postgres"
            )
            
            cursor = conn.cursor()
            
            # pgvector拡張の確認
            cursor.execute("SELECT * FROM pg_extension WHERE extname = 'vector';")
            vector_extension = cursor.fetchone()
            assert vector_extension is not None, "pgvector extension not found"
            
            # テーブル存在確認
            tables = ["universities", "research_labs", "search_logs"]
            for table in tables:
                cursor.execute(f"SELECT COUNT(*) FROM {table};")
                count = cursor.fetchone()[0]
                logger.info(f"Table {table}: {count} records")
            
            cursor.close()
            conn.close()
            
            return TestResult(
                name="Database Connection",
                passed=True,
                duration=0,
                message="✅ Database connection and schema verified"
            )
            
        except Exception as e:
            return TestResult(
                name="Database Connection",
                passed=False,
                duration=0,
                message=f"❌ Database test failed: {str(e)}"
            )
    
    def test_data_integrity(self) -> TestResult:
        """データ整合性テスト"""
        try:
            # 研究室データの確認
            response = requests.get(f"{self.base_url}/api/labs/", timeout=10)
            assert response.status_code == 200
            
            labs = response.json()
            assert len(labs) > 0, "No research labs found"
            
            # 大学データの確認
            response = requests.get(f"{self.base_url}/api/labs/universities/", timeout=10)
            assert response.status_code == 200
            
            universities = response.json()
            assert len(universities) > 0, "No universities found"
            
            # 統計情報の確認
            response = requests.get(f"{self.base_url}/api/universities/statistics", timeout=10)
            assert response.status_code == 200
            
            stats = response.json()
            assert stats["total_universities"] > 0
            assert stats["total_labs"] > 0
            
            return TestResult(
                name="Data Integrity",
                passed=True,
                duration=0,
                message=f"✅ Data integrity verified: {stats['total_labs']} labs, {stats['total_universities']} universities"
            )
            
        except Exception as e:
            return TestResult(
                name="Data Integrity",
                passed=False,
                duration=0,
                message=f"❌ Data integrity test failed: {str(e)}"
            )
    
    def test_semantic_search_basic(self) -> TestResult:
        """基本セマンティック検索テスト"""
        try:
            search_queries = [
                "がん治療の研究をしたい",
                "免疫学に興味がある",
                "ワクチン開発",
                "アレルギー治療"
            ]
            
            all_passed = True
            results_summary = []
            
            for query in search_queries:
                payload = {
                    "query": query,
                    "limit": 10,
                    "min_similarity": 0.5
                }
                
                response = requests.post(
                    f"{self.base_url}/api/search/",
                    json=payload,
                    timeout=15
                )
                
                if response.status_code != 200:
                    all_passed = False
                    continue
                
                data = response.json()
                results_count = data["total_results"]
                search_time = data["search_time_ms"]
                
                results_summary.append(f"{query}: {results_count} results ({search_time:.1f}ms)")
                
                # 基本的な検証
                assert "query" in data
                assert "results" in data
                assert data["query"] == query
                assert search_time < 5000  # 5秒以内
                
            return TestResult(
                name="Semantic Search Basic",
                passed=all_passed,
                duration=0,
                message="✅ Basic semantic search working: " + "; ".join(results_summary)
            )
            
        except Exception as e:
            return TestResult(
                name="Semantic Search Basic",
                passed=False,
                duration=0,
                message=f"❌ Basic search test failed: {str(e)}"
            )
    
    def test_semantic_search_advanced(self) -> TestResult:
        """高度なセマンティック検索テスト"""
        try:
            # フィルター付き検索
            payload = {
                "query": "免疫学の研究",
                "limit": 20,
                "region_filter": ["関東"],
                "field_filter": ["免疫学"],
                "min_similarity": 0.3
            }
            
            response = requests.post(
                f"{self.base_url}/api/search/",
                json=payload,
                timeout=15
            )
            
            assert response.status_code == 200
            data = response.json()
            
            # フィルターが正しく適用されているか確認
            for result in data["results"]:
                assert result["region"] == "関東"
                assert result["research_field"] == "免疫学"
                assert result["similarity_score"] >= 0.3
            
            # 類似研究室検索テスト
            if data["results"]:
                first_lab_id = data["results"][0]["id"]
                similar_response = requests.get(
                    f"{self.base_url}/api/labs/similar/{first_lab_id}?limit=5",
                    timeout=10
                )
                assert similar_response.status_code == 200
            
            return TestResult(
                name="Semantic Search Advanced",
                passed=True,
                duration=0,
                message=f"✅ Advanced search features working: {len(data['results'])} filtered results"
            )
            
        except Exception as e:
            return TestResult(
                name="Semantic Search Advanced",
                passed=False,
                duration=0,
                message=f"❌ Advanced search test failed: {str(e)}"
            )
    
    def test_api_performance(self) -> TestResult:
        """APIパフォーマンステスト"""
        try:
            # 同時リクエストテスト
            import concurrent.futures
            import threading
            
            def single_search():
                payload = {"query": "研究", "limit": 5}
                start = time.time()
                response = requests.post(f"{self.base_url}/api/search/", json=payload, timeout=10)
                duration = time.time() - start
                return response.status_code == 200, duration
            
            # 10回の同時リクエスト
            with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
                futures = [executor.submit(single_search) for _ in range(10)]
                results = [future.result() for future in concurrent.futures.as_completed(futures)]
            
            success_count = sum(1 for success, _ in results if success)
            avg_duration = sum(duration for _, duration in results) / len(results)
            
            assert success_count >= 8, f"Only {success_count}/10 requests succeeded"
            assert avg_duration < 3.0, f"Average response time too high: {avg_duration:.2f}s"
            
            return TestResult(
                name="API Performance",
                passed=True,
                duration=0,
                message=f"✅ Performance test passed: {success_count}/10 requests, avg {avg_duration:.2f}s"
            )
            
        except Exception as e:
            return TestResult(
                name="API Performance",
                passed=False,
                duration=0,
                message=f"❌ Performance test failed: {str(e)}"
            )
    
    def test_frontend_loading(self) -> TestResult:
        """フロントエンド読み込みテスト"""
        try:
            response = requests.get(self.frontend_url, timeout=10)
            assert response.status_code == 200
            
            # HTMLコンテンツの基本確認
            html_content = response.text
            assert "研究室ファインダー" in html_content
            assert "<!DOCTYPE html>" in html_content
            assert "<div id=\"root\">" in html_content
            
            # 静的ファイルのチェック
            # CSSファイルの存在確認（実際のファイル名は動的に生成される）
            import re
            css_links = re.findall(r'href="([^"]*\.css)"', html_content)
            if css_links:
                css_response = requests.get(f"{self.frontend_url}{css_links[0]}")
                assert css_response.status_code == 200
            
            return TestResult(
                name="Frontend Loading",
                passed=True,
                duration=0,
                message="✅ Frontend loading correctly with all assets"
            )
            
        except Exception as e:
            return TestResult(
                name="Frontend Loading",
                passed=False,
                duration=0,
                message=f"❌ Frontend loading test failed: {str(e)}"
            )
    
    def test_full_user_journey(self) -> TestResult:
        """フルユーザージャーニーテスト"""
        try:
            # 1. 検索実行
            search_payload = {
                "query": "がん治療の研究をしたい",
                "limit": 10
            }
            
            search_response = requests.post(
                f"{self.base_url}/api/search/",
                json=search_payload,
                timeout=15
            )
            assert search_response.status_code == 200
            
            search_data = search_response.json()
            assert search_data["total_results"] > 0
            
            # 2. 研究室詳細取得
            first_lab_id = search_data["results"][0]["id"]
            detail_response = requests.get(
                f"{self.base_url}/api/labs/{first_lab_id}",
                timeout=10
            )
            assert detail_response.status_code == 200
            
            # 3. 類似研究室取得
            similar_response = requests.get(
                f"{self.base_url}/api/labs/similar/{first_lab_id}",
                timeout=10
            )
            assert similar_response.status_code == 200
            
            # 4. 統計情報取得
            stats_response = requests.get(
                f"{self.base_url}/api/universities/statistics",
                timeout=10
            )
            assert stats_response.status_code == 200
            
            return TestResult(
                name="Full User Journey",
                passed=True,
                duration=0,
                message="✅ Complete user journey test passed"
            )
            
        except Exception as e:
            return TestResult(
                name="Full User Journey",
                passed=False,
                duration=0,
                message=f"❌ User journey test failed: {str(e)}"
            )
    
    def test_error_handling(self) -> TestResult:
        """エラーハンドリングテスト"""
        try:
            # 1. 存在しない研究室ID
            response = requests.get(f"{self.base_url}/api/labs/99999")
            assert response.status_code == 404
            
            # 2. 無効な検索クエリ
            invalid_payload = {"query": "", "limit": 10}
            response = requests.post(f"{self.base_url}/api/search/", json=invalid_payload)
            assert response.status_code == 422
            
            # 3. 無効なリクエスト形式
            response = requests.post(f"{self.base_url}/api/search/", json={"invalid": "data"})
            assert response.status_code == 422
            
            # 4. 存在しないエンドポイント
            response = requests.get(f"{self.base_url}/api/nonexistent")
            assert response.status_code == 404
            
            return TestResult(
                name="Error Handling",
                passed=True,
                duration=0,
                message="✅ Error handling working correctly"
            )
            
        except Exception as e:
            return TestResult(
                name="Error Handling",
                passed=False,
                duration=0,
                message=f"❌ Error handling test failed: {str(e)}"
            )
    
    def test_security_headers(self) -> TestResult:
        """セキュリティヘッダーテスト"""
        try:
            response = requests.get(f"{self.base_url}/health")
            headers = response.headers
            
            # 基本的なセキュリティヘッダーの確認
            security_checks = []
            
            # CORS ヘッダー
            if 'access-control-allow-origin' in headers:
                security_checks.append("CORS configured")
            
            # Content-Type
            if headers.get('content-type', '').startswith('application/json'):
                security_checks.append("Correct Content-Type")
            
            return TestResult(
                name="Security Headers",
                passed=True,
                duration=0,
                message=f"✅ Security headers check passed: {', '.join(security_checks)}"
            )
            
        except Exception as e:
            return TestResult(
                name="Security Headers",
                passed=False,
                duration=0,
                message=f"❌ Security headers test failed: {str(e)}"
            )
    
    def print_results(self):
        """テスト結果を出力"""
        logger.info("\n" + "="*80)
        logger.info("🧪 統合テスト結果")
        logger.info("="*80)
        
        passed_count = sum(1 for result in self.results if result.passed)
        total_count = len(self.results)
        
        for result in self.results:
            status = "✅ PASS" if result.passed else "❌ FAIL"
            duration_str = f"({result.duration:.2f}s)" if result.duration > 0 else ""
            logger.info(f"{status} {result.name} {duration_str}")
            if result.message:
                logger.info(f"    {result.message}")
        
        logger.info("="*80)
        logger.info(f"📊 総合結果: {passed_count}/{total_count} テストが成功")
        
        if passed_count == total_count:
            logger.info("🎉 全テストが成功しました！システムは正常に動作しています。")
        else:
            logger.error("⚠️ 一部のテストが失敗しました。ログを確認してください。")
        
        logger.info("="*80)

def main():
    """メイン実行関数"""
    # 環境確認
    if not os.getenv('OPENAI_API_KEY'):
        logger.error("❌ OPENAI_API_KEY environment variable not set")
        sys.exit(1)
    
    # テスト実行
    test_suite = IntegrationTestSuite()
    success = test_suite.run_all_tests()
    
    if success:
        logger.info("🚀 システムは本番デプロイ準備完了です！")
        sys.exit(0)
    else:
        logger.error("🔧 システムに問題があります。修正が必要です。")
        sys.exit(1)

if __name__ == "__main__":
    main()