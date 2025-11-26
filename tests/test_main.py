"""Tests for the main API."""
import pytest
from fastapi.testclient import TestClient
from api.main import app

client = TestClient(app)


def test_root():
    """Test the root endpoint."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "version" in data
    assert "mounted_apps" in data


def test_health_check():
    """Test the health check endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "app" in data
    assert "version" in data


def test_mounted_app_accessible():
    """Test that mounted apps are accessible."""
    response = client.get("/example/")
    assert response.status_code == 200
    data = response.json()
    assert data["app"] == "Example App"
