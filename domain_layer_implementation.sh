#!/bin/bash

echo "🧬 Domain層（ビジネスロジック）を実装中..."

# ==================== 1. 研究室ドメインオブジェクト ====================
echo "📝 研究室ドメインオブジェクトを作成中..."

cat > scraper/domain/research_lab.py << 'EOF'
"""
研究室ドメインオブジェクト
ビジネスロジックと不変条件を管理
"""

from dataclasses import dataclass, field
from typing import Optional, List, Dict, Any
from enum import Enum

from scraper.config.interfaces import (
    ResearchLabData, ResearchField, FacultyType,
    DataValidationError
)


class ResearchLabStatus(str, Enum):
    """研究室ステータス"""
    ACTIVE = "active"           # アクティブ
    INACTIVE = "inactive"       # 非アクティブ
    PENDING = "pending"         # 検証待ち
    REJECTED = "rejected"       # 却下


@dataclass
class ContactInfo:
    """連絡先情報"""
    email: Optional[str] = None
    phone: Optional[str] = None
    website: Optional[str] = None
    
    def has_contact_info(self) -> bool:
        """連絡先情報があるかチェック"""
        return any([self.email, self.phone, self.website])


@dataclass  
class ResearchKeywords:
    """研究キーワード管理"""
    raw_keywords: str = ""
    extracted_keywords: List[str] = field(default_factory=list)
    immune_keywords: List[str] = field(default_factory=list)
    animal_species: List[str] = field(default_factory=list)
    
    @property
    def keyword_count(self) -> int:
        """キーワード総数"""
        return len(self.extracted_keywords)
    
    @property
    def immune_keyword_count(self) -> int:
        """免疫関連キーワード数"""
        return len(self.immune_keywords)
    
    def add_keyword(self, keyword: str) -> None:
        """キーワード追加"""
        if keyword and keyword not in self.extracted_keywords:
            self.extracted_keywords.append(keyword)


