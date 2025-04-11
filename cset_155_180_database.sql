CREATE DATABASE IF NOT EXISTS goods;
USE goods;

-- ----------------------- --
-- CREATE TABLE STATEMENTS --
-- ----------------------- --

CREATE TABLE IF NOT EXISTS users (
	email VARCHAR(255) PRIMARY KEY, 										-- using email like a user id since unique
    username VARCHAR(255) NOT NULL UNIQUE,
    hashed_pswd VARCHAR(300) NOT NULL, 										-- hashed passwords needed more space in prev programs so using 300 instead of 255
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    type ENUM('vendor', 'admin', 'customer') NOT NULL
);
-- select * from order_items natural join colors natural join sizes natural join product_variants natural join products;
-- products
CREATE TABLE IF NOT EXISTS products (					
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    vendor_id VARCHAR(255) NOT NULL,
    product_title VARCHAR(255) NOT NULL,
    product_description VARCHAR(500),
    warranty_months INT,
    FOREIGN KEY (vendor_id) REFERENCES users(email)
);
CREATE TABLE IF NOT EXISTS colors (						-- product colors
    color_id INT PRIMARY KEY AUTO_INCREMENT,
    color_name VARCHAR(50) UNIQUE NOT NULL
);
CREATE TABLE IF NOT EXISTS sizes(						-- product sizes
    size_id INT PRIMARY KEY AUTO_INCREMENT,
    size_description VARCHAR(100) UNIQUE NOT NULL
);
CREATE TABLE IF NOT EXISTS product_variants (			-- product variants with each color / size / price combos
    variant_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    color_id INT,
    size_id INT,
    price INT NOT NULL,
    current_inventory INT NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (color_id) REFERENCES colors(color_id),
    FOREIGN KEY (size_id) REFERENCES sizes(size_id),
    UNIQUE(product_id, color_id, size_id) 				-- ensures no duplicate combos
);

-- images
CREATE TABLE IF NOT EXISTS images (						-- product, complaint, and review images
    image_id INT PRIMARY KEY AUTO_INCREMENT,
    variant_id INT NOT NULL,												-- will contain variant_id if image belongs to product
	chat_id INT,															-- will contain chat_id if image belongs to chat conversation															
    complaint_id INT,														-- will contain complaint_id if image belongs to customer complaint
    file_path VARCHAR(500) NOT NULL,  										-- path or URL to the image file
    alt_text VARCHAR(255),            										-- image description / alt text
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id),
	CONSTRAINT only_one_fk CHECK (											-- forces only one foreign key per row, ensuring image will belong to only one type of entry
	(chat_id IS NOT NULL AND variant_id IS NULL AND complaint_id IS NULL) OR
	(chat_id IS NULL AND variant_id IS NOT NULL AND complaint_id IS NULL) OR
	(chat_id IS NULL AND variant_id IS NULL AND complaint_id IS NOT NULL)
    )
);

-- cart
CREATE TABLE IF NOT EXISTS carts (
    cart_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_email VARCHAR(255) NOT NULL UNIQUE,								-- forces one cart per user
    FOREIGN KEY (customer_email) REFERENCES users(email)
);
CREATE TABLE IF NOT EXISTS cart_items (
    cart_item_id INT PRIMARY KEY AUTO_INCREMENT,
    cart_id INT NOT NULL,														-- references user's cart
    variant_id INT NOT NULL,													-- product
    quantity INT NOT NULL,														-- product quantity
    FOREIGN KEY (cart_id) REFERENCES carts(cart_id),
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id),
    UNIQUE (cart_id, variant_id) -- ensures each variant only appears once per cart, can increase quantity in cart instead
);

-- orders
CREATE TABLE IF NOT EXISTS orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,		
    customer_email VARCHAR(255) NOT NULL,	
    status ENUM('pending', 'rejected', 'confirmed', 'processing', 'complete') NOT NULL DEFAULT 'pending',
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    total_price INT NOT NULL,													 -- in cents
    FOREIGN KEY (customer_email) REFERENCES users(email)
);
CREATE TABLE IF NOT EXISTS order_items (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,														-- references user's order
    variant_id INT NOT NULL,
    quantity INT NOT NULL,
    price_at_order_time INT NOT NULL, 											-- copy of the product_variant.price at time of order
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id)
);

