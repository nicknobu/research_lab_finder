#!/bin/bash

set -e

echo "íº ç ç©¶å®¤ãã¡ã¤ã³ãã¼ - ã»ããã¢ããéå§"

# ã«ã©ã¼ã³ã¼ã
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# å¿è¦ãªãã¼ã«ã®ç¢ºèª
check_requirements() {
    echo -e "${BLUE}í³ å¿è¦ãªãã¼ã«ã®ç¢ºèªä¸­...${NC}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}â Dockerãã¤ã³ã¹ãã¼ã«ããã¦ãã¾ãã${NC}"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}â Docker Composeãã¤ã³ã¹ãã¼ã«ããã¦ãã¾ãã${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}â å¿è¦ãªãã¼ã«ãæã£ã¦ãã¾ã${NC}"
}

# ç°å¢å¤æ°ãã¡ã¤ã«ã®ç¢ºèªã»ä½æ
setup_env() {
    echo -e "${BLUE}í´§ ç°å¢å¤æ°ã®è¨­å®ä¸­...${NC}"
    
    if [ ! -f .env ]; then
        echo -e "${YELLOW}â ï¸ .envãã¡ã¤ã«ãè¦ã¤ããã¾ããã.env.exampleããã³ãã¼ãã¦ãã¾ã...${NC}"
        cp .env.example .env
        echo -e "${YELLOW}í³ .envãã¡ã¤ã«ãç·¨éãã¦OpenAI APIã­ã¼ãè¨­å®ãã¦ãã ãã${NC}"
        
        read -p "ä»ããOpenAI APIã­ã¼ãå¥åãã¾ããï¼ (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -p "OpenAI APIã­ã¼ãå¥åãã¦ãã ãã: " api_key
            if [ ! -z "$api_key" ]; then
                sed -i.bak "s/your_openai_api_key_here/$api_key/" .env
                echo -e "${GREEN}â OpenAI APIã­ã¼ãè¨­å®ããã¾ãã${NC}"
            fi
        fi
    else
        echo -e "${GREEN}â .envãã¡ã¤ã«ãå­å¨ãã¾ã${NC}"
    fi
}

# Dockerç°å¢ã®æ§ç¯
build_docker() {
    echo -e "${BLUE}í°³ Dockerç°å¢ã®æ§ç¯ä¸­...${NC}"
    
    echo "æ¢å­ã®ã³ã³ãããåæ­¢ä¸­..."
    docker-compose down -v 2>/dev/null || true
    
    echo "Dockerã¤ã¡ã¼ã¸ããã«ãä¸­..."
    docker-compose build --no-cache
    
    echo -e "${GREEN}â Dockerç°å¢ã®æ§ç¯å®äº${NC}"
}

# ãã¼ã¿ãã¼ã¹ã®åæå
init_database() {
    echo -e "${BLUE}í³ ãã¼ã¿ãã¼ã¹ã®åæåä¸­...${NC}"
    
    echo "ãã¼ã¿ãã¼ã¹ã³ã³ãããèµ·åä¸­..."
    docker-compose up -d db
    
    echo "ãã¼ã¿ãã¼ã¹ã®èµ·åãå¾æ©ä¸­..."
    sleep 10
    
    max_attempts=30
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if docker-compose exec -T db pg_isready -U postgres > /dev/null 2>&1; then
            echo -e "${GREEN}â ãã¼ã¿ãã¼ã¹ã«æ¥ç¶ã§ãã¾ãã${NC}"
            break
        fi
        echo "ãã¼ã¿ãã¼ã¹æ¥ç¶è©¦è¡ $attempt/$max_attempts..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        echo -e "${RED}â ãã¼ã¿ãã¼ã¹ã¸ã®æ¥ç¶ãã¿ã¤ã ã¢ã¦ããã¾ãã${NC}"
        exit 1
    fi
}

# ã¢ããªã±ã¼ã·ã§ã³ã®èµ·å
start_application() {
    echo -e "${BLUE}íº ã¢ããªã±ã¼ã·ã§ã³ã®èµ·åä¸­...${NC}"
    
    docker-compose up -d
    
    echo "ãµã¼ãã¹ã®èµ·åç¢ºèªä¸­..."
    sleep 15
    
    max_attempts=20
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost:8000/health > /dev/null 2>&1; then
            echo -e "${GREEN}â ããã¯ã¨ã³ãAPIãèµ·åãã¾ãã${NC}"
            break
        fi
        echo "ããã¯ã¨ã³ãAPIèµ·åç¢ºèª $attempt/$max_attempts..."
        sleep 3
        attempt=$((attempt + 1))
    done
    
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost:3000 > /dev/null 2>&1; then
            echo -e "${GREEN}â ãã­ã³ãã¨ã³ããèµ·åãã¾ãã${NC}"
            break
        fi
        echo "ãã­ã³ãã¨ã³ãèµ·åç¢ºèª $attempt/$max_attempts..."
        sleep 3
        attempt=$((attempt + 1))
    done
}

# æåã¡ãã»ã¼ã¸ã®è¡¨ç¤º
show_success() {
    echo -e "${GREEN}"
    echo "í¾ ã»ããã¢ããå®äºï¼"
    echo "==============================================="
    echo "í¼ ãã­ã³ãã¨ã³ã: http://localhost:3000"
    echo "í´§ ããã¯ã¨ã³ãAPI: http://localhost:8000"
    echo "í³ APIææ¸: http://localhost:8000/docs"
    echo "==============================================="
    echo ""
    echo "í³ ä½¿ç¨æ¹æ³:"
    echo "  â¢ ãã©ã¦ã¶ã§ http://localhost:3000 ã«ã¢ã¯ã»ã¹"
    echo "  â¢ èå³ã®ããåéãèªç±ã«å¥åãã¦æ¤ç´¢"
    echo "  â¢ AIæ¨å¥¨ã·ã¹ãã ãé¢é£ç ç©¶å®¤ãè¡¨ç¤º"
    echo ""
    echo "ï¿½ï¿½ï¸ ç®¡çã³ãã³ã:"
    echo "  â¢ åæ­¢: docker-compose down"
    echo "  â¢ åèµ·å: docker-compose restart"
    echo "  â¢ ã­ã°ç¢ºèª: docker-compose logs -f"
    echo "${NC}"
}

# ã¨ã©ã¼ãã³ããªã³ã°
error_handler() {
    echo -e "${RED}â ã»ããã¢ããä¸­ã«ã¨ã©ã¼ãçºçãã¾ãã${NC}"
    echo "ã­ã°ãç¢ºèªãã¦ãã ãã: docker-compose logs"
    exit 1
}

trap error_handler ERR

# ã¡ã¤ã³å®è¡
main() {
    echo -e "${BLUE}ç ç©¶å®¤ãã¡ã¤ã³ãã¼ èªåã»ããã¢ããã¹ã¯ãªãã${NC}"
    echo "============================================="
    
    check_requirements
    setup_env
    build_docker
    init_database
    start_application
    show_success
}

# ã¹ã¯ãªããå®è¡
main "$@"
