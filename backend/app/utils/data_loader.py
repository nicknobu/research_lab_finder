"""
データローダー - 初期データの読み込み（安全版）
"""
import logging
from sqlalchemy.orm import Session
from app.models import University, ResearchLab

logger = logging.getLogger(__name__)


async def load_initial_data(db: Session):
    """初期データの読み込み（安全版）"""
    try:
        # 既にデータがある場合はスキップ
        existing_labs = db.query(ResearchLab).count()
        if existing_labs > 0:
            logger.info(f"既に {existing_labs} 件の研究室データが存在します")
            return
        
        logger.info("初期データの読み込みを開始します...")
        
        # サンプル大学データの挿入
        sample_universities = [
            {"name": "東京大学", "type": "national", "prefecture": "東京都", "region": "関東"},
            {"name": "京都大学", "type": "national", "prefecture": "京都府", "region": "関西"},
            {"name": "大阪大学", "type": "national", "prefecture": "大阪府", "region": "関西"},
            {"name": "横浜市立大学", "type": "public", "prefecture": "神奈川県", "region": "関東"},
            {"name": "名古屋大学", "type": "national", "prefecture": "愛知県", "region": "中部"},
            {"name": "九州大学", "type": "national", "prefecture": "福岡県", "region": "九州"},
            {"name": "東京理科大学", "type": "private", "prefecture": "東京都", "region": "関東"},
            {"name": "慶應義塾大学", "type": "private", "prefecture": "東京都", "region": "関東"},
        ]
        
        universities_created = 0
        for uni_data in sample_universities:
            existing_uni = db.query(University).filter(University.name == uni_data["name"]).first()
            if not existing_uni:
                university = University(**uni_data)
                db.add(university)
                universities_created += 1
        
        db.commit()
        logger.info(f"Created {universities_created} universities")
        
        # 研究室データの挿入
        sample_labs = [
            {
                "university_id": 1,  # 東京大学
                "name": "免疫制御学教室",
                "professor_name": "田中太郎",
                "department": "医学部",
                "research_theme": "T細胞免疫応答の制御機構",
                "research_content": "がん免疫療法の開発を目指した基礎研究を行っています。T細胞の活性化機構を解明し、新しい治療法の開発に取り組んでいます。",
                "research_field": "免疫学",
                "speciality": "がん免疫、T細胞免疫",
                "keywords": "がん免疫,T細胞,免疫療法,腫瘍免疫",
                "lab_url": "https://example.com/lab1"
            },
            {
                "university_id": 2,  # 京都大学
                "name": "分子腫瘍学研究室",
                "professor_name": "佐藤花子",
                "department": "医学研究科",
                "research_theme": "がん細胞の増殖機構",
                "research_content": "がん細胞の分子メカニズムを解明し、新しい診断法と治療法の開発を目指しています。特にがん幹細胞の特性解析に力を入れています。",
                "research_field": "腫瘍学",
                "speciality": "がん幹細胞、分子診断",
                "keywords": "がん,腫瘍,分子生物学,診断,治療",
                "lab_url": "https://example.com/lab2"
            },
            {
                "university_id": 3,  # 大阪大学
                "name": "再生医学研究所",
                "professor_name": "山田次郎",
                "department": "医学系研究科",
                "research_theme": "幹細胞を用いた再生療法",
                "research_content": "幹細胞技術を活用した組織再生療法の研究を行っています。特に心臓や神経系の再生医療に取り組んでいます。",
                "research_field": "再生医学",
                "speciality": "幹細胞、組織再生",
                "keywords": "幹細胞,再生医療,組織工学,細胞療法",
                "lab_url": "https://example.com/lab3"
            },
            {
                "university_id": 4,  # 横浜市立大学
                "name": "免疫学教室",
                "professor_name": "田村智彦",
                "department": "医学部",
                "research_theme": "樹状細胞分化制御機構",
                "research_content": "樹状細胞の分化制御機構と自己免疫疾患における役割を研究しています。新しい免疫療法の開発を目指しています。",
                "research_field": "免疫学",
                "speciality": "樹状細胞、自己免疫",
                "keywords": "樹状細胞,自己免疫,免疫制御,炎症",
                "lab_url": "https://example.com/lab4"
            },
            {
                "university_id": 5,  # 名古屋大学
                "name": "感染症研究室",
                "professor_name": "鈴木一郎",
                "department": "医学系研究科",
                "research_theme": "ウイルス感染に対する免疫応答機構",
                "research_content": "ウイルス感染に対する自然免疫および獲得免疫の応答機構を解析し、新しいワクチン開発や抗ウイルス療法の基盤となる研究を行っています。",
                "research_field": "感染免疫学",
                "speciality": "感染免疫、ウイルス免疫、ワクチン開発",
                "keywords": "感染免疫,ウイルス,ワクチン,抗ウイルス療法,免疫応答",
                "lab_url": "https://example.com/lab5"
            },
            {
                "university_id": 5,  # 名古屋大学
                "name": "アレルギー免疫学分野",
                "professor_name": "伊藤美咲",
                "department": "医学系学府",
                "research_theme": "アレルギー疾患の分子機構",
                "research_content": "アトピー性皮膚炎や食物アレルギーなどのアレルギー疾患の発症機構を分子レベルで解明し、新しい治療戦略の開発を目指しています。",
                "research_field": "免疫学",
                "speciality": "アレルギー、IgE、肥満細胞",
                "keywords": "アレルギー,アトピー,IgE,肥満細胞,炎症",
                "lab_url": "https://example.com/lab6"
            },
            {
                "university_id": 6,  # 九州大学
                "name": "分子生物学研究室",
                "professor_name": "高橋達也",
                "department": "理学研究院",
                "research_theme": "細胞分裂制御機構",
                "research_content": "細胞分裂の制御機構を分子レベルで解明し、がん化のメカニズムや老化現象との関連を研究しています。",
                "research_field": "分子生物学",
                "speciality": "細胞周期、がん化機構",
                "keywords": "細胞分裂,がん,老化,分子機構",
                "lab_url": "https://example.com/lab7"
            },
            {
                "university_id": 7,  # 東京理科大学
                "name": "生理学研究室",
                "professor_name": "小林恵子",
                "department": "理学部",
                "research_theme": "神経免疫相互作用",
                "research_content": "神経系と免疫系の相互作用を研究し、ストレス応答や神経変性疾患における免疫機能の役割を解明しています。",
                "research_field": "神経免疫学",
                "speciality": "神経免疫、ストレス応答",
                "keywords": "神経免疫,ストレス,神経変性疾患,免疫調節",
                "lab_url": "https://example.com/lab8"
            },
            {
                "university_id": 8,  # 慶應義塾大学
                "name": "バイオインフォマティクス研究室",
                "professor_name": "森田章",
                "department": "理工学部",
                "research_theme": "AIを活用した創薬研究",
                "research_content": "機械学習と生物情報学を組み合わせて、新薬の候補化合物を効率的に発見するための計算手法を開発しています。",
                "research_field": "バイオインフォマティクス",
                "speciality": "機械学習、創薬、データサイエンス",
                "keywords": "AI,機械学習,創薬,バイオインフォマティクス,データ解析",
                "lab_url": "https://example.com/lab9"
            }
        ]
        
        labs_created = 0
        for lab_data in sample_labs:
            # 大学IDの確認
            university = db.query(University).filter(University.id == lab_data["university_id"]).first()
            if university:
                existing_lab = db.query(ResearchLab).filter(
                    ResearchLab.university_id == lab_data["university_id"],
                    ResearchLab.name == lab_data["name"]
                ).first()
                
                if not existing_lab:
                    lab = ResearchLab(**lab_data)
                    db.add(lab)
                    labs_created += 1
        
        db.commit()
        logger.info(f"Created {labs_created} research labs")
        
        # 埋め込みベクトルの生成（安全版）
        try:
            await generate_embeddings_safe(db)
        except Exception as e:
            logger.warning(f"埋め込みベクトル生成をスキップします（OpenAI API未設定の可能性）: {e}")
        
        logger.info("✅ 初期データの読み込みが完了しました")
        
    except Exception as e:
        logger.error(f"❌ 初期データの読み込みに失敗しました: {e}")
        db.rollback()
        raise


