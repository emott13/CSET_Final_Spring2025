CREATE DATABASE IF NOT EXISTS goods;
USE goods_fix;
-- drop database goods;
-- ----------------------- --
-- CREATE TABLE STATEMENTS --
-- ----------------------- --
-- select variant_id from product_variants;
 SELECT file_path, image_id
                FROM images 
                WHERE variant_id = 100200 
                ORDER BY image_id;
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
    product_description VARCHAR(800),
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
    UNIQUE(product_id, color_id, size_id) -- ensures no duplicate combos
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
ALTER TABLE products AUTO_INCREMENT=850555;
ALTER TABLE colors AUTO_INCREMENT=800;
ALTER TABLE sizes AUTO_INCREMENT=100;
ALTER TABLE product_variants AUTO_INCREMENT=100200;

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
	-- 850555
	('c_simmons@worksmart.com', 'BIC Xtra-Smooth Mechanical Pencil, 0.7mm, #2 Medium Lead', 'BIC Xtra-Smooth Mechanical Pencils with lead are the perfect companion for your everyday writing needs. These good mechanical pencils feature a 0.7mm medium point, ideal for a variety of tasks, from jotting down notes to solving math problems. As the #1 selling mechanical pencil brand in the United States*, BIC pencils ensure consistent performance and quality you can trust. Each mechanical pencil comes with three pieces of No. 2 lead, making them suitable for standardized tests. The lead advances with a simple click of the built-in eraser, eliminating the need for sharpening and keeping your work neat and professional.', 0, 11),
    -- 850556
	('c_simmons@worksmart.com', 'BIC Xtra Smooth Pastel Edition Mechanical Pencil, 0.7mm, #2 Medium Lead', 'Enjoy smooth, dark writing with the durable BIC Xtra-Smooth mechanical pencils. With a fresh 0.7mm point only a click away, these No. 2 Bic mechanical pencils are perfect for standardized tests and eliminate the need to sharpen constantly, so you\'re always ready to write, draw, sketch, or doodle. The smooth-writing lead does not smudge and erases cleanly, and each pencil comes with three No. 2 leads, offering performance and value. These pencils are the perfect addition for your school or office supplies.', 0, 11),
    -- 850557
	('c_simmons@worksmart.com', 'Dixon Wooden Pencil, 2.2mm, #2 Soft Lead', 'Sketch out blueprints or make note of ideas with this pack of 144 No. 2 Dixon wooden soft pencils. Take notes or create sketched pictures with this pack of 144 soft No. 2 pencils. The commercial-grade wooden case delivers durability to the design, and the bonded lead prevents the tip from breaking in the middle of a sentence. These Dixon wooden soft pencils come in a pack of 144 to ensure you always have extras on hand.', 0, 11),
    -- 850558
	('g_pitts@supplies4school.org', 'Ticonderoga Pre-Sharpened Wooden Pencil, 2.2mm, #2 Soft Lead', 'Write down clear notes by hand with these Ticonderoga wood-cased pre-sharpened #2 pencils. Draw or write with these soft yellow-barrel pencils. The premium wood construction has a comfortable feel, while the graphite core formula offers smooth, consistent performance. Made with latex-free erasers, these Ticonderoga #2 pencils create neat, easy corrections.', 0, 11),
    -- 850559
	('g_pitts@supplies4school.org', 'Ticonderoga The World\'s Best Pencil Wooden Pencil, 2.2mm, #2 Soft Lead', 'Sketch and jot down notes with accuracy with this 12-pack of Dixon Ticonderoga wood-case #2 soft yellow-barrel pencils. Write easy-to-read notes with these Dixon Ticonderoga wood-case #2 soft, yellow-barrel pencils. These pencils are ideal for busy offices and classrooms, and the solid graphite core delivers a smooth performance and easy-to-read text. These Dixon Ticonderoga wood-case pencils have a latex-free eraser to make it easy to correct mistakes on paper.', 0, 11),
    -- 850560
	('g_pitts@supplies4school.org', 'BiC Round Stic Xtra Life Ballpoint Pens, Medium Point, 0.7mm', 'BIC Round Stic Xtra Life Black Ballpoint Pens are your go-to choice for reliable writing. These ball point pens feature a 1.0mm medium point, making them a great ballpoint pen for everyday use. The BIC Round Stic Pen writes 90% longer compared to PaperMate InkJoy 100 stick ball pens*, ensuring you have a pen that lasts. With a comfortable, flexible round barrel, these medium point pens provide a smooth and controlled writing experience. The translucent barrel lets you see the ink level, so you\'re not caught off guard. With a BIC Round Stic Pen handy, you\'ll be ready for any task.', 0, 11),
    -- 850561
	('c_simmons@worksmart.com', 'Pilot G2 Retractable Gel Pens, Fine Point, Medium Point, 0.7mm', 'Enjoy a smear-free writing experience by using these Pilot G2 fine-point premium retractable gel roller pens. Improve handwriting, create drawings and work on other projects by using these fine-point premium roller pens. With a convenient clip, these pens attach to binders, notebooks and pockets, while the contoured grip offers increased support, making it easy to take on lengthy writing tasks. These Pilot G2 gel pens feature a retractable design, so you can tuck the tips away when not in use, preventing unintentional marks to documents.', 0, 11),
    -- 850562
	('g_pitts@supplies4school.org', 'Pilot G2 Retractable Gel Pens, Fine Point, 0.7mm', 'Enjoy a smear-free writing experience by using these Pilot G2 fine-point premium retractable gel roller pens. Improve handwriting, create drawings and work on other projects by using these fine-point premium roller pens. With a convenient clip, these pens attach to binders, notebooks and pockets, while the contoured grip offers increased support, making it easy to take on lengthy writing tasks. These Pilot G2 gel pens feature a retractable design, so you can tuck the tips away when not in use, preventing unintentional marks to documents.', 0, 11),
    -- 850563
	('c_simmons@worksmart.com', 'Paper Mate 0.7mm Flair Felt Pens', 'Make solid strokes in vibrant colors with this 12-pack of Flair medium-point felt pens in assorted Tropical Vacation colors. Add color to your calendar and all your general writing tasks with ease with these Paper Mate medium-point pens in assorted colors. The metal-reinforced felt tip delivers smooth, thick lines using long-lasting, water-based ink that dries quickly to resist smudges. These felt pens feature a plastic construction that matches the ink color and a secure cap with a pocket clip to prevent dry out.', 0, 11),
    -- 850564
    ('c_simmons@worksmart.com', 'Sharpie Permanent Fine Tip Markers', 'Sharpie fine point permanent markers write smoothly on a variety of surfaces. Create a bold, vibrant impression on metal, glass, plastic or cloth with Sharpie permanent markers. The resilient, quick-drying ink is waterproof, smudge-proof and doesn\'t wear, so your text stays clear over time. Fine-point tips make these markers a pleasure to use by ensuring your writing is legible and uniform. An AP nontoxic certification makes these markers perfect for use around coworkers or children.', 0, 11),
    -- 850565
    ('g_pitts@supplies4school.org', 'Expo Dry Erase Starter Set', 'Create eye-catching white board presentations and dry-erase them easily with the Expo dr-erase starter set. Produce colorful whiteboard presentations with the﻿ black, red, green and blue markers in this starter set. The nontoxic markers are made using a low-odor formula and feature a chisel tip for fine or bold markings. The cleaner solution in this Expo dry-erase starter set removes any stubborn markings or smudges from whiteboard surfaces.', 0, 11),
    -- 850566
    ('g_pitts@supplies4school.org', 'Expo Dry Erase Kit', 'This Expo Dry-Erase Kit contains low-odor ink and is everything you\'ll need to give effective and colorful presentations. This low-odor whiteboard kit comes in a durable storage case and offers contemporary designs to fit any decor. This whiteboard marker set includes four fine point markers, eight chisel tip markers, an eraser and an 8 oz. bottle of cleaner.', 0, 11),
    -- 850566
    ('c_simmons@worksmart.com', 'Expo Dry Erase Markers', 'Organize ideas on the boardroom whiteboard with this 12-pack of Expo low-odor chisel tip dry-erase markers. Brainstorm new concepts with your team and these Expo dry-erase markers. The bold pens come in a pack of 12 assorted colors, so it\'s easy to list ideas or notate diagrams clearly and the low odor makes these markers ideal for closed areas such as classrooms and offices. Chisel tips on these quick-drying Expo dry-erase markers let you write with broad, medium and fine lines.', 0, 11),
    