-- complaints
CREATE TABLE IF NOT EXISTS complaints ( 									-- join tables using complaint_id to get images 
	complaint_id INT PRIMARY KEY AUTO_INCREMENT,
	title VARCHAR(30),
    description VARCHAR(500),
    demand ENUM('return', 'refund', 'warranty claim'),
    status ENUM('pending', 'rejected', 'confirmed', 'processing', 'complete') NOT NULL,
    date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- chats
CREATE TABLE IF NOT EXISTS chats (
	chat_id INT PRIMARY KEY AUTO_INCREMENT,
	text VARCHAR(500),
	image_id INT,
    user_from VARCHAR(50),													-- customer user sending chat
    user_to VARCHAR(50),													-- vendor user replying to chat
    date_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,							-- to keep track of when chats were sent to display in proper order
    FOREIGN KEY (user_from) REFERENCES users(email),
    FOREIGN KEY (user_to) REFERENCES users(email),
    FOREIGN KEY (image_id) REFERENCES images(image_id)
); 

-- reviews
CREATE TABLE IF NOT EXISTS reviews (
	review_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_email VARCHAR(255),
    rating INT NOT NULL,
    description VARCHAR(500),
    image VARCHAR(255),
    date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_email) REFERENCES users(email)
);

-- discounts
CREATE TABLE IF NOT EXISTS discounts (
	discount_id INT PRIMARY KEY AUTO_INCREMENT,
    variant_id INT,
    discount_price INT,
    start_date DATETIME,
    end_date DATETIME,
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id)
);


-- ---------------------- --
-- ALTER TABLE STATEMENTS --
-- ---------------------- --

-- setting auto increment start values so id's have variety 
ALTER TABLE products AUTO_INCREMENT=850555;
ALTER TABLE colors AUTO_INCREMENT=19780;
ALTER TABLE sizes AUTO_INCREMENT=15;
ALTER TABLE product_variants AUTO_INCREMENT=100200;

-- ----------------- --
-- INSERT STATEMENTS --
-- ----------------- --

-- data needed: 2 admin accounts, 5 customer accounts, 3 vendor accounts **DONE**
-- 10 products from the 3 vendors **DONE**
-- untimed discount on 2 products **DONE**
-- timed discount on 2 products **DONE**
-- items in cart from 3 customer accounts **DONE**
-- at least 7 orders of various statuses and 3 shipped orders from 3 customers **DONE**
-- orders should have multiple products from different vendors **DONE**
-- meaningful reviews with images from customers on all shipped orders
-- one return and one warranty application in progress
-- meaningful chat messages regarding these requests
-- meaningful chat messages from all customers to different vendors
-- any additional information necessary to model a running ecommerce website

