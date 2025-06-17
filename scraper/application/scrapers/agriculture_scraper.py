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
