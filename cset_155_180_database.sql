CREATE DATABASE IF NOT EXISTS goods;
USE goods;

-- multi vendors on same product? double check final requirements. still have to add foreign key vendor_id from users (email)

CREATE TABLE IF NOT EXISTS cart_items (
	cart_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT,
    quantity INT,
    color VARCHAR(30),
    size VARCHAR(30),
    user_id VARCHAR(30),
    order_id INT
);
-- chat to/from
CREATE TABLE IF NOT EXISTS chats (
	chat_id INT PRIMARY KEY AUTO_INCREMENT,
	text VARCHAR(500),
	image_id INT,
    user_from VARCHAR(50),													-- customer user sending chat
    user_to VARCHAR(50),													-- vendor user replying to chat
    date_time DATETIME														-- to keep track of when chats were sent to display in proper order
); 

CREATE TABLE IF NOT EXISTS complaints ( 									-- join tables using complaint_id to get images 
	complaint_id INT PRIMARY KEY AUTO_INCREMENT,
	title VARCHAR(30),
    description VARCHAR(500),
    demand ENUM('return', 'refund', 'warranty claim'),
    status ENUM('pending', 'rejected', 'confirmed', 'processing', 'complete'),
    date DATETIME
);

CREATE TABLE IF NOT EXISTS discounts (
	discount_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT,
    discount_price INT,
    start_date DATETIME,
    end_date DATETIME
);

CREATE TABLE IF NOT EXISTS images (
	image_id INT PRIMARY KEY AUTO_INCREMENT,
	chat_id INT,															-- will contain chat_id if image belongs to chat conversation
	product_id INT,															-- will contain product_id if image belongs to product
    complaint_id INT,														-- will contain complaint_id if image belongs to customer complaint
    image LONGBLOB,
	CONSTRAINT only_one_fk CHECK (											-- forces only one foreign key per row, ensuring image will belong to only one type of entry
	(chat_id IS NOT NULL AND product_id IS NULL AND complaint_id IS NULL) OR
	(chat_id IS NULL AND product_id IS NOT NULL AND complaint_id IS NULL) OR
	(chat_id IS NULL AND product_id IS NULL AND complaint_id IS NOT NULL)
    )
);

CREATE TABLE IF NOT EXISTS orders (
	order_id INT PRIMARY KEY AUTO_INCREMENT,
    status ENUM('pending', 'rejected', 'confirmed', 'processing', 'complete'),
    order_date DATETIME,
    total INT -- decminal size setting is depreciated so we use INT and divide by 100 when displaying in UI
);

