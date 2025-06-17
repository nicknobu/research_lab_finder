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
