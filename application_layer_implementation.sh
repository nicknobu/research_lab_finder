#!/bin/bash

echo "🚀 Application層（ビジネスロジック実装）を実装中..."

# ==================== 1. Scrapers（スクレイパー層）実装 ====================
echo "🔬 Scrapers（スクレイパー層）を実装中..."

# 基底スクレイパー
cat > scraper/application/scrapers/university_scraper_base.py << 'EOF'
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
EOF

# 医学部専用スクレイパー
cat > scraper/application/scrapers/medical_scraper.py << 'EOF'
"""
医学部専用スクレイパー
医学系研究室に特化した情報抽出
"""

import re
from typing import List, Dict
import logging

from scraper.application.scrapers.university_scraper_base import UniversityScraperBase
from scraper.domain.university import University

logger = logging.getLogger(__name__)


class MedicalLabScraper(UniversityScraperBase):
    """医学部研究室専用スクレイパー"""
    
    def __init__(self, university: University):
        super().__init__(university)
        self.medical_keywords = [
            '医学部', '医学研究科', '医学院', 'medical', 'medicine',
            '医療', '臨床', 'clinical', '病院', 'hospital'
        ]
        self.immune_indicators = [
            '免疫', 'immunology', 'immunity', 'アレルギー', 'allergy',
            'がん免疫', 'cancer immunology', '感染症', 'infection',
            'ワクチン', 'vaccine', '自己免疫', 'autoimmune'
        ]
    
    async def _discover_target_urls(self) -> List[str]:
        """医学部特化のURL発見"""
        urls = []
        
        if not self.base_url:
            return urls
        
        # 医学部特化URL
        medical_urls = [
            f"{self.base_url}/medicine/",
            f"{self.base_url}/medical/",
            f"{self.base_url}/med/",
            f"{self.base_url}/graduate/medicine/",
            f"{self.base_url}/research/medicine/",
            f"{self.base_url}/faculty/medicine/",
            # 日本語URL
            f"{self.base_url}/医学部/",
            f"{self.base_url}/医学研究科/",
            f"{self.base_url}/研究/医学/"
        ]
        
        # 免疫学特化URL
        immune_urls = [
            f"{self.base_url}/immunology/",
            f"{self.base_url}/research/immunology/",
            f"{self.base_url}/免疫学/",
            f"{self.base_url}/研究/免疫/"
        ]
        
        urls.extend(medical_urls)
        urls.extend(immune_urls)
        
        # 大学固有のURL発見
        university_specific_urls = await self._discover_university_specific_urls()
        urls.extend(university_specific_urls)
        
        return urls
    
    async def _discover_university_specific_urls(self) -> List[str]:
        """大学固有のURL発見"""
        urls = []
        university_name = self.university.name
        
        # 大学別の特別なURL構造
        if "東京大学" in university_name:
            urls.extend([
                f"{self.base_url}/faculty/medicine/",
                f"{self.base_url}/graduate/medicine/",
                "https://www.m.u-tokyo.ac.jp/research/"
            ])
        elif "京都大学" in university_name:
            urls.extend([
                f"{self.base_url}/med/",
                "https://www.med.kyoto-u.ac.jp/research/"
            ])
        elif "大阪大学" in university_name:
            urls.extend([
                f"{self.base_url}/medicine/",
                "https://www.med.osaka-u.ac.jp/research/"
            ])
        elif "東北大学" in university_name:
            urls.extend([
                "https://www.med.tohoku.ac.jp/research/",
                "https://www.tohoku.ac.jp/japanese/research/"
            ])
        elif "北海道大学" in university_name:
            urls.extend([
                "https://www.med.hokudai.ac.jp/research/",
                "https://www.hokudai.ac.jp/research/"
            ])
        elif "千葉大学" in university_name:
            urls.extend([
                "https://www.m.chiba-u.ac.jp/research/",
                "https://www.chiba-u.ac.jp/research/"
            ])
        elif "順天堂大学" in university_name:
            urls.extend([
                "https://www.juntendo.ac.jp/faculty/medicine/",
                "https://www.juntendo.ac.jp/research/"
            ])
        
        return urls
    
    async def _scrape_single_page(self, url: str) -> List[Dict[str, str]]:
        """医学部特化の単一ページスクレイピング"""
        try:
            # 基底クラスのメソッドを実行
            base_labs = await super()._scrape_single_page(url)
            
            # 医学部・免疫学特化フィルタリング
            medical_labs = []
            for lab in base_labs:
                if self._is_medical_immune_lab(lab):
                    enhanced_lab = self._enhance_medical_lab_data(lab)
                    medical_labs.append(enhanced_lab)
            
            logger.info(f"🏥 医学部フィルタリング: {len(base_labs)}件 → {len(medical_labs)}件")
            return medical_labs
            
        except Exception as e:
            logger.error(f"医学部ページスクレイピング失敗 {url}: {e}")
            return []
    
    def _is_medical_immune_lab(self, lab_data) -> bool:
        """医学・免疫関連研究室かどうかを判定"""
        content_text = (
            lab_data.research_content + " " + 
            lab_data.name + " " + 
            lab_data.department
        ).lower()
        
        # 医学関連キーワードチェック
        has_medical = any(keyword.lower() in content_text for keyword in self.medical_keywords)
        
        # 免疫関連キーワードチェック
        has_immune = any(keyword.lower() in content_text for keyword in self.immune_indicators)
        
        # 医学関連または免疫関連であればOK
        return has_medical or has_immune
    
    def _enhance_medical_lab_data(self, lab_data) -> Dict[str, str]:
        """医学部研究室データの強化"""
        enhanced_data = lab_data.copy()
        
        # 診療科・専門分野の抽出
        specialties = self._extract_medical_specialties(lab_data.research_content)
        if specialties:
            existing_keywords = enhanced_data.get('keywords', '')
            specialty_keywords = ', '.join(specialties)
            enhanced_data['keywords'] = f"{existing_keywords}, {specialty_keywords}".strip(', ')
        
        # 研究手法の抽出
        methods = self._extract_research_methods(lab_data.research_content)
        if methods:
            enhanced_data['research_methods'] = ', '.join(methods)
        
        # 学部・研究科の正規化
        enhanced_data['faculty'] = 'medicine'
        
        return enhanced_data
    
    def _extract_medical_specialties(self, content: str) -> List[str]:
        """医学専門分野を抽出"""
        specialties = []
        content_lower = content.lower()
        
        medical_specialties = [
            '内科', 'internal medicine', '外科', 'surgery',
            '小児科', 'pediatrics', '産婦人科', 'obstetrics',
            '整形外科', 'orthopedics', '皮膚科', 'dermatology',
            '眼科', 'ophthalmology', '耳鼻咽喉科', 'otolaryngology',
            '精神科', 'psychiatry', '放射線科', 'radiology',
            '麻酔科', 'anesthesiology', '病理', 'pathology',
            '免疫学', 'immunology', '感染症学', 'infectious disease',
            'がん学', 'oncology', 'アレルギー学', 'allergology'
        ]
        
        for specialty in medical_specialties:
            if specialty.lower() in content_lower:
                specialties.append(specialty)
        
        return list(set(specialties))
    
    def _extract_research_methods(self, content: str) -> List[str]:
        """研究手法を抽出"""
        methods = []
        content_lower = content.lower()
        
        research_methods = [
            'PCR', 'qPCR', 'RT-PCR', 'Western blot', 'ELISA',
            'FACS', 'フローサイトメトリー', 'flow cytometry',
            'RNA-seq', 'ChIP-seq', 'マイクロアレイ', 'microarray',
            'CRISPR', 'クローニング', 'cloning',
            '細胞培養', 'cell culture', 'in vitro', 'in vivo',
            '動物実験', 'animal model', 'マウス', 'mouse',
            '臨床試験', 'clinical trial', '疫学調査', 'epidemiology'
        ]
        
        for method in research_methods:
            if method.lower() in content_lower:
                methods.append(method)
        
        return list(set(methods))
