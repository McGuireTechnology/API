"""Tests for the example app."""
import pytest
from fastapi.testclient import TestClient
from api.apps.example.app import app

client = TestClient(app)


def test_root():
    """Test the root endpoint."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["app"] == "Example App"
    assert data["version"] == "1.0.0"


def test_list_items():
    """Test listing items."""
    response = client.get("/items")
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data
    assert len(data["items"]) > 0


def test_list_items_with_pagination():
    """Test item pagination."""
    response = client.get("/items?skip=1&limit=1")
    assert response.status_code == 200
    data = response.json()
    assert data["skip"] == 1
    assert data["limit"] == 1
    assert len(data["items"]) <= 1


def test_get_item():
    """Test getting a specific item."""
    response = client.get("/items/1")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == 1
    assert "name" in data


def test_create_item():
    """Test creating a new item."""
    new_item = {
        "name": "Test Item",
        "description": "A test item",
        "price": 9.99,
        "in_stock": True,
    }
    response = client.post("/items", json=new_item)
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == new_item["name"]
    assert data["price"] == new_item["price"]


def test_health_check():
    """Test the health check endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "items_count" in data
