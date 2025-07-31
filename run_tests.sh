#!/bin/bash

echo "🧪 Executando testes da Email Analytics API..."

if [ -z "$VIRTUAL_ENV" ]; then
    echo "⚠️  Ativando ambiente virtual..."
    source venv/bin/activate
fi

mkdir -p /tmp/teste-api scripts data
chmod +x scripts/*.sh

echo ""
echo "🔍 Executando testes unitários..."
python -m pytest tests/test_utils.py -v

echo ""
echo "🐚 Testando scripts bash..."

if [ -f "data/input" ]; then
    echo "📊 Testando max-min-size.sh..."
    echo "  - Usuário com maior size:"
    ./scripts/max-min-size.sh data/input
    echo "  - Usuário com menor size:"
    ./scripts/max-min-size.sh data/input -min
    
    echo "📝 Testando order-by-username.sh..."
    echo "  - Ordenação crescente (primeiros 3):"
    ./scripts/order-by-username.sh data/input | head -n 3
    echo "  - Ordenação decrescente (primeiros 3):"
    ./scripts/order-by-username.sh data/input -desc | head -n 3
    
    echo "📬 Testando between-msgs.sh..."
    echo "  - Usuários entre 1000000 e 2000000 mensagens:"
    ./scripts/between-msgs.sh data/input 1000000 2000000 | head -n 5
else
    echo "⚠️  Arquivo data/input não encontrado"
fi

echo ""
echo "✅ Testes concluídos!"
