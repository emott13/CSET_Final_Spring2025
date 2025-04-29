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
-- products related tables
CREATE TABLE IF NOT EXISTS categories(					-- product categories for search / filter
	cat_num INT PRIMARY KEY,
    cat_name VARCHAR(255) UNIQUE NOT NULL
);
CREATE TABLE IF NOT EXISTS products (					
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    vendor_id VARCHAR(255) NOT NULL,
    product_title VARCHAR(255) NOT NULL,
    product_description VARCHAR(700),
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
ALTER TABLE colors AUTO_INCREMENT=19780;
ALTER TABLE sizes AUTO_INCREMENT=15;
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
	-- 850555
	('g_pitts@supplies4school.org', 'BIC Xtra-Smooth Mechanical Pencils', 'BIC Xtra-Smooth Mechanical Pencils offer smooth, dark writing with a 0.7mm medium point. Each pencil comes with three pieces of No. 2 lead that doesn’t smudge and erases cleanly, making them ideal for standardized tests.', 0, 11),
	-- 850556
    ('g_pitts@supplies4school.org', 'APEX Spiral Notebook', 'APEX Spiral Notebooks feature 70 wide-ruled sheets, 1 subject, with 3-hole perforated sheets. Available as single notebook or in multi-packs.', 0, 12),
	-- 850557
	('a_batts@textbooksmadeeasy.org', 'Chemistry in Context', '"Applying Chemistry to Society." First edition textbook, new.', 0, 315),
	-- 850558
    ('a_batts@textbooksmadeeasy.org', 'The Language of Composition', '2nd edition textbook. Authors: Renee H. Shea, Lawrence Scanlon, and Robin Dissin Aufses.', 0, 305),
    -- 850559
	('a_batts@textbooksmadeeasy.org', 'Advanced Pysics', '2nd edition textbook. Authors: Steve Adams and Jonathan Allday.', 0, 315),
    -- 850560
    ('a_batts@textbooksmadeeasy.org', 'Precalculus', '"A Graphing Approach. First edition textbook, used. Teacher\'s Edition"', 0, 310),
    -- 850561
    ('i_tombolli@study_space.com', 'Metro Adjustable Height Desk - 60 x 30"', 'Simple-to-use push-button control with 4 programmable heights. Powered by quiet electric motors. 9\' power cord.', 12, 506),
	-- 850562
    ('i_tombolli@study_space.com', 'Metro L-Desk with Adjustable Height - 72 x 78.', 'Simple-to-use push-button control with 4 programmable heights. Powered by 2 quiet electric motors. 9\' power cord.', 12, 506),
	-- 850563
    ('i_tombolli@study_space.com', 'Mesh Task Chair', 'Hi-tech design with ventilated mesh fabric - keeps you cool an comfortable. 3 1/2" thick seat. Standard tilt with adjustable tension. Fixed armrests.', 6, 505),
	-- 850564
    ('i_tombolli@study_space.com', 'Anti-Static Carpet Chair Mat', 'Anti-skid surface and straight edges. Vinyl construction. Cleared backing keeps chair mat firmly in place. Use on low pile carpeting - 3/8" thick or less.', 0, 508),
	-- 850565
    ('i_tombolli@study_space.com', 'Metro Office Desks', 'Strong, sleek design. For ad agencies, design studios, and urban office spaces. Durable 1 1/2" thick laminate top with PVC edges and cable grommets. 30" height. Heavy-duty steel frame with rectangle tube legs and full-length modest panel.', 12, 506),
	-- 850566
    ('i_tombolli@study_space.com', 'Metro Mobile Pedestal File - 2 Drawer', 'Companion storage fits under Metro Office Desks. Durable laminate surface resists scratches, stains and spills. 2 file drawers. 5 swivel casters, 2locking. Includes lock and 2 keys.', 12, 507),
	-- 850567
    ('i_tombolli@study_space.com', 'Metro Mobile Pedestal File - 3 Drawer', 'Companion storage fits under Metro Office Desks. Durable laminate surface resists scratches, stains and spills. 1 file drawer, 2 box drawers. 5 swivel casters, 2locking. Includes lock and 2 keys.', 12, 507),
	-- 850568
	('i_tombolli@study_space.com', 'Designer Office Desks', 'Brighten up your workplace. Minimalist style for modern and trendy offices. 1" thick elevated laminate top with PVC edges and 2 cable grommets. 30" height. Durable white steel frame with beveled legs and hanging modesty panel.', 12, 506),
	-- 850569
	('i_tombolli@study_space.com', 'Designer Office L-Desks', 'Brighten up your workplace. Minimalist style for modern and trendy offices. 1" thick elevated laminate top with PVC edges and 2 cable grommets. 30" height. Durable white steel frame with beveled legs and hanging modesty panel. L-Desk has extra space to get work done. Spread out your projects, reports, or creative materials.', 12, 506),
	-- 850570    
	('i_tombolli@study_space.com', 'Designer Mobile Pedestal File - 3 Drawer', 'Companion storage tucks away neatly and underneath Designer Office Desks. Durable laminate surface resists scratches, stains and spills. 1 file drawer, 2 box drawers. 5 swivel casters, 2 locking. Includes lock and two keys.', 12, 507),
	-- 850571
	('g_pitts@supplies4school.org', 'JanSport Big Student Backpacks', 'The JanSport Big Student backpack is perfect for carrying all of your supplies. The backpack is made of 100% recycled polyester and features a dedicated 15" padded laptop compartment. Features two large main compartments, one front utility pocket with organizer, one pleated front stash pocket, and one zippered front stash pocket. Includes a side water bottle pocket, ergonomic S-curve shoulder straps, and a fully padded back panel.', 0, 14),
	-- 850572
	('g_pitts@supplies4school.org', 'JanSport Big Student Patterned Backpacks', 'The JanSport Big Student backpack is perfect for carrying all of your supplies. The backpack is made of 100% recycled polyester and features a dedicated 15" padded laptop compartment. Features two large main compartments, one front utility pocket with organizer, one pleated front stash pocket, and one zippered front stash pocket. Includes a side water bottle pocket, ergonomic S-curve shoulder straps,  and a fully padded back panel.', 0, 14),
	-- 850573
    ('g_pitts@supplies4school.org', 'Post-It Super Sticky Notes 3" x 3"', "Post-it® Super Sticky Notes are the perfect solution for shopping lists, reminders, to-do lists, color-coding, labeling, family chore reminders, brainstorming, storyboarding, and quick notes. Post-it Super Sticky Notes offer twice the sticking power of basic sticky notes, ensuring they stay put and won't fall off.", 0, 12),
    -- 850574
    ('g_pitts@supplies4school.org', 'Post-It Flags Combo Pack', 'Find it fast with Post-it® Flags in bright eye-catching colors that get noticed. They make it simple to mark or highlight important information in textbooks, calendars, notebooks, planners and more. They stick securely, remove cleanly and come in a wide variety of colors. Draw attention to critical items or use them to index, file or color code your work, either at home, work or in the classroom.', 0, 12),
    -- 850575
    ('g_pitts@supplies4school.org', 'Post-It Durable Tabs', 'Durable Tabs are extra thick and strong to stand up to long-term wear and tear. Great for dividing notes, expanding files and project files. Sticks securely, removes cleanly.', 0, 13),
	-- 850576
    ('f_craft@techtime.com', 'HP OfficeJet Pro Wireless Color All-In-One Printers', "FROM AMERICA'S MOST TRUSTED PRINTER BRAND – The OfficeJet Pro Printers are perfect for offices printing professional-quality color documents like presentations, brochures and flyers. The HP OfficeJet Pro Printers deliver fast color printing. They include wireless and printer security capabilities to keep your multifunction printers up to date and secure. Compatible ink cartridges – works with HP 936 ink cartridges to deliver bold, high quality color. Plus, get 2X more pages with the HP EvoMore 936e high yield ink cartridges, HP's most sustainable ink cartridges.", 12, 409),
    -- 850577
    ('f_craft@techtime.com', 'HP 936 Ink Cartridges', 'Ensure your printing is right the first time and every time with HP 936 Ink Cartridges, which provide precision output so you can take pride in fade-resistant documents and brilliant images. HP 936 cartridges work with: HP OfficeJet 9122e, HP OfficeJet Pro 9110b, 9125e, 9128e, 9130b, 9135e, HP OfficeJet Pro Wide Format 9730e. Cartridges yeild approx 1,250 pages for black ink, or approx. 800 pages with magenta, yellow, or cyan ink.', 0, 409),
	-- 850578
    ('f_craft@techtime.com', 'Canon MegaTank MAXIFY GX Series Printers', "Designed for small- and medium‐size businesses, the Canon MegaTank MAXIFY GX Series Printers balance speedy performance and minimal maintenance. The maintenance cartridges in the MAXIFY GX Series Printers are easily replaceable should the need arise. No service visit calls required. With a four-color pigment ink system, you'll get crisp color and black-and-white documents, along with sharp highlighter-resistant text. Create and print professional posters, banners, and signage with the PosterArtist online version.", 24, 409),
    -- 850579
    ('f_craft@techtime.com', 'Canon 26 High Yield Ink Bottle', 'The Canon ink refill produces superior quality for a wide array of printing needs. Features an easy-to-use no-squeeze bottle design. 132mL capacity. Compatible with: GX3020, GX4020, & GX5020 printers. Prints up to 6000 pages with black ink bottle, up to 14000 with magenta, yellow, or cyan ink bottle.', 0, 409),
    -- 850580
    ('c_simmons@worksmart.com', 'Pilot G2 Retractable 0.7mm Fine Tip Gel Pens', 'Enjoy a smear-free writing experience by using Pilot G2 premium retractable gel roller pens. Improve handwriting, create drawings, and work on other projects worry free. With a convenient clip, these pens attach to binders, notebooks, and pockets, while the contoured grip offers increased support, making it easy to take on lengthy writing tasks. These Pilot G2 gel pens feature a retractable design, so you can tuck the tips away when not in use, preventing unintentional marks on documents.', 0, 11),
    -- 850581
    ('c_simmons@worksmart.com', 'BiC Round Stic Xtra-Life 1.0mm Ballpoint Pen', 'BIC Round Stic Xtra Life Ballpoint Pens are your go-to choice for reliable writing. These ball point pens feature a 1.0mm medium point, making them a great ballpoint pen for everyday use. With a comfortable, flexible round barrel, these medium point pens provide a smooth and controlled writing experience.', 0, 11),
    -- 850582
    ('c_simmons@worksmart.com', 'Paper Mate 0.7mm Flair Felt Pens', 'Make solid strokes in vibrant colors with this 12-pack of Flair medium-point felt pens in assorted Tropical Vacation colors. Add color to your calendar and all your general writing tasks with ease with these Paper Mate medium-point pens in assorted colors. The metal-reinforced felt tip delivers smooth, thick lines using long-lasting, water-based ink that dries quickly to resist smudges. These felt pens feature a plastic construction that matches the ink color and a secure cap with a pocket clip to prevent dry out.', 0, 11),
    -- 850583
    ('c_simmons@worksmart.com', 'Sharpie Permanent Fine Tip Markers', 'Sharpie fine point permanent markers write smoothly on a variety of surfaces. Create a bold, vibrant impression on metal, glass, plastic or cloth with Sharpie permanent markers. The resilient, quick-drying ink is waterproof, smudge-proof and doesn\'t wear, so your text stays clear over time. Fine-point tips make these markers a pleasure to use by ensuring your writing is legible and uniform. An AP nontoxic certification makes these markers perfect for use around coworkers or children.', 0, 11),
    -- 850584
    ('g_pitts@supplies4school.org', 'Expo Dry Erase Starter Set', 'Create eye-catching white board presentations and dry-erase them easily with the Expo dr-erase starter set. Produce colorful whiteboard presentations with the﻿ black, red, green and blue markers in this starter set. The nontoxic markers are made using a low-odor formula and feature a chisel tip for fine or bold markings. The cleaner solution in this Expo dry-erase starter set removes any stubborn markings or smudges from whiteboard surfaces.', 0, 11),
    -- 850585
    ('g_pitts@supplies4school.org', 'Expo Dry Erase Kit', 'This Expo Dry-Erase Kit contains low-odor ink and is everything you\'ll need to give effective and colorful presentations. This low-odor whiteboard kit comes in a durable storage case and offers contemporary designs to fit any decor. This whiteboard marker set includes four fine point markers, eight chisel tip markers, an eraser and an 8 oz. bottle of cleaner.', 0, 11),
    -- 850586
    ('c_simmons@worksmart.com', 'Expo Dry Erase Markers', 'Organize ideas on the boardroom whiteboard with this 12-pack of Expo low-odor chisel tip dry-erase markers. Brainstorm new concepts with your team and these Expo dry-erase markers. The bold pens come in a pack of 12 assorted colors, so it\'s easy to list ideas or notate diagrams clearly and the low odor makes these markers ideal for closed areas such as classrooms and offices. Chisel tips on these quick-drying Expo dry-erase markers let you write with broad, medium and fine lines.', 0, 11),
    -- 850587 https://www.staples.com/pendaflex-double-stuff-3-tab-file-folder-letter-size-manila-50-box-ess54459/product_810520
	('c_simmons@worksmart.com', 'Pendaflex Manila File Folders, 1/3-Cut Tab', 'Handle bulky paperwork with these Pendaflex Double Stuff three-tab standard file folders. Each file expands to hold up to 250 sheets of paper, helping you organize thick stacks of documents without overloading your files. A three-tab arrangement helps keep file titles visible, and each pack contains 50 folders to organize your archives or expand your existing filing system.', 0, 13),
    -- 850588 https://www.staples.com/pendaflex-essentials-file-folders-1-3-cut-tab-letter-size-manila-100-box-752-1-3/product_33760
	('c_simmons@worksmart.com', 'Pendaflex Essentials File Folders', 'Prepare files for customers or organize your office paperwork with these Pendaflex 1/3-cut tab assorted letter-size manila file folders. Eliminate piles of paperwork on your desk with these Pendaflex 1/3-cut tab manila file folders. The assorted position tab keeps each label visible as you sift through file cabinets, while durable 11-point stock offers strength for daily handling. Each of these Pendaflex 1/3-cut tab manila file folders accommodates letter-size sheets, offering a versatile document storage solution for your office.', 0, 13),
    -- 850589 https://www.staples.com/pendaflex-glow-twisted-3-tab-file-folder-letter-size-multicolor-12-pack-40526/product_1075842
    ('c_simmons@worksmart.com', 'Pendaflex Glow Tested Recycled File Folders', 'Expand your file cabinet\'s organization options with this these multicolor file folders; turn the folders inside-out to double your options! Brighten your desktop or filing system beyond standard hues. Top tabs stick out above the level of the papers so you can easily see custom-made labels, this overall system reduces: confusion, optimizes time when retrieving files and makes it easier to locate important records.', 0, 13),
    -- 850590 https://www.staples.com/pendaflex-file-folder-1-tab-letter-size-assorted-100-box-02315/product_24607975
    ('c_simmons@worksmart.com', 'Pendaflex File Folders', 'Pendaflex Two-Tone Color File Folders come in brilliant shades with lighter interiors to prevent time-wasting misfiles. Create bright, color-coded files for fast, efficient filing or reverse them for double the color options. 1/3-Cut tabs in assorted positions. Letter size, assorted colors: magenta, grey, purple, blue, teal. 100 Per box.', 0, 13), 
    -- 850591 https://www.staples.com/storex-portable-file-storage-box-letter-black-stx61502u01c/product_1129608
    ('c_simmons@worksmart.com', 'Storex Portable File Storage Box', 'Storex Portable storage box in black color offers a unique handle design which makes carrying and opening file box easy. Box has an organizer lid that allows for easy access to supplies. Latch lock accepts padlock (not included).', 0, 13),
    -- 850592 https://www.staples.com/advantus-super-stacker-file-box-letter-legal-size-clear-36871/product_486085
    ('c_simmons@worksmart.com', 'Advantus Super Stacker File Box', 'Protect stored files from water, dirt, dings and other damage with this Advantus Super Stacker clear file box. Keep files safe while storing or transporting them with this clear file box. The snap-tight handles hold contents securely inside while making this file box easy to carry, and it can hold letter-sized or legal-sized documents for versatility. This Advantus Super Stacker file box is made with transparent material, so you can see what\'s inside without having to open it.', 0, 13),
    -- 850593 hammerhill copy paper letter
    ('g_pitts@supplies4school.org', 'Hammermill Copy Plus 8.5" x 11" US Letter Copy Paper', 'The Hammermill Copy Plus paper is an economical product that\'s perfect for everyday printing and copying. This versatile paper is great for all types of black and white documents, copies, and printouts. The Hammermill Copy Plus paper is designed to run in all office equipment.', 0, 202),
    -- 850594 hammerhill copy paper legal
    ('g_pitts@supplies4school.org', 'Hammermill Copy Plus 8.5" x 14" Legal Copy Paper', 'The Hammermill Copy Plus paper is an economical product that\'s perfect for everyday printing and copying. This versatile paper is great for all types of black and white documents, copies, and printouts. The Hammermill Copy Plus paper is designed to run in all office equipment.', 0, 202),
    -- 850595 hammerhill copy paper A4
    ('g_pitts@supplies4school.org', 'Hammermill Copy Plus 8.27" x 11.69" A4 Copy Paper', 'The Hammermill Copy Plus paper is an economical product that\'s perfect for everyday printing and copying. This versatile paper is great for all types of black and white documents, copies, and printouts. The Hammermill Copy Plus paper is designed to run in all office equipment.', 0, 202),
    -- 850596
    ('c_simmons@worksmart.com', 'bentogo Modern Lunch Box', 'The Bentgo Modern lunch box gives healthy eating on the go a stylish makeover. Designed to turn heads in the office break room, the versatile three- or four-compartment bento-style lunch box features a contoured outer shell with a sleek matte finish, held tightly closed with a shiny metallic clip. Leak-resistant, the removable tray is microwave- and dishwasher-friendly, making eating and cleanup a breeze. Eating healthy has never looked so good.', 0, 14),
    -- 850597
    ('c_simmons@worksmart.com', 'bentogo Pop Lunch Box', 'Perfect for big kids and teens, the bentgo Pop leakproof lunch box livens up their lunchtime routine with its bright, bold colors, and stylish design. This microwave-safe bento box holds up to 5 cups of food, so it\'s two times bigger than bentgo kids\' lunch box. Your teen can enjoy an entire sandwich or a full entree, plus two sides, in the removable, three-compartment tray. Insert the optional divider to turn your three-compartment meal prep container into a four-compartment food container. The box is stylish, colorful, and leakproof, so they never have to worry about spills in their backpack or bag.', 0, 14),
	-- 850598
    ('g_pitts@supplies4school.org', 'JAM Paper Kraft Lunch Bags', 'Keep up to date with the zero-plastic trend and use these JAM Paper kraft paper small lunch bags. Each of these small bags is ideal for snacks, spices or arts and crafts materials, and they\'re constructed from 100 percent recycled materials and are biodegradable and recyclable. This pack of 25 JAM Paper kraft paper small lunch bags supplies you with meal packaging for a month, or use them in retail environments for an upmarket look.', 0, 14),
    -- 850599 
    ('f_craft@techtime.com', 'HP 25OR G9 15.6" Laptop', 'The HP 250R G9 laptop provides essential business-ready features in a thin and light design that\'s easy to take everywhere you go. The powerful Intel processor, fast memory and storage, and big screen-to-body ratio on a 15.6" display is key for productivity, while the included ports connect your peripherals, all at a price you can value. Features a 1.2GHz Intel Core i3-1315U hexa-core processor, with up to 4.5GHz speed and 10MB L3 cache memory. 512GB SSD Capacity. HP Long Life three-cell, 41Wh Li-ion polymer battery with a runtime of up to 12 hours.', 0, 408),
    -- 850600
    ('f_craft@techtime.com', 'HP 255 G10 15.6" Laptop', 'The HP 255 G10 laptop provides essential business-ready features in a thin and light design that\'s easy to take everywhere you go. The 15.6" diagonal display with 85% screen-to-body ratio, robust AMD Ryzen processor, fast memory, and storage is powered for productivity, while the included ports connect your peripherals, all at a price you can value. Features a 2GHz AMD Ryzen 7 7730U octa-core processor, with up to 4.5GHz and 16MB cache memory. 512GB SSD Capacity. HP Long Life three-cell, 41Wh Li-ion polymer battery with a runtime of up to 12 hours.', 0, 408),
    -- 850601
    ('f_craft@techtime.com', 'HP Elite SFF 600 G9 Desktop Computer', 'The HP Elite 600 SFF Desktop PC delivers uncompromising performance, expandability, and reliability in a space-saving design. Equipped with the latest Intel processor, speedy storage, and memory, this is the right PC for big jobs performed in smaller workspaces. Future proof your fleet with multiple drives and configurable ports that provide expandability. The HP Elite 600 SFF utilizes HP Run Quiet Design that finely tunes the fans to keep systems running quiet and cool. At least 60 percent of all plastic used in this PC is post-consumer recycled plastic. Rest easy with a PC that undergoes hours of HP\'s Total Test Process and MIL-STD 810 testing.', 0, 403),
    -- 850602
    ('f_craft@techtime.com', 'HP Elite Tower 600 G9 Desktop Computer', 'The HP Elite 600 Tower Desktop PC delivers uncompromising performance, expandability, and reliability in a space-saving design. Equipped with the latest Intel processor, speedy storage, and memory, this is the right PC for big jobs performed in smaller workspaces. Future proof your fleet with multiple drives and configurable ports that provide expandability. The HP Elite 600 Tower utilizes HP Run Quiet Design that finely tunes the fans to keep systems running quiet and cool. At least 60 percent of all plastic used in this PC is post-consumer recycled plastic. Rest easy with a PC that undergoes hours of HP\'s Total Test Process and MIL-STD 810 testing.', 0, 403);
    -- 850603
    -- (),
    -- 850604
    -- 850605
    -- 850606
    -- 850607
    -- 850608
INSERT INTO colors (color_name, color_hex)
VALUES
	('Assorted', NULL),			-- 19780
    ('Red', '#ff0000'),			-- 19781
    ('Blue', '#0000ff'),		-- 19782
    ('Green', '#00ff00'),		-- 19783
    ('Yellow', '#ffff00'),		-- 19784
    ('Navy', '#000080'),		-- 19785
    ('Black', '#000000'),		-- 19786
	('Walnut', '#99592e'), 		-- 19787
    ('Clear', NULL),			-- 19788
    ('None', NULL),				-- 19789
	('White', '#ffffff'),		-- 19790
    ('Maple', '#bb9351'), 		-- 19791
	('Lilac', '#c8a2c8'), 		-- 19792
    ('Dark blue', '#06065c'), 	-- 19793
    ('Rose pink', '#f0afc1'), 	-- 19794
    ('Sky blue', '#1a6bb8'), 	-- 19795
    ('Dark red', '#8b0000'), 	-- 19796
    ('Floral pink/purple', NULL), -- 19797
    ('Galaxy blue', NULL), 		-- 19798
    ('Multicolor', NULL), 		-- 19799
    ('Supernova Neons', NULL),	-- 19800
    ('Energy Boost', NULL),		-- 19801
    ('Summer Joy', NULL),		-- 19802
    ('Playful Primaries', NULL),-- 19803
    ('Magenta', '#ff33cc'),		-- 19804
    ('Cyan', '#00bfff'),		-- 19805
    ('Purple', '#800080'),		-- 19806
    ('Silver', '#c0c0c0'),		-- 19807
    ('Manila', '#e7c9a9'),		-- 19808
    ('Orchid', '#e2cfe1'),		-- 19809
    ('Light Green', '#66ffc3'), -- 19810
    ('Pink', '#ff6699'),		-- 19811
    ('Brown', '#b59b7c'); 		-- 19812

INSERT INTO sizes (size_description)
VALUES
	('Single'), 				-- 15
	('6-Pack'), 				-- 16
	('10-Pack'), 				-- 17
    ('12-Pack'), 				-- 18
	('24-Pack'), 				-- 19
	('48-Pack'), 				-- 20
    ('60-Pack'), 				-- 21
    ('60L X 30W Inches'),		-- 22
    ('72L X 78W Inches'),		-- 23
    ('36L X 48W Inches'),		-- 24
    ('45L X 53W Inches'),		-- 25
    ('20W X 19D X 18-22H Inches'), -- 26
    ('Standard'),				-- 27
	('48L X 24W Inches'), 		-- 28
    ('60L X 24W Inches'), 		-- 29
    ('72L X 24W Inches'), 		-- 30
    ('60W x 30L Inches'), 		-- 31
    ('72W X 30L Inches'), 		-- 32
    ('16W X 22D X 28L Inches'), -- 33
	('60W X 66L Inches'), 		-- 34
    ('72W X 66L Inches'), 		-- 35
    ('16W X 18D X 26L Inches'), -- 36
	('13W X 10D X 17.5H Inches'), -- 37
    ('70 Sheet/Pad, 24 Pads/Pack'),-- 38
    ('90 Sheet/Pad, 5 Pads/Pack'),-- 39
    ('320 Flags/Pack'),			-- 40
    ('1"W 66Tabs/Pack'),		-- 41
    ('2"W 24 Tabs/Pack'),		-- 42
    ('9125e: 250 Sheet Input/60 Sheet Output'), -- 43
    ('9135e: 500 Sheet Input/100 Sheet Output'), -- 44
    ('1 Pack/1250 Pages'),		-- 45
    ('1 Pack/800 Pages'),		-- 46
    ('4 Pack/3650 Pages'),		-- 47
    ('GX3020: 250 Sheet Input/100 Sheet Output'), -- 48
    ('GX4020: 250 Sheet Input/100 Sheet Output'), -- 49
    ('GX5020: 350 Sheet Input'), -- 50
    ('132mL capacity'),			-- 51
    ('36-Pack'),				-- 52
    ('50-Pack'),				-- 53
    ('100-Pack'),				-- 54
    ('14.5H X 14W X 11.25D Inches'), -- 55
    ('33.75H X 14.68W X 18.37L Inches'), -- 56
    ('1-Ream 500 Sheets/Ream'),	-- 57
    ('3-Ream 500 Sheets/Ream'), -- 58
    ('5-Ream 500 Sheets/Ream'), -- 59
    ('8-Ream 500 Sheets/Ream'), -- 60
    ('10-Ream 500 Sheets/Ream'),-- 61
    ('2.4H X 9.1W X 7D Inches'),-- 62
    ('2.4H X 9.4W X 7.1D Inches'), -- 63
    ('8H X 4.25W X 2.25D Inches'), -- 64
    ('16GB RAM'); -- 65
    
    
INSERT INTO product_variants (product_id, color_id, size_id, price, current_inventory)
VALUES
	-- Mechanical Pencils
	(850555, 19780, 17, 474, 150),		-- 100200
	(850555, 19780, 20, 2274, 50),		-- 100201
    (850555, 19780, 21, 2649, 18),		-- 100202
	(850556, 19781, 15, 299, 100),		-- 100203
	(850556, 19782, 15, 299, 100),		-- 100204
	(850556, 19783, 15, 299, 100),		-- 100205
	(850556, 19784, 15, 299, 100),		-- 100206
	(850556, 19785, 15, 299, 100),		-- 100207
	(850556, 19786, 15, 299, 100),		-- 100208
	(850556, 19780, 16, 1599, 50),		-- 100209
	(850556, 19780, 18, 2999, 25),		-- 100210
    -- Chem textbook 
    (850557, 19789, 27, 42999, 16), 	-- 100211
    -- Comp textbook 
    (850558, 19789, 27, 34999, 11),		-- 100212
    -- Phys textbook 
    (850559, 19789, 27, 36949, 21),		-- 100213
    -- Precalc textbook 
    (850560, 19789, 27, 39500, 9),		-- 100214
    -- Adjustable height desk 
    (850561, 19787, 22, 95000, 9),		-- 100215
    -- Adjustable height L-shaped desk 
    (850562, 19787, 23, 144900, 7),		-- 100216
    -- Mesh office chair 
    (850563, 19786, 26, 18999, 16),		-- 100217
    -- Anti-static chair mat 
    (850564, 19788, 24, 7999, 25),		-- 100218
    (850564, 19788, 25, 9499, 19),		-- 100219
	(850565, 19787, 28, 44900, 20),		-- 100220
    (850565, 19787, 29, 48900, 20),		-- 100221
    (850565, 19787, 30, 52900, 20),		-- 100222
    (850565, 19787, 31, 53900, 20),		-- 100223
    (850565, 19787, 32, 57900, 15),		-- 100224
    (850566, 19787, 33, 26900, 32),		-- 100225
    (850567, 19787, 33, 27900, 31),		-- 100226
	(850568, 19790, 28, 36900, 15),		-- 100227
    (850568, 19791, 28, 36900, 15),		-- 100228
	(850568, 19790, 29, 41900, 15),    	-- 100229
    (850568, 19791, 29, 41900, 15),    	-- 100230
    (850568, 19790, 22, 45900, 15),    	-- 100231
    (850568, 19791, 22, 45900, 15),    	-- 100232
    (850568, 19790, 32, 48900, 15),    	-- 100233
    (850568, 19791, 32, 48900, 15),    	-- 100234
    (850569, 19790, 34, 64900, 15),    	-- 100235
    (850569, 19791, 34, 64900, 15),    	-- 100236
    (850569, 19790, 35, 72900, 15),    	-- 100237
    (850569, 19791, 35, 72900, 15),    	-- 100238
    (850570, 19790, 36, 25900, 10),    	-- 100239
    (850570, 19791, 36, 25900, 10),    	-- 100240
	(850571, 19792, 37, 5499, 15),		-- 100241
	(850571, 19786, 37, 5499, 20),		-- 100242
	(850571, 19793, 37, 5499, 25),		-- 100243
	(850571, 19794, 37, 5499, 20),    	-- 100244
	(850571, 19795, 37, 5499, 20),		-- 100245
	(850571, 19796, 37, 5499, 15),		-- 100246
	(850572, 19797, 37, 5999, 7),		-- 100247
	(850572, 19798, 37, 5999, 6),		-- 100248
	(850572, 19799, 37, 5999, 12),		-- 100249
    -- postit notes large pack
    (850573, 19800, 38, 2399, 5),		-- 100250
    (850573, 19801, 38, 2399, 5),		-- 100251
    (850573, 19802, 38, 2399, 5),		-- 100252
    (850573, 19803, 38, 2399, 5),		-- 100253
	-- post it notes small pack
    (850573, 19800, 39, 699, 5),		-- 100254
    (850573, 19801, 39, 699, 5),		-- 100255
    (850573, 19802, 39, 699, 5),		-- 100256
    (850573, 19803, 39, 699, 5),		-- 100257
    -- post it flags combo
    (850574, 19780, 40, 1329, 15),		-- 100258
    -- post it tabs
    (850575, 19780, 41, 789, 11),		-- 100259
    (850575, 19780, 42, 429, 8),		-- 100260
    -- hp officejet pro printers
    (850576, 19799, 43, 32999, 15),		-- 100261
    (850576, 19799, 44, 40999, 12), 	-- 100262
    -- hp ink cartridges
    (850577, 19786, 45, 4299, 18),		-- 100263
	(850577, 19804, 46, 2499, 9),		-- 100264
	(850577, 19784, 46, 2499, 9),		-- 100265
	(850577, 19805, 46, 2499, 6),		-- 100266
	(850577, 19780, 47, 10999, 11),		-- 100267
    
    (850578, 19799, 48, 34999, 10),		-- 100268
    (850578, 19799, 49, 44999, 10),		-- 100269
    (850578, 19799, 50, 52999, 10),		-- 100270
    
    (850579, 19786, 51, 2949, 15),		-- 100271
    (850579, 19804, 51, 3629, 20),		-- 100272
    (850579, 19784, 51, 3629, 20),		-- 100273
    (850579, 19805, 51, 3629, 20),		-- 100274
    -- pilot g2 gel pens
	(850580, 19786, 18, 1599, 30),	 	-- 100275 black
    (850580, 19781, 18, 1599, 30), 		-- 100276 red
    (850580, 19783, 18, 1599, 30), 		-- 100277 green
    (850580, 19782, 18, 1599, 30), 		-- 100278 blue
    (850580, 19785, 18, 1599, 30), 		-- 100279 navy blue
    (850580, 19806, 18, 1599, 30), 		-- 100280 purple
    -- bic round ballpoint pens
    (850581, 19786, 21, 879, 25),		-- 100281 black
    (850581, 19782, 21, 879, 25),		-- 100282 blue
    -- paper mate felt pens
    (850582, 19780, 18, 1149, 16),		-- 100283 assorted colors
    -- sharpie permenant markers 
    (850583, 19786, 52, 2599, 12),		-- 100284 black
    (850583, 19781, 52, 2599, 12), 		-- 100285 red
    (850583, 19782, 52, 2599, 12), 		-- 100286 blue
    (850583, 19807, 52, 2599, 12), 		-- 100287 silver
    (850583, 19780, 52, 2599, 12), 		-- 100288 assorted
    (850583, 19780, 19, 1999, 16),		-- 100289 assorted 24 pack
    -- dry erase starter set
    (850584, 19780, 15, 799, 9),		-- 100290
    -- dry erase kit
    (850585, 19780, 15, 1999, 11),		-- 100291
    -- dry erase markers 12-pack
    (850586, 19780, 18, 1379, 10), 		-- 100292 assorted
    (850586, 19786, 18, 1379, 10), 		-- 100293 black 
    (850586, 19781, 18, 1379, 10),		-- 100294 red
    (850586, 19783, 18, 1379, 10), 		-- 100295 green
    (850586, 19782, 18, 1379, 10), 		-- 100296 blue
    (850586, 19806, 18, 1379, 10), 		-- 100297 purple
    -- file folders 850587
    (850587, 19808, 53, 3369, 15),		-- 100298 manila
    (850587, 19780, 53, 3369, 15),		-- 100299 assorted
    -- file folders 850588
    (850588, 19808, 54, 3249, 11),		-- 100300 manila
    -- file folders glow multicolor
    (850589, 19799, 18, 1349, 6),		-- 100301 multicolor
    -- file folders assorted 100pack
    (850590, 19780, 54, 3789, 18),		-- 100302 assorted
    -- file storage box
    (850591, 19786, 55, 3649, 8),		-- 100303 black
    -- file stacker box
    (850592, 19788, 56, 2869, 11),		-- 100304 clear
    
    -- hammermill copy paper --
    -- letter
    (850593, 19790, 57, 1389, 40),		-- 100305
    (850593, 19790, 58, 2929, 30),		-- 100306
    (850593, 19790, 59, 4849, 20),		-- 100307
    (850593, 19790, 60, 7669, 20),		-- 100308
    (850593, 19790, 61, 8999, 10),		-- 100309
    -- legal
    (850594, 19790, 57, 1389, 40),		-- 100310
    (850594, 19790, 61, 8999, 10),		-- 100311
    -- A4
    (850595, 19790, 57, 1389, 40),		-- 100312
    (850595, 19790, 61, 8999, 20),		-- 100313
    
    -- bentogo modern lunch box --
    (850596, 19786, 62, 37.49, 15), 	-- 100314 black
    (850596, 19785, 62, 37.49, 15), 	-- 100315 navy
    (850596, 19809, 62, 37.49, 15),		-- 100316 orchid
    (850596, 19790, 62, 37.49, 15),		-- 100317 white
    
    (850597, 19781, 63, 3249, 15), 		-- 100318 red
    (850597, 19811, 63, 3249, 15),		-- 100319 pink
    (850597, 19810, 63, 3249, 15), 		-- 100320 light green
    (850597, 19795, 63, 3249, 15), 		-- 100321 sky blue
    (850597, 19785, 63, 3249, 15), 		-- 100322 navy
    
    -- jam paper bags --
    (850598, 19812, 64, 15.49, 45), 	-- 100323
    
    -- laptops --
	(850599, 19786, 65, 42999, 12),		-- 100324
    (850600, 19786, 65, 59999, 15),		-- 100325
    -- computer --
    (850601, 19786, 65, 67999, 11),		-- 100326
    (850602, 19786, 65, 67999, 11);		-- 100327

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
INSERT INTO reviews (customer_email, product_id, rating, description, date)
VALUES
	('c_ramos@outlook.com', 850557, 4, 'I ordered this chemistry textbook after transfering to a chem class mid semester. It shipped quickly and the cover had some slight dents in it but otherwise in good condition.', '2025-03-20 11:15:36'),
    ('j_prescott@gmail.com', 850560, 3, 'Got this textbook at a discount. Its Precalculus by Holt. The corner of the cover had some damage which was annoying.', '2025-03-22 13:57:04'),
    ('s_teller@gmail.com', 850555, 5, 'These are my favorite mechanical pencils. Super reliable and smooth, I dont buy any other brand. 100% recommend!', '2025-03-24 10:32:45');
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


INSERT INTO images (variant_id, file_path, alt_text)
VALUES
	-- H-10353
	(100220, '/static_product/images/metro_collection/H-10353-A.png', 'Front View'), 
    (100220, '/static_product/images/metro_collection/H-10353-B.png', 'Back View'), 
    (100220, '/static_product/images/metro_collection/H-10353-C.png', 'Front View With Office Items'), 
    (100220, '/static_product/images/metro_collection/H-10353-D.png', 'Back View With Office Items'), 
    (100220, '/static_product/images/metro_collection/corner-wheel.png', 'Bottom Corner Wheel'), 
    (100220, '/static_product/images/metro_collection/grommet.png', 'Desktop Grommet With Cord'), 
    -- H-9778
    (100221, '/static_product/images/metro_collection/H-9778-A.png', 'Front View'), 
    (100221, '/static_product/images/metro_collection/H-9778-B.png', 'Back View'), 
    (100221, '/static_product/images/metro_collection/H-9778-C.png', 'Front View With Office Items'), 
    (100221, '/static_product/images/metro_collection/H-9778-D.png', 'Back View With Office Items'), 
    (100221, '/static_product/images/metro_collection/corner-wheel.png', 'Bottom Corner Wheel'), 
    (100221, '/static_product/images/metro_collection/grommet.png', 'Desktop Grommet With Cord'), 
    -- H-10355
    (100222, '/static_product/images/metro_collection/H-10355-A.png', 'Front View'), 
    (100222, '/static_product/images/metro_collection/H-10355-B.png', 'Back View'), 
    (100222, '/static_product/images/metro_collection/H-10355-C.png', 'Front View With Office Items'), 
    (100222, '/static_product/images/metro_collection/H-10355-D.png', 'Back View With Office Items'), 
    (100222, '/static_product/images/metro_collection/corner-wheel.png', 'Bottom Corner Wheel'), 
    (100222, '/static_product/images/metro_collection/grommet.png', 'Desktop Grommet With Cord'), 
    -- H-10354
    (100223, '/static_product/images/metro_collection/H-10355-A.png', 'Front View'), 
    (100223, '/static_product/images/metro_collection/H-10355-B.png', 'Back View'), 
    (100223, '/static_product/images/metro_collection/H-10355-C.png', 'Front View With Office Items'), 
    (100223, '/static_product/images/metro_collection/H-10355-D.png', 'Back View With Office Items'), 
    (100223, '/static_product/images/metro_collection/corner-wheel.png', 'Bottom Corner Wheel'), 
    (100223, '/static_product/images/metro_collection/grommet.png', 'Desktop Grommet With Cord'), 
    -- H-9779
    (100224, '/static_product/images/metro_collection/H-10355-A.png', 'Front View'), 
    (100224, '/static_product/images/metro_collection/H-10355-B.png', 'Back View'), 
    (100224, '/static_product/images/metro_collection/H-10355-C.png', 'Front View With Office Items'), 
    (100224, '/static_product/images/metro_collection/H-10355-D.png', 'Back View With Office Items'), 
    (100224, '/static_product/images/metro_collection/corner-wheel.png', 'Bottom Corner Wheel'), 
    (100224, '/static_product/images/metro_collection/grommet.png', 'Desktop Grommet With Cord'), 
    -- H-9784
    (100225, '/static_product/images/metro_collection/H-9784-A.png', 'Front View'), 
    (100225, '/static_product/images/metro_collection/H-9784-B.png', 'File Drawer Open'), 
    (100225, '/static_product/images/metro_collection/laminate-edge.png', 'Laminate Corner'), 
    (100225, '/static_product/images/metro_collection/lock-keys.png', 'Front - keys in keyhole'), 
    -- H-9785
    (100226, '/static_product/images/metro_collection/H-9784-A.png', 'Front View'),
    (100226, '/static_product/images/metro_collection/H-9784-B.png', 'File Drawer Open'),
    (100226, '/static_product/images/metro_collection/H-9784-C.png', 'Box Drawer Open'),
    (100226, '/static_product/images/metro_collection/laminate-edge.png', 'Laminate Corner'),
    (100226, '/static_product/images/metro_collection/lock-keys.png', 'Front - keys in keyhole'),
    
	(100227, '/static_product/images/designer_collection/H-9790-WHITE-A.png', 'Front View'),
    (100227, '/static_product/images/designer_collection/H-9790-WHITE-B.png', 'Back View'),
    (100227, '/static_product/images/designer_collection/H-9790-WHITE-C.png', 'Front View - Office Items'),
    (100227, '/static_product/images/designer_collection/H-9790-WHITE-D.png', 'Back View -- Office Items'),
	(100227, '/static_product/images/designer_collection/grommet-white.png', 'Desktop Grommet with Cord'),
    (100227, '/static_product/images/designer_collection/laminate-corner-white.png', 'Laminate Corner'),
    
    (100228, '/static_product/images/designer_collection/H-9790-MAPLE-A.png', 'Front View'),
    (100228, '/static_product/images/designer_collection/H-9790-MAPLE-B.png', 'Back View'),
    (100228, '/static_product/images/designer_collection/H-9790-MAPLE-C.png', 'Front View - Office Items'),
    (100228, '/static_product/images/designer_collection/H-9790-MAPLE-D.png', 'Back View -- Office Items'),
    (100228, '/static_product/images/designer_collection/grommet-maple.png', 'Desktop Grommet with Cord'),
    (100228, '/static_product/images/designer_collection/laminate-corner-maple.png', 'Laminate Corner'),
    
    (100229, '/static_product/images/designer_collection/H-10260-WHITE-A.png', 'Front View'),
    (100229, '/static_product/images/designer_collection/H-10260-WHITE-B.png', 'Back View'),
    (100229, '/static_product/images/designer_collection/H-10260-WHITE-C.png', 'Front View - Office Items'),
    (100229, '/static_product/images/designer_collection/H-10260-WHITE-D.png', 'Back View -- Office Items'),
    (100229, '/static_product/images/designer_collection/grommet-white.png', 'Desktop Grommet with Cord'),
    (100229, '/static_product/images/designer_collection/laminate-corner-white.png', 'Laminate Corner'),
    
    (100230, '/static_product/images/designer_collection/H-10260-MAPLE-A.png', 'Front View'),
    (100230, '/static_product/images/designer_collection/H-10260-MAPLE-B.png', 'Back View'),
    (100230, '/static_product/images/designer_collection/H-10260-MAPLE-C.png', 'Front View - Office Items'),
    (100230, '/static_product/images/designer_collection/H-10260-MAPLE-D.png', 'Back View -- Office Items'),
    (100230, '/static_product/images/designer_collection/grommet-maple.png', 'Desktop Grommet with Cord'),
    (100230, '/static_product/images/designer_collection/laminate-corner-maple.png', 'Laminate Corner'),
    
    (100231, '/static_product/images/designer_collection/H-10260-WHITE-A.png', 'Front View'),
    (100231, '/static_product/images/designer_collection/H-10260-WHITE-B.png', 'Back View'),
    (100231, '/static_product/images/designer_collection/H-10260-WHITE-C.png', 'Front View - Office Items'),
    (100231, '/static_product/images/designer_collection/H-10260-WHITE-D.png', 'Back View -- Office Items'),
    (100231, '/static_product/images/designer_collection/grommet-white.png', 'Desktop Grommet with Cord'),
    (100231, '/static_product/images/designer_collection/laminate-corner-white.png', 'Laminate Corner'),
    
    (100232, '/static_product/images/designer_collection/H-10260-MAPLE-A.png', 'Front View'),
    (100232, '/static_product/images/designer_collection/H-10260-MAPLE-B.png', 'Back View'),
    (100232, '/static_product/images/designer_collection/H-10260-MAPLE-C.png', 'Front View - Office Items'),
    (100232, '/static_product/images/designer_collection/H-10260-MAPLE-D.png', 'Back View -- Office Items'),
    (100232, '/static_product/images/designer_collectiongrommet-maple.png', 'Desktop Grommet with Cord'),
    (100232, '/static_product/images/designer_collection/laminate-corner-maple.png', 'Laminate Corner'),
    
    (100233, '/static_product/images/designer_collection/H-10261-WHITE-A.png', 'Front View'),
    (100233, '/static_product/images/designer_collection/H-10261-WHITE-B.png', 'Back View'),
    (100233, '/static_product/images/designer_collection/H-10261-WHITE-C.png', 'Front View - Office Items'),
    (100233, '/static_product/images/designer_collection/H-10261-WHITE-D.png', 'Back View -- Office Items'),
    (100233, '/static_product/images/designer_collection/grommet-white.png', 'Desktop Grommet with Cord'),
    (100233, '/static_product/images/designer_collection/laminate-corner-white.png', 'Laminate Corner'),
    
    (100234, '/static_product/images/designer_collection/H-10261-MAPLE-A.png', 'Front View'),
    (100234, '/static_product/images/designer_collection/H-10261-MAPLE-B.png', 'Back View'),
    (100234, '/static_product/images/designer_collection/H-10261-MAPLE-C.png', 'Front View - Office Items'),
    (100234, '/static_product/images/designer_collection/H-10261-MAPLE-D.png', 'Back View -- Office Items'),
    (100234, '/static_product/images/designer_collection/grommet-maple.png', 'Desktop Grommet with Cord'),
    (100234, '/static_product/images/designer_collection/laminate-corner-maple.png', 'Back View -- Office Items'),
    
    (100235, '/static_product/images/designer_collection/H-9800-WHITE-A.png', 'Front View'),
    (100235, '/static_product/images/designer_collection/H-9800-WHITE-B.png', 'Back View'),
    (100235, '/static_product/images/designer_collection/H-9800-WHITE-C.png', 'Front View - Office Items'),
    (100235, '/static_product/images/designer_collection/H-9800-WHITE-D.png', 'Back View -- Office Items'),
    (100235, '/static_product/images/designer_collection/laminate-corner-white.png', 'Laminate Corner'),
    (100235, '/static_product/images/designer_collection/grommet-white.png', 'Desktop Grommet with Cord'),
    
    (100236, '/static_product/images/designer_collection/H-9800-MAPLE-A.png', 'Front View'),
    (100236, '/static_product/images/designer_collection/H-9800-MAPLE-B.png', 'Back View'),
    (100236, '/static_product/images/designer_collection/H-9800-MAPLE-C.png', 'Front View - Office Items'),
    (100236, '/static_product/images/designer_collection/H-9800-MAPLE-D.png', 'Back View -- Office Items'),
    (100236, '/static_product/images/designer_collection/laminate-corner-maple.png', 'Laminate Corner'),
    (100236, '/static_product/images/designer_collection/grommet-maple.png', 'Desktop Grommet with Cord'),
    
--     (100237, '/static_product/images/designer_collection/H-10262-WHITE-', 'Front View'),
--     (100237, '/static_product/images/designer_collection/H-10262-WHITE-', 'Back View'),
--     (100237, '/static_product/images/designer_collection/H-10262-WHITE-', 'Front View - Office Items'),
--     (100237, '/static_product/images/designer_collection/H-10262-WHITE-', 'Back View -- Office Items'),
--     
--     (100238, '/static_product/images/designer_collection/H-10262-MAPLE-', 'Front View'),
--     (100238, '/static_product/images/designer_collection/H-10262-MAPLE-', 'Back View'),
--     (100238, '/static_product/images/designer_collection/H-10262-MAPLE-', 'Front View - Office Items'),
--     (100238, '/static_product/images/designer_collection/H-10262-MAPLE-', 'Back View -- Office Items'),
    
    (100239, '/static_product/images/designer_collection/H-9806-WHITE-A.png', 'Front View'),
    (100239, '/static_product/images/designer_collection/H-9806-WHITE-B.png', 'File Drawer Open'),
    (100239, '/static_product/images/designer_collection/H-9806-WHITE-C.png', 'Block Drawer Open'),
    (100239, '/static_product/images/designer_collection/lock-keys-white.png', 'Front - keys in keyhole'),
    (100239, '/static_product/images/designer_collection/pedestal-wheel-white.png', 'Front Corner - Wheel'),
    
    (100240, '/static_product/images/designer_collection/H-9806-MAPLE-A.png', 'Front View'),
    (100240, '/static_product/images/designer_collection/H-9806-MAPLE-B.png', 'File Drawer Open'),
    (100240, '/static_product/images/designer_collection/H-9806-MAPLE-C.png', 'Block Drawer Open'),
    (100240, '/static_product/images/designer_collection/lock-keys-maple.png', 'Front - keys in keyhole'),
    (100240, '/static_product/images/designer_collection/pedestal-wheel-maple.png', 'Front Corner - Wheel'),
	-- 100241
	(100241, '/static_product/images/school_supplies/backpacks/JS0A47JK5M9-A', ''),
    (100241, '/static_product/images/school_supplies/backpacks/JS0A47JK5M9-B', ''),
    (100241, '/static_product/images/school_supplies/backpacks/JS0A47JK5M9-C', ''),
    
    (100242, '/static_product/images/school_supplies/backpacks/TDN7008JAN-A', ''),
    (100242, '/static_product/images/school_supplies/backpacks/TDN7008JAN-B', ''),
    (100242, '/static_product/images/school_supplies/backpacks/TDN7008JAN-C', ''),
    
    (100243, '/static_product/images/school_supplies/backpacks/JS00TDN7003-A', ''),
    
    (100244, '/static_product/images/school_supplies/backpacks/JS0A47JK7N8-A', ''),
    (100244, '/static_product/images/school_supplies/backpacks/JS0A47JK7N8-B', ''),
    (100244, '/static_product/images/school_supplies/backpacks/JS0A47JK7N8-C', ''),
    
    (100245, '/static_product/images/school_supplies/backpacks/JS0A47JKZ70-A', ''),
    (100245, '/static_product/images/school_supplies/backpacks/JS0A47JKZ70-B', ''),
    
    (100246, '/static_product/images/school_supplies/backpacks/JS0A47JK04S-A', ''),
    (100246, '/static_product/images/school_supplies/backpacks/JS0A47JK04S-B', ''),
    (100246, '/static_product/images/school_supplies/backpacks/JS0A47JK04S-C', ''),
    
    (100247, '/static_product/images/school_supplies/backpacks/JS0A47JKAO5-A', ''),
    (100247, '/static_product/images/school_supplies/backpacks/JS0A47JKAO5-B', ''),
    
    (100248, '/static_product/images/school_supplies/backpacks/JS0A47JKAO3-A', ''),
    (100248, '/static_product/images/school_supplies/backpacks/JS0A47JKAO3-B', ''),
    
    (100249, '/static_product/images/school_supplies/backpacks/JS0A47JKZ47-A', ''),
    (100249, '/static_product/images/school_supplies/backpacks/JS0A47JKZ47-B', ''),
    (100249, '/static_product/images/school_supplies/backpacks/JS0A47JKZ47-C', ''),
    
    (100250, '/static_product/images/school_supplies/2095545-A', ''),
    (100250, '/static_product/images/school_supplies/2095545-B', ''),
    (100250, '/static_product/images/school_supplies/POST-IT-C', ''),
    
	(100251, '/static_product/images/school_supplies/77278-A', ''),
    (100251, '/static_product/images/school_supplies/77278-B', ''),
    (100251, '/static_product/images/school_supplies/POST-IT-C', ''),
    
	(100252, '/static_product/images/school_supplies/24534139-A', ''),
    (100252, '/static_product/images/school_supplies/24534139-B', ''),
    (100252, '/static_product/images/school_supplies/POST-IT-C', ''),
    
	(100253, '/static_product/images/school_supplies/77285-A', ''),
    (100253, '/static_product/images/school_supplies/77285-B', ''),
    (100253, '/static_product/images/school_supplies/POST-IT-C', ''),
    
	(100254, '/static_product/images/school_supplies/2398220-A', ''),
    (100254, '/static_product/images/school_supplies/2398220-B', ''),
    (100254, '/static_product/images/school_supplies/POST-IT-C', ''),
    
	(100255, '/static_product/images/school_supplies/586111-A', ''),
    (100255, '/static_product/images/school_supplies/586111-B', ''),
    (100255, '/static_product/images/school_supplies/POST-IT-C', ''),
    
	(100256, '/static_product/images/school_supplies/562930-A', ''),
    (100256, '/static_product/images/school_supplies/562930-B', ''),
    (100256, '/static_product/images/school_supplies/POST-IT-C', ''),
    
	(100257, '/static_product/images/school_supplies/24517481-A', ''),
    (100257, '/static_product/images/school_supplies/24517481-B', ''),
    (100257, '/static_product/images/school_supplies/POST-IT-C', ''),
    
    (100258, '/static_product/images/school_supplies/575671-A', ''),
    (100258, '/static_product/images/school_supplies/575671-B', ''),
    
    (100259, '/static_product/images/school_supplies/663660-A', ''),
    (100259, '/static_product/images/school_supplies/663660-B', ''),
    
    (100260, '/static_product/images/school_supplies/751540-A', ''),
    (100260, '/static_product/images/school_supplies/751540-B', ''),
    
    (100261, '/static_product/images/school_supplies/24583386-A', ''),
    (100261, '/static_product/images/school_supplies/24583386-B', ''),
    
    (100262, '/static_product/images/school_supplies/24583387-A', ''),
    (100262, '/static_product/images/school_supplies/24583387-B', ''),
    
    (100263, '/static_product/images/technology/100263-A.png', ''), -- 850577
    (100263, '/static_product/images/technology/100263-B.png', ''),
    
    (100264, '/static_product/images/technology/100264-A.png', ''),
    (100264, '/static_product/images/technology/100264-B.png', ''),
    
    (100265, '/static_product/images/technology/100265-A.png', ''),
    (100265, '/static_product/images/technology/100265-B.png', ''),
    
	(100266, '/static_product/images/technology/100266-A.png', ''),
    (100266, '/static_product/images/technology/100266-B.png', ''),
    
    (100267, '/static_product/images/technology/100267-A.png', ''),
    (100267, '/static_product/images/technology/100267-B.png', ''),
    -- canon printers
    (100268, 'https://i.ebayimg.com/images/g/yE0AAOSwN9Nm9eRW/s-l400.jpg', ''),
    (100268, 'https://crdms.images.consumerreports.org/f_auto,w_600/prod/products/cr/models/408882-all-in-one-tank-inkjet-printers-canon-megatank-maxify-gx3020-10036450.png', ''),
    
    (100269, 'https://media.officedepot.com/images/f_auto,q_auto,e_sharpen,h_450/products/8426203/8426203_o51_canon_maxify_gx4020_wireless_megatank_small_office_all_in_one_color_printer/8426203', ''),
    (100269, 'https://s7d1.scene7.com/is/image/canon/5779C002_GX4020_2?wid=800', ''),
    
    (100270, 'https://m.media-amazon.com/images/I/71gFWh3WhlL.jpg', ''),
    (100270, 'https://webobjects2.cdw.com/is/image/CDW/7323310?$product-main$', ''),
    
    -- canon ink bottles
    (100271, 'https://content.oppictures.com/Master_Images/Master_Variants/Variant_240/719466.JPG', ''),
    (100271, 'https://www.staples-3p.com/s7/is/image/Staples/sp131230822_sc7?wid=700&hei=700', ''),
    (100271, 'https://www.staples-3p.com/s7/is/image/Staples/sp131230823_sc7?wid=700&hei=700', ''),
    
    (100272, 'https://www.staples-3p.com/s7/is/image/Staples/sp172009163_sc7?wid=700&hei=700', ''),
    (100272, 'https://www.staples-3p.com/s7/is/image/Staples/sp131230828_sc7?wid=700&hei=700', ''),
    (100272, 'https://www.staples-3p.com/s7/is/image/Staples/sp131230829_sc7?wid=700&hei=700', ''),
    
    (100273, 'https://www.staples-3p.com/s7/is/image/Staples/sp172008526_sc7?wid=700&hei=700', ''),
    (100273, 'https://www.staples-3p.com/s7/is/image/Staples/sp131230824_sc7?wid=700&hei=700', ''),
    (100273, 'https://www.staples-3p.com/s7/is/image/Staples/sp131230825_sc7?wid=700&hei=700', ''),
    
    (100274, 'https://www.compandsave.com/media/catalog/product/cache/e4401aba6d3f9e552234272afd624a20/c/a/canon-gi-26-cyan-ink-bottle.JPG', ''),
    (100274, 'https://www.staples-3p.com/s7/is/image/Staples/sp131230826_sc7?wid=700&hei=700', ''),
    (100274, 'https://www.staples-3p.com/s7/is/image/Staples/sp131230827_sc7?wid=700&hei=700', ''),
    
    -- pilot g2 gel pens --
	-- black
    (100275, 'https://www.staples-3p.com/s7/is/image/Staples/sp130855922_sc7?wid=700&hei=700', ''),
    (100275, 'https://www.staples-3p.com/s7/is/image/Staples/sp40286010_sc7?wid=700&hei=700', ''),
    (100275, 'https://www.staples-3p.com/s7/is/image/Staples/sp130855909_sc7?wid=700&hei=700', ''),
    -- red
    (100276, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856306_sc7?wid=700&hei=700', ''),
    (100276, 'https://www.staples-3p.com/s7/is/image/Staples/sp130855924_sc7?wid=700&hei=700', ''),
    (100276, 'https://www.staples-3p.com/s7/is/image/Staples/sp130855909_sc7?wid=700&hei=700', ''),
    -- green
    (100277, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856294_sc7?wid=700&hei=700', ''),
    (100277, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856295_sc7?wid=700&hei=700', ''),
    (100277, 'https://www.staples-3p.com/s7/is/image/Staples/sp130855909_sc7?wid=700&hei=700', ''),
	-- blue	
    (100278, 'https://www.staples-3p.com/s7/is/image/Staples/sp138382946_sc7?wid=700&hei=700', ''),
    (100278, 'https://www.staples-3p.com/s7/is/image/Staples/sp41817060_sc7?wid=700&hei=700', ''),
    (100278, 'https://www.staples-3p.com/s7/is/image/Staples/sp130855909_sc7?wid=700&hei=700', ''),
    -- navy
    (100279, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856301_sc7?wid=700&hei=700', ''),
    (100279, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856302_sc7?wid=700&hei=700', ''),
    (100279, 'https://www.staples-3p.com/s7/is/image/Staples/sp130855909_sc7?wid=700&hei=700', ''),
    -- purple
    (100280, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856303_sc7?wid=700&hei=700', ''),
    (100280, 'https://www.staples-3p.com/s7/is/image/Staples/sp130856304_sc7?wid=700&hei=700', ''),
    (100280, 'https://www.staples-3p.com/s7/is/image/Staples/sp130855909_sc7?wid=700&hei=700', ''),
    -- bic round ballpoint pens 60 pack --
    -- black
    (100281, 'https://www.staples-3p.com/s7/is/image/Staples/AFD5FBB8-71A3-434C-989B74986834C3E5_sc7?wid=700&hei=700', ''),
    (100281, 'https://www.staples-3p.com/s7/is/image/Staples/281C65AA-E03C-4165-BE0335374B5300D6_sc7?wid=700&hei=700', ''),
    -- blue
    (100282, 'https://www.staples-3p.com/s7/is/image/Staples/8FF19026-7FC9-49C6-945FC921B193E318_sc7?wid=700&hei=700', ''),
    (100282, 'https://www.staples-3p.com/s7/is/image/Staples/0E907B5E-E49E-41E3-94C9770B386C4F22_sc7?wid=700&hei=700', ''),
    -- paper mate felt pens --
    (100283, 'https://www.staples-3p.com/s7/is/image/Staples/98C1DFBD-AFCE-488D-B080922050338AA7_sc7?wid=700&hei=700', ''),
    (100283, 'https://www.staples-3p.com/s7/is/image/Staples/sp161466748_sc7?wid=700&hei=700', ''),
    (100283, 'https://www.staples-3p.com/s7/is/image/Staples/sp161466749_sc7?wid=700&hei=700', ''),
    -- sharpie permenant markers --
    -- black
    (100284, 'https://www.staples-3p.com/s7/is/image/Staples/D67EC31B-0DB3-45F9-BD62DC872D1ACBF1_sc7?wid=700&hei=700', ''),
    (100284, 'https://www.staples-3p.com/s7/is/image/Staples/1BCDF1C0-5454-4A4A-A616BD9601C8C140_sc7?wid=700&hei=700', ''),
    (100284, 'https://www.staples-3p.com/s7/is/image/Staples/DD9A5C21-9C21-4A0E-B3B6C1149A3D0399_sc7?wid=700&hei=700', ''),
    -- red
    (100285, 'https://www.staples-3p.com/s7/is/image/Staples/5CA98F6D-8D11-4886-B08C0CC322E38815_sc7?wid=700&hei=700', ''),
    (100285, 'https://www.staples-3p.com/s7/is/image/Staples/sp89168542_sc7?wid=700&hei=700', ''),
    (100285, 'https://www.staples-3p.com/s7/is/image/Staples/s0922441_sc7?wid=700&hei=700', ''),
    -- blue
    (100286, 'https://www.staples-3p.com/s7/is/image/Staples/1C929E3D-8BCF-48E2-A00933FB4AAD3B2D_sc7?wid=700&hei=700', ''),
    (100286, 'https://www.staples-3p.com/s7/is/image/Staples/s0933668_sc7?wid=700&hei=700', ''),
    (100286, 'https://www.staples-3p.com/s7/is/image/Staples/s0922442_sc7?wid=700&hei=700', ''),
    -- silver
    (100287, 'https://www.staples-3p.com/s7/is/image/Staples/m007068285_sc7?wid=700&hei=700', ''),
    (100287, 'https://www.staples-3p.com/s7/is/image/Staples/m007068281_sc7?wid=700&hei=700', ''),
    (100287, 'https://www.staples-3p.com/s7/is/image/Staples/m007068283_sc7?wid=700&hei=700', ''),
    -- assorted
    (100288, 'https://www.staples-3p.com/s7/is/image/Staples/s1189983_sc7?wid=700&hei=700', ''),
    (100288, 'https://www.staples-3p.com/s7/is/image/Staples/m002908378_sc7?wid=700&hei=700', ''),
    -- assorted 24 pack
    (100289, 'https://www.staples-3p.com/s7/is/image/Staples/D5E6B1CA-30FC-4219-9BD4322085DCA998_sc7?wid=700&hei=700', ''),
    (100289, 'https://www.staples-3p.com/s7/is/image/Staples/sp44335828_sc7?wid=700&hei=700', ''),
    (100289, 'https://www.staples-3p.com/s7/is/image/Staples/sp44335829_sc7?wid=700&hei=700', ''),
    -- dry erase starter set
    (100290, 'https://www.staples-3p.com/s7/is/image/Staples/E1755194-7001-4CE3-93598F83B0079751_sc7?wid=700&hei=700', ''),
    (100290, 'https://www.staples-3p.com/s7/is/image/Staples/sp40798560_sc7?wid=700&hei=700', ''),
    (100290, 'https://www.staples-3p.com/s7/is/image/Staples/sp40798562_sc7?wid=700&hei=700', ''),
    (100290, 'https://www.staples-3p.com/s7/is/image/Staples/sp40798565_sc7?wid=700&hei=700', ''),
    -- dry erase kit
    (100291, 'https://www.staples-3p.com/s7/is/image/Staples/m002304039_sc7?wid=700&hei=700', ''),
    (100291, 'https://www.staples-3p.com/s7/is/image/Staples/m002304040_sc7?wid=700&hei=700https://www.staples-3p.com/s7/is/image/Staples/m002304040_sc7?wid=700&hei=700', ''),
    (100291, 'https://www.staples-3p.com/s7/is/image/Staples/m002304041_sc7?wid=700&hei=700', ''),
    (100291, 'https://www.staples-3p.com/s7/is/image/Staples/m002304042_sc7?wid=700&hei=700', ''),
    -- dry erase markers
    -- assorted
    (100292, 'https://www.staples-3p.com/s7/is/image/Staples/1B6FF91A-3111-4FC5-993BBF7E44F1E0BE_sc7?wid=700&hei=700', ''),
    (100292, 'https://www.staples-3p.com/s7/is/image/Staples/sp155560515_sc7?wid=700&hei=700', ''),
    (100292, 'https://www.staples-3p.com/s7/is/image/Staples/sp155560516_sc7?wid=700&hei=700', ''),
    -- black
    (100293, 'https://www.staples-3p.com/s7/is/image/Staples/sp161387743_sc7?wid=700&hei=700', ''),
    (100293, 'https://www.staples-3p.com/s7/is/image/Staples/sp161387838_sc7?wid=700&hei=700', ''),
    (100293, 'https://www.staples-3p.com/s7/is/image/Staples/sp161387839_sc7?wid=700&hei=700', ''),
    -- red
    (100294, 'https://www.staples-3p.com/s7/is/image/Staples/sp102580415_sc7?wid=700&hei=700', ''),
    (100294, 'https://www.staples-3p.com/s7/is/image/Staples/6E4861C8-7E9A-4E8F-9968DE672544E5AA_sc7?wid=700&hei=700', ''),
    (100294, 'https://www.staples-3p.com/s7/is/image/Staples/sp102580416_sc7?wid=700&hei=700', ''),
    -- green
    (100295, 'https://www.staples-3p.com/s7/is/image/Staples/sp40888435_sc7?wid=700&hei=700', ''),
    (100295, 'https://www.staples-3p.com/s7/is/image/Staples/sp40888433_sc7?wid=700&hei=700', ''),
    (100295, 'https://www.staples-3p.com/s7/is/image/Staples/sp40888432_sc7?wid=700&hei=700', ''),
    -- blue
    (100296, 'https://www.staples-3p.com/s7/is/image/Staples/s1184756_sc7?wid=700&hei=700', ''),
    (100296, 'https://www.staples-3p.com/s7/is/image/Staples/614B9DDE-27C9-41AE-89E590D1247EC18B_sc7?wid=700&hei=700', ''),
    (100296, 'https://www.staples-3p.com/s7/is/image/Staples/sp57451607_sc7?wid=700&hei=700', ''),
    -- purple
    (100297, 'https://www.staples-3p.com/s7/is/image/Staples/s1192758_sc7?wid=700&hei=700', ''),
    (100297, 'https://www.staples-3p.com/s7/is/image/Staples/sp49508023_sc7?wid=700&hei=700', ''),
    -- manila folders
    -- manila
    (100298, 'https://www.staples-3p.com/s7/is/image/Staples/m005168086_sc7?wid=700&hei=700', ''),
    (100298, 'https://www.staples-3p.com/s7/is/image/Staples/m005168088_sc7?wid=700&hei=700', ''),
    -- assorted
    (100299, 'https://www.staples-3p.com/s7/is/image/Staples/m005168092_sc7?wid=700&hei=700', ''),
    (100299, 'https://www.staples-3p.com/s7/is/image/Staples/m005168094_sc7?wid=700&hei=700', ''),
    -- manila folders 100pack
    (100300, 'https://www.staples-3p.com/s7/is/image/Staples/D78FD954-11CF-41A0-A71BBCB7CCD8766E_sc7?wid=700&hei=700', ''),
    (100300, 'https://www.staples-3p.com/s7/is/image/Staples/D11D58C3-46E6-43A7-9C047BE614DFC4D7_sc7?wid=700&hei=700', ''),
    -- glow recycled folders
    (100301, 'https://www.staples-3p.com/s7/is/image/Staples/A692FDEC-9287-4F04-82D5EB5EAB02A116_sc7?wid=700&hei=700', ''),
    (100301, 'https://www.staples-3p.com/s7/is/image/Staples/m005168164_sc7?wid=700&hei=700', ''),
    (100301, 'https://www.staples-3p.com/s7/is/image/Staples/m005168165_sc7?wid=700&hei=700', ''),
    -- two toned file folders
    (100302, 'https://www.staples-3p.com/s7/is/image/Staples/C1E78604-C620-441E-A279141C22632D96_sc7?wid=700&hei=700', ''),
    (100302, 'https://www.staples-3p.com/s7/is/image/Staples/32EF3FA8-228A-4D80-A9D50D37769E6E94_sc7?wid=700&hei=700', ''),
    (100302, 'https://www.staples-3p.com/s7/is/image/Staples/358543D3-5044-4F4E-B0844D7B6F1B81A6_sc7?wid=700&hei=700', ''),
    -- storage lock box
    (100303, 'https://www.staples-3p.com/s7/is/image/Staples/s1149303_sc7?wid=700&hei=700', ''),
    (100303, 'https://www.staples-3p.com/s7/is/image/Staples/s1149302_sc7?wid=700&hei=700', ''),
    (100303, 'https://www.staples-3p.com/s7/is/image/Staples/s1149299_sc7?wid=700&hei=700', ''),
    -- storage bin
    (100304, 'https://www.staples-3p.com/s7/is/image/Staples/0CE12CD8-6132-4072-B0831D74D6DFA3FA_sc7?wid=700&hei=700', ''),
    (100304, 'https://www.staples-3p.com/s7/is/image/Staples/sp39611891_sc7?wid=700&hei=700', ''),
    (100304, 'https://www.staples-3p.com/s7/is/image/Staples/sp39611893_sc7?wid=700&hei=700', ''),
    -- 100319
    (100305, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072084_sc7?wid=700&hei=700', ''),
    (100305, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700', ''),
    
    (100306, 'https://www.staples-3p.com/s7/is/image/Staples/DC2712FE-A922-4E5F-B9B9CF5677D6BE83_sc7?wid=700&hei=700', ''),
    (100306, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700', ''),
    
    (100307, 'https://www.staples-3p.com/s7/is/image/Staples/A2C4AC65-2CB3-4263-BB0C166AE240F3D8_sc7?wid=700&hei=700', ''),
    (100307, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700', ''),
    
    (100308, 'https://www.staples-3p.com/s7/is/image/Staples/sp167250067_sc7?wid=700&hei=700', ''),
    (100308, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700', ''),
    
    (100309, 'https://www.staples-3p.com/s7/is/image/Staples/95CBC599-9581-4384-AB7E87134750EEBE_sc7?wid=700&hei=700', ''),
    (100309, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700', ''),
    
    (100310, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072261_sc7?wid=700&hei=700', ''),
    (100310, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700', ''),
    
    (100311, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072238_sc7?wid=700&hei=700', ''),
    (100311, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700', ''),
    
    (100312, 'https://www.staples-3p.com/s7/is/image/Staples/sp167250076_sc7?wid=700&hei=700', ''),
    (100312, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700', ''),
    
    (100313, 'https://www.staples-3p.com/s7/is/image/Staples/95CBC599-9581-4384-AB7E87134750EEBE_sc7?wid=700&hei=700', ''),
    (100313, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700', ''),
    
	(100314, 'https://www.staples-3p.com/s7/is/image/Staples/0D3524FF-2832-47D7-A2AACA09B78251AF_sc7?wid=700&hei=700', ''),
    (100314, 'https://www.staples-3p.com/s7/is/image/Staples/D7428E65-0EE6-478F-884DCE28AD123792_sc7?wid=700&hei=700', ''),
    (100314, 'https://www.staples-3p.com/s7/is/image/Staples/2C813818-609C-48B0-A5B72C9270296301_sc7?wid=700&hei=700', ''),
    (100314, 'https://www.staples-3p.com/s7/is/image/Staples/24AD6A77-5DC8-4FBD-989E4FEE55F15DA9_sc7?wid=700&hei=700', ''),
    (100314, 'https://www.staples-3p.com/s7/is/image/Staples/8BB61944-3D48-4CE4-8327F63BF437634F_sc7?wid=700&hei=700', ''),
    (100314, 'https://www.staples-3p.com/s7/is/image/Staples/3E85D25E-1967-4307-8A64BC3BA5F18A62_sc7?wid=700&hei=700', ''),
    
    (100315, 'https://www.staples-3p.com/s7/is/image/Staples/37B758D7-2B96-4E2D-ABF4E4AAFFE3BC6F_sc7?wid=700&hei=700', ''),
    (100315, 'https://www.staples-3p.com/s7/is/image/Staples/5E737974-B2C3-448C-B4DD1BBC1F1B0F06_sc7?wid=700&hei=700', ''),
    (100315, 'https://www.staples-3p.com/s7/is/image/Staples/58FD9017-97AE-48E8-AAB4269BC0883BD9_sc7?wid=700&hei=700', ''),
    (100315, 'https://www.staples-3p.com/s7/is/image/Staples/8C2DF227-53C1-4D0E-929B8F5EC0A09A2D_sc7?wid=700&hei=700', ''),
    (100315, 'https://www.staples-3p.com/s7/is/image/Staples/E6F89404-A849-45B4-80DCC8BEF18E2DB8_sc7?wid=700&hei=700', ''),
    (100315, 'https://www.staples-3p.com/s7/is/image/Staples/6E602881-5F54-4B2E-996312B335A7FE9B_sc7?wid=700&hei=700', ''),
    
    (100316, 'https://www.staples-3p.com/s7/is/image/Staples/A9809EBD-5FCC-4A03-B40FAFB26118DA2D_sc7?wid=700&hei=700', ''),
    (100316, 'https://www.staples-3p.com/s7/is/image/Staples/B3D23C50-568C-4B28-959B3CF228CC8C89_sc7?wid=700&hei=700', ''),
    (100316, 'https://www.staples-3p.com/s7/is/image/Staples/5C21529A-EFDE-448E-A53EAC257AE36928_sc7?wid=700&hei=700', ''),
    (100316, 'https://www.staples-3p.com/s7/is/image/Staples/053E5E0E-70C8-40E7-925992EE95C92A2E_sc7?wid=700&hei=700', ''),
    (100316, 'https://www.staples-3p.com/s7/is/image/Staples/561C327E-6541-411D-9BD30A2BC1684949_sc7?wid=700&hei=700', ''),
    (100316, 'https://www.staples-3p.com/s7/is/image/Staples/EC589213-4362-47E4-BB4383489F986315_sc7?wid=700&hei=700', ''),
    
    (100317, 'https://www.staples-3p.com/s7/is/image/Staples/0278D8CC-CD92-488F-A51BBFEF8525B601_sc7?wid=700&hei=700', ''),
    (100317, 'https://www.staples-3p.com/s7/is/image/Staples/458B3FB4-6391-4DA2-A81E960707074A01_sc7?wid=700&hei=700', ''),
    (100317, 'https://www.staples-3p.com/s7/is/image/Staples/6057FEA6-587E-428E-A1EB00AA985361D8_sc7?wid=700&hei=700', ''),
    (100317, 'https://www.staples-3p.com/s7/is/image/Staples/3ABF2577-407D-4AE7-83BFA04EC3F81832_sc7?wid=700&hei=700', ''),
    (100317, 'https://www.staples-3p.com/s7/is/image/Staples/C4FFF143-A820-4A77-907625918C01B691_sc7?wid=700&hei=700', ''),
    (100317, 'https://www.staples-3p.com/s7/is/image/Staples/2B6ADFEF-D3DE-4B33-9CEF5C1D71C9741E_sc7?wid=700&hei=700', ''),
    
    (100318, 'https://www.staples-3p.com/s7/is/image/Staples/7802D637-CB82-415E-AD543B5AECD0F8B0_sc7?wid=700&hei=700', ''),
    (100318, 'https://www.staples-3p.com/s7/is/image/Staples/84239C76-86E5-491D-BA3738AC08D7078B_sc7?wid=700&hei=700', ''),
    (100318, 'https://www.staples-3p.com/s7/is/image/Staples/820464A3-38B8-4F93-AE794889BBE4E222_sc7?wid=700&hei=700', ''),
    (100318, 'https://www.staples-3p.com/s7/is/image/Staples/6789F01A-E7F3-4C16-A9C0B5A03DB540C3_sc7?wid=700&hei=700', ''),
    (100318, 'https://www.staples-3p.com/s7/is/image/Staples/459428D1-2F4C-4A2B-ACA9B062AC797467_sc7?wid=700&hei=700', ''),
    (100318, 'https://www.staples-3p.com/s7/is/image/Staples/1EF62BCA-C053-4587-9EAA8547341A6F6D_sc7?wid=700&hei=700', ''),
    
    (100319, 'https://www.staples-3p.com/s7/is/image/Staples/B94BEB4E-D957-48EF-95D72577308D9D9E_sc7?wid=700&hei=700', ''),
    (100319, 'https://www.staples-3p.com/s7/is/image/Staples/C86E6289-5F11-4B7F-8134AB18B8BBCEDF_sc7?wid=700&hei=700', ''),
    (100319, 'https://www.staples-3p.com/s7/is/image/Staples/BB5695B7-BB6D-4041-870DD10C8694077D_sc7?wid=700&hei=700', ''),
    (100319, 'https://www.staples-3p.com/s7/is/image/Staples/454A7A0F-3B24-496D-8825EACBDDFE9136_sc7?wid=700&hei=700', ''),
    (100319, 'https://www.staples-3p.com/s7/is/image/Staples/DC8A7FB9-DEA9-4F01-90E512858E58C32B_sc7?wid=700&hei=700', ''),
    (100319, 'https://www.staples-3p.com/s7/is/image/Staples/5241D329-4F2A-4FB5-A8A9F25AF1827BC1_sc7?wid=700&hei=700', ''),
    
    (100320, 'https://www.staples-3p.com/s7/is/image/Staples/99B9D519-6226-4D08-B5D63D58833982D0_sc7?wid=700&hei=700', ''),
    (100320, 'https://www.staples-3p.com/s7/is/image/Staples/A1EB8473-94EF-47B3-92B2E6BED0600A15_sc7?wid=700&hei=700', ''),
    (100320, 'https://www.staples-3p.com/s7/is/image/Staples/D45B7B60-D35B-487A-8DF59B7CDEECAC7E_sc7?wid=700&hei=700', ''),
    (100320, 'https://www.staples-3p.com/s7/is/image/Staples/563C0F35-F21A-4A5D-A4F71A8DB0D7D22D_sc7?wid=700&hei=700', ''),
    (100320, 'https://www.staples-3p.com/s7/is/image/Staples/43147E57-97C4-4D52-A7EFB57CCBBA7CBE_sc7?wid=700&hei=700', ''),
    (100320, 'https://www.staples-3p.com/s7/is/image/Staples/C29F0E87-FCF5-4588-BEA9AAC74014BFC1_sc7?wid=700&hei=700', ''),
    
    (100321, 'https://www.staples-3p.com/s7/is/image/Staples/4CC559BD-0238-429E-A7313225AB132440_sc7?wid=700&hei=700', ''),
    (100321, 'https://www.staples-3p.com/s7/is/image/Staples/8AFD60A3-5403-473F-A1541896FB8CC470_sc7?wid=700&hei=700', ''),
    (100321, 'https://www.staples-3p.com/s7/is/image/Staples/342935CA-7C09-4E4B-B093C4DB3B578A30_sc7?wid=700&hei=700', ''),
    (100321, 'https://www.staples-3p.com/s7/is/image/Staples/E3BE1F16-4503-4980-8DA18F6B6E041180_sc7?wid=700&hei=700', ''),
    (100321, 'https://www.staples-3p.com/s7/is/image/Staples/EB90F81D-1EF8-4950-A2A086EEF78B1D93_sc7?wid=700&hei=700', ''),
    (100321, 'https://www.staples-3p.com/s7/is/image/Staples/18E0B232-5AC9-4758-AEE8BA168DDC3058_sc7?wid=700&hei=700', ''),
    
    (100322, 'https://www.staples-3p.com/s7/is/image/Staples/9483D0B0-C978-4EF1-8E0C2F1C0FC4375A_sc7?wid=700&hei=700', ''),
    (100322, 'https://www.staples-3p.com/s7/is/image/Staples/CBDE0746-0BBD-4B9B-A27394B9C7B9AD5A_sc7?wid=700&hei=700', ''),
    (100322, 'https://www.staples-3p.com/s7/is/image/Staples/A4C81F63-7C65-40E8-B151CD67AB13A1C0_sc7?wid=700&hei=700', ''),
    (100322, 'https://www.staples-3p.com/s7/is/image/Staples/5271254D-38E5-4650-9039CE4B4F650C68_sc7?wid=700&hei=700', ''),
    (100322, 'https://www.staples-3p.com/s7/is/image/Staples/DDEFA5EE-FF77-4D88-9C3897C9C5ABF86C_sc7?wid=700&hei=700', ''),
    (100322, 'https://www.staples-3p.com/s7/is/image/Staples/05D9E779-A5E0-4E12-909095440A75E541_sc7?wid=700&hei=700', ''),
    
    
    (100323, 'https://www.staples-3p.com/s7/is/image/Staples/sp71001592_sc7?wid=700&hei=700', ''),
    (100323, 'https://www.staples-3p.com/s7/is/image/Staples/sp71001593_sc7?wid=700&hei=700', ''),
    (100323, 'https://www.staples-3p.com/s7/is/image/Staples/sp71001594_sc7?wid=700&hei=700', ''),
    
    (100324, 'https://www.staples-3p.com/s7/is/image/Staples/8A083AC9-4DE7-4F3C-8E07CFBDF68FEFE3_sc7?wid=700&hei=700', ''),
    (100324, 'https://www.staples-3p.com/s7/is/image/Staples/C38A3E2B-1A6B-48D5-9B0A1F6A56D34199_sc7?wid=700&hei=700', ''),
    (100324, 'https://www.staples-3p.com/s7/is/image/Staples/A1D17B3A-648C-45DC-869827C5C22B357D_sc7?wid=700&hei=700', ''),
    (100324, 'https://www.staples-3p.com/s7/is/image/Staples/5D4C0670-C416-45F4-9DDF3DB44C386DF0_sc7?wid=700&hei=700', ''),
    (100324, 'https://www.staples-3p.com/s7/is/image/Staples/8E39592A-D4F2-4D32-83E7CC1FF489E2AD_sc7?wid=700&hei=700', ''),
    
    (100325, 'https://www.staples-3p.com/s7/is/image/Staples/169FAA15-ABA2-44DE-90E453B4845A0560_sc7?wid=700&hei=700', ''),
    (100325, 'https://www.staples-3p.com/s7/is/image/Staples/F3A84282-64AD-4D4B-A7B33185AFD444D7_sc7?wid=700&hei=700', ''),
    (100325, 'https://www.staples-3p.com/s7/is/image/Staples/4156686B-2782-42B9-A93D36A084B4B8A7_sc7?wid=700&hei=700', ''),
    (100325, 'https://www.staples-3p.com/s7/is/image/Staples/C262E7E1-E817-41CC-BAE138C77E23BB6F_sc7?wid=700&hei=700', '');
    
--     (100326, '', ''),
--     (100327, '', ''),
--     (100328, '', ''),
--     (100329, '', ''),
--     (100329, '', ''),
--     (100330, '', ''),
    
    
    