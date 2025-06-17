#!/bin/bash
echo "=== Project Status ==="
echo ""

# Check Python venv
if [ -d "venv" ]; then
    echo "Python venv: EXISTS"
else 
    echo "Python venv: NOT FOUND"
fi

# Check Node modules
if [ -d "frontend/node_modules" ]; then
    echo "Node modules: INSTALLED"
else
    echo "Node modules: NOT INSTALLED"  
fi

# Check Docker containers
echo ""
echo "=== Docker Containers ==="
docker-compose ps

echo ""
echo "=== Health Checks ==="
curl -s http://localhost:8000/health && echo "" || echo "Backend API: ERROR"
curl -s http://localhost:3000 >/dev/null && echo "Frontend: OK" || echo "Frontend: ERROR"
