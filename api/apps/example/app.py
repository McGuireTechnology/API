from fastapi import FastAPI, Query
from typing import Optional, List
from pydantic import BaseModel


# Pydantic models for this app
class Item(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    price: float
    in_stock: bool = True


class ItemCreate(BaseModel):
    name: str
    description: Optional[str] = None
    price: float
    in_stock: bool = True


class ItemsResponse(BaseModel):
    items: List[Item]
    total: int
    skip: int
    limit: int


# Create the FastAPI app for this mounted application
app = FastAPI(
    title="Example App",
    description="Example mounted application demonstrating the pattern",
    version="1.0.0",
)


# In-memory storage for demo purposes
items_db: List[Item] = [
    Item(id=1, name="Widget", description="A useful widget", price=19.99, in_stock=True),
    Item(id=2, name="Gadget", description="An amazing gadget", price=29.99, in_stock=True),
    Item(id=3, name="Tool", description="A handy tool", price=39.99, in_stock=False),
]


@app.get("/", tags=["Root"])
async def example_root():
    """
    Example root endpoint for this app.
    
    This demonstrates how to structure a mounted application.
    Each mounted app is a full FastAPI application with its own
    middleware, dependencies, and configuration.
    """
    return {
        "app": "Example App",
        "version": "1.0.0",
        "message": "This is an example mounted FastAPI application",
        "endpoints": {
            "items": "/items - List all items",
            "item_detail": "/items/{id} - Get item by ID",
            "create_item": "/items - POST to create new item",
        },
    }


@app.get("/items", response_model=ItemsResponse, tags=["Items"])
async def list_items(
    skip: int = Query(0, ge=0, description="Number of items to skip"),
    limit: int = Query(10, ge=1, le=100, description="Max items to return"),
    in_stock: Optional[bool] = Query(None, description="Filter by stock status"),
):
    """
    List items with pagination and optional filtering.
    
    - **skip**: Number of items to skip (for pagination)
    - **limit**: Maximum number of items to return
    - **in_stock**: Optional filter by stock status
    """
    filtered_items = items_db
    
    if in_stock is not None:
        filtered_items = [item for item in items_db if item.in_stock == in_stock]
    
    paginated_items = filtered_items[skip : skip + limit]
    
    return ItemsResponse(
        items=paginated_items,
        total=len(filtered_items),
        skip=skip,
        limit=limit,
    )


@app.get("/items/{item_id}", response_model=Item, tags=["Items"])
async def get_item(item_id: int):
    """
    Get a specific item by ID.
    
    Example endpoint showing path parameters.
    """
    for item in items_db:
        if item.id == item_id:
            return item
    
    return {"error": f"Item with ID {item_id} not found"}, 404


@app.post("/items", response_model=Item, status_code=201, tags=["Items"])
async def create_item(item: ItemCreate):
    """
    Create a new item.
    
    Example endpoint showing POST operation with request body.
    """
    new_id = max([item.id for item in items_db], default=0) + 1
    new_item = Item(id=new_id, **item.model_dump())
    items_db.append(new_item)
    
    return new_item


@app.put("/items/{item_id}", response_model=Item, tags=["Items"])
async def update_item(item_id: int, item: ItemCreate):
    """Update an existing item."""
    for idx, existing_item in enumerate(items_db):
        if existing_item.id == item_id:
            updated_item = Item(id=item_id, **item.model_dump())
            items_db[idx] = updated_item
            return updated_item
    
    return {"error": f"Item with ID {item_id} not found"}, 404


@app.delete("/items/{item_id}", tags=["Items"])
async def delete_item(item_id: int):
    """Delete an item."""
    for idx, item in enumerate(items_db):
        if item.id == item_id:
            items_db.pop(idx)
            return {"message": f"Item {item_id} deleted successfully"}
    
    return {"error": f"Item with ID {item_id} not found"}, 404


@app.get("/health", tags=["Health"])
async def health_check():
    """Health check endpoint for this app."""
    return {
        "status": "healthy",
        "app": "Example App",
        "items_count": len(items_db),
    }
