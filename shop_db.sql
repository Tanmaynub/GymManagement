CREATE DATABASE IF NOT EXISTS shop_db;
USE shop_db;

CREATE TABLE Product (
    product_id    INT AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(80) NOT NULL UNIQUE,
    price         DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    stock         INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
    reorder_level INT NOT NULL DEFAULT 5
);

CREATE TABLE Customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(80) NOT NULL,
    phone       VARCHAR(15) NOT NULL UNIQUE
);

CREATE TABLE Sale (
    sale_id     INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NULL,
    product_id  INT NOT NULL,
    quantity    INT NOT NULL CHECK (quantity > 0),
    unit_price  DECIMAL(10,2) NOT NULL,
    total       DECIMAL(12,2) NOT NULL,
    sale_date   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id) ON DELETE SET NULL,
    FOREIGN KEY (product_id)  REFERENCES Product(product_id)
);

INSERT INTO Product (name, price, stock, reorder_level) VALUES
 ('Basmati Rice 1kg', 120.00, 40, 10),
 ('Sugar 1kg',         48.00, 8,  10),
 ('Tea Powder 250g',  110.00, 25, 5),
 ('Soap Bar',          35.00, 3,  5);

INSERT INTO Customer (name, phone) VALUES
 ('Amit Joshi', '9822012345'),
 ('Priya More', '9890098900');