INSERT INTO users (email, username, hashed_pswd, first_name, last_name, type)
VALUES
	('d_daedalus_admin@goods.com', 'dd_admin', '$+&2q9e~*$1+JR=G_#K$8`!_/k~9?3#oEJ/`dLe*D$5?_GR#kPEk2JK2;kdE8#$2mmd/=G5#EK0dR=$3RG18L20J0~q;Q`#2`0~=e@Gq_`2@+JRDQ5i/3~*;L`95&@mq/D=1`ei&D*~kQKdKR1d+$k2R!5m2_RQo_L=KQ5@J$=@93R~2i`;#J`1J8Km`#*`D@11qq_o/&Q`+e`&3?`EDio9?*K55iL82Pm`;&o1/GJi@_mo/DQ', 'Daedalus', 'Dzidzic', 'admin'), -- admin
	('m_malova_admin@goods.com', 'mm_admin', '$+&2q9e~*$1+JR=G_#K$8`!_/k~9?3#oEJ/`dLe*D$5?_GR#kPEk2JK2;kdE8#$2mmd/=G5#EK0dR=$3RG18L20J0~q;Q`#2`0~=e@Gq_`2@+JRDQ5i/3~*;L`95&@mq/D=1`ei&D*~kQKdKR1d+$k2R!5m2_RQo_L=KQ5@J$=@93R~2i`;#J`1J8Km`#*`D@11qq_o/&Q`+e`&3?`EDio9?*K55iL82Pm`;&o1/GJi@_mo/DQ', 'Maya', 'Malova', 'admin'), -- admin
	('s_teller@gmail.com', 'steller', '$+&2q9e~*$1+JR=G_#K$8`!_/k~9?3#oEJ/`dLe*D$5?_GR#kPEk2JK2;kdE8#$2mmd/=G5#EK0dR=$3RG18L20J0~q;Q`#2`0~=e@Gq_`2@+JRDQ5i/3~*;L`95&@mq/D=1`ei&D*~kQKdKR1d+$k2R!5m2_RQo_L=KQ5@J$=@93R~2i`;#J`1J8Km`#*`D@11qq_o/&Q`+e`&3?`EDio9?*K55iL82Pm`;&o1/GJi@_mo/DQ', 'Simpson', 'Teller', 'customer'), -- customer
	('s_petocs@gmail.com', 'spetocs', '$+&2q9e~*$1+JR=G_#K$8`!_/k~9?3#oEJ/`dLe*D$5?_GR#kPEk2JK2;kdE8#$2mmd/=G5#EK0dR=$3RG18L20J0~q;Q`#2`0~=e@Gq_`2@+JRDQ5i/3~*;L`95&@mq/D=1`ei&D*~kQKdKR1d+$k2R!5m2_RQo_L=KQ5@J$=@93R~2i`;#J`1J8Km`#*`D@11qq_o/&Q`+e`&3?`EDio9?*K55iL82Pm`;&o1/GJi@_mo/DQ', 'Sajay', 'Petocs', 'customer'), -- customer
	('d_giant@outlook.com', 'dgiant', '$+&2q9e~*$1+JR=G_#K$8`!_/k~9?3#oEJ/`dLe*D$5?_GR#kPEk2JK2;kdE8#$2mmd/=G5#EK0dR=$3RG18L20J0~q;Q`#2`0~=e@Gq_`2@+JRDQ5i/3~*;L`95&@mq/D=1`ei&D*~kQKdKR1d+$k2R!5m2_RQo_L=KQ5@J$=@93R~2i`;#J`1J8Km`#*`D@11qq_o/&Q`+e`&3?`EDio9?*K55iL82Pm`;&o1/GJi@_mo/DQ', 'Damien', 'Giant', 'customer'), -- customer
	('c_ramos@outlook.com', 'cramos', '$+&2q9e~*$1+JR=G_#K$8`!_/k~9?3#oEJ/`dLe*D$5?_GR#kPEk2JK2;kdE8#$2mmd/=G5#EK0dR=$3RG18L20J0~q;Q`#2`0~=e@Gq_`2@+JRDQ5i/3~*;L`95&@mq/D=1`ei&D*~kQKdKR1d+$k2R!5m2_RQo_L=KQ5@J$=@93R~2i`;#J`1J8Km`#*`D@11qq_o/&Q`+e`&3?`EDio9?*K55iL82Pm`;&o1/GJi@_mo/DQ', 'Celia', 'Ramos', 'customer'), -- customer
	('j_prescott@gmail.com', 'jprescott', '$+&2q9e~*$1+JR=G_#K$8`!_/k~9?3#oEJ/`dLe*D$5?_GR#kPEk2JK2;kdE8#$2mmd/=G5#EK0dR=$3RG18L20J0~q;Q`#2`0~=e@Gq_`2@+JRDQ5i/3~*;L`95&@mq/D=1`ei&D*~kQKdKR1d+$k2R!5m2_RQo_L=KQ5@J$=@93R~2i`;#J`1J8Km`#*`D@11qq_o/&Q`+e`&3?`EDio9?*K55iL82Pm`;&o1/GJi@_mo/DQ', 'Jean', 'Prescott', 'customer'), -- customer
	('a_batts@simplescience.org', 'abatts_vendor', '$+&2q9e~*$1+JR=G_#K$8`!_/k~9?3#oEJ/`dLe*D$5?_GR#kPEk2JK2;kdE8#$2mmd/=G5#EK0dR=$3RG18L20J0~q;Q`#2`0~=e@Gq_`2@+JRDQ5i/3~*;L`95&@mq/D=1`ei&D*~kQKdKR1d+$k2R!5m2_RQo_L=KQ5@J$=@93R~2i`;#J`1J8Km`#*`D@11qq_o/&Q`+e`&3?`EDio9?*K55iL82Pm`;&o1/GJi@_mo/DQ', 'Annemarie', 'Batts', 'vendor'), -- vendor
	('g_pitts@supplies4school.org', 'gpitts_vendor', '$+&2q9e~*$1+JR=G_#K$8`!_/k~9?3#oEJ/`dLe*D$5?_GR#kPEk2JK2;kdE8#$2mmd/=G5#EK0dR=$3RG18L20J0~q;Q`#2`0~=e@Gq_`2@+JRDQ5i/3~*;L`95&@mq/D=1`ei&D*~kQKdKR1d+$k2R!5m2_RQo_L=KQ5@J$=@93R~2i`;#J`1J8Km`#*`D@11qq_o/&Q`+e`&3?`EDio9?*K55iL82Pm`;&o1/GJi@_mo/DQ', 'Gebhard', 'Pitts', 'vendor'), -- vendor
	('i_tombolli@study_space.com', 'itombolli_vendor', '$+&2q9e~*$1+JR=G_#K$8`!_/k~9?3#oEJ/`dLe*D$5?_GR#kPEk2JK2;kdE8#$2mmd/=G5#EK0dR=$3RG18L20J0~q;Q`#2`0~=e@Gq_`2@+JRDQ5i/3~*;L`95&@mq/D=1`ei&D*~kQKdKR1d+$k2R!5m2_RQo_L=KQ5@J$=@93R~2i`;#J`1J8Km`#*`D@11qq_o/&Q`+e`&3?`EDio9?*K55iL82Pm`;&o1/GJi@_mo/DQ', 'Isabella', 'Tomboli', 'vendor'); -- vendor

