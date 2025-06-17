"""
大学ドメインオブジェクト
大学に関するビジネスルールを管理
"""

from dataclasses import dataclass
from typing import List, Optional, Dict, Any
from enum import Enum

from scraper.config.interfaces import UniversityType, FacultyType


@dataclass
class UniversityInfo:
    """大学情報"""
    id: int
    name: str
    type: UniversityType
    prefecture: str
    region: str
    website_url: Optional[str] = None
    established_year: Optional[int] = None
    description: Optional[str] = None


@dataclass
class FacultyInfo:
    """学部情報"""
    name: str
    faculty_type: FacultyType
    department_count: int = 0
    research_lab_count: int = 0
    has_graduate_school: bool = False
    admission_quota: Optional[int] = None


class University:
    """
    大学エンティティ
    大学に関するビジネスルールと制約を管理
    """
    
    def __init__(self, info: UniversityInfo):
        self._info = info
        self._faculties: Dict[str, FacultyInfo] = {}
        self._target_faculties: List[str] = []
        self._priority_level: int = 3  # 1=最高, 2=高, 3=中, 4=低
    
    @property
    def info(self) -> UniversityInfo:
        return self._info
    
    @property
    def name(self) -> str:
        return self._info.name
    
    @property
    def type(self) -> UniversityType:
        return self._info.type
    
    @property
    def region(self) -> str:
        return self._info.region
    
    @property
    def prefecture(self) -> str:
        return self._info.prefecture
    
    @property
    def faculties(self) -> Dict[str, FacultyInfo]:
        return self._faculties.copy()
    
    @property
    def priority_level(self) -> int:
        return self._priority_level
    
    def add_faculty(self, faculty_info: FacultyInfo) -> None:
        """学部を追加"""
        self._faculties[faculty_info.name] = faculty_info
    
    def set_target_faculties(self, faculty_names: List[str]) -> None:
        """対象学部を設定"""
        self._target_faculties = faculty_names.copy()
    
    def get_target_faculties(self) -> List[str]:
        """対象学部を取得"""
        return self._target_faculties.copy()
    
    def set_priority_level(self, level: int) -> None:
        """優先度レベルを設定（1=最高, 4=最低）"""
        if not 1 <= level <= 4:
            raise ValueError("Priority level must be between 1 and 4")
        self._priority_level = level
    
    def has_faculty(self, faculty_name: str) -> bool:
        """指定された学部があるかチェック"""
        return faculty_name in self._faculties
    
    def has_medical_faculty(self) -> bool:
        """医学部があるかチェック"""
        return any(
            faculty.faculty_type == FacultyType.MEDICINE 
            for faculty in self._faculties.values()
        )
    
    def has_agriculture_faculty(self) -> bool:
        """農学部があるかチェック"""
        return any(
            faculty.faculty_type in [FacultyType.AGRICULTURE, FacultyType.VETERINARY]
            for faculty in self._faculties.values()
        )
    
    def is_tier1_university(self) -> bool:
        """Tier1大学（医学・農学強豪）かチェック"""
        tier1_names = [
            "東京大学", "京都大学", "大阪大学", "東北大学",
            "東京農工大学", "北海道大学", "帯広畜産大学"
        ]
        return self.name in tier1_names
    
    def is_tier2_university(self) -> bool:
        """Tier2大学（旧帝大・難関国立）かチェック"""
        tier2_names = [
            "名古屋大学", "九州大学", "神戸大学", "筑波大学",
            "千葉大学", "新潟大学", "金沢大学", "岡山大学"
        ]
        return self.name in tier2_names
    
    def get_scraping_priority(self) -> int:
        """スクレイピング優先度を計算"""
        priority = self._priority_level
        
        # Tier1は最優先
        if self.is_tier1_university():
            priority = 1
        elif self.is_tier2_university():
            priority = 2
        
        # 医学部・農学部がある場合は優先度向上
        if self.has_medical_faculty() and self.has_agriculture_faculty():
            priority = max(1, priority - 1)
        elif self.has_medical_faculty() or self.has_agriculture_faculty():
            priority = max(2, priority - 1)
        
        return priority
    
    def estimate_research_lab_count(self) -> int:
        """推定研究室数を計算"""
        base_count = 0
        
        # 大学規模による基準値
        if self.type == UniversityType.NATIONAL:
            base_count = 30
        elif self.type == UniversityType.PUBLIC:
            base_count = 15
        else:  # PRIVATE
            base_count = 20
        
        # 学部数による調整
        faculty_count = len(self._faculties)
        adjusted_count = base_count + (faculty_count * 5)
        
        # Tier調整
        if self.is_tier1_university():
            adjusted_count = int(adjusted_count * 1.5)
        elif self.is_tier2_university():
            adjusted_count = int(adjusted_count * 1.2)
        
        return adjusted_count
    
    def __str__(self) -> str:
        return f"University({self.name} - {self.type.value})"
    
    def __repr__(self) -> str:
        return (f"University(name='{self.name}', type='{self.type.value}', "
                f"region='{self.region}', priority={self.priority_level})")
    
    def __eq__(self, other) -> bool:
        if not isinstance(other, University):
            return False
        return self.name == other.name
    
    def __hash__(self) -> int:
        return hash(self.name)


# ユーティリティ関数
def create_university_from_config(config: Dict[str, Any]) -> University:
    """
    設定辞書から大学エンティティを作成
    
    Args:
        config: 大学設定辞書
    
    Returns:
        University: 大学エンティティ
    """
    info = UniversityInfo(
        id=config.get('id', 0),
        name=config['name'],
        type=UniversityType(config['type']),
        prefecture=config['prefecture'],
        region=config['region'],
        website_url=config.get('website_url'),
        established_year=config.get('established_year'),
        description=config.get('description')
    )
    
    university = University(info)
    
    # 学部情報を追加
    for faculty_data in config.get('faculties', []):
        faculty_info = FacultyInfo(
            name=faculty_data['name'],
            faculty_type=FacultyType(faculty_data['type']),
            department_count=faculty_data.get('department_count', 0),
            has_graduate_school=faculty_data.get('has_graduate_school', False)
        )
        university.add_faculty(faculty_info)
    
    # 対象学部を設定
    if 'target_faculties' in config:
        university.set_target_faculties(config['target_faculties'])
    
    # 優先度を設定
    if 'priority_level' in config:
        university.set_priority_level(config['priority_level'])
    
    return university