class ResearchLab:
    """
    研究室エンティティ
    ビジネスルールと不変条件を保証
    """
    
    def __init__(
        self, 
        data: ResearchLabData,
        university_info: 'UniversityInfo',
        contact_info: Optional[ContactInfo] = None,
        keywords: Optional[ResearchKeywords] = None
    ):
        self._data = data
        self._university_info = university_info
        self._contact_info = contact_info or ContactInfo()
        self._keywords = keywords or ResearchKeywords()
        self._status = ResearchLabStatus.PENDING
        self._immune_relevance_score: Optional[float] = None
        
        # 作成時のバリデーション
        self._validate_required_fields()
    
    # プロパティアクセス
    @property
    def name(self) -> str:
        return self._data.name
    
    @property
    def professor_name(self) -> str:
        return self._data.professor_name
    
    @property
    def research_content(self) -> str:
        return self._data.research_content
    
    @property
    def research_field(self) -> str:
        return self._data.research_field
    
    @property
    def university_info(self) -> 'UniversityInfo':
        return self._university_info
    
    @property
    def contact_info(self) -> ContactInfo:
        return self._contact_info
    
    @property
    def keywords(self) -> ResearchKeywords:
        return self._keywords
    
    @property
    def status(self) -> ResearchLabStatus:
        return self._status
    
    @property
    def immune_relevance_score(self) -> Optional[float]:
        return self._immune_relevance_score
    
    # ビジネスメソッド
    def _validate_required_fields(self) -> None:
        """必須フィールドの検証"""
        required_fields = ['name', 'professor_name', 'research_content']
        
        for field_name in required_fields:
            value = getattr(self._data, field_name)
            if not value or (isinstance(value, str) and len(value.strip()) == 0):
                raise DataValidationError(f"Required field '{field_name}' is missing or empty")
    
    def update_immune_relevance_score(self, score: float) -> None:
        """免疫関連度スコアを更新"""
        if not 0.0 <= score <= 1.0:
            raise ValueError("Immune relevance score must be between 0.0 and 1.0")
        
        self._immune_relevance_score = score
        
        # スコアに基づいてステータス更新
        if score >= 0.7:
            self._status = ResearchLabStatus.ACTIVE
        elif score >= 0.3:
            self._status = ResearchLabStatus.PENDING
        else:
            self._status = ResearchLabStatus.REJECTED
    
    def add_animal_species(self, species: List[str]) -> None:
        """動物種情報を追加（農学・獣医学用）"""
        if self._data.faculty in ['agriculture', 'veterinary']:
            for species_name in species:
                if species_name not in self._keywords.animal_species:
                    self._keywords.animal_species.append(species_name)
    
    def is_agriculture_related(self) -> bool:
        """農学関連研究室かどうか"""
        agriculture_indicators = [
            'agriculture', '農学', 'veterinary', '獣医',
            'animal', '動物', 'livestock', '家畜',
            'food', '食品', 'nutrition', '栄養'
        ]
        
        content_lower = self.research_content.lower()
        return any(indicator in content_lower for indicator in agriculture_indicators)
    
    def is_medical_related(self) -> bool:
        """医学関連研究室かどうか"""
        medical_indicators = [
            'medical', '医学', 'medicine', 'clinical', '臨床',
            'patient', '患者', 'disease', '疾患', 'therapy', '治療'
        ]
        
        content_lower = self.research_content.lower()
        return any(indicator in content_lower for indicator in medical_indicators)
    
    def calculate_data_quality_score(self) -> float:
        """データ品質スコア計算"""
        score = 0.0
        total_weight = 0.0
        
        # 基本情報の完全性（重み高）
        if self.name and len(self.name) > 3: score += 0.2; total_weight += 0.2
        if self.professor_name: score += 0.2; total_weight += 0.2
        if self.research_content and len(self.research_content) > 50: score += 0.2; total_weight += 0.2
        
        # 詳細情報（重み中）
        if self._data.speciality: score += 0.1; total_weight += 0.1
        if self._data.lab_url: score += 0.1; total_weight += 0.1
        if self.keywords.keyword_count > 0: score += 0.1; total_weight += 0.1
        
        # 連絡先情報（重み低）
        if self.contact_info.has_contact_info(): score += 0.05; total_weight += 0.05
        
        # 免疫関連度（重み低）
        if self.immune_relevance_score is not None: score += 0.05; total_weight += 0.05
        
        return score / total_weight if total_weight > 0 else 0.0
    
    def to_research_lab_data(self) -> ResearchLabData:
        """ResearchLabDataに変換"""
        return self._data
    
    def __str__(self) -> str:
        return f"ResearchLab({self.name} - {self.professor_name}@{self.university_info.name})"
    
    def __repr__(self) -> str:
        return (f"ResearchLab(name='{self.name}', professor='{self.professor_name}', "
                f"university='{self.university_info.name}', status='{self.status.value}')")
    
    def __eq__(self, other) -> bool:
        if not isinstance(other, ResearchLab):
            return False
        return (self.name == other.name and 
                self.professor_name == other.professor_name and
                self.university_info.id == other.university_info.id)
    
    def __hash__(self) -> int:
        return hash((self.name, self.professor_name, self.university_info.id))


# ファクトリーメソッド
def create_research_lab_from_data(
    data: ResearchLabData,
    university_info: 'UniversityInfo',
    contact_info: Optional[ContactInfo] = None,
    keywords: Optional[ResearchKeywords] = None
) -> ResearchLab:
    """
    ResearchLabDataから研究室エンティティを作成
    
    Args:
        data: 研究室データ
        university_info: 大学情報
        contact_info: 連絡先情報（オプション）
        keywords: キーワード情報（オプション）
    
    Returns:
        ResearchLab: 研究室エンティティ
    """
    return ResearchLab(
        data=data,
        university_info=university_info,
        contact_info=contact_info,
        keywords=keywords
    )
EOF

echo "✅ 研究室ドメインオブジェクト完了"

# ==================== 2. 大学ドメインオブジェクト ====================
echo "🏫 大学ドメインオブジェクトを作成中..."

cat > scraper/domain/university.py << 'EOF'
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
EOF

echo "✅ 大学ドメインオブジェクト完了"

# ==================== 3. 免疫関連度解析器 ====================
echo "🔬 免疫関連度解析器を作成中..."

cat > scraper/domain/keyword_analyzer.py << 'EOF'
"""
免疫関連度解析器
研究内容の免疫関連度を計算し、キーワードを抽出
"""

