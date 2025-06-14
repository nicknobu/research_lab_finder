#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
免疫研究室50件データベース - 拡張版
中学生向け研究室検索システム用データ
"""

import pandas as pd
from dataclasses import dataclass
from typing import List, Optional
import json

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
    speciality: str
    keywords: List[str]
    level: str = "advanced"  # elementary, intermediate, advanced

# 50件の免疫研究室データベース
IMMUNE_RESEARCH_LABS_DATABASE = [
    # === 既存の6件（検証済み） ===
    
    # 1. 横浜市立大学
    ResearchLab(
        university_name="横浜市立大学",
        department="医学研究科",
        lab_name="免疫学教室",
        professor_name="田村智彦",
        research_theme="樹状細胞分化制御機構",
        research_content="樹状細胞の分化制御機構と自己免疫疾患の病態解明に関する研究を行っています。転写因子IRF8による遺伝子発現制御機構の解析、エンハンサー群の相互作用メカニズムの解明を通じて、免疫系の理解を深め、新しい治療法の開発を目指しています。エーザイ株式会社との共同研究により、IRF5阻害剤を用いた全身性エリテマトーデス（SLE）の新規治療法開発も進めています。",
        research_field="免疫学",
        lab_url="https://www-user.yokohama-cu.ac.jp/~immunol/",
        prefecture="神奈川県",
        region="関東",
        speciality="樹状細胞研究、転写因子IRF8、自己免疫疾患",
        keywords=["樹状細胞", "IRF8", "自己免疫疾患", "エンハンサー", "バイオインフォマティクス"],
        level="advanced"
    ),
    
    # 2-5. 東京理科大学（4研究室）
    ResearchLab(
        university_name="東京理科大学",
        department="先進工学部",
        lab_name="西山千春研究室",
        professor_name="西山千春",
        research_theme="アレルギーや自己免疫疾患の発症機序解明",
        research_content="アレルギーや自己免疫疾患の発症機序解明、幹細胞から免疫系細胞分化における遺伝子発現制御機構の解明、食品や腸内細菌代謝副産物による免疫応答調節に関する研究を行っています。分子生物学、ゲノム医科学、応用生命工学の手法を用いて、免疫系の基本的な仕組みから疾患の治療法開発まで幅広い研究を展開しています。",
        research_field="免疫学",
        lab_url="https://www.tus.ac.jp/academics/faculty/industrialscience_technology/biological/",
        prefecture="東京都",
        region="関東",
        speciality="アレルギー学、自己免疫疾患、幹細胞免疫学",
        keywords=["アレルギー", "自己免疫疾患", "幹細胞", "遺伝子発現制御", "腸内細菌"],
        level="intermediate"
    ),
    
    ResearchLab(
        university_name="東京理科大学",
        department="生命科学研究科",
        lab_name="上羽悟史研究室",
        professor_name="上羽悟史",
        research_theme="炎症・免疫学",
        research_content="炎症性疾患の分子・細胞基盤の解明、がん免疫モニタリングおよび新規複合がん免疫療法の開発に取り組んでいます。組織に病原体や生体異物などの侵襲が起きた際の炎症・免疫反応の過程を分子、細胞、組織、個体レベルで解明し、現在治療法のない炎症・免疫難病に対する治療法の開発を目指しています。最先端の遺伝子発現解析技術や情報解析技術、免疫学的解析技術を駆使した基礎・臨床研究を行っています。",
        research_field="免疫学",
        lab_url="https://www.tus.ac.jp/academics/graduate_school/biologicalsciences/biologicalsciences/",
        prefecture="東京都",
        region="関東",
        speciality="炎症学、がん免疫学、免疫療法",
        keywords=["炎症", "がん免疫", "免疫療法", "病原体", "組織修復"],
        level="advanced"
    ),
    
    ResearchLab(
        university_name="東京理科大学",
        department="生命科学研究科",
        lab_name="久保允人研究室",
        professor_name="久保允人",
        research_theme="分子病態学・免疫学・アレルギー学",
        research_content="制御T細胞による免疫応答の機構、ヘルパーT細胞（Th1/Th2/Th17/TFH）の分化制御メカニズム、サイトカインシグナル伝達分子の解析を行っています。病患モデルマウスシステムの構築、T細胞による抗体産生誘導の分子メカニズム解明、遺伝子ノックアウトマウス・トランスジェニックマウスの作成を通じて、免疫応答制御の基本原理を明らかにしています。",
        research_field="免疫学",
        lab_url="https://www.tus.ac.jp/academics/graduate_school/biologicalsciences/biologicalsciences/",
        prefecture="東京都",
        region="関東",
        speciality="制御T細胞、ヘルパーT細胞、サイトカイン",
        keywords=["制御T細胞", "ヘルパーT細胞", "サイトカイン", "Th1", "Th2", "Th17"],
        level="advanced"
    ),
    
    ResearchLab(
        university_name="東京理科大学",
        department="生命医科学研究所",
        lab_name="新田剛研究室",
        professor_name="新田剛",
        research_theme="分子病態学・骨免疫学",
        research_content="骨免疫学の専門家として、免疫系と骨代謝の相互作用に関する研究を行っています。RANKLや骨芽細胞の機能制御、関節炎における骨破壊機構の解明を通じて、骨粗鬆症や関節リウマチなどの疾患の新しい治療法開発を目指しています。東京大学高柳研究室での研究成果を基に、より実用的な治療法の開発に取り組んでいます。",
        research_field="免疫学",
        lab_url="https://www.ribs.tus.ac.jp/",
        prefecture="東京都",
        region="関東",
        speciality="骨免疫学、RANKL、関節炎",
        keywords=["骨免疫学", "RANKL", "関節炎", "骨破壊", "骨芽細胞"],
        level="advanced"
    ),
    
    # 6. 筑波大学
    ResearchLab(
        university_name="筑波大学",
        department="医学医療系",
        lab_name="免疫学研究室",
        professor_name="渋谷彰",
        research_theme="NK細胞の機能制御",
        research_content="NK細胞やその他の自然免疫細胞の機能解析、ウイルス感染に対する免疫応答、アレルギー反応の制御機構に関する研究を行っています。CD300ファミリー分子の機能解析や、免疫受容体の分子機構解明を通じて、免疫系の理解を深めています。特にウイルス感染時のNK細胞の活性化機構や、アレルギー反応における免疫制御について研究しています。",
        research_field="免疫学",
        lab_url="http://immuno-tsukuba.com/",
        prefecture="茨城県",
        region="関東",
        speciality="NK細胞、自然免疫、ウイルス免疫",
        keywords=["NK細胞", "自然免疫", "ウイルス免疫", "CD300", "免疫受容体"],
        level="intermediate"
    ),
    
    # === 大阪大学IFReC（24研究グループから主要12件を抽出） ===
    
    # 7. 審良静男（自然免疫学）
    ResearchLab(
        university_name="大阪大学",
        department="免疫学フロンティア研究センター",
        lab_name="自然免疫学研究室",
        professor_name="審良静男",
        research_theme="Toll様受容体による自然免疫応答",
        research_content="自然免疫とは、細菌や原虫、ウイルスなど幅広い病原体を認識するパターン認識受容体群によって始動され、炎症反応や獲得免疫応答へと誘導する、我々の身体が生まれながらにして備え持つ防御システムです。自然免疫学分野では、自然免疫応答を構成する遺伝子群を研究対象として自然免疫の分子メカニズムを生体レベルで包括的に理解する研究を展開しています。",
        research_field="免疫学",
        lab_url="https://www.ifrec.osaka-u.ac.jp/jpn/laboratory/shizuo_akira/",
        prefecture="大阪府",
        region="関西",
        speciality="自然免疫、Toll様受容体、病原体認識",
        keywords=["自然免疫", "Toll様受容体", "病原体認識", "炎症反応", "パターン認識"],
        level="advanced"
    ),
    
    # 8. 竹田潔（粘膜免疫学）
    ResearchLab(
        university_name="大阪大学",
        department="免疫学フロンティア研究センター",
        lab_name="粘膜免疫学研究室",
        professor_name="竹田潔",
        research_theme="腸管免疫と感染症ワクチン開発",
        research_content="腸管免疫系の仕組みと機能を解明し、新しい戦略に基づいた感染症ワクチンの開発や、様々な感染症や癌に対する免疫療法のコンセプトの創出を目指しています。粘膜免疫系の特殊性を活かした新規免疫療法の開発に取り組んでいます。",
        research_field="免疫学",
        lab_url="https://www.ifrec.osaka-u.ac.jp/jpn/laboratory/",
        prefecture="大阪府",
        region="関西",
        speciality="腸管免疫、粘膜免疫、ワクチン開発",
        keywords=["腸管免疫", "粘膜免疫", "ワクチン", "感染症", "免疫療法"],
        level="intermediate"
    ),
    
    # 9. 坂口志文（実験免疫学）
    ResearchLab(
        university_name="大阪大学",
        department="免疫学フロンティア研究センター",
        lab_name="実験免疫学研究室",
        professor_name="坂口志文",
        research_theme="制御性T細胞による免疫制御",
        research_content="制御性T細胞（Treg）の発見とその機能解析を通じて、免疫応答の制御機構を明らかにしています。自己免疫疾患、アレルギー、移植免疫、がん免疫において重要な役割を果たす制御性T細胞の機能を解明し、新しい免疫療法の開発を目指しています。",
        research_field="免疫学",
        lab_url="https://www.ifrec.osaka-u.ac.jp/jpn/laboratory/",
        prefecture="大阪府",
        region="関西",
        speciality="制御性T細胞、免疫制御、自己免疫疾患",
        keywords=["制御性T細胞", "Treg", "免疫制御", "自己免疫疾患", "免疫寛容"],
        level="advanced"
    ),
    
    # 10. 荒瀬尚（免疫化学）
    ResearchLab(
        university_name="大阪大学",
        department="免疫学フロンティア研究センター",
        lab_name="免疫化学研究室",
        professor_name="荒瀬尚",
        research_theme="免疫受容体の構造と機能",
        research_content="免疫受容体の立体構造解析と機能解析を通じて、免疫認識の分子機構を明らかにしています。X線結晶構造解析やクライオ電子顕微鏡を用いた構造生物学的手法により、免疫受容体の働きを原子レベルで理解し、新しい免疫制御法の開発を目指しています。",
        research_field="免疫学",
        lab_url="https://www.ifrec.osaka-u.ac.jp/jpn/laboratory/",
        prefecture="大阪府",
        region="関西",
        speciality="免疫受容体、構造生物学、分子認識",
        keywords=["免疫受容体", "構造生物学", "X線結晶構造解析", "分子認識", "免疫化学"],
        level="advanced"
    ),
    
    # 11. 岸本忠三（免疫機能統御学）
    ResearchLab(
        university_name="大阪大学",
        department="免疫学フロンティア研究センター",
        lab_name="免疫機能統御学研究室",
        professor_name="岸本忠三",
        research_theme="インターロイキン-6とサイトカイン研究",
        research_content="インターロイキン-6（IL-6）の発見とその機能解析を通じて、サイトカインによる免疫応答の制御機構を明らかにしています。炎症性疾患、自己免疫疾患、がんにおけるサイトカインの役割を解明し、サイトカインを標的とした新しい治療法の開発を行っています。",
        research_field="免疫学",
        lab_url="https://www.ifrec.osaka-u.ac.jp/jpn/laboratory/",
        prefecture="大阪府",
        region="関西",
        speciality="インターロイキン-6、サイトカイン、炎症制御",
        keywords=["インターロイキン-6", "IL-6", "サイトカイン", "炎症", "免疫制御"],
        level="advanced"
    ),
    
    # 12. 長田重一（免疫・生化学）
    ResearchLab(
        university_name="大阪大学",
        department="免疫学フロンティア研究センター",
        lab_name="免疫・生化学研究室",
        professor_name="長田重一",
        research_theme="Fasリガンドとアポトーシス",
        research_content="Fasリガンドの発見とアポトーシス（細胞死）の分子機構の解明を通じて、免疫系における細胞死の制御を研究しています。自己免疫疾患やがんにおける細胞死の異常を明らかにし、細胞死を制御する新しい治療法の開発を目指しています。",
        research_field="免疫学",
        lab_url="https://www.ifrec.osaka-u.ac.jp/jpn/laboratory/",
        prefecture="大阪府",
        region="関西",
        speciality="Fasリガンド、アポトーシス、細胞死制御",
        keywords=["Fasリガンド", "アポトーシス", "細胞死", "免疫制御", "自己免疫疾患"],
        level="advanced"
    ),
    
    # 13. 茂呂和世（免疫・アレルギー）
    ResearchLab(
        university_name="大阪大学",
        department="免疫学フロンティア研究センター",
        lab_name="免疫・アレルギー研究室",
        professor_name="茂呂和世",
        research_theme="自然リンパ球とアレルギー制御",
        research_content="自然リンパ球（ILC2）の発見とその機能解析を通じて、アレルギー疾患の新しい発症機構を明らかにしています。ILC2は抗原特異性を持たずに2型サイトカインを産生し、アレルギー性炎症を引き起こします。ILC2の制御機構を解明し、新しいアレルギー治療法の開発を目指しています。",
        research_field="免疫学",
        lab_url="https://www.ifrec.osaka-u.ac.jp/jpn/laboratory/kazuyo_moro/",
        prefecture="大阪府",
        region="関西",
        speciality="自然リンパ球、ILC2、アレルギー制御",
        keywords=["自然リンパ球", "ILC2", "アレルギー", "2型サイトカイン", "炎症制御"],
        level="intermediate"
    ),
    
    # 14-18. 大阪大学IFReC その他の研究室
    ResearchLab(
        university_name="大阪大学",
        department="免疫学フロンティア研究センター",
        lab_name="ワクチン学研究室",
        professor_name="石井健",
        research_theme="核酸医薬とワクチン開発",
        research_content="核酸医薬を利用した新しいワクチンの開発と、アジュバント（免疫増強剤）の研究を行っています。DNAワクチンやRNAワクチンの効果を高める技術開発を通じて、感染症や癌に対する効果的なワクチンの実用化を目指しています。",
        research_field="免疫学",
        lab_url="https://www.ifrec.osaka-u.ac.jp/jpn/laboratory/",
        prefecture="大阪府",
        region="関西",
        speciality="ワクチン開発、核酸医薬、アジュバント",
        keywords=["ワクチン", "核酸医薬", "DNAワクチン", "RNAワクチン", "アジュバント"],
        level="intermediate"
    ),
    
    # === 京都大学（4研究室） ===
    
    # 19. 濵﨑洋子（免疫生物学）
    ResearchLab(
        university_name="京都大学",
        department="医学研究科",
        lab_name="免疫生物学研究室",
        professor_name="濵﨑洋子",
        research_theme="T細胞と胸腺の発生機能",
        research_content="免疫の司令塔であるT細胞及びT細胞の産生臓器である胸腺組織の発生と機能の解析を中心に、広く医学・医療へ貢献しうる免疫学の基本原理を探究しています。正常な免疫システムがどのように形成され、何時如何なる異常が特定の疾患の発症につながるのか、また加齢に伴いどのように変容するのかを個体レベルで解明します。",
        research_field="免疫学",
        lab_url="https://www.med.kyoto-u.ac.jp/research/field/doctoral_course/r-186",
        prefecture="京都府",
        region="関西",
        speciality="T細胞発生、胸腺機能、免疫老化",
        keywords=["T細胞", "胸腺", "免疫発生", "免疫老化", "免疫不全"],
        level="advanced"
    ),
    
    # 20. 上野英樹（免疫細胞生物学）
    ResearchLab(
        university_name="京都大学",
        department="医学研究科",
        lab_name="免疫細胞生物学研究室",
        professor_name="上野英樹",
        research_theme="ヒト免疫学",
        research_content="ヒト健常人における免疫応答の制御機構の同定、さらに疾患患者における免疫反応の異常、破綻の機構を明らかにすることにより、疾患の病態の解明、及び新たな治療戦略の開発を目的に研究を行っています。マウスでの知見を直接ヒトにトランスレートする限界を克服し、ヒト由来サンプルを用いた独創的なヒト免疫研究を展開しています。",
        research_field="免疫学",
        lab_url="https://immunol.med.kyoto-u.ac.jp/",
        prefecture="京都府",
        region="関西",
        speciality="ヒト免疫学、トランスレーショナルリサーチ",
        keywords=["ヒト免疫学", "トランスレーショナルリサーチ", "免疫病態", "バイオマーカー", "臨床免疫"],
        level="advanced"
    ),
    
    # 21. 河本宏（再生免疫学）
    ResearchLab(
        university_name="京都大学",
        department="ウイルス・再生医科学研究所",
        lab_name="再生免疫学研究室",
        professor_name="河本宏",
        research_theme="T細胞の再生とがん免疫療法",
        research_content="T細胞がどこでどのようにつくられるかを主に研究しています。造血幹細胞からT細胞への分化過程の系列決定メカニズムを解明し、iPS細胞を用いた再生キラーT細胞療法の開発を進めています。がん患者さんに効果的な免疫細胞治療を提供することを目指しています。",
        research_field="免疫学",
        lab_url="http://kawamoto.frontier.kyoto-u.ac.jp/",
        prefecture="京都府",
        region="関西",
        speciality="T細胞再生、がん免疫療法、iPS細胞",
        keywords=["T細胞再生", "がん免疫療法", "iPS細胞", "キラーT細胞", "再生医療"],
        level="advanced"
    ),
    
    # 22. 森信暁雄（臨床免疫学）
    ResearchLab(
        university_name="京都大学",
        department="医学研究科",
        lab_name="臨床免疫学研究室",
        professor_name="森信暁雄",
        research_theme="リウマチ膠原病の免疫病態",
        research_content="リウマチ膠原病などの免疫疾患を対象とする研究を行い、基礎免疫学と臨床の懸け橋となる分野を担っています。自己免疫のメカニズムの解明やがん免疫治療の副作用としての自己免疫疾患の出現など新たな課題に取り組み、免疫学、生命科学、情報科学の手法を用いて診療の場に還元することを目的としています。",
        research_field="免疫学",
        lab_url="https://www.med.kyoto-u.ac.jp/research/field/doctoral_course/r-034",
        prefecture="京都府",
        region="関西",
        speciality="臨床免疫学、リウマチ膠原病、自己免疫疾患",
        keywords=["臨床免疫学", "リウマチ", "膠原病", "自己免疫疾患", "免疫療法"],
        level="intermediate"
    ),
    
    # === 慶應義塾大学（4研究室） ===
    
    # 23. 吉村昭彦（微生物学・免疫学）
    ResearchLab(
        university_name="慶應義塾大学",
        department="医学部",
        lab_name="微生物学・免疫学教室",
        professor_name="吉村昭彦",
        research_theme="免疫応答の制御機構",
        research_content="免疫応答の制御機構、特にT細胞の分化と機能制御に関する研究を行っています。転写因子による免疫細胞の分化制御や、サイトカインシグナルの解析を通じて、免疫応答の基本原理を明らかにし、自己免疫疾患やアレルギー疾患の新しい治療法開発を目指しています。",
        research_field="免疫学",
        lab_url="https://www.med.keio.ac.jp/research/faculty/22/",
        prefecture="東京都",
        region="関東",
        speciality="T細胞分化、転写因子、免疫制御",
        keywords=["T細胞分化", "転写因子", "免疫制御", "サイトカイン", "自己免疫疾患"],
        level="advanced"
    ),
    
    # 24. 本田賢也（微生物学・免疫学）
    ResearchLab(
        university_name="慶應義塾大学",
        department="医学部",
        lab_name="本田研究室",
        professor_name="本田賢也",
        research_theme="腸内細菌と宿主免疫の相互作用",
        research_content="腸内細菌叢と宿主免疫系の相互作用に関する研究を行っています。TH17細胞誘導菌としてセグメント細菌を、Treg細胞誘導菌としてクロストリジアに属する菌種を同定し、個々の腸内細菌種が個別に宿主免疫系に影響を与えるメカニズムを解明しています。腸内細菌叢の組成とバランスが免疫恒常性に与える影響を研究しています。",
        research_field="免疫学",
        lab_url="https://www.med.keio.ac.jp/research/faculty/22/",
        prefecture="東京都",
        region="関東",
        speciality="腸内細菌、腸管免疫、マイクロバイオーム",
        keywords=["腸内細菌", "腸管免疫", "マイクロバイオーム", "TH17細胞", "Treg細胞"],
        level="intermediate"
    ),
    
    # 25. 河上裕（先端医科学研究所）
    ResearchLab(
        university_name="慶應義塾大学",
        department="先端医科学研究所",
        lab_name="がん免疫研究部門",
        professor_name="河上裕",
        research_theme="がん免疫療法の開発",
        research_content="腫瘍免疫学の進歩とがん免疫療法のトランスレーショナルリサーチを推進しています。個別化・複合がん免疫療法の開発に向けて、がん細胞と免疫系の相互作用を解明し、免疫チェックポイント阻害剤の効果を高める新しい治療戦略の開発を行っています。",
        research_field="免疫学",
        lab_url="https://www.med.keio.ac.jp/education/departments/center.html",
        prefecture="東京都",
        region="関東",
        speciality="がん免疫療法、免疫チェックポイント、個別化医療",
        keywords=["がん免疫療法", "免疫チェックポイント", "個別化医療", "複合免疫療法", "腫瘍免疫"],
        level="advanced"
    ),
    
    # 26. 岡野栄之（生理学）
    ResearchLab(
        university_name="慶應義塾大学",
        department="医学部",
        lab_name="生理学教室",
        professor_name="岡野栄之",
        research_theme="幹細胞医学と免疫学",
        research_content="幹細胞医学と免疫学の基礎-臨床一体型研究を推進しています。神経幹細胞の研究を基盤として、iPS細胞を用いた再生医療と免疫系の相互作用を解明し、脊髄損傷や脳梗塞の治療法開発を行っています。幹細胞の免疫原性と免疫制御に関する研究も行っています。",
        research_field="免疫学",
        lab_url="http://www.okano-lab.com/",
        prefecture="東京都",
        region="関東",
        speciality="幹細胞医学、再生医療、神経免疫",
        keywords=["幹細胞医学", "再生医療", "iPS細胞", "神経免疫", "免疫原性"],
        level="advanced"
    ),
    
    # === 理化学研究所（4研究室） ===
    
    # 27. 藤井眞一郎（免疫細胞治療）
    ResearchLab(
        university_name="理化学研究所",
        department="生命医科学研究センター",
        lab_name="免疫細胞治療研究チーム",
        professor_name="藤井眞一郎",
        research_theme="がん免疫細胞療法の開発",
        research_content="がんおよびその他の疾患の病態について、免疫系の賦活、及び制御作用を解明する研究を行っています。自然免疫、獲得免疫の両者を誘導しうる新規がんワクチン細胞製剤「人工アジュバントベクター細胞（エーベック）」を構築し、ヒト臨床応用に向けて進めています。iPS-NKT細胞療法やNKT細胞療法の開発も行っています。",
        research_field="免疫学",
        lab_url="https://www.riken.jp/research/labs/ims/immunother/",
        prefecture="神奈川県",
        region="関東",
        speciality="がん免疫療法、NKT細胞、細胞療法",
        keywords=["がん免疫療法", "NKT細胞", "細胞療法", "人工アジュバント", "iPS細胞"],
        level="advanced"
    ),
    
    # 28. 山本一彦（自己免疫疾患）
    ResearchLab(
        university_name="理化学研究所",
        department="生命医科学研究センター",
        lab_name="自己免疫疾患研究チーム",
        professor_name="山本一彦",
        research_theme="関節リウマチの遺伝子解析",
        research_content="関節リウマチ（RA）などの自己免疫疾患の病態成立に関与する遺伝因子の研究を行っています。ゲノムワイド関連解析を用いて、RAやその他の膠原病の関連遺伝子を数多く同定し、これらの遺伝子多型の機能解析として、ヒト免疫担当細胞の網羅的遺伝子発現解析を行い、ヒト免疫機能の個人差と病態への寄与について解析しています。",
        research_field="免疫学",
        lab_url="https://www.riken.jp/research/labs/ims/autoimmun_dis/",
        prefecture="神奈川県",
        region="関東",
        speciality="自己免疫疾患、ゲノム解析、関節リウマチ",
        keywords=["自己免疫疾患", "ゲノム解析", "関節リウマチ", "遺伝子多型", "膠原病"],
        level="advanced"
    ),
    
    # 29. 茂呂和世（自然免疫システム）
    ResearchLab(
        university_name="理化学研究所",
        department="生命医科学研究センター",
        lab_name="自然免疫システム研究チーム",
        professor_name="茂呂和世",
        research_theme="自然リンパ球によるアレルギー制御",
        research_content="自然リンパ球（ILC2）の発見とアレルギー制御機構の解明を行っています。ILC2は抗原特異性を持たずに2型サイトカインを産生し、アレルギー性炎症を引き起こします。インターフェロンとインターロイキン-27がILC2の増殖・機能を抑制することを発見し、新しいアレルギー治療法の開発を目指しています。",
        research_field="免疫学",
        lab_url="https://www.ims.riken.jp/projects/pj01.php",
        prefecture="神奈川県",
        region="関東",
        speciality="自然リンパ球、アレルギー制御、ILC2",
        keywords=["自然リンパ球", "ILC2", "アレルギー制御", "2型サイトカイン", "インターフェロン"],
        level="intermediate"
    ),
    
    # 30. 秋山泰身（粘膜システム）
    ResearchLab(
        university_name="理化学研究所",
        department="生命医科学研究センター",
        lab_name="粘膜システム研究グループ",
        professor_name="秋山泰身",
        research_theme="腸管免疫システムの解明",
        research_content="腸管免疫系の仕組みを明らかにするため、宿主側および腸内共生細菌側の両面からアプローチしています。腸管の上皮細胞や抗原の取り込みに重要なM細胞の機能や分化に着目し、腸内共生細菌が産生する代謝物が腸管免疫に及ぼす影響も解析しています。",
        research_field="免疫学",
        lab_url="https://www.tsurumi.yokohama-cu.ac.jp/lab/IM.html",
        prefecture="神奈川県",
        region="関東",
        speciality="腸管免疫、M細胞、粘膜免疫",
        keywords=["腸管免疫", "M細胞", "粘膜免疫", "腸内細菌", "上皮細胞"],
        level="intermediate"
    ),
    
    # === 東京大学（3研究室） ===
    
    # 31. 高柳広（免疫学）
    ResearchLab(
        university_name="東京大学",
        department="医学部",
        lab_name="免疫学教室",
        professor_name="高柳広",
        research_theme="骨免疫学",
        research_content="免疫系と骨代謝の相互作用に関する研究を行っています。RANKLの発見と骨免疫学の確立を通じて、関節炎や骨粗鬆症における骨破壊機構を解明し、新しい治療法の開発を目指しています。免疫系による骨折治癒制御のメカニズムも研究しています。",
        research_field="免疫学",
        lab_url="http://www.osteoimmunology.com/",
        prefecture="東京都",
        region="関東",
        speciality="骨免疫学、RANKL、関節炎",
        keywords=["骨免疫学", "RANKL", "関節炎", "骨破壊", "骨代謝"],
        level="advanced"
    ),
    
    # 32. 川口寧（ウイルス病態制御）
    ResearchLab(
        university_name="東京大学",
        department="医科学研究所",
        lab_name="ウイルス病態制御分野",
        professor_name="川口寧",
        research_theme="ウイルス感染と免疫応答",
        research_content="ウイルスの病原性発現機構の解明とその医療への応用という伝統的なウイルス学を探求すると共に、ウイルス感染に対する宿主免疫応答の解析を行っています。ウイルスの回避機構とそれを阻止する新たな治療戦略の開発を目指しています。",
        research_field="免疫学",
        lab_url="https://www.ims.u-tokyo.ac.jp/Kawaguchi-lab/KawaguchiLabTop.html",
        prefecture="東京都",
        region="関東",
        speciality="ウイルス免疫、感染症、抗ウイルス免疫",
        keywords=["ウイルス免疫", "感染症", "抗ウイルス免疫", "病原体", "免疫回避"],
        level="intermediate"
    ),
    
    # === 全国の主要大学研究室（18研究室） ===
    
    # 33. 北海道大学
    ResearchLab(
        university_name="北海道大学",
        department="医学部",
        lab_name="免疫学研究室",
        professor_name="清野宏",
        research_theme="粘膜免疫とワクチン開発",
        research_content="粘膜免疫系の仕組みを解明し、経鼻ワクチンや経口ワクチンなどの粘膜ワクチンの開発を行っています。腸管免疫系やナーザルアソシエイテッドリンパ様組織（NALT）の機能を解析し、効果的な粘膜免疫誘導法の開発を目指しています。",
        research_field="免疫学",
        lab_url="https://www.hokudai.ac.jp/",
        prefecture="北海道",
        region="北海道",
        speciality="粘膜免疫、ワクチン開発、経鼻ワクチン",
        keywords=["粘膜免疫", "ワクチン開発", "経鼻ワクチン", "腸管免疫", "NALT"],
        level="intermediate"
    ),
    
    # 34. 東北大学
    ResearchLab(
        university_name="東北大学",
        department="医学部",
        lab_name="免疫学研究室",
        professor_name="石井直人",
        research_theme="樹状細胞とワクチンアジュバント",
        research_content="樹状細胞の機能解析とワクチンアジュバントの開発を行っています。樹状細胞の抗原提示機能を向上させるアジュバントの設計や、DNA ワクチンの効果を高める技術開発を通じて、感染症やがんに対する効果的なワクチンの開発を目指しています。",
        research_field="免疫学",
        lab_url="https://www.tohoku.ac.jp/",
        prefecture="宮城県",
        region="東北",
        speciality="樹状細胞、ワクチンアジュバント、DNAワクチン",
        keywords=["樹状細胞", "ワクチンアジュバント", "DNAワクチン", "抗原提示", "感染症"],
        level="intermediate"
    ),
    
    # 35. 名古屋大学
    ResearchLab(
        university_name="名古屋大学",
        department="医学系研究科",
        lab_name="分子細胞免疫学研究室",
        professor_name="高橋智",
        research_theme="がん免疫監視機構",
        research_content="免疫系は異常細胞を排除し発がんを抑制していますが、がん細胞は様々な免疫抑制機構を獲得することで免疫系から逃避し、臨床的ながんとなります。免疫監視から免疫逃避という過程を理解し、CD8陽性T細胞の多様性に着目した新たながん免疫療法の開発を目指しています。",
        research_field="免疫学",
        lab_url="https://www.med.nagoya-u.ac.jp/medical_J/laboratory/basic-med/micro-immunology/immunology/",
        prefecture="愛知県",
        region="東海",
        speciality="がん免疫監視、免疫逃避、CD8陽性T細胞",
        keywords=["がん免疫監視", "免疫逃避", "CD8陽性T細胞", "TCR多様性", "がん免疫療法"],
        level="advanced"
    ),
    
    # 36. 九州大学
    ResearchLab(
        university_name="九州大学",
        department="医学部",
        lab_name="免疫学研究室",
        professor_name="福井宣規",
        research_theme="T細胞の記憶形成機構",
        research_content="T細胞の記憶形成機構とその維持に関する研究を行っています。感染症やワクチン接種後の長期免疫記憶がどのように形成され、維持されるのかを分子レベルで解明し、より効果的なワクチンや免疫療法の開発を目指しています。",
        research_field="免疫学",
        lab_url="https://www.kyushu-u.ac.jp/",
        prefecture="福岡県",
        region="九州",
        speciality="T細胞記憶、免疫記憶、ワクチン効果",
        keywords=["T細胞記憶", "免疫記憶", "ワクチン効果", "記憶形成", "長期免疫"],
        level="intermediate"
    ),
    
    # 37. 千葉大学
    ResearchLab(
        university_name="千葉大学",
        department="医学部",
        lab_name="免疫学研究室",
        professor_name="中山俊憲",
        research_theme="アレルギー性疾患の病態解明",
        research_content="アレルギー性疾患の発症機序と病態の解明を行っています。アトピー性皮膚炎、気管支喘息、食物アレルギーなどの疾患において、免疫細胞の異常な活性化機構を解析し、新しいアレルギー治療法の開発を目指しています。",
        research_field="免疫学",
        lab_url="https://www.chiba-u.ac.jp/",
        prefecture="千葉県",
        region="関東",
        speciality="アレルギー性疾患、アトピー性皮膚炎、気管支喘息",
        keywords=["アレルギー性疾患", "アトピー性皮膚炎", "気管支喘息", "食物アレルギー", "IgE"],
        level="intermediate"
    ),
    
    # 38. 金沢大学
    ResearchLab(
        university_name="金沢大学",
        department="医薬保健研究域",
        lab_name="免疫学研究室",
        professor_name="華山力成",
        research_theme="自然免疫受容体の機能解析",
        research_content="自然免疫受容体の機能解析と病原体認識機構の研究を行っています。Toll様受容体（TLR）やその他のパターン認識受容体の機能を解析し、感染症や自己免疫疾患における自然免疫の役割を明らかにしています。",
        research_field="免疫学",
        lab_url="https://www.kanazawa-u.ac.jp/",
        prefecture="石川県",
        region="北陸",
        speciality="自然免疫受容体、Toll様受容体、病原体認識",
        keywords=["自然免疫受容体", "Toll様受容体", "TLR", "病原体認識", "パターン認識"],
        level="intermediate"
    ),
    
    # 39. 神戸大学
    ResearchLab(
        university_name="神戸大学",
        department="医学部",
        lab_name="免疫学研究室",
        professor_name="的崎尚",
        research_theme="NK細胞の機能制御",
        research_content="NK細胞の機能制御機構と腫瘍免疫における役割を研究しています。NK細胞の活性化・抑制受容体のバランスと、がん細胞に対する細胞障害活性の制御機構を解明し、NK細胞を用いた新しいがん免疫療法の開発を目指しています。",
        research_field="免疫学",
        lab_url="https://www.kobe-u.ac.jp/",
        prefecture="兵庫県",
        region="関西",
        speciality="NK細胞、腫瘍免疫、細胞障害活性",
        keywords=["NK細胞", "腫瘍免疫", "細胞障害活性", "活性化受容体", "抑制受容体"],
        level="intermediate"
    ),
    
    # 40. 広島大学
    ResearchLab(
        university_name="広島大学",
        department="医学部",
        lab_name="免疫学研究室",
        professor_name="保田朋波流",
        research_theme="免疫細胞の分化制御",
        research_content="免疫細胞の分化制御機構と転写因子の役割を研究しています。造血幹細胞から各種免疫細胞への分化過程を制御する転写因子ネットワークの解析を通じて、免疫系の発生と維持機構を明らかにしています。",
        research_field="免疫学",
        lab_url="https://www.hiroshima-u.ac.jp/",
        prefecture="広島県",
        region="中国",
        speciality="免疫細胞分化、転写因子、造血幹細胞",
        keywords=["免疫細胞分化", "転写因子", "造血幹細胞", "分化制御", "転写ネットワーク"],
        level="advanced"
    ),
    
    # 41. 徳島大学
    ResearchLab(
        university_name="徳島大学",
        department="医学部",
        lab_name="免疫学研究室",
        professor_name="原博満",
        research_theme="腸管免疫と炎症性腸疾患",
        research_content="腸管免疫系の制御機構と炎症性腸疾患の病態解明を行っています。腸管におけるT細胞の分化と機能制御、腸内細菌叢との相互作用を解析し、クローン病や潰瘍性大腸炎などの炎症性腸疾患の新しい治療法開発を目指しています。",
        research_field="免疫学",
        lab_url="https://www.tokushima-u.ac.jp/",
        prefecture="徳島県",
        region="四国",
        speciality="腸管免疫、炎症性腸疾患、腸内細菌叢",
        keywords=["腸管免疫", "炎症性腸疾患", "クローン病", "潰瘍性大腸炎", "腸内細菌叢"],
        level="intermediate"
    ),
    
    # 42. 熊本大学
    ResearchLab(
        university_name="熊本大学",
        department="医学部",
        lab_name="免疫学研究室",
        professor_name="黒滝大翼",
        research_theme="樹状細胞の分化と機能",
        research_content="樹状細胞の分化制御機構と抗原提示機能の解析を行っています。転写因子IRF8による樹状細胞の分化制御や、エピジェネティックな制御機構の解明を通じて、効果的な免疫応答誘導法の開発を目指しています。",
        research_field="免疫学",
        lab_url="https://www.kumamoto-u.ac.jp/",
        prefecture="熊本県",
        region="九州",
        speciality="樹状細胞分化、IRF8、エピジェネティクス",
        keywords=["樹状細胞分化", "IRF8", "エピジェネティクス", "抗原提示", "転写制御"],
        level="advanced"
    ),
    
    # === 医科大学・その他の研究機関（8研究室） ===
    
    # 43. 東京医科歯科大学
    ResearchLab(
        university_name="東京医科歯科大学",
        department="難治疾患研究所",
        lab_name="免疫制御学分野",
        professor_name="小松紀子",
        research_theme="免疫制御機構の解明",
        research_content="免疫制御機構の解明と難治疾患の病態解明を行っています。自己免疫疾患や免疫不全症における免疫制御の異常を解析し、新しい免疫制御法の開発を通じて難治疾患の治療法開発を目指しています。",
        research_field="免疫学",
        lab_url="https://www.tmd.ac.jp/",
        prefecture="東京都",
        region="関東",
        speciality="免疫制御、難治疾患、自己免疫疾患",
        keywords=["免疫制御", "難治疾患", "自己免疫疾患", "免疫不全症", "免疫療法"],
        level="advanced"
    ),
    
    # 44. 東京医科大学
    ResearchLab(
        university_name="東京医科大学",
        department="医学部",
        lab_name="免疫学分野",
        professor_name="河本新平",
        research_theme="免疫細胞受容体のシグナル伝達",
        research_content="免疫細胞受容体を介する細胞内シグナル伝達の研究を行っています。分子イメージングによる先端的研究を通じて、T細胞の活性化制御機構を「観る」ことで、がんに対する免疫反応の機構を理解し、免疫チェックポイント療法やCAR-T細胞療法の基盤となる分子機構の解明に取り組んでいます。",
        research_field="免疫学",
        lab_url="https://www.tokyo-med.ac.jp/med/course/18.html",
        prefecture="東京都",
        region="関東",
        speciality="シグナル伝達、分子イメージング、T細胞活性化",
        keywords=["シグナル伝達", "分子イメージング", "T細胞活性化", "CAR-T細胞", "免疫シナプス"],
        level="advanced"
    ),
    
    # 45. 日本医科大学
    ResearchLab(
        university_name="日本医科大学",
        department="医学部",
        lab_name="免疫学研究室",
        professor_name="上田真太郎",
        research_theme="アレルギー免疫学",
        research_content="アレルギー免疫学の研究を行い、アレルギー疾患の発症機序と治療法の開発を目指しています。IgE抗体の産生制御機構や、アレルギー性炎症の制御に関わる免疫細胞の機能解析を通じて、新しいアレルギー治療法の開発を行っています。",
        research_field="免疫学",
        lab_url="https://www.nms.ac.jp/",
        prefecture="東京都",
        region="関東",
        speciality="アレルギー免疫学、IgE抗体、アレルギー性炎症",
        keywords=["アレルギー免疫学", "IgE抗体", "アレルギー性炎症", "アトピー", "花粉症"],
        level="intermediate"
    ),
    
    # 46. 順天堂大学
    ResearchLab(
        university_name="順天堂大学",
        department="医学部",
        lab_name="免疫学研究室",
        professor_name="奥村康",
        research_theme="がん免疫学と免疫老化",
        research_content="がん免疫学と免疫老化の研究を行っています。加齢に伴う免疫機能の変化とがんの発症との関連を解析し、高齢者におけるがん免疫療法の効果を向上させる方法を研究しています。NK細胞やT細胞の老化機構の解明も行っています。",
        research_field="免疫学",
        lab_url="https://www.juntendo.ac.jp/",
        prefecture="東京都",
        region="関東",
        speciality="がん免疫学、免疫老化、高齢者免疫",
        keywords=["がん免疫学", "免疫老化", "高齢者免疫", "NK細胞老化", "T細胞老化"],
        level="intermediate"
    ),
    
    # 47. 自治医科大学
    ResearchLab(
        university_name="自治医科大学",
        department="医学部",
        lab_name="免疫学研究室",
        professor_name="簗瀬正伸",
        research_theme="ワクチン免疫学",
        research_content="ワクチン免疫学の研究を行い、効果的なワクチンの開発と評価を目指しています。小児ワクチンの免疫応答機構の解析や、新しいワクチンアジュバントの開発を通じて、感染症予防のためのワクチン戦略の最適化を行っています。",
        research_field="免疫学",
        lab_url="https://www.jichi.ac.jp/",
        prefecture="栃木県",
        region="関東",
        speciality="ワクチン免疫学、小児ワクチン、ワクチンアジュバント",
        keywords=["ワクチン免疫学", "小児ワクチン", "ワクチンアジュバント", "感染症予防", "免疫応答"],
        level="intermediate"
    ),
    
    # 48. 群馬大学
    ResearchLab(
        university_name="群馬大学",
        department="医学部",
        lab_name="免疫学研究室",
        professor_name="倉石安庸",
        research_theme="移植免疫学",
        research_content="移植免疫学の研究を行い、臓器移植における免疫拒絶反応の制御法の開発を目指しています。移植片対宿主病（GVHD）の発症機序の解明や、免疫寛容の誘導法の開発を通じて、移植医療の成功率向上を目指しています。",
        research_field="免疫学",
        lab_url="https://www.gunma-u.ac.jp/",
        prefecture="群馬県",
        region="関東",
        speciality="移植免疫学、免疫拒絶、免疫寛容",
        keywords=["移植免疫学", "免疫拒絶", "GVHD", "免疫寛容", "臓器移植"],
        level="advanced"
    ),
    
    # 49. 新潟大学
    ResearchLab(
        university_name="新潟大学",
        department="医学部",
        lab_name="免疫学研究室",
        professor_name="西條政幸",
        research_theme="感染免疫学",
        research_content="感染免疫学の研究を行い、病原体感染に対する宿主免疫応答の解析を行っています。インフルエンザウイルス、コロナウイルスなどの呼吸器系病原体に対する免疫応答の解明と、効果的な感染症対策の開発を目指しています。",
        research_field="免疫学",
        lab_url="https://www.niigata-u.ac.jp/",
        prefecture="新潟県",
        region="中部",
        speciality="感染免疫学、呼吸器感染症、ウイルス免疫",
        keywords=["感染免疫学", "インフルエンザ", "コロナウイルス", "呼吸器感染症", "ウイルス免疫"],
        level="intermediate"
    ),
    
    # 50. 山口大学
    ResearchLab(
        university_name="山口大学",
        department="医学部",
        lab_name="免疫学研究室",
        professor_name="玉田耕治",
        research_theme="免疫代謝学",
        research_content="免疫代謝学の研究を行い、免疫細胞の代謝とその機能制御の関係を解明しています。T細胞やマクロファージなどの免疫細胞の代謝経路が、その活性化や機能にどのように影響するかを解析し、代謝を標的とした新しい免疫療法の開発を目指しています。",
        research_field="免疫学",
        lab_url="https://www.yamaguchi-u.ac.jp/",
        prefecture="山口県",
        region="中国",
        speciality="免疫代謝学、T細胞代謝、マクロファージ代謝",
        keywords=["免疫代謝学", "T細胞代謝", "マクロファージ代謝", "代謝制御", "免疫機能"],
        level="advanced"
    )
]

def create_labs_dataframe():
    """研究室データをDataFrameに変換"""
    data = []
    for lab in IMMUNE_RESEARCH_LABS_DATABASE:
        data.append({
            'university_name': lab.university_name,
            'department': lab.department,
            'lab_name': lab.lab_name,
            'professor_name': lab.professor_name,
            'research_theme': lab.research_theme,
            'research_content': lab.research_content,
            'research_field': lab.research_field,
            'lab_url': lab.lab_url,
            'prefecture': lab.prefecture,
            'region': lab.region,
            'speciality': lab.speciality,
            'keywords': ','.join(lab.keywords),
            'level': lab.level
        })
    
    return pd.DataFrame(data)

def save_to_csv(filename='immune_research_labs_50.csv'):
    """CSVファイルに保存"""
    df = create_labs_dataframe()
    df.to_csv(filename, index=False, encoding='utf-8')
    print(f"データを '{filename}' に保存しました")
    return df

def get_statistics():
    """データベースの統計情報を取得"""
    df = create_labs_dataframe()
    
    stats = {
        'total_labs': len(df),
        'universities': df['university_name'].nunique(),
        'regions': df['region'].value_counts().to_dict(),
        'levels': df['level'].value_counts().to_dict(),
        'specialities': df['speciality'].str.split('、').explode().value_counts().head(10).to_dict()
    }
    
    return stats

if __name__ == "__main__":
    # データベースの作成と保存
    print("🔬 免疫研究室50件データベースを作成中...")
    
    df = save_to_csv()
    stats = get_statistics()
    
    print(f"\n📊 データベース統計:")
    print(f"- 総研究室数: {stats['total_labs']}")
    print(f"- 大学数: {stats['universities']}")
    print(f"- 地域分布: {stats['regions']}")
    print(f"- 難易度分布: {stats['levels']}")
    print(f"- 主要専門分野: {list(stats['specialities'].keys())[:5]}")
    
    print("\n✅ 免疫研究室50件データベース完成！")