EOF

# 農学部専用スクレイパー（新規）
cat > scraper/application/scrapers/agriculture_scraper.py << 'EOF'
"""
農学部専用スクレイパー（新規実装）
農学・食品・動物免疫研究に特化
"""

import re
from typing import List, Dict
import logging

from scraper.application.scrapers.university_scraper_base import UniversityScraperBase
from scraper.domain.university import University

logger = logging.getLogger(__name__)


class AgricultureLabScraper(UniversityScraperBase):
    """農学部研究室専用スクレイパー"""
    
    def __init__(self, university: University):
        super().__init__(university)
        self.agriculture_keywords = [
            '農学部', '農学研究科', '農業', 'agriculture', 'agricultural',
            '食品', 'food', '栄養', 'nutrition', '生物資源', 'bioresource'
        ]
        self.animal_immune_indicators = [
            '動物免疫', 'animal immunity', '家畜免疫', 'livestock immunity',
            '獣医', 'veterinary', '動物', 'animal', '家畜', 'livestock',
            '牛', 'cattle', '豚', 'pig', '鶏', 'chicken', '魚', 'fish'
        ]
        self.plant_indicators = [
            '植物免疫', 'plant immunity', '植物病理', 'plant pathology',
            '作物', 'crop', '植物', 'plant', '育種', 'breeding'
        ]
        self.food_indicators = [
            '食品免疫', 'food immunity', '機能性食品', 'functional food',
            'プロバイオティクス', 'probiotics', '発酵', 'fermentation',
            '腸内細菌', 'gut microbiota'
        ]
    
    async def _discover_target_urls(self) -> List[str]:
        """農学部特化のURL発見"""
        urls = []
        
        if not self.base_url:
            return urls
        
        # 農学部特化URL
        agriculture_urls = [
            f"{self.base_url}/agriculture/",
            f"{self.base_url}/agricultural/",
            f"{self.base_url}/agr/",
            f"{self.base_url}/bioresource/",
            f"{self.base_url}/food/",
            f"{self.base_url}/veterinary/",
            # 日本語URL
            f"{self.base_url}/農学部/",
            f"{self.base_url}/農学研究科/",
            f"{self.base_url}/獣医学部/",
            f"{self.base_url}/生物資源/"
        ]
        
        # 動物・食品・植物免疫特化URL
        specialized_urls = [
            f"{self.base_url}/animal/",
            f"{self.base_url}/livestock/",
            f"{self.base_url}/veterinary/",
            f"{self.base_url}/plant/",
            f"{self.base_url}/crop/",
            f"{self.base_url}/food/",
            f"{self.base_url}/nutrition/"
        ]
        
        urls.extend(agriculture_urls)
        urls.extend(specialized_urls)
        
        # 農学系大学固有URL
        university_specific_urls = await self._discover_agriculture_specific_urls()
        urls.extend(university_specific_urls)
        
        return urls
    
    async def _discover_agriculture_specific_urls(self) -> List[str]:
        """農学系大学固有のURL発見"""
        urls = []
        university_name = self.university.name
        
        # 農学系大学別の特別なURL構造
        if "東京農工大学" in university_name:
            urls.extend([
                "https://www.tuat.ac.jp/outline/faculty/agriculture/",
                "https://www.tuat.ac.jp/research/"
            ])
        elif "北海道大学" in university_name:
            urls.extend([
                "https://www.agr.hokudai.ac.jp/",
                "https://www.vet.hokudai.ac.jp/"
            ])
        elif "帯広畜産大学" in university_name:
            urls.extend([
                "https://www.obihiro.ac.jp/research/",
                "https://www.obihiro.ac.jp/faculty/"
            ])
        elif "岐阜大学" in university_name:
            urls.extend([
                "https://www.gifu-u.ac.jp/education/faculty/applied_biological_sciences/",
                "https://www.gifu-u.ac.jp/research/"
            ])
        elif "鳥取大学" in university_name:
            urls.extend([
                "https://www.tottori-u.ac.jp/dd.aspx?menuid=1414",
                "https://www.ag.tottori-u.ac.jp/"
            ])
        elif "宮崎大学" in university_name:
            urls.extend([
                "https://www.miyazaki-u.ac.jp/agriculture/",
                "https://www.vet.miyazaki-u.ac.jp/"
            ])
        
        return urls
    
    def _is_agriculture_immune_lab(self, lab_data) -> bool:
        """農学・動物・食品免疫関連研究室かどうかを判定"""
        content_text = (
            lab_data.research_content + " " + 
            lab_data.name + " " + 
            lab_data.department
        ).lower()
        
        # 農学関連キーワードチェック
        has_agriculture = any(keyword.lower() in content_text for keyword in self.agriculture_keywords)
        
        # 動物免疫関連キーワードチェック
        has_animal_immune = any(keyword.lower() in content_text for keyword in self.animal_immune_indicators)
        
        # 植物免疫関連キーワードチェック
        has_plant_immune = any(keyword.lower() in content_text for keyword in self.plant_indicators)
        
        # 食品免疫関連キーワードチェック
        has_food_immune = any(keyword.lower() in content_text for keyword in self.food_indicators)
        
        # いずれかの農学・免疫関連であればOK
        return has_agriculture or has_animal_immune or has_plant_immune or has_food_immune
    
    def _enhance_agriculture_lab_data(self, lab_data) -> Dict[str, str]:
        """農学部研究室データの強化"""
        enhanced_data = lab_data.copy()
        
        # 動物種の抽出
        animal_species = self._extract_animal_species(lab_data.research_content)
        if animal_species:
            enhanced_data['animal_species'] = ', '.join(animal_species)
        
        # 植物種の抽出
        plant_species = self._extract_plant_species(lab_data.research_content)
        if plant_species:
            enhanced_data['plant_species'] = ', '.join(plant_species)
        
        # 農学研究分野の特定
        research_area = self._determine_agriculture_research_area(lab_data.research_content)
        enhanced_data['agriculture_research_area'] = research_area
        
        # 学部・研究科の正規化
        enhanced_data['faculty'] = 'agriculture'
        
        return enhanced_data
    
    def _extract_animal_species(self, content: str) -> List[str]:
        """動物種を抽出"""
        species = []
        content_lower = content.lower()
        
        animal_species_list = [
            '牛', 'cattle', 'bovine', '乳牛', 'dairy cow',
            '豚', 'pig', 'swine', 'porcine',
            '鶏', 'chicken', 'poultry', '家禽',
            '魚', 'fish', '養殖魚', 'aquaculture',
            '羊', 'sheep', 'ovine', '山羊', 'goat',
            '馬', 'horse', 'equine', '犬', 'dog', 'canine',
            '猫', 'cat', 'feline', 'マウス', 'mouse',
            'ラット', 'rat', 'ウサギ', 'rabbit'
        ]
        
        for animal in animal_species_list:
            if animal.lower() in content_lower:
                species.append(animal)
        
        return list(set(species))
    
    def _extract_plant_species(self, content: str) -> List[str]:
        """植物種を抽出"""
        species = []
        content_lower = content.lower()
        
        plant_species_list = [
            '稲', 'rice', 'イネ', 'トマト', 'tomato',
            '大豆', 'soybean', '小麦', 'wheat',
            'トウモロコシ', 'corn', 'maize', 'ジャガイモ', 'potato',
            'キャベツ', 'cabbage', 'ニンジン', 'carrot',
            'リンゴ', 'apple', 'ミカン', 'orange',
            'バラ', 'rose', 'アラビドプシス', 'arabidopsis'
        ]
        
        for plant in plant_species_list:
            if plant.lower() in content_lower:
                species.append(plant)
        
        return list(set(species))
    
    def _determine_agriculture_research_area(self, content: str) -> str:
        """農学研究分野を特定"""
        content_lower = content.lower()
        
        if any(kw in content_lower for kw in ['animal', '動物', 'livestock', '家畜']):
            return '動物科学'
        elif any(kw in content_lower for kw in ['plant', '植物', 'crop', '作物']):
            return '植物科学'
        elif any(kw in content_lower for kw in ['food', '食品', 'nutrition', '栄養']):
            return '食品科学'
        elif any(kw in content_lower for kw in ['environment', '環境', 'ecology', '生態']):
            return '環境科学'
        elif any(kw in content_lower for kw in ['biotechnology', 'バイオテクノロジー', 'genetic']):
            return 'バイオテクノロジー'
        else:
            return '農学一般'
