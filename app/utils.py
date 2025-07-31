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
