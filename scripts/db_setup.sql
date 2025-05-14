CREATE DATABASE IF NOT EXISTS goods;
USE goods;
-- drop database goods_fix;
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

CREATE TABLE IF NOT EXISTS admin_appli (
	email VARCHAR(255) PRIMARY KEY, 										-- using email like a user id since unique
    username VARCHAR(255) NOT NULL UNIQUE,
    hashed_pswd VARCHAR(300) NOT NULL, 										-- hashed passwords needed more space in prev programs so using 300 instead of 255
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL
);

-- products related tables
CREATE TABLE IF NOT EXISTS categories(					-- product categories for search / filter
	cat_num INT PRIMARY KEY,
    cat_name VARCHAR(255) UNIQUE NOT NULL
);
CREATE TABLE IF NOT EXISTS products (					
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    vendor_id VARCHAR(255) NOT NULL,
    product_title VARCHAR(255) NOT NULL,
    product_description VARCHAR(900),
    warranty_months INT,
    cat_num INT NOT NULL,
    FOREIGN KEY (vendor_id) REFERENCES users(email),
    FOREIGN KEY (cat_num) REFERENCES categories(cat_num)
);
CREATE TABLE IF NOT EXISTS colors (						-- product colors
    color_id INT PRIMARY KEY AUTO_INCREMENT,
    color_name VARCHAR(50) UNIQUE NOT NULL,
    color_hex VARCHAR(9)
);
CREATE TABLE IF NOT EXISTS sizes(						-- product sizes
    size_id INT PRIMARY KEY AUTO_INCREMENT,
    size_description VARCHAR(100) UNIQUE NOT NULL
);
CREATE TABLE IF NOT EXISTS specifications(
	spec_id INT PRIMARY KEY AUTO_INCREMENT,
	spec_description VARCHAR(100) UNIQUE NOT NULL
);
CREATE TABLE IF NOT EXISTS product_variants (			-- product variants with each color / size / price combos
    variant_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    color_id INT NOT NULL,
    size_id INT NOT NULL,
    spec_id INT NOT NULL,
    price INT NOT NULL,
    current_inventory INT NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (color_id) REFERENCES colors(color_id),
    FOREIGN KEY (size_id) REFERENCES sizes(size_id),
    FOREIGN KEY (spec_id) REFERENCES specifications(spec_id)
);
-- UNIQUE(product_id, color_id, size_id, spec_id) -- ensures no duplicate combos

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
    address VARCHAR(255),
    address2 VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(255),
    country VARCHAR(255),
    credit_card VARCHAR(19),
    card_name VARCHAR(255),
    card_cvc VARCHAR(4),
    FOREIGN KEY (customer_email) REFERENCES users(email)
);
CREATE TABLE IF NOT EXISTS order_items (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,	
	status ENUM('pending', 'rejected', 'confirmed', 'processing', 'complete') NOT NULL DEFAULT 'pending',
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
    product_id int NOT NULL,
    rating INT NOT NULL,
    description VARCHAR(500),
    image VARCHAR(255),
    date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_email) REFERENCES users(email),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
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
ALTER TABLE products AUTO_INCREMENT = 9000;
ALTER TABLE product_variants AUTO_INCREMENT = 800;
ALTER TABLE colors AUTO_INCREMENT = 600;
ALTER TABLE sizes AUTO_INCREMENT = 400;
ALTER TABLE specifications AUTO_INCREMENT = 200;

-- ----------------- --
-- INSERT STATEMENTS --
-- ----------------- --

INSERT INTO users (email, username, hashed_pswd, first_name, last_name, type)
VALUES											
	('d_daedalus_admin@goods.com', 'dd_admin', '$2b$12$sm8yNymjyUq40vGxRkGhve0dvWvSN2eb0ENT4/QZUEkYRGVTHDXjy', 'Daedalus', 'Dzidzic', 'admin'), -- admin
	('m_malova_admin@goods.com', 'mm_admin', '$2b$12$sm8yNymjyUq40vGxRkGhve0dvWvSN2eb0ENT4/QZUEkYRGVTHDXjy', 'Maya', 'Malova', 'admin'), -- admin
	('s_teller@gmail.com', 'steller', '$2b$12$sm8yNymjyUq40vGxRkGhve0dvWvSN2eb0ENT4/QZUEkYRGVTHDXjy', 'Simpson', 'Teller', 'customer'), -- customer
	('s_petocs@gmail.com', 'spetocs', '$2b$12$sm8yNymjyUq40vGxRkGhve0dvWvSN2eb0ENT4/QZUEkYRGVTHDXjy', 'Sajay', 'Petocs', 'customer'), -- customer
	('d_giant@outlook.com', 'dgiant', '$2b$12$sm8yNymjyUq40vGxRkGhve0dvWvSN2eb0ENT4/QZUEkYRGVTHDXjy', 'Damien', 'Giant', 'customer'), -- customer
	('c_ramos@outlook.com', 'cramos', '$2b$12$sm8yNymjyUq40vGxRkGhve0dvWvSN2eb0ENT4/QZUEkYRGVTHDXjy', 'Celia', 'Ramos', 'customer'), -- customer
	('j_prescott@gmail.com', 'jprescott', '$2b$12$sm8yNymjyUq40vGxRkGhve0dvWvSN2eb0ENT4/QZUEkYRGVTHDXjy', 'Jean', 'Prescott', 'customer'), -- customer
	('a_batts@textbooksmadeeasy.org', 'abatts_vendor', '$2b$12$sm8yNymjyUq40vGxRkGhve0dvWvSN2eb0ENT4/QZUEkYRGVTHDXjy', 'Textbooks', 'Made Easy', 'vendor'), -- vendor
	('g_pitts@supplies4school.org', 'gpitts_vendor', '$2b$12$sm8yNymjyUq40vGxRkGhve0dvWvSN2eb0ENT4/QZUEkYRGVTHDXjy', 'Supplies', '4 School', 'vendor'), -- vendor
	('i_tombolli@study_space.com', 'itombolli_vendor', '$2b$12$sm8yNymjyUq40vGxRkGhve0dvWvSN2eb0ENT4/QZUEkYRGVTHDXjy', 'Study', 'Space', 'vendor'), -- vendor
    ('f_craft@techtime.com', 'fcraft_vendor', '$2b$12$sm8yNymjyUq40vGxRkGhve0dvWvSN2eb0ENT4/QZUEkYRGVTHDXjy', 'Tech', 'Time', 'vendor'),
    ('c_simmons@worksmart.com', 'csimmons_vendor', '2b$12$sm8yNymjyUq40vGxRkGhve0dvWvSN2eb0ENT4/QZUEkYRGVTHDXjy', 'Work', 'Smart Co.', 'vendor'); 
    
INSERT INTO categories(cat_num, cat_name)
VALUES
-- school', 'office', 'textbook', 'furniture', 'technology'
	-- school / office
    (11, 'Writing Supplies'),
    (12, 'Notetaking'),
    (13, 'Folders & Filing'),
    (14, 'Bags, Lunchboxes, & Backpacks'),
    
	-- school
    (101, 'School Basics'),
    (102, 'Calculators'),
    (103, 'Art Supplies'),
    
    -- office
    (201, 'Office Basics'),
    (202, 'Paper & Mailing Supplies'),
    
    -- textbooks
    (301, 'Art Textbooks'),
    (302, 'Business & Economics Textbooks'),
    (303, 'Computer Textbooks'),
    (304, 'Design Textbooks'),
    (305, 'English Textbooks'),
    (306, 'Foreign Language Textbooks'),
    (307, 'Health & Fitness Textbooks'),
    (308, 'History Textbooks'),
    (309, 'Law Textbooks'),
    (310, 'Mathematics Textbooks'),
    (311, 'Medical Textbooks'),
    (312, 'Music Textbooks'),
    (313, 'Philosophy Textbooks'),
    (314, 'Photography Textbooks'),
    (315, 'Science Textbooks'),
    (316, 'Study Aids Textbooks'),
    (317, 'Tech & Engineering Textbooks'),
    
    (401, 'Batteries'),
    (402, 'Cables'),
    (403, 'Computers'),
    (404, 'Computer Accessories'),
    (405, 'Computer Monitors'),
    (406, 'Extension Cords'),
    (407, 'External Device Storage'),
    (408, 'Laptops'),
    (409, 'Printers, Scanners & Accessories'),
    
    -- furniture
    (501, 'Classroom Chairs'),
    (502, 'Classroom Desks'),
    (503, 'Classroom Mats & Rugs'),
    (504, 'Classroom Storage'),
    (505, 'Office Chairs'),
    (506, 'Office Desks'),
    (507, 'Office Storage'),
	(508, 'Office Mats & Rugs');
    
INSERT INTO products (vendor_id, product_title, product_description, warranty_months, cat_num)
VALUES

-- 11 writing supplies --
		-- 9000
	('c_simmons@worksmart.com', 'BIC Xtra-Smooth Mechanical Pencil, 0.7mm, #2 Medium Lead', 'BIC Xtra-Smooth Mechanical Pencils with lead are the perfect companion for your everyday writing needs. These good mechanical pencils feature a 0.7mm medium point, ideal for a variety of tasks, from jotting down notes to solving math problems. As the #1 selling mechanical pencil brand in the United States*, BIC pencils ensure consistent performance and quality you can trust. Each mechanical pencil comes with three pieces of No. 2 lead, making them suitable for standardized tests. The lead advances with a simple click of the built-in eraser, eliminating the need for sharpening and keeping your work neat and professional.', 0, 11),
		-- 9001
	('c_simmons@worksmart.com', 'BIC Xtra Smooth Pastel Edition Mechanical Pencil, 0.7mm, #2 Medium Lead', 'Enjoy smooth, dark writing with the durable BIC Xtra-Smooth mechanical pencils. With a fresh 0.7mm point only a click away, these No. 2 Bic mechanical pencils are perfect for standardized tests and eliminate the need to sharpen constantly, so you\'re always ready to write, draw, sketch, or doodle. The smooth-writing lead does not smudge and erases cleanly, and each pencil comes with three No. 2 leads, offering performance and value. These pencils are the perfect addition for your school or office supplies.', 0, 11),
		-- 9002
	('c_simmons@worksmart.com', 'Dixon Wooden Pencil, 2.2mm, #2 Soft Lead', 'Sketch out blueprints or make note of ideas with this pack of 144 No. 2 Dixon wooden soft pencils. Take notes or create sketched pictures with this pack of 144 soft No. 2 pencils. The commercial-grade wooden case delivers durability to the design, and the bonded lead prevents the tip from breaking in the middle of a sentence. These Dixon wooden soft pencils come in a pack of 144 to ensure you always have extras on hand.', 0, 11),
		-- 9003
	('g_pitts@supplies4school.org', 'Ticonderoga Pre-Sharpened Wooden Pencil, 2.2mm, #2 Soft Lead', 'Write down clear notes by hand with these Ticonderoga wood-cased pre-sharpened #2 pencils. Draw or write with these soft yellow-barrel pencils. The premium wood construction has a comfortable feel, while the graphite core formula offers smooth, consistent performance. Made with latex-free erasers, these Ticonderoga #2 pencils create neat, easy corrections.', 0, 11),
		-- 9004
	('g_pitts@supplies4school.org', 'Ticonderoga The World\'s Best Pencil Wooden Pencil, 2.2mm, #2 Soft Lead', 'Sketch and jot down notes with accuracy with this 12-pack of Dixon Ticonderoga wood-case #2 soft yellow-barrel pencils. Write easy-to-read notes with these Dixon Ticonderoga wood-case #2 soft, yellow-barrel pencils. These pencils are ideal for busy offices and classrooms, and the solid graphite core delivers a smooth performance and easy-to-read text. These Dixon Ticonderoga wood-case pencils have a latex-free eraser to make it easy to correct mistakes on paper.', 0, 11),
		-- 9005
	('g_pitts@supplies4school.org', 'BiC Round Stic Xtra Life Ballpoint Pens, Medium Point, 0.7mm', 'BIC Round Stic Xtra Life Black Ballpoint Pens are your go-to choice for reliable writing. These ball point pens feature a 1.0mm medium point, making them a great ballpoint pen for everyday use. The BIC Round Stic Pen writes 90% longer compared to PaperMate InkJoy 100 stick ball pens*, ensuring you have a pen that lasts. With a comfortable, flexible round barrel, these medium point pens provide a smooth and controlled writing experience. The translucent barrel lets you see the ink level, so you\'re not caught off guard. With a BIC Round Stic Pen handy, you\'ll be ready for any task.', 0, 11),
		-- 9006
	('c_simmons@worksmart.com', 'Pilot G2 Retractable Gel Pens, Fine Point, Medium Point, 0.7mm', 'Enjoy a smear-free writing experience by using these Pilot G2 fine-point premium retractable gel roller pens. Improve handwriting, create drawings and work on other projects by using these fine-point premium roller pens. With a convenient clip, these pens attach to binders, notebooks and pockets, while the contoured grip offers increased support, making it easy to take on lengthy writing tasks. These Pilot G2 gel pens feature a retractable design, so you can tuck the tips away when not in use, preventing unintentional marks to documents.', 0, 11),
		-- 9007
	('g_pitts@supplies4school.org', 'Pilot G2 Retractable Gel Pens, Fine Point, 0.7mm', 'Enjoy a smear-free writing experience by using these Pilot G2 fine-point premium retractable gel roller pens. Improve handwriting, create drawings and work on other projects by using these fine-point premium roller pens. With a convenient clip, these pens attach to binders, notebooks and pockets, while the contoured grip offers increased support, making it easy to take on lengthy writing tasks. These Pilot G2 gel pens feature a retractable design, so you can tuck the tips away when not in use, preventing unintentional marks to documents.', 0, 11),
		-- 9008
	('c_simmons@worksmart.com', 'Paper Mate 0.7mm Flair Felt Pens', 'Make solid strokes in vibrant colors with this 12-pack of Flair medium-point felt pens in assorted Tropical Vacation colors. Add color to your calendar and all your general writing tasks with ease with these Paper Mate medium-point pens in assorted colors. The metal-reinforced felt tip delivers smooth, thick lines using long-lasting, water-based ink that dries quickly to resist smudges. These felt pens feature a plastic construction that matches the ink color and a secure cap with a pocket clip to prevent dry out.', 0, 11),
		-- 9009
    ('c_simmons@worksmart.com', 'Sharpie Permanent Fine Tip Markers', 'Sharpie fine point permanent markers write smoothly on a variety of surfaces. Create a bold, vibrant impression on metal, glass, plastic or cloth with Sharpie permanent markers. The resilient, quick-drying ink is waterproof, smudge-proof and doesn\'t wear, so your text stays clear over time. Fine-point tips make these markers a pleasure to use by ensuring your writing is legible and uniform. An AP nontoxic certification makes these markers perfect for use around coworkers or children.', 0, 11),
		-- 9010
    ('g_pitts@supplies4school.org', 'Expo Dry Erase Starter Set', 'Create eye-catching white board presentations and dry-erase them easily with the Expo dr-erase starter set. Produce colorful whiteboard presentations with the﻿ black, red, green and blue markers in this starter set. The nontoxic markers are made using a low-odor formula and feature a chisel tip for fine or bold markings. The cleaner solution in this Expo dry-erase starter set removes any stubborn markings or smudges from whiteboard surfaces.', 0, 11),
		-- 9011
    ('g_pitts@supplies4school.org', 'Expo Dry Erase Kit', 'This Expo Dry-Erase Kit contains low-odor ink and is everything you\'ll need to give effective and colorful presentations. This low-odor whiteboard kit comes in a durable storage case and offers contemporary designs to fit any decor. This whiteboard marker set includes four fine point markers, eight chisel tip markers, an eraser and an 8 oz. bottle of cleaner.', 0, 11),
		-- 9012
    ('c_simmons@worksmart.com', 'Expo Dry Erase Markers', 'Organize ideas on the boardroom whiteboard with this 12-pack of Expo low-odor chisel tip dry-erase markers. Brainstorm new concepts with your team and these Expo dry-erase markers. The bold pens come in a pack of 12 assorted colors, so it\'s easy to list ideas or notate diagrams clearly and the low odor makes these markers ideal for closed areas such as classrooms and offices. Chisel tips on these quick-drying Expo dry-erase markers let you write with broad, medium and fine lines.', 0, 11),

-- 12 notetaking -- 
		-- 9013
	('g_pitts@supplies4school.org', 'APEX Spiral Notebook', 'APEX Spiral Notebooks feature 70 wide-ruled sheets, 1 subject, with 3-hole perforated sheets. Available as single notebook or in multi-packs.', 0, 12),
		-- 9014
    ('g_pitts@supplies4school.org', 'Post-It Super Sticky Notes 3" x 3"', "Post-it® Super Sticky Notes are the perfect solution for shopping lists, reminders, to-do lists, color-coding, labeling, family chore reminders, brainstorming, storyboarding, and quick notes. Post-it Super Sticky Notes offer twice the sticking power of basic sticky notes, ensuring they stay put and won't fall off.", 0, 12),
		-- 9015
    ('g_pitts@supplies4school.org', 'Post-It Flags Combo Pack', 'Find it fast with Post-it® Flags in bright eye-catching colors that get noticed. They make it simple to mark or highlight important information in textbooks, calendars, notebooks, planners and more. They stick securely, remove cleanly and come in a wide variety of colors. Draw attention to critical items or use them to index, file or color code your work, either at home, work or in the classroom.', 0, 12),

-- 13 folders & filing --
		-- 9016
    ('g_pitts@supplies4school.org', 'Post-It Durable Tabs', 'Durable Tabs are extra thick and strong to stand up to long-term wear and tear. Great for dividing notes, expanding files and project files. Sticks securely, removes cleanly.', 0, 13),

-- 14 bags, lunchboxes, & backpacks --
		-- 9017
	('c_simmons@worksmart.com', 'bentogo Modern Lunch Box', 'The Bentgo Modern lunch box gives healthy eating on the go a stylish makeover. Designed to turn heads in the office break room, the versatile three- or four-compartment bento-style lunch box features a contoured outer shell with a sleek matte finish, held tightly closed with a shiny metallic clip. Leak-resistant, the removable tray is microwave- and dishwasher-friendly, making eating and cleanup a breeze. Eating healthy has never looked so good.', 0, 14),
		-- 9018
    ('c_simmons@worksmart.com', 'bentogo Pop Lunch Box', 'Perfect for big kids and teens, the bentgo Pop leakproof lunch box livens up their lunchtime routine with its bright, bold colors, and stylish design. This microwave-safe bento box holds up to 5 cups of food, so it\'s two times bigger than bentgo kids\' lunch box. Your teen can enjoy an entire sandwich or a full entree, plus two sides, in the removable, three-compartment tray. Insert the optional divider to turn your three-compartment meal prep container into a four-compartment food container. The box is stylish, colorful, and leakproof, so they never have to worry about spills in their backpack or bag.', 0, 14),
		-- 9019
    ('g_pitts@supplies4school.org', 'JAM Paper Kraft Lunch Bags', 'Keep up to date with the zero-plastic trend and use these JAM Paper kraft paper small lunch bags. Each of these small bags is ideal for snacks, spices or arts and crafts materials, and they\'re constructed from 100 percent recycled materials and are biodegradable and recyclable. This pack of 25 JAM Paper kraft paper small lunch bags supplies you with meal packaging for a month, or use them in retail environments for an upmarket look.', 0, 14),
		-- 9020
	('g_pitts@supplies4school.org', 'JanSport Big Student Backpacks', 'The JanSport Big Student backpack is perfect for carrying all of your supplies. The backpack is made of 100% recycled polyester and features a dedicated 15" padded laptop compartment. Features two large main compartments, one front utility pocket with organizer, one pleated front stash pocket, and one zippered front stash pocket. Includes a side water bottle pocket, ergonomic S-curve shoulder straps, and a fully padded back panel.', 0, 14),
		-- 9021
	('g_pitts@supplies4school.org', 'JanSport Big Student Patterned Backpacks', 'The JanSport Big Student backpack is perfect for carrying all of your supplies. The backpack is made of 100% recycled polyester and features a dedicated 15" padded laptop compartment. Features two large main compartments, one front utility pocket with organizer, one pleated front stash pocket, and one zippered front stash pocket. Includes a side water bottle pocket, ergonomic S-curve shoulder straps,  and a fully padded back panel.', 0, 14),

-- 101 school basics --
		-- 9022
	('g_pitts@supplies4school.org', 'Fiskars Kids\' Scissors, Blunt Tip', 'Every child is a creative genius, and the only limit to their self-expression should be their wildest imaginations. The Fiskars blunt-tip kids\' scissors are thoughtfully designed for growing hands and creative minds. These scissors are great for children ages four and up, because every creative genius deserves the right scissors at the right age to express themselves. Safety-edge blades feature a safer blade angle and blunt tip for added safety when cutting classroom materials', 0, 101),
		-- 9023
	('g_pitts@supplies4school.org', 'Elmer\'s School Washable Removable Glue Sticks', 'Put together presentations, crafts, and other projects with this 30-pack of Elmer\'s all-purpose clear school glue sticks. Permanently bond items to paper, cardboard, foam board, display board, and more with the non-toxic adhesive of Elmer\'s All Purpose Glue Sticks. They are washable, acid-free, photo safe, and non-toxic', 0, 101),
		-- 9024
	('g_pitts@supplies4school.org', 'Westcott 12" Plastic Standard Ruler', 'Westcott standard rulers are made of sturdy plastic and come in assorted colors and measure up to 12". 0.06" imperial and standard 0.1cm metric scales. Measures up to 12" with extra margins at the ends for clear starts and stops. Includes holes for three-ring binders.', 0, 101),
		-- 9025
	('g_pitts@supplies4school.org', 'Barker Creek Self-adhesive Oh Hello! School Name Tags, 2.75" x 3.5"', "You'll find dozens of uses for these versatile name tags / self-adhesive labels from Barker Creek. Barker Creek’s Oh, hello! Name tags and self-adhesive labels are perfect for all ages! Package includes 90 multi-purpose self-adhesive name tags — 30 each of 3 designs. The designs feature a lovely navy color and say ‘Oh, Hello! My name is…’, ‘Hello! My name is…’, and ‘Hi there! My name is…’. There is also a box to write in your name. These name tags are perfect for the first week of school, field trips, assemblies, special visitors, staff meetings and more!", 0, 101),
		-- 9026
	('g_pitts@supplies4school.org', 'PURELL SINGLES Advanced 70% Alcohol Gel Hand Sanitizer', 'Help those you care for kill germs on the go with PURELL SINGLES® Advanced Hand Sanitizer Gel, also known as PURELL PERSONALS™ Advanced Hand Sanitizer Gel. Just bend the packet and squirt with one hand, for a fun and refreshing cleaning experience. Gives you the perfect amount of America\'s No. 1 brand hand sanitizer to kill 99.99% of most common germs that may cause illness – anywhere, anytime. With four unique skin conditioners, it’s gentle on hands. PURELL PERSONALS™ packets fit anywhere – pocket, wallet, car, cell phone case, your smallest bag – and the no-leak durable design means mess-free protection from germs.', 0, 101),
		-- 9027
	('g_pitts@supplies4school.org', 'CloroxPro Disinfecting Wipes, Fresh Scent', 'DISINFECTING WIPES: EPA registered to kill 99.9% of viruses and bacteria; Meets EPA criteria for use against SARS-CoV-2, the virus that causes COVID-19, on non-porous surfaces. VERSITILE CLEANING WIPE: Create clean public spaces with these wet wipes that breakdown grease, soap scum and grime so you can tackle messes on a variety of surfaces, bleach-free. ALL PURPOSE WIPE: Quickly sanitizes bacteria and kills most viruses in as little as 15 seconds; removes common allergens and deodorizes, preventing the odor causing bacteria for up to 24 hours. GREAT FOR COMMERCIAL USE: From CloroxPro™, ideal for use in offices, day care centers, schools, busy healthcare environments and other commercial facilities.', 0, 101),
    
-- 102 calculators --
		-- 9028 blue, pink, cyan
	('c_simmons@worksmart.com', 'Texas Instruments TI-30XIIS 10-Digit Scientific Battery & Solar Powered Scientific Calculator', 'Explore math and science concepts in the classroom or at home with this Texas Instruments scientific calculator. The calculator has a two-line display for optimal convenience and lets you edit, cut and paste entries to perform calculations faster. This versatile calculator is ideal for fraction features, conversions, basic scientific calculations and trigonometric functions to help in homework and other school tasks. The TI-30XIIS is solar and battery powered to ensure consistent use without worrying about power. This Texas Instruments scientific calculator has an impact-resistant cover with a quick-reference card for keeping notes, and the hard plastic, color-coded keys don\'t fade over time due to regular use.', 0, 102),
		-- 9029 light blue
	('c_simmons@worksmart.com', 'Texas Instruments MultiView TI-30XS 16 Digit Scientific Calculator', 'Find accurate solutions to complex equations with this Texas Instruments TI-30XS MultiView Scientific calculator. The MathPrint feature displays problems as they appear in textbooks, offering a more intuitive learning experience for students. A four-line display shows multiple calculations and lets you follow the steps needed to solve problems. This calculator includes options for scientific notations and tables, making it a smart option for use in high school and college math courses. Clearly labeled buttons along with cut, edit and paste functions delivers effortless navigation, while the solar power and battery combination ensures uninterrupted operation during tests or classroom lessons. This Texas Instruments TI-30XS MultiView Scientific calculator is approved for use with SAT, ACT and AP exams, providing you with a handy test-taking tool.', 0, 102),
		-- 9030
	('c_simmons@worksmart.com', 'Texas Instruments TI-30Xa 10-Digit Scientific Calculator', 'Find accurate solutions to complex problems with this Texas Instruments TI-30Xa scientific calculator. A one-line 10-digit display makes answers easy to see, while the color-coded keypad lets you find numbers and functions for effortless operation. The shift key provides access to advanced functions, letting you tackle pre-algebra, algebra, general science and trigonometry problems. Fraction conversion and decimal functions are perfect for solving basic math problems. This calculator comes with an impact-resistant cover, so it stands up to the rigors of everyday school use. Accepted for use in SAT, ACT and AP exams, this Texas Instruments TI-30Xa scientific calculator is an ideal option for junior high and high school students.', 0, 102),
		-- 9031
	('g_pitts@supplies4school.org', 'Texas Instruments TI-36X Pro 16-Digit Scientific Calculator', 'Complete your math and science tasks faster with this Texas Instruments scientific calculator. The versatile calculator features a MultiView four-line display to show multiple calculations at the same time, and built-in solvers provide quick solutions to linear equations and numeric equations. With an easy-to-use mode menu, you can easily access commands and format numbers with a few button clicks. This Texas Instruments scientific calculator lets you view (x,y) table of values by keying in specific X values, and it displays stacked fractions and math expressions exactly like in textbooks. Nonskid rubber feet prevent slipping on desks, and solar cell assistance helps to boost the battery life.', 0, 102),
    
