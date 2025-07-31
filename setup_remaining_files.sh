at > requirements.txt << 'REQEOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
python-multipart==0.0.6
pydantic==2.5.0
pytest==7.4.3
pytest-asyncio==0.21.1
httpx==0.25.2
REQEOF

at > requirements.txt << 'REQEOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
python-multipart==0.0.6
pydantic==2.5.0
pytest==7.4.3
pytest-asyncio==0.21.1
httpx==0.25.2
REQEOF

echo "🐚 Criando scripts bash..."
cat > scripts/max-min-size.sh << 'SCRIPTEOF'
#!/bin/bash
cat > scripts/max-min-size.sh << 'SCRIPTEOF'
#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Uso: $0 <arquivo> [-min]"
    exit 1
fi

INPUT_FILE="$1"
MODE="max"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Erro: Arquivo '$INPUT_FILE' não encontrado."
    exit 1
fi

if [ "$2" = "-min" ]; then
    MODE="min"
fi

if [ "$MODE" = "max" ]; then
    awk '{
        size_value = $NF
        if (size_value > max_size || max_size == "") {
            max_size = size_value
            max_record = $0
        }
    } END {
        print max_record
    }' "$INPUT_FILE"
else
    awk '{
        size_value = $NF
        if (size_value < min_size || min_size == "") {
            min_size = size_value
            min_record = $0
        }
    } END {
        print min_record
    }' "$INPUT_FILE"
fi
SCRIPTEOF

# Script order-by-username.sh
cat > scripts/order-by-username.sh << 'SCRIPTEOF'
#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Uso: $0 <arquivo> [-desc]"
    exit 1
fi

INPUT_FILE="$1"
ORDER="asc"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Erro: Arquivo '$INPUT_FILE' não encontrado."
    exit 1
fi

if [ "$2" = "-desc" ]; then
    ORDER="desc"
fi

if [ "$ORDER" = "asc" ]; then
    sort "$INPUT_FILE"
else
    sort -r "$INPUT_FILE"
fi
SCRIPTEOF

# Script between-msgs.sh
cat > scripts/between-msgs.sh << 'SCRIPTEOF'
#!/bin/bash

if [ $# -ne 3 ]; then
    echo "Uso: $0 <arquivo> <min_messages> <max_messages>"
    exit 1
fi

INPUT_FILE="$1"
MIN_MESSAGES="$2"
MAX_MESSAGES="$3"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Erro: Arquivo '$INPUT_FILE' não encontrado."
    exit 1
fi

if ! [[ "$MIN_MESSAGES" =~ ^[0-9]+$ ]] || ! [[ "$MAX_MESSAGES" =~ ^[0-9]+$ ]]; then
    echo "Erro: Os valores de mensagens devem ser números inteiros."
    exit 1
fi

awk -v min="$MIN_MESSAGES" -v max="$MAX_MESSAGES" '{
    messages = $3 + 0
    if (messages >= min && messages <= max) {
        print $0
    }
}' "$INPUT_FILE" | sort
SCRIPTEOF

# 3. Criar arquivos Python
echo "🐍 Criando aplicação Python..."

# app/__init__.py
touch app/__init__.py
touch app/api/__init__.py

# app/models.py
cat > app/models.py << 'PYEOF'
from pydantic import BaseModel
from typing import List, Optional
from enum import Enum

class UserRecord(BaseModel):
    username: str
    folder: str
    numberMessages: int
    size: int

class OrderDirection(str, Enum):
    asc = "asc"
    desc = "desc"

class FileInfo(BaseModel):
    filename: str
    size: int
    created_at: str

class PaginatedResponse(BaseModel):
    data: List[UserRecord]
    page: int
    page_size: int
    total_items: int
    total_pages: int

class PaginatedFileResponse(BaseModel):
    data: List[FileInfo]
    page: int
    page_size: int
    total_items: int
    total_pages: int

class ErrorResponse(BaseModel):
    error: str
    message: str
PYEOF

# app/utils.py
cat > app/utils.py << 'PYEOF'
import re
import os
import subprocess
from typing import List, Optional
from app.models import UserRecord

def is_valid_filename(filename: str) -> bool:
    pattern = r'^[A-Za-z0-9_-]+$'
    return bool(re.match(pattern, filename))

def parse_user_record(line: str) -> Optional[UserRecord]:
    try:
        parts = line.strip().split()
        if len(parts) >= 5 and parts[-2] == "size":
            username = parts[0]
            folder = parts[1]
            number_messages = int(parts[2])
            size = int(parts[-1])
            
            return UserRecord(
                username=username,
                folder=folder,
                numberMessages=number_messages,
                size=size
            )
    except (ValueError, IndexError):
        pass
    return None

def execute_script(script_path: str, args: List[str]) -> str:
    try:
        cmd = ['bash', script_path] + args
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        raise Exception(f"Erro ao executar script: {e.stderr}")
    except FileNotFoundError:
        raise Exception(f"Script não encontrado: {script_path}")