-- notetaking -- 
    -- 850567
	('g_pitts@supplies4school.org', 'APEX Spiral Notebook', 'APEX Spiral Notebooks feature 70 wide-ruled sheets, 1 subject, with 3-hole perforated sheets. Available as single notebook or in multi-packs.', 0, 12),
	-- 850568
    ('g_pitts@supplies4school.org', 'Post-It Super Sticky Notes 3" x 3"', "Post-it® Super Sticky Notes are the perfect solution for shopping lists, reminders, to-do lists, color-coding, labeling, family chore reminders, brainstorming, storyboarding, and quick notes. Post-it Super Sticky Notes offer twice the sticking power of basic sticky notes, ensuring they stay put and won't fall off.", 0, 12),
    -- 850569
    ('g_pitts@supplies4school.org', 'Post-It Flags Combo Pack', 'Find it fast with Post-it® Flags in bright eye-catching colors that get noticed. They make it simple to mark or highlight important information in textbooks, calendars, notebooks, planners and more. They stick securely, remove cleanly and come in a wide variety of colors. Draw attention to critical items or use them to index, file or color code your work, either at home, work or in the classroom.', 0, 12),
    
-- folders & filing --
    -- 850570
    ('g_pitts@supplies4school.org', 'Post-It Durable Tabs', 'Durable Tabs are extra thick and strong to stand up to long-term wear and tear. Great for dividing notes, expanding files and project files. Sticks securely, removes cleanly.', 0, 13),
    
-- Bags, Lunchboxes, & Backpacks --
    -- 850571
	('c_simmons@worksmart.com', 'bentogo Modern Lunch Box', 'The Bentgo Modern lunch box gives healthy eating on the go a stylish makeover. Designed to turn heads in the office break room, the versatile three- or four-compartment bento-style lunch box features a contoured outer shell with a sleek matte finish, held tightly closed with a shiny metallic clip. Leak-resistant, the removable tray is microwave- and dishwasher-friendly, making eating and cleanup a breeze. Eating healthy has never looked so good.', 0, 14),
    -- 850572
    ('c_simmons@worksmart.com', 'bentogo Pop Lunch Box', 'Perfect for big kids and teens, the bentgo Pop leakproof lunch box livens up their lunchtime routine with its bright, bold colors, and stylish design. This microwave-safe bento box holds up to 5 cups of food, so it\'s two times bigger than bentgo kids\' lunch box. Your teen can enjoy an entire sandwich or a full entree, plus two sides, in the removable, three-compartment tray. Insert the optional divider to turn your three-compartment meal prep container into a four-compartment food container. The box is stylish, colorful, and leakproof, so they never have to worry about spills in their backpack or bag.', 0, 14),
	-- 850573
    ('g_pitts@supplies4school.org', 'JAM Paper Kraft Lunch Bags', 'Keep up to date with the zero-plastic trend and use these JAM Paper kraft paper small lunch bags. Each of these small bags is ideal for snacks, spices or arts and crafts materials, and they\'re constructed from 100 percent recycled materials and are biodegradable and recyclable. This pack of 25 JAM Paper kraft paper small lunch bags supplies you with meal packaging for a month, or use them in retail environments for an upmarket look.', 0, 14),
    -- 850574
	('g_pitts@supplies4school.org', 'JanSport Big Student Backpacks', 'The JanSport Big Student backpack is perfect for carrying all of your supplies. The backpack is made of 100% recycled polyester and features a dedicated 15" padded laptop compartment. Features two large main compartments, one front utility pocket with organizer, one pleated front stash pocket, and one zippered front stash pocket. Includes a side water bottle pocket, ergonomic S-curve shoulder straps, and a fully padded back panel.', 0, 14),
	-- 850575
	('g_pitts@supplies4school.org', 'JanSport Big Student Patterned Backpacks', 'The JanSport Big Student backpack is perfect for carrying all of your supplies. The backpack is made of 100% recycled polyester and features a dedicated 15" padded laptop compartment. Features two large main compartments, one front utility pocket with organizer, one pleated front stash pocket, and one zippered front stash pocket. Includes a side water bottle pocket, ergonomic S-curve shoulder straps,  and a fully padded back panel.', 0, 14);

