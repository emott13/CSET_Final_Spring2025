CREATE DATABASE IF NOT EXISTS goods;
USE goods;
-- drop database goods;
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
    variant_id INT,															-- will contain variant_id if image belongs to product
	chat_id INT,															-- will contain chat_id if image belongs to chat conversation															
    complaint_id INT,														-- will contain complaint_id if image belongs to customer complaint
    review_id INT,															-- will contain review_id if image belongs to customer review
    file_path VARCHAR(500) NOT NULL,  										-- path or URL to the image file
    alt_text VARCHAR(255),            										-- image description / alt text
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id),
	CONSTRAINT only_one_fk CHECK (											-- forces only one foreign key per row, ensuring image will belong to only one type of entry
		(chat_id IS NOT NULL AND variant_id IS NULL AND complaint_id IS NULL AND review_id IS NULL) OR
		(chat_id IS NULL AND variant_id IS NOT NULL AND complaint_id IS NULL AND review_id IS NULL) OR
		(chat_id IS NULL AND variant_id IS NULL AND complaint_id IS NOT NULL AND review_id IS NULL) OR
		(chat_id IS NULL AND variant_id IS NULL AND complaint_id IS NULL AND review_id IS NOT NULL)
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
    submitted_by VARCHAR(255),
    reviewed_by VARCHAR(255),			-- email of admin who reviewed
	title VARCHAR(50),
    description VARCHAR(500),
    demand ENUM('return', 'refund', 'warranty claim'),
    status ENUM('pending', 'rejected', 'confirmed', 'processing', 'complete') NOT NULL,
    date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (submitted_by) REFERENCES users(email),
    FOREIGN KEY (reviewed_by) REFERENCES users(email)
);