INSERT INTO products (vendor_id, product_title, product_description, warranty_months)
VALUES
	-- 850555
	('g_pitts@supplies4school.org', 'BIC Xtra-Smooth Mechanical Pencils', 'BIC Xtra-Smooth Mechanical Pencils offer smooth, dark writing with a 0.7mm medium point. Each pencil comes with three pieces of No. 2 lead that doesn’t smudge and erases cleanly, making them ideal for standardized tests.', 0),
	-- 850556
    ('g_pitts@supplies4school.org', 'APEX Spiral Notebook', 'APEX Spiral Notebooks feature 70 wide-ruled sheets, 1 subject, with 3-hole perforated sheets. Available as single notebook or in multi-packs.', 0),
	-- 850557
	('a_batts@simplescience.org', 'Chemistry in Context', '"Applying Chemistry to Society." First edition textbook, new.', 0),
	-- 850558
    ('a_batts@simplescience.org', 'The Language of Composition', '2nd edition textbook. Authors: Renee H. Shea, Lawrence Scanlon, and Robin Dissin Aufses.', 0),
    -- 850559
	('a_batts@simplescience.org', 'Advanced Pysics', '2nd edition textbook. Authors: Steve Adams and Jonathan Allday.', 0),
    -- 850560
    ('a_batts@simplescience.org', 'Precalculus', '"A Graphing Approach. First edition textbook, used. Teacher\'s Edition"', 0),
    -- 850561
    ('i_tombolli@study_space.com', 'Metro Adjustable Height Desk - 60 x 30"', 'Simple-to-use push-button control with 4 programmable heights. Powered by quiet electric motors. 9\' power cord.', 12),
	-- 850562
    ('i_tombolli@study_space.com', 'Metro L-Desk with Adjustable Height - 72 x 78.', 'Simple-to-use push-button control with 4 programmable heights. Powered by 2 quiet electric motors. 9\' power cord.', 12),
	-- 850563
    ('i_tombolli@study_space.com', 'Mesh Task Chair', 'Hi-tech design with ventilated mesh fabric - keeps you cool an comfortable. 3 1/2" thick seat. Standard tilt with adjustable tension. Fixed armrests.', 6),
	-- 850564
    ('i_tombolli@study_space.com', 'Anti-Static Carpet Chair Mat', 'Anti-skid surface and straight edges. Vinyl construction. Cleared backing keeps chair mat firmly in place. Use on low pile carpeting - 3/8" thick or less.', 0);