-- school basics --
    -- 850576
	('g_pitts@supplies4school.org', 'Fiskars Kids\' Scissors, Blunt Tip', 'Every child is a creative genius, and the only limit to their self-expression should be their wildest imaginations. The Fiskars blunt-tip kids\' scissors are thoughtfully designed for growing hands and creative minds. These scissors are great for children ages four and up, because every creative genius deserves the right scissors at the right age to express themselves. Safety-edge blades feature a safer blade angle and blunt tip for added safety when cutting classroom materials', 0, 101),
    -- 850577
	('g_pitts@supplies4school.org', 'Elmer\'s School Washable Removable Glue Sticks', 'Put together presentations, crafts, and other projects with this 30-pack of Elmer\'s all-purpose clear school glue sticks. Permanently bond items to paper, cardboard, foam board, display board, and more with the non-toxic adhesive of Elmer\'s All Purpose Glue Sticks. They are washable, acid-free, photo safe, and non-toxic', 0, 101),
    -- 850578
	('g_pitts@supplies4school.org', 'Westcott 12" Plastic Standard Ruler', 'Westcott standard rulers are made of sturdy plastic and come in assorted colors and measure up to 12". 0.06" imperial and standard 0.1cm metric scales. Measures up to 12" with extra margins at the ends for clear starts and stops. Includes holes for three-ring binders.', 0, 101),
    -- 850579
	('g_pitts@supplies4school.org', 'Barker Creek Self-adhesive Oh Hello! School Name Tags, 2.75" x 3.5"', "You'll find dozens of uses for these versatile name tags / self-adhesive labels from Barker Creek. Barker Creek’s Oh, hello! Name tags and self-adhesive labels are perfect for all ages! Package includes 90 multi-purpose self-adhesive name tags — 30 each of 3 designs. The designs feature a lovely navy color and say ‘Oh, Hello! My name is…’, ‘Hello! My name is…’, and ‘Hi there! My name is…’. There is also a box to write in your name. These name tags are perfect for the first week of school, field trips, assemblies, special visitors, staff meetings and more!", 0, 101),
    -- 850580
	('g_pitts@supplies4school.org', 'PURELL SINGLES Advanced 70% Alcohol Gel Hand Sanitizer', 'Help those you care for kill germs on the go with PURELL SINGLES® Advanced Hand Sanitizer Gel, also known as PURELL PERSONALS™ Advanced Hand Sanitizer Gel. Just bend the packet and squirt with one hand, for a fun and refreshing cleaning experience. Gives you the perfect amount of America\'s No. 1 brand hand sanitizer to kill 99.99% of most common germs that may cause illness – anywhere, anytime. With four unique skin conditioners, it’s gentle on hands. PURELL PERSONALS™ packets fit anywhere – pocket, wallet, car, cell phone case, your smallest bag – and the no-leak durable design means mess-free protection from germs.', 0, 101),
    -- 850581
	('g_pitts@supplies4school.org', 'CloroxPro Disinfecting Wipes, Fresh Scent', 'DISINFECTING WIPES: EPA registered to kill 99.9% of viruses and bacteria; Meets EPA criteria for use against SARS-CoV-2, the virus that causes COVID-19, on non-porous surfaces. VERSITILE CLEANING WIPE: Create clean public spaces with these wet wipes that breakdown grease, soap scum and grime so you can tackle messes on a variety of surfaces, bleach-free. ALL PURPOSE WIPE: Quickly sanitizes bacteria and kills most viruses in as little as 15 seconds; removes common allergens and deodorizes, preventing the odor causing bacteria for up to 24 hours. GREAT FOR COMMERCIAL USE: From CloroxPro™, ideal for use in offices, day care centers, schools, busy healthcare environments and other commercial facilities.', 0, 101),
    -- 850582
	-- ('', '', '', , ),
    -- 850583
	-- ('', '', '', , ),
    -- 850584
	-- ('', '', '', , ),
    -- 850585
-- 	('', '', '', , ),
    -- 850586
	-- ('', '', '', , ),
    -- 850587
-- 	('', '', '', , ),
    -- 850588
	-- ('', '', '', , ),
    -- 850588
    -- ('', '', '', , ),
    -- 850589
    -- ('', '', '', , ),
    -- 850590
    -- ('', '', '', , ),
    -- 850591
    -- ('', '', '', , ),
    -- 850592
    -- ('', '', '', , ),
    -- 850593
    -- ('', '', '', , ),
    -- 850594
    -- ('', '', '', , ),
    -- 850595
    -- ('', '', '', , ),
    -- 850596
    -- ('', '', '', , ),
    -- 850597
   --  ('', '', '', , ),
    -- 850598
   --  ('', '', '', , ),
    -- 850599
   --  ('', '', '', , ),
    -- 850600
   --  ('', '', '', , );
   
INSERT INTO colors (color_name, color_hex)
VALUES
	('Assorted', NULL),					-- 800 (19710)
    ('Assorted Metallics', NULL),		-- 801
    ('Assorted Pastels', NULL),			-- 803
	('Multicolor', NULL),				-- 804 19799
	('Pattern', NULL),					-- 805 19797, 19798 19803 19802 19800
	('Black', '#000000'),				-- 806 19786
	('Blue', '#0000ff'),				-- 807 19782
	('Clear', NULL),					-- 808 19788
	('Cyan', '#00bfff'),				-- 809 19805
	('Dark Blue', '#06065c'),			-- 810 19793
	('Dark Brown', '#52422e'),			-- 811 
	('Dark Green', '#004d00'),			-- 812 
	('Dark Grey', '#666666'),			-- 813 
	('Dark Red', '#8b0000'),			-- 814 
	('Green', '#00ff00'),				-- 815 19783
	('Light Blue', '#b3d9ff'),			-- 816 
	('Light Brown', '#b59b7c'),			-- 817 
	('Light Green', '#66ffc3'),			-- 818 19810
	('Light Grey', '#bfbfbf'),			-- 819 
	('Lilac', '#c8a2c8'),				-- 820 19792
	('Magenta', '#ff33cc'),				-- 821 19804
	('Manila', '#e7c9a9'),				-- 822 19808
	('Maple', '#bb9351'),				-- 823 19791
	('Navy', '#000080'),				-- 824 19785
	('Orange', '#ff6600'),				-- 825 
	('Orchid', '#e2cfe1'),				-- 826 19809
	('Pink', '#ff80aa'),				-- 827 19811
	('Purple', '#800080'),				-- 828 19806
	('Red', '#ff0000'),					-- 829 19781
	('Rose Pink', '#f0afc1'),			-- 830 19794
	('Silver', '#c0c0c0'),				-- 831 19807
	('Sky Blue', '#1a6bb8'),			-- 832 19795
	('Walnut', '#99592e'),				-- 833 19787
	('White', '#ffffff'),				-- 834 19790
	('Yellow', '#ffff00');				-- 835 19784

