# 免疫研究室データベース拡充戦略（完全版）🔬

## 🎯 目標
- **対象**: 日本の国公立・私立大学の免疫関係研究室（農学部含む）
- **規模**: 500-1000研究室（現在の9研究室から大幅拡張）
- **品質**: 正確で最新の研究内容情報 + 総合型選抜情報

## 📊 データソース戦略

### 1. 主要データソース
```
優先度1: 各大学公式サイト
├── 医学部・医学研究科の研究室一覧
├── 理学部・生物学科の研究室情報
├── 工学部・バイオ工学科の研究室
├── 薬学部の研究室情報
├── 農学部・獣医学部の研究室情報 ★新規追加
├── 歯学部の研究室情報
└── 入試情報（総合型選抜） ★新規追加

優先度2: 研究者データベース
├── researchmap.jp (科学技術振興機構)
├── KAKEN (科研費データベース)
├── J-GLOBAL (JST)
├── 日本免疫学会 会員情報
├── 日本獣医学会 会員情報 ★新規追加
└── 日本農芸化学会 会員情報 ★新規追加

優先度3: 学術情報・入試情報
├── PubMed論文データ
├── 学会発表情報
├── 研究プロジェクト情報
├── 各大学入試要項 ★新規追加
└── 文部科学省入試データ ★新規追加
```

### 2. 対象大学リスト（3倍拡張：約90校）

#### 国公立大学（約60校）

##### 【旧帝大・難関国立】
```
- 東京大学、京都大学、大阪大学
- 東北大学、名古屋大学、九州大学、北海道大学
- 東京工業大学、一橋大学、筑波大学
- 神戸大学、横浜国立大学、お茶の水女子大学
```

##### 【医科大学・医学部強豪】
```
- 東京医科歯科大学、浜松医科大学
- 滋賀医科大学、旭川医科大学
- 島根大学医学部、山梨大学医学部
- 徳島大学医学部、香川大学医学部
- 高知大学医学部、大分大学医学部
- 宮崎大学医学部、鹿児島大学医学部
```

##### 【農学・獣医学強豪】★新規追加
```
- 東京農工大学、岐阜大学（獣医学部）
- 鳥取大学（農学部・獣医学科）
- 山口大学（獣医学科）
- 宮崎大学（農学部・獣医学科）
- 鹿児島大学（獣医学部）
- 北海道大学（獣医学部・農学部）
- 帯広畜産大学
```

##### 【地方国立大学】
```
関東: 茨城大学、宇都宮大学、群馬大学、埼玉大学、千葉大学、
      信州大学、新潟大学、富山大学、金沢大学、福井大学

関西: 滋賀大学、京都府立大学、大阪府立大学、奈良女子大学、
      和歌山大学、兵庫県立大学

中国: 岡山大学、広島大学、山口大学、鳥取大学、島根大学

四国: 徳島大学、香川大学、愛媛大学、高知大学

九州: 福岡教育大学、佐賀大学、長崎大学、熊本大学、
      大分大学、宮崎大学、鹿児島大学、琉球大学

東北: 弘前大学、岩手大学、秋田大学、山形大学、福島大学

北海道: 室蘭工業大学、小樽商科大学、北見工業大学
```

#### 私立大学（免疫・農学研究で著名：約30校）

##### 【医科大学・総合大学医学部】
```
- 慶應義塾大学、早稲田大学、上智大学
- 順天堂大学、日本医科大学、東京医科大学
- 昭和大学、東邦大学、日本大学医学部
- 聖マリアンナ医科大学、北里大学
- 兵庫医科大学、関西医科大学、近畿大学医学部
- 福岡大学医学部、久留米大学医学部
```

##### 【農学・獣医学・バイオ系強豪】★新規追加
```
- 東京農業大学、日本獣医生命科学大学
- 麻布大学（獣医学部）、日本大学生物資源科学部
- 北里大学獣医学部、酪農学園大学
- 岡山理科大学獣医学部
```

##### 【理工系・バイオ強豪】
```
- 東京理科大学、立教大学、明治大学
- 法政大学、中央大学、青山学院大学
- 関西大学、関西学院大学、同志社大学、立命館大学
- 名城大学、南山大学、福岡工業大学
```

### 3. 拡張キーワードリスト