INSERT INTO colors (color_name)
VALUES
	('Assorted'),	-- 19780
    ('Red'),		-- 19781
    ('Blue'),		-- 19782
    ('Green'),		-- 19783
    ('Yellow'),		-- 19784
    ('Navy'),		-- 19785
    ('Black'),		-- 19786
	('Walnut'),		-- 19787
    ('Clear'),		-- 19788
    ('None');		-- 19789
    
INSERT INTO sizes (size_description)
VALUES
	('Single'), 			-- 15
	('6-Pack'), 			-- 16
	('10-Pack'), 			-- 17
    ('12-Pack'), 			-- 18
	('24-Pack'), 			-- 19
	('48-Pack'), 			-- 20
    ('60-Pack'), 			-- 21
    ('60L X 30W Inches'),	-- 22
    ('72L X 78W Inches'),	-- 23
    ('36L X 48W Inches'),	-- 24
    ('45L X 53W Inches'),	-- 25
    ('20W X 19D X 18-22H Inches'), -- 26
    ('Standard');			-- 27

INSERT INTO product_variants (product_id, color_id, size_id, price, current_inventory)
VALUES
	-- Mechanical Pencils
	(850555, 19780, 17, 474, 150),  -- 10 Count Pack
	(850555, 19780, 20, 2274, 50), 	-- 48 Count Pack
    (850555, 19780, 21, 2649, 18), 	-- 60 Count Pack
    -- Single Notebooks
	(850556, 19781, 15, 299, 100),  -- Red Single Notebook - $2.99
	(850556, 19782, 15, 299, 100),  -- Blue Single Notebook - $2.99
	(850556, 19783, 15, 299, 100),  -- Green Single Notebook - $2.99
	(850556, 19784, 15, 299, 100),  -- Yellow Single Notebook - $2.99
	(850556, 19785, 15, 299, 100),  -- Navy Single Notebook - $2.99
	(850556, 19786, 15, 299, 100),  -- Black Single Notebook - $2.99
	-- 6-Pack Notebooks Assortment
	(850556, 19780, 16, 1599, 50),  -- Assorted Colors 6-Pack - $15.99
	-- 12-Pack Notebooks Assortment
	(850556, 19780, 18, 2999, 25),  -- Assorted Colors 12-Pack - $29.99
    
    -- Chem textbook
    (850557, 19789, 27, 42999, 16),
    -- Comp textbook
    (850558, 19789, 27, 34999, 11),
    -- Phys textbook
    (850559, 19789, 27, 36949, 21),
    -- Precalc textbook
    (850560, 19789, 27, 39500, 9),
    
    -- Adjustable height desk
    (850561, 19787, 22, 95000, 9),
    -- Adjustable height L-shaped desk
    (850562, 19787, 23, 144900, 7),
    -- Mesh office chair
    (850563, 19786, 26, 18999, 16),
    -- Anti-static chair mat
    (850564, 19788, 24, 7999, 25),
    (850564, 19788, 25, 9499, 19);

