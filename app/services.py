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
