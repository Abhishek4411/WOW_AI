# Database Schema for Jute Bags E-commerce Website

## Tables

### Users
- user_id (PK, UUID)
- username (unique)
- email (unique)
- password_hash
- full_name
- phone
- address
- created_at
- updated_at

### Products
- product_id (PK, UUID)
- name
- description
- price
- stock_quantity
- category
- main_image_url
- created_at
- updated_at

### ProductImages
- image_id (PK, UUID)
- product_id (FK)
- image_url

### Orders
- order_id (PK, UUID)
- user_id (FK)
- status (enum: pending, processing, shipped, delivered, canceled)
- total_amount
- shipping_address
- placed_at
- updated_at

### OrderItems
- order_item_id (PK, UUID)
- order_id (FK)
- product_id (FK)
- quantity
- price_at_order

### CartItems
- cart_item_id (PK, UUID)
- user_id (FK)
- product_id (FK)
- quantity
- added_at


## Backend API design (summary)

### User APIs
- POST /users/register
- POST /users/login
- GET /users/:id
- PUT /users/:id

### Product APIs
- GET /products
- GET /products/:id

### Cart APIs
- GET /cart
- POST /cart
- PUT /cart/:id
- DELETE /cart/:id

### Order APIs
- POST /orders
- GET /orders/:id
- GET /orders/user/:userId


This schema and API design will support product management, order processing, user authentication, and cart handling.