def paginate_list(items: List, page: int, page_size: int):
    total_items = len(items)
    total_pages = (total_items + page_size - 1) // page_size
    
    start_idx = (page - 1) * page_size
    end_idx = start_idx + page_size
    
    return {
        'data': items[start_idx:end_idx],
        'page': page,
        'page_size': page_size,
        'total_items': total_items,
        'total_pages': total_pages
    }
PYEOF

# app/services.py
cat > app/services.py << 'PYEOF'
import os
from datetime import datetime
from typing import List, Optional
from pathlib import Path

from app.models import UserRecord, FileInfo, OrderDirection
from app.utils import execute_script, parse_user_record, paginate_list

class FileService:
    def __init__(self, storage_path: str = "/tmp/teste-api"):
        self.storage_path = Path(storage_path)
        self.storage_path.mkdir(parents=True, exist_ok=True)
        
        self.scripts_path = Path("scripts")
        self.max_min_script = self.scripts_path / "max-min-size.sh"
        self.order_script = self.scripts_path / "order-by-username.sh"
        self.between_script = self.scripts_path / "between-msgs.sh"
    
    def save_file(self, filename: str, content: bytes) -> bool:
        file_path = self.storage_path / filename
        is_new_file = not file_path.exists()
        
        with open(file_path, 'wb') as f:
            f.write(content)
        
        return is_new_file
    
    def list_files(self, page: int = 1, page_size: int = 10) -> dict:
        files = []
        for file_path in self.storage_path.iterdir():
            if file_path.is_file():
                stat = file_path.stat()
                files.append(FileInfo(
                    filename=file_path.name,
                    size=stat.st_size,
                    created_at=datetime.fromtimestamp(stat.st_ctime).isoformat()
                ))
        
        files.sort(key=lambda x: x.filename)
        return paginate_list(files, page, page_size)
    
    def file_exists(self, filename: str) -> bool:
        return (self.storage_path / filename).exists()
    
    def get_max_min_size_user(self, filename: str, min_mode: bool = False) -> Optional[UserRecord]:
        if not self.file_exists(filename):
            return None
        
        file_path = self.storage_path / filename
        args = [str(file_path)]
        if min_mode:
            args.append("-min")
        
        try:
            output = execute_script(str(self.max_min_script), args)
            if output:
                return parse_user_record(output)
        except Exception:
            pass
        
        return None
    
    def get_ordered_users(self, filename: str, order: OrderDirection = OrderDirection.asc, 
                         page: int = 1, page_size: int = 10, 
                         username_filter: Optional[str] = None) -> Optional[dict]:
        if not self.file_exists(filename):
            return None
        
        file_path = self.storage_path / filename
        args = [str(file_path)]
        if order == OrderDirection.desc:
            args.append("-desc")
        
        try:
            output = execute_script(str(self.order_script), args)
            if not output:
                return {'data': [], 'page': page, 'page_size': page_size, 'total_items': 0, 'total_pages': 0}
            
            users = []
            for line in output.split('\n'):
                if line.strip():
                    user = parse_user_record(line)
                    if user:
                        if username_filter is None or username_filter.lower() in user.username.lower():
                            users.append(user)
            
            return paginate_list(users, page, page_size)
        except Exception:
            pass
        
        return None
    
    def get_users_between_messages(self, filename: str, min_messages: int, max_messages: int,
                                  page: int = 1, page_size: int = 10,
                                  username_filter: Optional[str] = None) -> Optional[dict]:
        if not self.file_exists(filename):
            return None
        
        file_path = self.storage_path / filename
        args = [str(file_path), str(min_messages), str(max_messages)]
        
        try:
            output = execute_script(str(self.between_script), args)
            if not output:
                return {'data': [], 'page': page, 'page_size': page_size, 'total_items': 0, 'total_pages': 0}
            
            users = []
            for line in output.split('\n'):
                if line.strip():
                    user = parse_user_record(line)
                    if user:
                        if username_filter is None or username_filter.lower() in user.username.lower():
                            users.append(user)
            
            return paginate_list(users, page, page_size)
        except Exception:
            pass
        
        return None
PYEOF

# app/api/routes.py
cat > app/api/routes.py << 'PYEOF'
from fastapi import APIRouter, UploadFile, File, HTTPException, Query, status
from typing import Optional

from app.models import (
    UserRecord, OrderDirection, PaginatedResponse, 
    PaginatedFileResponse, ErrorResponse
)
from app.services import FileService
from app.utils import is_valid_filename

router = APIRouter()
file_service = FileService()

@router.put("/files/{filename}", status_code=status.HTTP_201_CREATED)
async def upload_file(filename: str, file: UploadFile = File(...)):
    if not is_valid_filename(filename):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Nome de arquivo não permitido. Use apenas A-Z, a-z, 0-9, - e _"
        )
    
    content = await file.read()
    is_new_file = file_service.save_file(filename, content)
    
    if is_new_file:
        return {"message": "Arquivo criado com sucesso", "filename": filename}
    else:
        return {"message": "Arquivo substituído com sucesso", "filename": filename}

