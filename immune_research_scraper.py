import asyncio
import aiohttp
from bs4 import BeautifulSoup
import pandas as pd
from dataclasses import dataclass
from typing import List, Optional
import time
import json
import re
from urllib.parse import urljoin, urlparse
import logging

# ログ設定
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class ResearchLab:
    """研究室データ構造"""
    university_name: str
    department: str
    lab_name: str
    professor_name: str
    research_theme: str
    research_content: str
    research_field: str
    lab_url: str
    prefecture: str
    region: str

class ImmuneResearchScraper:
    """免疫研究室専用スクレイピングクラス"""
    
    def __init__(self):
        self.session = None
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Research Lab Finder Bot) AppleWebKit/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'ja,en-US;q=0.7,en;q=0.3',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
        }
        self.delay = 2  # 2秒間隔でアクセス
        
    async def __aenter__(self):
        """非同期コンテキストマネージャー"""
        self.session = aiohttp.ClientSession(headers=self.headers)
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """セッションクリーンアップ"""
        if self.session:
            await self.session.close()
    
    async def fetch_page(self, url: str) -> Optional[str]:
        """Webページを取得"""
        try:
            await asyncio.sleep(self.delay)  # レート制限
            async with self.session.get(url, timeout=10) as response:
                if response.status == 200:
                    return await response.text()
                else:
                    logger.warning(f"Failed to fetch {url}: {response.status}")
                    return None
        except Exception as e:
            logger.error(f"Error fetching {url}: {e}")
            return None
    
    def extract_immune_keywords(self, text: str) -> bool:
        """免疫関連キーワードの検出"""
        immune_keywords = [
            '免疫', 'immunity', 'immunology', 'immune',
            'T細胞', 'B細胞', 'NK細胞', 'マクロファージ',
            'サイトカイン', 'インターフェロン', 'インターロイキン',
            '抗体', 'antibody', 'antigen', '抗原',
            'アレルギー', 'allergy', 'アトピー',
            '自己免疫', 'autoimmune', 'autoimmunity',
            'ワクチン', 'vaccine', '予防接種',
            'がん免疫', 'cancer immunotherapy',
            '炎症', 'inflammation', 'inflammatory'
        ]
        
        text_lower = text.lower()
        return any(keyword.lower() in text_lower for keyword in immune_keywords)
    
    async def scrape_university_labs(self, university_config: dict) -> List[ResearchLab]:
        """大学の研究室情報を取得"""
        labs = []
        
        # 大学サイトの構造に応じたスクレイピング
        for url in university_config['urls']:
            html = await self.fetch_page(url)
            if not html:
                continue
                
            soup = BeautifulSoup(html, 'html.parser')
            
            # 各大学のHTML構造に応じた解析
            lab_elements = self.find_lab_elements(soup, university_config)
            
            for element in lab_elements:
                lab_data = self.extract_lab_data(element, university_config)
                if lab_data and self.extract_immune_keywords(lab_data.research_content):
                    labs.append(lab_data)
                    logger.info(f"Found immune lab: {lab_data.lab_name}")
        
        return labs
    
    def find_lab_elements(self, soup: BeautifulSoup, config: dict) -> List:
        """研究室要素を探す（大学ごとにカスタマイズ）"""
        # 一般的なパターンを試す
        selectors = [
            '.lab-item', '.research-lab', '.professor-info',
            '.faculty-member', '.lab-info', '.research-group'
        ]
        
        for selector in selectors:
            elements = soup.select(selector)
            if elements:
                return elements
        
        # タグベースでの検索
        return soup.find_all(['div', 'section'], class_=re.compile(r'lab|research|professor'))
    
    def extract_lab_data(self, element, config: dict) -> Optional[ResearchLab]:
        """要素から研究室データを抽出"""
        try:
            # 基本情報の抽出（これは実際のHTML構造に応じて調整が必要）
            lab_name = self.extract_text(element, ['.lab-name', '.title', 'h2', 'h3'])
            professor_name = self.extract_text(element, ['.professor', '.name', '.faculty-name'])
            research_content = self.extract_text(element, ['.research', '.description', '.content', 'p'])
            
            if not lab_name or not research_content:
                return None
            
            return ResearchLab(
                university_name=config['name'],
                department=config.get('department', ''),
                lab_name=lab_name,
                professor_name=professor_name or '',
                research_theme=lab_name,  # 仮設定
                research_content=research_content,
                research_field='免疫学',
                lab_url=config.get('base_url', ''),
                prefecture=config.get('prefecture', ''),
                region=config.get('region', '')
            )
        except Exception as e:
            logger.error(f"Error extracting lab data: {e}")
            return None
    
    def extract_text(self, element, selectors: List[str]) -> str:
        """指定されたセレクタからテキストを抽出"""
        for selector in selectors:
            found = element.select_one(selector)
            if found:
                return found.get_text(strip=True)
        return ''