INSERT INTO images (variant_id, file_path, alt_text)
VALUES 
	-- BiC mech pencils 10 pack
	(100200, 'https://i5.walmartimages.com/seo/BIC-Xtra-Smooth-Mechanical-Pencils-0-7mm-Point-10-Count-Pack-Mechanical-Pencils-for-School_7a1df234-c72e-4549-a80f-92e1c2e0b557.6e46388b39294d44bb018d522a55dd08.jpeg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF', 'Assorted 10 Pack - Front View'),
    (100200, 'https://i5.walmartimages.com/asr/8a6d51f9-efbb-4ba6-aa81-beec59e6997d.c4b459a21ec1a7982b9e00ed4224598b.jpeg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF', '5 Pencil colors - Front View'),
    -- BiC mech pencils 48 pack
    (100201, 'https://i5.walmartimages.com/seo/BIC-Xtra-Smooth-2-Mechanical-Pencil-Black-Medium-Point-0-7-mm-48-Count_effc7018-d8e3-4f21-9919-517baae13efd_1.d4b16ba3223f42852420d2dfd7971946.jpeg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF', 'Assorted 48 Pack - Front View'),
    (100201, 'https://i5.walmartimages.com/asr/8a6d51f9-efbb-4ba6-aa81-beec59e6997d.c4b459a21ec1a7982b9e00ed4224598b.jpeg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF', '5 Pencil colors - Front View'),
    -- BiC mech pencils 60 pack
    (100202, 'https://i.dansdeals.com/wp-content/uploads/2021/08/24145550/bic-xtra-smooth-mechanical-pencil-medium-point-07mm-perfect-for-the.jpg', 'Assorted 60 Pack - Front View'),
    (100202, 'https://i5.walmartimages.com/asr/8a6d51f9-efbb-4ba6-aa81-beec59e6997d.c4b459a21ec1a7982b9e00ed4224598b.jpeg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF', '5 Pencil colors - Front View'),
    -- red apex notebook
    (100203, 'https://m.media-amazon.com/images/I/81y2PkckqSL._AC_SL1500_.jpg', 'Assorted 6 Pack - Front View'),
    (100203, 'https://i5.walmartimages.com/asr/a5a532f2-8ad9-4b60-9e4e-5cdd439ce47f.d8217e8b065113176b8fd5325d6d0a14.jpeg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF', 'Single Notebook - Inside View'),
    -- blue apex notebook
    (100204, 'https://m.media-amazon.com/images/I/81y2PkckqSL._AC_SL1500_.jpg', 'Assorted 6 Pack - Front View'),
    (100204, 'https://i5.walmartimages.com/asr/a5a532f2-8ad9-4b60-9e4e-5cdd439ce47f.d8217e8b065113176b8fd5325d6d0a14.jpeg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF', 'Single Notebook - Inside View'),
    -- green apex notebook
    (100205, 'https://m.media-amazon.com/images/I/81y2PkckqSL._AC_SL1500_.jpg', 'Assorted 6 Pack - Front View'),
    (100205, 'https://i5.walmartimages.com/asr/a5a532f2-8ad9-4b60-9e4e-5cdd439ce47f.d8217e8b065113176b8fd5325d6d0a14.jpeg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF', 'Single Notebook - Inside View'),
    -- yellow apex notebook
    (100206, 'https://m.media-amazon.com/images/I/81y2PkckqSL._AC_SL1500_.jpg', 'Assorted 6 Pack - Front View'),
    (100206, 'https://i5.walmartimages.com/asr/a5a532f2-8ad9-4b60-9e4e-5cdd439ce47f.d8217e8b065113176b8fd5325d6d0a14.jpeg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF', 'Single Notebook - Inside View'),
    -- navy apex notebook
    (100207, 'https://m.media-amazon.com/images/I/81y2PkckqSL._AC_SL1500_.jpg', 'Assorted 6 Pack - Front View'),
    (100207, 'https://i5.walmartimages.com/asr/a5a532f2-8ad9-4b60-9e4e-5cdd439ce47f.d8217e8b065113176b8fd5325d6d0a14.jpeg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF', 'Single Notebook - Inside View'),
    -- black apex notebook
    (100208, 'https://m.media-amazon.com/images/I/81y2PkckqSL._AC_SL1500_.jpg', 'Assorted 6 Pack - Front View'),
    (100208, 'https://i5.walmartimages.com/asr/a5a532f2-8ad9-4b60-9e4e-5cdd439ce47f.d8217e8b065113176b8fd5325d6d0a14.jpeg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF', 'Single Notebook - Inside View'),
	-- assorted 6 pack apex notebooks
    (100209, 'https://i5.walmartimages.com/seo/VEEBOOST-Spiral-Notebook-Wide-Ruled-Notebooks-Pack-70-Sheets-1-Subject-Notebooks-Bulk-6-Color-Assortment-3-Hole-Perforated-Sheets-6-College-Ruled_1b531551-d0b8-450d-9ff7-afea18bbd779.5271cf7c8925bd50af57f06aba6cc5cc.jpeg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF', 'Assorted 6 Pack - Stacked View'),
	(100209, 'https://eclipsusa.com/cdn/shop/files/23955Shot_6_Lifestyle.jpg?v=1735326621&width=1946', 'Assorted 6 Pack - Split Stacked View'),
	-- assorted 12 pack apex notebooks
    (100210, 'https://m.media-amazon.com/images/I/81MjndMAZYL.jpg', 'Assorted 12 Pack - Stacked View'),
    (100210, 'https://i5.walmartimages.com/asr/a5a532f2-8ad9-4b60-9e4e-5cdd439ce47f.d8217e8b065113176b8fd5325d6d0a14.jpeg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF', 'Single Notebook - Inside View'),
	-- text books
	(100211, "/images/chem_text_product.jpg", 'Chemistry Textbook - Front View'),
	(100212, "/images/comp_text_product.webp", 'Composition Textbook - Front View'),
	(100213, "/images/phys_text_product.jpg", 'Physics Textbook - Front View'),
	(100214, "/images/precalc_text_product.jpg", 'Precalculus Textbook - Front View');
    