#### 3.1 基本免疫学キーワード
```python
IMMUNE_KEYWORDS = [
    # 基本用語
    "免疫", "immunology", "immunity",
    "アレルギー", "allergy", "allergic",
    "ワクチン", "vaccine", "vaccination",
    
    # 細胞・分子
    "T細胞", "B細胞", "樹状細胞", "マクロファージ",
    "抗体", "抗原", "サイトカイン", "インターロイキン",
    
    # 疾患
    "自己免疫", "がん免疫", "感染免疫",
    "免疫不全", "炎症", "移植免疫",
    
    # 技術・治療
    "免疫療法", "細胞療法", "遺伝子治療",
    
    # ★新規追加キーワード
    "iPS細胞", "iPSC", "induced pluripotent stem cell",
    "オートファジー", "autophagy",
    "NETosis", "neutrophil extracellular traps",
    
    # ★追加免疫関係キーワード（10個）
    "補体系", "complement system",
    "MHC", "major histocompatibility complex", "主要組織適合抗原",
    "免疫チェックポイント", "immune checkpoint",
    "CAR-T細胞", "CAR-T cell therapy",
    "単クローン抗体", "monoclonal antibody",
    "免疫記憶", "immunological memory",
    "腸管免疫", "intestinal immunity",
    "粘膜免疫", "mucosal immunity", 
    "先天免疫", "innate immunity",
    "獲得免疫", "adaptive immunity"
]
```

#### 3.2 農学部特化キーワード ★新規追加
```python
AGRICULTURE_IMMUNE_KEYWORDS = [
    # 動物免疫
    "動物免疫", "veterinary immunology",
    "家畜免疫", "livestock immunity",
    "魚類免疫", "fish immunology",
    "水産免疫", "aquatic immunology",
    
    # 植物免疫
    "植物免疫", "plant immunity",
    "植物病理", "plant pathology",
    "植物防御", "plant defense",
    "病害抵抗性", "disease resistance",
    
    # 食品・栄養免疫
    "食品免疫", "food immunology",
    "栄養免疫", "nutritional immunology",
    "機能性食品", "functional food",
    "プロバイオティクス", "probiotics",
    
    # 微生物・発酵
    "発酵免疫", "fermentation immunity",
    "微生物免疫", "microbial immunology",
    "腸内細菌", "gut microbiota"
]
```

## 🎓 総合型選抜情報収集システム ★新機能

### 4.1 データ構造
```python
ADMISSION_INFO_SCHEMA = {
    "university_name": str,
    "faculty_name": str,
    "department_name": str,
    "comprehensive_selection": {
        "available": bool,
        "quota": int or str,  # 募集定員 or "-"
        "info_url": str,
        "application_period": str,
        "selection_method": str,
        "last_updated": datetime
    }
}
```

### 4.2 総合型選抜スクレイピング戦略
```python
class ComprehensiveAdmissionScraper:
    """総合型選抜情報スクレイパー"""
    
    def __init__(self):
        self.admission_keywords = [
            "総合型選抜", "AO入試", "総合選抜",
            "特別選抜", "推薦入試", "自己推薦"
        ]
    
    def scrape_admission_info(self, university_url):
        """大学の入試情報をスクレイピング"""
        admission_pages = self.find_admission_pages(university_url)
        
        for page in admission_pages:
            info = self.parse_admission_page(page)
            if self.is_comprehensive_selection(info):
                return self.extract_quota_and_url(info)
        
        return {"available": False, "quota": "-", "info_url": None}
    
    def parse_admission_page(self, page_url):
        """入試ページの詳細解析"""
        soup = self.get_page_content(page_url)
        
        # 学部・学科別の総合型選抜情報を抽出
        faculties = soup.find_all(['div', 'section'], 
                                 class_=re.compile(r'faculty|department|admission'))
        
        admission_data = {}
        for faculty in faculties:
            faculty_name = self.extract_faculty_name(faculty)
            
            # 総合型選抜の募集定員を検索
            quota_text = faculty.get_text()
            quota = self.extract_quota(quota_text)
            
            admission_data[faculty_name] = {
                "quota": quota,
                "details_url": self.find_details_url(faculty)
            }
        
        return admission_data
    
    def extract_quota(self, text):
        """募集定員の抽出"""
        # "若干名", "5名", "10名程度" などのパターンを検出
        patterns = [
            r'(\d+)名',
            r'(\d+)人',
            r'若干名',
            r'数名',
            r'(\d+)名程度'
        ]
        
        for pattern in patterns:
            match = re.search(pattern, text)
            if match:
                if pattern in ['若干名', '数名']:
                    return '若干名'
                return match.group(1) + '名'
        
        return '-'  # 実施していない場合
```

## 🛠️ 技術実装戦略（拡張版）

### Phase 1: 多学部対応スクレイピング基盤