-- 103 art supplies --
		-- paints
		-- 9032 assorted colors
	('g_pitts@supplies4school.org', 'Crayola® Classic Washable Watercolors', '2 oz. washable kids paint bottle set includes 10 non-toxic water-based paint that is great for arts, crafts, and school projects. The Crayola® non-toxic kids paint bottle set contains 10 non-toxic water-based paints that are great for arts, crafts and school projects. With this washable paint you can decorate book covers, signs or posters. It is suitable for use with various brushes, stamps or sponges to create interesting patterns as well as designs.', 0, 103),
		-- 9033 white
	('g_pitts@supplies4school.org', 'Crayola® Washable Paints', 'Crayola® Washable Paint combines vibrant color with easy washability. Children can express themselves freely because Crayola® Washable Paint cleans up with just soap and water. Washes easily from skin and most children\'s clothing. Non-toxic, AP Seal. Includes 128 ounces of 1 washable paint color. Ideal for early childhood. Washability you can trust. Non-toxic.', 0, 103),
		-- 9034
	('g_pitts@supplies4school.org', 'Crayola® Assorted Paint Set', 'Vivid colors wash easily from skin & most clothing! Makes painting worry free for teachers & parents! Features a creamy consistency for smooth laydown & brush flow. Assures consistent performance. Non-separating & freeze-thaw stable. Color(s): Assorted; Assortment: Black; Blue; Brown; Green; Magenta; Orange; Peach; Red; Turquoise; Violet; White; Yellow; Capacity (Volume): 16 oz; Packing Type: Bottle.', 0, 103),
		-- 9035
    ('g_pitts@supplies4school.org', 'Crayola® Washable Kids\' Paint Pots', 'Crayola® Kids poster paint-pot comes with a paint brush, sold as 18 per pack. Crayola® Kids poster paint-pot accommodates 3 oz paint. Pot is washable and is easy to clean, sold as 18 per pack. Set includes one paint brush. Equalss 3 fl. oz. of paint. Easy to clean up.', 0, 103),
		-- 9036
    ('g_pitts@supplies4school.org', 'Apple Barrel Acrylic Paint Matte', 'BRILLIANT COVERAGE- Use this acrylic paint kit on a variety of surfaces including wood, paper, canvas, Styrofoam, paper mache, and so much more. EASY CLEAN UP- Apple Barrel Acrylic Paint is a breeze to clean up making this kit a must-have to your art supplies. Simply clean up while wet with soap and water. White, Bright Yellow, Pink Parfait, Bright Red, Caribbean, Spring Green, Purple Iris, Black.', 0, 103),
    
    -- paintbrushes
		-- 9037
    ('g_pitts@supplies4school.org', 'Chenille Kraft® Creativity Street® Mixed Media Synthetic Nylon/Polyester Bristle', 'Basic brushes can be used for various types of paint. Plastic handles offering a sturdy grip. Small round black bristle brushes.', 0, 103),
		-- 9038
    ('g_pitts@supplies4school.org', 'Chenille Kraft® Creativity Street® Beginner Paint Brush', 'Beginner paintbrush set featuring hardwood handles and natural hog bristles. 12 round and 12 flat bristles in assorted sizes. Natural wood handles.', 0, 103),
		-- 9039
    ('g_pitts@supplies4school.org', 'Creativity Street® Acrylic Synthetic Bristle', 'Assorted paintbrush set. Translucent plastic handles with metal ferrules: orange, yellow, green, pink. Assorted sizes.', 0, 103),
		-- 9040
    ('g_pitts@supplies4school.org', 'Plaid Synthetic Taklon Round Brush Set', 'Paintbrush set for adding fine details to craft and decorative painting projects. Brushes feature gold synthetic bristles, gold brass ferrules, and ergonomic wood handles. Spotter 10/0; Liner 10/0, 1; Round 10/0, 0, 1, 3, 5; Flat 2, 4.', 0, 103),
    
    -- colored pencils
		-- 9041 pastel assorted, assorted 12packs
	('g_pitts@supplies4school.org', 'Crayola® Colored Pencils', 'From playroom to the classroom these pretty colored pencils are great for creative art projects and homework assignments. Each pack includes 12 assorted colors.', 0, 103),
		-- 9042 24pack
	('g_pitts@supplies4school.org', 'Crayola® Colors of the World Colored Pencils', 'Crayola® Colors of the World colored pencils contain 24 specially formulated colors representing people of the world. These skin-tone colored pencils are an exciting addition to your pencil collection at home or in the classroom, making coloring pages and drawings even more detailed and realistic. The subtle shades inside are formulated to better represent the growing diversity worldwide. Crayola® Colors of the World fall into three main shades: almond, golden, and rose – and all the darker or lighter shades in between. This pack includes 24 new pencil colors that represent people from around the world.', 0, 103),
		-- 9043 36pack, 100pack
	('g_pitts@supplies4school.org', 'Crayola® Colored Pencils', 'Fill in charts and graphs with these colored pencils. A fine tip creates precise lines for illustrations that require detail, and a thin barrel provides a comfortable grip for controlling the outcome. With an assortment of deep colors like brick red and cocoa, as well as soft colors, such as unmellow yellow and almond, these Crayola® colored lead pencils help bring ideas and presentations to life.', 0, 103),
		-- 9044 64pack kids(shorter)
	('g_pitts@supplies4school.org', 'Crayola® Kids\' Colored Pencil Set', 'Crayola® Short colored pencil set features re-usable flip-top box as well as tiered sleeves for easy access to pencils and is sold as 64 per pack. The thick, soft cores of Crayola® Mini Color Pencils won\'t break easily under pressure. They are perfect for coloring projects that require color mixing and blending, and the vibrant color choices in this 64 count set are perfect for coloring books and crafts. These 3-inch colored pencils are perfect for small hands, and arrive pre-sharpened and ready to fill all of your coloring needs. Ideal for school projects, coloring books, and crafts, the reusable storage box makes it easy to take this colored pencil set anywhere your creativity takes you. Plus there\'s a handy built-in sharpener for colorful creativity on the go.', 0, 103),
    
    -- crayons     -- CRAYONS REGULAR SIZE TO BE IN DB IS 3.6L" x 0.3W" each crayon
		-- 9045
	('g_pitts@supplies4school.org', 'Crayola® Classpack Crayons', 'Make teaching bold and captivating with this 800-count Crayola® Classpack of crayons. Enhance class projects with this Crayola® Classpack of crayons. With 50 sets of 16 colors, these crayons can meet all of your schoolroom entertainment and artistic needs. Vibrant hues and truer colors help develop your students\' creativity skills and open their imaginations. The original eight crayon colors are included, as well as, in-between hues like carnation pink and blue green. This Crayola® Classpack of crayons comes in a convenient, space-conscious container, making it easy for students to clean up after themselves.', 0, 103),
		-- 9046 assorted 24, metallic 24, pastel 24
	('g_pitts@supplies4school.org', 'Crayola® Crayons Assorted 24-Packs', 'Box of Twenty-Four Crayola Crayons- Create Vibrant Pictures. Brilliant colors and smooth color laydown. Reformulated colors provide more intense hues and truer colors. Easy blending without smudging. Convenient, reusable tuck box.', 0, 103),
		-- 9047 assorted 120pack
	('g_pitts@supplies4school.org', 'Crayola® Original Crayons', 'Burnt sienna, olive green, thistle--the nostalgic favorites are all here, along with new options like tickle me pink and laser lemon! Crayola 120-Count original crayon in assorted colors makes a perfect gift for home or the classroom. Crayon contains durable dump bin storage box with large color variety.', 0, 103),
		-- 9048 assorted 8pack
	('g_pitts@supplies4school.org', 'Crayola® Crayons', 'Coloring, crafts, and school projects are more fun with Crayola Crayons. This pack includes 8 classic colors and a reusable storage box that fits nicely in bookbags, pencil cases, and even pockets. The eight featured crayon colors include Red, Black, Blue, Green, Yellow, Orange, Purple, and Brown. Pair this crayon set with a new coloring book featuring your child\'s favorite characters for a delightful birthday or holiday gift idea. Crayola Crayons are a teacher preferred classroom essential, and are trusted by parents to be safe and nontoxic.', 0, 103),
		-- 9049 assorted large easy clean SIZE 4L" x 0.4W"
	('g_pitts@supplies4school.org', 'Crayola® Specialty Crayons', 'Crayola® Large washable crayons offer smooth as well as easier laydown and are sold as 8 assorted colors per box. Crayola® Large washable crayons can be wiped off from most nonporous surfaces with warm water and a sponge. Non-toxic crayons include black, blue, brown, green, orange, red, violet and yellow colors. AP certified nontoxic', 0, 103),
   
   -- origami paper
   -- 9050 18.59 40pack
	('g_pitts@supplies4school.org', 'Pacon Origami Paper', 'Lightweight origami paper comes in assorted bright colors. Instructions are included to make many folded shapes and designs. Assorted colors. Recommended for ages 6 and up.', 0, 103),
   
	-- crayola construction paper
		-- 9051 12" x 9" assorted variants: 96sheets 4.69 / 240sheets 11.69 / 96sh 12bulk pack 60.79 / 240sh 3bulk pack 33.29
	('g_pitts@supplies4school.org', 'Crayola 9" x 12" Construction Paper', 'Crayola Construction Paper is a must-have for home and school projects! These large paper packs include sheets of construction paper in standard 9x12 inch paper size. The thick, high quality sheets are perfect for coloring, cardmaking, crafting and more! Pair with a set of Crayola Crayons (sold separately) for a great bundled gift for kids.', 0, 103),
	-- crayola giant construction paper
		-- 9052 12" x 18" assorted variants: 48sheets 9.69 / 48sheets 6bulk pack 47.39
	('g_pitts@supplies4school.org', 'Crayola Project Giant 12" x 18" Construction Paper', 'Crayola construction paper is essential to creative fun. From simple homemade crafts to detailed art projects, it is perfect for a wide variety of uses. This pack includes 48 sheets of construction paper and one giant stencil with letters, numbers, and other useful designs with school projects in mind. The paper sheets are perfect for making posters with clear, bold visuals. Includes stencil for home crafts and school projects. Stencil sheet comes with letters, numbers, and other useful designs with school projects in mind.', 0, 103),
   
   -- prang construction paper
		-- 9053 9" x 12" assorted 500sheets 30.39
	('g_pitts@supplies4school.org', 'Prang 9" x 12" Construction Paper', 'Prang lightweight groundwood construction paper provides the best value in school grade construction paper with its bright and consistent colors, is slightly textured and cuts and folds evenly without cracking, making it the perfect solution for school projects and other arts & crafts. Bright colors, slightly textured, and cuts and folds evenly, Prang (Formerly Art Street) provides the best value in school grade construction paper.', 0, 103),
   
   -- coloring books --
		-- bluey coloring book
		-- 9054 12" x 18" 18 pages
	('g_pitts@supplies4school.org', 'Crayola Giant Coloring Pages - Bluey', 'CRAYOLA GIANT COLORING PAGES: Features 18 super-sized coloring pages for kids, featuring characters from Bluey! HUGE COLORING PAGES: Coloring pages are each 18 x 12" to give kids plenty of extra room to create! DISNEY BLUEY CHARACTERS: Kids will delight in themed coloring pages filled with their favorite characters from the Bluey TV show.', 0, 103),
    
		-- crayola limited edition retired colors coloring book
		-- 9055 8" x 10.75" 96 pages
	('g_pitts@supplies4school.org', 'Crayola Limited Edition Retired Crayola Colors Coloring Book', 'The moment Crayola collectors everywhere have been waiting for, iconic Retired Crayola Crayon Colors are back, but only for a limited time! Take a trip down memory lane with the Crayola Retired Crayon Colors Coloring Book featuring 96 pages of Retired Crayola Tip Character designs. Plus, there\'s even a sticker sheet, giving kids the chance to add onto their coloring pages or decorate wherever they choose! Ideal for kids, adult coloring enthusiasts, and Crayola collectors, this book inspires creativity and encourages imaginative thinking. Whether you\'re gifting it or enjoying it yourself, embrace the joy of coloring with 96 pages. The perfect activity for long car rides, rainy afternoons, and quiet days at the park, kids will delight in being able to bring this coloring set with them.', 0, 103),
   
		-- frozen 2 coloring book
		-- 9056 7.75" x 10.75" 64 pages
	('g_pitts@supplies4school.org', 'Bendon Frozen 2 Jumbo Coloring & Activity Book', 'Frozen 2 Coloring and Activity Book (2 Titles) - 1 book title chosen at random. Join Anna and Elsa on a coloring adventure with Bendon\'s Frozen 2 Jumbo Coloring and Activity Book! This coloring book is chock-full of activities, games, and puzzles featuring your child’s favorite characters! 64 pages of coloring and activity fun. Tear and Share® pages make showcasing your little artist’s masterpieces a snap. Artwork featuring your child’s favorite Frozen 2 characters. Officially licensed product. Ideal for ages 3 and up. 1 coloring book - title chosen at random.', 0, 103),
   
		-- paw patrol coloring book
		-- 9057 7.75" x 10.75" 64 pages
	('g_pitts@supplies4school.org', 'Bendon Paw Patrol Jumbo Coloring & Activity Book', 'Paw Patrol Jumbo Coloring & Activity Book. Join Chase, Marshall and Skye on a coloring adventure with Bendon\'s Paw Patrol Jumbo Coloring and Activity Book! This coloring book is chock-full of activities, games, and puzzles featuring your child’s favorite characters! 64 pages of coloring and activity fun. Tear and Share® pages make showcasing your little artist’s masterpieces a snap. Artwork featuring your child’s favorite Frozen 2 characters. Officially licensed product. Ideal for ages 3 and up.', 0, 103),
   
		-- despicable me 4 coloring book
		-- 9058 7.75" x 10.75" 64 pages
	('g_pitts@supplies4school.org', 'Bendon Despicable Me 4 Jumbo Coloring & Activity Book', 'Despicable Me 4 Jumbo Coloring and Activity Book. Join Gru and the Minions on a coloring adventure with Bendon\'s Descpicable Me 4 Jumbo Coloring and Activity Book! This coloring book is chock-full of activities, games, and puzzles featuring your child’s favorite characters! 64 pages of coloring and activity fun. Tear and Share® pages make showcasing your little artist’s masterpieces a snap. Artwork featuring your child’s favorite Frozen 2 characters. Officially licensed product. Ideal for ages 3 and up.', 0, 103),
   
		-- stickers --
		-- trend stinky stickers
		-- 9059 0.75" 648 count
	('g_pitts@supplies4school.org', 'Trend Stinky Scratch-and-Sniff Stickers', 'Bring on the smiles with this Trend Stinky Stickers scented smiles and stars jumbo variety pack. Give out fun incentives, collectibles, and rewards with this variety pack of stickers. This pack of stickers includes 648 0.75-inch scratch-and-sniff stickers shaped like smiles and stars. All of the stickers in this Trend Stinky Stickers jumbo variety pack are non-toxic, acid-free, and safe for photos.', 0, 103),
   
		-- Trend superShapes Stickers
		-- 9060 1300 count
	('g_pitts@supplies4school.org', 'Trend superShapes Stickers', 'Celebrate small achievements with these Trend superShapes stickers stars. Let students know they\'ve done a great job with these star stickers. The bright colors and hint of sparkle bring a fun finishing touch to graded handouts, reports, and other homework. Each of these Trend superShapes stickers features a self-adhesive backing to stay firmly in place on paper, folders and other classroom materials.', 0, 103),
   
		-- Trend superSpots & superShapes Awesome Assortment Stickers
		-- 9061 5100 count
	('g_pitts@supplies4school.org', 'Trend superSpots & superShapes Awesome Assortment Stickers', 'Keep students motivated with this Trend superSpots & superShapes Awesome Assortment sticker variety pack. Give handouts and homework fun grades with this Trend superSpots & superShapes sticker variety pack. Silly shapes and playful characters bring smiles to your students\' faces, and adhesive backings keep each sticker in place. This Trend superSpots & superShapes sticker variety pack contains 5,100 stickers.', 0, 103),
   
-- 201 office basics --
		-- mind reader 7-compartment desktop organizer
		-- 9062 -- Measuring 11 inches long by 5.5 inches wide by 5 inches tall (27.94 x 13.97 x 12.7 cm) and weighing only 1.43 lbs (0.65 kg),
	('c_simmons@worksmart.com', 'Mind Reader 7-Compartment Metal Desk Organizer File and Accessory Storage', 'Maximize Your Desk Space with a 7-Compartment Desktop Organizer. Boost your productivity and get organized with this sleek, functional desktop organizer. The metal mesh design adds a touch of style to your workspace while keeping all your supplies and accessories neatly in order. Featuring a minimalist design and seven compartments, this organizer is perfect for reducing desktop clutter, allowing you to focus more on your work. This compact organizer fits on nearly any desk without taking up valuable space. It includes a mail sorter, sticky note pad holder, pen and pencil basket, and a paperclip drawer, all designed to keep your important supplies within easy reach, saving you time and effort in locating these items.', 0, 201),
   
		-- Mind Reader Metal Pen and Accessory Holder Desk Organizer
		-- 9063
	('c_simmons@worksmart.com', 'Mind Reader Metal Pen and Accessory Holder Desk Organizer', 'Streamline your workspace with this set of metal mesh organizers. Designed to keep your desk neat, this set provides ample space for pens, pencils, highlighters, and other small accessories. Crafted from sturdy metal mesh, these organizers are durable enough for everyday use. Their modern mesh design adds a contemporary touch, seamlessly complementing any decor. This value-packed set includes multiple holders perfect for binder clips, staples, post-it notes, or any other accessories you need within reach. Versatile in use, these organizers can also store makeup accessories or kitchen items and utensils. Lightweight and portable, this set is ideal for both desktop and home use.', 0, 201),
   
		-- 9064 black
	('c_simmons@worksmart.com', 'Mind Reader 8-Compartment Metal Mesh Desk Organizer and Office Supplies', 'Perfect as a New Employee Starter Pack, setting up a home office, or for a new college student. Elevate your desk space with this versatile desktop organizer which includes essential office supplies. Crafted from durable metal mesh, this organizer has compartments that keep your office supplies organized and within reach. It features anti-slip grips at the base to ensure it stays firmly in place. The back compartment has ample space for documents, files, and folders, ensuring your important paperwork is organized and accessible. The front is equipped with seven compartments, offering a neat solution for storing small office items like pens, pencils, paper clips, stapler and stapler remover, all within easy view and reach.', 0, 201),
   
		-- hole punchers --
		-- 9065 black
	('c_simmons@worksmart.com', 'Bostitch Electric Desktop Rectangle 3-Hole Punch', 'Cleanly punch up to 20 sheets of 20lb paper with this dual loading electric or battery operated 3 hole punch. Paper can be loaded horizontally or vertically for ultimate convenience. It\'s compact modern design accentuates any desktop, and adjustable paper guide makes for easy customization. Easy clean chip drawer helps to maintain a spotless work environment. Precision steel punch heads. Use 6 AA batteries when operating on battery power. Three hole punch. Manufacturer\'s limited seven year warranty. Black.', 84, 201),
 
		-- 9066 light grey
	('c_simmons@worksmart.com', 'Bostitch EZ Squeeze One-Hole Punch', 'Paperwork can be a hassle, but hole punching it shouldn\'t be. With this Bostitch one-hole punch featuring PaperPro technology, experience 50% easier, jam-free punching when you need it most. The curved, lightweight non-slip grip handles provide optimal comfort--ideal for frequent single hole punch users. Efficiently built into the handle is a chip waste chamber that easily empties through a door. Handles also lock closed for compact storage in drawers, bags, or a craft box. With smooth, curved ergonomic handles, conquer paper stacks with unprecedented ease.', 0, 201),
   
		-- rubber bands --
		-- 9067 0.13W" 50pack assorted
	('c_simmons@worksmart.com', 'Alliance Rubber Brites Multi-Purpose Rubber Bands', 'Organize office supplies, color coordinate project files and keep boxes sealed with these Alliance Brites rubber file bands. Secure files, stationery, writing utensils or other items with these rubber bands. This pack includes 50 assorted-color Alliance Brites rubber bands, which are easy to stretch and reuse.', 0, 201),
   
		-- 9068 0.13W" x 7L" 50 pack assorted 
	('c_simmons@worksmart.com', 'Alliance Rubber Reusable Solutions Multi-Purpose #117B Rubber Bands', 'Use these Alliance Rubber Reusable Solutions file bands to easily keep papers separated and neat. Organize work or home spaces with these rubber bands that help you keep papers, folders and other items bundled. These rubber bands come in several colors and are ideal for setting up a color-coding system for documents. Store unused bands in the resealable bag to contain these Alliance Rubber Reusable Solutions file bands.', 0, 201),
   
-- 202 paper & mailing --
		-- 9069 hammerhill copy paper letter
	('g_pitts@supplies4school.org', 'Hammermill Copy Plus 8.5" x 11" US Letter Copy Paper', 'The Hammermill Copy Plus paper is an economical product that\'s perfect for everyday printing and copying. This versatile paper is great for all types of black and white documents, copies, and printouts. The Hammermill Copy Plus paper is designed to run in all office equipment.', 0, 202),
    
		-- 9070 hammerhill copy paper legal
	('g_pitts@supplies4school.org', 'Hammermill Copy Plus 8.5" x 14" Legal Copy Paper', 'The Hammermill Copy Plus paper is an economical product that\'s perfect for everyday printing and copying. This versatile paper is great for all types of black and white documents, copies, and printouts. The Hammermill Copy Plus paper is designed to run in all office equipment.', 0, 202),
    
		-- 9071 hammerhill copy paper A4
	('g_pitts@supplies4school.org', 'Hammermill Copy Plus 8.27" x 11.69" A4 Copy Paper', 'The Hammermill Copy Plus paper is an economical product that\'s perfect for everyday printing and copying. This versatile paper is great for all types of black and white documents, copies, and printouts. The Hammermill Copy Plus paper is designed to run in all office equipment.', 0, 202),

-- 401 batteries --
-- 402 cables --
-- 403 computers --
	-- 9072
	('f_craft@techtime.com', 'HP Elite SFF 600 G9 Desktop Computer', 'The HP Elite 600 SFF Desktop PC delivers uncompromising performance, expandability, and reliability in a space-saving design. Equipped with the Intel Core i5-13500 processor, 16GB RAM, 256GB SSD, and Windows 11 Pro, this is the right PC for big jobs performed in smaller workspaces. Future proof your fleet with multiple drives and configurable ports that provide expandability. The HP Elite 600 SFF utilizes HP Run Quiet Design that finely tunes the fans to keep systems running quiet and cool. At least 60 percent of all plastic used in this PC is post-consumer recycled plastic. Rest easy with a PC that undergoes hours of HP\'s Total Test Process and MIL-STD 810 testing.', 24, 403),
    -- 9073
    ('f_craft@techtime.com', 'HP Elite Tower 600 G9 Desktop Computer', 'The HP Elite 600 Tower Desktop PC delivers uncompromising performance, expandability, and reliability in a space-saving design. Equipped with the Intel Core i5-13500, 16GB RAM, 256GB SSD, and Windows 11 Pro, this is the right PC for big jobs performed in smaller workspaces. Future proof your fleet with multiple drives and configurable ports that provide expandability. The HP Elite 600 Tower utilizes HP Run Quiet Design that finely tunes the fans to keep systems running quiet and cool. At least 60 percent of all plastic used in this PC is post-consumer recycled plastic. Rest easy with a PC that undergoes hours of HP\'s Total Test Process and MIL-STD 810 testing.', 24, 403),