INSERT INTO discounts (variant_id, discount_price, start_date, end_date)
VALUES
	(100211, 2499, '2025-04-09 16:30:00', '2025-04-16 16:30:00'),
    (100213, 32999, NULL, NULL),
    (100214, 37599, NULL, NULL),
    (100217, 16599, '2025-04-01 21:59:59', '2025-04-15 21:59:59');

INSERT INTO carts (customer_email)
VALUES 
		('d_giant@outlook.com'),
        ('j_prescott@gmail.com'),
        ('s_teller@gmail.com'),
        ('c_ramos@outlook.com'),
        ('s_petocs@gmail.com');

INSERT INTO cart_items (cart_id, variant_id, quantity)
VALUES
	-- cust 1
	(1, 100205, 4),
    (1, 100206, 3),
    (1, 100201, 1),
    -- cust 2
    (2, 100210, 2),
    (2, 100202, 4),
    (2, 100213, 1),
    (2, 100215, 1),
    (2, 100211, 1),
    (2, 100216, 1),
    -- cust 3
    (3, 100217, 6),
    (3, 100219, 6);

INSERT INTO orders (customer_email, status, order_date, total_price)
VALUES 
	('c_ramos@outlook.com', 'pending', '2025-04-06 10:26:54', 55669), -- chair discounted
    ('c_ramos@outlook.com', 'complete', '2025-03-12 14:35:22', 64870),
    ('s_petocs@gmail.com', 'pending', '2025-04-06 16:39:12', 36246), 
    ('s_teller@gmail.com', 'confirmed', '2025-04-01 22:11:00', 51496), -- chair discounted
    ('d_giant@outlook.com', 'processing', '2025-03-25 12:05:59', 144900), 
    ('d_giant@outlook.com', 'processing', '2025-03-30 17:03:36', 188497),
    ('s_petocs@gmail.com', 'processing', '2025-03-27 08:22:13', 62646),
    ('j_prescott@gmail.com', 'complete', '2025-03-17 09:18:47', 40471),
    ('s_teller@gmail.com', 'complete', '2025-03-20 20:44:05', 3947),
    ('s_teller@gmail.com', 'rejected', '2025-04-03 07:48:31', 143445);
    
