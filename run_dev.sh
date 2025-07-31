#!/bin/bash

echo "🚀 Iniciando Email Analytics API em modo desenvolvimento..."

if [ ! -f "requirements.txt" ]; then
    echo "❌ Execute este script no diretório raiz do projeto"
    exit 1
fi

if [ ! -d "venv" ]; then
    echo "📦 Criando ambiente virtual..."
    python3 -m venv venv
fi

echo "🔧 Ativando ambiente virtual..."
source venv/bin/activate

echo "📥 Instalando dependências..."
pip install -r requirements.txt

echo "📁 Criando diretórios..."
mkdir -p /tmp/teste-api scripts data

echo "🔐 Configurando permissões dos scripts..."
chmod +x scripts/*.sh

if [ -f "data/input" ] && [ ! -f "/tmp/teste-api/input" ]; then
    echo "📋 Copiando arquivo de exemplo..."
    cp data/input /tmp/teste-api/
fi

echo "✅ Configuração concluída!"
echo ""
echo "🌐 Iniciando servidor de desenvolvimento..."
echo "📖 API Docs: http://localhost:8000/docs"
echo "🔍 Health Check: http://localhost:8000/health"
echo ""

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
