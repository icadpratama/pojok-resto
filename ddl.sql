-- Step 1: Core Setup Tables (No Foreign Keys)
CREATE TABLE categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(30) UNIQUE NOT NULL
);
CREATE TABLE order_statuses (
  status_id INT AUTO_INCREMENT PRIMARY KEY,
  status_name VARCHAR(20) NOT NULL
);
CREATE TABLE tax_rates (
  tax_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL,
  rate DECIMAL(5, 2) NOT NULL CHECK (rate >= 0),
  effective_date DATE
);
CREATE TABLE storage_locations (
  location_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(30) NOT NULL,
  description TEXT
);
CREATE TABLE suppliers (
  supplier_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  contact VARCHAR(20),
  email VARCHAR(100) UNIQUE,
  address TEXT
);
-- Step 2: Primary Entity Tables (Referencing Core Setup)
CREATE TABLE menu_items (
  item_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL,
  category_id INT,
  description TEXT,
  available_status BOOLEAN DEFAULT TRUE,
  preparation_time INT,
  is_customizable BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (category_id) REFERENCES categories(category_id)
);
CREATE TABLE ingredients (
  ingredient_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL,
  stock INT NOT NULL,
  unit VARCHAR(10) NOT NULL,
  expiration_date DATE,
  reorder_level INT DEFAULT 50,
  supplier_id INT,
  storage_location_id INT,
  cost_per_unit DECIMAL(15, 0),
  FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id),
  FOREIGN KEY (storage_location_id) REFERENCES storage_locations(location_id)
);
-- Step 3: Supporting Tables
CREATE TABLE item_prices (
  price_id INT AUTO_INCREMENT PRIMARY KEY,
  item_id INT,
  price DECIMAL(15, 0) NOT NULL,
  cost_price DECIMAL(15, 0),
  currency VARCHAR(3) DEFAULT 'IDR',
  start_date DATE,
  end_date DATE,
  FOREIGN KEY (item_id) REFERENCES menu_items(item_id)
);
CREATE TABLE modifiers (
  modifier_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL,
  description TEXT
);
CREATE TABLE modifier_prices (
  price_id INT AUTO_INCREMENT PRIMARY KEY,
  modifier_id INT,
  additional_cost DECIMAL(15, 0) DEFAULT 0,
  start_date DATE,
  end_date DATE,
  FOREIGN KEY (modifier_id) REFERENCES modifiers(modifier_id)
);
CREATE TABLE item_modifiers (
  item_modifier_id INT AUTO_INCREMENT PRIMARY KEY,
  item_id INT,
  modifier_id INT,
  FOREIGN KEY (item_id) REFERENCES menu_items(item_id),
  FOREIGN KEY (modifier_id) REFERENCES modifiers(modifier_id),
  UNIQUE (item_id, modifier_id)
);
-- Step 4: Employee, Customer, and Table Management
CREATE TABLE customers (
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50),
  contact_number VARCHAR(20),
  email VARCHAR(100),
  created_at DATE,
  loyalty_points INT DEFAULT 0,
  loyalty_level VARCHAR(20)
);
CREATE TABLE employees (
  employee_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL,
  role VARCHAR(20) NOT NULL,
  email VARCHAR(100),
  phone_number VARCHAR(20),
  join_date DATE
);
CREATE TABLE tables (
  table_id INT AUTO_INCREMENT PRIMARY KEY,
  number INT NOT NULL,
  seating_capacity INT,
  location_description VARCHAR(100),
  status ENUM('Available', 'Occupied', 'Reserved') DEFAULT 'Available',
  parent_table_id INT,
  FOREIGN KEY (parent_table_id) REFERENCES tables(table_id)
);
-- Step 5: Order and Order Details
CREATE TABLE orders (
  order_id INT AUTO_INCREMENT PRIMARY KEY,
  order_date DATE NOT NULL,
  order_time TIME NOT NULL,
  employee_id INT,
  customer_id INT,
  table_id INT,
  current_table_id INT,
  order_type ENUM('Dine-In', 'Takeout', 'Delivery') NOT NULL,
  order_status_id INT DEFAULT 1,
  discount DECIMAL(15, 0) DEFAULT 0,
  tax_id INT,
  payment_method VARCHAR(20) NOT NULL,
  FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  FOREIGN KEY (table_id) REFERENCES tables(table_id),
  FOREIGN KEY (current_table_id) REFERENCES tables(table_id),
  FOREIGN KEY (order_status_id) REFERENCES order_statuses(status_id),
  FOREIGN KEY (tax_id) REFERENCES tax_rates(tax_id)
);
CREATE TABLE order_details (
  order_detail_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT,
  item_id INT,
  quantity INT NOT NULL CHECK (quantity > 0),
  special_instructions TEXT,
  total_price DECIMAL(15, 0) NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(order_id),
  FOREIGN KEY (item_id) REFERENCES menu_items(item_id)
);
CREATE TABLE order_modifiers (
  order_detail_id INT,
  modifier_id INT,
  PRIMARY KEY (order_detail_id, modifier_id),
  FOREIGN KEY (order_detail_id) REFERENCES order_details(order_detail_id),
  FOREIGN KEY (modifier_id) REFERENCES modifiers(modifier_id)
);
-- Step 6: Inventory and Recipe Tracking
CREATE TABLE recipes (
  recipe_id INT AUTO_INCREMENT PRIMARY KEY,
  item_id INT,
  ingredient_id INT,
  quantity_used INT NOT NULL,
  FOREIGN KEY (item_id) REFERENCES menu_items(item_id),
  FOREIGN KEY (ingredient_id) REFERENCES ingredients(ingredient_id)
);
CREATE TABLE stock_adjustments (
  adjustment_id INT AUTO_INCREMENT PRIMARY KEY,
  ingredient_id INT NOT NULL,
  adjustment_type ENUM('Restock', 'Waste', 'Other') NOT NULL,
  quantity_adjusted INT NOT NULL,
  adjustment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  notes TEXT,
  FOREIGN KEY (ingredient_id) REFERENCES ingredients(ingredient_id)
);
CREATE TABLE usage_history (
  usage_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT,
  ingredient_id INT,
  quantity_used INT NOT NULL,
  usage_date DATE NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(order_id),
  FOREIGN KEY (ingredient_id) REFERENCES ingredients(ingredient_id)
);
-- Step 7: Table Operations and Reservation Management
CREATE TABLE table_operations_log (
  operation_id INT AUTO_INCREMENT PRIMARY KEY,
  operation_type ENUM('Split', 'Merge', 'Transfer') NOT NULL,
  source_table_id INT NOT NULL,
  target_table_id INT,
  order_id INT,
  operation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (source_table_id) REFERENCES tables(table_id),
  FOREIGN KEY (target_table_id) REFERENCES tables(table_id),
  FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
CREATE TABLE table_merge_history (
  merge_id INT AUTO_INCREMENT PRIMARY KEY,
  active_table_id INT NOT NULL,
  merged_table_id INT NOT NULL,
  merge_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (active_table_id) REFERENCES tables(table_id),
  FOREIGN KEY (merged_table_id) REFERENCES tables(table_id)
);
CREATE TABLE table_split_history (
  split_id INT AUTO_INCREMENT PRIMARY KEY,
  original_table_id INT NOT NULL,
  resulting_table_id INT NOT NULL,
  split_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (original_table_id) REFERENCES tables(table_id),
  FOREIGN KEY (resulting_table_id) REFERENCES tables(table_id)
);
CREATE TABLE reservations (
  reservation_id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT,
  table_id INT,
  reservation_date DATE NOT NULL,
  reservation_time TIME NOT NULL,
  status ENUM('Pending', 'Confirmed', 'Cancelled') DEFAULT 'Pending',
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  FOREIGN KEY (table_id) REFERENCES tables(table_id)
);
-- Step 8: Quick Sales
CREATE TABLE quick_sales (
  sale_id INT AUTO_INCREMENT PRIMARY KEY,
  total_amount DECIMAL(15, 0) NOT NULL,
  sale_date DATE,
  sale_time TIME
);
-- Step 9: Indexes for Performance
CREATE INDEX idx_order_date ON orders(order_date);
CREATE INDEX idx_order_status_id ON orders(order_status_id);
CREATE INDEX idx_item_id ON recipes(item_id);
CREATE INDEX idx_order_id ON usage_history(order_id);
-- Adding suggested indexes for improved performance
CREATE INDEX idx_reservation_date ON reservations(reservation_date);
CREATE INDEX idx_stock_adjustments_ingredient ON stock_adjustments(ingredient_id);
CREATE INDEX idx_sale_date ON quick_sales(sale_date);
CREATE INDEX idx_orders_customer ON orders(customer_id);
-- Adding unique constraints to ensure data integrity
ALTER TABLE item_prices
ADD CONSTRAINT uq_item_price_start UNIQUE (item_id, start_date);
ALTER TABLE modifier_prices
ADD CONSTRAINT uq_modifier_price_start UNIQUE (modifier_id, start_date);
ALTER TABLE recipes
ADD CONSTRAINT uq_recipe_item_ingredient UNIQUE (item_id, ingredient_id);
-- Relationships Between Tables:
-- 1. `categories` and `menu_items`: Each menu item in `menu_items` belongs to one category in `categories`.
--    Each category can have multiple items.
-- 2. `menu_items` and `item_prices`: Each menu item can have multiple price records over time in `item_prices`,
--    allowing for price adjustments.
-- 3. `menu_items` and `modifiers` through `item_modifiers`: Each menu item can have multiple modifiers (e.g., size, extra toppings),
--    and each modifier can apply to multiple items. `item_modifiers` serves as a junction table for this many-to-many relationship.
-- 4. `modifiers` and `modifier_prices`: Each modifier can have multiple price records in `modifier_prices`, 
--    allowing for price changes over time.
-- 5. `suppliers` and `ingredients`: Each ingredient in `ingredients` can be supplied by a supplier in `suppliers`.
-- 6. `storage_locations` and `ingredients`: Each ingredient can be stored in a specific location tracked in `storage_locations`.
-- 7. `ingredients` and `recipes`: Each menu item has a recipe that details the required ingredients and quantities 
--    in `recipes`, linking `menu_items` and `ingredients`.
-- 8. `tables` and `table_operations_log`: Operations like split, merge, and transfer on tables are logged in `table_operations_log`,
--    with `source_table_id` and `target_table_id` referring to tables involved in the operation.
-- 9. `tables` and `table_merge_history`: Tracks tables that have been merged, linking the merged table to the active table.
-- 10. `tables` and `table_split_history`: Logs tables that were split, recording the original table and the resulting tables.
-- 11. `order_statuses` and `orders`: Each order has a status (e.g., Pending, Completed) from the `order_statuses` table,
--     allowing for order tracking.
-- 12. `tax_rates` and `orders`: Each order may have an applicable tax rate referenced from the `tax_rates` table.
-- 13. `customers` and `orders`: Each order in `orders` can be associated with a customer in `customers`, 
--     useful for customer tracking and loyalty.
-- 14. `employees` and `orders`: Each order is handled by an employee in `employees`, allowing tracking of which employee served an order.
-- 15. `orders` and `order_details`: Each order in `orders` has associated items listed in `order_details`, 
--     detailing item quantity and price.
-- 16. `order_details` and `order_modifiers`: Each item in an order can have one or more modifiers (e.g., extra toppings)
--     from `modifiers`, tracked in `order_modifiers`.
-- 17. `orders` and `usage_history`: Ingredient usage per order is tracked in `usage_history`, linking `orders` with ingredients used.
-- 18. `tables` and `reservations`: Reservations for tables are recorded in `reservations`, tracking customer bookings and table status.
-- 19. `quick_sales`: This table records rapid transactions, useful for street vendors and other quick sales cases, 
--     independent of other detailed order tables.