-- 404 computer accessories --
	-- logitech mk540 black
	-- 9074
    ('f_craft@techtime.com', 'Logitech MK540 Advanced Wireless Keyboard and Mouse Combo', 'MK540 Advanced is an instantly familiar wireless keyboard and mouse combo built for precision, comfort and reliability. The full-size keyboard features a familiar key shape, size, and feeling – optimized for precision and noise reduction. The palm rest and adjustable tilt legs keep you comfortable for long stretches and the contoured mouse is designed to fit perfectly into either palm. Plug and play your keyboard and mouse with one tiny USB receiver with Logitech Unifying™ technology. You’ll get a reliable – and encrypted – wireless connection up to 10 meters away with virtually no delays or dropouts. Your keyboard won’t require new batteries for 36 months and your mouse stays powered for 18 months.', 18, 404),
    -- 9075 -- delton n35 silver
    ('f_craft@techtime.com', 'Delton N35 Mini Wireless Keyboard and Optical Mouse Combo', 'Streamline your workflow with outstanding versatility and comfort using this compact and slim wireless keyboard and mouse combo from Delton allowing effortless portability. Compatible with Windows, macOS, iOS, Linux, Android and more, the keyboard and mouse combo offers Bluetooth and 2.4GHz auto-pair USB dongle options for steadfast wireless connectivity. Navigate with ease using the 12 multimedia function keys, and enjoy the liberty of a 30\' range. Featuring a slim and compact design, this small wireless mouse and keyboard combo is great for small desks, offices and homes, enhancing modern spaces efficiently. The cordless mouse boasts three dpi settings for personalized precision and a smooth scrolling, all while offering up to 15 months of long-lasting battery life.', 12, 404),
    -- 9076 -- delton kb250/s38 black
    ('f_craft@techtime.com', 'Delton KB250/S38 Wired Ergonomic Keyboard and Optical Mouse Combo', 'Experience ultimate comfort and productivity with Delton\'s ergonomic keyboard and mouse bundle. The wired computer keyboard features a plush wrist rest that enhances typing posture and prevents fatigue during long typing sessions. The vertical mouse with an optical sensor ensures smooth, accurate movement, making it perfect for work or play. Our ergonomic mouse and keyboard provide a quiet, distraction-free experience. The split keyboard features USB-A powered connectivity with a 4.9ft long cable, ensuring a reliable and flexible setup across various devices. Recommended by rheumatologists, the ergonomic mouse and keyboard offer long-term hand and wrist comfort.', 18, 404),
    -- 9077 -- logitech g435 black
    ('f_craft@techtime.com', 'Logitech G435 LIGHTSPEED Bluetooth Over-the-Ear Gaming Headset', 'Logitech G435 LIGHTSPEED wireless and low-lag Bluetooth connectivity lets you play and talk on PC, Mac, PS5/PS4, smartphones, and other Bluetooth audio-enabled devices. Gaming-grade sound, carefully balanced high-fidelity audio, 40mm audio drivers and compatibility with Dolby Atmos, Tempest 3D AudioTech, and Windows Sonic provide ultimate surround sound for all of your gaming adventures.', 12, 404),
    -- 9078 -- delton k130 black
    ('f_craft@techtime.com', 'Delton K130 Wireless Noise Canceling Bluetooth Computer Earbud Headset', 'The Delton K130 computer headset is a perfect companion for productivity and seamless communication. With an impressive battery life of up to 12 hours of continuous use and an additional 72 hours available through the charging case, the K130 is always available when you need it to be. With three differently sized soft cushions to fit the wearer\'s comfort, a crystal clear noise-canceling mic, and outstanding sound quality, it\'s the perfect headset for any executive. Setup is a breeze with the included auto-pair USB dongle: just plug in, and you\'re good to go.', 18, 404),
    -- 9079 -- logitech astro a50
    ('f_craft@techtime.com', 'Logitech Astro A50 Gen 5 Wireless Noise Canceling Bluetooth Dolby Digital Gaming Headset', 'Whether you prefer playing on PC, Xbox Series X|S, or PlayStation 5 console, the black A50 Gen 5 Wireless Gaming Headset from Astro Gaming has you covered. Seamlessly switch between up to three USB-C connected devices at the press of a button and enjoy clear audio as you battle opponents and coordinate with teammates. True Color Black finish with an ergonomic and lightweight design. Wired Connector Type USB Type-C (for charging only). Microphone & Headset Technology Flip-to-mute unidirectional microphone with noise-canceling technology. Power Source Rechargeable battery with up to 24 hours of playtime. Includes a 2-year limited warranty.', 24, 404),
    -- 9080 -- logitech brio 100 2 variants black and white
    ('f_craft@techtime.com', 'Logitech Brio 100 Full HD 1080p Webcam', 'Look, sound, and meet better with the Logitech Brio 100, a simple and affordable webcam that lets you show your best self in video calls. Full HD (1080p) resolution and auto-light balance bring clarity and brightness to your calls, so you look your best. Sound better with a built-in microphone, and get total privacy with an integrated shutter. The Brio 100 comes in fun, sophisticated colors that let you express yourself at your workspace. Made with a minimum of 34% recycled plastic.', 12, 404),
    -- 9081 -- logitech c920s black
    ('f_craft@techtime.com', 'Logitech C920S Pro 1080p HD Webcam', 'Logitech C920s is a budget-friendly, work-from-anywhere webcam that delivers a professional video meeting experience. It includes features designed to make you look and sound great in your next meeting. A 78º diagonal field of view perfectly frames you and your space, while autofocus adjusts smoothly and precisely. RightLight 2 technology automatically adjusts to your lighting situation even in low-light or backlit conditions. And dual integrated mics accurately capture your voice from multiple angles for greater nuance. If you’re streaming or recording, use Logitech’s Capture app to edit and customize. Flip down the lens cover at any point to protect your privacy.', 12, 404),
    -- 9082 -- mind reader monitory stand 2pack 20 inches long x 11.5 inches wide x 5.5 inches tall
    ('f_craft@techtime.com', 'Mind Reader Monitor Stand with Paper Tray, Up to 24" Monitor', 'Work comfortably and elevate your productivity with our dual monitor stand and desktop organizer combo. Tailored to raise your monitor, laptop, or tablet to an optimal height, this stand ensures a better viewing angle and places your body in a more ergonomic position, reducing strain and discomfort in your neck and shoulders over extended periods. Enjoy the benefits of a tidier workspace with this combination of monitor stand and organizer. The stand features two side storage compartments, perfect for easy access to your pens, markers, and various office essentials. Clear up the clutter from your desk by placing papers and files in the lower tier and slide your keyboard underneath the stand when not in use. Enhance your workspace with this sleek, metal mesh monitor stand.', 0, 404),
    -- 9083 -- mind reader adjustable dual stand black 51.25 inches in length, 9.25 inches in width, and 4.75 inches in height 
    ('f_craft@techtime.com', 'Mind Reader Adjustable Dual Monitor Stand, Up to 44 lbs.', 'Enhance your workspace ergonomics with this adjustable length monitor riser, designed to lessen eye and back strain by elevating your monitor or laptop to an optimal viewing level. The riser offers versatility with its flexible configurations, giving you the freedom to extend either side up to a total of 36 inches or leave them unextended to suit different spatial arrangements. Made from robust MDF, this monitor riser can securely support one or two monitors, up to a total weight of 44 lbs. (20kg). Measuring up to an adjustable 51.25 inches in length, 9.25 inches in width, and 4.75 inches in height, it\'s an invaluable addition to home offices, professional workplaces, dorm rooms, TV or family rooms, and even classrooms.', 0, 404),
    -- 9084 -- Mount-It! 2-Tier Monitor Stand, Up to 32" 5.67"H x 16"W x 11.18"D dark grey
    ('f_craft@techtime.com', 'Mount-It! 2-Tier Monitor Stand, Up to 32"', 'The Mount-It! MI-7361 slim metal riser will create a more ergonomic workspace with its extra shelf. Create more desk space by storing office essentials under the riser. The legs feature silicone pads that will protect your work surface from scratches. The sturdy stand can hold up to 44 lbs. Supports up to 32" monitors for versatile use. Features an extra shelf for your keyboard or office supplies. Ergonomic airflow design will look modern and minimal anywhere.', 36, 404),

-- 405 computer monitors --
	-- 9085 -- ViewSonic 100 Hz LED Monitor 2 variants 22" and 24" width $79.99-99.99
    ('f_craft@techtime.com', 'ViewSonic 100 Hz LED Monitor', 'With flexible connectivity, wide-angle viewing, and amazing screen performance, the ViewSonic VA2247-MH delivers solid multimedia features and a sleek design at a great value. Featuring frameless MVA panel technology, the VA2247-MH delivers stunning brightness and contrast at nearly any viewing angle. A minimalistic design, edge-to-edge screen, and frameless bezel make this an ideal monitor for nearly seamless multi-screen setups. Whether for working at the office, or enjoying entertainment at home, this ViewSonic monitor also features an HDMI port for flexible connectivity to PCs, laptops, gaming consoles, and HDMI cable is included in every box. In addition, a 3-year limited warranty, along with one of the industry\'s best pixel performance policies, makes the VA2247-MH a great overall value choice.', 36, 405),
    -- 9086 -- lg ips 100hx fhd lcd monitor
    ('f_craft@techtime.com', 'LG 24" IPS 100Hz FHD LCD Monitor with AMD FreeSync Technology', 'The LG 24BR400-B 24" IPS FHD Monitor features a 24" Full HD IPS display that delivers true color accuracy and wide viewing angles. It includes AMD FreeSync™ technology for smooth gaming, a 100Hz refresh rate for crisp visuals, and Black Stabilizer to enhance visibility in dark scenes. Additionally, it offers Reader Mode and Flicker Safe to reduce eye strain, making it a versatile choice for both work and play.', 36, 405),

-- 406 extension cords --
	-- 9087 -- next technologies 6-outlet surge protector 2 variants 1pack 8' cord white and 2pack 2.5' cord white
    ('c_simmons@worksmart.com', 'NXT Technologies™ 6-Outlet Surge Protector', 'Power up and protect appliances and electronics with this slim NXT Technologies™ six-outlet surge protector. Protect electronic equipment from dangerous power bursts with this surge protector. Use the convenient switch for one-touch on/off operation. Take advantage of this NXT Technologies™ six-outlets to provide up to 900 joules of surge protection for digital devices and their data.', 0, 406),
    -- 9088 -- next technologies 2-outlet plus usb surge protector black $31.79
    ('c_simmons@worksmart.com', 'NXT Technologies™ 2-Outlet Plus USB Surge Protector, 5\' Cord', 'Elevate your conference room power capability: introducing this NXT Technologies mini conference room surge protector with two outlets, two USB Type-A (2.4A), and one USB Type-C (15W) ports. Experience seamless power and connectivity in your mini conference room with this mini conference room surge protector. This NXT Technologies compact powerhouse features two outlets, two USB Type-A ports with 2.4A charging capacity, and one USB Type-C port with 15W charging capability. Stay plugged in and charged up as you connect and collaborate effortlessly. With its sleek design and versatile functionality, this NXT Technologies surge protector with two outlets, two USB Type-A (2.4A) ports, and one USB Type-C (15W) port is a must-have for productive meetings and efficient device management.', 0, 406),
    
-- 407 external storage devices --
	-- 9089 -- seagate 1tb drive black $73.69
	('c_simmons@worksmart.com', 'Seagate 1TB External USB 3.0 Portable Hard Drive, Black', 'Simple, compact, and PC-compatible, the Seagate portable drive gives you additional on-the-go storage and lets you take along large files when you travel. Setup for the PC is simple and straightforward; simply connect a single USB cable, and you are ready to go. The drive is powered via USB cable, so there is no need for an external power supply. Just connect and take advantage of the fast data transfer speeds with the USB 3.0 interface by connecting to a SuperSpeed USB 3.0 port.', 12, 407),
    -- 9090 -- seagate 4tb drive black $129.99
    ('f_craft@techtime.com', 'Seagate One Touch 4TB External Hard Drive Portable HDD USB 3.0 / USB 2.0, Black', 'Offering up to 4TB of expansive capacity and an array of color choices, Backup Plus Portable complements daily life by making room for digital life. Up to 4TB of massive capacity portable external hard drive for file backup. Compatible with USB 3.0/2.0. Works with Windows and Mac without needing to reformat. Offers customized backup and file mirroring. Powered by USB connection. 2 Year Limited Warranty', 24, 407),
    -- centon datastick pro usb 2.0 flash drive grey
    -- multiple variants:
		-- grey 8gb 10count
        -- grey 8gb 25count
        -- grey 16gb 10 count
        -- grey 16gb 25 count
        -- grey 32gb 10count
        -- grey 32gb 25count
        -- grey 64gb 10count
        -- grey 64gb 25count
    -- 9091
    ('f_craft@techtime.com', 'Centon DataStick Pro USB 2.0 Type A Flash Drive', 'Keep important files within arm\'s reach by using Centon DataStick Pro USB Flash Drives. These flash drives let you store and access files quickly with USB 2.0 interfaces and easily accommodate large numbers of files and records. These Centon DataStick Pro flash drives have sturdy aluminum housings for lasting durability. The Centon Flash Drives are made with a strong aluminum casing and sports and elegant grey color.', 60, 407),
-- 408 laptops --
    -- 9092
    ('f_craft@techtime.com', 'HP 25OR G9 15.6" Laptop', 'The HP 250R G9 laptop provides essential business-ready features in a thin and light design that\'s easy to take everywhere you go. The powerful Intel processor, fast memory and storage, and big screen-to-body ratio on a 15.6" display is key for productivity, while the included ports connect your peripherals, all at a price you can value. Features a 1.2GHz Intel Core i3-1315U hexa-core processor, with up to 4.5GHz speed and 10MB L3 cache memory. 512GB SSD Capacity. HP Long Life three-cell, 41Wh Li-ion polymer battery with a runtime of up to 12 hours.', 0, 408),
    
    -- 9093
    ('f_craft@techtime.com', 'HP 255 G10 15.6" Laptop', 'The HP 255 G10 laptop provides essential business-ready features in a thin and light design that\'s easy to take everywhere you go. The 15.6" diagonal display with 85% screen-to-body ratio, robust AMD Ryzen processor, fast memory, and storage is powered for productivity, while the included ports connect your peripherals, all at a price you can value. Features a 2GHz AMD Ryzen 7 7730U octa-core processor, with up to 4.5GHz and 16MB cache memory. 512GB SSD Capacity. HP Long Life three-cell, 41Wh Li-ion polymer battery with a runtime of up to 12 hours.', 0, 408),
   
-- 409 printers, scanners, & accessories --
    -- 9094
    ('f_craft@techtime.com', 'HP OfficeJet Pro Wireless Color All-In-One Printers', "FROM AMERICA'S MOST TRUSTED PRINTER BRAND – The OfficeJet Pro Printers are perfect for offices printing professional-quality color documents like presentations, brochures and flyers. The HP OfficeJet Pro Printers deliver fast color printing. They include wireless and printer security capabilities to keep your multifunction printers up to date and secure. Compatible ink cartridges – works with HP 936 ink cartridges to deliver bold, high quality color. Plus, get 2X more pages with the HP EvoMore 936e high yield ink cartridges, HP's most sustainable ink cartridges.", 12, 409),
    -- 9095
    ('f_craft@techtime.com', 'HP 936 Ink Cartridges', 'Ensure your printing is right the first time and every time with HP 936 Ink Cartridges, which provide precision output so you can take pride in fade-resistant documents and brilliant images. HP 936 cartridges work with: HP OfficeJet 9122e, HP OfficeJet Pro 9110b, 9125e, 9128e, 9130b, 9135e, HP OfficeJet Pro Wide Format 9730e. Cartridges yeild approx 1,250 pages for black ink, or approx. 800 pages with magenta, yellow, or cyan ink.', 0, 409),
	-- 9096
    ('f_craft@techtime.com', 'Canon MegaTank MAXIFY GX Series Printers', "Designed for small- and medium‐size businesses, the Canon MegaTank MAXIFY GX Series Printers balance speedy performance and minimal maintenance. The maintenance cartridges in the MAXIFY GX Series Printers are easily replaceable should the need arise. No service visit calls required. With a four-color pigment ink system, you'll get crisp color and black-and-white documents, along with sharp highlighter-resistant text. Create and print professional posters, banners, and signage with the PosterArtist online version.", 24, 409),
	-- 9097
    ('f_craft@techtime.com', 'Canon 26 High Yield Ink Bottle', 'The Canon ink refill produces superior quality for a wide array of printing needs. Features an easy-to-use no-squeeze bottle design. 132mL capacity. Compatible with: GX3020, GX4020, & GX5020 printers. Prints up to 6000 pages with black ink bottle, up to 14000 with magenta, yellow, or cyan ink bottle.', 0, 409),
    
-- furniture 500s category --
-- 500s classroom -- 
	-- 9098 -- stack chair 20-3/4" L x 19" W x 31" H black, grey, navy
	('i_tombolli@study_space.com', '18" Stack Chair with Swivel Glides', 'Perfect for any classroom space, the innovative School Stack Chairs are built for comfort and durability. Each chair features a molded seat with vented back for comfort, reinforced ribbing behind and under the seat for added strength, and steel lower back support. Don\'t worry about hair or clothes getting caught — our no-snag design ensures screws and other hardware don\'t poke through the seat. Chairs are easy to wipe clean and sanitize at the end of the day. Colors may vary.', 24, 501),
    -- 9099
    ('i_tombolli@study_space.com', '16" Stack Chair with Ball Glides', 'Perfect for any early childhood space, these innovative Stack Chairs with Ball Glides are built for comfort and durability. Each chair features a molded seat with a vented back for comfort, reinforced ribbing behind and under the seat for added strength, and steel lower back support. Don\'t worry about hair or clothes getting caught - our no-snag design ensures screws and other hardware don\'t poke through the seat. These easy-to-clean chairs stack on top of each other for convenient storage in classrooms, daycares, homeschools, recreation centers, and more.', 24, 501),
    -- 9100
    ('i_tombolli@study_space.com', 'Jonti-Craft™ Single 18” Stacking Chairs with Chrome Legs ', 'Child-friendly design promotes seating comfort, durability and attractive styling. Made of heavy-gauge steel with polypropylene seat. Chairs match Rainbow Accents® furniture. Nylon glides reduce noise. Non-exposed rivets prevent snags. 5-year warranty', 60, 501),
    -- 9101
    ('i_tombolli@study_space.com', '10" Stack Chair with Ball Glides, 4-Piece - Light Gray/Navy/Sand/Seafoam', 'Perfect for any classroom space, the innovative School Stack Chairs are built for comfort and durability. Each chair features a molded seat with vented back for comfort, reinforced ribbing behind and under the seat for added strength, and steel lower back support. Don\'t worry about hair or clothes getting caught — our no-snag design ensures screws and other hardware don\'t poke through the seat. Chairs are easy to wipe clean and sanitize at the end of the day. Colors may vary.', 24, 501),
    -- 9102
    ('i_tombolli@study_space.com', 'SoftScape Dew Drop Bean Bag', 'The SoftScape Dew Drop Bean Bag is the perfect place to snuggle in and read or watch a movie. Designed so you can sit with your torso more upright with the unique extended shape, this will quickly become your favorite seat when situated properly. Taller than a Classic round bean bag with a narrower top, the dew drop shape allows you to sit on the floor with a backrest. filled with shape-retaining foam beads that form to body contours then re-expand back to their original shape for a comfy seat every time. The soft, leather-like cover features double-stitched seams for durability and two locking zippers to keep beads safely inside. Perfect for home, dorms, recreation centers, libraries, and classrooms.', 0, 501),
    -- 9103
	('i_tombolli@study_space.com', 'SoftScape 15" Square Floor Cushions, 6-Piece - Contemporary', 'Cozy floor cushions that are easy to carry to your favorite spot! SoftScape Floor Cushions are a comfortable way to implement flexible seating into any environment. Each cushion in the pack features sewn-in handles and 2" of dense foam. Perfect for circling up on the floor for stories, snacks, playing games or just hanging out! The soft, colorful polyurethane material is durable and easy to maintain - just wipe clean with mild soap and water solution. Non-slip base keep the cushions in place during use. Recommended for children ages 2 years and older.', 0, 501),
	-- 9104
    ('i_tombolli@study_space.com', '48" Round Table, Gray/Assorted', 'Ideal for use in classrooms, playrooms, churches, recreational centers, and at home, T-Mold Adjustable Activity Tables with Standard Legs provide a durable, versatile space for kids to work and play. This 48" round table with adjustable legs provides a durable, versatile space to work and play in classrooms, daycares, homes, churches and more. Standard table legs adjust in 1" increments for table top heights from 19" to 30" to accommodate children, teens, and adults', 12, 502),
    -- 9105
    ('i_tombolli@study_space.com', '18" x 30" Trapezoid Table - Gray/Blue', 'Ideal for use in classrooms, playrooms, churches, recreational centers, and at home, T-Mold Adjustable Activity Tables with Standard Legs provide a durable, versatile space for kids to work and play. The laminate table top is easy to clean and sanitize between activities and features a t-molding edge band that protects from everyday wear and tear. Table legs adjust in 1-inch increments to accommodate growing children and for use with different age groups. Complementary School Stack Chairs and Contour Chairs sold separately.', 12, 502),
-- 502 classroom mats & rugs --
    -- 9106
    ('i_tombolli@study_space.com', 'Carpets for Kids® Sunny Day Learn and Play 4\'5" x 5\'10" Oval Premium Carpet', 'This exciting alpha/numeric rug provides a colorful circle time theme for all activities. Manufactured with the finest commercial grade premium nylon. Finished with bound, double-stitched serged edges to withstand any childhood environment. Meets Class 1 fire code requirements. KIDply® backing. Carpet Guard stain protection. Lifetime anti-bacterial treatment', 24, 503),
    -- 9107 -- two variants multicolor 4'x6' and 6'x9'
    ('i_tombolli@study_space.com', 'Carpets for Kids® Honeycomb Pattern Rectangle Pixel Perfect Carpet', 'Soothing cool colors with a honeycomb pattern will add a comforting and calming soft area to any room. Innovative technology prints photo real images onto the carpet, giving the rug more depth of color and crisp realistic images. The soothing shades of blue in this rug create a relaxed and comfortable feel for classrooms, daycares, and playrooms. True Stain Blocker Technology makes clean up a cinch using only hot water extraction with no harsh chemicals, leaving a safe area for children to learn and play. Designed to handle the wear and tear of early childhood spaces. Rug features KIDply backing to help prevent wrinkling and creasing.', 24, 503),
    -- 9108 -- two variants multicolor 4'x6' and 6'x9'
    ('i_tombolli@study_space.com', 'Animal Sounds Rectangle KidSoft Premium Carpet', 'Bow wow! This vibrant carpet features 13 playful animals and introduces the sounds they make. Perfect for any toddler room or center. KIDPly® backing. Lifetime antimicrobial protection. Carpet stain protection. Lifetime anti-static fiber. Assists in allergen particle control. Class 1 Firecode rating.', 24, 503),
-- 504 class storage --
	-- 9109	-- 48"W x 15"D x 36"H maple? light wood $79999
    ('i_tombolli@study_space.com', 'Environments® Mobile Multi Section Storage Unit - Assembled', 'This versatile unit is mobile, modern, and designed to meet the learning needs of Gen. A kids. It’s the perfect piece of furniture for creating unique and memorable tinker zones or makerspaces. Providing kids with hands-on STEM learning projects will help develop fine motor and problem-solving skills. This unit’s flexibility will keep spaces current as learning needs evolve. It’s guaranteed to weather years of rigorous use. This unit arrives pre-assembled.', 12, 504),
	-- 9110	-- 48"W x 15"D x 43"H light wood 72599
    ('i_tombolli@study_space.com', 'Environments® Mobile 12-Section Cubby Storage - Assembled', 'Our Mobile 12-Section Cubby Storage Unit is designed to modernize today’s learning environments. Use it to create different flex spaces geared towards igniting imagination, STEM learning, problem-solving, or the development of fine motor skills. It’s guaranteed to weather years of rigorous use. This unit arrives pre-assembled.', 12, 504),
	-- 9111	-- 20"W x 15"D x 36"H light wood 44999
    ('i_tombolli@study_space.com', 'Environments® Mobile 10-Section Cubby Storage - Assembled', 'The future of storage solutions is here. We reimagined our line of furniture to meet the learning needs of today’s Gen. A kid. This versatile, mobile, cubby unit will modernize the landscape of kids’ spaces in homes or classrooms. It features 10 cubbies, each measuring 9"W x 6"H. It’s guaranteed to stand up to years of rigorous use.', 12, 504),
	-- 9112	-- 36"W x 18"D x 72"H $1,023.99
    ('i_tombolli@study_space.com', 'Sandusky Lee Large Locking Metal Cabinet - Black', 'These functional storage cabinets are great for all office and classroom needs! The heavy-gauge steel shelves are adjustable on 2" centers with Tru-Glide 3-point locking assembly and locking dome handles. Measures 36"W x 18"D x 72"H.', 60, 504),
	-- 9113	-- 71-1/2"H x 15"D x 46"W $1,194.99
    ('i_tombolli@study_space.com', 'Dual Purpose Student Locker - Assembled', 'Dual purpopse unit combines loads of functional storage in a small footprint. Lockers and cubbies keep personal items organized and teachers can store supplies behind locked doors on top. Upper locked cabinet has 4 compartments for secure storage. Coat hooks are strong enough for bulky winter wear. Ships fully assembled.', 36, 504),

-- 500s office --
-- 	505 --
	-- 9114
    ('i_tombolli@study_space.com', 'Office Star Products Work Smart Series Mesh Back Office Chair', 'This high back task chair has breathable mesh fabric along the backrest to keep you cool and comfortable. The Black bonded leather seat and height-adjustable armrests are comfortably padded, and it all sets atop a durable nylon base. This product has a 2 year limited manufacturer\'s warranty.', 24, 505),
    -- 9115
    ('i_tombolli@study_space.com', 'Office Star Products Pro Line II Series Mesh Back Office Chair', 'This reclining office chair is equipped with a synchro-tilt control system, which allows you to recline the back while keeping the seat relatively level. The back also features adjustable lumbar support. This product comes standard with a Black fabric seat and a mesh back.', 24, 505),
    -- 9116
    ('i_tombolli@study_space.com', 'Euro Style Filip Series Low Back Modern Office Chair', 'This adjustable rolling desk chair features a sleek low back design with soft leatherette over molded foam for lasting comfort. It glides on nylon casters, swivels 360°, and reclines with three tilt lock positions. Padded, height-adjustable armrests offer personalized support. Available in multiple colors and backed by a 5-year manufacturer’s warranty.', 60, 505),
    -- 9117
    ('i_tombolli@study_space.com', 'Office Star Products Work Smart Series Executive Leather Office Chair', 'This leather chair with wheels contrasts an Espresso leather ensemble on the seat, back, and arms with an Cocoa finish on the sturdy nylon structure and accents. Black endcaps above each set of casters serve as accents to bring the look together. The contoured, thick padding on the seat and back serve function as well as form to keep you comfortable.', 36, 505),

-- 506 --
    -- 9118
    ('i_tombolli@study_space.com', 'Performance Furnishings Small Rectangular Desk', 'The small computer desk is crafted from durable, scratch resistant laminate with PVC edge banding, providing long-lasting quality and protection against daily use. You can choose from various sizes and finishes, and multiple drawer configurations are available. It comes equipped with pre-installed grommets, adjustable leveling glides, and is backed by a 5 year warranty.', 60, 506),
    -- 9119
    ('i_tombolli@study_space.com', 'Performance Furnishings Double Pedestal Desk with Modesty Panel ', 'The pedestal desk brings a sharp blend of modern design and industrial character to any office. It features a high-quality laminate top with 3mm PVC edge banding, white locking drawers, and a rustic wire mesh modesty panel. Available in multiple sizes, you can choose a finish for the top that best complements your workspace.', 24, 506),
    -- 9120
    ('i_tombolli@study_space.com', 'Heartland Office Source L Shaped Desk with Hutch', 'The L-shaped office desk is made from a high quality laminate and and you can order it with a return on either side, Right shown. Shown in an Ash Gray finish, it has a set of 2 & 3 drawer pedestals and a hutch for overhead storage. It\'s available in different sizes and finishes with your choice of drawers. Quality guaranteed by a 10-year manufacturer\'s warranty.', 120, 506),
    