INSERT INTO sizes (size_description)
VALUES
	('standard'),									-- 100
	('Single'),				 						-- 101
    ('5-Pack'),										-- 102
	('6-Pack'), 									-- 103
	('10-Pack'), 									-- 104
	('12-Pack'),			 						-- 105
	('24-Pack'), 									-- 106
    ('30-Pack'),									-- 107
	('36-Pack'),									-- 108
    ('40-Pack'),									-- 109
	('48-Pack'),			 						-- 110
	('50-Pack'),									-- 111
	('60-Pack'), 									-- 112
    ('72-Pack'),									-- 113
    ('90-Pack'),									-- 114
	('100-Pack'),									-- 115
    ('144-Pack'),									-- 116
    ('320-Pack'),									-- 117
    ('432-Pack'),									-- 118
	('2.4"H x 9.1"W x 7"D '),						-- 119
	('2.4"H x 9.4"W x 7.1"D '), 					-- 120
	('8"H x 4.25"W x 2.25"D '), 					-- 121 
	('14.5"H x 14"W x 11.25"D '), 					-- 122
	('33.75"H x 14.68"W x 18.37"L '), 				-- 123
	('13"W x 10"D x 17.5"H '), 						-- 124
	('20"W x 19"D x 18-22"H '), 					-- 125
	('16"W x 18"D x 26"L '), 						-- 126
	('16"W x 22"D x 28"L '), 						-- 127
	('1-Ream 500 Sheets/Ream'),						-- 128
	('3-Ream 500 Sheets/Ream'), 					-- 129
	('5-Ream 500 Sheets/Ream'), 					-- 130
	('8-Ream 500 Sheets/Ream'), 					-- 131
	('10-Ream 500 Sheets/Ream'),					-- 132
	('70 Sheet/Pad, 24 Pads/Pack'),					-- 133
	('90 Sheet/Pad, 5 Pads/Pack'),					-- 134
	('320 Flags/Pack'),								-- 135
	('1"W 66Tabs/Pack'),							-- 136
	('2"W 24 Tabs/Pack'),							-- 137
	('1 Pack/800 Pages'),							-- 138
	('1 Pack/1250 Pages'),							-- 139
	('4 Pack/3650 Pages'),							-- 140
	('9125e: 250 Sheet Input/60 Sheet Output'), 	-- 141
	('9135e: 500 Sheet Input/100 Sheet Output'), 	-- 142
	('GX3020: 250 Sheet Input/100 Sheet Output'), 	-- 143
	('GX4020: 250 Sheet Input/100 Sheet Output'), 	-- 144
	('GX5020: 350 Sheet Input'), 					-- 145
	('132mL capacity'),								-- 146
	('16GB RAM'); 									-- 147
    
INSERT INTO product_variants (product_id, color_id, size_id, price, current_inventory)
VALUES
	-- 850555 bic mech pencils smooth regular --
	-- 100200
	(850555, 800, 104, 479, 15), -- 10 pack
    -- 100201
    (850555, 800, 105, 499, 15), -- 12 pack
    -- 100202
    (850555, 800, 109, 1689, 15), -- 40 pack
    -- 100203
    (850555, 800, 117, 13099, 15), -- 320 pack
    
    -- 850556 bic mech pencils smooth pastels --
    -- 100204
    (850556, 800, 106, 999, 15), -- 24 pack
    -- 100205
    (850556, 800, 109, 1899, 15), -- 40 pack
    
    -- dixon wooden pencil --
    -- 100206
    (850557, 816, 116, 1249, 15), -- 144 Pack
    
    -- ticonderoga sharpened wooden pencils --
    -- 100207
    (850558, 834, 105, 559, 15), -- 12 pack
    -- 100208
    (850558, 834, 100, 719, 15), -- 18 pack
    -- 100209
    (850558, 834, 107, 949, 15), -- 30 pack
    -- 100210
    (850558, 834, 113, 1889, 15), -- 72 pack 
    
    -- ticonderoga UNsharpened wooden pencils --
    -- 100211
    (850559, 834, 105, 499, 15), -- 12 pack
    -- 100212
    (850559, 834, 106, 799, 15), -- 24 pack
    -- 100213
    (850559, 834, 114, 2149, 15), -- 96 pack

    -- bic round stic xtra life pens --
    -- 100214
    (850560, 805, 105, 111, 15), -- 12 pack black
    -- 100215
    (850560, 806, 105, 111, 15), -- 12 pack blue
    -- 100216
    (850560, 828, 105, 111, 15), -- 12 pack red
    -- 100217
    (850560, 805, 112, 111, 15), -- 60 pack black
    -- 100218
    (850560, 806, 112, 111, 15), -- 60 pack blue
    -- 100219
    (850560, 800, 112, 111, 15), -- 60 pack assorted 
    -- 100220
    (850560, 805, 115, 111, 15), -- 120 pack black
    -- 100221
    (850560, 805, 118, 111, 15), -- 432 pack black
    
    -- pilot g2 pens 12 pack --
    -- 100222
    (850561, 805, 105, 111, 15), -- black 12 pack
    -- 100223
    (850561, 828, 105, 111, 15), -- red 12 pack
    -- 100224
    (850561, 823, 105, 111, 15), -- navy 12 pack
    -- 100225
    (850561, 806, 105, 111, 15), -- blue 12 pack
    -- 100226
    (850561, 814, 105, 111, 15), -- green 12 pack
    -- 100227
    (850561, 827, 105, 111, 15), -- purple 12 pack
    
    
    -- 100228
    (850562, 805, 108, 111, 15), -- black
    -- 100229
    (850562, 806, 108, 111, 15), -- blue
    -- 100230
    (850562, 800, 108, 111, 15), -- assorted
    -- 100231
    (850562, 801, 108, 111, 15), -- assorted (pastels)
    -- 100232
    (850562, 802, 108, 111, 15), -- assorted (metallic)
    
	-- paper mate felt pens --
    (850563, 800, 100, 1149, 16),			-- 100233 assorted colors
    
    -- sharpie permenant markers --
    (850564, 805, 100, 2599, 12),			-- 100234 black
    (850564, 828, 100, 2599, 12), 			-- 100235 red
    (850564, 806, 100, 2599, 12), 			-- 100236 blue
    (850564, 830, 100, 2599, 12), 			-- 100237 silver
    (850564, 800, 100, 2599, 12), 			-- 100238 assorted
    (850564, 800, 101, 1999, 16),			-- 100239 assorted 24 pack
    
    -- dry erase starter set --
    (850565, 800, 100, 799, 9),			-- 100240
    
    -- dry erase kit --
    (850566, 800, 100, 1999, 11),			-- 100241
    
    -- dry erase markers 12-pack --
    (850567, 800, 100, 1379, 10), 		-- 100242 assorted
    (850567, 803, 100, 1379, 10), 		-- 100243 black 
    (850567, 826, 100, 1379, 10),			-- 100244 red
    (850567, 812, 100, 1379, 10), 		-- 100245 green
    (850567, 804, 100, 1379, 10), 		-- 100246 blue
    (850567, 825, 100, 1379, 10), 		-- 100247 purple
    
    -- 100248
    -- post it notes large pack --
    (850568, 800, 100, 2399, 5),			-- 100249
    (850568, 800, 101, 2399, 5),			-- 100250
    (850568, 800, 103, 2399, 5),			-- 100251
    (850568, 800, 102, 2399, 5),			-- 100252
	-- post it notes small pack
    (850569, 800, 103, 699, 5),	-- 100253
    (850569, 800, 104, 699, 5),	-- 100254
    (850569, 800, 105, 699, 5),	-- 100255
    (850569, 800, 106, 699, 5),	-- 100256
    -- post it flags combo
    (850570, 800, 100, 1329, 15),	-- 100257
    -- post it tabs
    (850571, 800, 100, 789, 11),		-- 100258
    (850571, 800, 101, 429, 8);		-- 100259
    
 --    100260
 --    ( , , , , 15),
    -- 100261
    -- ( , , , , 15),
    -- 100250
   --  ( , , , , 15),
    -- 100251
   --  ( , , , , 15),
    -- 100252
    -- ( , , , , 15),
    -- 100253
   --  ( , , , , 15),
    -- 100254
  --   ( , , , , 15),
    -- 100255
   --  ( , , , , 15),
    -- 100256
   --  ( , , , , 15),
    -- 100257
   --  ( , , , , 15),
    -- 100258
   --  ( , , , , 15),
    -- 100259
   --  ( , , , , 15),
    -- 100260
  --   ( , , , , 15),
    -- 100261
   --  ( , , , , 15),
    -- 100262
   --  ( , , , , 15),
    -- 100263
    -- ( , , , , 15),
    -- 100264
    -- -- ( , , , , 15),
    -- 100265
   --  ( , , , , 15),
    -- 100266
    -- ( , , , , 15),
    -- 100267
    -- ( , , , , 15),
    -- 100268
    -- ( , , , , 15),
    -- 100269
    -- ( , , , , 15),
    -- 100270
    -- ( , , , , 15),
    -- 100271
    -- ( , , , , 15),
    -- 100272
    -- ( , , , , 15),
    -- 100273
    -- ( , , , , 15),
    -- 100274
    -- ( , , , , 15),
    -- 100275
    -- ( , , , , 15),
    -- 100276
    -- ( , , , , 15),
    -- 100277
  -- --   ( , , , , 15),
    -- 100278
   --  ( , , , , 15),
    -- 100279
    -- ( , , , , 15),
    -- 100280
    -- ( , , , , 15);