EOF

echo "✅ Scrapers（スクレイパー層）実装完了"

# ==================== 2. Pipelines（データ処理パイプライン）実装 ====================
echo "⚙️ Pipelines（データ処理パイプライン）を実装中..."

# データ処理パイプライン
cat > scraper/application/pipelines/lab_processing.py << 'EOF'
"""
研究室データ処理パイプライン
データの統合・強化・品質管理
"""

import asyncio
from typing import List, Dict, Optional, Tuple
import logging
from datetime import datetime

from scraper.config.interfaces import ResearchLabData, DataValidationError
from scraper.domain.research_lab import ResearchLab, create_research_lab_from_data
from scraper.domain.university import University
from scraper.domain.keyword_analyzer import keyword_analyzer
from scraper.config.settings import quality_settings

logger = logging.getLogger(__name__)


class LabDataProcessor:
    """研究室データ処理パイプライン"""
    
    def __init__(self):
        self.processed_count = 0
        self.rejected_count = 0
        self.duplicate_count = 0
        self.enhanced_count = 0
    
    async def process_lab_data_batch(
        self, 
        raw_labs: List[ResearchLabData],
        university: University
    ) -> List[ResearchLab]:
        """研究室データのバッチ処理"""
        logger.info(f"🔄 {university.name}: {len(raw_labs)}件の研究室データ処理開始")
        
        # Step 1: 基本バリデーション
        validated_labs = await self._validate_basic_requirements(raw_labs)
        logger.info(f"📋 基本バリデーション: {len(validated_labs)}/{len(raw_labs)}件合格")
        
        # Step 2: 重複除去
        deduplicated_labs = await self._remove_duplicates(validated_labs)
        self.duplicate_count += len(validated_labs) - len(deduplicated_labs)
        logger.info(f"🔍 重複除去: {len(deduplicated_labs)}件（{self.duplicate_count}件除去）")
        
        # Step 3: データ強化
        enhanced_labs = await self._enhance_lab_data(deduplicated_labs, university)
        logger.info(f"⚡ データ強化: {len(enhanced_labs)}件")
        
        # Step 4: 品質フィルタリング
        quality_filtered_labs = await self._filter_by_quality(enhanced_labs)
        self.rejected_count += len(enhanced_labs) - len(quality_filtered_labs)
        logger.info(f"🎯 品質フィルタリング: {len(quality_filtered_labs)}件（{len(enhanced_labs) - len(quality_filtered_labs)}件除外）")
        
        # Step 5: ResearchLabエンティティ作成
        research_labs = await self._create_research_lab_entities(quality_filtered_labs, university)
        self.processed_count += len(research_labs)
        
        logger.info(f"✅ {university.name}: {len(research_labs)}件の研究室データ処理完了")
        return research_labs
    
    async def _validate_basic_requirements(self, labs: List[ResearchLabData]) -> List[ResearchLabData]:
        """基本要件バリデーション"""
        validated_labs = []
        
        for lab in labs:
            try:
                # 必須フィールドチェック
                if not lab.name or len(lab.name.strip()) < 3:
                    continue
                
                if not lab.professor_name or len(lab.professor_name.strip()) < 2:
                    continue
                
                if not lab.research_content or len(lab.research_content) < quality_settings.min_content_length:
                    continue
                
                # 研究内容の質チェック
                if not self._is_meaningful_content(lab.research_content):
                    continue
                
                validated_labs.append(lab)
                
            except Exception as e:
                logger.warning(f"基本バリデーション失敗: {e}")
                continue
        
        return validated_labs
    
    def _is_meaningful_content(self, content: str) -> bool:
        """研究内容が意味のあるコンテンツかチェック"""
        if not content:
            return False
        
        # 最小文字数チェック
        if len(content) < 50:
            return False
        
        # 意味のある単語の数をチェック
        meaningful_words = [
            '研究', 'research', '開発', 'development', '解析', 'analysis',
            '実験', 'experiment', '検討', '調査', 'investigation',
            '技術', 'technology', '手法', 'method', '理論', 'theory'
        ]
        
        word_count = sum(1 for word in meaningful_words if word.lower() in content.lower())
        return word_count >= 2
    
    async def _remove_duplicates(self, labs: List[ResearchLabData]) -> List[ResearchLabData]:
        """重複研究室の除去"""
        seen_signatures = set()
        unique_labs = []
        
        for lab in labs:
            # 重複判定のシグネチャ作成
            signature = self._create_lab_signature(lab)
            
            if signature not in seen_signatures:
                seen_signatures.add(signature)
                unique_labs.append(lab)
        
        return unique_labs
    
    def _create_lab_signature(self, lab: ResearchLabData) -> str:
        """研究室の重複判定用シグネチャ作成"""
        # 研究室名と教授名を正規化して結合
        normalized_name = self._normalize_text(lab.name)
        normalized_professor = self._normalize_text(lab.professor_name)
        
        return f"{normalized_name}#{normalized_professor}#{lab.university_id}"
    
    def _normalize_text(self, text: str) -> str:
        """テキストの正規化"""
        if not text:
            return ""
        
        # 小文字化、空白除去、記号除去
        import re
        normalized = re.sub(r'[^\w\s]', '', text.lower())
        normalized = re.sub(r'\s+', '', normalized)
        
        return normalized
    
    async def _enhance_lab_data(self, labs: List[ResearchLabData], university: University) -> List[ResearchLabData]:
        """データ強化処理"""
        enhanced_labs = []
        
        for lab in labs:
            try:
                enhanced_lab = await self._enhance_single_lab(lab, university)
                enhanced_labs.append(enhanced_lab)
                self.enhanced_count += 1
                
            except Exception as e:
                logger.warning(f"データ強化失敗 {lab.name}: {e}")
                # 強化に失敗してもオリジナルデータは保持
                enhanced_labs.append(lab)
        
        return enhanced_labs
    
    async def _enhance_single_lab(self, lab: ResearchLabData, university: University) -> ResearchLabData:
        """単一研究室のデータ強化"""
        enhanced_lab = lab
        
        # 免疫関連度分析
        if lab.research_content:
            analysis_result = keyword_analyzer.analyze_content(lab.research_content)
            
            enhanced_lab.immune_relevance_score = analysis_result.immune_relevance_score
            enhanced_lab.research_field = analysis_result.field_classification
            
            # キーワード統合
            if analysis_result.matched_keywords:
                existing_keywords = lab.keywords or ''
                new_keywords = ', '.join(analysis_result.matched_keywords)
                enhanced_lab.keywords = f"{existing_keywords}, {new_keywords}".strip(', ')
            
            # 動物種・植物種情報
            if analysis_result.animal_species:
                enhanced_lab.animal_species = ', '.join(analysis_result.animal_species)
            
            if analysis_result.plant_species:
                enhanced_lab.plant_species = ', '.join(analysis_result.plant_species)
        
        # 大学情報の統合
        enhanced_lab.university_id = university.info.id
        
        # メタデータの追加
        if not enhanced_lab.metadata:
            enhanced_lab.metadata = {}
        
        enhanced_lab.metadata.update({
            'processed_at': datetime.now().isoformat(),
            'university_tier': 1 if university.is_tier1_university() else 2 if university.is_tier2_university() else 3,
            'university_type': university.type.value,
            'university_region': university.region
        })
        
        return enhanced_lab
    
    async def _filter_by_quality(self, labs: List[ResearchLabData]) -> List[ResearchLabData]:
        """品質基準によるフィルタリング"""
        quality_labs = []
        
        for lab in labs:
            try:
                quality_score = self._calculate_quality_score(lab)
                
                # 品質スコアが基準を満たす場合のみ通す
                if quality_score >= 0.6:  # 60%以上の品質スコア
                    if not lab.metadata:
                        lab.metadata = {}
                    lab.metadata['quality_score'] = quality_score
                    quality_labs.append(lab)
                
            except Exception as e:
                logger.warning(f"品質評価失敗 {lab.name}: {e}")
                continue
        
        return quality_labs
    
    def _calculate_quality_score(self, lab: ResearchLabData) -> float:
        """データ品質スコア計算"""
        score = 0.0
        total_weight = 0.0
        
        # 基本情報の完全性（50%）
        if lab.name and len(lab.name) > 5:
            score += 0.2; total_weight += 0.2
        if lab.professor_name and len(lab.professor_name) > 2:
            score += 0.15; total_weight += 0.15
        if lab.research_content and len(lab.research_content) > 100:
            score += 0.15; total_weight += 0.15
        
        # 詳細情報の充実度（30%）
        if lab.keywords and len(lab.keywords.split(',')) >= 3:
            score += 0.15; total_weight += 0.15
        if lab.lab_url:
            score += 0.15; total_weight += 0.15
        
        # 免疫関連度（20%）
        if lab.immune_relevance_score and lab.immune_relevance_score >= quality_settings.min_immune_relevance_score:
            score += 0.2; total_weight += 0.2
        
        return score / total_weight if total_weight > 0 else 0.0
    
    async def _create_research_lab_entities(self, labs: List[ResearchLabData], university: University) -> List[ResearchLab]:
        """ResearchLabエンティティの作成"""
        research_labs = []
        
        for lab_data in labs:
            try:
                research_lab = create_research_lab_from_data(
                    data=lab_data,
                    university_info=university.info
                )
                research_labs.append(research_lab)
                
            except Exception as e:
                logger.error(f"ResearchLabエンティティ作成失敗 {lab_data.name}: {e}")
                continue
        
        return research_labs
    
    def get_processing_stats(self) -> Dict[str, int]:
        """処理統計を取得"""
        return {
            'processed_count': self.processed_count,
            'rejected_count': self.rejected_count,
            'duplicate_count': self.duplicate_count,
            'enhanced_count': self.enhanced_count
        }