-- 507 --
    -- 9121 -- 5 tier  17D" x 64H" x 36W"  1690.00
    ('i_tombolli@study_space.com', 'Tennsco Standard Series Lateral File Cabinet with Shelves', 'The locking file cabinet is built for durability and organization, featuring strong steel construction, fixed shelves, and a powder-coated finish for long-lasting performance. Its reinforced doors open effortlessly and retract to save aisle space, while a single lock secures all compartments. Available in multiple sizes and colors, it arrives fully assembled and ready for use.', 12, 507),
    -- 9122 2 SIZES 18D" x 60H" x 36W"  AND  24D" x 60H" x 36W"
    ('i_tombolli@study_space.com', 'Tennsco Standard Series Storage Cabinet with Doors - 60" Tall', 'The storage cabinet with shelves maximizes vertical storage space with a reinforced steel frame and a three-point keyed locking mechanism for security. Its adjustable shelves can support up to 200 lbs. each, and the raised base protects contents from cleaning liquids. Available in multiple sizes and colors, it ships fully assembled and is ready for immediate use.', 12, 507),
    -- 9123 18D" x 28H" x 42W"
    ('i_tombolli@study_space.com', 'Tennsco Standard Series 2 Drawer Lateral File Cabinet - 42" Wide', 'The metal lateral file cabinet offers durable steel construction with reinforced drawer fronts, ensuring long-lasting performance. Available in a variety of sizes and colors, it features an adjustable file system for both letter and legal files, full-extension ball-bearing slides for smooth operation, and an anti-tip mechanism for safety. With a powder-coated finish and a secure single-core lock, it combines style, durability, and functionality.', 12, 507),
    
-- 508 --
    -- 9124 48L" x 30W" AND 48L" x 36W"  and  51L" x 48W"  and   45L" x 52W"  and  60L" x 48W"
    ('i_tombolli@study_space.com', 'Floor1ex Valumat Series Office Chair Mat for Hardwood Floor', 'This floor mat for office chair is made in a transparent finish to better blend in with your flooring and protect it from scuffs at the same time. The unique phthalate-free formula ensures your mat is free of toxins while keeping the standard durability of vinyl. Each Valumat® from Floortex® is protected by a limited two-year warranty.', 24, 508),
    -- 9125
    ('i_tombolli@study_space.com', 'Floor1ex Advantagemat Series Office Chair Mat for Carpet', 'This computer chair mat features a specialized underside for gripping carpets up to a quarter inch thick. The top surface is also designed to provide a smooth rolling surface for your office chair of choice. Each Advantagemat® product from Floortex® is protected by a limited 2 year warranty.', 24, 508);
   

INSERT INTO colors (color_name, color_hex)
VALUES
('None', NULL),	 -- 600
('Assorted', NULL),	 -- 601
('Assorted Metallics', NULL),	 -- 602
('Assorted Pastels', NULL),	 -- 603
('Multicolor', NULL),	 -- 604
('Pattern', NULL),	 -- 605
('Black', '#000000'),	 -- 606
('Blue', '#0000ff'),	 -- 607
('Cherry', '#8e3a25'),	 -- 608
('Clear', NULL),	 -- 609
('Cyan', '#00bfff'),	 -- 610
('Dark Blue', '#090990'),	 -- 611
('Dark Brown', '#52422e'),	 -- 612
('Dark Green', '#004d00'),	 -- 613
('Dark Gray', '#666666'),	 -- 614
('Dark Red', '#8b0000'),	 -- 615
('Espresso', '#3b2112'),	 -- 616
('Green', '#00ff00'),	 -- 617
('Light Blue', '#b3d9ff'),	 -- 618
('Light Brown', '#b59b7c'),	 -- 619
('Light Green', '#66ffc3'),	 -- 620
('Light Gray', '#bfbfbf'),	 -- 621
('Light Wood', '#f9ebb9'),	 -- 622
('Lilac', '#c8a2c8'),	 -- 623
('Magenta', '#ff33cc'),	 -- 624
('Mahogany', '#7a1d05'),	 -- 625
('Manila', '#e7c9a9'),	 -- 626
('Maple', '#bb9351'),	 -- 627
('Mint', '#8adbce'),	 -- 628
('Navy', '#000080'),	 -- 629
('Newport Gray', '#9b9292'),	 -- 630
('Orange', '#ff6600'),	 -- 631
('Orchid', '#e2cfe1'),	 -- 632
('Pencil Yellow', '#ffdd00'),	 -- 633
('Pink', '#ff80aa'),	 -- 634
('Purple', '#800080'),	 -- 635
('Red', '#ff0000'),	 -- 636
('Rose Pink', '#f0afc1'),	 -- 637
('Sand', '#dbc6a4'),	 -- 638
('Silver', '#c0c0c0'),	 -- 639
('Silver Birch', '#d9d9d9'),	 -- 640
('Sky Blue', '#1a6bb8'),	 -- 641
('Teal', '#29a3a3'),	 -- 642
('Walnut', '#55402b'),	 -- 643
('White', '#ffffff'),	 -- 644
('Yellow', '#ffff00');	 -- 645

INSERT INTO sizes (size_description)
VALUES
('None'),	          -- 400
('Standard'),	          -- 401
('Variable'),	          -- 402
('A4: 8.25W" x 11.75L"'),	          -- 403
('Legal (US): 8.5W" x 14L"'),	          -- 404
('Letter (US): 8.5W" x 11L"'),	          -- 405
('0.75"'),	          -- 406
('10"'),	          -- 407
('15"'),	          -- 408
('16"'),	          -- 409
('18"'),	          -- 410
('1W"'),	          -- 411
('2.5L'),	          -- 412
('2W"'),	          -- 413
('24W"'),	          -- 414
('48"'),	          -- 415
('5L\''),	          -- 416
('8L\''),	          -- 417
('3fl.oz.'),	          -- 418
('8fl.oz'),	          -- 419
('132mL capacity'),	          -- 420
('118L” x 48W”'),	          -- 421
('18" x 30"'),	          -- 422
('3" x 3"'),	          -- 423
('3.6L" x 0.3W"'),	          -- 424
('30L”  x 48W”'),	          -- 425
('4\'5" x 5\'10"'),	          -- 426
('45L" x 52W"'),	          -- 427
('48L" x 30W"'),	          -- 428
('48L" x 36W"'),	          -- 429
('48L” x 24W"'),	          -- 430
('4L" x 0.4W"'),	          -- 431
('4L\' x 6W\''),	          -- 432
('51L" x 48W"'),	          -- 433
('8L" x 10.75W"'),	          -- 434
('12L" x 9W"'),	          -- 435
('12L" x 18W"'),	          -- 436
('2.75" x 3.5"'),	          -- 437
('60L” x 24W”'),	          -- 438
('60L” x 30W”'),	          -- 439
('60L” x 48W”'),	          -- 440
('66L” x 30W”'),	          -- 441
('6L\' x 9W\''),	          -- 442
('71L" x 72W"'),	          -- 443
('71L” x 30W”'),	          -- 444
('71L” x 36W”'),	          -- 445
('72L” x 24W”'),	          -- 446
('72L” x 30W”'),	          -- 447
('79L” x 48W”'),	          -- 448
('11.18D" x 5.67H" x 16W"'),	          -- 449
('13"W x 10"D x 17.5"H '),	          -- 450
('14.5H" x 14W" x 11.25D"'),	          -- 451
('14.6H" x 19.4L" x 8.1W"'),	          -- 452
('15.9H" x 21.2L" x 8.1W"'),	          -- 453
('15D" x 36H" x 20W"'),	          -- 454
('15D" x 36H" x 48W"'),	          -- 455
('15D" x 43H" x 48W"'),	          -- 456
('15D" x 71.5H" x 46W"'),	          -- 457
('16"W x 18"D x 26"L '),	          -- 458
('16"W x 22"D x 28"L '),	          -- 459
('17D" x 64H" x 36W"'),	          -- 460
('18D" x 72H" x 36W"'),	          -- 461
('2.4H" x 9.1W" x 7D"'),	          -- 462
('2.4H" x 9.4W" x 7.1D"'),	          -- 463
('20W" x 19D" x 18-22H" '),	          -- 464
('33.75H" x 14.68W" x 18.37L" '),	          -- 465
('4.75H" x 51.25L" x 9.25W"'),	          -- 466
('5.25W" x 11L" x 5.25H"'),	          -- 467
('5.5H" x 20L" x 11.5W"'),	          -- 468
('61.4L mm  x 18.84W mm'),	          -- 469
('8H" x 4.25W" x 2.25D"'),	          -- 470
('8GB'), -- 471
	('16GB'), -- 472
	('32GB'), -- 473
	('64GB'), -- 474
    ('16fl.oz.'), -- 475
    ('7.75L" x 10.75W"'), -- 476
    ('7L" x 0.13W"'), -- 477
    ('24D" x 60H" x 36W"'), -- 478
    ('18D" x 28H" x 42W"'), -- 479
    ('12"'); -- 480
    
INSERT INTO specifications (spec_description)
VALUES
	('Single'), -- 200
	('2-Pack'), -- 201
	('3-Pack'), -- 202
	('4-Pack'), -- 203
	('5-Pack'), -- 204
	('6-Pack'), -- 205
	('7-Pack'), -- 206
	('8-Pack'), -- 207
	('9-Pack'), -- 208
	('10-Pack'), -- 209
	('12-Pack'), -- 210
	('15-Pack'), -- 211
	('18-Pack'), -- 212
	('20-Pack'), -- 213
	('24-Pack'), -- 214
	('30-Pack'), -- 215
	('32-Pack'), -- 216
	('36-Pack'), -- 217
	('40-Pack'), -- 218
	('42-Pack'), -- 219
	('45-Pack'), -- 220
	('48-Pack'), -- 221
	('50-Pack'), -- 222
	('52-Pack'), -- 223
	('55-Pack'), -- 224
	('56-Pack'), -- 225
	('60-Pack'), -- 226
	('64-Pack'), -- 227
	('72-Pack'), -- 228
	('90-Pack'), -- 229
	('96-Pack'), -- 230
	('100-Pack'), -- 231
	('120-Pack'), -- 232
    ('125-Pack'), -- 233
	('144-Pack'), -- 234
	('320-Pack'), -- 235
	('432-Pack'), -- 236
	('1 Pack/800 Pages'), -- 237
	('1 Pack/1250 Pages'), -- 238
	('4 Pack/3650 Pages'), -- 239
	('24 Tabs/Pack'), -- 240
	('66 Tabs/Pack'), -- 241
	('320 Flags/Pack'), -- 242
	('70 Sheet/Pad, 24 Pads/Pack'), -- 243
	('90 Sheet/Pad, 5 Pads/Pack'), -- 244
	('48 Sheets'), -- 245
	('96 Sheets'), -- 246
	('240 Sheets'), -- 247
	('96 Sheets/Pack, 12-Pack'), -- 248
	('48 Sheets/Pack, 6-Pack'), -- 249
	('240 Sheets/Pack, 3-Pack'), -- 250
	('1-Ream 500 Sheets/Ream'), -- 251
	('3-Ream 500 Sheets/Ream'), -- 252
	('5-Ream 500 Sheets/Ream'), -- 253
	('8-Ream 500 Sheets/Ream'), -- 254
	('10-Ream 500 Sheets/Ream'), -- 255
	('9125e: 250 Sheet Input/60 Sheet Output'), -- 256
	('9135e: 500 Sheet Input/100 Sheet Output'), -- 257
	('GX3020: 250 Sheet Input/100 Sheet Output'), -- 258
	('GX4020: 250 Sheet Input/100 Sheet Output'), -- 259
	('GX5020: 350 Sheet Input'), -- 260
	('1-Hole Punch'), -- 261
	('3-Hole Punch'), -- 262
	('16GB RAM'), -- 263
	('1TB'), -- 264
	('4TB'), -- 265
    ('2000-Pack'), -- 266
    ('1 Gallon'), -- 267
    ('500 Sheets'), -- 268
    ('18 Pages'), -- 269
    ('64 Pages'), -- 270
    ('96 Pages'), -- 271
    ('144-Pack, 2 Packs/Set'), -- 272
    ('25-Pack'), -- 273
    ('648-Count'), -- 274
    ('1300-Count'), -- 275
    ('5100-Count'); -- 276

INSERT INTO product_variants (product_id, color_id, size_id, spec_id, price, current_inventory)
VALUES
(9000, 601, 401, 209, 479, 10),
(9000, 601, 401, 210, 499, 10),
(9000, 601, 401, 218, 1689, 10),
(9000, 601, 401, 234, 13099, 10),
(9001, 603, 401, 214, 999, 10), 
(9001, 603, 401, 218, 1899, 10),
(9002, 619, 401, 233, 1849, 10),
(9003, 633, 401, 210, 559, 10),
(9003, 633, 401, 212, 719, 10),
(9003, 633, 401, 215, 949, 10),
(9003, 633, 401, 228, 1889, 10),
(9004, 633, 401, 210, 499, 10),
(9004, 633, 401, 214, 799, 10),
(9004, 633, 401, 230, 2149, 10),
(9005, 606, 401, 210, 479, 10),
(9005, 607, 401, 210, 479, 10),
(9005, 636, 401, 210, 479, 10),
(9005, 606, 401, 226, 2149, 10),
(9005, 607, 401, 226, 2149, 10),
(9005, 601, 401, 226, 2149, 10),
(9005, 606, 401, 232, 4099, 10),
(9005, 606, 401, 235, 12999, 10),
(9006, 606, 401, 210, 799, 10),
(9006, 636, 401, 210, 799, 10),
(9006, 629, 401, 210, 799, 10),
(9006, 607, 401, 210, 799, 10),
(9006, 617, 401, 210, 799, 10),
(9006, 635, 401, 210, 799, 10),
(9007, 606, 401, 204, 479, 10),
(9007, 601, 401, 204, 479, 10),
(9007, 601, 401, 204, 479, 10),
(9007, 602, 401, 204, 479, 10),
(9008, 601, 401, 210, 1149, 10),
(9009, 606, 401, 217, 2599, 10),
(9009, 636, 401, 217, 2599, 10),
(9009, 607, 401, 217, 2599, 10),
(9009, 639, 401, 217, 2599, 10),
(9009, 601, 401, 217, 2599, 10),
(9009, 601, 401, 214, 1999, 10),
(9010, 601, 401, 200, 799, 10),
(9011, 601, 401, 200, 1999, 10),
(9012, 601, 401, 210, 1379, 10),
(9012, 606, 401, 210, 1379, 10),
(9012, 636, 401, 210, 1379, 10),
(9012, 617, 401, 210, 1379, 10),
(9012, 607, 401, 210, 1379, 10),
(9012, 635, 401, 210, 1379, 10),

(9013, 636, 405, 200, 379, 10),
(9013, 645, 405, 200, 379, 10),
(9013, 617, 405, 200, 379, 10),
(9013, 607, 405, 200, 379, 10),
(9013, 629, 405, 200, 379, 10),
(9013, 606, 405, 200, 379, 10),
(9013, 601, 405, 205, 1299, 10),

(9014, 601, 420, 242, 2399, 10),
(9014, 601, 420, 242, 2399, 10),
(9014, 601, 420, 242, 2399, 10),
(9014, 601, 420, 242, 2399, 10),
(9014, 601, 420, 243, 699, 10),
(9014, 601, 420, 243, 699, 10),
(9014, 601, 420, 243, 699, 10),
(9014, 601, 420, 243, 699, 10),

(9015, 601, 401, 241, 1329, 10),

(9016, 601, 410, 240, 789, 10),
(9016, 601, 412, 239, 429, 10),

(9017, 606, 401, 200, 3799, 10),
(9017, 629, 401, 200, 3799, 10),
(9017, 632, 401, 200, 3799, 10),
(9017, 644, 401, 200, 3799, 10),

(9018, 636, 401, 200, 3299, 10),
(9018, 634, 401, 200, 3299, 10),
(9018, 620, 401, 200, 3299, 10),
(9018, 618, 401, 200, 3299, 10),
(9018, 611, 401, 200, 3299, 10),

(9019, 619, 401, 200, 1499, 10),

(9020, 623, 401, 200, 5499, 10),
(9020, 606, 401, 200, 5499, 10),
(9020, 611, 401, 200, 5499, 10),
(9020, 637, 401, 200, 5499, 10),
(9020, 641, 401, 200, 5499, 10),
(9020, 615, 401, 200, 5499, 10),

(9021, 605, 401, 200, 5499, 10),
(9021, 605, 401, 200, 5499, 10),
(9021, 605, 401, 200, 5499, 10),

(9022, 601, 401, 200, 4889, 10),

(9023, 609, 401, 215, 1089, 10),
(9023, 609, 401, 226, 1899, 10),

(9024, 601, 480, 217, 1649, 10),

(9025, 629, 437, 229, 2449, 10),

(9026, 600, 401, 233, 2199, 10),
(9026, 600, 401, 266, 21919, 10),

(9027, 600, 401, 200, 649, 10),
(9027, 600, 401, 200, 649, 10),
(9027, 600, 401, 205, 3849, 10),
(9027, 600, 401, 205, 3849, 10),

(9028, 629, 401, 200, 1849, 10),
(9028, 634, 401, 200, 1849, 10),
(9028, 610, 401, 200, 1849, 10),

(9029, 607, 401, 200, 1789, 10),

(9030, 614, 401, 200, 1259, 10),

(9031, 606, 401, 200, 2449, 10),

(9032, 601, 401, 209, 939, 10),

(9033, 636, 401, 267, 4039, 10),
(9033, 631, 401, 267, 4039, 10),
(9033, 645, 401, 267, 4039, 10),
(9033, 617, 401, 267, 4039, 10),
(9033, 607, 401, 267, 4039, 10),
(9033, 624, 401, 267, 4039, 10),
(9033, 644, 401, 267, 4039, 10),
(9033, 612, 401, 267, 4039, 10),

(9034, 601, 475, 210, 5299, 10),
(9035, 601, 418, 212, 849, 10),
(9036, 601, 419, 207, 3299, 10),
(9037, 601, 401, 272, 3069, 10),
(9038, 622, 401, 214, 2589, 10),
(9039, 601, 401, 221, 3049, 10),
(9040, 644, 401, 202, 1899, 10),
(9041, 603, 401, 210, 0, 10),
(9041, 601, 401, 210, 0, 10),
(9042, 601, 401, 214, 0, 10),
(9043, 601, 401, 217, 0, 10),
(9043, 601, 401, 231, 0, 10),
(9044, 601, 401, 227, 0, 10),
(9045, 601, 424, 222, 0, 10),
(9046, 601, 424, 214, 0, 10),
(9046, 602, 424, 214, 0, 10),
(9046, 603, 424, 214, 0, 10),
(9047, 601, 424, 232, 0, 10),
(9048, 601, 424, 207, 0, 10),
(9049, 601, 431, 207, 0, 10),
(9050, 601, 400, 218, 0, 10),
(9051, 601, 435, 246, 469, 10),
(9051, 601, 435, 247, 1169, 10),
(9051, 601, 435, 248, 6079, 10),
(9051, 601, 435, 250, 3329, 10),
(9052, 601, 436, 245, 969, 10),
(9052, 601, 436, 249, 4739, 10),
(9053, 601, 435, 268, 3039, 10),
(9054, 601, 436, 269, 0, 10),
(9055, 601, 434, 271, 0, 10),
(9056, 601, 476, 270, 0, 10),
(9057, 601, 476, 270, 0, 10),
(9058, 601, 476, 270, 0, 10),
(9059, 601, 406, 274, 0, 10),
(9060, 601, 406, 275, 0, 10),
(9061, 601, 406, 276, 0, 10),
(9062, 606, 467, 200, 2769, 10),
(9062, 634, 467, 200, 2769, 10),
(9062, 639, 467, 200, 2769, 10),
(9062, 644, 467, 200, 2769, 10),
(9063, 606, 401, 200, 0, 10),
(9063, 639, 401, 200, 0, 10),
(9063, 644, 401, 200, 0, 10),
(9064, 606, 401, 200, 0, 10),
(9065, 606, 400, 262, 5299, 10),
(9066, 621, 400, 261, 5299, 10),
(9067, 601, 477, 222, 0, 10),
(9068, 601, 477, 222, 0, 10),
(9069, 644, 405, 251, 0, 10),
(9069, 644, 405, 252, 0, 10),
(9069, 644, 405, 253, 0, 10),
(9069, 644, 405, 254, 0, 10),
(9069, 644, 405, 255, 0, 10),
(9070, 644, 404, 251, 0, 10),
(9070, 644, 404, 252, 0, 10),
(9070, 644, 404, 253, 0, 10),
(9070, 644, 404, 254, 0, 10),
(9070, 644, 404, 255, 0, 10),
(9071, 644, 403, 251, 0, 10),
(9071, 644, 403, 252, 0, 10),
(9071, 644, 403, 253, 0, 10),
(9071, 644, 403, 254, 0, 10),
(9071, 644, 403, 255, 0, 10),
(9072, 606, 401, 263, 0, 10),
(9073, 606, 401, 263, 0, 10),
(9074, 606, 402, 200, 5999, 10),
(9075, 639, 402, 200, 5569, 10),
(9076, 606, 402, 200, 10719, 10),
(9077, 606, 402, 200, 4999, 10),
(9078, 606, 402, 200, 12549, 10),
(9079, 606, 402, 200, 29999, 10),
(9080, 606, 402, 200, 3999, 10),
(9080, 644, 402, 200, 3999, 10),
(9081, 606, 402, 200, 6999, 10),
(9082, 606, 401, 200, 4489, 10),
(9083, 606, 401, 200, 4999, 10),
(9084, 614, 401, 200, 0, 10),
(9085, 606, 401, 200, 7999, 10),
(9085, 606, 401, 200, 9999, 10),
(9086, 606, 401, 200, 9999, 10),
(9087, 644, 417, 200, 2869, 10),
(9087, 644, 412, 201, 2729, 10),
(9088, 606, 416, 200, 3249, 10),
(9089, 606, 401, 200, 7639, 10),
(9090, 606, 401, 200, 12999, 10),
(9091, 613, 471, 209, 0, 10),
(9091, 613, 471, 273, 0, 10),
(9091, 613, 472, 209, 0, 10),
(9091, 613, 472, 273, 0, 10),
(9091, 613, 473, 209, 0, 10),
(9091, 613, 473, 273, 0, 10),
(9091, 613, 474, 209, 0, 10),
(9091, 613, 474, 273, 0, 10),
(9092, 606, 401, 200, 0, 10),
(9093, 606, 401, 200, 0, 10),
(9094, 644, 401, 256, 29999, 10),
(9094, 644, 401, 257, 39999, 10),
(9095, 606, 401, 200, 4549, 10),
(9095, 624, 401, 200, 3999, 10),
(9095, 645, 401, 200, 3999, 10),
(9095, 610, 401, 200, 3999, 10),
(9095, 601, 401, 200, 9089, 10),
(9095, 601, 401, 200, 12999, 10),
(9096, 644, 401, 258, 34999, 10),
(9096, 644, 401, 259, 3999, 10),
(9097, 606, 401, 200, 4199, 10),
(9097, 624, 401, 200, 3649, 10),
(9097, 645, 401, 200, 3649, 10),
(9097, 610, 401, 200, 3649, 10),
(9098, 606, 410, 203, 57199, 10),
(9098, 629, 410, 203, 57199, 10),
(9098, 613, 410, 203, 57199, 10),
(9099, 607, 409, 205, 45599, 10),
(9099, 629, 409, 205, 45599, 10),
(9099, 613, 409, 205, 45599, 10),
(9099, 628, 409, 205, 45599, 10),
(9099, 638, 409, 205, 45599, 10),
(9100, 607, 410, 200, 10899, 10),
(9100, 617, 410, 200, 10899, 10),
(9100, 631, 410, 200, 10899, 10),
(9100, 635, 410, 200, 10899, 10),
(9100, 636, 410, 200, 10899, 10),
(9100, 645, 410, 200, 10899, 10),
(9100, 642, 410, 200, 10899, 10),
(9100, 629, 410, 200, 10899, 10),
(9101, 601, 410, 203, 19499, 10),
(9102, 606, 401, 200, 13899, 10),
(9102, 607, 401, 200, 13899, 10),
(9102, 642, 401, 200, 13899, 10),
(9102, 629, 401, 200, 13899, 10),
(9103, 601, 408, 205, 0, 10),
(9104, 606, 415, 200, 0, 10),
(9104, 607, 415, 200, 0, 10),
(9104, 617, 415, 200, 0, 10),
(9104, 636, 415, 200, 0, 10),
(9105, 607, 422, 200, 17199, 10),
(9106, 604, 401, 200, 19499, 10),
(9107, 605, 432, 200, 17999, 5),
(9107, 605, 442, 200, 34499, 5),
(9108, 605, 432, 200, 17999, 5),
(9108, 605, 442, 200, 34499, 5),
(9109, 622, 455, 200, 79999, 10),
(9110, 622, 456, 200, 72599, 10),
(9111, 622, 454, 200, 44999, 10),
(9112, 606, 461, 200, 102599, 10),
(9113, 627, 457, 200, 119499, 10),
(9114, 606, 401, 200, 47500, 10),
(9115, 606, 401, 200, 79500, 10),
(9116, 606, 401, 200, 75900, 10),
(9117, 606, 401, 200, 56000, 10),
(9118, 643, 428, 200, 27500, 10), 
(9118, 643, 430, 200, 25500 , 10), 
(9118, 643, 439, 200, 28500, 10),
(9118, 643, 441, 200, 31500, 10),
(9118, 643, 445, 200, 33500, 10),
(9118, 643, 444, 200, 31500, 10),
(9118, 630, 428, 200, 27500, 10), 
(9118, 630, 430, 200, 25500, 10), 
(9118, 630, 439, 200, 28500, 10),
(9118, 630, 441, 200, 31500, 10),
(9118, 630, 445, 200, 33500, 10),
(9118, 630, 444, 200, 31500, 10),
(9118, 640, 428, 200, 27500, 10), 
(9118, 640, 430, 200, 25500, 10), 
(9118, 640, 439, 200, 28500, 10),
(9118, 640, 441, 200, 31500, 10),
(9118, 640, 445, 200, 33500, 10),
(9118, 640, 444, 200, 31500, 10),
(9118, 627, 428, 200, 27500, 10), 
(9118, 627, 430, 200, 25500, 10), 
(9118, 627, 439, 200, 28500, 10),
(9118, 627, 441, 200, 31500, 10),
(9118, 627, 445, 200, 33500, 10),
(9118, 627, 444, 200, 31500, 10),
(9118, 608, 428, 200, 27500, 10), 
(9118, 608, 430, 200, 25500, 10), 
(9118, 608, 439, 200, 28500, 10),
(9118, 608, 441, 200, 31500, 10),
(9118, 608, 445, 200, 33500, 10),
(9118, 608, 444, 200, 31500, 10),
(9118, 616, 428, 200, 27500, 10), 
(9118, 616, 430, 200, 25500, 10), 
(9118, 616, 439, 200, 28500, 10),
(9118, 616, 441, 200, 31500, 10),
(9118, 616, 445, 200, 33500, 10),
(9118, 616, 444, 200, 31500, 10),
(9118, 625, 428, 200, 27500, 10), 
(9118, 625, 430, 200, 25500, 10), 
(9118, 625, 439, 200, 28500, 10),
(9118, 625, 441, 200, 31500, 10),
(9118, 625, 445, 200, 33500, 10),
(9118, 625, 444, 200, 31500, 10),
(9119, 643, 438, 200, 89000, 10),
(9119, 643, 446, 200, 91500, 10),
(9119, 643, 439, 200, 100500, 10),
(9119, 643, 447, 200, 104500, 10),
(9120, 614, 401, 200, 94500, 10),
(9120, 643, 401, 200, 94500, 10),
(9121, 606, 460, 200, 169000, 10),
(9121, 613, 460, 200, 169000, 10),
(9121, 644, 460, 200, 169000, 10),
(9122, 606, 461, 200, 162500, 10),
(9122, 606, 478, 200, 166500, 10),
(9122, 614, 461, 200, 162500, 10),
(9122, 614, 478, 200, 166500, 10),
(9122, 621, 461, 200, 162500, 10),
(9122, 621, 478, 200, 166500, 10),
(9123, 606, 479, 200, 89500, 10),
(9123, 614, 479, 200, 89500, 10),
(9123, 621, 479, 200, 89500, 10),
(9124, 609, 428, 200, 7000, 10),
(9124, 609, 429, 200, 7500, 10),
(9124, 609, 433, 200, 10000, 10),
(9124, 609, 427, 200, 10000, 10),
(9124, 609, 440, 200, 10500, 10),
(9125, 600, 428, 200, 7000, 10),
(9125, 600, 440, 200, 13500, 10),
(9125, 600, 448, 200, 18500, 10),
(9125, 600, 421, 200, 26000, 10);
	-- 9000 bic mech pencils smooth regular --
	-- 800