INSERT INTO images (variant_id, file_path)
VALUES
-- bic mech pencils --
	(100200, 'https://www.staples-3p.com/s7/is/image/Staples/sp134866786_sc7?wid=700&hei=700'),
    (100200, 'https://www.staples-3p.com/s7/is/image/Staples/BD2506AA-25C9-4DBF-8A9A71DDABB79FEC_sc7?wid=700&hei=700'),
    (100200, 'https://www.staples-3p.com/s7/is/image/Staples/D1FA9BE6-94CE-4799-89346460B9D84DC6_sc7?wid=700&hei=700'),
    (100200, 'https://www.staples-3p.com/s7/is/image/Staples/6DBDA0CD-FD08-4936-9C6C77F937090506_sc7?wid=700&hei=700'),
    
    (100201, 'https://www.staples-3p.com/s7/is/image/Staples/CFABF4B6-1E01-4A4B-BBF48A5466E535C4_sc7?wid=700&hei=700'),
    (100201, 'https://www.staples-3p.com/s7/is/image/Staples/BD2506AA-25C9-4DBF-8A9A71DDABB79FEC_sc7?wid=700&hei=700'),
    (100201, 'https://www.staples-3p.com/s7/is/image/Staples/D1FA9BE6-94CE-4799-89346460B9D84DC6_sc7?wid=700&hei=700'),
    (100201, 'https://www.staples-3p.com/s7/is/image/Staples/6DBDA0CD-FD08-4936-9C6C77F937090506_sc7?wid=700&hei=700'),
    
    (100202, 'https://www.staples-3p.com/s7/is/image/Staples/12F2D191-C6FA-4470-A45D43E3FB233591_sc7?wid=700&hei=700'),
    (100202, 'https://www.staples-3p.com/s7/is/image/Staples/BD2506AA-25C9-4DBF-8A9A71DDABB79FEC_sc7?wid=700&hei=700'),
    (100202, 'https://www.staples-3p.com/s7/is/image/Staples/D1FA9BE6-94CE-4799-89346460B9D84DC6_sc7?wid=700&hei=700'),
    (100202, 'https://www.staples-3p.com/s7/is/image/Staples/6DBDA0CD-FD08-4936-9C6C77F937090506_sc7?wid=700&hei=700'),
    
    (100203, 'https://www.staples-3p.com/s7/is/image/Staples/sp168943593_sc7?wid=700&hei=700'),
    (100203, 'https://www.staples-3p.com/s7/is/image/Staples/BD2506AA-25C9-4DBF-8A9A71DDABB79FEC_sc7?wid=700&hei=700'),
    (100203, 'https://www.staples-3p.com/s7/is/image/Staples/D1FA9BE6-94CE-4799-89346460B9D84DC6_sc7?wid=700&hei=700'),
    (100203, 'https://www.staples-3p.com/s7/is/image/Staples/6DBDA0CD-FD08-4936-9C6C77F937090506_sc7?wid=700&hei=700'),
    
-- bic mech pencils smooth pastels --
    (100204, 'https://www.staples-3p.com/s7/is/image/Staples/1C475290-ABD6-41A1-8631B8F24A3F3A8F_sc7?wid=700&hei=700'),
    (100204, 'https://www.staples-3p.com/s7/is/image/Staples/E86EB62F-574D-48C2-87426BF1569AE046_sc7?wid=700&hei=700'),
    (100204, 'https://www.staples-3p.com/s7/is/image/Staples/0EF056CA-AEA0-4DFD-841D625E40E23F4E_sc7?wid=700&hei=700'),
    (100204, 'https://www.staples-3p.com/s7/is/image/Staples/2BDD2BDD-F434-44A8-85AE5CDB932F35FA_sc7?wid=700&hei=700'),
    
    (100205, 'https://www.staples-3p.com/s7/is/image/Staples/F25FB988-02AE-4727-B8C1D5E1505761B2_sc7?wid=700&hei=700'),
    (100205, 'https://www.staples-3p.com/s7/is/image/Staples/E86EB62F-574D-48C2-87426BF1569AE046_sc7?wid=700&hei=700'),
    (100205, 'https://www.staples-3p.com/s7/is/image/Staples/0EF056CA-AEA0-4DFD-841D625E40E23F4E_sc7?wid=700&hei=700'),
    (100205, 'https://www.staples-3p.com/s7/is/image/Staples/2BDD2BDD-F434-44A8-85AE5CDB932F35FA_sc7?wid=700&hei=700'),
    
-- dixon wooden pencils 144 pack --
	(100206, 'https://www.staples-3p.com/s7/is/image/Staples/sp49507996_sc7?wid=700&hei=700'),
    (100206, 'https://www.staples-3p.com/s7/is/image/Staples/sp49507997_sc7?wid=700&hei=700'),
    (100206, 'https://www.staples-3p.com/s7/is/image/Staples/sp49507998_sc7?wid=700&hei=700'),
    (100206, 'https://www.staples-3p.com/s7/is/image/Staples/E6C6C568-E17D-4B4C-8B021B125435EF61_sc7?wid=700&hei=700'),
    