@router.get("/files", response_model=PaginatedFileResponse)
async def list_files(
    page: int = Query(1, ge=1, description="Número da página"),
    page_size: int = Query(10, ge=1, le=100, description="Itens por página")
):
    result = file_service.list_files(page, page_size)
    return PaginatedFileResponse(**result)

@router.get("/files/{filename}/max-size", response_model=UserRecord)
async def get_max_size_user(filename: str):
    user = file_service.get_max_min_size_user(filename, min_mode=False)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Arquivo não encontrado"
        )
    return user

@router.get("/files/{filename}/min-size", response_model=UserRecord)
async def get_min_size_user(filename: str):
    user = file_service.get_max_min_size_user(filename, min_mode=True)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Arquivo não encontrado"
        )
    return user

@router.get("/files/{filename}/users", response_model=PaginatedResponse)
async def get_ordered_users(
    filename: str,
    order: OrderDirection = Query(OrderDirection.asc, description="Direção da ordenação"),
    page: int = Query(1, ge=1, description="Número da página"),
    page_size: int = Query(10, ge=1, le=100, description="Itens por página"),
    username: Optional[str] = Query(None, description="Filtro por username")
):
    result = file_service.get_ordered_users(filename, order, page, page_size, username)
    if result is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Arquivo não encontrado"
        )
    return PaginatedResponse(**result)

@router.get("/files/{filename}/users/between", response_model=PaginatedResponse)
async def get_users_between_messages(
    filename: str,
    min_messages: int = Query(..., ge=0, description="Número mínimo de mensagens"),
    max_messages: int = Query(..., ge=0, description="Número máximo de mensagens"),
    page: int = Query(1, ge=1, description="Número da página"),
    page_size: int = Query(10, ge=1, le=100, description="Itens por página"),
    username: Optional[str] = Query(None, description="Filtro por username")
):
    if min_messages > max_messages:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Número mínimo de mensagens não pode ser maior que o máximo"
        )
    
    result = file_service.get_users_between_messages(
        filename, min_messages, max_messages, page, page_size, username
    )
    if result is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Arquivo não encontrado"
        )
    return PaginatedResponse(**result)
PYEOF

# app/main.py
cat > app/main.py << 'PYEOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.routes import router

app = FastAPI(
    title="Email Analytics API",
    description="API para análise de dados de email com scripts bash",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router, prefix="/api/v1")

@app.get("/")
async def root():
    return {"message": "Email Analytics API", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
PYEOF

# 4. Criar testes
echo "🧪 Criando testes..."
touch tests/__init__.py

cat > tests/test_utils.py << 'PYEOF'
import pytest
from app.utils import is_valid_filename, parse_user_record, paginate_list

class TestValidateFilename:
    def test_valid_filenames(self):
        valid_names = ["input", "data_file", "test-file", "File123"]
        for name in valid_names:
            assert is_valid_filename(name)
    
    def test_invalid_filenames(self):
        invalid_names = ["file.txt", "file with spaces", "file@email.com"]
        for name in invalid_names:
            assert not is_valid_filename(name)

class TestParseUserRecord:
    def test_parse_valid_record(self):
        line = "hgioep@uol.com.br inbox 000000050 size 001003108"
        user = parse_user_record(line)
        
        assert user is not None
        assert user.username == "hgioep@uol.com.br"
        assert user.folder == "inbox"
        assert user.numberMessages == 50
        assert user.size == 1003108

class TestPagination:
    def test_paginate_first_page(self):
        items = list(range(25))
        result = paginate_list(items, 1, 10)
        
        assert result['data'] == list(range(10))
        assert result['page'] == 1
        assert result['page_size'] == 10
        assert result['total_items'] == 25
        assert result['total_pages'] == 3
PYEOF

# 5. Criar scripts de execução
echo "⚙️ Criando scripts de execução..."

cat > run_dev.sh << 'RUNEOF'
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
RUNEOF

cat > run_tests.sh << 'RUNEOF'
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
RUNEOF

# 6. Configurar permissões
chmod +x scripts/*.sh
chmod +x run_dev.sh
chmod +x run_tests.sh

echo ""
echo "🎉 Projeto completo criado com sucesso!"
echo ""
echo "📂 Estrutura final:"
find . -type f -name "*.py" -o -name "*.sh" -o -name "*.txt" | head -15

echo ""
echo "🚀 Próximos passos:"
echo "   1. ./run_dev.sh     # Para iniciar em desenvolvimento"
echo "   2. ./run_tests.sh   # Para testar"
echo ""
echo "📖 URLs importantes:"
echo "   🌐 API: http://localhost:8000"
echo "   📚 Docs: http://localhost:8000/docs"
echo "   ❤️  Health: http://localhost:8000/health"