-- 	(9000, 601, 400, 204, 479, 15),			-- 10 pack
    -- 801
 --    (9000, 601, 400, 205, 499, 15),			-- 12 pack
    -- 802
  --   (9000, 601, 400, 209, 1689, 15),		-- 40 pack
    -- 803
 --    (9000, 601, 400, 220, 13099, 15),		-- 320 pack
    
    -- 9001 bic mech pencils smooth pastels --
    -- 804
  --   (9001, 601, 400, 207, 999, 15),			-- 24 pack
    -- 805
--     (9001, 601, 400, 210, 1899, 15),		-- 40 pack
    
    -- dixon wooden pencil --
    -- 806
 --    (9002, 617, 400, 220, 1249, 15), 		-- 144 Pack

    -- ticonderoga sharpened wooden pencils --
    -- 807
  --   (9003, 635, 400, 205, 559, 15),			-- 12 pack
    -- 808
  --   (9003, 635, 400, 206, 719, 15),			-- 18 pack
    -- 809
  --   (9003, 635, 400, 208, 949, 15),			-- 30 pack
    -- 810
 --    (9003, 635, 400, 215, 1889, 15),		-- 72 pack 
    
    -- ticonderoga UNsharpened wooden pencils --
    -- 811
  --   (9004, 635, 400, 205, 499, 15),			-- 12 pack
    -- 812
  --   (9004, 635, 400, 207, 799, 15),			-- 24 pack
    -- 813
  --   (9004, 635, 400, 217, 2149, 15),		-- 96 pack

    -- bic round stic xtra life pens --
    -- 814
  --   (9005, 606, 400, 205, 479, 15),			-- 12 pack black
    -- 815
  --   (9005, 607, 400, 205, 479, 15),			-- 12 pack blue
    -- 816
 --    (9005, 629, 400, 205, 479, 15), 		-- 12 pack red
    -- 817
 --    (9005, 606, 400, 213, 2149, 15),		-- 60 pack black
    -- 818
 --    (9005, 607, 400, 213, 2149, 15),		-- 60 pack blue
    -- 819
 --    (9005, 601, 400, 213, 2149, 15),		-- 60 pack assorted 
    -- 820
--     (9005, 606, 400, 219, 4099, 15),		-- 120 pack black
    -- 821
  --   (9005, 606, 400, 222, 13999, 15),		-- 432 pack black
    
    -- pilot g2 pens 12 pack --
    -- 822
 --    (9006, 606, 400, 205, 799, 15),			-- black 12 pack
    -- 823
  --   (9006, 629, 400, 205, 799, 15),			-- red 12 pack
    -- 824
--     (9006, 624, 400, 205, 799, 15),			-- navy 12 pack
    -- 825
 --    (9006, 607, 400, 205, 799, 15),			-- blue 12 pack
    -- 826
 --    (9006, 615, 400, 205, 799, 15),			-- green 12 pack
    -- 827
  --   (9006, 628, 400, 205, 799, 15),			-- purple 12 pack
    
    
    -- 828
 --    (9007, 606, 400, 213, 111, 15),			-- black
    -- 829
--     (9007, 607, 400, 213, 111, 15),			-- blue
    -- 830
 --    (9007, 601, 400, 213, 111, 15),			-- assorted
    -- 831
 --    (9007, 603, 400, 213, 111, 15),			-- assorted (pastels)
    -- 832
 --    (9007, 602, 400, 213, 111, 15),			-- assorted (metallic)
    
	-- paper mate felt pens --
    -- 833
--     (9008, 601, 400, 205, 1149, 16),			-- 100233 assorted colors
    
    -- sharpie permenant markers --
    -- 834
 --    (9009, 606, 400, 209, 2599, 12),			-- 100234 black
    -- 835
 --    (9009, 629, 400, 209, 2599, 12), 			-- 100235 red
    -- 836
 --    (9009, 607, 400, 209, 2599, 12), 			-- 100236 blue
    -- 837
  --   (9009, 631, 400, 209, 2599, 12), 			-- 100237 silver
    -- 838
 --    (9009, 601, 400, 209, 2599, 12), 			-- 100238 assorted
    -- 839
--     (9009, 601, 400, 207, 1999, 16),			-- 100239 assorted 24 pack
    
    -- dry erase starter set --
    -- 840
--     (9010, 601, 400, 200, 799, 9),			-- 100240
    
    -- dry erase kit --
    -- 841
 --    (9011, 601, 400, 200, 1999, 11),			-- 100241
    
    -- dry erase markrs 12-pack --
    -- 842
--     (9012, 601, 400, 205, 1379, 10), 		-- 100242 assorted
    -- 843
 --    (9012, 606, 400, 205, 1379, 10), 		-- 100243 black 
    -- 844
  --   (9012, 629, 400, 205, 1379, 10),			-- 100244 red
    -- 845
--     (9012, 615, 400, 205, 1379, 10), 		-- 100245 green
    -- 846
 --    (9012, 607, 400, 205, 1379, 10), 		-- 100246 blue
    -- 847
 --    (9012, 628, 400, 205, 1379, 10), 		-- 100247 purple
    
    
    -- 9013 notebooks --
    -- single notebooks
    -- 848
 --    (9013, 629, 418, 200, 379, 10),	-- red
    -- 849
  --   (9013, 635, 418, 200, 379, 10),	-- yellow
    -- 850
   --  (9013, 615, 418, 200, 379, 10),	-- green
    -- 851
 --    (9013, 607, 418, 200, 379, 10),	-- blue
    -- 852
  --   (9013, 624, 418, 200, 379, 10),	-- navy
    -- 853
--     (9013, 606, 418, 200, 379, 10),	-- black
    -- 6 pack
    -- 854
 --    (9013, 601, 418, 202, 1299, 10),	-- assorted
    
    -- 100248
    -- post it notes large pack --
    -- 855
 --    (9014, 601, 400, 236, 2399, 5),			-- 100249
    -- 856
  --   (9014, 601, 400, 236, 2399, 5),			-- 100250
    -- 857
   --  (9014, 601, 400, 236, 2399, 5),			-- 100251
    -- 858
 --    (9014, 601, 400, 236, 2399, 5),			-- 100252

	-- post it notes small pack
    -- 859
  --   (9014, 601, 400, 237, 699, 5),	-- 100253
    -- 860
  --   (9014, 601, 400, 237, 699, 5),	-- 100254
    -- 861
 --    (9014, 601, 400, 237, 699, 5),	-- 100255
    -- 862
 --    (9014, 601, 400, 237, 699, 5),	-- 100256
    
    -- post it flags combo
    -- 863
 --    (9015, 601, 400, 238, 1329, 15),	-- 100257
    -- post it tabs
    -- 864 ````````````````````````````````````````````````
  --  (9016, 601, 413, 242, 789, 11),		-- 100258
    -- 858
   --  (9016, 601, 414, 243, 429, 8),		-- 100259
    
    -- bentogo modern lunch box --
    -- 859
    -- (9017, 606, 400, 200, 3799, 10),	-- black
    -- 860
-- 	(9017, 624, 400, 200, 3799, 10),	-- navy
    -- 861
	-- (9017, 626, 400, 200, 3799, 10),	-- orchid
    -- 862
	-- (9017, 634, 400, 200, 3799, 10),	-- white
    
    -- bentogo pop lunch box --
    -- 863
  --   (9018, 629, 400, 200, 3299, 10),	-- red
    -- 864
 --    (9018, 627, 400, 200, 3299, 10),	-- pink
    -- 865
--     (9018, 618, 400, 200, 3299, 10),	-- light green
    -- 866
--     (9018, 616, 400, 200, 3299, 10),	-- light blue
    -- 867
--     (9018, 610, 400, 200, 3299, 10),	-- dark blue
    
    
    -- jam paper lunch bags --
    -- 868
   --  (9019, 617, 400, 200, 1499, 10);
 
INSERT INTO discounts (variant_id, discount_price, start_date, end_date)
VALUES
	(806, 1149, '2025-04-09 16:30:00', '2025-04-16 16:30:00'),
    (840, 699, NULL, NULL),
    (841, 1599, NULL, NULL),
    (856, 1099, '2025-04-01 21:59:59', '2025-04-15 21:59:59');

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
	(1, 809, 4),
    (1, 811, 3),
    (1, 852, 1),
    -- cust 2
    (2, 840, 2),
    (2, 842, 4),
    (2, 850, 1),
    (2, 809, 1),
    (2, 810, 1),
    (2, 812, 1),
    -- cust 3
    (3, 827, 6),
    (3, 833, 6);

-- INSERT INTO orders (customer_email, status, order_date, total_price)
-- VALUES 
-- 	('c_ramos@outlook.com', 'pending', '2025-04-06 10:26:54', 55669), -- chair discounted
--     ('c_ramos@outlook.com', 'complete', '2025-03-12 14:35:22', 64870),
--     ('s_petocs@gmail.com', 'pending', '2025-04-06 16:39:12', 36246), 
--     ('s_teller@gmail.com', 'complete', '2025-04-01 22:11:00', 51496), -- chair discounted
--     ('d_giant@outlook.com', 'processing', '2025-03-25 12:05:59', 144900), 
--     ('d_giant@outlook.com', 'processing', '2025-03-30 17:03:36', 188497),
--     ('s_petocs@gmail.com', 'processing', '2025-03-27 08:22:13', 62646),
--     ('j_prescott@gmail.com', 'complete', '2025-03-17 09:18:47', 40471),
--     ('s_teller@gmail.com', 'complete', '2025-03-20 20:44:05', 3947),
--     ('s_teller@gmail.com', 'rejected', '2025-04-03 07:48:31', 143445);
--     
-- INSERT INTO order_items (order_id, variant_id, quantity, price_at_order_time)
-- VALUES 																			-- phys and precalc all discounted
-- 	(2, 100211, 1, 42999), -- chem textbook x1 => 42999
--     (2, 100204, 2, 299), -- blue notebook x2 => 299 * 2 = 598
--     (2, 100201, 1, 2274), -- 48-pack pencils x1 => 2274
--     (2, 100217, 1, 18999), -- mesh chair x1 => 18999
--     -- ^ total = 42999 + 598 + 2274 + 18999 = 64870
--     
--     (5, 100205, 2, 299), -- green notebook x2 => 299 * 2 = 598
--     (5, 100206, 1, 299), -- yellow notebook x1 => 299
--     (5, 100214, 1, 39500), -- precalc textbook x1 => 39500
--     (5, 100216, 1, 144900), -- L-desk x1 => 144900
-- 	-- ^ total = 598 + 299 + 39500 + 144900
--    
--     (7, 100213, 1, 32999), -- phys textbook x1 => discounted price => 32999
--     (7, 100202 , 1, 2649), -- 60-pack pencils x1 => 2649
--     (7, 100217, 1, 18999), -- mesh chair x1 => 18999
--     (7, 100218 , 1, 7999), -- chair mat (36x48) x1 => 7999
--     -- ^ total = 32999 + 2649 + 18999 + 7999 = 62646
--     
--     (3, 100208, 1, 299), -- black notebook x1 => 299
--     (3, 100212, 1, 34999), -- chem textbook x1 => 34999
--     (3, 100200, 2, 474), -- 10-pack pencils x2 => 474 * 2 = 948
--     -- ^ total = 299 + 34999 + 948 = 36246
--     
--     (9, 100210, 1, 2999), -- 12-pack notebooks x1 => 2999
--     (9, 100200, 2, 474), -- 10-pack pencils x2 => 474 * 2 = 948
--     -- ^ total = 299 + 948 = 3947
--     
--     (4, 100209, 1, 1599), -- 6-pack notebooks x1 => 1599
--     (4, 100213, 1, 32999), -- phys textbook => discounted price => 32999
--     (4, 100217, 1, 16599), -- mesh chair x1 => discounted price => 16599
--     (4, 100203, 1, 299), -- red notebook x1 => 299
--     -- ^ total = 1599 + 32999 + 16599 + 299 = 51496

    -- (8, 100214, 1, 37599), -- precalc textbook => discounted price => 37599
--     (8, 100208, 2, 299), -- black notebook x2 => 299 * 2 = 598
--     (8, 100201, 1, 2274); -- 48-pack pencils x1 => 2274
    -- ^ total = 37599 + 598 + 2274 = 40471
    
   --  (1, 100217, 1, 16599), -- mesh chair => discounted price => 16599
--     (1, 100210, 1, 2999), -- 12-pack notebooks x1 => 2999
--     (1, 100204, 2, 299), -- blue notebook x2 => 299 * 2 = 598
--     (1, 100212, 1, 34999), -- comp textbook x1 => 34999
--     (1, 100200, 1, 474), -- 10-pack pencils => 474
--     -- total ^ = 16599 + 2999 + 598 + 34999 + 474 = 55669 DISCOUNTED CHAIR
--     
--     (6, 100205, 2, 299), -- green notebooks x2 => 299 * 2 = 598
--     (6, 100211, 1, 42999), -- chem textbook => 42999
--     (6, 100216, 1, 144900), -- L-desk x1 => 144900
--     -- ^ total = 598 + 42999 + 144900 = 188497
--     
--     (10, 100202, 1, 2649), -- 60-pack pencils x1 => 2649
--     (10, 100213, 1, 32999), -- phys textbook => discounted price => 32999
--     (10, 100204, 1, 299), -- blue notebook => 299
--     (10, 100215, 1, 95000), -- desk (60x30) x1 => 95000
--     (10, 100219, 1, 9499), -- chair mat (45x53) x1 => 9499
--     (10, 100210, 1, 2999); -- 12-pack notebooks x1 => 2999
--     -- ^ total = 2649 + 32999 + 299 + 95000 + 9499 + 2999 = 143445

-- reviews with images on shipped orders
INSERT INTO reviews (customer_email, product_id, rating, description, date)
VALUES
	-- ('c_ramos@outlook.com', 850557, 4, 'I ordered this chemistry textbook after transfering to a chem class mid semester. It shipped quickly and the cover had some slight dents in it but otherwise in good condition.', '2025-03-20 11:15:36'),
--     ('j_prescott@gmail.com', 850560, 3, 'Got this textbook at a discount. Its Precalculus by Holt. The corner of the cover had some damage which was annoying.', '2025-03-22 13:57:04'),
    ('s_teller@gmail.com', 9000, 5, 'These are my favorite mechanical pencils. Super reliable and smooth, I dont buy any other brand. 100% recommend!', '2025-03-24 10:32:45');
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
-- INSERT INTO chats (text, complaint_id, product_id, image_id, user_from, user_to, date_time)
-- VALUES
--     ('Okay here is the photo:', 2, NULL, NULL, 's_teller@gmail.com', 'i_tombolli@study_space.com', '2025-04-08 11:49:12'),
--     (NULL, 2, NULL, 32, 's_teller@gmail.com', 'i_tombolli@study_space.com', '2025-04-08 11:49:28');
-- INSERT INTO chats (text, complaint_id, product_id, user_from, user_to, date_time)
-- VALUES
--     ('Thank you, Mr. Teller. I see the issue. I will submit the warranty claim for you. It can take up to 7 business days to be processed.', 2, NULL, 'i_tombolli@study_space.com', 's_teller@gmail.com', '2025-04-08 11:50:00'),
--     ('You will receive an email when the replacement part has been shipped.', 2, NULL, 'i_tombolli@study_space.com', 's_teller@gmail.com', '2025-04-08 11:50:19'),
--     ('Is there anything else I can help you with before closing the support ticket?', 2, NULL, 'i_tombolli@study_space.com', 's_teller@gmail.com', '2025-04-08 11:50:31'),
--     ('Not right now, I appreciate the help.', 2, NULL, 's_teller@gmail.com', 'i_tombolli@study_space.com', '2025-04-08 11:52:36'),
-- 	('It is my pleasure. Thank you for choosing Study Space. Have a wonderful day.', 2, NULL, 'i_tombolli@study_space.com', 's_teller@gmail.com', '2025-04-08 11:53:14');

-- -- chats from remaining customers to vendors about products
-- INSERT INTO chats (text, product_id, user_from, user_to, date_time) 
-- VALUES
-- 	-- user s_petocs@gmail.com
-- 	('Hi Annemarie, I saw your listing for "The Language of Composition" and wanted to ask if it’s still available.', 850558, 's_petocs@gmail.com', 'a_batts@textbooksmadeeasy.org', '2025-03-15 13:02:51'),
-- 	('Hi Sajay! Yes, the textbook is still available. It’s the 2nd edition and in good condition.', 850558, 'a_batts@textbooksmadeeasy.org', 's_petocs@gmail.com', '2025-03-15 13:10:17'),
-- 	('That’s great to hear. Are there any markings or highlights inside?', 850558, 's_petocs@gmail.com', 'a_batts@textbooksmadeeasy.org', '2025-03-15 13:12:45'),
-- 	('There are a few pencil notes in the margins, but no ink or highlighting. Nothing that would interfere with reading.', 850558, 'a_batts@textbooksmadeeasy.org', 's_petocs@gmail.com', '2025-03-15 13:15:30'),
-- 	('Thanks for the info. Since it’s used and has some pencil notes, would you be open to a small discount?', 850558, 's_petocs@gmail.com', 'a_batts@textbooksmadeeasy.org', '2025-03-15 13:17:02'),
-- 	('I understand, but I’m firm on the price due to high demand for this edition. Let me know if you’re still interested.', 850558, 'a_batts@textbooksmadeeasy.org', 's_petocs@gmail.com', '2025-03-15 13:19:38'),
--     -- user j_prescott@gmail.com
-- 	('Hi Isabella, I’m interested in the Anti-Static Carpet Chair Mat. Is the 45 x 53 inch size currently in stock?', 850563, 'j_prescott@gmail.com', 'i_tombolli@study_space.com', '2025-03-18 09:24:12'),
-- 	('Hi Jean! Yes, both sizes are in stock, including the 45 x 53 inch option at $94.99.', 850563, 'i_tombolli@study_space.com', 'j_prescott@gmail.com', '2025-03-18 09:27:01'),
-- 	('Great, thanks! Can you tell me how durable it is for daily use with a rolling chair?', 850563, 'j_prescott@gmail.com', 'i_tombolli@study_space.com', '2025-03-18 09:29:18'),
-- 	('Absolutely. It’s made from durable vinyl and holds up well under regular use. The cleared backing keeps it steady, even with frequent rolling.', 850563, 'i_tombolli@study_space.com', 'j_prescott@gmail.com', '2025-03-18 09:31:44'),
-- 	('Sounds good. I’d like to go ahead with the 45 x 53 size. Do you offer local pickup or only shipping?', 850563, 'j_prescott@gmail.com', 'i_tombolli@study_space.com', '2025-03-18 09:34:29'),
-- 	('Thanks, Jean. We offer both options—local pickup is available if you’re nearby, otherwise we can ship it to you.', 850563, 'i_tombolli@study_space.com', 'j_prescott@gmail.com', '2025-03-18 09:36:10'),
-- 	-- user d_giant@outlook.com
-- 	('Hi Gebhard, I’m looking to place a bulk order for the 12-pack APEX Spiral Notebooks. Do you offer any discounts for larger quantities?', 850556, 'd_giant@outlook.com', 'g_pitts@supplies4school.org', '2025-04-09 10:52:03'),
-- 	('Hi Damien! I’d be happy to discuss a bulk deal. How many 12-packs are you looking to purchase?', 850556, 'g_pitts@supplies4school.org', 'd_giant@outlook.com', '2025-04-09 10:55:21'),
-- 	('I’m thinking of ordering 10 to 15 packs, depending on pricing.', 850556, 'd_giant@outlook.com', 'g_pitts@supplies4school.org', '2025-04-09 10:57:36'),
-- 	('Thanks for the info! For 10 or more 12-packs, I can offer them at $26.99 per pack instead of $29.99.', 850556, 'g_pitts@supplies4school.org', 'd_giant@outlook.com', '2025-04-09 11:01:12'),
-- 	('That’s a fair offer. If I go with 15 packs, could you do $25 each?', 850556, 'd_giant@outlook.com', 'g_pitts@supplies4school.org', '2025-04-09 11:03:44'),
-- 	('For 15 packs, I can meet you halfway at $25.99 per pack. Let me know if that works for you.', 850556, 'g_pitts@supplies4school.org', 'd_giant@outlook.com', '2025-04-09 11:06:10');

INSERT INTO images (variant_id, file_path)
VALUES
	(800, 'https://www.staples-3p.com/s7/is/image/Staples/sp134866786_sc7?wid=700&hei=700'),
    (800, 'https://www.staples-3p.com/s7/is/image/Staples/BD2506AA-25C9-4DBF-8A9A71DDABB79FEC_sc7?wid=700&hei=700'),
    (800, 'https://www.staples-3p.com/s7/is/image/Staples/D1FA9BE6-94CE-4799-89346460B9D84DC6_sc7?wid=700&hei=700'),
    (800, 'https://www.staples-3p.com/s7/is/image/Staples/6DBDA0CD-FD08-4936-9C6C77F937090506_sc7?wid=700&hei=700'),
    
    (801, 'https://www.staples-3p.com/s7/is/image/Staples/CFABF4B6-1E01-4A4B-BBF48A5466E535C4_sc7?wid=700&hei=700'),
    (801, 'https://www.staples-3p.com/s7/is/image/Staples/BD2506AA-25C9-4DBF-8A9A71DDABB79FEC_sc7?wid=700&hei=700'),
    (801, 'https://www.staples-3p.com/s7/is/image/Staples/D1FA9BE6-94CE-4799-89346460B9D84DC6_sc7?wid=700&hei=700'),
    (801, 'https://www.staples-3p.com/s7/is/image/Staples/6DBDA0CD-FD08-4936-9C6C77F937090506_sc7?wid=700&hei=700'),
    
    (802, 'https://www.staples-3p.com/s7/is/image/Staples/12F2D191-C6FA-4470-A45D43E3FB233591_sc7?wid=700&hei=700'),
    (802, 'https://www.staples-3p.com/s7/is/image/Staples/BD2506AA-25C9-4DBF-8A9A71DDABB79FEC_sc7?wid=700&hei=700'),
    (802, 'https://www.staples-3p.com/s7/is/image/Staples/D1FA9BE6-94CE-4799-89346460B9D84DC6_sc7?wid=700&hei=700'),
    (802, 'https://www.staples-3p.com/s7/is/image/Staples/6DBDA0CD-FD08-4936-9C6C77F937090506_sc7?wid=700&hei=700'),
    
    (803, 'https://www.staples-3p.com/s7/is/image/Staples/sp168943593_sc7?wid=700&hei=700'),
    (803, 'https://www.staples-3p.com/s7/is/image/Staples/BD2506AA-25C9-4DBF-8A9A71DDABB79FEC_sc7?wid=700&hei=700'),
    (803, 'https://www.staples-3p.com/s7/is/image/Staples/D1FA9BE6-94CE-4799-89346460B9D84DC6_sc7?wid=700&hei=700'),
    (803, 'https://www.staples-3p.com/s7/is/image/Staples/6DBDA0CD-FD08-4936-9C6C77F937090506_sc7?wid=700&hei=700'),
    
