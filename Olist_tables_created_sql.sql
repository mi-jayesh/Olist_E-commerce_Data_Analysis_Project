--------- Creating Tables in PostgreSQL    ------------------

--------- Creating customers table   -------------------

CREATE TABLE customers (
    customer_id TEXT PRIMARY KEY, -- Define primary key
    customer_unique_id TEXT NOT NULL UNIQUE, -- Unique constraint for unique identifier
    customer_zip_code_prefix INT,
    customer_city VARCHAR(50),
    customer_state_code VARCHAR(10), -- Keeping one state column
	customer_state varchar(50)
);

---------------------------------------------------------------------------------
--------- Creating Orders table   -------------------

CREATE TABLE orders (
    order_id TEXT PRIMARY KEY, -- Primary key for orders table
    customer_id TEXT NOT NULL, -- Foreign key reference to customers table
    order_status VARCHAR(50),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
        ON DELETE CASCADE -- Automatically delete orders when a customer is deleted
);

---------------------------------------------------------------------------------
--------- Creating Order Items table   -------------------

CREATE TABLE order_items (
    order_id text,
    order_item_id int, 
    product_id text, 
    seller_id text,
    shipping_limit_date timestamp,
    price float, 
    freight_value float,
    constraint fk_product_id foreign key (product_id) references products(product_id),
    constraint fk_seller_id foreign key (seller_id) references sellers(seller_id)  -- Corrected foreign key reference
);

---------------------------------------------------------------------------------
--------- Creating Order Payments  table   -------------------

CREATE TABLE order_payments (
    order_id TEXT,
    payment_sequential INT,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value FLOAT,
    PRIMARY KEY (order_id, payment_sequential),
    CONSTRAINT fk_order FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
---------------------------------------------------------------------------------
--------- Creating Products table   -------------------

CREATE TABLE products (
    product_id TEXT PRIMARY KEY,
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,  
    product_weight_g FLOAT,
    product_length_cm FLOAT,
    product_height_cm FLOAT,
    product_width_cm FLOAT,
	product_category_name TEXT
);

---------------------------------------------------------------------------------
--------- Creating Reviews table   -------------------

CREATE TABLE reviews (
    review_id TEXT PRIMARY KEY,
    order_id TEXT,
    review_score INT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    CONSTRAINT fk_order_id FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

---------------------------------------------------------------------------------
--------- Creating Sellers table   -------------------

CREATE TABLE sellers (
    seller_id TEXT PRIMARY KEY,
    seller_zip_code_prefix int, 
    seller_city VARCHAR(50),
    seller_state_code VARCHAR(10),
	seller_state varchar(50)
);

---------------------------------------------------------------------------------
--------- Creating Geolocation table   -------------------

CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat FLOAT,
    geolocation_lng FLOAT,
    geolocation_city VARCHAR(50),
    geolocation_state_code VARCHAR(10),
    geolocation_state VARCHAR(50)
);