EOF

echo "✅ Pipelines（データ処理パイプライン）実装完了"

# ==================== 3. Orchestration（プロセス調整）実装 ====================
echo "🎯 Orchestration（プロセス調整）を実装中..."

# スクレイパーファクトリ
cat > scraper/application/orchestration/scraper_factory.py << 'EOF'
"""
スクレイパーファクトリ
大学・学部に応じた適切なスクレイパーを生成
"""

from typing import Dict, Type, List, Optional
import logging

from scraper.domain.university import University
from scraper.application.scrapers.university_scraper_base import UniversityScraperBase
from scraper.application.scrapers.medical_scraper import MedicalLabScraper
from scraper.application.scrapers.agriculture_scraper import AgricultureLabScraper
from scraper.config.interfaces import ScrapingError

logger = logging.getLogger(__name__)


class ScraperFactory:
    """スクレイパーファクトリ"""
    
    def __init__(self):
        self._scraper_registry: Dict[str, Type[UniversityScraperBase]] = {
            'medical': MedicalLabScraper,
            'agriculture': AgricultureLabScraper,
            'veterinary': AgricultureLabScraper,  # 農学系スクレイパーを流用
            'general': UniversityScraperBase
        }
    
    def create_scraper(self, university: University, faculty_type: str = None) -> UniversityScraperBase:
        """
        大学・学部に応じたスクレイパーを作成
        
        Args:
            university: 大学エンティティ
            faculty_type: 学部種別（自動判定も可能）
        
        Returns:
            UniversityScraperBase: 適切なスクレイパー
        """
        try:
            # 学部種別の自動判定
            if not faculty_type:
                faculty_type = self._determine_faculty_type(university)
            
            # スクレイパークラスの選択
            scraper_class = self._scraper_registry.get(faculty_type, UniversityScraperBase)
            
            # スクレイパー作成
            scraper = scraper_class(university)
            
            logger.info(f"✅ {university.name} 用 {scraper_class.__name__} を作成")
            return scraper
            
        except Exception as e:
            logger.error(f"❌ スクレイパー作成失敗 {university.name}: {e}")
            raise ScrapingError(f"Failed to create scraper for {university.name}: {e}")
    
    def create_multiple_scrapers(self, universities: List[University]) -> List[UniversityScraperBase]:
        """複数大学用のスクレイパーを一括作成"""
        scrapers = []
        
        for university in universities:
            try:
                scraper = self.create_scraper(university)
                scrapers.append(scraper)
            except Exception as e:
                logger.error(f"❌ {university.name} のスクレイパー作成をスキップ: {e}")
                continue
        
        logger.info(f"🏭 {len(scrapers)}/{len(universities)} のスクレイパーを作成")
        return scrapers
    
    def _determine_faculty_type(self, university: University) -> str:
        """大学の特徴から学部種別を自動判定"""
        university_name = university.name.lower()
        
        # 農学・獣医学系大学
        agriculture_indicators = [
            '農工大', '農業大', '畜産大', '獣医大',
            'agriculture', 'veterinary', 'livestock'
        ]
        
        if any(indicator in university_name for indicator in agriculture_indicators):
            return 'agriculture'
        
        # 医科大学
        medical_indicators = [
            '医科大', '医大', '医療大',
            'medical', 'medicine'
        ]
        
        if any(indicator in medical_indicators for indicator in medical_indicators):
            return 'medical'
        
        # 学部情報から判定
        if university.has_medical_faculty() and university.has_agriculture_faculty():
            # 両方ある場合は、優先度で決定（免疫研究の観点）
            return 'medical'
        elif university.has_medical_faculty():
            return 'medical'
        elif university.has_agriculture_faculty():
            return 'agriculture'
        
        # デフォルトは医学系（免疫研究の主要分野）
        return 'medical'
    
    def register_scraper(self, faculty_type: str, scraper_class: Type[UniversityScraperBase]) -> None:
        """新しいスクレイパーを登録"""
        self._scraper_registry[faculty_type] = scraper_class
        logger.info(f"📝 新しいスクレイパーを登録: {faculty_type} -> {scraper_class.__name__}")
    
    def get_available_faculty_types(self) -> List[str]:
        """利用可能な学部種別を取得"""
        return list(self._scraper_registry.keys())
    
    def get_scraper_info(self) -> Dict[str, str]:
        """スクレイパー情報を取得"""
        return {
            faculty_type: scraper_class.__name__ 
            for faculty_type, scraper_class in self._scraper_registry.items()
        }