# 実際の調査結果に基づく大学設定データ
UNIVERSITY_CONFIGS = [
    {
        'name': '大阪大学',
        'department': '免疫学フロンティア研究センター',
        'prefecture': '大阪府',
        'region': '関西',
        'urls': [
            'https://www.ifrec.osaka-u.ac.jp/jpn/laboratory/',  # 研究グループ一覧
        ],
        'base_url': 'https://www.ifrec.osaka-u.ac.jp/',
        'type': 'ifrec_format',  # 特別な解析形式
        'research_groups': 24  # 24の研究グループ
    },
    {
        'name': '横浜市立大学',
        'department': '医学研究科',
        'prefecture': '神奈川県',
        'region': '関東',
        'urls': [
            'https://www-user.yokohama-cu.ac.jp/~immunol/',
        ],
        'base_url': 'https://www-user.yokohama-cu.ac.jp/',
        'type': 'ycu_format',
        'professor': '田村智彦',  # 論文引用度1位
        'speciality': '樹状細胞研究'
    },
    {
        'name': '東京大学',
        'department': '医学部免疫学教室',
        'prefecture': '東京都',
        'region': '関東',
        'urls': [
            'http://www.osteoimmunology.com/',  # 高柳研究室
            'http://www.immunol.m.u-tokyo.ac.jp/',
        ],
        'base_url': 'http://www.immunol.m.u-tokyo.ac.jp/',
        'type': 'utokyo_format',
        'professor': '高柳広',
        'speciality': '骨免疫学'
    },
    {
        'name': '筑波大学',
        'department': '医学医療系',
        'prefecture': '茨城県',
        'region': '関東',
        'urls': [
            'http://immuno-tsukuba.com/',
        ],
        'base_url': 'http://immuno-tsukuba.com/',
        'type': 'tsukuba_format',
        'professor': '渋谷彰',
        'speciality': 'NK細胞研究'
    },
    {
        'name': '名古屋大学',
        'department': '医学系研究科',
        'prefecture': '愛知県',
        'region': '東海',
        'urls': [
            'https://www.med.nagoya-u.ac.jp/medical_J/laboratory/basic-med/micro-immunology/immunology/',
        ],
        'base_url': 'https://www.med.nagoya-u.ac.jp/',
        'type': 'nagoya_format',
        'speciality': 'がん免疫学'
    },
]