-- ticonderoga pencils sharpened --
	(100207, 'https://www.staples-3p.com/s7/is/image/Staples/049FBA3E-4A6D-4AD0-9C2BEBBA853D6EE2_sc7?wid=700&hei=700'),
    (100207, 'https://www.staples-3p.com/s7/is/image/Staples/CB08C81A-B707-4DFF-85DF4A6E006CC277_sc7?wid=700&hei=700'),
    (100207, 'https://www.staples-3p.com/s7/is/image/Staples/D1119CF9-8775-4F6F-B228B0DE23CBA425_sc7?wid=700&hei=700'),
    (100207, 'https://www.staples-3p.com/s7/is/image/Staples/E71A5E9A-B04F-43B6-97E6F6EB5EF5A79F_sc7?wid=700&hei=700'),
    
	(100208, 'https://www.staples-3p.com/s7/is/image/Staples/42511C4C-95D1-41B2-BCC9AA58E69BC20B_sc7?wid=700&hei=700'),
    (100208, 'https://www.staples-3p.com/s7/is/image/Staples/BF3720DC-8A99-473C-9B8F2B160F453C35_sc7?wid=700&hei=700'),
    (100208, 'https://www.staples-3p.com/s7/is/image/Staples/B0B60957-E5E1-402D-90A1534BD6109340_sc7?wid=700&hei=700'),
    (100208, 'https://www.staples-3p.com/s7/is/image/Staples/FF4B7AE7-A90E-4368-B74105FF1B14558E_sc7?wid=700&hei=700'),
    
	(100209, 'https://www.staples-3p.com/s7/is/image/Staples/D484B555-81C2-4C89-BE1E3E6E0B757359_sc7?wid=700&hei=700'),
    (100209, 'https://www.staples-3p.com/s7/is/image/Staples/5C992AA3-B589-4DB5-B6B6E759F957B70A_sc7?wid=700&hei=700'),
    (100209, 'https://www.staples-3p.com/s7/is/image/Staples/FD036A75-1493-43D8-A3C06C9AE418E8A1_sc7?wid=700&hei=700'),
    (100209, 'https://www.staples-3p.com/s7/is/image/Staples/3ABDD635-CDE8-4D0B-AB9BCA795F56D66A_sc7?wid=700&hei=700'),
    
	(100210, 'https://www.staples-3p.com/s7/is/image/Staples/7661DDE1-93D7-4F37-A9A89942EB5F96D3_sc7?wid=700&hei=700'),
    (100210, 'https://www.staples-3p.com/s7/is/image/Staples/92822F48-D2D0-4B93-ADE2B00569D2E221_sc7?wid=700&hei=700'),
    (100210, 'https://www.staples-3p.com/s7/is/image/Staples/09EA427F-71CF-4177-B095CE08564B488D_sc7?wid=700&hei=700'),

-- ticonderoga pencils unsharpened --
    (100211, 'https://www.staples-3p.com/s7/is/image/Staples/E8191618-67DB-431B-B01CB7FB8B06D167_sc7?wid=700&hei=700'),
    (100211, 'https://www.staples-3p.com/s7/is/image/Staples/29C8C17E-598F-4446-A3D3B967E9D3B26B_sc7?wid=700&hei=700'),
    (100211, 'https://www.staples-3p.com/s7/is/image/Staples/ACE88776-DBE8-489D-808559078CFD6466_sc7?wid=700&hei=700'),
    (100211, 'https://www.staples-3p.com/s7/is/image/Staples/F8A19755-D2DE-446B-B1CF5BFB27A5474C_sc7?wid=700&hei=700'),
    
    (100211, 'https://www.staples-3p.com/s7/is/image/Staples/6C8A5B5E-EBF7-42C9-A2E0C4E317F393EF_sc7?wid=700&hei=700'),
    (100211, 'https://www.staples-3p.com/s7/is/image/Staples/43591D45-A913-42BE-A376D8C7E5074049_sc7?wid=700&hei=700'),
    (100211, 'https://www.staples-3p.com/s7/is/image/Staples/939E04CB-B5C9-4832-A7AB4B90345DDD20_sc7?wid=700&hei=700'),
    (100211, 'https://www.staples-3p.com/s7/is/image/Staples/052DB59F-FA7E-4411-890DEC20751DC751_sc7?wid=700&hei=700'),
    
    (100211, 'https://www.staples-3p.com/s7/is/image/Staples/372E4DA9-88DD-4EBF-89BBFFC8852CD969_sc7?wid=700&hei=700'),
    (100211, 'https://www.staples-3p.com/s7/is/image/Staples/ADC6E670-5FD1-4120-BA6DB5C1F79B8A6D_sc7?wid=700&hei=700'),
    (100211, 'https://www.staples-3p.com/s7/is/image/Staples/6CF02D83-A85D-4904-A47A9116E17E883C_sc7?wid=700&hei=700'),
    (100211, 'https://www.staples-3p.com/s7/is/image/Staples/1C264F7C-635F-4786-8C736D66C16A5EF7_sc7?wid=700&hei=700'),
    
