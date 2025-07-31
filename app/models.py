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