INSERT INTO order_items (order_id, variant_id, quantity, price_at_order_time)
VALUES 																			-- phys and precalc all discounted
	(2, 100211, 1, 42999), -- chem textbook x1 => 42999
    (2, 100204, 2, 299), -- blue notebook x2 => 299 * 2 = 598
    (2, 100201, 1, 2274), -- 48-pack pencils x1 => 2274
    (2, 100217, 1, 18999), -- mesh chair x1 => 18999
    -- ^ total = 42999 + 598 + 2274 + 18999 = 64870
    
    (5, 100205, 2, 299), -- green notebook x2 => 299 * 2 = 598
    (5, 100206, 1, 299), -- yellow notebook x1 => 299
    (5, 100214, 1, 39500), -- precalc textbook x1 => 39500
    (5, 100216, 1, 144900), -- L-desk x1 => 144900
	-- ^ total = 598 + 299 + 39500 + 144900
   
    (7, 100213 , 1, 32999), -- phys textbook x1 => discounted price => 32999
    (7, 100202 , 1, 2649), -- 60-pack pencils x1 => 2649
    (7, 100217, 1, 18999), -- mesh chair x1 => 18999
    (7, 100218 , 1, 7999), -- chair mat (36x48) x1 => 7999
    -- ^ total = 32999 + 2649 + 18999 + 7999 = 62646
    
    (3, 100208, 1, 299), -- black notebook x1 => 299
    (3, 100212, 1, 34999), -- chem textbook x1 => 34999
    (3, 100200, 2, 474), -- 10-pack pencils x2 => 474 * 2 = 948
    -- ^ total = 299 + 34999 + 948 = 36246
    
    (9, 100210, 1, 2999), -- 12-pack notebooks x1 => 2999
    (9, 100200, 2, 474), -- 10-pack pencils x2 => 474 * 2 = 948
    -- ^ total = 299 + 948 = 3947
    
    (4, 100209, 1, 1599), -- 6-pack notebooks x1 => 1599
    (4, 100213, 1, 32999), -- phys textbook => discounted price => 32999
    (4, 100217, 1, 16599), -- mesh chair x1 => discounted price => 16599
    (4, 100203, 1, 299), -- red notebook x1 => 299
    -- ^ total = 1599 + 32999 + 16599 + 299 = 51496
    
    (8, 100214, 1, 37599), -- precalc textbook => discounted price => 37599
    (8, 100208, 2, 299), -- black notebook x2 => 299 * 2 = 598
    (8, 100201, 1, 2274), -- 48-pack pencils x1 => 2274
    -- ^ total = 37599 + 598 + 2274 = 40471
    
    (1, 100217, 1, 16599), -- mesh chair => discounted price => 16599
    (1, 100210, 1, 2999), -- 12-pack notebooks x1 => 2999
    (1, 100204, 2, 299), -- blue notebook x2 => 299 * 2 = 598
    (1, 100212, 1, 34999), -- comp textbook x1 => 34999
    (1, 100200, 1, 474), -- 10-pack pencils => 474
    -- total ^ = 16599 + 2999 + 598 + 34999 + 474 = 55669 DISCOUNTED CHAIR
    
    (6, 100205, 2, 299), -- green notebooks x2 => 299 * 2 = 598
    (6, 100211, 1, 42999), -- chem textbook => 42999
    (6, 100216, 1, 144900), -- L-desk x1 => 144900
    -- ^ total = 598 + 42999 + 144900 = 188497
    
    (10, 100202, 1, 2649), -- 60-pack pencils x1 => 2649
    (10, 100213, 1, 32999), -- phys textbook => discounted price => 32999
    (10, 100204, 1, 299), -- blue notebook => 299
    (10, 100215, 1, 95000), -- desk (60x30) x1 => 95000
    (10, 100219, 1, 9499), -- chair mat (45x53) x1 => 9499
    (10, 100210, 1, 2999); -- 12-pack notebooks x1 => 2999
    -- ^ total = 2649 + 32999 + 299 + 95000 + 9499 + 2999 = 143445