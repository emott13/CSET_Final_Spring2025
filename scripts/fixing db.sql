CREATE DATABASE IF NOT EXISTS goods_fix;
USE goods_fix;
-- drop database goods_fix;
-- ----------------------- --
-- CREATE TABLE STATEMENTS --
-- ----------------------- --
-- select variant_id from product_variants;
 
CREATE TABLE IF NOT EXISTS users (
	email VARCHAR(255) PRIMARY KEY, 										-- using email like a user id since unique
    username VARCHAR(255) NOT NULL UNIQUE,
    hashed_pswd VARCHAR(300) NOT NULL, 										-- hashed passwords needed more space in prev programs so using 300 instead of 255
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    type ENUM('vendor', 'admin', 'customer') NOT NULL
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
    (410, 'Projectors & Accessories'),
    
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

-- writing supplies --
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

-- notetaking -- 
    -- 9013
	('g_pitts@supplies4school.org', 'APEX Spiral Notebook', 'APEX Spiral Notebooks feature 70 wide-ruled sheets, 1 subject, with 3-hole perforated sheets. Available as single notebook or in multi-packs.', 0, 12),
	-- 9014
    ('g_pitts@supplies4school.org', 'Post-It Super Sticky Notes 3" x 3"', "Post-it® Super Sticky Notes are the perfect solution for shopping lists, reminders, to-do lists, color-coding, labeling, family chore reminders, brainstorming, storyboarding, and quick notes. Post-it Super Sticky Notes offer twice the sticking power of basic sticky notes, ensuring they stay put and won't fall off.", 0, 12),
    -- 9015
    ('g_pitts@supplies4school.org', 'Post-It Flags Combo Pack', 'Find it fast with Post-it® Flags in bright eye-catching colors that get noticed. They make it simple to mark or highlight important information in textbooks, calendars, notebooks, planners and more. They stick securely, remove cleanly and come in a wide variety of colors. Draw attention to critical items or use them to index, file or color code your work, either at home, work or in the classroom.', 0, 12),
    
-- folders & filing --
    -- 9016
    ('g_pitts@supplies4school.org', 'Post-It Durable Tabs', 'Durable Tabs are extra thick and strong to stand up to long-term wear and tear. Great for dividing notes, expanding files and project files. Sticks securely, removes cleanly.', 0, 13),
    
-- bags, lunchboxes, & backpacks --
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

-- school basics --
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
    
-- calculators --
    -- 9028 blue, pink, cyan
	('c_simmons@worksmart.com', 'Texas Instruments TI-30XIIS 10-Digit Scientific Battery & Solar Powered Scientific Calculator', 'Explore math and science concepts in the classroom or at home with this Texas Instruments scientific calculator. The calculator has a two-line display for optimal convenience and lets you edit, cut and paste entries to perform calculations faster. This versatile calculator is ideal for fraction features, conversions, basic scientific calculations and trigonometric functions to help in homework and other school tasks. The TI-30XIIS is solar and battery powered to ensure consistent use without worrying about power. This Texas Instruments scientific calculator has an impact-resistant cover with a quick-reference card for keeping notes, and the hard plastic, color-coded keys don\'t fade over time due to regular use.', 0, 102),
    -- 9029 light blue
	('c_simmons@worksmart.com', 'Texas Instruments MultiView TI-30XS 16 Digit Scientific Calculator', 'Find accurate solutions to complex equations with this Texas Instruments TI-30XS MultiView Scientific calculator. The MathPrint feature displays problems as they appear in textbooks, offering a more intuitive learning experience for students. A four-line display shows multiple calculations and lets you follow the steps needed to solve problems. This calculator includes options for scientific notations and tables, making it a smart option for use in high school and college math courses. Clearly labeled buttons along with cut, edit and paste functions delivers effortless navigation, while the solar power and battery combination ensures uninterrupted operation during tests or classroom lessons. This Texas Instruments TI-30XS MultiView Scientific calculator is approved for use with SAT, ACT and AP exams, providing you with a handy test-taking tool.', 0, 102),
    -- 9030
	('c_simmons@worksmart.com', 'Texas Instruments TI-30Xa 10-Digit Scientific Calculator', 'Find accurate solutions to complex problems with this Texas Instruments TI-30Xa scientific calculator. A one-line 10-digit display makes answers easy to see, while the color-coded keypad lets you find numbers and functions for effortless operation. The shift key provides access to advanced functions, letting you tackle pre-algebra, algebra, general science and trigonometry problems. Fraction conversion and decimal functions are perfect for solving basic math problems. This calculator comes with an impact-resistant cover, so it stands up to the rigors of everyday school use. Accepted for use in SAT, ACT and AP exams, this Texas Instruments TI-30Xa scientific calculator is an ideal option for junior high and high school students.', 0, 102),
    -- 9031
	('g_pitts@supplies4school.org', 'Texas Instruments TI-36X Pro 16-Digit Scientific Calculator', 'Complete your math and science tasks faster with this Texas Instruments scientific calculator. The versatile calculator features a MultiView four-line display to show multiple calculations at the same time, and built-in solvers provide quick solutions to linear equations and numeric equations. With an easy-to-use mode menu, you can easily access commands and format numbers with a few button clicks. This Texas Instruments scientific calculator lets you view (x,y) table of values by keying in specific X values, and it displays stacked fractions and math expressions exactly like in textbooks. Nonskid rubber feet prevent slipping on desks, and solar cell assistance helps to boost the battery life.', 0, 102),
    
-- art supplies --
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
   
-- office basics 201 --

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
   
-- paper & mailing 202 --
   -- 9069 hammerhill copy paper letter
    ('g_pitts@supplies4school.org', 'Hammermill Copy Plus 8.5" x 11" US Letter Copy Paper', 'The Hammermill Copy Plus paper is an economical product that\'s perfect for everyday printing and copying. This versatile paper is great for all types of black and white documents, copies, and printouts. The Hammermill Copy Plus paper is designed to run in all office equipment.', 0, 202),
    
    -- 9070 hammerhill copy paper legal
    ('g_pitts@supplies4school.org', 'Hammermill Copy Plus 8.5" x 14" Legal Copy Paper', 'The Hammermill Copy Plus paper is an economical product that\'s perfect for everyday printing and copying. This versatile paper is great for all types of black and white documents, copies, and printouts. The Hammermill Copy Plus paper is designed to run in all office equipment.', 0, 202),
    
    -- 9071 hammerhill copy paper A4
    ('g_pitts@supplies4school.org', 'Hammermill Copy Plus 8.27" x 11.69" A4 Copy Paper', 'The Hammermill Copy Plus paper is an economical product that\'s perfect for everyday printing and copying. This versatile paper is great for all types of black and white documents, copies, and printouts. The Hammermill Copy Plus paper is designed to run in all office equipment.', 0, 202);

-- art textbooks --

--    -- 850625
--    ('', '', '', 0, 301),
--    -- 850626
--    ('', '', '', 0, 301),
--    -- 850627
--    ('', '', '', 0, 302),
--    -- 850628
--    ('', '', '', 0, 302),
--    -- 850629
--    ('', '', '', 0, 303),
--    -- 850630
--    ('', '', '', 0, 303),
--    -- 850631
--    ('', '', '', 0, 304),
--    -- 850632
--    ('', '', '', 0, 304),
--    -- 850633
--    ('', '', '', 0, 305),
--    -- 850634
--    ('', '', '', 0, 305),
--    -- 850635
--    ('', '', '', 0, ),
--    -- 850636
--    ('', '', '', 0, ),
--    -- 850637
--    ('', '', '', 0, ),
--    -- 850638
--    ('', '', '', 0, ),
--    -- 850639
--    ('', '', '', 0, ),
--    -- 850640
--    ('', '', '', 0, ),
--    
   
INSERT INTO colors (color_name, color_hex)
VALUES
	('None', NULL),						-- 600
	('Assorted', NULL),					-- 601 (19710)
    ('Assorted Metallics', NULL),		-- 602
    ('Assorted Pastels', NULL),			-- 603
	('Multicolor', NULL),				-- 604 19799
	('Pattern', NULL),					-- 605 19797, 19798 19803 19802 19800
	('Black', '#000000'),				-- 606 19786
	('Blue', '#0000ff'),				-- 607 19782
	('Clear', NULL),					-- 608 19788
	('Cyan', '#00bfff'),				-- 609 19805
	('Dark Blue', '#06065c'),			-- 610 19793
	('Dark Brown', '#52422e'),			-- 611 
	('Dark Green', '#004d00'),			-- 612 
	('Dark Grey', '#666666'),			-- 613 
	('Dark Red', '#8b0000'),			-- 614 
	('Green', '#00ff00'),				-- 615 19783
	('Light Blue', '#b3d9ff'),			-- 616 
	('Light Brown', '#b59b7c'),			-- 617 
	('Light Green', '#66ffc3'),			-- 618 19810
	('Light Grey', '#bfbfbf'),			-- 619 
	('Lilac', '#c8a2c8'),				-- 620 19792
	('Magenta', '#ff33cc'),				-- 621 19804
	('Manila', '#e7c9a9'),				-- 622 19808
	('Maple', '#bb9351'),				-- 623 19791
	('Navy', '#000080'),				-- 624 19785
	('Orange', '#ff6600'),				-- 625 
	('Orchid', '#e2cfe1'),				-- 626 19809
	('Pink', '#ff80aa'),				-- 627 19811
	('Purple', '#800080'),				-- 628 19806
	('Red', '#ff0000'),					-- 629 19781
	('Rose Pink', '#f0afc1'),			-- 630 19794
	('Silver', '#c0c0c0'),				-- 631 19807
	('Sky Blue', '#1a6bb8'),			-- 632 19795
	('Walnut', '#99592e'),				-- 633 19787
	('White', '#ffffff'),				-- 634 19790
	('Yellow', '#ffff00');				-- 635 19784

INSERT INTO sizes (size_description)
VALUES
('None'),							-- 400
('Standard'),
('14.5H" x 14W" x 11.25D"'),
('2.4H" x 9.1W" x 7D"'),
('2.4H" x 9.4W" x 7.1D"'),
('33.75H" x 14.68W" x 18.37L" '),
('8H" x 4.25W" x 2.25D"'),
('3.6L" x 0.3W"'),
('13"W x 10"D x 17.5"H '),
('16"W x 18"D x 26"L '),
('16"W x 22"D x 28"L '),
('20W" x 19D" x 18-22H" '),
('5.25W" x 11L" x 5.25H"'),
('1W"'),
('2W"'),
('A4: 8.25W" x 11.75L"'),
('Legal (US): 8.5W" x 14L"'),
('Letter (US): 8.5W" x 11L"'),
('132mL capacity');
    
INSERT INTO specifications (spec_description)
VALUES
('Single'),
('5-Pack'),
('6-Pack'),
('8-Pack'),
('10-Pack'),
('12-Pack'),
('24-Pack'),
('30-Pack'),
('36-Pack'),
('40-Pack'),
('48-Pack'),
('50-Pack'),
('60-Pack'),
('64-Pack'),
('72-Pack'),
('80-Pack'),
('90-Pack'),
('100-Pack'),
('120-Pack'),
('144-Pack'),
('320-Pack'),
('432-Pack'),
('48 Sheets'),
('48 Sheets/Pack, 6-Pack'),
('96 Sheets'),
('96 Sheets/Pack, 12-Pack'),
('240 Sheets'),
('240 Sheets/Pack, 3-Pack'),
('1-Hole Punch'),
('3-Hole Punch'),
('1-Ream 500 Sheets/Ream'),
('3-Ream 500 Sheets/Ream'),
('5-Ream 500 Sheets/Ream'),
('8-Ream 500 Sheets/Ream'),
('10-Ream 500 Sheets/Ream'),
('70 Sheet/Pad, 24 Pads/Pack'),
('90 Sheet/Pad, 5 Pads/Pack'),
('320 Flags/Pack'),
('1 Pack/800 Pages'),
('1 Pack/1250 Pages'),
('4 Pack/3650 Pages'),
('66 Tabs/Pack'),
('24 Tabs/Pack'),
('9125e: 250 Sheet Input/60 Sheet Output'),
('9135e: 500 Sheet Input/100 Sheet Output'),
('GX3020: 250 Sheet Input/100 Sheet Output'),
('GX4020: 250 Sheet Input/100 Sheet Output'),
('GX5020: 350 Sheet Input'),
('16GB RAM');
-- 	(),
--     (),
--     (),
--     (),
--     (),
--     (),
--     (),
--     (),
--     (),
--     (),
--     (),
--     (),
--     (),
--     (),
--     (),
--     (),
--     (),
--     (),
--     ();
    
INSERT INTO product_variants (product_id, color_id, size_id, spec_id, price, current_inventory)
VALUES
	-- 9000 bic mech pencils smooth regular --
	-- 800
	(9000, 601, 400, 204, 479, 15),			-- 10 pack
    -- 801
    (9000, 601, 400, 205, 499, 15),			-- 12 pack
    -- 802
    (9000, 601, 400, 209, 1689, 15),		-- 40 pack
    -- 803
    (9000, 601, 400, 220, 13099, 15),		-- 320 pack
    
    -- 9001 bic mech pencils smooth pastels --
    -- 804
    (9001, 601, 400, 207, 999, 15),			-- 24 pack
    -- 805
    (9001, 601, 400, 210, 1899, 15),		-- 40 pack
    
    -- dixon wooden pencil --
    -- 806
    (9002, 617, 400, 220, 1249, 15), 		-- 144 Pack

    -- ticonderoga sharpened wooden pencils --
    -- 807
    (9003, 635, 400, 205, 559, 15),			-- 12 pack
    -- 808
    (9003, 635, 400, 206, 719, 15),			-- 18 pack
    -- 809
    (9003, 635, 400, 208, 949, 15),			-- 30 pack
    -- 810
    (9003, 635, 400, 215, 1889, 15),		-- 72 pack 
    
    -- ticonderoga UNsharpened wooden pencils --
    -- 811
    (9004, 635, 400, 205, 499, 15),			-- 12 pack
    -- 812
    (9004, 635, 400, 207, 799, 15),			-- 24 pack
    -- 813
    (9004, 635, 400, 217, 2149, 15),		-- 96 pack

    -- bic round stic xtra life pens --
    -- 814
    (9005, 606, 400, 205, 479, 15),			-- 12 pack black
    -- 815
    (9005, 607, 400, 205, 479, 15),			-- 12 pack blue
    -- 816
    (9005, 629, 400, 205, 479, 15), 		-- 12 pack red
    -- 817
    (9005, 606, 400, 213, 2149, 15),		-- 60 pack black
    -- 818
    (9005, 607, 400, 213, 2149, 15),		-- 60 pack blue
    -- 819
    (9005, 601, 400, 213, 2149, 15),		-- 60 pack assorted 
    -- 820
    (9005, 606, 400, 219, 4099, 15),		-- 120 pack black
    -- 821
    (9005, 606, 400, 222, 13999, 15),		-- 432 pack black
    
    -- pilot g2 pens 12 pack --
    -- 822
    (9006, 606, 400, 205, 799, 15),			-- black 12 pack
    -- 823
    (9006, 629, 400, 205, 799, 15),			-- red 12 pack
    -- 824
    (9006, 624, 400, 205, 799, 15),			-- navy 12 pack
    -- 825
    (9006, 607, 400, 205, 799, 15),			-- blue 12 pack
    -- 826
    (9006, 615, 400, 205, 799, 15),			-- green 12 pack
    -- 827
    (9006, 628, 400, 205, 799, 15),			-- purple 12 pack
    
    
    -- 828
    (9007, 606, 400, 213, 111, 15),			-- black
    -- 829
    (9007, 607, 400, 213, 111, 15),			-- blue
    -- 830
    (9007, 601, 400, 213, 111, 15),			-- assorted
    -- 831
    (9007, 603, 400, 213, 111, 15),			-- assorted (pastels)
    -- 832
    (9007, 602, 400, 213, 111, 15),			-- assorted (metallic)
    
	-- paper mate felt pens --
    -- 833
    (9008, 601, 400, 205, 1149, 16),			-- 100233 assorted colors
    
    -- sharpie permenant markers --
    -- 834
    (9009, 606, 400, 209, 2599, 12),			-- 100234 black
    -- 835
    (9009, 629, 400, 209, 2599, 12), 			-- 100235 red
    -- 836
    (9009, 607, 400, 209 , 2599, 12), 			-- 100236 blue
    -- 837
    (9009, 631, 400, 209, 2599, 12), 			-- 100237 silver
    -- 838
    (9009, 601, 400, 209, 2599, 12), 			-- 100238 assorted
    -- 839
    (9009, 601, 400, 207, 1999, 16),			-- 100239 assorted 24 pack
    
    -- dry erase starter set --
    -- 840
    (9010, 601, 400, 200, 799, 9),			-- 100240
    
    -- dry erase kit --
    -- 841
    (9011, 601, 400, 200, 1999, 11),			-- 100241
    
    -- dry erase markrs 12-pack --
    -- 842
    (9012, 601, 400, 205, 1379, 10), 		-- 100242 assorted
    -- 843
    (9012, 606, 400, 205, 1379, 10), 		-- 100243 black 
    -- 844
    (9012, 629, 400, 205, 1379, 10),			-- 100244 red
    -- 845
    (9012, 615, 400, 205, 1379, 10), 		-- 100245 green
    -- 846
    (9012, 607, 400, 205, 1379, 10), 		-- 100246 blue
    -- 847
    (9012, 628, 400, 205, 1379, 10), 		-- 100247 purple
    
    
    -- 9013 notebooks --
    -- put notebooks here --
    
    
    -- 100248
    -- post it notes large pack --
    -- 848
    (9014, 601, 400, 236, 2399, 5),			-- 100249
    -- 849
    (9014, 601, 400, 236, 2399, 5),			-- 100250
    -- 850
    (9014, 601, 400, 236, 2399, 5),			-- 100251
    -- 851
    (9014, 601, 400, 236, 2399, 5),			-- 100252
    
	-- post it notes small pack
    -- 852
    (9014, 601, 400, 237, 699, 5),	-- 100253
    -- 853
    (9014, 601, 400, 237, 699, 5),	-- 100254
    -- 854
    (9014, 601, 400, 237, 699, 5),	-- 100255
    -- 855
    (9014, 601, 400, 237, 699, 5),	-- 100256
    
    -- post it flags combo
    -- 856
    (9015, 601, 400, 238, 1329, 15),	-- 100257
    -- post it tabs
    -- 857
    (9016, 601, 413, 242, 789, 11),		-- 100258
    -- 858
    (9016, 601, 414, 243, 429, 8),		-- 100259
    
    -- bentogo modern lunch box --
    -- 859
    (9017, 606, 400, 200, 3799, 10),	-- black
    -- 860
	(9017, 624, 400, 200, 3799, 10),	-- navy
    -- 861
	(9017, 626, 400, 200, 3799, 10),	-- orchid
    -- 862
	(9017, 634, 400, 200, 3799, 10),	-- white
    
    -- bentogo pop lunch box --
    -- 863
    (9018, 629, 400, 200, 3299, 10),	-- red
    -- 864
    (9018, 627, 400, 200, 3299, 10),	-- pink
    -- 865
    (9018, 618, 400, 200, 3299, 10),	-- light green
    -- 866
    (9018, 616, 400, 200, 3299, 10),	-- light blue
    -- 867
    (9018, 610, 400, 200, 3299, 10),	-- dark blue
    
    
    -- jam paper lunch bags --
    -- 868
    (9019, 617, 400, 200, 1499, 10);
 
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
--     (7, 100213 , 1, 32999), -- phys textbook x1 => discounted price => 32999
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
--     
INSERT INTO images (variant_id, file_path)
VALUES
-- bic mech pencils --
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
    (816, ''),
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
    
    (829, 'https://www.staples-3p.com/s7/is/image/Staples/sp137770008_sc7?wid=700&hei=700'),
    (829, 'https://www.staples-3p.com/s7/is/image/Staples/sp137770011_sc7?wid=700&hei=700'),
    
    (830, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856218_sc7?wid=700&hei=700'),
    (830, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856219_sc7?wid=700&hei=700'),
    
    (831, 'https://www.staples-3p.com/s7/is/image/Staples/s1070669_sc7?wid=700&hei=700'),
    (831, 'https://www.staples-3p.com/s7/is/image/Staples/s1082037_sc7?wid=700&hei=700'),
    
    (832, 'https://www.staples-3p.com/s7/is/image/Staples/s1078333_sc7?wid=700&hei=700'),
    (832, 'https://www.staples-3p.com/s7/is/image/Staples/s1078334_sc7?wid=700&hei=700'),
    (832, 'https://www.staples-3p.com/s7/is/image/Staples/s1078335_sc7?wid=700&hei=700'),
    (832, 'https://www.staples-3p.com/s7/is/image/Staples/s1078336_sc7?wid=700&hei=700'),
    (832, 'https://www.staples-3p.com/s7/is/image/Staples/s1078337_sc7?wid=700&hei=700'),
    
    -- paper mate felt pens --
    (833, 'https://www.staples-3p.com/s7/is/image/Staples/98C1DFBD-AFCE-488D-B080922050338AA7_sc7?wid=700&hei=700'),
    (833, 'https://www.staples-3p.com/s7/is/image/Staples/sp161466748_sc7?wid=700&hei=700'),
    (833, 'https://www.staples-3p.com/s7/is/image/Staples/sp161466749_sc7?wid=700&hei=700'),
    
    -- sharpie permenant markers --
    -- black
    (834, 'https://www.staples-3p.com/s7/is/image/Staples/D67EC31B-0DB3-45F9-BD62DC872D1ACBF1_sc7?wid=700&hei=700'),
    (834, 'https://www.staples-3p.com/s7/is/image/Staples/1BCDF1C0-5454-4A4A-A616BD9601C8C140_sc7?wid=700&hei=700'),
    (834, 'https://www.staples-3p.com/s7/is/image/Staples/DD9A5C21-9C21-4A0E-B3B6C1149A3D0399_sc7?wid=700&hei=700'),
    -- red
    (835, 'https://www.staples-3p.com/s7/is/image/Staples/5CA98F6D-8D11-4886-B08C0CC322E38815_sc7?wid=700&hei=700'),
    (835, 'https://www.staples-3p.com/s7/is/image/Staples/sp89168542_sc7?wid=700&hei=700'),
    (835, 'https://www.staples-3p.com/s7/is/image/Staples/s0922441_sc7?wid=700&hei=700'),
    -- blue
    (836, 'https://www.staples-3p.com/s7/is/image/Staples/1C929E3D-8BCF-48E2-A00933FB4AAD3B2D_sc7?wid=700&hei=700'),
    (836, 'https://www.staples-3p.com/s7/is/image/Staples/s0933668_sc7?wid=700&hei=700'),
    (836, 'https://www.staples-3p.com/s7/is/image/Staples/s0922442_sc7?wid=700&hei=700'),
    -- silver
    (837, 'https://www.staples-3p.com/s7/is/image/Staples/m007068285_sc7?wid=700&hei=700'),
    (837, 'https://www.staples-3p.com/s7/is/image/Staples/m007068281_sc7?wid=700&hei=700'),
    (837, 'https://www.staples-3p.com/s7/is/image/Staples/m007068283_sc7?wid=700&hei=700'),
    -- assorted
    (838, 'https://www.staples-3p.com/s7/is/image/Staples/s1189983_sc7?wid=700&hei=700'),
    (838, 'https://www.staples-3p.com/s7/is/image/Staples/m002908378_sc7?wid=700&hei=700'),
    -- assorted 24 pack
    (839, 'https://www.staples-3p.com/s7/is/image/Staples/D5E6B1CA-30FC-4219-9BD4322085DCA998_sc7?wid=700&hei=700'),
    (839, 'https://www.staples-3p.com/s7/is/image/Staples/sp44335828_sc7?wid=700&hei=700'),
    (839, 'https://www.staples-3p.com/s7/is/image/Staples/sp44335829_sc7?wid=700&hei=700'),
    
    -- dry erase starter set
    (840, 'https://www.staples-3p.com/s7/is/image/Staples/E1755194-7001-4CE3-93598F83B0079751_sc7?wid=700&hei=700'),
    (840, 'https://www.staples-3p.com/s7/is/image/Staples/sp40798560_sc7?wid=700&hei=700'),
    (840, 'https://www.staples-3p.com/s7/is/image/Staples/sp40798562_sc7?wid=700&hei=700'),
    (840, 'https://www.staples-3p.com/s7/is/image/Staples/sp40798565_sc7?wid=700&hei=700'),
    
    -- dry erase kit
    (841, 'https://www.staples-3p.com/s7/is/image/Staples/m002304039_sc7?wid=700&hei=700'),
    (841, 'https://www.staples-3p.com/s7/is/image/Staples/m002304040_sc7?wid=700&hei=700https://www.staples-3p.com/s7/is/image/Staples/m002304040_sc7?wid=700&hei=700'),
    (841, 'https://www.staples-3p.com/s7/is/image/Staples/m002304041_sc7?wid=700&hei=700'),
    (841, 'https://www.staples-3p.com/s7/is/image/Staples/m002304042_sc7?wid=700&hei=700'),
    
    -- dry erase markers
    -- assorted
    (842, 'https://www.staples-3p.com/s7/is/image/Staples/1B6FF91A-3111-4FC5-993BBF7E44F1E0BE_sc7?wid=700&hei=700'),
    (842, 'https://www.staples-3p.com/s7/is/image/Staples/sp155560515_sc7?wid=700&hei=700'),
    (842, 'https://www.staples-3p.com/s7/is/image/Staples/sp155560516_sc7?wid=700&hei=700'),
    -- black
    (843, 'https://www.staples-3p.com/s7/is/image/Staples/sp161387743_sc7?wid=700&hei=700'),
    (843, 'https://www.staples-3p.com/s7/is/image/Staples/sp161387838_sc7?wid=700&hei=700'),
    (843, 'https://www.staples-3p.com/s7/is/image/Staples/sp161387839_sc7?wid=700&hei=700'),
    -- red
    (844, 'https://www.staples-3p.com/s7/is/image/Staples/sp102580415_sc7?wid=700&hei=700'),
    (844, 'https://www.staples-3p.com/s7/is/image/Staples/6E4861C8-7E9A-4E8F-9968DE672544E5AA_sc7?wid=700&hei=700'),
    (844, 'https://www.staples-3p.com/s7/is/image/Staples/sp102580416_sc7?wid=700&hei=700'),
    -- green
    (845, 'https://www.staples-3p.com/s7/is/image/Staples/sp40888435_sc7?wid=700&hei=700'),
    (845, 'https://www.staples-3p.com/s7/is/image/Staples/sp40888433_sc7?wid=700&hei=700'),
    (845, 'https://www.staples-3p.com/s7/is/image/Staples/sp40888432_sc7?wid=700&hei=700'),
    -- blue
    (846, 'https://www.staples-3p.com/s7/is/image/Staples/s1184756_sc7?wid=700&hei=700'),
    (846, 'https://www.staples-3p.com/s7/is/image/Staples/614B9DDE-27C9-41AE-89E590D1247EC18B_sc7?wid=700&hei=700'),
    (846, 'https://www.staples-3p.com/s7/is/image/Staples/sp57451607_sc7?wid=700&hei=700'),
    -- purple
    (847, 'https://www.staples-3p.com/s7/is/image/Staples/s1192758_sc7?wid=700&hei=700'),
    (847, 'https://www.staples-3p.com/s7/is/image/Staples/sp49508023_sc7?wid=700&hei=700'),
    
	(848, '/static_product/images/school_supplies/2095545-A'),
    (848, '/static_product/images/school_supplies/2095545-B'),
    (848, '/static_product/images/school_supplies/POST-IT-C'),
    
	(849, '/static_product/images/school_supplies/77278-A'),
    (849, '/static_product/images/school_supplies/77278-B'),
    (849, '/static_product/images/school_supplies/POST-IT-C'),
    
	(850, '/static_product/images/school_supplies/24534139-A'),
    (850, '/static_product/images/school_supplies/24534139-B'),
    (850, '/static_product/images/school_supplies/POST-IT-C'),
    
	(851, '/static_product/images/school_supplies/77285-A'),
    (851, '/static_product/images/school_supplies/77285-B'),
    (851, '/static_product/images/school_supplies/POST-IT-C'),
    
	(852, '/static_product/images/school_supplies/2398220-A'),
    (852, '/static_product/images/school_supplies/2398220-B'),
    (852, '/static_product/images/school_supplies/POST-IT-C'),
    
	(853, '/static_product/images/school_supplies/586111-A'),
    (853, '/static_product/images/school_supplies/586111-B'),
    (853, '/static_product/images/school_supplies/POST-IT-C'),
    
	(854, '/static_product/images/school_supplies/562930-A'),
    (854, '/static_product/images/school_supplies/562930-B'),
    (854, '/static_product/images/school_supplies/POST-IT-C'),
    
	(855, '/static_product/images/school_supplies/24517481-A'),
    (855, '/static_product/images/school_supplies/24517481-B'),
    (855, '/static_product/images/school_supplies/POST-IT-C'),
    
    (856, '/static_product/images/school_supplies/575671-A'),
    (856, '/static_product/images/school_supplies/575671-B'),
    
    (857, '/static_product/images/school_supplies/663660-A'),
    (857, '/static_product/images/school_supplies/663660-B'),
    
    (858, '/static_product/images/school_supplies/751540-A'),
    (858, '/static_product/images/school_supplies/751540-B'),
    
    	-- black
	(859, 'https://www.staples-3p.com/s7/is/image/Staples/0D3524FF-2832-47D7-A2AACA09B78251AF_sc7?wid=700&hei=700'),
    (859, 'https://www.staples-3p.com/s7/is/image/Staples/D7428E65-0EE6-478F-884DCE28AD123792_sc7?wid=700&hei=700'),
    (859, 'https://www.staples-3p.com/s7/is/image/Staples/2C813818-609C-48B0-A5B72C9270296301_sc7?wid=700&hei=700'),
    (859, 'https://www.staples-3p.com/s7/is/image/Staples/24AD6A77-5DC8-4FBD-989E4FEE55F15DA9_sc7?wid=700&hei=700'),
    (859, 'https://www.staples-3p.com/s7/is/image/Staples/8BB61944-3D48-4CE4-8327F63BF437634F_sc7?wid=700&hei=700'),
    (859, 'https://www.staples-3p.com/s7/is/image/Staples/3E85D25E-1967-4307-8A64BC3BA5F18A62_sc7?wid=700&hei=700'),
    -- navy
    (860, 'https://www.staples-3p.com/s7/is/image/Staples/37B758D7-2B96-4E2D-ABF4E4AAFFE3BC6F_sc7?wid=700&hei=700'),
    (860, 'https://www.staples-3p.com/s7/is/image/Staples/5E737974-B2C3-448C-B4DD1BBC1F1B0F06_sc7?wid=700&hei=700'),
    (860, 'https://www.staples-3p.com/s7/is/image/Staples/58FD9017-97AE-48E8-AAB4269BC0883BD9_sc7?wid=700&hei=700'),
    (860, 'https://www.staples-3p.com/s7/is/image/Staples/8C2DF227-53C1-4D0E-929B8F5EC0A09A2D_sc7?wid=700&hei=700'),
    (860, 'https://www.staples-3p.com/s7/is/image/Staples/E6F89404-A849-45B4-80DCC8BEF18E2DB8_sc7?wid=700&hei=700'),
    (860, 'https://www.staples-3p.com/s7/is/image/Staples/6E602881-5F54-4B2E-996312B335A7FE9B_sc7?wid=700&hei=700'),
    -- orchid
    (861, 'https://www.staples-3p.com/s7/is/image/Staples/A9809EBD-5FCC-4A03-B40FAFB26118DA2D_sc7?wid=700&hei=700'),
    (861, 'https://www.staples-3p.com/s7/is/image/Staples/B3D23C50-568C-4B28-959B3CF228CC8C89_sc7?wid=700&hei=700'),
    (861, 'https://www.staples-3p.com/s7/is/image/Staples/5C21529A-EFDE-448E-A53EAC257AE36928_sc7?wid=700&hei=700'),
    (861, 'https://www.staples-3p.com/s7/is/image/Staples/053E5E0E-70C8-40E7-925992EE95C92A2E_sc7?wid=700&hei=700'),
    (861, 'https://www.staples-3p.com/s7/is/image/Staples/561C327E-6541-411D-9BD30A2BC1684949_sc7?wid=700&hei=700'),
    (861, 'https://www.staples-3p.com/s7/is/image/Staples/EC589213-4362-47E4-BB4383489F986315_sc7?wid=700&hei=700'),
    -- white
    (862, 'https://www.staples-3p.com/s7/is/image/Staples/0278D8CC-CD92-488F-A51BBFEF8525B601_sc7?wid=700&hei=700'),
    (862, 'https://www.staples-3p.com/s7/is/image/Staples/458B3FB4-6391-4DA2-A81E960707074A01_sc7?wid=700&hei=700'),
    (862, 'https://www.staples-3p.com/s7/is/image/Staples/6057FEA6-587E-428E-A1EB00AA985361D8_sc7?wid=700&hei=700'),
    (862, 'https://www.staples-3p.com/s7/is/image/Staples/3ABF2577-407D-4AE7-83BFA04EC3F81832_sc7?wid=700&hei=700'),
    (862, 'https://www.staples-3p.com/s7/is/image/Staples/C4FFF143-A820-4A77-907625918C01B691_sc7?wid=700&hei=700'),
    (862, 'https://www.staples-3p.com/s7/is/image/Staples/2B6ADFEF-D3DE-4B33-9CEF5C1D71C9741E_sc7?wid=700&hei=700'),
    
    -- bentogo pop lunch box --
    -- red
    (863, 'https://www.staples-3p.com/s7/is/image/Staples/7802D637-CB82-415E-AD543B5AECD0F8B0_sc7?wid=700&hei=700'),
    (863, 'https://www.staples-3p.com/s7/is/image/Staples/84239C76-86E5-491D-BA3738AC08D7078B_sc7?wid=700&hei=700'),
    (863, 'https://www.staples-3p.com/s7/is/image/Staples/820464A3-38B8-4F93-AE794889BBE4E222_sc7?wid=700&hei=700'),
    (863, 'https://www.staples-3p.com/s7/is/image/Staples/6789F01A-E7F3-4C16-A9C0B5A03DB540C3_sc7?wid=700&hei=700'),
    (863, 'https://www.staples-3p.com/s7/is/image/Staples/459428D1-2F4C-4A2B-ACA9B062AC797467_sc7?wid=700&hei=700'),
    (863, 'https://www.staples-3p.com/s7/is/image/Staples/1EF62BCA-C053-4587-9EAA8547341A6F6D_sc7?wid=700&hei=700'),
    -- pink
    (864, 'https://www.staples-3p.com/s7/is/image/Staples/B94BEB4E-D957-48EF-95D72577308D9D9E_sc7?wid=700&hei=700'),
    (864, 'https://www.staples-3p.com/s7/is/image/Staples/C86E6289-5F11-4B7F-8134AB18B8BBCEDF_sc7?wid=700&hei=700'),
    (864, 'https://www.staples-3p.com/s7/is/image/Staples/BB5695B7-BB6D-4041-870DD10C8694077D_sc7?wid=700&hei=700'),
    (864, 'https://www.staples-3p.com/s7/is/image/Staples/454A7A0F-3B24-496D-8825EACBDDFE9136_sc7?wid=700&hei=700'),
    (864, 'https://www.staples-3p.com/s7/is/image/Staples/DC8A7FB9-DEA9-4F01-90E512858E58C32B_sc7?wid=700&hei=700'),
    (864, 'https://www.staples-3p.com/s7/is/image/Staples/5241D329-4F2A-4FB5-A8A9F25AF1827BC1_sc7?wid=700&hei=700'),
    -- light green
    (865, 'https://www.staples-3p.com/s7/is/image/Staples/99B9D519-6226-4D08-B5D63D58833982D0_sc7?wid=700&hei=700'),
    (865, 'https://www.staples-3p.com/s7/is/image/Staples/A1EB8473-94EF-47B3-92B2E6BED0600A15_sc7?wid=700&hei=700'),
    (865, 'https://www.staples-3p.com/s7/is/image/Staples/D45B7B60-D35B-487A-8DF59B7CDEECAC7E_sc7?wid=700&hei=700'),
    (865, 'https://www.staples-3p.com/s7/is/image/Staples/563C0F35-F21A-4A5D-A4F71A8DB0D7D22D_sc7?wid=700&hei=700'),
    (865, 'https://www.staples-3p.com/s7/is/image/Staples/43147E57-97C4-4D52-A7EFB57CCBBA7CBE_sc7?wid=700&hei=700'),
    (865, 'https://www.staples-3p.com/s7/is/image/Staples/C29F0E87-FCF5-4588-BEA9AAC74014BFC1_sc7?wid=700&hei=700'),
    -- light blue
    (866, 'https://www.staples-3p.com/s7/is/image/Staples/4CC559BD-0238-429E-A7313225AB132440_sc7?wid=700&hei=700'),
    (866, 'https://www.staples-3p.com/s7/is/image/Staples/8AFD60A3-5403-473F-A1541896FB8CC470_sc7?wid=700&hei=700'),
    (866, 'https://www.staples-3p.com/s7/is/image/Staples/342935CA-7C09-4E4B-B093C4DB3B578A30_sc7?wid=700&hei=700'),
    (866, 'https://www.staples-3p.com/s7/is/image/Staples/E3BE1F16-4503-4980-8DA18F6B6E041180_sc7?wid=700&hei=700'),
    (866, 'https://www.staples-3p.com/s7/is/image/Staples/EB90F81D-1EF8-4950-A2A086EEF78B1D93_sc7?wid=700&hei=700'),
    (866, 'https://www.staples-3p.com/s7/is/image/Staples/18E0B232-5AC9-4758-AEE8BA168DDC3058_sc7?wid=700&hei=700'),
    -- dark blue
    (867, 'https://www.staples-3p.com/s7/is/image/Staples/9483D0B0-C978-4EF1-8E0C2F1C0FC4375A_sc7?wid=700&hei=700'),
    (867, 'https://www.staples-3p.com/s7/is/image/Staples/CBDE0746-0BBD-4B9B-A27394B9C7B9AD5A_sc7?wid=700&hei=700'),
    (867, 'https://www.staples-3p.com/s7/is/image/Staples/A4C81F63-7C65-40E8-B151CD67AB13A1C0_sc7?wid=700&hei=700'),
    (867, 'https://www.staples-3p.com/s7/is/image/Staples/5271254D-38E5-4650-9039CE4B4F650C68_sc7?wid=700&hei=700'),
    (867, 'https://www.staples-3p.com/s7/is/image/Staples/DDEFA5EE-FF77-4D88-9C3897C9C5ABF86C_sc7?wid=700&hei=700'),
    (867, 'https://www.staples-3p.com/s7/is/image/Staples/05D9E779-A5E0-4E12-909095440A75E541_sc7?wid=700&hei=700'),
    
    -- jam kraft brown paper bags --
	(868, 'https://www.staples-3p.com/s7/is/image/Staples/sp71001592_sc7?wid=700&hei=700'),
    (868, 'https://www.staples-3p.com/s7/is/image/Staples/sp71001593_sc7?wid=700&hei=700'),
    (868, 'https://www.staples-3p.com/s7/is/image/Staples/sp71001594_sc7?wid=700&hei=700');