-- bic mech pencils smooth pastels --
    (804, 'https://www.staples-3p.com/s7/is/image/Staples/1C475290-ABD6-41A1-8631B8F24A3F3A8F_sc7?wid=700&hei=700'),
    (804, 'https://www.staples-3p.com/s7/is/image/Staples/E86EB62F-574D-48C2-87426BF1569AE046_sc7?wid=700&hei=700'),
    (804, 'https://www.staples-3p.com/s7/is/image/Staples/0EF056CA-AEA0-4DFD-841D625E40E23F4E_sc7?wid=700&hei=700'),
    (804, 'https://www.staples-3p.com/s7/is/image/Staples/2BDD2BDD-F434-44A8-85AE5CDB932F35FA_sc7?wid=700&hei=700'),
    
    (805, 'https://www.staples-3p.com/s7/is/image/Staples/F25FB988-02AE-4727-B8C1D5E1505761B2_sc7?wid=700&hei=700'),
    (805, 'https://www.staples-3p.com/s7/is/image/Staples/E86EB62F-574D-48C2-87426BF1569AE046_sc7?wid=700&hei=700'),
    (805, 'https://www.staples-3p.com/s7/is/image/Staples/0EF056CA-AEA0-4DFD-841D625E40E23F4E_sc7?wid=700&hei=700'),
    (805, 'https://www.staples-3p.com/s7/is/image/Staples/2BDD2BDD-F434-44A8-85AE5CDB932F35FA_sc7?wid=700&hei=700'),
    
-- dixon wooden pencils 144 pack --
	(806, 'https://www.staples-3p.com/s7/is/image/Staples/sp49507996_sc7?wid=700&hei=700'),
    (806, 'https://www.staples-3p.com/s7/is/image/Staples/sp49507997_sc7?wid=700&hei=700'),
    (806, 'https://www.staples-3p.com/s7/is/image/Staples/sp49507998_sc7?wid=700&hei=700'),
    (806, 'https://www.staples-3p.com/s7/is/image/Staples/E6C6C568-E17D-4B4C-8B021B125435EF61_sc7?wid=700&hei=700'),
    
-- ticonderoga pencils sharpened --
	(807, 'https://www.staples-3p.com/s7/is/image/Staples/049FBA3E-4A6D-4AD0-9C2BEBBA853D6EE2_sc7?wid=700&hei=700'),
    (807, 'https://www.staples-3p.com/s7/is/image/Staples/CB08C81A-B707-4DFF-85DF4A6E006CC277_sc7?wid=700&hei=700'),
    (807, 'https://www.staples-3p.com/s7/is/image/Staples/D1119CF9-8775-4F6F-B228B0DE23CBA425_sc7?wid=700&hei=700'),
    (807, 'https://www.staples-3p.com/s7/is/image/Staples/E71A5E9A-B04F-43B6-97E6F6EB5EF5A79F_sc7?wid=700&hei=700'),
    
	(808, 'https://www.staples-3p.com/s7/is/image/Staples/42511C4C-95D1-41B2-BCC9AA58E69BC20B_sc7?wid=700&hei=700'),
    (808, 'https://www.staples-3p.com/s7/is/image/Staples/BF3720DC-8A99-473C-9B8F2B160F453C35_sc7?wid=700&hei=700'),
    (808, 'https://www.staples-3p.com/s7/is/image/Staples/B0B60957-E5E1-402D-90A1534BD6109340_sc7?wid=700&hei=700'),
    (808, 'https://www.staples-3p.com/s7/is/image/Staples/FF4B7AE7-A90E-4368-B74105FF1B14558E_sc7?wid=700&hei=700'),
    
	(809, 'https://www.staples-3p.com/s7/is/image/Staples/D484B555-81C2-4C89-BE1E3E6E0B757359_sc7?wid=700&hei=700'),
    (809, 'https://www.staples-3p.com/s7/is/image/Staples/5C992AA3-B589-4DB5-B6B6E759F957B70A_sc7?wid=700&hei=700'),
    (809, 'https://www.staples-3p.com/s7/is/image/Staples/FD036A75-1493-43D8-A3C06C9AE418E8A1_sc7?wid=700&hei=700'),
    (809, 'https://www.staples-3p.com/s7/is/image/Staples/3ABDD635-CDE8-4D0B-AB9BCA795F56D66A_sc7?wid=700&hei=700'),
    
	(810, 'https://www.staples-3p.com/s7/is/image/Staples/7661DDE1-93D7-4F37-A9A89942EB5F96D3_sc7?wid=700&hei=700'),
    (810, 'https://www.staples-3p.com/s7/is/image/Staples/92822F48-D2D0-4B93-ADE2B00569D2E221_sc7?wid=700&hei=700'),
    (810, 'https://www.staples-3p.com/s7/is/image/Staples/09EA427F-71CF-4177-B095CE08564B488D_sc7?wid=700&hei=700'),

-- ticonderoga pencils unsharpened --
    (811, 'https://www.staples-3p.com/s7/is/image/Staples/E8191618-67DB-431B-B01CB7FB8B06D167_sc7?wid=700&hei=700'),
    (811, 'https://www.staples-3p.com/s7/is/image/Staples/29C8C17E-598F-4446-A3D3B967E9D3B26B_sc7?wid=700&hei=700'),
    (811, 'https://www.staples-3p.com/s7/is/image/Staples/ACE88776-DBE8-489D-808559078CFD6466_sc7?wid=700&hei=700'),
    (811, 'https://www.staples-3p.com/s7/is/image/Staples/F8A19755-D2DE-446B-B1CF5BFB27A5474C_sc7?wid=700&hei=700'),
    
    (812, 'https://www.staples-3p.com/s7/is/image/Staples/6C8A5B5E-EBF7-42C9-A2E0C4E317F393EF_sc7?wid=700&hei=700'),
    (812, 'https://www.staples-3p.com/s7/is/image/Staples/43591D45-A913-42BE-A376D8C7E5074049_sc7?wid=700&hei=700'),
    (812, 'https://www.staples-3p.com/s7/is/image/Staples/939E04CB-B5C9-4832-A7AB4B90345DDD20_sc7?wid=700&hei=700'),
    (812, 'https://www.staples-3p.com/s7/is/image/Staples/052DB59F-FA7E-4411-890DEC20751DC751_sc7?wid=700&hei=700'),
    
    (813, 'https://www.staples-3p.com/s7/is/image/Staples/372E4DA9-88DD-4EBF-89BBFFC8852CD969_sc7?wid=700&hei=700'),
    (813, 'https://www.staples-3p.com/s7/is/image/Staples/ADC6E670-5FD1-4120-BA6DB5C1F79B8A6D_sc7?wid=700&hei=700'),
    (813, 'https://www.staples-3p.com/s7/is/image/Staples/6CF02D83-A85D-4904-A47A9116E17E883C_sc7?wid=700&hei=700'),
    (813, 'https://www.staples-3p.com/s7/is/image/Staples/1C264F7C-635F-4786-8C736D66C16A5EF7_sc7?wid=700&hei=700'),
    
