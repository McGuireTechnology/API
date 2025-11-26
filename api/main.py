from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from api.shared.config import settings
from api.apps import example


# Create the main FastAPI application
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="Centralized API for McGuire Technology applications",
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "message": f"Welcome to {settings.app_name}",
        "version": settings.app_version,
        "environment": settings.environment,
        "docs": "/docs" if settings.debug else "Documentation disabled",
        "mounted_apps": {
            "example": "/example - Example application with CRUD operations",
        },
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "app": settings.app_name,
        "version": settings.app_version,
        "environment": settings.environment,
    }


# Mount FastAPI applications
# Each mounted app is a complete FastAPI application
app.mount("/example", example.app)

# Add more mounted apps here:
# from api.apps import auth, users
# app.mount("/auth", auth.app)
# app.mount("/users", users.app)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "api.main:app",
        host=settings.api_host,
        port=settings.api_port,
        reload=settings.debug,
    )