# サンプルデータ生成（実際のスクレイピングの代替）
def generate_sample_immune_labs() -> List[ResearchLab]:
    """免疫研究のサンプルデータを生成"""
    sample_labs = [
        ResearchLab(
            university_name="東京大学",
            department="医学部",
            lab_name="免疫制御学教室",
            professor_name="田中太郎",
            research_theme="T細胞免疫応答の制御機構",
            research_content="T細胞の分化と機能制御、特に制御性T細胞（Treg）の機能解析を通じて、自己免疫疾患やアレルギー疾患の病態解明と治療法開発を目指しています。また、がん免疫療法における免疫チェックポイント阻害剤の作用機序についても研究しています。",
            research_field="免疫学",
            lab_url="https://www.m.u-tokyo.ac.jp/immunology/",
            prefecture="東京都",
            region="関東"
        ),
        ResearchLab(
            university_name="京都大学",
            department="医学部",
            lab_name="感染免疫学分野",
            professor_name="佐藤花子",
            research_theme="感染症に対する免疫応答機構",
            research_content="ウイルス感染に対する自然免疫および獲得免疫の応答機構を解析し、新しいワクチン開発や抗ウイルス療法の基盤となる研究を行っています。特にインフルエンザウイルスやコロナウイルスに対する免疫記憶の形成機構に注目しています。",
            research_field="免疫学",
            lab_url="https://www.med.kyoto-u.ac.jp/infection-immunology/",
            prefecture="京都府",
            region="関西"
        ),
        ResearchLab(
            university_name="大阪大学",
            department="免疫学フロンティア研究センター",
            lab_name="分子免疫学研究室",
            professor_name="山田次郎",
            research_theme="自然免疫受容体の機能解析",
            research_content="Toll様受容体（TLR）をはじめとする自然免疫受容体の分子機構を解析し、炎症性疾患や自己免疫疾患の病態解明を目指しています。また、これらの受容体を標的とした新規治療薬の開発も行っています。",
            research_field="免疫学",
            lab_url="https://www.ifrec.osaka-u.ac.jp/molecular-immunology/",
            prefecture="大阪府",
            region="関西"
        )
    ]
    
    # より多くのサンプルデータを生成
    research_themes = [
        ("アレルギー免疫学", "アレルギー反応のメカニズム解明と治療法開発"),
        ("がん免疫学", "免疫系によるがん細胞の認識と排除機構の研究"),
        ("自己免疫学", "自己免疫疾患の発症機構と免疫寛容の維持"),
        ("ワクチン学", "効果的なワクチン設計と免疫記憶の形成"),
        ("粘膜免疫学", "腸管免疫系と感染防御機構の研究"),
        ("免疫老化学", "加齢に伴う免疫機能の変化と疾患との関連"),
        ("移植免疫学", "臓器移植における免疫拒絶反応の制御"),
        ("免疫代謝学", "免疫細胞の代謝と機能の相関関係"),
    ]
    
    universities = [
        ("慶應義塾大学", "医学部", "東京都", "関東"),
        ("早稲田大学", "先進理工学部", "東京都", "関東"),
        ("北海道大学", "医学部", "北海道", "北海道"),
        ("東北大学", "医学部", "宮城県", "東北"),
        ("名古屋大学", "医学部", "愛知県", "東海"),
        ("九州大学", "医学部", "福岡県", "九州"),
    ]
    
    for i, (theme, content) in enumerate(research_themes):
        univ_info = universities[i % len(universities)]
        sample_labs.append(
            ResearchLab(
                university_name=univ_info[0],
                department=univ_info[1],
                lab_name=f"{theme}研究室",
                professor_name=f"教授{i+4}",
                research_theme=theme,
                research_content=f"{content}を中心とした研究を行っています。分子レベルから個体レベルまでの多角的なアプローチにより、免疫システムの理解を深め、新しい治療戦略の開発を目指しています。",
                research_field="免疫学",
                lab_url=f"https://{univ_info[0].lower()}.ac.jp/immunology{i+1}/",
                prefecture=univ_info[2],
                region=univ_info[3]
            )
        )
    
    return sample_labs

async def main():
    """メイン実行関数"""
    print("🔬 免疫研究室データ収集開始...")
    
    # 実際のスクレイピング（実装例）
    # async with ImmuneResearchScraper() as scraper:
    #     all_labs = []
    #     for config in UNIVERSITY_CONFIGS:
    #         labs = await scraper.scrape_university_labs(config)
    #         all_labs.extend(labs)
    #         print(f"✅ {config['name']}: {len(labs)} labs found")
    
    # サンプルデータの使用（開発・テスト用）
    all_labs = generate_sample_immune_labs()
    print(f"📊 サンプルデータ生成完了: {len(all_labs)} 研究室")
    
    # データをDataFrameに変換
    df = pd.DataFrame([
        {
            'university_name': lab.university_name,
            'department': lab.department,
            'lab_name': lab.lab_name,
            'professor_name': lab.professor_name,
            'research_theme': lab.research_theme,
            'research_content': lab.research_content,
            'research_field': lab.research_field,
            'lab_url': lab.lab_url,
            'prefecture': lab.prefecture,
            'region': lab.region
        }
        for lab in all_labs
    ])
    
    # CSVファイルに保存
    df.to_csv('immune_research_labs.csv', index=False, encoding='utf-8')
    print("💾 データを 'immune_research_labs.csv' に保存しました")
    
    # 統計情報の表示
    print("\n📈 収集データ統計:")
    print(f"- 研究室数: {len(df)}")
    print(f"- 大学数: {df['university_name'].nunique()}")
    print(f"- 地域分布: {df['region'].value_counts().to_dict()}")
    
    return df

if __name__ == "__main__":
    # サンプル実行
    asyncio.run(main())