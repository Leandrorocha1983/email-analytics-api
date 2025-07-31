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
