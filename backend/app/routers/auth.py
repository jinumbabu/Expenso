from fastapi import APIRouter, HTTPException, Depends, status
from pydantic import BaseModel, Field
import jwt
import uuid
from datetime import datetime, timedelta
from typing import Optional, Dict, Any

from app.config import settings
from app.database import get_user_by_google_id, get_user_by_email, create_user

router = APIRouter(prefix="/auth", tags=["authentication"])

class GoogleLoginRequest(BaseModel):
    google_token: str

class RefreshRequest(BaseModel):
    refresh_token: str

def create_tokens(user_id: str) -> Dict[str, str]:
    now = datetime.utcnow()
    
    # Access Token
    access_expiry = now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_payload = {
        "sub": user_id,
        "type": "access",
        "exp": access_expiry,
        "iat": now
    }
    access_token = jwt.encode(access_payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)
    
    # Refresh Token
    refresh_expiry = now + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    refresh_payload = {
        "sub": user_id,
        "type": "refresh",
        "exp": refresh_expiry,
        "iat": now
    }
    refresh_token = jwt.encode(refresh_payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token
    }

def get_current_user_id(token: str) -> str:
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        if payload.get("type") != "access":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type"
            )
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token missing subject"
            )
        return user_id
    except jwt.PyJWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )

@router.post("/google")
def login_with_google(req: GoogleLoginRequest):
    token = req.google_token
    email = "user@example.com"
    name = "Jinu"
    google_id = "mock-google-id"

    # Check for Mock Mode
    is_mock = False
    if settings.DEV_MODE and (token.startswith("mock-") or token == "google-id-token"):
        is_mock = True
        if "email" in token:
            # e.g., mock-user@example.com-token
            parts = token.split("-")
            for part in parts:
                if "@" in part:
                    email = part
                    name = part.split("@")[0].capitalize()
        google_id = f"mock_{email}"
    else:
        # Real Google Sign-in Verification
        try:
            from google.oauth2 import id_token
            from google.auth.transport import requests as google_requests
            
            # Verify the token
            idinfo = id_token.verify_oauth2_token(token, google_requests.Request(), settings.GOOGLE_CLIENT_ID)
            
            # ID token passed validation
            google_id = idinfo['sub']
            email = idinfo['email']
            name = idinfo.get('name', email.split('@')[0].capitalize())
        except Exception as e:
            if settings.DEV_MODE:
                # If Google client ID is not setup, fallback to mock login in Dev mode
                is_mock = True
                google_id = f"fallback_{token}"
            else:
                raise HTTPException(
                    status_code=401,
                    detail=f"Google authentication failed: {str(e)}"
                )

    # Check if user exists by Google ID
    user = get_user_by_google_id(google_id)
    if not user:
        # Fallback check by email to merge accounts if needed
        user = get_user_by_email(email)
        if not user:
            # Create user
            user_id = str(uuid.uuid4())
            user = create_user(
                user_id=user_id,
                google_id=google_id,
                email=email,
                display_name=name,
                currency="INR",
                country="IN"
            )
        else:
            # Update google_id if matched by email
            # Just return this user
            pass
            
    # Generate tokens
    tokens = create_tokens(user["id"])
    
    return {
        "success": True,
        "data": {
            "access_token": tokens["access_token"],
            "refresh_token": tokens["refresh_token"],
            "user": {
                "id": user["id"],
                "name": user["display_name"],
                "email": user["email"]
            }
        }
    }

@router.post("/refresh")
def refresh_token(req: RefreshRequest):
    try:
        payload = jwt.decode(req.refresh_token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        if payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type"
            )
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token missing subject"
            )
            
        # Generate new access token
        now = datetime.utcnow()
        access_expiry = now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_payload = {
            "sub": user_id,
            "type": "access",
            "exp": access_expiry,
            "iat": now
        }
        new_access_token = jwt.encode(access_payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)
        
        return {
            "success": True,
            "data": {
                "access_token": new_access_token
            }
        }
    except jwt.PyJWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token"
        )

@router.post("/logout")
def logout():
    # Stateless JWT logout is successful immediately
    return {"success": True}