CREATE TABLE IF NOT EXISTS products (
	product_id INT PRIMARY KEY AUTO_INCREMENT,
	title VARCHAR(30),
    description VARCHAR(500),
    warranty_months INT,
    curr_inventory INT,
    price INT 																-- decminal size setting is depreciated so we use INT and divide by 100 when displaying in UI
);
-- product attributes images, colors, sizes, related vendors have own tables since multivalue attributes
CREATE TABLE IF NOT EXISTS product_colors (
	product_id INT NOT NULL,
    color VARCHAR(20)
);
CREATE TABLE IF NOT EXISTS product_sizes (
	product_id INT NOT NULL,
    size VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS product_vendors (
	product_id INT,
    vendor_id VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS reviews (
	review_id INT PRIMARY KEY AUTO_INCREMENT,
    rating INT,
    description VARCHAR(500),
    image LONGBLOB,
    date DATETIME
);

CREATE TABLE IF NOT EXISTS users (
	email VARCHAR(255) PRIMARY KEY, 										-- using email like a user id since unique
    username VARCHAR(255) NOT NULL,
    hashed_pswd VARCHAR(300) NOT NULL, 										-- hashed passwords needed more space in prev programs so using 300 instead of 255
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    type ENUM('vendor', 'admin', 'customer') NOT NULL
);

-- adding foreign keys after table creation to prevent issues with table not yet existing
ALTER TABLE images
	ADD FOREIGN KEY (product_id) REFERENCES products(product_id),
    ADD FOREIGN KEY (chat_id) REFERENCES chats(chat_id),
    ADD FOREIGN KEY (complaint_id) REFERENCES complaints(complaint_id);
ALTER TABLE product_vendors
	ADD FOREIGN KEY (product_id) REFERENCES products(product_id),
    ADD FOREIGN KEY (vendor_id) REFERENCES users(email);
ALTER TABLE discounts
	ADD FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE cart_items 
	ADD FOREIGN KEY (user_id) REFERENCES users(email),
    ADD FOREIGN KEY (order_id) REFERENCES orders(order_id);
ALTER TABLE chats
    ADD FOREIGN KEY (user_from) REFERENCES users(email),
    ADD FOREIGN KEY (user_to) REFERENCES users(email),
    ADD FOREIGN KEY (image_id) REFERENCES images(image_id);
ALTER TABLE product_sizes
	ADD FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE product_colors
	ADD FOREIGN KEY (product_id) REFERENCES products(product_id);
    
-- altering auto increment starting numbers
ALTER TABLE cart_items AUTO_INCREMENT=100;
ALTER TABLE chats AUTO_INCREMENT=2000;
ALTER TABLE complaints AUTO_INCREMENT=3500;
ALTER TABLE discounts AUTO_INCREMENT=4200;
ALTER TABLE images AUTO_INCREMENT=5000;
ALTER TABLE orders AUTO_INCREMENT=724000;
ALTER TABLE products AUTO_INCREMENT=850555;
ALTER TABLE reviews AUTO_INCREMENT=945450;

-- data needed: 2 admin accounts, 5 customer accounts, 3 vendor accounts
-- 10 products from the 3 vendors, untimed discount on 2 products,
-- timed discount on 2 products, items in cart from 3 customer accounts,
-- at least 7 orders of various statuses and 3 shipped orders from 3 customers
-- orders should have multiple products from different vendors
-- meaningful reviews with images from customers on all shipped orders
-- one return and one warranty application in progress
-- meaningful chat messages regarding these requests
-- meaningful chat messages from all customers to different vendors
-- any additional information necessary to model a running ecommerce website

SELECT * FROM cart_items;
SELECT * FROM chats;
SELECT * FROM complaints;
SELECT * FROM discounts;
SELECT * FROM images;
SELECT * FROM orders;
SELECT * FROM product_colors;
SELECT * FROM product_sizes;
SELECT * FROM product_vendors;
SELECT * FROM products;
SELECT * FROM reviews;
SELECT * FROM users;

-- 2 admin, 5 customers, 3 vendors
INSERT INTO users (email, username, hashed_pswd, first_name, last_name, type)
	VALUES  ('d_daedalus_admin@goods.com', 'dd_admin', '$+&2q9e~*$1+JR=G_#K$8`!_/k~9?3#oEJ/`dLe*D$5?_GR#kPEk2JK2;kdE8#$2mmd/=G5#EK0dR=$3RG18L20J0~q;Q`#2`0~=e@Gq_`2@+JRDQ5i/3~*;L`95&@mq/D=1`ei&D*~kQKdKR1d+$k2R!5m2_RQo_L=KQ5@J$=@93R~2i`;#J`1J8Km`#*`D@11qq_o/&Q`+e`&3?`EDio9?*K55iL82Pm`;&o1/GJi@_mo/DQ', 'Daedalus', 'Dzidzic', 'admin'), -- admin
			('m_malova_admin@goods.com', 'mm_admin', '$+&2q9e~*$1+JR=G_#K$8`!_/k~9?3#oEJ/`dLe*D$5?_GR#kPEk2JK2;kdE8#$2mmd/=G5#EK0dR=$3RG18L20J0~q;Q`#2`0~=e@Gq_`2@+JRDQ5i/3~*;L`95&@mq/D=1`ei&D*~kQKdKR1d+$k2R!5m2_RQo_L=KQ5@J$=@93R~2i`;#J`1J8Km`#*`D@11qq_o/&Q`+e`&3?`EDio9?*K55iL82Pm`;&o1/GJi@_mo/DQ', 'Maya', 'Malova', 'admin'), -- admin
			('s_teller@gmail.com', 'steller', '$+&2q9e~*$1+JR=G_#K$8`!_/k~9?3#oEJ/`dLe*D$5?_GR#kPEk2JK2;kdE8#$2mmd/=G5#EK0dR=$3RG18L20J0~q;Q`#2`0~=e@Gq_`2@+JRDQ5i/3~*;L`95&@mq/D=1`ei&D*~kQKdKR1d+$k2R!5m2_RQo_L=KQ5@J$=@93R~2i`;#J`1J8Km`#*`D@11qq_o/&Q`+e`&3?`EDio9?*K55iL82Pm`;&o1/GJi@_mo/DQ', 'Simpson', 'Teller', 'customer'), -- customer
			('s_petocs@gmail.com', 'spetocs', '$+&2q9e~*$1+JR=G_#K$8`!_/k~9?3#oEJ/`dLe*D$5?_GR#kPEk2JK2;kdE8#$2mmd/=G5#EK0dR=$3RG18L20J0~q;Q`#2`0~=e@Gq_`2@+JRDQ5i/3~*;L`95&@mq/D=1`ei&D*~kQKdKR1d+$k2R!5m2_RQo_L=KQ5@J$=@93R~2i`;#J`1J8Km`#*`D@11qq_o/&Q`+e`&3?`EDio9?*K55iL82Pm`;&o1/GJi@_mo/DQ', 'Sajay', 'Petocs', 'customer'), -- customer
			('d_giant@outlook.com', 'dgiant', '$+&2q9e~*$1+JR=G_#K$8`!_/k~9?3#oEJ/`dLe*D$5?_GR#kPEk2JK2;kdE8#$2mmd/=G5#EK0dR=$3RG18L20J0~q;Q`#2`0~=e@Gq_`2@+JRDQ5i/3~*;L`95&@mq/D=1`ei&D*~kQKdKR1d+$k2R!5m2_RQo_L=KQ5@J$=@93R~2i`;#J`1J8Km`#*`D@11qq_o/&Q`+e`&3?`EDio9?*K55iL82Pm`;&o1/GJi@_mo/DQ', 'Damien', 'Giant', 'customer'), -- customer
			('c_ramos@outlook.com', 'cramos', '$+&2q9e~*$1+JR=G_#K$8`!_/k~9?3#oEJ/`dLe*D$5?_GR#kPEk2JK2;kdE8#$2mmd/=G5#EK0dR=$3RG18L20J0~q;Q`#2`0~=e@Gq_`2@+JRDQ5i/3~*;L`95&@mq/D=1`ei&D*~kQKdKR1d+$k2R!5m2_RQo_L=KQ5@J$=@93R~2i`;#J`1J8Km`#*`D@11qq_o/&Q`+e`&3?`EDio9?*K55iL82Pm`;&o1/GJi@_mo/DQ', 'Celia', 'Ramos', 'customer'), -- customer
			('j_prescott@gmail.com', 'jprescott', '$+&2q9e~*$1+JR=G_#K$8`!_/k~9?3#oEJ/`dLe*D$5?_GR#kPEk2JK2;kdE8#$2mmd/=G5#EK0dR=$3RG18L20J0~q;Q`#2`0~=e@Gq_`2@+JRDQ5i/3~*;L`95&@mq/D=1`ei&D*~kQKdKR1d+$k2R!5m2_RQo_L=KQ5@J$=@93R~2i`;#J`1J8Km`#*`D@11qq_o/&Q`+e`&3?`EDio9?*K55iL82Pm`;&o1/GJi@_mo/DQ', 'Jean', 'Prescott', 'customer'), -- customer
			('a_batts@simplescience.org', 'abatts_vendor', '$+&2q9e~*$1+JR=G_#K$8`!_/k~9?3#oEJ/`dLe*D$5?_GR#kPEk2JK2;kdE8#$2mmd/=G5#EK0dR=$3RG18L20J0~q;Q`#2`0~=e@Gq_`2@+JRDQ5i/3~*;L`95&@mq/D=1`ei&D*~kQKdKR1d+$k2R!5m2_RQo_L=KQ5@J$=@93R~2i`;#J`1J8Km`#*`D@11qq_o/&Q`+e`&3?`EDio9?*K55iL82Pm`;&o1/GJi@_mo/DQ', 'Annemarie', 'Batts', 'vendor'), -- vendor
			('g_pitts@supplies4school.org', 'gpitts_vendor', '$+&2q9e~*$1+JR=G_#K$8`!_/k~9?3#oEJ/`dLe*D$5?_GR#kPEk2JK2;kdE8#$2mmd/=G5#EK0dR=$3RG18L20J0~q;Q`#2`0~=e@Gq_`2@+JRDQ5i/3~*;L`95&@mq/D=1`ei&D*~kQKdKR1d+$k2R!5m2_RQo_L=KQ5@J$=@93R~2i`;#J`1J8Km`#*`D@11qq_o/&Q`+e`&3?`EDio9?*K55iL82Pm`;&o1/GJi@_mo/DQ', 'Gebhard', 'Pitts', 'vendor'), -- vendor
			('i_tombolli@study_space.com', 'itombolli_vendor', '$+&2q9e~*$1+JR=G_#K$8`!_/k~9?3#oEJ/`dLe*D$5?_GR#kPEk2JK2;kdE8#$2mmd/=G5#EK0dR=$3RG18L20J0~q;Q`#2`0~=e@Gq_`2@+JRDQ5i/3~*;L`95&@mq/D=1`ei&D*~kQKdKR1d+$k2R!5m2_RQo_L=KQ5@J$=@93R~2i`;#J`1J8Km`#*`D@11qq_o/&Q`+e`&3?`EDio9?*K55iL82Pm`;&o1/GJi@_mo/DQ', 'Isabella', 'Tomboli', 'vendor'); -- vendor
    
-- 10 products from the 3 vendors
INSERT INTO products (title, description, warranty_months, curr_inventory, price)
	VALUES ()

DROP DATABASE goods;