from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, Field
from typing import Optional

from app.routers.auth import get_current_user_id
from app.database import get_user_by_id, update_user

router = APIRouter(prefix="/users", tags=["users"])
security = HTTPBearer()

class ProfileUpdateRequest(BaseModel):
    display_name: str
    currency: str
    country: Optional[str] = None

def get_auth_user_id(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    token = credentials.credentials
    return get_current_user_id(token)

@router.get("/me")
def get_me(user_id: str = Depends(get_auth_user_id)):
    user = get_user_by_id(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User profile not found"
        )
    return {
        "id": user["id"],
        "name": user["display_name"],
        "currency": user["currency"],
        "country": user["country"]
    }

@router.put("/me")
def update_me(req: ProfileUpdateRequest, user_id: str = Depends(get_auth_user_id)):
    user = get_user_by_id(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User profile not found"
        )
        
    updated = update_user(
        user_id=user_id,
        display_name=req.display_name,
        currency=req.currency,
        country=req.country
    )
    
    if not updated:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update profile"
        )
        
    return {
        "id": updated["id"],
        "name": updated["display_name"],
        "currency": updated["currency"],
        "country": updated["country"]
    }
