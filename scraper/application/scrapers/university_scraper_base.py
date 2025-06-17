"""
大学スクレイパー基底クラス
共通のスクレイピング機能を提供
"""

from abc import ABC, abstractmethod
from typing import List, Dict, Optional, Any
import asyncio
import logging
from urllib.parse import urljoin, urlparse

from scraper.config.interfaces import (
    UniversityScraperInterface, ResearchLabData, AdmissionData,
    ScrapingError, DataValidationError
)
from scraper.domain.university import University
from scraper.domain.research_lab import create_research_lab_from_data
from scraper.infrastructure.http.http_client import ResearchLabHttpClient
from scraper.infrastructure.parsers.content_parser import UniversityContentParser
from scraper.config.settings import scraping_settings

logger = logging.getLogger(__name__)


class UniversityScraperBase(UniversityScraperInterface):
    """大学スクレイパー基底クラス"""
    
    def __init__(self, university: University):
        self.university = university
        self.base_url = university.info.website_url or ""
        self.http_client: Optional[ResearchLabHttpClient] = None
        self.parser: Optional[UniversityContentParser] = None
        self._scraped_labs: List[ResearchLabData] = []
        self._scraped_admissions: List[AdmissionData] = []
    
    async def __aenter__(self):
        """非同期コンテキストマネージャー開始"""
        self.http_client = ResearchLabHttpClient()
        await self.http_client.__aenter__()
        self.parser = UniversityContentParser(self.university.name)
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """非同期コンテキストマネージャー終了"""
        if self.http_client:
            await self.http_client.__aexit__(exc_type, exc_val, exc_tb)
    
    async def scrape_research_labs(self) -> List[ResearchLabData]:
        """研究室データの取得（基本実装）"""
        try:
            logger.info(f"🔍 {self.university.name} の研究室スクレイピング開始")
            
            # 対象URLリストを生成
            target_urls = await self._discover_target_urls()
            
            # 各URLをスクレイピング
            for url in target_urls:
                try:
                    labs = await self._scrape_single_page(url)
                    self._scraped_labs.extend(labs)
                    
                    # プログレス表示
                    logger.info(f"✅ {url}: {len(labs)}件の研究室を発見")
                    
                except Exception as e:
                    logger.error(f"❌ {url} のスクレイピング失敗: {e}")
                    continue
            
            # データ品質向上とバリデーション
            validated_labs = await self._validate_and_enrich_labs(self._scraped_labs)
            
            logger.info(f"🎉 {self.university.name}: 合計{len(validated_labs)}件の研究室を収集")
            return validated_labs
            
        except Exception as e:
            logger.error(f"❌ {self.university.name} のスクレイピング失敗: {e}")
            raise ScrapingError(f"Failed to scrape {self.university.name}: {e}")
    
    async def scrape_admission_info(self) -> List[AdmissionData]:
        """総合型選抜情報の取得（基本実装）"""
        try:
            logger.info(f"📋 {self.university.name} の総合型選抜情報収集開始")
            
            # 入試情報ページを検索
            admission_urls = await self._discover_admission_urls()
            
            for url in admission_urls:
                try:
                    admissions = await self._scrape_admission_page(url)
                    self._scraped_admissions.extend(admissions)
                    
                except Exception as e:
                    logger.error(f"❌ 総合型選抜情報収集失敗 {url}: {e}")
                    continue
            
            logger.info(f"📊 {self.university.name}: {len(self._scraped_admissions)}件の選抜情報を収集")
            return self._scraped_admissions
            
        except Exception as e:
            logger.error(f"❌ {self.university.name} の総合型選抜情報収集失敗: {e}")
            return []
    
    def validate_data(self, data: ResearchLabData) -> bool:
        """データバリデーション"""
        try:
            # 必須フィールドチェック
            required_fields = ['name', 'professor_name', 'research_content']
            for field in required_fields:
                value = getattr(data, field, None)
                if not value or (isinstance(value, str) and len(value.strip()) < 3):
                    return False
            
            # 研究内容の長さチェック
            if len(data.research_content) < scraping_settings.min_content_length:
                return False
            
            # 免疫関連度チェック（後で実装）
            # if data.immune_relevance_score and data.immune_relevance_score < 0.3:
            #     return False
            
            return True
            
        except Exception as e:
            logger.error(f"データバリデーションエラー: {e}")
            return False
    
    async def _discover_target_urls(self) -> List[str]:
        """対象URLを発見（サブクラスでオーバーライド）"""
        urls = []
        
        if not self.base_url:
            logger.warning(f"{self.university.name}: ベースURLが設定されていません")
            return urls
        
        # 学部ページを探索
        faculty_urls = [
            f"{self.base_url}/medicine/",
            f"{self.base_url}/medical/",
            f"{self.base_url}/graduate/",
            f"{self.base_url}/research/",
            f"{self.base_url}/faculty/"
        ]
        
        urls.extend(faculty_urls)
        return urls
    
    async def _discover_admission_urls(self) -> List[str]:
        """総合型選抜URLを発見"""
        urls = []
        
        if not self.base_url:
            return urls
        
        # 入試情報ページを探索
        admission_urls = [
            f"{self.base_url}/admissions/",
            f"{self.base_url}/entrance/",
            f"{self.base_url}/exam/",
            f"{self.base_url}/nyushi/",
            f"{self.base_url}/ao/"
        ]
        
        urls.extend(admission_urls)
        return urls
    
    async def _scrape_single_page(self, url: str) -> List[ResearchLabData]:
        """単一ページのスクレイピング"""
        try:
            # HTMLを取得
            html_content = await self.http_client.get_text(url)
            
            # パース
            self.parser.parse_html(html_content)
            
            # 研究室情報を抽出
            raw_labs = self.parser.extract_research_labs()
            
            # ResearchLabDataに変換
            lab_data_list = []
            for raw_lab in raw_labs:
                try:
                    lab_data = self._convert_to_research_lab_data(raw_lab, url)
                    if self.validate_data(lab_data):
                        lab_data_list.append(lab_data)
                except Exception as e:
                    logger.warning(f"研究室データ変換失敗: {e}")
                    continue
            
            return lab_data_list
            
        except Exception as e:
            logger.error(f"ページスクレイピング失敗 {url}: {e}")
            return []
    
    async def _scrape_admission_page(self, url: str) -> List[AdmissionData]:
        """総合型選抜ページのスクレイピング"""
        try:
            html_content = await self.http_client.get_text(url)
            # 総合型選抜情報の抽出（簡易実装）
            
            # プレースホルダー実装
            admission_data = AdmissionData(
                university_id=self.university.info.id,
                faculty="医学部",  # 実際の実装では動的に抽出
                department=None,
                is_available=True,
                quota="若干名",
                info_url=url
            )
            
            return [admission_data]
            
        except Exception as e:
            logger.error(f"総合型選抜ページスクレイピング失敗 {url}: {e}")
            return []
    
    def _convert_to_research_lab_data(self, raw_lab: Dict[str, str], source_url: str) -> ResearchLabData:
        """生データをResearchLabDataに変換"""
        return ResearchLabData(
            name=raw_lab.get('name', '').strip(),
            professor_name=raw_lab.get('professor_name', '').strip(),
            department=raw_lab.get('department', '').strip(),
            faculty=self._determine_faculty_from_url(source_url),
            research_content=raw_lab.get('research_content', '').strip(),
            university_id=self.university.info.id,
            lab_url=self._resolve_lab_url(raw_lab.get('lab_url', ''), source_url),
            keywords=raw_lab.get('keywords', ''),
            immune_relevance_score=raw_lab.get('immune_relevance_score')
        )
    
    def _determine_faculty_from_url(self, url: str) -> str:
        """URLから学部を推定"""
        url_lower = url.lower()
        
        if any(keyword in url_lower for keyword in ['medical', 'medicine', '医学']):
            return 'medicine'
        elif any(keyword in url_lower for keyword in ['agriculture', '農学', '農業']):
            return 'agriculture'
        elif any(keyword in url_lower for keyword in ['veterinary', '獣医']):
            return 'veterinary'
        elif any(keyword in url_lower for keyword in ['science', '理学']):
            return 'science'
        else:
            return 'general'
    
    def _resolve_lab_url(self, lab_url: str, base_url: str) -> str:
        """研究室URLを絶対URLに変換"""
        if not lab_url:
            return ""
        
        if lab_url.startswith('http'):
            return lab_url
        
        return urljoin(base_url, lab_url)
    
    async def _validate_and_enrich_labs(self, labs: List[ResearchLabData]) -> List[ResearchLabData]:
        """研究室データの検証と強化"""
        validated_labs = []
        
        for lab in labs:
            try:
                # 基本バリデーション
                if not self.validate_data(lab):
                    continue
                
                # データ強化（免疫関連度計算など）
                enriched_lab = await self._enrich_lab_data(lab)
                validated_labs.append(enriched_lab)
                
            except Exception as e:
                logger.warning(f"研究室データ検証失敗: {e}")
                continue
        
        return validated_labs
    
    async def _enrich_lab_data(self, lab: ResearchLabData) -> ResearchLabData:
        """研究室データの強化"""
        # 免疫関連度分析
        from scraper.domain.keyword_analyzer import keyword_analyzer
        
        if lab.research_content:
            analysis_result = keyword_analyzer.analyze_content(lab.research_content)
            lab.immune_relevance_score = analysis_result.immune_relevance_score
            lab.research_field = analysis_result.field_classification
            
            # キーワード統合
            if analysis_result.matched_keywords:
                existing_keywords = lab.keywords or ''
                new_keywords = ', '.join(analysis_result.matched_keywords)
                lab.keywords = f"{existing_keywords}, {new_keywords}".strip(', ')
        
        return lab
