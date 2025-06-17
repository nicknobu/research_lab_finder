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
