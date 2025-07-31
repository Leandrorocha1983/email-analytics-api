#!/bin/bash

echo "🎯 DEMONSTRAÇÃO COMPLETA - EMAIL ANALYTICS API"
echo "=============================================="
echo ""

API_URL="http://localhost:8000/api/v1"
HEALTH_URL="http://localhost:8000/health"

# Verificar se API está rodando
echo "🔍 Verificando se API está online..."
if ! curl -s "$HEALTH_URL" > /dev/null; then
    echo "❌ API não está rodando. Inicie com: ./run_dev.sh"
    exit 1
fi
echo "✅ API está rodando!"
echo ""

echo "❤️  0. HEALTH CHECK:"
curl -s "$HEALTH_URL" | python3 -m json.tool
echo ""

echo "📤 1. UPLOAD DE ARQUIVO:"
curl -X PUT "$API_URL/files/dados_avaliacao" -F "file=@data/input"
echo -e "\n"

echo "📊 2. USUÁRIO COM MAIOR SIZE:"
curl -s "$API_URL/files/dados_avaliacao/max-size" | python3 -m json.tool
echo ""

echo "📉 3. USUÁRIO COM MENOR SIZE (BÔNUS):"
curl -s "$API_URL/files/dados_avaliacao/min-size" | python3 -m json.tool
echo ""

echo "📝 4. USUÁRIOS ORDENADOS CRESCENTE:"
curl -s "$API_URL/files/dados_avaliacao/users?page=1&page_size=3" | python3 -m json.tool
echo ""

echo "📝 5. USUÁRIOS ORDENADOS DECRESCENTE (BÔNUS):"
curl -s "$API_URL/files/dados_avaliacao/users?order=desc&page=1&page_size=3" | python3 -m json.tool
echo ""

echo "🔍 6. FILTRO POR USERNAME (BÔNUS):"
curl -s "$API_URL/files/dados_avaliacao/users?username=uol&page_size=3" | python3 -m json.tool
echo ""

echo "📬 7. USUÁRIOS ENTRE FAIXA DE MENSAGENS:"
curl -s "$API_URL/files/dados_avaliacao/users/between?min_messages=1000000&max_messages=3000000&page_size=3" | python3 -m json.tool
echo ""

echo "📋 8. LISTAGEM DE ARQUIVOS COM PAGINAÇÃO:"
curl -s "$API_URL/files" | python3 -m json.tool
echo ""

echo "❌ 9. TESTE DE ERRO - ARQUIVO NÃO ENCONTRADO:"
curl -s "$API_URL/files/arquivo_inexistente/max-size" | python3 -m json.tool
echo ""

echo "❌ 10. TESTE DE ERRO - NOME INVÁLIDO:"
echo "teste" | curl -s -X PUT "$API_URL/files/arquivo.inválido" -F "file=@-" | python3 -m json.tool
echo ""

echo "🐚 11. TESTANDO SCRIPTS BASH DIRETAMENTE:"
echo "  Max size:"
./scripts/max-min-size.sh data/input
echo "  Min size:"
./scripts/max-min-size.sh data/input -min
echo "  Ordenação (3 primeiros):"
./scripts/order-by-username.sh data/input | head -3
echo "  Entre mensagens:"
./scripts/between-msgs.sh data/input 1000000 3000000 | head -3

echo ""
echo "✅ DEMONSTRAÇÃO CONCLUÍDA!"
echo "📖 Documentação: http://localhost:8000/docs"
echo "🎯 Status Codes testados: 201, 200, 404, 400"