async def generate_embeddings_safe(db: Session):
    """研究室データの埋め込みベクトル生成（安全版）"""
    try:
        logger.info("埋め込みベクトルの生成を開始します...")
        
        # OpenAI APIキーの確認
        from app.config import settings
        if not settings.OPENAI_API_KEY:
            logger.warning("OpenAI API キーが設定されていません。埋め込みベクトル生成をスキップします。")
            return
        
        # 埋め込みベクトルが未生成の研究室を取得
        labs_without_embeddings = db.query(ResearchLab)\
            .filter(ResearchLab.embedding.is_(None))\
            .all()
        
        if not labs_without_embeddings:
            logger.info("すべての研究室に埋め込みベクトルが生成済みです")
            return
        
        # search_engineのインポートと初期化を安全に実行
        try:
            from app.core.semantic_search import search_engine
        except ImportError as e:
            logger.warning(f"semantic_search のインポートに失敗しました: {e}")
            return
        
        embeddings_created = 0
        for lab in labs_without_embeddings:
            try:
                # 研究内容のテキストを結合
                combined_text = f"{lab.research_theme} {lab.research_content} {lab.speciality} {lab.keywords}"
                
                # 埋め込みベクトルを生成
                embedding_vector = await search_engine.get_embedding(combined_text)
                
                # データベースに保存
                lab.embedding = embedding_vector
                embeddings_created += 1
                
                if embeddings_created % 5 == 0:
                    logger.info(f"埋め込みベクトル生成中... ({embeddings_created}/{len(labs_without_embeddings)})")
                
            except Exception as e:
                logger.error(f"研究室 {lab.name} の埋め込みベクトル生成に失敗: {e}")
                continue
        
        db.commit()
        logger.info(f"✅ {embeddings_created} 件の埋め込みベクトルを生成しました")
        
    except Exception as e:
        logger.error(f"❌ 埋め込みベクトル生成に失敗しました: {e}")
        # エラーでも処理を続行（埋め込みベクトルは後で生成可能）
        logger.info("埋め込みベクトルは後で手動生成できます")


# 旧関数との互換性のための関数
def load_initial_data_sync(db: Session):
    """同期版の初期データ読み込み（互換性用）"""
    import asyncio
    try:
        loop = asyncio.get_event_loop()
        loop.run_until_complete(load_initial_data(db))
    except RuntimeError:
        # イベントループが既に存在する場合
        asyncio.create_task(load_initial_data(db))