#### 1.1 拡張アーキテクチャ
```python
research_lab_scraper/
├── scrapers/
│   ├── university_scraper.py           # 大学別スクレイパー
│   ├── medical_scraper.py              # 医学部専用
│   ├── agriculture_scraper.py          # 農学部専用 ★新規
│   ├── veterinary_scraper.py           # 獣医学部専用 ★新規
│   ├── admission_scraper.py            # 総合型選抜専用 ★新規
│   ├── researchmap_scraper.py          # researchmap専用
│   └── kaken_scraper.py                # 科研費DB専用
├── parsers/
│   ├── content_parser.py               # 研究内容解析
│   ├── contact_parser.py               # 連絡先情報解析
│   ├── agriculture_parser.py           # 農学系内容解析 ★新規
│   └── admission_parser.py             # 入試情報解析 ★新規
├── data/
│   ├── university_urls.json            # 大学URL一覧（90校）
│   ├── medical_keywords.json           # 医学系キーワード
│   ├── agriculture_keywords.json       # 農学系キーワード ★新規
│   └── admission_keywords.json         # 入試関連キーワード ★新規
├── database/
│   ├── models.py                       # 拡張データモデル
│   └── migrations/                     # DB変更管理
└── utils/
    ├── rate_limiter.py                 # アクセス制御
    ├── data_validator.py               # データ品質チェック
    └── url_discovery.py                # URL自動発見
```

#### 1.2 拡張データベースモデル
```python
# 研究室テーブル拡張
class ResearchLab(Base):
    __tablename__ = "research_labs"
    
    # 既存フィールド
    id = Column(Integer, primary_key=True)
    university_id = Column(Integer, ForeignKey("universities.id"))
    name = Column(String(255))
    professor_name = Column(String(255))
    department = Column(String(255))
    faculty = Column(String(255))  # ★新規追加：学部
    research_theme = Column(Text)
    research_content = Column(Text)
    research_field = Column(String(100))
    
    # ★新規追加フィールド
    lab_type = Column(String(50))  # medical, agriculture, veterinary, etc.
    animal_species = Column(String(255))  # 動物種（獣医・畜産系）
    plant_species = Column(String(255))   # 植物種（農学系）
    research_techniques = Column(Text)     # 研究技術・手法
    
    # 既存フィールド
    embedding = Column(Vector(1536))

# ★新規追加：総合型選抜テーブル
class ComprehensiveAdmission(Base):
    __tablename__ = "comprehensive_admissions"
    
    id = Column(Integer, primary_key=True)
    university_id = Column(Integer, ForeignKey("universities.id"))
    faculty = Column(String(255), nullable=False)
    department = Column(String(255))
    is_available = Column(Boolean, default=False)
    quota = Column(String(50))  # "10名", "若干名", "-"
    info_url = Column(String(500))
    application_period = Column(String(255))
    selection_method = Column(Text)
    last_updated = Column(DateTime, default=datetime.utcnow)
```

### Phase 2: 大学別スクレイピング実装（拡張版）

#### 2.1 東京農工大学の例 ★新規
```python
class TokyoUniversityAgricultureScraper:
    """東京農工大学 農学部スクレイパー"""
    
    BASE_URL = "https://www.tuat.ac.jp"
    
    def scrape_agriculture_labs(self):
        """農学部研究室一覧をスクレイピング"""
        urls = [
            f"{self.BASE_URL}/faculty/agriculture/departments/",
            f"{self.BASE_URL}/graduate/agriculture/research/"
        ]
        
        labs = []
        for url in urls:
            page_labs = self.parse_lab_pages(url)
            labs.extend(self.filter_immune_related(page_labs))
        
        return labs
    
    def scrape_veterinary_labs(self):
        """獣医学関連研究室"""
        vet_url = f"{self.BASE_URL}/faculty/agriculture/veterinary/"
        return self.parse_vet_labs(vet_url)
    
    def filter_immune_related(self, labs):
        """免疫関連研究室をフィルタリング"""
        immune_labs = []
        
        for lab in labs:
            content = lab.get('research_content', '').lower()
            
            # 農学系免疫キーワードをチェック
            if any(keyword.lower() in content for keyword in AGRICULTURE_IMMUNE_KEYWORDS):
                lab['lab_type'] = 'agriculture_immune'
                immune_labs.append(lab)
            
            # 動物種情報の抽出
            animals = self.extract_animal_species(content)
            if animals:
                lab['animal_species'] = ', '.join(animals)
        
        return immune_labs
    
    def extract_animal_species(self, content):
        """研究対象動物種の抽出"""
        animal_keywords = [
            '牛', 'cattle', '豚', 'pig', 'swine',
            '鶏', 'chicken', '魚', 'fish',
            'マウス', 'mouse', 'ラット', 'rat',
            '羊', 'sheep', '山羊', 'goat'
        ]
        
        found_animals = []
        for animal in animal_keywords:
            if animal in content.lower():
                found_animals.append(animal)
        
        return found_animals
```