-- bic ballpoint pens -- 
	-- 12 black
	(814, 'https://www.staples-3p.com/s7/is/image/Staples/726A4704-D070-461A-A455FCF4ACF7B46F_sc7?wid=700&hei=700'),
    (814, 'https://www.staples-3p.com/s7/is/image/Staples/02F1F184-741B-4288-8382383E0E596991_sc7?wid=700&hei=700'),
    (814, 'https://www.staples-3p.com/s7/is/image/Staples/2DFF5935-83DB-4F93-9B7616091D23EEA2_sc7?wid=700&hei=700'),
    -- 12 blue
    (815, 'https://www.staples-3p.com/s7/is/image/Staples/5BA27BD0-0DFA-441E-991D22D9B7EEBC85_sc7?wid=700&hei=700'),
    (815, 'https://www.staples-3p.com/s7/is/image/Staples/CCA66B60-B2CF-412C-9E6129E35472C408_sc7?wid=700&hei=700'),
    (815, 'https://www.staples-3p.com/s7/is/image/Staples/B3EC6B8C-E373-4EC4-B3E9702F0FF629AE_sc7?wid=700&hei=700'),
    -- 12 red
    (816, 'https://www.staples-3p.com/s7/is/image/Staples/BC5D0E88-8321-4645-AA5F31AC9F42C60A_sc7?wid=700&hei=700'),
    (816, 'https://www.staples-3p.com/s7/is/image/Staples/A6D65917-D1B1-498B-8980AD55397B2366_sc7?wid=700&hei=700'),
    (816, '*'),
    -- black 60
    (817, 'https://www.staples-3p.com/s7/is/image/Staples/AFD5FBB8-71A3-434C-989B74986834C3E5_sc7?wid=700&hei=700'),
    (817, 'https://www.staples-3p.com/s7/is/image/Staples/281C65AA-E03C-4165-BE0335374B5300D6_sc7?wid=700&hei=700'),
    (817, 'https://www.staples-3p.com/s7/is/image/Staples/DE4A6A03-B734-40EB-89A43123630B1165_sc7?wid=700&hei=700'),
	-- blue 60
    (818, 'https://www.staples-3p.com/s7/is/image/Staples/8FF19026-7FC9-49C6-945FC921B193E318_sc7?wid=700&hei=700'),
    (818, 'https://www.staples-3p.com/s7/is/image/Staples/0E907B5E-E49E-41E3-94C9770B386C4F22_sc7?wid=700&hei=700'),
    (818, 'https://www.staples-3p.com/s7/is/image/Staples/763AFBAF-0157-4089-B191ABFD609F081D_sc7?wid=700&hei=700'),
    -- assorted 60
    (819, 'https://www.staples-3p.com/s7/is/image/Staples/98CCE1B5-453E-4B3D-8D536E36EB5CB2E8_sc7?wid=700&hei=700'),
    (819, 'https://www.staples-3p.com/s7/is/image/Staples/1483FD07-AEE3-4F94-A0450B55CC341499_sc7?wid=700&hei=700'),
    (819, 'https://www.staples-3p.com/s7/is/image/Staples/FFEA53A9-96B9-4420-8D86911F934B46A7_sc7?wid=700&hei=700'),
    -- black 120
    (820, 'https://www.staples-3p.com/s7/is/image/Staples/sp132863911_sc7?wid=700&hei=700'),
    (820, 'https://www.staples-3p.com/s7/is/image/Staples/2F39A9B2-5AFC-47CF-A27302F60C109353_sc7?wid=700&hei=700'),
    (820, 'https://www.staples-3p.com/s7/is/image/Staples/05C87821-7CA8-4C72-92A559379E8AE3A2_sc7?wid=700&hei=700'),
    -- black 432
    (821, 'https://www.staples-3p.com/s7/is/image/Staples/sp41812286_sc7?wid=700&hei=700'),
    (821, 'https://www.staples-3p.com/s7/is/image/Staples/sp41812283_sc7?wid=700&hei=700'),
    (821, 'https://www.staples-3p.com/s7/is/image/Staples/sp41812284_sc7?wid=700&hei=700'),
    
	-- pilot g2 pens --
	(822, 'https://www.staples-3p.com/s7/is/image/Staples/sp130855922_sc7?wid=700&hei=700'),
    (822, 'https://www.staples-3p.com/s7/is/image/Staples/sp40286009_sc7?wid=700&hei=700'),
    (822, 'https://www.staples-3p.com/s7/is/image/Staples/sp40286010_sc7?wid=700&hei=700'),
    
    (823, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856306_sc7?wid=700&hei=700'),
    (823, 'https://www.staples-3p.com/s7/is/image/Staples/sp130855924_sc7?wid=700&hei=700'),
    
    (824, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856301_sc7?wid=700&hei=700'),
    (824, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856302_sc7?wid=700&hei=700'),
    
    (825, 'https://www.staples-3p.com/s7/is/image/Staples/sp138382946_sc7?wid=700&hei=700'),
    (825, 'https://www.staples-3p.com/s7/is/image/Staples/5743C478-DAF6-41D4-A3DC245D60749CF1_sc7?wid=700&hei=700'),
    (825, 'https://www.staples-3p.com/s7/is/image/Staples/sp41817060_sc7?wid=700&hei=700'),
    
    (826, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856294_sc7?wid=700&hei=700'),
    (826, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856295_sc7?wid=700&hei=700'),
    
    (827, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856303_sc7?wid=700&hei=700'),
    (827, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856304_sc7?wid=700&hei=700'),
    
    (828, 'https://www.staples-3p.com/s7/is/image/Staples/sp137770008_sc7?wid=700&hei=700'),
    (828, 'https://www.staples-3p.com/s7/is/image/Staples/sp137770011_sc7?wid=700&hei=700'),

    (829, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856218_sc7?wid=700&hei=700'),
    (829, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856219_sc7?wid=700&hei=700'),
    
    (830, 'https://www.staples-3p.com/s7/is/image/Staples/s1070669_sc7?wid=700&hei=700'),
    (830, 'https://www.staples-3p.com/s7/is/image/Staples/s1082037_sc7?wid=700&hei=700'),
    
    (831, 'https://www.staples-3p.com/s7/is/image/Staples/s1078333_sc7?wid=700&hei=700'),
    (831, 'https://www.staples-3p.com/s7/is/image/Staples/s1078334_sc7?wid=700&hei=700'),
    (831, 'https://www.staples-3p.com/s7/is/image/Staples/s1078335_sc7?wid=700&hei=700'),
    (831, 'https://www.staples-3p.com/s7/is/image/Staples/s1078336_sc7?wid=700&hei=700'),
    (831, 'https://www.staples-3p.com/s7/is/image/Staples/s1078337_sc7?wid=700&hei=700'),
    
    -- paper mate felt pens --
    (832, 'https://www.staples-3p.com/s7/is/image/Staples/98C1DFBD-AFCE-488D-B080922050338AA7_sc7?wid=700&hei=700'),
    (832, 'https://www.staples-3p.com/s7/is/image/Staples/sp161466748_sc7?wid=700&hei=700'),
    (832, 'https://www.staples-3p.com/s7/is/image/Staples/sp161466749_sc7?wid=700&hei=700'),
    
    -- sharpie permenant markers --
    -- black
    (833, 'https://www.staples-3p.com/s7/is/image/Staples/D67EC31B-0DB3-45F9-BD62DC872D1ACBF1_sc7?wid=700&hei=700'),
    (833, 'https://www.staples-3p.com/s7/is/image/Staples/1BCDF1C0-5454-4A4A-A616BD9601C8C140_sc7?wid=700&hei=700'),
    (833, 'https://www.staples-3p.com/s7/is/image/Staples/DD9A5C21-9C21-4A0E-B3B6C1149A3D0399_sc7?wid=700&hei=700'),
    -- red
    (834, 'https://www.staples-3p.com/s7/is/image/Staples/5CA98F6D-8D11-4886-B08C0CC322E38815_sc7?wid=700&hei=700'),
    (834, 'https://www.staples-3p.com/s7/is/image/Staples/sp89168542_sc7?wid=700&hei=700'),
    (834, 'https://www.staples-3p.com/s7/is/image/Staples/s0922441_sc7?wid=700&hei=700'),
    -- blue
    (835, 'https://www.staples-3p.com/s7/is/image/Staples/1C929E3D-8BCF-48E2-A00933FB4AAD3B2D_sc7?wid=700&hei=700'),
    (835, 'https://www.staples-3p.com/s7/is/image/Staples/s0933668_sc7?wid=700&hei=700'),
    (835, 'https://www.staples-3p.com/s7/is/image/Staples/s0922442_sc7?wid=700&hei=700'),
    -- silver
    (836, 'https://www.staples-3p.com/s7/is/image/Staples/m007068285_sc7?wid=700&hei=700'),
    (836, 'https://www.staples-3p.com/s7/is/image/Staples/m007068281_sc7?wid=700&hei=700'),
    (836, 'https://www.staples-3p.com/s7/is/image/Staples/m007068283_sc7?wid=700&hei=700'),
    -- assorted
    (837, 'https://www.staples-3p.com/s7/is/image/Staples/s1189983_sc7?wid=700&hei=700'),
    (837, 'https://www.staples-3p.com/s7/is/image/Staples/m002908378_sc7?wid=700&hei=700'),
    -- assorted 24 pack
    (838, 'https://www.staples-3p.com/s7/is/image/Staples/D5E6B1CA-30FC-4219-9BD4322085DCA998_sc7?wid=700&hei=700'),
    (838, 'https://www.staples-3p.com/s7/is/image/Staples/sp44335828_sc7?wid=700&hei=700'),
    (838, 'https://www.staples-3p.com/s7/is/image/Staples/sp44335829_sc7?wid=700&hei=700'),
    
    -- dry erase starter set
    (839, 'https://www.staples-3p.com/s7/is/image/Staples/E1755194-7001-4CE3-93598F83B0079751_sc7?wid=700&hei=700'),
    (839, 'https://www.staples-3p.com/s7/is/image/Staples/sp40798560_sc7?wid=700&hei=700'),
    (839, 'https://www.staples-3p.com/s7/is/image/Staples/sp40798562_sc7?wid=700&hei=700'),
    (839, 'https://www.staples-3p.com/s7/is/image/Staples/sp40798565_sc7?wid=700&hei=700'),
    
    -- dry erase kit
    (840, 'https://www.staples-3p.com/s7/is/image/Staples/m002304039_sc7?wid=700&hei=700'),
    (840, 'https://www.staples-3p.com/s7/is/image/Staples/m002304040_sc7?wid=700&hei=700https://www.staples-3p.com/s7/is/image/Staples/m002304040_sc7?wid=700&hei=700'),
    (840, 'https://www.staples-3p.com/s7/is/image/Staples/m002304041_sc7?wid=700&hei=700'),
    (840, 'https://www.staples-3p.com/s7/is/image/Staples/m002304042_sc7?wid=700&hei=700'),
    
    -- dry erase markers
    -- assorted
    (841, 'https://www.staples-3p.com/s7/is/image/Staples/1B6FF91A-3111-4FC5-993BBF7E44F1E0BE_sc7?wid=700&hei=700'),
    (841, 'https://www.staples-3p.com/s7/is/image/Staples/sp155560515_sc7?wid=700&hei=700'),
    (841, 'https://www.staples-3p.com/s7/is/image/Staples/sp155560516_sc7?wid=700&hei=700'),
    -- black
    (842, 'https://www.staples-3p.com/s7/is/image/Staples/sp161387743_sc7?wid=700&hei=700'),
    (842, 'https://www.staples-3p.com/s7/is/image/Staples/sp161387838_sc7?wid=700&hei=700'),
    (842, 'https://www.staples-3p.com/s7/is/image/Staples/sp161387839_sc7?wid=700&hei=700'),
    -- red
    (843, 'https://www.staples-3p.com/s7/is/image/Staples/sp102580415_sc7?wid=700&hei=700'),
    (843, 'https://www.staples-3p.com/s7/is/image/Staples/6E4861C8-7E9A-4E8F-9968DE672544E5AA_sc7?wid=700&hei=700'),
    (843, 'https://www.staples-3p.com/s7/is/image/Staples/sp102580416_sc7?wid=700&hei=700'),
    -- green
    (844, 'https://www.staples-3p.com/s7/is/image/Staples/sp40888435_sc7?wid=700&hei=700'),
    (844, 'https://www.staples-3p.com/s7/is/image/Staples/sp40888433_sc7?wid=700&hei=700'),
    (844, 'https://www.staples-3p.com/s7/is/image/Staples/sp40888432_sc7?wid=700&hei=700'),
    -- blue
    (845, 'https://www.staples-3p.com/s7/is/image/Staples/s1184756_sc7?wid=700&hei=700'),
    (845, 'https://www.staples-3p.com/s7/is/image/Staples/614B9DDE-27C9-41AE-89E590D1247EC18B_sc7?wid=700&hei=700'),
    (845, 'https://www.staples-3p.com/s7/is/image/Staples/sp57451607_sc7?wid=700&hei=700'),
    -- purple
    (846, 'https://www.staples-3p.com/s7/is/image/Staples/s1192758_sc7?wid=700&hei=700'),
    (846, 'https://www.staples-3p.com/s7/is/image/Staples/sp49508023_sc7?wid=700&hei=700'),
    
    -- red apex notebook
    (847, 'https://m.media-amazon.com/images/I/81y2PkckqSL._AC_SL1500_.jpg'),
    (847, 'https://i5.walmartimages.com/asr/a5a532f2-8ad9-4b60-9e4e-5cdd439ce47f.d8217e8b065113176b8fd5325d6d0a14.jpeg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF'),
    -- blue apex notebook
    (848, 'https://m.media-amazon.com/images/I/81y2PkckqSL._AC_SL1500_.jpg'),
    (848, 'https://i5.walmartimages.com/asr/a5a532f2-8ad9-4b60-9e4e-5cdd439ce47f.d8217e8b065113176b8fd5325d6d0a14.jpeg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF'),
    -- green apex notebook
    (849, 'https://m.media-amazon.com/images/I/81y2PkckqSL._AC_SL1500_.jpg'),
    (849, 'https://i5.walmartimages.com/asr/a5a532f2-8ad9-4b60-9e4e-5cdd439ce47f.d8217e8b065113176b8fd5325d6d0a14.jpeg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF'),
    -- yellow apex notebook
    (850, 'https://m.media-amazon.com/images/I/81y2PkckqSL._AC_SL1500_.jpg'),
    (850, 'https://i5.walmartimages.com/asr/a5a532f2-8ad9-4b60-9e4e-5cdd439ce47f.d8217e8b065113176b8fd5325d6d0a14.jpeg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF'),
    -- navy apex notebook
    (851, 'https://m.media-amazon.com/images/I/81y2PkckqSL._AC_SL1500_.jpg'),
    (851, 'https://i5.walmartimages.com/asr/a5a532f2-8ad9-4b60-9e4e-5cdd439ce47f.d8217e8b065113176b8fd5325d6d0a14.jpeg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF'),
    -- black apex notebook
    (852, 'https://m.media-amazon.com/images/I/81y2PkckqSL._AC_SL1500_.jpg'),
    (852, 'https://i5.walmartimages.com/asr/a5a532f2-8ad9-4b60-9e4e-5cdd439ce47f.d8217e8b065113176b8fd5325d6d0a14.jpeg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF'),
	-- assorted 6 pack apex notebooks
    (853, 'https://i5.walmartimages.com/seo/VEEBOOST-Spiral-Notebook-Wide-Ruled-Notebooks-Pack-70-Sheets-1-Subject-Notebooks-Bulk-6-Color-Assortment-3-Hole-Perforated-Sheets-6-College-Ruled_1b531551-d0b8-450d-9ff7-afea18bbd779.5271cf7c8925bd50af57f06aba6cc5cc.jpeg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF'),
	(853, 'https://eclipsusa.com/cdn/shop/files/23955Shot_6_Lifestyle.jpg?v=1735326621&width=1946'),
	-- assorted 12 pack apex notebooks
    -- (855, 'https://m.media-amazon.com/images/I/81MjndMAZYL.jpg', 'Assorted 12 Pack - Stacked View'),
    -- (855, 'https://i5.walmartimages.com/asr/a5a532f2-8ad9-4b60-9e4e-5cdd439ce47f.d8217e8b065113176b8fd5325d6d0a14.jpeg?odnHeight=2000&odnWidth=2000&odnBg=FFFFFF', 'Single Notebook - Inside View'),

    -- large post it packs
	(854, 'https://www.staples-3p.com/s7/is/image/Staples/F44DFD2D-9753-43C2-BA3F9790DFDB4DF3_sc7?wid=700&hei=700'),
    (854, 'https://www.staples-3p.com/s7/is/image/Staples/D6069D02-1F52-4573-865AD52B40E466DB_sc7?wid=700&hei=700'),
    (854, 'https://www.staples-3p.com/s7/is/image/Staples/6917C6F4-2B87-488E-97496D7101CBDA1A_sc7?wid=700&hei=700'),
    
    (855, 'https://www.staples-3p.com/s7/is/image/Staples/9C2D556A-98F8-447E-8B5DFCD6EF7C7060_sc7?wid=700&hei=700'),
    (855, 'https://www.staples-3p.com/s7/is/image/Staples/A7CECE27-AB63-4A6F-BA8847561E4603C3_sc7?wid=700&hei=700'),
    (855, 'https://www.staples-3p.com/s7/is/image/Staples/4267CE5D-A42B-456F-9C0B3E82BF2C22C2_sc7?wid=700&hei=700'),
    
    (856, 'https://www.staples-3p.com/s7/is/image/Staples/F8E92CAF-1F6F-4325-873109687F2E8612_sc7?wid=700&hei=700'),
    (856, 'https://www.staples-3p.com/s7/is/image/Staples/E64BABF4-6D56-45D7-ABD2810EA7F1975F_sc7?wid=700&hei=700'),
    (856, 'https://www.staples-3p.com/s7/is/image/Staples/025DA1D9-7F5A-4203-9847D3492D3E5560_sc7?wid=700&hei=700'),
    
    (857, 'https://www.staples-3p.com/s7/is/image/Staples/452A6108-45E7-4047-B9C0874D166A5611_sc7?wid=700&hei=700'),
    (857, 'https://www.staples-3p.com/s7/is/image/Staples/4A0D9376-150E-4414-A33206877C7FEA3C_sc7?wid=700&hei=700'),
    (857, 'https://www.staples-3p.com/s7/is/image/Staples/EACE8D2D-6D38-46F9-B4F9A95F1493316C_sc7?wid=700&hei=700'),
    
    -- small pack post it notes --
	(858, 'https://www.staples-3p.com/s7/is/image/Staples/BFDF1A3E-7119-4F7E-8F987BDB0E8C04E5_sc7?wid=700&hei=700'),
    (858, 'https://www.staples-3p.com/s7/is/image/Staples/62F83CB0-0776-4D80-93FDDBBEF83D02C6_sc7?wid=700&hei=700'),
    (858, 'https://www.staples-3p.com/s7/is/image/Staples/B47EA64D-73EE-4B93-91E3C7553D5CE518_sc7?wid=700&hei=700'),
    
    (859, 'https://www.staples-3p.com/s7/is/image/Staples/E07963F4-0CAF-49AD-BDEB95F98A5CB1EF_sc7?wid=700&hei=700'),
    (859, 'https://www.staples-3p.com/s7/is/image/Staples/763A3A81-4C86-44BE-A4F6B03E6E15D0F5_sc7?wid=700&hei=700'),
    (859, 'https://www.staples-3p.com/s7/is/image/Staples/20B1174F-58C3-4C23-8596C7B33B9C512A_sc7?wid=700&hei=700'),
    
    (860, 'https://www.staples-3p.com/s7/is/image/Staples/326DBC5F-C484-47F3-80F547B9AD68F847_sc7?wid=700&hei=700'),
    (860, 'https://www.staples-3p.com/s7/is/image/Staples/C3B2A525-6B7E-48CC-A5CAB5A9E3C8A227_sc7?wid=700&hei=700'),
    (860, 'https://www.staples-3p.com/s7/is/image/Staples/A30142CC-B670-45A6-83CB1A7200E993CD_sc7?wid=700&hei=700'),
    
    
    (861, 'https://www.staples-3p.com/s7/is/image/Staples/2F939766-0CDF-4383-934896971849A14D_sc7?wid=700&hei=700'),
    (861, 'https://www.staples-3p.com/s7/is/image/Staples/19C11F38-D022-4A2B-B040A007BCDEAD78_sc7?wid=700&hei=700'),
    (861, 'https://www.staples-3p.com/s7/is/image/Staples/D4626D79-761A-4C3D-931E248DEDBBCB5E_sc7?wid=700&hei=700'),
    
    (862, '*'),
    (863, '*'),
    (864, '*'),
	-- black
	(865, 'https://www.staples-3p.com/s7/is/image/Staples/0D3524FF-2832-47D7-A2AACA09B78251AF_sc7?wid=700&hei=700'),
    (865, 'https://www.staples-3p.com/s7/is/image/Staples/D7428E65-0EE6-478F-884DCE28AD123792_sc7?wid=700&hei=700'),
    (865, 'https://www.staples-3p.com/s7/is/image/Staples/2C813818-609C-48B0-A5B72C9270296301_sc7?wid=700&hei=700'),
    (865, 'https://www.staples-3p.com/s7/is/image/Staples/24AD6A77-5DC8-4FBD-989E4FEE55F15DA9_sc7?wid=700&hei=700'),
    (865, 'https://www.staples-3p.com/s7/is/image/Staples/8BB61944-3D48-4CE4-8327F63BF437634F_sc7?wid=700&hei=700'),
    (865, 'https://www.staples-3p.com/s7/is/image/Staples/3E85D25E-1967-4307-8A64BC3BA5F18A62_sc7?wid=700&hei=700'),
    -- navy
    (866, 'https://www.staples-3p.com/s7/is/image/Staples/37B758D7-2B96-4E2D-ABF4E4AAFFE3BC6F_sc7?wid=700&hei=700'),
    (866, 'https://www.staples-3p.com/s7/is/image/Staples/5E737974-B2C3-448C-B4DD1BBC1F1B0F06_sc7?wid=700&hei=700'),
    (866, 'https://www.staples-3p.com/s7/is/image/Staples/58FD9017-97AE-48E8-AAB4269BC0883BD9_sc7?wid=700&hei=700'),
    (866, 'https://www.staples-3p.com/s7/is/image/Staples/8C2DF227-53C1-4D0E-929B8F5EC0A09A2D_sc7?wid=700&hei=700'),
    (866, 'https://www.staples-3p.com/s7/is/image/Staples/E6F89404-A849-45B4-80DCC8BEF18E2DB8_sc7?wid=700&hei=700'),
    (866, 'https://www.staples-3p.com/s7/is/image/Staples/6E602881-5F54-4B2E-996312B335A7FE9B_sc7?wid=700&hei=700'),
    -- orchid
    (867, 'https://www.staples-3p.com/s7/is/image/Staples/A9809EBD-5FCC-4A03-B40FAFB26118DA2D_sc7?wid=700&hei=700'),
    (867, 'https://www.staples-3p.com/s7/is/image/Staples/B3D23C50-568C-4B28-959B3CF228CC8C89_sc7?wid=700&hei=700'),
    (867, 'https://www.staples-3p.com/s7/is/image/Staples/5C21529A-EFDE-448E-A53EAC257AE36928_sc7?wid=700&hei=700'),
    (867, 'https://www.staples-3p.com/s7/is/image/Staples/053E5E0E-70C8-40E7-925992EE95C92A2E_sc7?wid=700&hei=700'),
    (867, 'https://www.staples-3p.com/s7/is/image/Staples/561C327E-6541-411D-9BD30A2BC1684949_sc7?wid=700&hei=700'),
    (867, 'https://www.staples-3p.com/s7/is/image/Staples/EC589213-4362-47E4-BB4383489F986315_sc7?wid=700&hei=700'),
    -- white
    (868, 'https://www.staples-3p.com/s7/is/image/Staples/0278D8CC-CD92-488F-A51BBFEF8525B601_sc7?wid=700&hei=700'),
    (868, 'https://www.staples-3p.com/s7/is/image/Staples/458B3FB4-6391-4DA2-A81E960707074A01_sc7?wid=700&hei=700'),
    (868, 'https://www.staples-3p.com/s7/is/image/Staples/6057FEA6-587E-428E-A1EB00AA985361D8_sc7?wid=700&hei=700'),
    (868, 'https://www.staples-3p.com/s7/is/image/Staples/3ABF2577-407D-4AE7-83BFA04EC3F81832_sc7?wid=700&hei=700'),
    (868, 'https://www.staples-3p.com/s7/is/image/Staples/C4FFF143-A820-4A77-907625918C01B691_sc7?wid=700&hei=700'),
    (868, 'https://www.staples-3p.com/s7/is/image/Staples/2B6ADFEF-D3DE-4B33-9CEF5C1D71C9741E_sc7?wid=700&hei=700'),
    
    -- bentogo pop lunch box --
    -- red
    (869, 'https://www.staples-3p.com/s7/is/image/Staples/7802D637-CB82-415E-AD543B5AECD0F8B0_sc7?wid=700&hei=700'),
    (869, 'https://www.staples-3p.com/s7/is/image/Staples/84239C76-86E5-491D-BA3738AC08D7078B_sc7?wid=700&hei=700'),
    (869, 'https://www.staples-3p.com/s7/is/image/Staples/820464A3-38B8-4F93-AE794889BBE4E222_sc7?wid=700&hei=700'),
    (869, 'https://www.staples-3p.com/s7/is/image/Staples/6789F01A-E7F3-4C16-A9C0B5A03DB540C3_sc7?wid=700&hei=700'),
    (869, 'https://www.staples-3p.com/s7/is/image/Staples/459428D1-2F4C-4A2B-ACA9B062AC797467_sc7?wid=700&hei=700'),
    (869, 'https://www.staples-3p.com/s7/is/image/Staples/1EF62BCA-C053-4587-9EAA8547341A6F6D_sc7?wid=700&hei=700'),
    -- pink
    (870, 'https://www.staples-3p.com/s7/is/image/Staples/B94BEB4E-D957-48EF-95D72577308D9D9E_sc7?wid=700&hei=700'),
    (870, 'https://www.staples-3p.com/s7/is/image/Staples/C86E6289-5F11-4B7F-8134AB18B8BBCEDF_sc7?wid=700&hei=700'),
    (870, 'https://www.staples-3p.com/s7/is/image/Staples/BB5695B7-BB6D-4041-870DD10C8694077D_sc7?wid=700&hei=700'),
    (870, 'https://www.staples-3p.com/s7/is/image/Staples/454A7A0F-3B24-496D-8825EACBDDFE9136_sc7?wid=700&hei=700'),
    (870, 'https://www.staples-3p.com/s7/is/image/Staples/DC8A7FB9-DEA9-4F01-90E512858E58C32B_sc7?wid=700&hei=700'),
    (870, 'https://www.staples-3p.com/s7/is/image/Staples/5241D329-4F2A-4FB5-A8A9F25AF1827BC1_sc7?wid=700&hei=700'),
    -- light green
    (871, 'https://www.staples-3p.com/s7/is/image/Staples/99B9D519-6226-4D08-B5D63D58833982D0_sc7?wid=700&hei=700'),
    (871, 'https://www.staples-3p.com/s7/is/image/Staples/A1EB8473-94EF-47B3-92B2E6BED0600A15_sc7?wid=700&hei=700'),
    (871, 'https://www.staples-3p.com/s7/is/image/Staples/D45B7B60-D35B-487A-8DF59B7CDEECAC7E_sc7?wid=700&hei=700'),
    (871, 'https://www.staples-3p.com/s7/is/image/Staples/563C0F35-F21A-4A5D-A4F71A8DB0D7D22D_sc7?wid=700&hei=700'),
    (871, 'https://www.staples-3p.com/s7/is/image/Staples/43147E57-97C4-4D52-A7EFB57CCBBA7CBE_sc7?wid=700&hei=700'),
    (871, 'https://www.staples-3p.com/s7/is/image/Staples/C29F0E87-FCF5-4588-BEA9AAC74014BFC1_sc7?wid=700&hei=700'),
    -- light blue
    (872, 'https://www.staples-3p.com/s7/is/image/Staples/4CC559BD-0238-429E-A7313225AB132440_sc7?wid=700&hei=700'),
    (872, 'https://www.staples-3p.com/s7/is/image/Staples/8AFD60A3-5403-473F-A1541896FB8CC470_sc7?wid=700&hei=700'),
    (872, 'https://www.staples-3p.com/s7/is/image/Staples/342935CA-7C09-4E4B-B093C4DB3B578A30_sc7?wid=700&hei=700'),
    (872, 'https://www.staples-3p.com/s7/is/image/Staples/E3BE1F16-4503-4980-8DA18F6B6E041180_sc7?wid=700&hei=700'),
    (872, 'https://www.staples-3p.com/s7/is/image/Staples/EB90F81D-1EF8-4950-A2A086EEF78B1D93_sc7?wid=700&hei=700'),
    (872, 'https://www.staples-3p.com/s7/is/image/Staples/18E0B232-5AC9-4758-AEE8BA168DDC3058_sc7?wid=700&hei=700'),
    -- dark blue
    (873, 'https://www.staples-3p.com/s7/is/image/Staples/9483D0B0-C978-4EF1-8E0C2F1C0FC4375A_sc7?wid=700&hei=700'),
    (873, 'https://www.staples-3p.com/s7/is/image/Staples/CBDE0746-0BBD-4B9B-A27394B9C7B9AD5A_sc7?wid=700&hei=700'),
    (873, 'https://www.staples-3p.com/s7/is/image/Staples/A4C81F63-7C65-40E8-B151CD67AB13A1C0_sc7?wid=700&hei=700'),
    (873, 'https://www.staples-3p.com/s7/is/image/Staples/5271254D-38E5-4650-9039CE4B4F650C68_sc7?wid=700&hei=700'),
    (873, 'https://www.staples-3p.com/s7/is/image/Staples/DDEFA5EE-FF77-4D88-9C3897C9C5ABF86C_sc7?wid=700&hei=700'),
    (873, 'https://www.staples-3p.com/s7/is/image/Staples/05D9E779-A5E0-4E12-909095440A75E541_sc7?wid=700&hei=700'),

    -- jam kraft brown paper bags --
	(874, 'https://www.staples-3p.com/s7/is/image/Staples/sp71001592_sc7?wid=700&hei=700'),
    (874, 'https://www.staples-3p.com/s7/is/image/Staples/sp71001593_sc7?wid=700&hei=700'),
    (874, 'https://www.staples-3p.com/s7/is/image/Staples/sp71001594_sc7?wid=700&hei=700'),

-- backpacks
	-- lilac
	(875, 'https://www.staples-3p.com/s7/is/image/Staples/sp169025046_sc7?wid=700&hei=700'),
	(875, 'https://www.staples-3p.com/s7/is/image/Staples/sp169025047_sc7?wid=700&hei=700'),
	(875, 'https://www.staples-3p.com/s7/is/image/Staples/sp169025048_sc7?wid=700&hei=700'),
    -- black
	(876, 'https://www.staples-3p.com/s7/is/image/Staples/sp40888791_sc7?wid=700&hei=700'),
    (876, 'https://www.staples-3p.com/s7/is/image/Staples/sp40888792_sc7?wid=700&hei=700'),
    (876, 'https://www.staples-3p.com/s7/is/image/Staples/sp40888793_sc7?wid=700&hei=700'),
    -- dark blue
    (877, 'https://www.staples-3p.com/s7/is/image/Staples/s1082362_sc7?wid=700&hei=700'),
    -- rose pink
    (878, 'https://www.staples-3p.com/s7/is/image/Staples/sp150961408_sc7?wid=700&hei=700'),
    (878, 'https://www.staples-3p.com/s7/is/image/Staples/sp150961409_sc7?wid=700&hei=700'),
    (878, 'https://www.staples-3p.com/s7/is/image/Staples/sp150961410_sc7?wid=700&hei=700'),
    -- sky blue
    (879, 'https://www.staples-3p.com/s7/is/image/Staples/A42527E5-1616-4463-975C38BBC150D177_sc7?wid=700&hei=700'),
    (879, 'https://www.staples-3p.com/s7/is/image/Staples/639855A4-A270-4DE2-89D1D0CCA0E89EE9_sc7?wid=700&hei=700'),

    -- dark red
    (880, 'https://www.staples-3p.com/s7/is/image/Staples/6F48881A-03DA-4D2D-B9A500674071B711_sc7?wid=700&hei=700'),
    (880, 'https://www.staples-3p.com/s7/is/image/Staples/70DAC7C3-DF86-421C-9C401CB4A3077035_sc7?wid=700&hei=700'),
    (880, 'https://www.staples-3p.com/s7/is/image/Staples/357DABE7-4E00-4964-A4DFED41577FCE66_sc7?wid=700&hei=700'),
    (880, 'https://www.staples-3p.com/s7/is/image/Staples/6D3276E6-2D0A-4C86-8CC5F92645E6AFAA_sc7?wid=700&hei=700'),
    -- pattern baltik
    (881, 'https://www.staples-3p.com/s7/is/image/Staples/FD9E3E64-F254-4D26-BB64AE738D1FCB6E_sc7?wid=700&hei=700'),
    (881, 'https://www.staples-3p.com/s7/is/image/Staples/1EF6D154-8899-4E93-882FB4A329BB2CA4_sc7?wid=700&hei=700'),
    
    -- floral
    (882, 'https://www.staples-3p.com/s7/is/image/Staples/34D30FCB-3D50-482D-8144049713B364E2_sc7?wid=700&hei=700'),
    (882, 'https://www.staples-3p.com/s7/is/image/Staples/283E7B9A-395F-46CD-9A1C536D65A1316C_sc7?wid=700&hei=700'),
    
    -- galaxy
    (883, 'https://www.staples-3p.com/s7/is/image/Staples/3770177A-F2DB-4F15-BC64FB4C4E707090_sc7?wid=700&hei=700'),
    (883, 'https://www.staples-3p.com/s7/is/image/Staples/7BB0CE69-8AEA-4DB5-8AA4122D306CDACE_sc7?wid=700&hei=700'),
    
    -- fiskars scissors
    (884, 'https://www.staples-3p.com/s7/is/image/Staples/F880E890-965C-4DBD-9BF2C7449FD0D5FB_sc7?wid=700&hei=700'),
    
    -- elmers glue sticks
    (885, 'https://www.staples-3p.com/s7/is/image/Staples/sp161466975_sc7?wid=700&hei=700'),
    (885, 'https://www.staples-3p.com/s7/is/image/Staples/sp161466773_sc7?wid=700&hei=700'),
    (885, 'https://www.staples-3p.com/s7/is/image/Staples/sp161466774_sc7?wid=700&hei=700'),
    (885, 'https://www.staples-3p.com/s7/is/image/Staples/sp161466946_sc7?wid=700&hei=700'),
    (885, '*'),
    
    (886, 'https://www.staples-3p.com/s7/is/image/Staples/sp161466816_sc7?wid=700&hei=700'),
    (886, 'https://www.staples-3p.com/s7/is/image/Staples/sp161466819_sc7?wid=700&hei=700'),
    (886, 'https://www.staples-3p.com/s7/is/image/Staples/sp161466823_sc7?wid=700&hei=700'),
    (886, 'https://www.staples-3p.com/s7/is/image/Staples/sp161466821_sc7?wid=700&hei=700'),
    
    (887, 'https://www.staples-3p.com/s7/is/image/Staples/sp86239112_sc7?wid=700&hei=700'),
    (887, 'https://www.staples-3p.com/s7/is/image/Staples/sp86239113_sc7?wid=700&hei=700'),
    (887, 'https://www.staples-3p.com/s7/is/image/Staples/sp86239114_sc7?wid=700&hei=700'),
    (887, 'https://www.staples-3p.com/s7/is/image/Staples/sp86239115_sc7?wid=700&hei=700'),
    
    (888, 'https://www.staples-3p.com/s7/is/image/Staples/sp222027441_sc7?wid=700&hei=700'),
    (888, 'https://www.staples-3p.com/s7/is/image/Staples/sp222027442_sc7?wid=700&hei=700'),
    (888, 'https://www.staples-3p.com/s7/is/image/Staples/sp222027443_sc7?wid=700&hei=700'),
    (888, 'https://www.staples-3p.com/s7/is/image/Staples/sp222027444_sc7?wid=700&hei=700'),
    (888, 'https://www.staples-3p.com/s7/is/image/Staples/sp222027445_sc7?wid=700&hei=700'),

    (889, 'https://www.staples-3p.com/s7/is/image/Staples/11063273-E98B-46FB-9D1C237A96D9115C_sc7?wid=700&hei=700'),
    (889, 'https://www.staples-3p.com/s7/is/image/Staples/CE53EDCF-FAE0-4DB8-913AC9BD27D7E019_sc7?wid=700&hei=700'),
    (889, 'https://www.staples-3p.com/s7/is/image/Staples/BA06CDFF-00AC-4DF3-92EF89ACCDF6C90F_sc7?wid=700&hei=700'),
    (889, 'https://www.staples-3p.com/s7/is/image/Staples/49BADA3E-C6EA-4CDF-B7601BFE4168A4F3_sc7?wid=700&hei=700'),

    (890, 'https://www.staples-3p.com/s7/is/image/Staples/CF953BE9-0A69-4668-B505684660540250_sc7?wid=700&hei=700'),
    (890, 'https://www.staples-3p.com/s7/is/image/Staples/0574AB13-BC19-48A3-808A24C3873D7921_sc7?wid=700&hei=700'),
    (890, 'https://www.staples-3p.com/s7/is/image/Staples/05AB2272-9D5B-4C40-B0157AB0B041471C_sc7?wid=700&hei=700'),
    (890, 'https://www.staples-3p.com/s7/is/image/Staples/10F99B35-1C80-495C-A30CE6BF1F39A2EC_sc7?wid=700&hei=700'),

    (891, 'https://www.staples-3p.com/s7/is/image/Staples/29C12086-2E8B-49D1-B422BD659B01A05D_sc7?wid=700&hei=700'),
    (891, 'https://www.staples-3p.com/s7/is/image/Staples/7BEA3649-0CC4-4780-9D062EC29C292530_sc7?wid=700&hei=700'),
    (891, 'https://www.staples-3p.com/s7/is/image/Staples/55660E2E-3F23-434C-9444A6D1567B9115_sc7?wid=700&hei=700'),
    
    (892, 'https://www.staples-3p.com/s7/is/image/Staples/941DD4A5-8BB3-4528-8CAAF94F24ACC3C0_sc7?wid=700&hei=700'),
    (892, 'https://www.staples-3p.com/s7/is/image/Staples/941DD4A5-8BB3-4528-8CAAF94F24ACC3C0_sc7?wid=700&hei=700'),
    (892, 'https://www.staples-3p.com/s7/is/image/Staples/7EB6B603-3FE4-43C3-A848E17CE6147FC7_sc7?wid=700&hei=700'),

    (893, 'https://www.staples-3p.com/s7/is/image/Staples/BB2926B9-034C-49A6-9763CE02A535A808_sc7?wid=700&hei=700'),
    (893, 'https://www.staples-3p.com/s7/is/image/Staples/EF3A40E9-9B2D-49F9-A75FA181B703B32F_sc7?wid=700&hei=700'),
    (893, 'https://www.staples-3p.com/s7/is/image/Staples/F58D711D-327D-42E4-8A61547D02C07A77_sc7?wid=700&hei=700'),
    (893, 'https://www.staples-3p.com/s7/is/image/Staples/51782929-A8CE-47A9-8490A2B2FB8B7EC6_sc7?wid=700&hei=700'),

    (894, 'https://www.staples-3p.com/s7/is/image/Staples/145C0E87-28A8-465E-81C59A9CE699F8A7_sc7?wid=700&hei=700'),
    (894, 'https://www.staples-3p.com/s7/is/image/Staples/275EBC20-088D-4AC5-8787B2C935A83B69_sc7?wid=700&hei=700'),
    (894, 'https://www.staples-3p.com/s7/is/image/Staples/545D12DE-4CCD-4866-8C8006A1AC9D70C6_sc7?wid=700&hei=700'),
    (894, 'https://www.staples-3p.com/s7/is/image/Staples/5C7349A8-0829-40E4-A76B3279719738E8_sc7?wid=700&hei=700'),

    (895, 'https://www.staples-3p.com/s7/is/image/Staples/sp36292377_sc7?wid=700&hei=700'),
    (895, 'https://www.staples-3p.com/s7/is/image/Staples/sp36292378_sc7?wid=700&hei=700'),

    (896, 'https://www.staples-3p.com/s7/is/image/Staples/sp36292379_sc7?wid=700&hei=700'),
    (896, 'https://www.staples-3p.com/s7/is/image/Staples/s0381730_sc7?wid=700&hei=700'),

    (897, 'https://www.staples-3p.com/s7/is/image/Staples/3E27756C-7302-4ED5-A455BE19F8A00A9E_sc7?wid=700&hei=700'),

    (898, 'https://www.staples-3p.com/s7/is/image/Staples/sp40319133_sc7?wid=700&hei=700'),

    (899, 'https://www.staples-3p.com/s7/is/image/Staples/sp36292364_sc7?wid=700&hei=700'),

    (900, 'https://www.staples-3p.com/s7/is/image/Staples/sp36292370_sc7?wid=700&hei=700'),
    (900, 'https://www.staples-3p.com/s7/is/image/Staples/sp36292371_sc7?wid=700&hei=700'),

    (901, 'https://www.staples-3p.com/s7/is/image/Staples/sp74866313_sc7?wid=700&hei=700'),
    (901, 'https://www.staples-3p.com/s7/is/image/Staples/sp74866314_sc7?wid=700&hei=700'),
    (901, 'https://www.staples-3p.com/s7/is/image/Staples/sp74866310_sc7?wid=700&hei=700'),
    (901, 'https://www.staples-3p.com/s7/is/image/Staples/sp74866311_sc7?wid=700&hei=700'),
    (901, 'https://www.staples-3p.com/s7/is/image/Staples/sp74866312_sc7?wid=700&hei=700'),
-- paint red
    (902, 'https://www.staples-3p.com/s7/is/image/Staples/sp66600518_sc7?wid=700&hei=700'),
    (902, 'https://www.staples-3p.com/s7/is/image/Staples/sp66600513_sc7?wid=700&hei=700'),

    (903, 'https://www.staples-3p.com/s7/is/image/Staples/sp66600491_sc7?wid=700&hei=700'),
    (903, 'https://www.staples-3p.com/s7/is/image/Staples/sp66600492_sc7?wid=700&hei=700'),
    (903, 'https://www.staples-3p.com/s7/is/image/Staples/sp66600406_sc7?wid=700&hei=700'),

    (904, 'https://www.staples-3p.com/s7/is/image/Staples/sp66600462_sc7?wid=700&hei=700'),
    (904, 'https://www.staples-3p.com/s7/is/image/Staples/sp66600459_sc7?wid=700&hei=700'),
    (904, 'https://www.staples-3p.com/s7/is/image/Staples/sp66600458_sc7?wid=700&hei=700'),

    (905, 'https://www.staples-3p.com/s7/is/image/Staples/sp66600623_sc7?wid=700&hei=700'),
    (905, 'https://www.staples-3p.com/s7/is/image/Staples/sp66600617_sc7?wid=700&hei=700'),
    
    (906, 'https://www.staples-3p.com/s7/is/image/Staples/s0068169_sc7?wid=700&hei=700'),
    (906, 'https://www.staples-3p.com/s7/is/image/Staples/s0166818_sc7?wid=700&hei=700'),
    
    (907, 'https://www.staples-3p.com/s7/is/image/Staples/m007093057_sc7?wid=700&hei=700'),
    
    (908, 'https://www.staples-3p.com/s7/is/image/Staples/sp66601198_sc7?wid=700&hei=700'),
    (908, 'https://www.staples-3p.com/s7/is/image/Staples/sp66601191_sc7?wid=700&hei=700'),
    (908, 'https://www.staples-3p.com/s7/is/image/Staples/sp66601193_sc7?wid=700&hei=700'),
    
    (909, 'https://www.staples-3p.com/s7/is/image/Staples/sp97810692_sc7?wid=700&hei=700'),
    (909, 'https://www.staples-3p.com/s7/is/image/Staples/sp97810695_sc7?wid=700&hei=700'),

    (910, 'https://www.staples-3p.com/s7/is/image/Staples/sp34067352_sc7?wid=700&hei=700'),
    (910, 'https://www.staples-3p.com/s7/is/image/Staples/sp34067357_sc7?wid=700&hei=700'),
    
    (911, 'https://www.staples-3p.com/s7/is/image/Staples/814B79CD-8C48-45F0-B3598CBA7F6C3C94_sc7?wid=700&hei=700'),
    (911, 'https://www.staples-3p.com/s7/is/image/Staples/9993840A-6CE0-45B3-8FD3DD07DF563297_sc7?wid=700&hei=700'),
    (911, 'https://www.staples-3p.com/s7/is/image/Staples/15952A1D-8415-4987-A5170BCC3B49C6E9_sc7?wid=700&hei=700'),
    (911, 'https://www.staples-3p.com/s7/is/image/Staples/647AAF7F-6B7F-4346-99575DC5FD307175_sc7?wid=700&hei=700'),
    (911, 'https://www.staples-3p.com/s7/is/image/Staples/AC3BF813-0461-401E-8527DDD7C045B35F_sc7?wid=700&hei=700'),
    
    (912, 'https://www.staples-3p.com/s7/is/image/Staples/7EB95350-001B-4FCA-8A10BE7D017380E2_sc7?wid=700&hei=700'),
    
    (913, 'https://www.staples-3p.com/s7/is/image/Staples/m007111304_sc7?wid=700&hei=700'),
    
    (914, 'https://www.staples-3p.com/s7/is/image/Staples/sp55888274_sc7?wid=700&hei=700'),
    
    (915, 'https://www.staples-3p.com/s7/is/image/Staples/sp128054629_sc7?wid=700&hei=700'),
    
    (916, 'https://www.staples-3p.com/s7/is/image/Staples/FA781511-4D0F-402E-95A8554B62E54C85_sc7?wid=700&hei=700'),
    (916, 'https://www.staples-3p.com/s7/is/image/Staples/8A225CD5-B8C6-43AF-92BEBAFCED34C027_sc7?wid=700&hei=700'),
    (916, 'https://www.staples-3p.com/s7/is/image/Staples/A3C14608-741B-4537-B48B742491FF16DE_sc7?wid=700&hei=700'),
    (916, 'https://www.staples-3p.com/s7/is/image/Staples/A0392C61-8B42-4DF2-83935F868A201E95_sc7?wid=700&hei=700'),
    (916, 'https://www.staples-3p.com/s7/is/image/Staples/14644629-505D-46D2-AB7B0EAEA86FB3F1_sc7?wid=700&hei=700'),
    
-- crayola colored pencils --
	-- pastel 12pack
	(917, 'https://www.staples-3p.com/s7/is/image/Staples/7F85263E-79E0-437C-A14FBE37C21CF681_sc7?wid=700&hei=700'),
	(917, 'https://www.staples-3p.com/s7/is/image/Staples/8F60F9E4-F334-416E-AAF7A89CE5D42CB5_sc7?wid=700&hei=700'),
	(917, 'https://www.staples-3p.com/s7/is/image/Staples/529F8607-C73D-4C14-82C35B42E22530A7_sc7?wid=700&hei=700'),
	(917, 'https://www.staples-3p.com/s7/is/image/Staples/307831B6-1D03-4D44-9B3234FD9D4FB14A_sc7?wid=700&hei=700'),
	-- regular/assorted 12pack
	(918, 'https://www.staples-3p.com/s7/is/image/Staples/5D27A585-FF26-4D7E-AF465FFEB2F8345D_sc7?wid=700&hei=700'),
	(918, 'https://www.staples-3p.com/s7/is/image/Staples/12D715CB-091E-4CEB-A592F528A41F3A39_sc7?wid=700&hei=700'),
	(918, 'https://www.staples-3p.com/s7/is/image/Staples/0AD39FB7-989F-453C-A9263138AEA15D3F_sc7?wid=700&hei=700'),
	(918, 'https://www.staples-3p.com/s7/is/image/Staples/35A652D4-B70D-42F3-B3556E4906C6F7DC_sc7?wid=700&hei=700'),
	(918, 'https://www.staples-3p.com/s7/is/image/Staples/E7741D8E-CEEE-4656-9517293FC4EA812E_sc7?wid=700&hei=700'),
	-- colors of the world 24 pack
	(919, 'https://www.staples-3p.com/s7/is/image/Staples/sp107458503_sc7?wid=700&hei=700'),
	(919, 'https://www.staples-3p.com/s7/is/image/Staples/sp107458504_sc7?wid=700&hei=700'),
	-- regular/assorted 36pack
	(920, 'https://www.staples-3p.com/s7/is/image/Staples/E58203F0-4B7A-49F5-97F5F8C1D01E9AE9_sc7?wid=700&hei=700'),
	(920, 'https://www.staples-3p.com/s7/is/image/Staples/2FFD9C47-E842-4EBF-A4C92197AF333E9F_sc7?wid=700&hei=700'),
	(920, 'https://www.staples-3p.com/s7/is/image/Staples/B47C356C-0778-4C50-87D02840E032D1D2_sc7?wid=700&hei=700'),
	(920, 'https://www.staples-3p.com/s7/is/image/Staples/D37E02DF-3AAF-4716-894F6BB6483C674A_sc7?wid=700&hei=700'),
	(920, 'https://www.staples-3p.com/s7/is/image/Staples/0D8AC005-1BBC-4CC5-88B785A978D06294_sc7?wid=700&hei=700'),
	-- regular/assorted 100pack
	(921, 'https://www.staples-3p.com/s7/is/image/Staples/sp56580404_sc7?wid=700&hei=700'),
	(921, 'https://www.staples-3p.com/s7/is/image/Staples/sp56580405_sc7?wid=700&hei=700'),
	(921, 'https://www.staples-3p.com/s7/is/image/Staples/sp56580406_sc7?wid=700&hei=700'),
	-- kids short regular/assorted 64pack
	(922, 'https://www.staples-3p.com/s7/is/image/Staples/527776E5-86D8-4BAA-873E5AD5FA854693_sc7?wid=700&hei=700'),
	(922, 'https://www.staples-3p.com/s7/is/image/Staples/211FBE95-ED40-43DF-80AA4CF3CFB0D02B_sc7?wid=700&hei=700'),
	(922, 'https://www.staples-3p.com/s7/is/image/Staples/B605D84F-736D-4A9A-892F9AE12E140D52_sc7?wid=700&hei=700'),
	(922, 'https://www.staples-3p.com/s7/is/image/Staples/0FF2591A-2E28-47F2-AB7160F64E680109_sc7?wid=700&hei=700'),
	(922, 'https://www.staples-3p.com/s7/is/image/Staples/D4770902-036D-4AA8-B101400D9DB788F7_sc7?wid=700&hei=700'),
	
	-- crayola crayons --
	-- classpack 80/box assorted
	(923, 'https://www.staples-3p.com/s7/is/image/Staples/EA29EB3B-116D-4C15-BFDAE2CAC268F59B_sc7?wid=700&hei=700'),
	(923, 'https://www.staples-3p.com/s7/is/image/Staples/49AEE1EE-747F-41AC-98AD44CE837AC3FE_sc7?wid=700&hei=700'),
	(923, 'https://www.staples-3p.com/s7/is/image/Staples/29E32DFA-769F-4233-938487200334E99A_sc7?wid=700&hei=700'),
	(923, 'https://www.staples-3p.com/s7/is/image/Staples/5B3A5113-5ECB-4045-ADF3B217D7E31C5C_sc7?wid=700&hei=700'),
	(923, 'https://www.staples-3p.com/s7/is/image/Staples/40992B7F-67B8-473A-94B12A9CEA5A609B_sc7?wid=700&hei=700'),
	
	-- 24/pack regular/assorted
	(924, 'https://www.staples-3p.com/s7/is/image/Staples/EFA6E1CD-D33E-499E-80C60408C7458DE7_sc7?wid=700&hei=700'),
	(924, 'https://www.staples-3p.com/s7/is/image/Staples/F26DDEFF-4824-4895-BC070726A57B234D_sc7?wid=700&hei=700'),
	(924, 'https://www.staples-3p.com/s7/is/image/Staples/69AD0382-DB7F-4F91-BECEF168ABB9B91E_sc7?wid=700&hei=700'),
	(924, 'https://www.staples-3p.com/s7/is/image/Staples/E7DB3A9A-DF0F-44BA-8ADE94A783070CDA_sc7?wid=700&hei=700'),
	(924, 'https://www.staples-3p.com/s7/is/image/Staples/272F2A6A-F2DD-4E69-AC5407A41847C1FE_sc7?wid=700&hei=700'),
	-- 24pack metallic assorted
	(925, 'https://www.staples-3p.com/s7/is/image/Staples/sp138066198_sc7?wid=700&hei=700'),
	(925, 'https://www.staples-3p.com/s7/is/image/Staples/sp138066201_sc7?wid=700&hei=700'),
	(925, 'https://www.staples-3p.com/s7/is/image/Staples/sp138066200_sc7?wid=700&hei=700'),
	(925, 'https://www.staples-3p.com/s7/is/image/Staples/sp138066199_sc7?wid=700&hei=700'),
	-- 24pack pastel assorted (colors of kindness pack)
	(926, 'https://www.staples-3p.com/s7/is/image/Staples/sp152284712_sc7?wid=700&hei=700'),
	(926, 'https://www.staples-3p.com/s7/is/image/Staples/sp152284713_sc7?wid=700&hei=700'),
	(926, 'https://www.staples-3p.com/s7/is/image/Staples/sp152284714_sc7?wid=700&hei=700'),
	(926, 'https://www.staples-3p.com/s7/is/image/Staples/sp152284715_sc7?wid=700&hei=700'),
	(926, 'https://www.staples-3p.com/s7/is/image/Staples/sp152284716_sc7?wid=700&hei=700'),
	(926, 'https://www.staples-3p.com/s7/is/image/Staples/sp152284717_sc7?wid=700&hei=700'),
	(926, 'https://www.staples-3p.com/s7/is/image/Staples/sp152284718_sc7?wid=700&hei=700'),
	-- 120pack regular/assorted
	(927, 'https://www.staples-3p.com/s7/is/image/Staples/49181D2F-44A7-425F-A077EF3A7FB61CEA_sc7?wid=700&hei=700'),
	(927, 'https://www.staples-3p.com/s7/is/image/Staples/8536C452-6E42-4F58-9008D3B2666E3265_sc7?wid=700&hei=700'),
	(927, 'https://www.staples-3p.com/s7/is/image/Staples/F1B734B2-56EA-4386-81328AD005BCADB7_sc7?wid=700&hei=700'),
	(927, 'https://www.staples-3p.com/s7/is/image/Staples/34987F2C-882C-49B2-A98D5681661CDFAE_sc7?wid=700&hei=700'),
    -- 8pack regular/assorted
	(928, 'https://www.staples-3p.com/s7/is/image/Staples/sp64626997_sc7?wid=700&hei=700'),
	(928, 'https://www.staples-3p.com/s7/is/image/Staples/sp64626998_sc7?wid=700&hei=700'),
	(928, 'https://www.staples-3p.com/s7/is/image/Staples/sp64626994_sc7?wid=700&hei=700'),
	(928, 'https://www.staples-3p.com/s7/is/image/Staples/sp64626995_sc7?wid=700&hei=700'),
	-- large washable 8pack assorted
	(929, 'https://www.staples-3p.com/s7/is/image/Staples/sp71925575_sc7?wid=700&hei=700'),
	(929, 'https://www.staples-3p.com/s7/is/image/Staples/sp71925574_sc7?wid=700&hei=700'),
	(929, 'https://www.staples-3p.com/s7/is/image/Staples/sp71925576_sc7?wid=700&hei=700'),
	(929, 'https://www.staples-3p.com/s7/is/image/Staples/sp71925577_sc7?wid=700&hei=700'),

	-- pacon origomi paper
	(930, 'https://www.staples-3p.com/s7/is/image/Staples/s0355585_sc7?wid=700&hei=700'),
	-- crayola 96sheet
	(931, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455179_sc7?wid=700&hei=700'),
	(931, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455181_sc7?wid=700&hei=700'),
	(931, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455182_sc7?wid=700&hei=700'),
	(931, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455178_sc7?wid=700&hei=700'),
	-- crayola 240sheet 
	(932, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455498_sc7?wid=700&hei=700'),
	(932, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455500_sc7?wid=700&hei=700'),
	(932, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455502_sc7?wid=700&hei=700'),
	(932, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455503_sc7?wid=700&hei=700'),
	(932, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455497_sc7?wid=700&hei=700'),
	-- crayola 96sheet 12bulk pack
	(933, 'https://www.staples-3p.com/s7/is/image/Staples/sp128051988_sc7?wid=700&hei=700'),
	(933, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455181_sc7?wid=700&hei=700'),
	(933, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455182_sc7?wid=700&hei=700'),
	(933, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455178_sc7?wid=700&hei=700'),
	-- crayola 240sheet 3 bulk pack
	(934, 'https://www.staples-3p.com/s7/is/image/Staples/95B45050-A9A5-48BC-AC6E70A0A9072CDD_sc7?wid=700&hei=700'),
	(934, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455500_sc7?wid=700&hei=700'),
	(934, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455502_sc7?wid=700&hei=700'),
	(934, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455503_sc7?wid=700&hei=700'),
	(934, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455497_sc7?wid=700&hei=700'),
	-- crayola giant paper 48sheet
	(935, 'https://www.staples-3p.com/s7/is/image/Staples/93B8D66E-3314-49DB-B96B213051B38BCC_sc7?wid=700&hei=700'),
	(935, 'https://www.staples-3p.com/s7/is/image/Staples/sp85143793_sc7?wid=700&hei=700'),
	(935, 'https://www.staples-3p.com/s7/is/image/Staples/0CF804E5-76CA-4D58-8100F8D3BD53EEEA_sc7?wid=700&hei=700'),
	(935, 'https://www.staples-3p.com/s7/is/image/Staples/sp85143832_sc7?wid=700&hei=700'),
	-- crayola giant paper 48sheet 6bulk pack
	(936, 'https://www.staples-3p.com/s7/is/image/Staples/sp128051987_sc7?wid=700&hei=700'),
	(936, 'https://www.staples-3p.com/s7/is/image/Staples/sp85143793_sc7?wid=700&hei=700'),
	(936, 'https://www.staples-3p.com/s7/is/image/Staples/0CF804E5-76CA-4D58-8100F8D3BD53EEEA_sc7?wid=700&hei=700'),
	(936, 'https://www.staples-3p.com/s7/is/image/Staples/sp85143832_sc7?wid=700&hei=700'),

	-- coloring books --
	-- crayola bluey
	(938, 'https://www.staples-3p.com/s7/is/image/Staples/AD8F2AE1-DB2E-4EEC-B24442C7B3BBCA1B_sc7?wid=700&hei=700'),
	-- crayola retired colors 
	(939, 'https://www.staples-3p.com/s7/is/image/Staples/C517303C-8CB9-4CE0-911D72D9BA7D28A8_sc7?wid=700&hei=700'),
	(939, 'https://www.staples-3p.com/s7/is/image/Staples/EEF52310-1D8F-4733-8C46BEB4C545D8B3_sc7?wid=700&hei=700'),
	-- bendon frozen 2
	(940, 'https://www.staples-3p.com/s7/is/image/Staples/E4178F86-7CBE-4D08-A1933F661428C2FE_sc7?wid=700&hei=700'),
	(940, 'https://www.staples-3p.com/s7/is/image/Staples/F056EE9A-BC96-4FCF-9481273AC642E2CB_sc7?wid=700&hei=700'),
	(940, 'https://www.staples-3p.com/s7/is/image/Staples/583FED6E-BD55-4DF5-9A8241E441D181B5_sc7?wid=700&hei=700'),
	-- bendon paw patrol
	(941, 'https://www.staples-3p.com/s7/is/image/Staples/189A041D-EC4D-4143-B7916355A349C3A8_sc7?wid=700&hei=700'),
	(941, 'https://www.staples-3p.com/s7/is/image/Staples/79B84B23-E8B4-4FD8-88D597DD0AF9BEAC_sc7?wid=700&hei=700'),
	(941, 'https://www.staples-3p.com/s7/is/image/Staples/150E4AFF-2E2F-4CFB-94DA538F398CF354_sc7?wid=700&hei=700'),
	-- bendon despicable me 4
	(942, 'https://www.staples-3p.com/s7/is/image/Staples/395A6C34-3408-478C-AD599243632A348E_sc7?wid=700&hei=700'),

	-- stickers --
	-- trend stinky stickers
	(943, 'https://www.staples-3p.com/s7/is/image/Staples/sp42804717_sc7?wid=700&hei=700'),
	-- trend supershapes stickers
	(944, 'https://www.staples-3p.com/s7/is/image/Staples/sp44852281_sc7?wid=700&hei=700'),
	-- Trend superSpots & superShapes
	(945, 'https://www.staples-3p.com/s7/is/image/Staples/sp38165596_sc7?wid=700&hei=700'),
	(945, 'https://www.staples-3p.com/s7/is/image/Staples/sp38165597_sc7?wid=700&hei=700'),
	(945, 'https://www.staples-3p.com/s7/is/image/Staples/sp38165598_sc7?wid=700&hei=700'),

	-- office basics --

	-- mind reader desk organizer 7-compartment
	-- black 5.25W" x 11L" x 5.25H" 7 compartments 27.69
	(946, 'https://www.staples-3p.com/s7/is/image/Staples/1F887323-3BA1-4C4F-BAA3CE6ADDCCB95B_sc7?wid=700&hei=700'),
	(946, 'https://www.staples-3p.com/s7/is/image/Staples/88002436-7EE5-433F-8F66EB61159A262A_sc7?wid=700&hei=700'),
	(946, 'https://www.staples-3p.com/s7/is/image/Staples/391E5B3C-238E-4587-A40A287C170F051E_sc7?wid=700&hei=700'),
	(946, 'https://www.staples-3p.com/s7/is/image/Staples/E812DAA3-17E6-48AA-A3C6DB7BD3AFF372_sc7?wid=700&hei=700'),
	(946, 'https://www.staples-3p.com/s7/is/image/Staples/9465C5FB-441F-43E9-ADEBB8AC9CD159C2_sc7?wid=700&hei=700'),
	-- pink 
	(947, 'https://www.staples-3p.com/s7/is/image/Staples/B3CA0957-B05B-4FD9-A32B78AD750AAB94_sc7?wid=700&hei=700'),
	(947, 'https://www.staples-3p.com/s7/is/image/Staples/504A8707-4D21-4405-93A9622B261E73C9_sc7?wid=700&hei=700'),
	(947, 'https://www.staples-3p.com/s7/is/image/Staples/8794E559-10F3-460A-BA01B3D50A2F7AA2_sc7?wid=700&hei=700'),
	(947, 'https://www.staples-3p.com/s7/is/image/Staples/DA11281B-8DEE-4903-8A22BE589425A0AC_sc7?wid=700&hei=700'),
	(947, 'https://www.staples-3p.com/s7/is/image/Staples/ABAA2A50-1B6C-47B6-A544347AD5305F9E_sc7?wid=700&hei=700'),
	-- silver
	(948, 'https://www.staples-3p.com/s7/is/image/Staples/829D8BC4-DC53-4179-BA5438890711EE71_sc7?wid=700&hei=700'),
	(948, 'https://www.staples-3p.com/s7/is/image/Staples/8439118D-F7FB-4F8D-A284480CFDE9B151_sc7?wid=700&hei=700'),
	(948, 'https://www.staples-3p.com/s7/is/image/Staples/36978FEA-E001-4079-BF3F455FA0FB3201_sc7?wid=700&hei=700'),
	(948, 'https://www.staples-3p.com/s7/is/image/Staples/503F7B41-9DF3-465E-99DDF54C9665257C_sc7?wid=700&hei=700'),
	(948, 'https://www.staples-3p.com/s7/is/image/Staples/2DC18375-3B4B-4B78-B73023CA08BBF405_sc7?wid=700&hei=700'),
	-- white
	(949, 'https://www.staples-3p.com/s7/is/image/Staples/82068D18-8D2F-4DD1-8D9536785755C703_sc7?wid=700&hei=700'),
	(949, 'https://www.staples-3p.com/s7/is/image/Staples/E0B006F3-1F86-4405-823CAD52E600AECD_sc7?wid=700&hei=700'),
	(949, 'https://www.staples-3p.com/s7/is/image/Staples/2453C7E1-7E49-4CC9-81F4101EF4D1234A_sc7?wid=700&hei=700'),
	(949, 'https://www.staples-3p.com/s7/is/image/Staples/66AACB70-BFA1-4219-AC170E8C746EEB6A_sc7?wid=700&hei=700'),
	(949, 'https://www.staples-3p.com/s7/is/image/Staples/36DBAE3C-670A-4309-A90295F92E111C0F_sc7?wid=700&hei=700'),

	-- Mind Reader Metal Pen and Accessory Holder Desk Organizer
	-- black
	(950, 'https://www.staples-3p.com/s7/is/image/Staples/EAFE6FC1-C70F-472E-A535E1B2D364FD44_sc7?wid=700&hei=700'),
	(950, 'https://www.staples-3p.com/s7/is/image/Staples/CE3AE701-6FCB-4B4A-8463CD2F7EEC34DD_sc7?wid=700&hei=700'),
	(950, 'https://www.staples-3p.com/s7/is/image/Staples/DA84883B-8A05-4EEE-937500DCC90F2F3B_sc7?wid=700&hei=700'),
	(950, 'https://www.staples-3p.com/s7/is/image/Staples/AE869E10-3E96-4E71-A5586300CAEF0E5F_sc7?wid=700&hei=700'),
	(950, 'https://www.staples-3p.com/s7/is/image/Staples/2E5D9327-0071-4820-94FC720AE517A249_sc7?wid=700&hei=700'),
	-- silver
	(951, 'https://www.staples-3p.com/s7/is/image/Staples/B373203F-45BB-4503-8DAC620D77B4D631_sc7?wid=700&hei=700'),
	(951, 'https://www.staples-3p.com/s7/is/image/Staples/566B7A9E-2FFE-474E-BB0E3DE5F7BBEFD1_sc7?wid=700&hei=700'),
	(951, 'https://www.staples-3p.com/s7/is/image/Staples/D5EA984E-6D97-4214-95616B57E76B422C_sc7?wid=700&hei=700'),
	(951, 'https://www.staples-3p.com/s7/is/image/Staples/14EA91ED-FDE1-4D18-9739621044A730D9_sc7?wid=700&hei=700'),
	(951, 'https://www.staples-3p.com/s7/is/image/Staples/BB2A9237-E6AC-4713-A02EAA789FFD958E_sc7?wid=700&hei=700'),
	(951, 'https://www.staples-3p.com/s7/is/image/Staples/C1E11F2A-C574-46BD-8F79CA9D2D5513D5_sc7?wid=700&hei=700'),
	-- white
	(952, 'https://www.staples-3p.com/s7/is/image/Staples/77C938F9-544F-417E-992773A8E7DC9AE2_sc7?wid=700&hei=700'),
	(952, 'https://www.staples-3p.com/s7/is/image/Staples/5766BE21-AABF-49C0-8C0940730BD232B9_sc7?wid=700&hei=700'),
	(952, 'https://www.staples-3p.com/s7/is/image/Staples/4381D588-FC53-4AFC-9F7F001599988586_sc7?wid=700&hei=700'),
	(952, 'https://www.staples-3p.com/s7/is/image/Staples/51E14056-51AC-42D6-A0491CA2FBB925E0_sc7?wid=700&hei=700'),
	(952, 'https://www.staples-3p.com/s7/is/image/Staples/61E4FFA7-4BEA-4011-919E37F4E3140CE3_sc7?wid=700&hei=700'),

	-- mind reader 8 compartment desk organizer black
	(953, 'https://www.staples-3p.com/s7/is/image/Staples/EF941F83-0BFB-47E2-BF73FC54D7094891_sc7?wid=700&hei=700'),
	(953, 'https://www.staples-3p.com/s7/is/image/Staples/C0AB5825-FE6E-4DEE-8CD9A5B2B724016A_sc7?wid=700&hei=700'),
	(953, 'https://www.staples-3p.com/s7/is/image/Staples/0564E03D-7354-4F18-9A43A0C7D64EF97D_sc7?wid=700&hei=700'),
	(953, 'https://www.staples-3p.com/s7/is/image/Staples/D1C60796-ABD3-48C5-BE5AD45BA67B1C19_sc7?wid=700&hei=700'),
	(953, 'https://www.staples-3p.com/s7/is/image/Staples/172816F2-3BC4-4FBF-98C7883E3E2CF459_sc7?wid=700&hei=700'),

	-- bostitch electric desktip 3 hole punch 52.59
	(954, 'https://www.staples-3p.com/s7/is/image/Staples/F6204164-3C12-4DD6-BA567DDBCFCAC154_sc7?wid=700&hei=700'),

	-- bostich ez squeeze 1-hole punch
	(955, 'https://www.staples-3p.com/s7/is/image/Staples/s1153400_sc7?wid=700&hei=700'),
	(955, 'https://www.staples-3p.com/s7/is/image/Staples/s1153401_sc7?wid=700&hei=700'),
	(955, 'https://www.staples-3p.com/s7/is/image/Staples/s1153403_sc7?wid=700&hei=700'),


	-- hammermill copy paper --
	-- letter
	(958, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072084_sc7?wid=700&hei=700'),
	(958, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700'),
		
	(959, 'https://www.staples-3p.com/s7/is/image/Staples/DC2712FE-A922-4E5F-B9B9CF5677D6BE83_sc7?wid=700&hei=700'),
	(959, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700'),
		
	(960, 'https://www.staples-3p.com/s7/is/image/Staples/A2C4AC65-2CB3-4263-BB0C166AE240F3D8_sc7?wid=700&hei=700'),
	(960, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700'),
    
	(961, 'https://www.staples-3p.com/s7/is/image/Staples/sp167250067_sc7?wid=700&hei=700'),
	(961, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700'),
    
	(962, 'https://www.staples-3p.com/s7/is/image/Staples/95CBC599-9581-4384-AB7E87134750EEBE_sc7?wid=700&hei=700'),
	(962, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700'),
    
	-- legal
	(963, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072261_sc7?wid=700&hei=700'),
	(963, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700'),
    
	(964, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072238_sc7?wid=700&hei=700'),
	(964, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700'),

	-- A4
	(968, 'https://www.staples-3p.com/s7/is/image/Staples/sp167250076_sc7?wid=700&hei=700'),
	(968, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700'),
		
	(969, 'https://www.staples-3p.com/s7/is/image/Staples/95CBC599-9581-4384-AB7E87134750EEBE_sc7?wid=700&hei=700'),
	(969, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700');