-- chats
CREATE TABLE IF NOT EXISTS chats (
	chat_id INT PRIMARY KEY AUTO_INCREMENT,
    complaint_id INT,
    product_id INT,
	text VARCHAR(500),
	image_id INT,
    user_from VARCHAR(255),													    -- person sending message
    user_to VARCHAR(255),													    -- person receiving message
    date_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,						-- to keep track of when chats were sent to display in proper order
    FOREIGN KEY (user_from) REFERENCES users(email),
    FOREIGN KEY (user_to) REFERENCES users(email),
    FOREIGN KEY (image_id) REFERENCES images(image_id),
    FOREIGN KEY (complaint_id) REFERENCES complaints(complaint_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    CONSTRAINT only_one_id CHECK (
		(complaint_id IS NOT NULL AND product_id IS NULL) OR
        (complaint_id IS NULL AND product_id IS NOT NULL)
    )
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
-- meaningful reviews with images from customers on all shipped orders **DONE**
-- one return and one warranty application in progress **DONE**
-- meaningful chat messages regarding these requests **DONE**
-- meaningful chat messages from all customers to different vendors
-- any additional information necessary to model a running ecommerce website
-- select product_title, size_description, file_path, alt_text from products natural join product_variants natural join sizes natural join images where vendor_id = 'g_pitts@supplies4school.org' and image_id IN(1,3,5,7,19,21);
SELECT product_title, size_description, file_path, alt_text
        FROM products NATURAL JOIN product_variants NATURAL JOIN sizes NATURAL JOIN images
        WHERE vendor_id = 'g_pitts@supplies4school.org' and image_id IN(1, 3, 5, 7, 19, 21); 

INSERT INTO users (email, username, hashed_pswd, first_name, last_name, type)
VALUES											
	('d_daedalus_admin@goods.com', 'dd_admin', '$2b$12$sm8yNymjyUq40vGxRkGhve0dvWvSN2eb0ENT4/QZUEkYRGVTHDXjy', 'Daedalus', 'Dzidzic', 'admin'), -- admin
	('m_malova_admin@goods.com', 'mm_admin', '$2b$12$sm8yNymjyUq40vGxRkGhve0dvWvSN2eb0ENT4/QZUEkYRGVTHDXjy', 'Maya', 'Malova', 'admin'), -- admin
	('s_teller@gmail.com', 'steller', '$2b$12$sm8yNymjyUq40vGxRkGhve0dvWvSN2eb0ENT4/QZUEkYRGVTHDXjy', 'Simpson', 'Teller', 'customer'), -- customer
	('s_petocs@gmail.com', 'spetocs', '$2b$12$sm8yNymjyUq40vGxRkGhve0dvWvSN2eb0ENT4/QZUEkYRGVTHDXjy', 'Sajay', 'Petocs', 'customer'), -- customer
	('d_giant@outlook.com', 'dgiant', '$2b$12$sm8yNymjyUq40vGxRkGhve0dvWvSN2eb0ENT4/QZUEkYRGVTHDXjy', 'Damien', 'Giant', 'customer'), -- customer
	('c_ramos@outlook.com', 'cramos', '$2b$12$sm8yNymjyUq40vGxRkGhve0dvWvSN2eb0ENT4/QZUEkYRGVTHDXjy', 'Celia', 'Ramos', 'customer'), -- customer
	('j_prescott@gmail.com', 'jprescott', '$2b$12$sm8yNymjyUq40vGxRkGhve0dvWvSN2eb0ENT4/QZUEkYRGVTHDXjy', 'Jean', 'Prescott', 'customer'), -- customer
	('a_batts@textbooksmadeeasy.org', 'abatts_vendor', '$2b$12$sm8yNymjyUq40vGxRkGhve0dvWvSN2eb0ENT4/QZUEkYRGVTHDXjy', 'Annemarie', 'Batts', 'vendor'), -- vendor
	('g_pitts@supplies4school.org', 'gpitts_vendor', '$2b$12$sm8yNymjyUq40vGxRkGhve0dvWvSN2eb0ENT4/QZUEkYRGVTHDXjy', 'Gebhard', 'Pitts', 'vendor'), -- vendor
	('i_tombolli@study_space.com', 'itombolli_vendor', '$2b$12$sm8yNymjyUq40vGxRkGhve0dvWvSN2eb0ENT4/QZUEkYRGVTHDXjy', 'Isabella', 'Tomboli', 'vendor'); -- vendor

INSERT INTO products (vendor_id, product_title, product_description, warranty_months)
VALUES
	-- 850555
	('g_pitts@supplies4school.org', 'BIC Xtra-Smooth Mechanical Pencils', 'BIC Xtra-Smooth Mechanical Pencils offer smooth, dark writing with a 0.7mm medium point. Each pencil comes with three pieces of No. 2 lead that doesn’t smudge and erases cleanly, making them ideal for standardized tests.', 0),
	-- 850556
    ('g_pitts@supplies4school.org', 'APEX Spiral Notebook', 'APEX Spiral Notebooks feature 70 wide-ruled sheets, 1 subject, with 3-hole perforated sheets. Available as single notebook or in multi-packs.', 0),
	-- 850557
	('a_batts@textbooksmadeeasy.org', 'Chemistry in Context', '"Applying Chemistry to Society." First edition textbook, new.', 0),
	-- 850558
    ('a_batts@textbooksmadeeasy.org', 'The Language of Composition', '2nd edition textbook. Authors: Renee H. Shea, Lawrence Scanlon, and Robin Dissin Aufses.', 0),
    -- 850559
	('a_batts@textbooksmadeeasy.org', 'Advanced Pysics', '2nd edition textbook. Authors: Steve Adams and Jonathan Allday.', 0),
    -- 850560
    ('a_batts@textbooksmadeeasy.org', 'Precalculus', '"A Graphing Approach. First edition textbook, used. Teacher\'s Edition"', 0),
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
    ('s_teller@gmail.com', 'complete', '2025-04-01 22:11:00', 51496), -- chair discounted
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

-- reviews with images on shipped orders
INSERT INTO reviews (customer_email, rating, description, date)
VALUES
	('c_ramos@outlook.com', 42, 'I ordered this chemistry textbook after transfering to a chem class mid semester. It shipped quickly and the cover had some slight dents in it but otherwise in good condition.', '2025-03-20 11:15:36'),
    ('j_prescott@gmail.com', 35, 'Got this textbook at a discount. Its Precalculus by Holt. The corner of the cover had some damage which was annoying.', '2025-03-22 13:57:04'),
    ('s_teller@gmail.com', 50, 'These are my favorite mechanical pencils. Super reliable and smooth, I dont buy any other brand. 100% recommend!', '2025-03-24 10:32:45');
INSERT INTO images (review_id, file_path, alt_text)
VALUES
	(1, '/images/chem_text_review_good', 'Chemistry textbook - Bottom Overhead View'),
    (2, '/images/precalc_text_review_2', 'Precalc textbook - Left Diagonal View'),
    (2, '/images/precalc_text_review_2a', 'Precalc textbook - Right Diagonal View'),
    (3, 'https://i5.walmartimages.com/dfw/6e29e393-90fa/k2-_ebd07f4b-3753-4a6e-850b-1125d114586f.v1.jpg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF', 'BiC 10-Pack pencils review');

-- one warranty claim and one return
INSERT INTO complaints (title, submitted_by, reviewed_by, description, demand, status, date)
VALUES
	('Received wrong item.', 'c_ramos@outlook.com', 'd_daedalus_admin@goods.com', 'I ordered the 48-pack of the BiC mechanical pencils but was sent a 10-pack instead?? I would like a refund.', 'refund', 'complete', '2025-03-16 16:37:49'),
    ('Chair broke within 2 days of receiving', 's_teller@gmail.com', NULL, 'I got the Uline brand mesh office chair recently. After only two days, two of the wheels snapped off. I would like a replacement part to fix the chair.', 'warranty claim', 'pending', '2025-04-08 11:13:41');
INSERT INTO images (complaint_id, file_path, alt_text)
VALUES
	(1, 'https://i5.walmartimages.com/dfw/6e29e393-e1a6/k2-_3afbd2e8-6936-4d46-bc55-094bacdff1e0.v1.jpg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF', 'BiC 10-pack mech pencils - Customer photo');

-- chats about complaints
INSERT INTO chats (text, complaint_id, product_id, user_from, user_to, date_time)
VALUES
	-- chats for refund complaint
	('Hello Ms. Ramos, we have recieved your refund ticket. An associate will be with you shortly to discuss solving this issue.', 1, NULL, 'g_pitts@supplies4school.org', 'c_ramos@outlook.com', '2025-03-16 16:41:00'),
    ('Good afternoon, Ms. Ramos. My name is Gebhard. I have reviewed your refund request and I am very sorry for the mix up. We will refund you for the BiC mechanical pencils 48-pack that you did not receive.', 1, NULL, 'g_pitts@supplies4school.org', 'c_ramos@outlook.com', '2025-03-16 16:42:07'),
    ('We are very sorry for the inconvenience and appreciate the opportunity to make this right for you.', 1, NULL, 'g_pitts@supplies4school.org', 'c_ramos@outlook.com', '2025-03-16 16:42:31'),
    ('Thank you for handling this quickly. How long until I get the money back?', 1, NULL, 'c_ramos@outlook.com', 'g_pitts@supplies4school.org', '2025-03-16 16:44:22'),
    ('Of course, it is our please. Refunds can take up to 30 business days to process, but most often you will see the chargeback within 7-10 business days.', 1, NULL, 'g_pitts@supplies4school.org', 'c_ramos@outlook.com', '2025-03-16 16:44:49'),
    ('Can I answer any other questions for you?', 1, NULL, 'g_pitts@supplies4school.org', 'c_ramos@outlook.com', '2025-03-16 16:45:03'),
    ('No, thanks for the help.', 1, NULL, 'c_ramos@outlook.com', 'g_pitts@supplies4school.org', '2025-03-16 16:48:32'),
    ('Absolutely, Ms. Ramos. Thank you for choosing Supplies4School and have a wonderful day.', 1, NULL, 'g_pitts@supplies4school.org', 'c_ramos@outlook.com', '2025-03-16 16:50:03'),
    -- chats for warranty complaint
    ('Hello Mr. Teller. Thank you for choosing Study Space! We have received your ticket and an associate will contact you shortly regarding this matter.', 2, NULL, 'i_tombolli@study_space.com', 's_teller@gmail.com', '2025-04-08 11:15:00'),
    ('Hello and thank you for reaching out. My name is Isabella, how can I assist you today?', 2, NULL, 'i_tombolli@study_space.com', 's_teller@gmail.com', '2025-04-08 11:16:21'),
    ('I would like to submit a warranty claim for a chair I bought from you guys recently.', 2, NULL, 's_teller@gmail.com', 'i_tombolli@study_space.com', '2025-04-08 11:17:11'),
    ('Absolutely, I would be happy to help you with that. Can you tell me the product name so I can find your order information?', 2, NULL, 'i_tombolli@study_space.com', 's_teller@gmail.com', '2025-04-08 11:17:58'),
    ('Sure, I think it was called a Mesh Task Chair? Maybe something like that.', 2, NULL, 's_teller@gmail.com', 'i_tombolli@study_space.com', '2025-04-08 11:18:33'),
    ('Okay, give me one moment to locate your order details.', 2, NULL, 'i_tombolli@study_space.com', 's_teller@gmail.com', '2025-04-08 11:19:06'),
    ('I have found a product "ULINE Mesh Task Chair" from your order on April 1st. Is this the correct item?', 2, NULL, 'i_tombolli@study_space.com', 's_teller@gmail.com', '2025-04-08 11:22:37'),
    ('Yeah thats it.', 2, NULL, 's_teller@gmail.com', 'i_tombolli@study_space.com', '2025-04-08 11:23:09'),
    ('Great! Can you please describe the issue so I can see if it is covered under the warranty?', 2, NULL, 'i_tombolli@study_space.com', 's_teller@gmail.com', '2025-04-08 11:23:41'),
    ('Yeah I mean I just sat on the chair and it broke.', 2, NULL, 's_teller@gmail.com', 'i_tombolli@study_space.com', '2025-04-08 11:43:46'),
    ('Two of the wheels snapped off from the base. I put it together based on the instructions so I dont even know how it happened.', 2, NULL, 's_teller@gmail.com', 'i_tombolli@study_space.com', '2025-04-08 11:44:05'),
    ('I tried to fix it but part where the wheels go into the base is broken.', 2, NULL, 's_teller@gmail.com', 'i_tombolli@study_space.com', '2025-04-08 11:44:27'),
    ('I am very sorry for the inconvenience. Can you please attach a photo of the damaged part?', 2, NULL, 'i_tombolli@study_space.com', 's_teller@gmail.com', '2025-04-08 11:45:23'),
    ('Sure one sec.', 2, NULL, 's_teller@gmail.com', 'i_tombolli@study_space.com', '2025-04-08 11:45:51');
INSERT INTO images (chat_id, file_path, alt_text)
VALUES
	(2, 'https://www.reddit.com/media?url=https%3A%2F%2Fi.redd.it%2F976ux5ctckwz.jpg', 'Customer submitted image');
INSERT INTO chats (text, complaint_id, product_id, image_id, user_from, user_to, date_time)
VALUES
    ('Okay here is the photo:', 2, NULL, NULL, 's_teller@gmail.com', 'i_tombolli@study_space.com', '2025-04-08 11:49:12'),
    (NULL, 2, NULL, 32, 's_teller@gmail.com', 'i_tombolli@study_space.com', '2025-04-08 11:49:28');
INSERT INTO chats (text, complaint_id, product_id, user_from, user_to, date_time)
VALUES
    ('Thank you, Mr. Teller. I see the issue. I will submit the warranty claim for you. It can take up to 7 business days to be processed.', 2, NULL, 'i_tombolli@study_space.com', 's_teller@gmail.com', '2025-04-08 11:50:00'),
    ('You will receive an email when the replacement part has been shipped.', 2, NULL, 'i_tombolli@study_space.com', 's_teller@gmail.com', '2025-04-08 11:50:19'),
    ('Is there anything else I can help you with before closing the support ticket?', 2, NULL, 'i_tombolli@study_space.com', 's_teller@gmail.com', '2025-04-08 11:50:31'),
    ('Not right now, I appreciate the help.', 2, NULL, 's_teller@gmail.com', 'i_tombolli@study_space.com', '2025-04-08 11:52:36'),
	('It is my pleasure. Thank you for choosing Study Space. Have a wonderful day.', 2, NULL, 'i_tombolli@study_space.com', 's_teller@gmail.com', '2025-04-08 11:53:14');

-- chats from remaining customers to vendors about products
INSERT INTO chats (text, product_id, user_from, user_to, date_time) 
VALUES
	-- user s_petocs@gmail.com
	('Hi Annemarie, I saw your listing for "The Language of Composition" and wanted to ask if it’s still available.', 850558, 's_petocs@gmail.com', 'a_batts@textbooksmadeeasy.org', '2025-03-15 13:02:51'),
	('Hi Sajay! Yes, the textbook is still available. It’s the 2nd edition and in good condition.', 850558, 'a_batts@textbooksmadeeasy.org', 's_petocs@gmail.com', '2025-03-15 13:10:17'),
	('That’s great to hear. Are there any markings or highlights inside?', 850558, 's_petocs@gmail.com', 'a_batts@textbooksmadeeasy.org', '2025-03-15 13:12:45'),
	('There are a few pencil notes in the margins, but no ink or highlighting. Nothing that would interfere with reading.', 850558, 'a_batts@textbooksmadeeasy.org', 's_petocs@gmail.com', '2025-03-15 13:15:30'),
	('Thanks for the info. Since it’s used and has some pencil notes, would you be open to a small discount?', 850558, 's_petocs@gmail.com', 'a_batts@textbooksmadeeasy.org', '2025-03-15 13:17:02'),
	('I understand, but I’m firm on the price due to high demand for this edition. Let me know if you’re still interested.', 850558, 'a_batts@textbooksmadeeasy.org', 's_petocs@gmail.com', '2025-03-15 13:19:38'),
    -- user j_prescott@gmail.com
	('Hi Isabella, I’m interested in the Anti-Static Carpet Chair Mat. Is the 45 x 53 inch size currently in stock?', 850563, 'j_prescott@gmail.com', 'i_tombolli@study_space.com', '2025-03-18 09:24:12'),
	('Hi Jean! Yes, both sizes are in stock, including the 45 x 53 inch option at $94.99.', 850563, 'i_tombolli@study_space.com', 'j_prescott@gmail.com', '2025-03-18 09:27:01'),
	('Great, thanks! Can you tell me how durable it is for daily use with a rolling chair?', 850563, 'j_prescott@gmail.com', 'i_tombolli@study_space.com', '2025-03-18 09:29:18'),
	('Absolutely. It’s made from durable vinyl and holds up well under regular use. The cleared backing keeps it steady, even with frequent rolling.', 850563, 'i_tombolli@study_space.com', 'j_prescott@gmail.com', '2025-03-18 09:31:44'),
	('Sounds good. I’d like to go ahead with the 45 x 53 size. Do you offer local pickup or only shipping?', 850563, 'j_prescott@gmail.com', 'i_tombolli@study_space.com', '2025-03-18 09:34:29'),
	('Thanks, Jean. We offer both options—local pickup is available if you’re nearby, otherwise we can ship it to you.', 850563, 'i_tombolli@study_space.com', 'j_prescott@gmail.com', '2025-03-18 09:36:10'),
	-- user d_giant@outlook.com
	('Hi Gebhard, I’m looking to place a bulk order for the 12-pack APEX Spiral Notebooks. Do you offer any discounts for larger quantities?', 850556, 'd_giant@outlook.com', 'g_pitts@supplies4school.org', '2025-04-09 10:52:03'),
	('Hi Damien! I’d be happy to discuss a bulk deal. How many 12-packs are you looking to purchase?', 850556, 'g_pitts@supplies4school.org', 'd_giant@outlook.com', '2025-04-09 10:55:21'),
	('I’m thinking of ordering 10 to 15 packs, depending on pricing.', 850556, 'd_giant@outlook.com', 'g_pitts@supplies4school.org', '2025-04-09 10:57:36'),
	('Thanks for the info! For 10 or more 12-packs, I can offer them at $26.99 per pack instead of $29.99.', 850556, 'g_pitts@supplies4school.org', 'd_giant@outlook.com', '2025-04-09 11:01:12'),
	('That’s a fair offer. If I go with 15 packs, could you do $25 each?', 850556, 'd_giant@outlook.com', 'g_pitts@supplies4school.org', '2025-04-09 11:03:44'),
	('For 15 packs, I can meet you halfway at $25.99 per pack. Let me know if that works for you.', 850556, 'g_pitts@supplies4school.org', 'd_giant@outlook.com', '2025-04-09 11:06:10');
    
    
-- select * from products;
-- select * from products natural join images;
-- select * from images;

-- updated products for cset 180 final
INSERT INTO products (vendor_id, product_title, product_description, warranty_months)
VALUES
	-- 850565
    ('i_tombolli@study_space.com', 'Metro Office Desks', 'Strong, sleek design. For ad agencies, design studios, and urban office spaces. Durable 1 1/2" thick laminate top with PVC edges and cable grommets. 30" height. Heavy-duty steel frame with rectangle tube legs and full-length modest panel.', 12),
	-- 850566
    ('i_tombolli@study_space.com', 'Metro Mobile Pedestal File - 2 Drawer', 'Companion storage fits under Metro Office Desks. Durable laminate surface resists scratches, stains and spills. 2 file drawers. 5 swivel casters, 2locking. Includes lock and 2 keys.', 12),
	-- 850567
    ('i_tombolli@study_space.com', 'Metro Mobile Pedestal File - 3 Drawer', 'Companion storage fits under Metro Office Desks. Durable laminate surface resists scratches, stains and spills. 1 file drawer, 2 box drawers. 5 swivel casters, 2locking. Includes lock and 2 keys.', 12);
--  select * from product_variants;
INSERT INTO sizes (size_description)
VALUES
	('48L X 24W Inches'), -- 28
    ('60L X 24W Inches'), -- 29
    ('72L X 24W Inches'), -- 30
    ('60W x 30L Inches'), -- 31
    ('72W X 30L Inches'), -- 32
    ('16W X 22D X 28L Inches'); -- 33
    
 INSERT INTO product_variants (product_id, color_id, size_id, price, current_inventory)
 VALUES -- color: 19787
	(850565, 19787, 28, 44900, 20), -- desk
    (850565, 19787, 29, 48900, 20), -- desk
    (850565, 19787, 30, 52900, 20), -- desk
    (850565, 19787, 31, 53900, 20), -- desk
    (850565, 19787, 32, 57900, 15), -- desk
    (850566, 19787, 33, 26900, 32), -- pedestal file 2-drawer
    (850567, 19787, 33, 27900, 31); -- pedestal file 3-drawer
-- select * from images where variant_id in(100227, 100227, 100239, 100240);
INSERT INTO images (variant_id, file_path, alt_text)
VALUES
	-- H-10353
	(100220, '/static/images/metro_collection/H-10353-A.png', 'Front View'), 
    (100220, '/static/images/metro_collection/H-10353-B.png', 'Back View'), 
    (100220, '/static/images/metro_collection/H-10353-C.png', 'Front View With Office Items'), 
    (100220, '/static/images/metro_collection/H-10353-D.png', 'Back View With Office Items'), 
    (100220, '/static/images/metro_collection/corner-wheel.png', 'Bottom Corner Wheel'), 
    (100220, '/static/images/metro_collection/grommet.png', 'Desktop Grommet With Cord'), 
    -- H-9778
    (100221, '/static/images/metro_collection/H-9778-A.png', 'Front View'), 
    (100221, '/static/images/metro_collection/H-9778-B.png', 'Back View'), 
    (100221, '/static/images/metro_collection/H-9778-C.png', 'Front View With Office Items'), 
    (100221, '/static/images/metro_collection/H-9778-D.png', 'Back View With Office Items'), 
    (100221, '/static/images/metro_collection/corner-wheel.png', 'Bottom Corner Wheel'), 
    (100221, '/static/images/metro_collection/grommet.png', 'Desktop Grommet With Cord'), 
    -- H-10355
    (100222, '/static/images/metro_collection/H-10355-A.png', 'Front View'), 
    (100222, '/static/images/metro_collection/H-10355-B.png', 'Back View'), 
    (100222, '/static/images/metro_collection/H-10355-C.png', 'Front View With Office Items'), 
    (100222, '/static/images/metro_collection/H-10355-D.png', 'Back View With Office Items'), 
    (100222, '/static/images/metro_collection/corner-wheel.png', 'Bottom Corner Wheel'), 
    (100222, '/static/images/metro_collection/grommet.png', 'Desktop Grommet With Cord'), 
    -- H-10354
    (100223, '/static/images/metro_collection/H-10355-A.png', 'Front View'), 
    (100223, '/static/images/metro_collection/H-10355-B.png', 'Back View'), 
    (100223, '/static/images/metro_collection/H-10355-C.png', 'Front View With Office Items'), 
    (100223, '/static/images/metro_collection/H-10355-D.png', 'Back View With Office Items'), 
    (100223, '/static/images/metro_collection/corner-wheel.png', 'Bottom Corner Wheel'), 
    (100223, '/static/images/metro_collection/grommet.png', 'Desktop Grommet With Cord'), 
    -- H-9779
    (100224, '/static/images/metro_collection/H-10355-A.png', 'Front View'), 
    (100224, '/static/images/metro_collection/H-10355-B.png', 'Back View'), 
    (100224, '/static/images/metro_collection/H-10355-C.png', 'Front View With Office Items'), 
    (100224, '/static/images/metro_collection/H-10355-D.png', 'Back View With Office Items'), 
    (100224, '/static/images/metro_collection/corner-wheel.png', 'Bottom Corner Wheel'), 
    (100224, '/static/images/metro_collection/grommet.png', 'Desktop Grommet With Cord'), 
    -- H-9784
    (100225, '/static/images/metro_collection/H-9784-A.png', 'Front View'), 
    (100225, '/static/images/metro_collection/H-9784-B.png', 'File Drawer Open'), 
    (100225, '/static/images/metro_collection/laminate-edge.png', 'Laminate Corner'), 
    (100225, '/static/images/metro_collection/lock-keys.png', 'Front - keys in keyhole'), 
    -- H-9785
    (100226, '/static/images/metro_collection/H-9784-A.png', 'Front View'),
    (100226, '/static/images/metro_collection/H-9784-B.png', 'File Drawer Open'),
    (100226, '/static/images/metro_collection/H-9784-C.png', 'Box Drawer Open'),
    (100226, '/static/images/metro_collection/laminate-edge.png', 'Laminate Corner'),
    (100226, '/static/images/metro_collection/lock-keys.png', 'Front - keys in keyhole'); 
-- select * from products natural join product_variants where vendor_id = 'i_tombolli@study_space.com' and product_id in(850565, 850566, 850567, 850568, 850569, 850570) order by product_id;

INSERT INTO products (vendor_id, product_title, product_description, warranty_months)
VALUES
-- 850568
	('i_tombolli@study_space.com', 'Designer Office Desks', 'Brighten up your workplace. Minimalist style for modern and trendy offices. 1" thick elevated laminate top with PVC edges and 2 cable grommets. 30" height. Durable white steel frame with beveled legs and hanging modesty panel.', 12),
-- 850569
	('i_tombolli@study_space.com', 'Designer Office L-Desks', 'Brighten up your workplace. Minimalist style for modern and trendy offices. 1" thick elevated laminate top with PVC edges and 2 cable grommets. 30" height. Durable white steel frame with beveled legs and hanging modesty panel. L-Desk has extra space to get work done. Spread out your projects, reports, or creative materials.', 12),
-- 850570    
	('i_tombolli@study_space.com', 'Designer Mobile Pedestal File - 3 Drawer', 'Companion storage tucks away neatly and underneath Designer Office Desks. Durable laminate surface resists scratches, stains and spills. 1 file drawer, 2 box drawers. 5 swivel casters, 2 locking. Includes lock and two keys.', 12);

INSERT INTO colors (color_name)
VALUES
	('white'), -- 19790
    ('maple'); -- 19791
INSERT INTO sizes (size_description)
VALUES
	('60W X 66L Inches'), -- 34
    ('72W X 66L Inches'), -- 35
    ('16W X 18D X 26L Inches'); -- 36
-- SELECT * FROM sizes;
 INSERT INTO product_variants (product_id, color_id, size_id, price, current_inventory)
 VALUES
	-- 100227
	(850568, 19790, 28, 36900, 15),
    -- 100228
    (850568, 19791, 28, 36900, 15),
    -- 100229
	(850568, 19790, 29, 41900, 15),
    -- 100230
    (850568, 19791, 29, 41900, 15),
    -- 100231
    (850568, 19790, 22, 45900, 15),
    -- 100232
    (850568, 19791, 22, 45900, 15),
    -- 100233
    (850568, 19790, 32, 48900, 15),
    -- 100234
    (850568, 19791, 32, 48900, 15),
    -- 100235
    (850569, 19790, 34, 64900, 15),
    -- 100236
    (850569, 19791, 34, 64900, 15),
    -- 100237
    (850569, 19790, 35, 72900, 15),
    -- 100238
    (850569, 19791, 35, 72900, 15),
    -- 100239
    (850570, 19790, 36, 25900, 10),
    -- 100240
    (850570, 19791, 36, 25900, 10);
select * from images where variant_id between 100227 AND 100240;
INSERT INTO images (variant_id, file_path, alt_text)
VALUES
	(100227, '/static/images/designer_collection/H-9790-WHITE-A.png', 'Front View'),
    (100227, '/static/images/designer_collection/H-9790-WHITE-B.png', 'Back View'),
    (100227, '/static/images/designer_collection/H-9790-WHITE-C.png', 'Front View - Office Items'),
    (100227, '/static/images/designer_collection/H-9790-WHITE-D.png', 'Back View -- Office Items'),
	(100227, '/static/images/designer_collection/grommet-white.png', 'Desktop Grommet with Cord'),
    (100227, '/static/images/designer_collection/laminate-corner-white.png', 'Laminate Corner'),
    
    (100228, '/static/images/designer_collection/H-9790-MAPLE-A.png', 'Front View'),
    (100228, '/static/images/designer_collection/H-9790-MAPLE-B.png', 'Back View'),
    (100228, '/static/images/designer_collection/H-9790-MAPLE-C.png', 'Front View - Office Items'),
    (100228, '/static/images/designer_collection/H-9790-MAPLE-D.png', 'Back View -- Office Items'),
    (100228, '/static/images/designer_collection/grommet-maple.png', 'Desktop Grommet with Cord'),
    (100228, '/static/images/designer_collection/laminate-corner-maple.png', 'Laminate Corner'),
    
    (100229, '/static/images/designer_collection/H-10260-WHITE-A.png', 'Front View'),
    (100229, '/static/images/designer_collection/H-10260-WHITE-B.png', 'Back View'),
    (100229, '/static/images/designer_collection/H-10260-WHITE-C.png', 'Front View - Office Items'),
    (100229, '/static/images/designer_collection/H-10260-WHITE-D.png', 'Back View -- Office Items'),
    (100229, '/static/images/designer_collection/grommet-white.png', 'Desktop Grommet with Cord'),
    (100229, '/static/images/designer_collection/laminate-corner-white.png', 'Laminate Corner'),
    
    (100230, '/static/images/designer_collection/H-10260-MAPLE-A.png', 'Front View'),
    (100230, '/static/images/designer_collection/H-10260-MAPLE-B.png', 'Back View'),
    (100230, '/static/images/designer_collection/H-10260-MAPLE-C.png', 'Front View - Office Items'),
    (100230, '/static/images/designer_collection/H-10260-MAPLE-D.png', 'Back View -- Office Items'),
    (100230, '/static/images/designer_collection/grommet-maple.png', 'Desktop Grommet with Cord'),
    (100230, '/static/images/designer_collection/laminate-corner-maple.png', 'Laminate Corner'),
    
    (100231, '/static/images/designer_collection/H-10260-WHITE-A.png', 'Front View'),
    (100231, '/static/images/designer_collection/H-10260-WHITE-B.png', 'Back View'),
    (100231, '/static/images/designer_collection/H-10260-WHITE-C.png', 'Front View - Office Items'),
    (100231, '/static/images/designer_collection/H-10260-WHITE-D.png', 'Back View -- Office Items'),
    (100231, '/static/images/designer_collection/grommet-white.png', 'Desktop Grommet with Cord'),
    (100231, '/static/images/designer_collection/laminate-corner-white.png', 'Laminate Corner'),
    
    (100232, '/static/images/designer_collection/H-10260-MAPLE-A.png', 'Front View'),
    (100232, '/static/images/designer_collection/H-10260-MAPLE-B.png', 'Back View'),
    (100232, '/static/images/designer_collection/H-10260-MAPLE-C.png', 'Front View - Office Items'),
    (100232, '/static/images/designer_collection/H-10260-MAPLE-D.png', 'Back View -- Office Items'),
    (100232, '/static/images/designer_collectiongrommet-maple.png', 'Desktop Grommet with Cord'),
    (100232, '/static/images/designer_collection/laminate-corner-maple.png', 'Laminate Corner'),
    
    (100233, '/static/images/designer_collection/H-10261-WHITE-A.png', 'Front View'),
    (100233, '/static/images/designer_collection/H-10261-WHITE-B.png', 'Back View'),
    (100233, '/static/images/designer_collection/H-10261-WHITE-C.png', 'Front View - Office Items'),
    (100233, '/static/images/designer_collection/H-10261-WHITE-D.png', 'Back View -- Office Items'),
    (100233, '/static/images/designer_collection/grommet-white.png', 'Desktop Grommet with Cord'),
    (100233, '/static/images/designer_collection/laminate-corner-white.png', 'Laminate Corner'),
    
    (100234, '/static/images/designer_collection/H-10261-MAPLE-A.png', 'Front View'),
    (100234, '/static/images/designer_collection/H-10261-MAPLE-B.png', 'Back View'),
    (100234, '/static/images/designer_collection/H-10261-MAPLE-C.png', 'Front View - Office Items'),
    (100234, '/static/images/designer_collection/H-10261-MAPLE-D.png', 'Back View -- Office Items'),
    (100234, '/static/images/designer_collection/grommet-maple.png', 'Desktop Grommet with Cord'),
    (100234, '/static/images/designer_collection/laminate-corner-maple.png', 'Back View -- Office Items'),
    
    (100235, '/static/images/designer_collection/H-9800-WHITE-A.png', 'Front View'),
    (100235, '/static/images/designer_collection/H-9800-WHITE-B.png', 'Back View'),
    (100235, '/static/images/designer_collection/H-9800-WHITE-C.png', 'Front View - Office Items'),
    (100235, '/static/images/designer_collection/H-9800-WHITE-D.png', 'Back View -- Office Items'),
    (100235, '/static/images/designer_collection/laminate-corner-white.png', 'Laminate Corner'),
    (100235, '/static/images/designer_collection/grommet-white.png', 'Desktop Grommet with Cord'),
    
    (100236, '/static/images/designer_collection/H-9800-MAPLE-A.png', 'Front View'),
    (100236, '/static/images/designer_collection/H-9800-MAPLE-B.png', 'Back View'),
    (100236, '/static/images/designer_collection/H-9800-MAPLE-C.png', 'Front View - Office Items'),
    (100236, '/static/images/designer_collection/H-9800-MAPLE-D.png', 'Back View -- Office Items'),
    (100236, '/static/images/designer_collection/laminate-corner-maple.png', 'Laminate Corner'),
    (100236, '/static/images/designer_collection/grommet-maple.png', 'Desktop Grommet with Cord'),
    
--     (100237, '/static/images/designer_collection/H-10262-WHITE-', 'Front View'),
--     (100237, '/static/images/designer_collection/H-10262-WHITE-', 'Back View'),
--     (100237, '/static/images/designer_collection/H-10262-WHITE-', 'Front View - Office Items'),
--     (100237, '/static/images/designer_collection/H-10262-WHITE-', 'Back View -- Office Items'),
--     
--     (100238, '/static/images/designer_collection/H-10262-MAPLE-', 'Front View'),
--     (100238, '/static/images/designer_collection/H-10262-MAPLE-', 'Back View'),
--     (100238, '/static/images/designer_collection/H-10262-MAPLE-', 'Front View - Office Items'),
--     (100238, '/static/images/designer_collection/H-10262-MAPLE-', 'Back View -- Office Items'),
    
    (100239, '/static/images/designer_collection/H-9806-WHITE-A.png', 'Front View'),
    (100239, '/static/images/designer_collection/H-9806-WHITE-B.png', 'File Drawer Open'),
    (100239, '/static/images/designer_collection/H-9806-WHITE-C.png', 'Block Drawer Open'),
    (100239, '/static/images/designer_collection/lock-keys-white.png', 'Front - keys in keyhole'),
    (100239, '/static/images/designer_collection/pedestal-wheel-white.png', 'Front Corner - Wheel'),
    
    (100240, '/static/images/designer_collection/H-9806-MAPLE-A.png', 'Front View'),
    (100240, '/static/images/designer_collection/H-9806-MAPLE-B.png', 'File Drawer Open'),
    (100240, '/static/images/designer_collection/H-9806-MAPLE-C.png', 'Block Drawer Open'),
    (100240, '/static/images/designer_collection/lock-keys-maple.png', 'Front - keys in keyhole'),
    (100240, '/static/images/designer_collection/pedestal-wheel-maple.png', 'Front Corner - Wheel');