-- bic ballpoint pens -- 
	-- 12 black
	(100214, 'https://www.staples-3p.com/s7/is/image/Staples/726A4704-D070-461A-A455FCF4ACF7B46F_sc7?wid=700&hei=700'),
    (100214, 'https://www.staples-3p.com/s7/is/image/Staples/02F1F184-741B-4288-8382383E0E596991_sc7?wid=700&hei=700'),
    (100214, 'https://www.staples-3p.com/s7/is/image/Staples/2DFF5935-83DB-4F93-9B7616091D23EEA2_sc7?wid=700&hei=700'),
    -- 12 blue
    (100215, 'https://www.staples-3p.com/s7/is/image/Staples/5BA27BD0-0DFA-441E-991D22D9B7EEBC85_sc7?wid=700&hei=700'),
    (100215, 'https://www.staples-3p.com/s7/is/image/Staples/CCA66B60-B2CF-412C-9E6129E35472C408_sc7?wid=700&hei=700'),
    (100215, 'https://www.staples-3p.com/s7/is/image/Staples/B3EC6B8C-E373-4EC4-B3E9702F0FF629AE_sc7?wid=700&hei=700'),
    -- 12 red
    (100216, 'https://www.staples-3p.com/s7/is/image/Staples/BC5D0E88-8321-4645-AA5F31AC9F42C60A_sc7?wid=700&hei=700'),
    (100216, 'https://www.staples-3p.com/s7/is/image/Staples/A6D65917-D1B1-498B-8980AD55397B2366_sc7?wid=700&hei=700'),
    (100216, ''),
    -- black 60
    (100217, 'https://www.staples-3p.com/s7/is/image/Staples/AFD5FBB8-71A3-434C-989B74986834C3E5_sc7?wid=700&hei=700'),
    (100217, 'https://www.staples-3p.com/s7/is/image/Staples/281C65AA-E03C-4165-BE0335374B5300D6_sc7?wid=700&hei=700'),
    (100217, 'https://www.staples-3p.com/s7/is/image/Staples/DE4A6A03-B734-40EB-89A43123630B1165_sc7?wid=700&hei=700'),
	-- blue 60
    (100218, 'https://www.staples-3p.com/s7/is/image/Staples/8FF19026-7FC9-49C6-945FC921B193E318_sc7?wid=700&hei=700'),
    (100218, 'https://www.staples-3p.com/s7/is/image/Staples/0E907B5E-E49E-41E3-94C9770B386C4F22_sc7?wid=700&hei=700'),
    (100218, 'https://www.staples-3p.com/s7/is/image/Staples/763AFBAF-0157-4089-B191ABFD609F081D_sc7?wid=700&hei=700'),
    -- assorted 60
    (100219, 'https://www.staples-3p.com/s7/is/image/Staples/98CCE1B5-453E-4B3D-8D536E36EB5CB2E8_sc7?wid=700&hei=700'),
    (100219, 'https://www.staples-3p.com/s7/is/image/Staples/1483FD07-AEE3-4F94-A0450B55CC341499_sc7?wid=700&hei=700'),
    (100219, 'https://www.staples-3p.com/s7/is/image/Staples/FFEA53A9-96B9-4420-8D86911F934B46A7_sc7?wid=700&hei=700'),
    -- black 120
    (100220, 'https://www.staples-3p.com/s7/is/image/Staples/sp132863911_sc7?wid=700&hei=700'),
    (100220, 'https://www.staples-3p.com/s7/is/image/Staples/2F39A9B2-5AFC-47CF-A27302F60C109353_sc7?wid=700&hei=700'),
    (100220, 'https://www.staples-3p.com/s7/is/image/Staples/05C87821-7CA8-4C72-92A559379E8AE3A2_sc7?wid=700&hei=700'),
    -- black 432
    (100221, 'https://www.staples-3p.com/s7/is/image/Staples/sp41812286_sc7?wid=700&hei=700'),
    (100221, 'https://www.staples-3p.com/s7/is/image/Staples/sp41812283_sc7?wid=700&hei=700'),
    (100221, 'https://www.staples-3p.com/s7/is/image/Staples/sp41812284_sc7?wid=700&hei=700'),
    
	-- pilot g2 pens --
	(100222, 'https://www.staples-3p.com/s7/is/image/Staples/sp130855922_sc7?wid=700&hei=700'),
    (100222, 'https://www.staples-3p.com/s7/is/image/Staples/sp40286009_sc7?wid=700&hei=700'),
    (100222, 'https://www.staples-3p.com/s7/is/image/Staples/sp40286010_sc7?wid=700&hei=700'),
    
    (100223, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856306_sc7?wid=700&hei=700'),
    (100223, 'https://www.staples-3p.com/s7/is/image/Staples/sp130855924_sc7?wid=700&hei=700'),
    
    (100224, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856301_sc7?wid=700&hei=700'),
    (100224, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856302_sc7?wid=700&hei=700'),
    
    (100225, 'https://www.staples-3p.com/s7/is/image/Staples/sp138382946_sc7?wid=700&hei=700'),
    (100225, 'https://www.staples-3p.com/s7/is/image/Staples/5743C478-DAF6-41D4-A3DC245D60749CF1_sc7?wid=700&hei=700'),
    (100225, 'https://www.staples-3p.com/s7/is/image/Staples/sp41817060_sc7?wid=700&hei=700'),
    
    (100226, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856294_sc7?wid=700&hei=700'),
    (100226, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856295_sc7?wid=700&hei=700'),
    
    (100227, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856303_sc7?wid=700&hei=700'),
    (100227, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856304_sc7?wid=700&hei=700'),
    
    (100228, 'https://www.staples-3p.com/s7/is/image/Staples/sp137770008_sc7?wid=700&hei=700'),
    (100228, 'https://www.staples-3p.com/s7/is/image/Staples/sp137770011_sc7?wid=700&hei=700'),
    
    (100229, 'https://www.staples-3p.com/s7/is/image/Staples/sp137770008_sc7?wid=700&hei=700'),
    (100229, 'https://www.staples-3p.com/s7/is/image/Staples/sp137770011_sc7?wid=700&hei=700'),
    
    (100230, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856218_sc7?wid=700&hei=700'),
    (100230, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856219_sc7?wid=700&hei=700'),
    
    (100231, 'https://www.staples-3p.com/s7/is/image/Staples/s1070669_sc7?wid=700&hei=700'),
    (100231, 'https://www.staples-3p.com/s7/is/image/Staples/s1082037_sc7?wid=700&hei=700'),
    
    (100232, 'https://www.staples-3p.com/s7/is/image/Staples/s1078333_sc7?wid=700&hei=700'),
    (100232, 'https://www.staples-3p.com/s7/is/image/Staples/s1078334_sc7?wid=700&hei=700'),
    (100232, 'https://www.staples-3p.com/s7/is/image/Staples/s1078335_sc7?wid=700&hei=700'),
    (100232, 'https://www.staples-3p.com/s7/is/image/Staples/s1078336_sc7?wid=700&hei=700'),
    (100232, 'https://www.staples-3p.com/s7/is/image/Staples/s1078337_sc7?wid=700&hei=700'),
    
    -- paper mate felt pens --
    (100233, 'https://www.staples-3p.com/s7/is/image/Staples/98C1DFBD-AFCE-488D-B080922050338AA7_sc7?wid=700&hei=700'),
    (100233, 'https://www.staples-3p.com/s7/is/image/Staples/sp161466748_sc7?wid=700&hei=700'),
    (100233, 'https://www.staples-3p.com/s7/is/image/Staples/sp161466749_sc7?wid=700&hei=700'),
    
    -- sharpie permenant markers --
    -- black
    (100234, 'https://www.staples-3p.com/s7/is/image/Staples/D67EC31B-0DB3-45F9-BD62DC872D1ACBF1_sc7?wid=700&hei=700'),
    (100234, 'https://www.staples-3p.com/s7/is/image/Staples/1BCDF1C0-5454-4A4A-A616BD9601C8C140_sc7?wid=700&hei=700'),
    (100234, 'https://www.staples-3p.com/s7/is/image/Staples/DD9A5C21-9C21-4A0E-B3B6C1149A3D0399_sc7?wid=700&hei=700'),
    -- red
    (100235, 'https://www.staples-3p.com/s7/is/image/Staples/5CA98F6D-8D11-4886-B08C0CC322E38815_sc7?wid=700&hei=700'),
    (100235, 'https://www.staples-3p.com/s7/is/image/Staples/sp89168542_sc7?wid=700&hei=700'),
    (100235, 'https://www.staples-3p.com/s7/is/image/Staples/s0922441_sc7?wid=700&hei=700'),
    -- blue
    (100236, 'https://www.staples-3p.com/s7/is/image/Staples/1C929E3D-8BCF-48E2-A00933FB4AAD3B2D_sc7?wid=700&hei=700'),
    (100236, 'https://www.staples-3p.com/s7/is/image/Staples/s0933668_sc7?wid=700&hei=700'),
    (100236, 'https://www.staples-3p.com/s7/is/image/Staples/s0922442_sc7?wid=700&hei=700'),
    -- silver
    (100237, 'https://www.staples-3p.com/s7/is/image/Staples/m007068285_sc7?wid=700&hei=700'),
    (100237, 'https://www.staples-3p.com/s7/is/image/Staples/m007068281_sc7?wid=700&hei=700'),
    (100237, 'https://www.staples-3p.com/s7/is/image/Staples/m007068283_sc7?wid=700&hei=700'),
    -- assorted
    (100238, 'https://www.staples-3p.com/s7/is/image/Staples/s1189983_sc7?wid=700&hei=700'),
    (100238, 'https://www.staples-3p.com/s7/is/image/Staples/m002908378_sc7?wid=700&hei=700'),
    -- assorted 24 pack
    (100239, 'https://www.staples-3p.com/s7/is/image/Staples/D5E6B1CA-30FC-4219-9BD4322085DCA998_sc7?wid=700&hei=700'),
    (100239, 'https://www.staples-3p.com/s7/is/image/Staples/sp44335828_sc7?wid=700&hei=700'),
    (100239, 'https://www.staples-3p.com/s7/is/image/Staples/sp44335829_sc7?wid=700&hei=700'),
    
    -- dry erase starter set
    (100240, 'https://www.staples-3p.com/s7/is/image/Staples/E1755194-7001-4CE3-93598F83B0079751_sc7?wid=700&hei=700'),
    (100240, 'https://www.staples-3p.com/s7/is/image/Staples/sp40798560_sc7?wid=700&hei=700'),
    (100240, 'https://www.staples-3p.com/s7/is/image/Staples/sp40798562_sc7?wid=700&hei=700'),
    (100240, 'https://www.staples-3p.com/s7/is/image/Staples/sp40798565_sc7?wid=700&hei=700'),
    
    -- dry erase kit
    (100241, 'https://www.staples-3p.com/s7/is/image/Staples/m002304039_sc7?wid=700&hei=700'),
    (100241, 'https://www.staples-3p.com/s7/is/image/Staples/m002304040_sc7?wid=700&hei=700https://www.staples-3p.com/s7/is/image/Staples/m002304040_sc7?wid=700&hei=700'),
    (100241, 'https://www.staples-3p.com/s7/is/image/Staples/m002304041_sc7?wid=700&hei=700'),
    (100241, 'https://www.staples-3p.com/s7/is/image/Staples/m002304042_sc7?wid=700&hei=700'),
    
    -- dry erase markers
    -- assorted
    (100242, 'https://www.staples-3p.com/s7/is/image/Staples/1B6FF91A-3111-4FC5-993BBF7E44F1E0BE_sc7?wid=700&hei=700'),
    (100242, 'https://www.staples-3p.com/s7/is/image/Staples/sp155560515_sc7?wid=700&hei=700'),
    (100242, 'https://www.staples-3p.com/s7/is/image/Staples/sp155560516_sc7?wid=700&hei=700'),
    -- black
    (100243, 'https://www.staples-3p.com/s7/is/image/Staples/sp161387743_sc7?wid=700&hei=700'),
    (100243, 'https://www.staples-3p.com/s7/is/image/Staples/sp161387838_sc7?wid=700&hei=700'),
    (100243, 'https://www.staples-3p.com/s7/is/image/Staples/sp161387839_sc7?wid=700&hei=700'),
    -- red
    (100244, 'https://www.staples-3p.com/s7/is/image/Staples/sp102580415_sc7?wid=700&hei=700'),
    (100244, 'https://www.staples-3p.com/s7/is/image/Staples/6E4861C8-7E9A-4E8F-9968DE672544E5AA_sc7?wid=700&hei=700'),
    (100244, 'https://www.staples-3p.com/s7/is/image/Staples/sp102580416_sc7?wid=700&hei=700'),
    -- green
    (100245, 'https://www.staples-3p.com/s7/is/image/Staples/sp40888435_sc7?wid=700&hei=700'),
    (100245, 'https://www.staples-3p.com/s7/is/image/Staples/sp40888433_sc7?wid=700&hei=700'),
    (100245, 'https://www.staples-3p.com/s7/is/image/Staples/sp40888432_sc7?wid=700&hei=700'),
    -- blue
    (100246, 'https://www.staples-3p.com/s7/is/image/Staples/s1184756_sc7?wid=700&hei=700'),
    (100246, 'https://www.staples-3p.com/s7/is/image/Staples/614B9DDE-27C9-41AE-89E590D1247EC18B_sc7?wid=700&hei=700'),
    (100246, 'https://www.staples-3p.com/s7/is/image/Staples/sp57451607_sc7?wid=700&hei=700'),
    -- purple
    (100247, 'https://www.staples-3p.com/s7/is/image/Staples/s1192758_sc7?wid=700&hei=700'),
    (100247, 'https://www.staples-3p.com/s7/is/image/Staples/sp49508023_sc7?wid=700&hei=700'),
    
	(100248, '/static_product/images/school_supplies/2095545-A'),
    (100248, '/static_product/images/school_supplies/2095545-B'),
    (100248, '/static_product/images/school_supplies/POST-IT-C'),
    
	(100249, '/static_product/images/school_supplies/77278-A'),
    (100249, '/static_product/images/school_supplies/77278-B'),
    (100249, '/static_product/images/school_supplies/POST-IT-C'),
    
	(100249, '/static_product/images/school_supplies/24534139-A'),
    (100249, '/static_product/images/school_supplies/24534139-B'),
    (100249, '/static_product/images/school_supplies/POST-IT-C'),
    
	(100250, '/static_product/images/school_supplies/77285-A'),
    (100250, '/static_product/images/school_supplies/77285-B'),
    (100250, '/static_product/images/school_supplies/POST-IT-C'),
    
	(100251, '/static_product/images/school_supplies/2398220-A'),
    (100251, '/static_product/images/school_supplies/2398220-B'),
    (100251, '/static_product/images/school_supplies/POST-IT-C'),
    
	(100252, '/static_product/images/school_supplies/586111-A'),
    (100252, '/static_product/images/school_supplies/586111-B'),
    (100252, '/static_product/images/school_supplies/POST-IT-C'),
    
	(100253, '/static_product/images/school_supplies/562930-A'),
    (100253, '/static_product/images/school_supplies/562930-B'),
    (100253, '/static_product/images/school_supplies/POST-IT-C'),
    
	(100254, '/static_product/images/school_supplies/24517481-A'),
    (100254, '/static_product/images/school_supplies/24517481-B'),
    (100254, '/static_product/images/school_supplies/POST-IT-C'),
    
    (100255, '/static_product/images/school_supplies/575671-A'),
    (100255, '/static_product/images/school_supplies/575671-B'),
    
    (100256, '/static_product/images/school_supplies/663660-A'),
    (100256, '/static_product/images/school_supplies/663660-B'),
    
    (100257, '/static_product/images/school_supplies/751540-A'),
    (100257, '/static_product/images/school_supplies/751540-B');