#### 2.2 総合型選抜情報スクレイピング実装
```python
class UniversityAdmissionScraper:
    """大学別総合型選抜情報スクレイパー"""
    
    def scrape_comprehensive_admission(self, university_name, base_url):
        """総合型選抜情報を取得"""
        
        # 入試情報ページを探索
        admission_urls = self.find_admission_pages(base_url)
        
        admission_data = {}
        
        for url in admission_urls:
            try:
                page_data = self.parse_admission_page(url)
                admission_data.update(page_data)
            except Exception as e:
                logger.warning(f"Failed to parse {url}: {e}")
        
        return self.format_admission_data(admission_data)
    
    def find_admission_pages(self, base_url):
        """入試関連ページのURL発見"""
        search_paths = [
            '/admission/', '/nyushi/', '/entrance/',
            '/undergraduate/admission/', '/graduate/admission/',
            '/faculty/*/admission/', '/入試/'
        ]
        
        found_urls = []
        for path in search_paths:
            potential_url = urljoin(base_url, path)
            if self.url_exists(potential_url):
                found_urls.append(potential_url)
        
        return found_urls
    
    def parse_admission_page(self, url):
        """入試ページの詳細解析"""
        soup = self.get_page_content(url)
        
        # 学部・学科セクションを特定
        sections = soup.find_all(['div', 'section', 'table'], 
                                class_=re.compile(r'faculty|department|course'))
        
        admission_info = {}
        
        for section in sections:
            # 学部・学科名を抽出
            faculty_info = self.extract_faculty_info(section)
            
            if faculty_info:
                # 総合型選抜の有無をチェック
                comprehensive_info = self.check_comprehensive_selection(section)
                
                admission_info[faculty_info['name']] = {
                    'department': faculty_info.get('department'),
                    'comprehensive_selection': comprehensive_info
                }
        
        return admission_info
    
    def check_comprehensive_selection(self, section):
        """総合型選抜実施状況をチェック"""
        text = section.get_text()
        
        # 総合型選抜キーワードを検索
        comprehensive_keywords = ['総合型選抜', 'AO入試', '総合選抜']
        
        if any(keyword in text for keyword in comprehensive_keywords):
            quota = self.extract_quota(text)
            details_url = self.find_details_url(section)
            
            return {
                'available': True,
                'quota': quota,
                'info_url': details_url
            }
        
        return {
            'available': False,
            'quota': '-',
            'info_url': None
        }
```

## 📋 実装スケジュール（拡張版）

### Week 1-2: 拡張基盤構築
- [ ] 多学部対応スクレイピングフレームワーク構築
- [ ] 90大学URL収集・整理
- [ ] 農学系・総合型選抜キーワード辞書作成
- [ ] データベースモデル拡張・マイグレーション

### Week 3-4: 主要大学スクレイピング（医学・農学）
- [ ] 旧帝大7校の医学部・農学部研究室
- [ ] 農工大・北大・帯広畜産大の農学・獣医学部
- [ ] 総合型選抜情報の並行収集

### Week 5-6: データベース統合・品質管理
- [ ] スクレイピングデータのDB投入
- [ ] 重複排除・データクリーニング
- [ ] 総合型選抜データの統合

### Week 7-8: 拡張・私立大学追加
- [ ] 私立大学30校の追加
- [ ] researchmap.jp連携強化
- [ ] 自動更新システム実装

### Week 9-10: 品質向上・機能拡張
- [ ] 検索精度向上
- [ ] 総合型選抜フィルタリング機能
- [ ] データ可視化・統計機能

## 🎯 期待される成果（拡張版）

### 数値目標
- **研究室数**: 500-1000件（現在の9件から100倍拡張）
- **大学数**: 90校（3倍拡張）
- **学部カバレッジ**: 医学・理学・工学・薬学・農学・獣医学
- **総合型選抜情報**: 90校×平均5学部 = 450学部の入試情報

### 新機能
- **農学・獣医学検索**: 動物・植物・食品免疫研究の発見
- **総合型選抜フィルタ**: 「総合型選抜あり」で絞り込み可能
- **募集定員表示**: 各学部の総合型選抜定員を表示
- **入試情報リンク**: 詳細な入試情報への直接リンク

この拡張戦略で実装を開始しますか？特に注力したい部分はありますか？