# グローバルファクトリインスタンス
scraper_factory = ScraperFactory()
EOF

echo "✅ Orchestration（プロセス調整）実装完了"

echo ""
echo "🎉 Application層実装完了！"
echo ""
echo "📋 実装されたコンポーネント:"
echo "├── scraper/application/"
echo "│   ├── scrapers/"
echo "│   │   ├── university_scraper_base.py   # 基底スクレイパー"
echo "│   │   ├── medical_scraper.py           # 医学部専用（既存強化）"
echo "│   │   └── agriculture_scraper.py       # 農学部専用（新規）"
echo "│   ├── pipelines/"
echo "│   │   └── lab_processing.py            # データ処理パイプライン"
echo "│   └── orchestration/"
echo "│       └── scraper_factory.py           # スクレイパーファクトリ"
echo ""
echo "🚀 Application層の特徴:"
echo "• 学部特化：医学部・農学部・獣医学部対応"
echo "• データ品質：自動バリデーション・強化・重複除去"
echo "• 拡張性：ファクトリパターンによる新スクレイパー追加"
echo "• 免疫特化：免疫関連度自動判定・分野分類"
echo "• 農学対応：動物種・植物種の自動抽出"
echo ""
echo "⚡ 次のステップ："
echo "1. 統合テストの実行"
echo "2. 実際の大学サイトでのテスト"
echo "3. データベース連携のテスト"