import re
import yaml
from pathlib import Path
from typing import List, Dict, Set, Tuple, Optional
from dataclasses import dataclass

from scraper.config.settings import scraping_settings


@dataclass
class KeywordAnalysisResult:
    """キーワード解析結果"""
    immune_relevance_score: float
    matched_keywords: List[str]
    animal_species: List[str]
    plant_species: List[str]
    research_techniques: List[str]
    field_classification: str


class ImmuneKeywordAnalyzer:
    """免疫関連キーワード解析器"""
    
    def __init__(self):
        self._medical_keywords: Dict[str, List[str]] = {}
        self._agriculture_keywords: Dict[str, List[str]] = {}
        self._animal_species_keywords: List[str] = []
        self._plant_species_keywords: List[str] = []
        self._technique_keywords: List[str] = []
        
        self._load_keywords()
    
    def _load_keywords(self) -> None:
        """キーワードファイルを読み込み"""
        keywords_dir = scraping_settings.keywords_dir
        
        # 医学系キーワード
        medical_file = keywords_dir / "medical_keywords.yaml"
        if medical_file.exists():
            with open(medical_file, 'r', encoding='utf-8') as f:
                self._medical_keywords = yaml.safe_load(f)
        
        # 農学系キーワード
        agriculture_file = keywords_dir / "agriculture_keywords.yaml"
        if agriculture_file.exists():
            with open(agriculture_file, 'r', encoding='utf-8') as f:
                self._agriculture_keywords = yaml.safe_load(f)
        
        # 動物種キーワード
        if 'animal_species' in self._agriculture_keywords:
            self._animal_species_keywords = self._agriculture_keywords['animal_species']
        
        # 植物種キーワード（プレースホルダー）
        self._plant_species_keywords = [
            '稲', 'rice', 'トマト', 'tomato', '大豆', 'soybean',
            '小麦', 'wheat', 'トウモロコシ', 'corn', 'maize'
        ]
        
        # 研究技術キーワード
        self._technique_keywords = [
            'PCR', 'qPCR', 'Western blot', 'ELISA', 'FACS',
            'RNA-seq', 'ChIP-seq', 'CRISPR', 'クローニング',
            '細胞培養', 'cell culture', 'in vitro', 'in vivo'
        ]
    
    def analyze_content(self, content: str) -> KeywordAnalysisResult:
        """
        研究内容を解析して免疫関連度とキーワードを抽出
        
        Args:
            content: 研究内容テキスト
        
        Returns:
            KeywordAnalysisResult: 解析結果
        """
        content_lower = content.lower()
        
        # 免疫関連キーワードのマッチング
        immune_score, matched_keywords = self._calculate_immune_score(content_lower)
        
        # 動物種の抽出
        animal_species = self._extract_animal_species(content_lower)
        
        # 植物種の抽出
        plant_species = self._extract_plant_species(content_lower)
        
        # 研究技術の抽出
        techniques = self._extract_research_techniques(content_lower)
        
        # 研究分野の分類
        field_classification = self._classify_research_field(
            content_lower, matched_keywords, animal_species, plant_species
        )
        
        return KeywordAnalysisResult(
            immune_relevance_score=immune_score,
            matched_keywords=matched_keywords,
            animal_species=animal_species,
            plant_species=plant_species,
            research_techniques=techniques,
            field_classification=field_classification
        )
    
    def _calculate_immune_score(self, content: str) -> Tuple[float, List[str]]:
        """免疫関連度スコアを計算"""
        matched_keywords = []
        total_score = 0.0
        
        # 医学系免疫キーワードのマッチング（重み高）
        for category, keywords in self._medical_keywords.items():
            category_matches = []
            for keyword in keywords:
                if keyword.lower() in content:
                    category_matches.append(keyword)
                    matched_keywords.append(keyword)
            
            # カテゴリ別の重み付け
            if category == 'basic_immunology':
                total_score += len(category_matches) * 0.3
            elif category == 'advanced_research':
                total_score += len(category_matches) * 0.25
            elif category == 'diseases_and_therapy':
                total_score += len(category_matches) * 0.2
            else:
                total_score += len(category_matches) * 0.15
        
        # 農学系免疫キーワードのマッチング（重み中）
        for category, keywords in self._agriculture_keywords.items():
            if category == 'animal_immunity':
                for keyword in keywords:
                    if keyword.lower() in content:
                        matched_keywords.append(keyword)
                        total_score += 0.2
        
        # スコアを0-1の範囲に正規化
        normalized_score = min(total_score / 3.0, 1.0)
        
        return normalized_score, list(set(matched_keywords))
    
    def _extract_animal_species(self, content: str) -> List[str]:
        """動物種を抽出"""
        found_species = []
        
        for species in self._animal_species_keywords:
            if species.lower() in content:
                found_species.append(species)
        
        return list(set(found_species))
    
    def _extract_plant_species(self, content: str) -> List[str]:
        """植物種を抽出"""
        found_species = []
        
        for species in self._plant_species_keywords:
            if species.lower() in content:
                found_species.append(species)
        
        return list(set(found_species))
    
    def _extract_research_techniques(self, content: str) -> List[str]:
        """研究技術を抽出"""
        found_techniques = []
        
        for technique in self._technique_keywords:
            if technique.lower() in content:
                found_techniques.append(technique)
        
        return list(set(found_techniques))
    
    def _classify_research_field(
        self, 
        content: str, 
        immune_keywords: List[str],
        animal_species: List[str],
        plant_species: List[str]
    ) -> str:
        """研究分野を分類"""
        
        # がん免疫学
        if any(kw in content for kw in ['cancer', 'がん', 'tumor', '腫瘍']):
            return 'がん免疫学'
        
        # アレルギー免疫学
        if any(kw in content for kw in ['allergy', 'アレルギー', 'atopic', 'ige']):
            return 'アレルギー免疫学'
        
        # 感染免疫学
        if any(kw in content for kw in ['infection', '感染', 'pathogen', 'virus', 'bacteria']):
            return '感染免疫学'
        
        # 自己免疫学
        if any(kw in content for kw in ['autoimmune', '自己免疫', 'lupus', 'rheumatoid']):
            return '自己免疫学'
        
        # 動物免疫学
        if animal_species and any(kw in content for kw in ['veterinary', '獣医', 'livestock']):
            return '動物免疫学'
        
        # 植物免疫学
        if plant_species and any(kw in content for kw in ['plant', '植物', 'crop']):
            return '植物免疫学'
        
        # 食品免疫学
        if any(kw in content for kw in ['food', '食品', 'nutrition', '栄養', 'probiotics']):
            return '食品免疫学'
        
        # デフォルトは基礎免疫学
        return '免疫学'
    
    def get_keyword_suggestions(self, partial_text: str, max_suggestions: int = 10) -> List[str]:
        """部分テキストからキーワード候補を提案"""
        suggestions = []
        partial_lower = partial_text.lower()
        
        # 全キーワードから部分マッチを検索
        all_keywords = []
        for keywords_dict in [self._medical_keywords, self._agriculture_keywords]:
            for keyword_list in keywords_dict.values():
                all_keywords.extend(keyword_list)
        
        for keyword in all_keywords:
            if partial_lower in keyword.lower() or keyword.lower().startswith(partial_lower):
                suggestions.append(keyword)
                if len(suggestions) >= max_suggestions:
                    break
        
        return suggestions


# グローバルインスタンス
keyword_analyzer = ImmuneKeywordAnalyzer()
EOF

echo "✅ 免疫関連度解析器完了"

echo ""
echo "🎉 Domain層実装完了！"
echo ""
echo "📋 実装されたコンポーネント:"
echo "├── scraper/domain/"
echo "│   ├── research_lab.py         # 研究室エンティティ（ビジネスルール）"
echo "│   ├── university.py           # 大学エンティティ（優先度管理）"
echo "│   └── keyword_analyzer.py     # 免疫関連度解析器"
echo ""
echo "🧬 Domain層の特徴:"
echo "• 型安全性：完全な型ヒント"
echo "• ビジネスルール：不変条件の保証"
echo "• 拡張性：農学・獣医学対応"
echo "• 品質管理：データ品質スコア計算"
echo "• 免疫関連度：自動スコア計算"
echo ""
echo "⚡ 次のステップ："
echo "1. Infrastructure層の実装"
echo "2. Application層の実装"
echo "3. 統合テストの実行"