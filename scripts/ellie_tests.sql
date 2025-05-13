select *
from products;
SELECT s.size_id, s.size_description
FROM products p
JOIN product_variants v ON p.product_id = v.product_id
LEFT JOIN sizes s ON v.size_id = s.size_id
WHERE p.cat_num BETWEEN 1 AND 99;
select CONCAT("'", cat_name, "':", cat_num) from categories order by cat_num asc;
SELECT sp.spec_id, sp.spec_description
FROM products p 
JOIN product_variants v ON p.product_id = v.product_id
LEFT JOIN specifications sp ON v.spec_id = sp.spec_id
WHERE p.cat_num BETWEEN 1 AND 99;

-- select * from images where variant_id between 100227 AND 100240;
select image_id, file_path from images where variant_id in (100261, 100262);
select * from products where cat_num = 101;
select * from products natural join product_variants natural join images where vendor_id = 'g_pitts@supplies4school.org' order by image_id;
select * from users where email = 'j_prescott@gmail.com';
select * from cart_items where cart_id = 2;
SELECT * FROM cart_items WHERE cart_id IN (SELECT cart_id FROM carts WHERE customer_email = 'j_prescott@gmail.com');
select * from carts natural join cart_items where customer_email = 'j_prescott@gmail.com';
select * from orders natural join order_items where customer_email = 'j_prescott@gmail.com';
SELECT order_id, status, order_date, total_price
            FROM orders
            WHERE customer_email = 'j_prescott@gmail.com'
            ORDER BY order_id DESC;
-- cart_id, customer_email <carts, cart_item_id, variant_id, quantity <cart_items
INSERT INTO carts (cart_id, customer_email)
VALUES ();
select * from product_variants;


SELECT variant_id, product_id, color_id, color_name,
                color_hex, size_id, size_description, price
            FROM product_variants NATURAL JOIN colors NATURAL JOIN sizes
            WHERE product_id = 850556 ORDER BY variant_id;
            
INSERT INTO cart_items (cart_id, variant_id, quantity)
VALUES 
	(2, 100203, 1),
    (2, 100216, 1),
    (2, 100225, 1),
    (2, 100235, 1);
    
SELECT *
FROM order_items
WHERE order_id
ORDER BY order_id DESC
LIMIT 1;
delete from order_items
where order_id between 17 and 85;
delete from orders
where order_id between 17 and 85;
select * from orders;
select * from product_variants;

select * from cart_items;
select * from order_items;

SELECT v.product_id, v.variant_id, p.product_title,
		p.cat_num, u.email, v.price, v.current_inventory,
        c.color_name, c.color_hex
	FROM product_variants v
	JOIN products p ON p.product_id = v.product_id
	LEFT JOIN users u ON p.vendor_id = u.email
    LEFT JOIN colors c ON v.color_id = c.color_id;
-- select * from users;
-- select variant_id from product_variants where product_id = 850555;
-- select product_title, product_description from products where product_id = 850555;
-- select product_id, COUNT(variant_id) from product_variants group by product_id order by product_id;
-- select MIN(price), MAX(price) from product_variants where product_id = 850555;
-- select product_id, product_title, size_description from products natural join product_variants natural join sizes where product_id = 850555 and variant_id IN(100200, 100201, 100202);
drop database goods_fix;
-- select * from users;
-- SELECT variant_id, COUNT(color_name), COUNT(size_description)
-- FROM product_variants
-- NATURAL JOIN colors
-- NATURAL JOIN sizes
-- GROUP BY variant_id
-- ORDER BY variant_id;
-- select product_id, product_title from products natural join product_variants;
-- select variant_id from product_variants where product_id = 850555;
-- SELECT product_id FROM products;
-- SELECT product_title, product_description FROM products WHERE product_id = :id;
-- SELECT variant_id, price FROM product_variants WHERE product_id = :id;
-- SELECT size_description FROM sizes WHERE variant_id = :id;
-- SELECT color_name FROM colors WHERE varian_id = :id;
-- SELECT product_title, product_description, size_description, price, warranty_months, current_inventory, product_id, variant_id 
-- FROM products NATURAL JOIN product_variants NATURAL JOIN sizes;
-- SELECT color_description FROM colors NATURAL JOIN product_variants WHERE product_id = AND variant_id = ;
select * from transactions where acc_num = 578066;
-- SELECT products.product_id, products.product_title, sizes.size_description
-- 	FROM products INNER JOIN product_variants
-- 	INNER JOIN sizes ON products.product_id = product_variants.product_id
-- 	AND product_variants.size_id = sizes.size_id
--     WHERE products.product_id = :id AND variant_id = :vid;

-- select * from images where variant_id in(100227, 100227, 100239, 100240);
-- select * from products natural join product_variants where vendor_id = 'i_tombolli@study_space.com' and product_id in(850565, 850566, 850567, 850568, 850569, 850570) order by product_id;

-- select * from products;
-- select * from products natural join images;
-- select * from images;

-- select * from products;

select size_description, size_id from sizes;
select color_name, color_id, color_hex from colors order by color_name;
order by size_id;
select * from categories order by cat_num;
select * from products order by product_title;
-- VENDORS 
SELECT email, CONCAT(first_name, ' ', last_name) FROM users WHERE type = 'vendor';
select * from products where product_id between 850566 and 8505673;
select * from product_variants;
select * from colors;
select * from images;
select * from users;
select * from chats;
select * from carts natural join cart_items natural join images;
select * from cart_items;
select product_id, product_title, cat_num, variant_id, size_id, color_id, price, current_inventory
from products
natural join product_variants;
SELECT chat_id, complaint_id, product_id, text, user_from, user_to, date_time 
FROM chats 
WHERE user_from = 'j_prescott@gmail.com' 
	OR user_to = 'j_prescott@gmail.com'
ORDER BY date_time DESC
LIMIT 1;

-- products
 -- 850580
-- ('c_simmons@worksmart.com', 'Pilot G2 Retractable Gel Pens', 'Enjoy a smear-free writing experience by using Pilot G2 premium retractable gel roller pens. Improve handwriting, create drawings, and work on other projects worry free. With a convenient clip, these pens attach to binders, notebooks, and pockets, while the contoured grip offers increased support, making it easy to take on lengthy writing tasks. These Pilot G2 gel pens feature a retractable design, so you can tuck the tips away when not in use, preventing unintentional marks on documents.', 0, 11),
-- variants
-- ()

select * from products where product_title like '%office desk%' or product_description like '%office desk%';

select p.product_id, p.product_title, p.cat_num,
		MIN(v.price) AS min_price, MAX(v.price) AS max_price,
		u.username AS vendor_name,
        v.variant_id
FROM products p
LEFT JOIN product_variants v ON p.product_id = v.product_id
JOIN users u ON p.vendor_id = u.email
GROUP BY p.product_id
ORDER BY p.product_id;

select product_id, variant_id, cat_num, username
from product_variants
natural join products
natural join users
group by variant_id
order by variant_id;

select v.product_id, v.variant_id, p.cat_num, 
	   u.email, v.price, v.current_inventory
from product_variants v
join products p on p.product_id = v.product_id
left join users u on p.vendor_id = u.email;

SELECT DISTINCT variant_id, file_path, image_id
FROM images 
WHERE variant_id IS NOT NULL 
ORDER BY image_id;

-- ('Assorted', 19710, NULL),
-- ('Black', 19711, '#000000'),
-- ('Blue', 19712, '#0000ff'),
-- ('Clear', 19713, NULL),
-- ('Cyan', 19714, '#00bfff'),
-- ('Dark Blue', 19715, '#06065c'),
-- ('Dark Brown', 19716, '#52422e'),
-- ('Dark Green', 19717, '#004d00'),
-- ('Dark Grey', 19718, '#666666'),
-- ('Dark Red', 19719, '#8b0000'),
-- ('Green', 19720, '#00ff00'),
-- ('Light Blue', 19721, '#b3d9ff'),
-- ('Light Brown', 19722, '#b59b7c'),
-- ('Light Green', 19723, '#66ffc3'),
-- ('Light Grey', 19724, '#bfbfbf'),
-- ('Lilac', 19725, '#c8a2c8'),
-- ('Magenta', 19726, '#ff33cc'),
-- ('Manila', 19727, '#e7c9a9'),
-- ('Maple', 19728, '#bb9351'),
-- ('Multicolor', 19729, NULL),
-- ('Navy', 19730, '#000080'),
-- ('Orange', 19731, '#ff6600'),
-- ('Orchid', 19732, '#e2cfe1'),
-- ('Pink', 19733, '#ff80aa'),
-- ('Purple', 19734, '#800080'),
-- ('Red', 19735, '#ff0000'),
-- ('Rose Pink', 19736, '#f0afc1'),
-- ('Silver', 19737, '#c0c0c0'),
-- ('Sky Blue', 19738, '#1a6bb8'),
-- ('Walnut', 19739, '#99592e'),
-- ('White', 19740, '#ffffff'),
-- ('Yellow', 19741, '#ffff00');

INSERT INTO product_variants (product_id, color_id, size_id, spec, price, current_inventory)
VALUES
	(9000, , '', '', , )




-- images
-- (pid, cid, sid, price, inventory)
-- (iid, filepath)

-- bentogo modern lunch boxes -- 
-- black 37.99
(859, 'https://www.staples-3p.com/s7/is/image/Staples/0D3524FF-2832-47D7-A2AACA09B78251AF_sc7?wid=700&hei=700'),
(859, 'https://www.staples-3p.com/s7/is/image/Staples/D7428E65-0EE6-478F-884DCE28AD123792_sc7?wid=700&hei=700'),
(859, 'https://www.staples-3p.com/s7/is/image/Staples/2C813818-609C-48B0-A5B72C9270296301_sc7?wid=700&hei=700'),
(859, 'https://www.staples-3p.com/s7/is/image/Staples/24AD6A77-5DC8-4FBD-989E4FEE55F15DA9_sc7?wid=700&hei=700'),
(859, 'https://www.staples-3p.com/s7/is/image/Staples/8BB61944-3D48-4CE4-8327F63BF437634F_sc7?wid=700&hei=700'),
(859, 'https://www.staples-3p.com/s7/is/image/Staples/3E85D25E-1967-4307-8A64BC3BA5F18A62_sc7?wid=700&hei=700'),
-- navy -- 
(860, 'https://www.staples-3p.com/s7/is/image/Staples/37B758D7-2B96-4E2D-ABF4E4AAFFE3BC6F_sc7?wid=700&hei=700'),
(860, 'https://www.staples-3p.com/s7/is/image/Staples/5E737974-B2C3-448C-B4DD1BBC1F1B0F06_sc7?wid=700&hei=700'),
(860, 'https://www.staples-3p.com/s7/is/image/Staples/58FD9017-97AE-48E8-AAB4269BC0883BD9_sc7?wid=700&hei=700'),
(860, 'https://www.staples-3p.com/s7/is/image/Staples/8C2DF227-53C1-4D0E-929B8F5EC0A09A2D_sc7?wid=700&hei=700'),
(860, 'https://www.staples-3p.com/s7/is/image/Staples/E6F89404-A849-45B4-80DCC8BEF18E2DB8_sc7?wid=700&hei=700'),
(860, 'https://www.staples-3p.com/s7/is/image/Staples/6E602881-5F54-4B2E-996312B335A7FE9B_sc7?wid=700&hei=700'),

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
    (868, 'https://www.staples-3p.com/s7/is/image/Staples/sp71001594_sc7?wid=700&hei=700'),
    
-- crayola colored pencils --
-- pastel 12pack
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/7F85263E-79E0-437C-A14FBE37C21CF681_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/8F60F9E4-F334-416E-AAF7A89CE5D42CB5_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/529F8607-C73D-4C14-82C35B42E22530A7_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/307831B6-1D03-4D44-9B3234FD9D4FB14A_sc7?wid=700&hei=700'),
-- regular/assorted 12pack
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/5D27A585-FF26-4D7E-AF465FFEB2F8345D_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/12D715CB-091E-4CEB-A592F528A41F3A39_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/0AD39FB7-989F-453C-A9263138AEA15D3F_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/35A652D4-B70D-42F3-B3556E4906C6F7DC_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/E7741D8E-CEEE-4656-9517293FC4EA812E_sc7?wid=700&hei=700'),
-- colors of the world 24 pack
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp107458503_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp107458504_sc7?wid=700&hei=700'),
-- regular/assorted 36pack
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/E58203F0-4B7A-49F5-97F5F8C1D01E9AE9_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/2FFD9C47-E842-4EBF-A4C92197AF333E9F_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/B47C356C-0778-4C50-87D02840E032D1D2_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/D37E02DF-3AAF-4716-894F6BB6483C674A_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/0D8AC005-1BBC-4CC5-88B785A978D06294_sc7?wid=700&hei=700'),
-- regular/assorted 100pack
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp56580404_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp56580405_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp56580406_sc7?wid=700&hei=700'),
-- kids short regular/assorted 64pack
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/527776E5-86D8-4BAA-873E5AD5FA854693_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/211FBE95-ED40-43DF-80AA4CF3CFB0D02B_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/B605D84F-736D-4A9A-892F9AE12E140D52_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/0FF2591A-2E28-47F2-AB7160F64E680109_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/D4770902-036D-4AA8-B101400D9DB788F7_sc7?wid=700&hei=700'),

-- crayola crayons --
-- classpack 80/box assorted
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/EA29EB3B-116D-4C15-BFDAE2CAC268F59B_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/49AEE1EE-747F-41AC-98AD44CE837AC3FE_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/29E32DFA-769F-4233-938487200334E99A_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/5B3A5113-5ECB-4045-ADF3B217D7E31C5C_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/40992B7F-67B8-473A-94B12A9CEA5A609B_sc7?wid=700&hei=700'),
-- 8pack regular/assorted
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp64626997_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp64626998_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp64626994_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp64626995_sc7?wid=700&hei=700'),
-- 24/pack regular/assorted
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/EFA6E1CD-D33E-499E-80C60408C7458DE7_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/F26DDEFF-4824-4895-BC070726A57B234D_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/69AD0382-DB7F-4F91-BECEF168ABB9B91E_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/E7DB3A9A-DF0F-44BA-8ADE94A783070CDA_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/272F2A6A-F2DD-4E69-AC5407A41847C1FE_sc7?wid=700&hei=700'),
-- 24pack metallic assorted
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp138066198_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp138066201_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp138066200_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp138066199_sc7?wid=700&hei=700'),
-- 24pack pastel assorted (colors of kindness pack)
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp152284712_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp152284713_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp152284714_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp152284715_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp152284716_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp152284717_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp152284718_sc7?wid=700&hei=700'),
-- 120pack regular/assorted
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/49181D2F-44A7-425F-A077EF3A7FB61CEA_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/8536C452-6E42-4F58-9008D3B2666E3265_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/F1B734B2-56EA-4386-81328AD005BCADB7_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/34987F2C-882C-49B2-A98D5681661CDFAE_sc7?wid=700&hei=700'),
-- large washable 8pack assorted
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp71925575_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp71925574_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp71925576_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp71925577_sc7?wid=700&hei=700'),

-- art/craft paper --

-- pacon origomi paper
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/s0355585_sc7?wid=700&hei=700'),
-- crayola 96sheet
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455179_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455181_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455182_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455178_sc7?wid=700&hei=700'),
-- crayola 240sheet 
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455498_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455500_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455502_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455503_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455497_sc7?wid=700&hei=700'),
-- crayola 96sheet 12bulk pack
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp128051988_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455181_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455182_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455178_sc7?wid=700&hei=700'),
-- crayola 240sheet 3 bulk pack
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/95B45050-A9A5-48BC-AC6E70A0A9072CDD_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455500_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455502_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455503_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp127455497_sc7?wid=700&hei=700'),
-- crayola giant paper 48sheet
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/93B8D66E-3314-49DB-B96B213051B38BCC_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp85143793_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/0CF804E5-76CA-4D58-8100F8D3BD53EEEA_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp85143832_sc7?wid=700&hei=700'),
-- crayola giant paper 48sheet 6bulk pack
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp128051987_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp85143793_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/0CF804E5-76CA-4D58-8100F8D3BD53EEEA_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp85143832_sc7?wid=700&hei=700'),

-- coloring books --
-- crayola bluey
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/AD8F2AE1-DB2E-4EEC-B24442C7B3BBCA1B_sc7?wid=700&hei=700'),
-- crayola retired colors 
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/C517303C-8CB9-4CE0-911D72D9BA7D28A8_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/EEF52310-1D8F-4733-8C46BEB4C545D8B3_sc7?wid=700&hei=700'),
-- bendon frozen 2
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/E4178F86-7CBE-4D08-A1933F661428C2FE_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/F056EE9A-BC96-4FCF-9481273AC642E2CB_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/583FED6E-BD55-4DF5-9A8241E441D181B5_sc7?wid=700&hei=700'),
-- bendon paw patrol
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/189A041D-EC4D-4143-B7916355A349C3A8_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/79B84B23-E8B4-4FD8-88D597DD0AF9BEAC_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/150E4AFF-2E2F-4CFB-94DA538F398CF354_sc7?wid=700&hei=700'),
-- bendon despicable me 4
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/395A6C34-3408-478C-AD599243632A348E_sc7?wid=700&hei=700'),

-- stickers --
-- trend stinky stickers
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp42804717_sc7?wid=700&hei=700'),
-- trend supershapes stickers
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp44852281_sc7?wid=700&hei=700'),
-- Trend superSpots & superShapes
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp38165596_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp38165597_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp38165598_sc7?wid=700&hei=700'),

-- office basics --

-- mind reader desk organizer 7-compartment
-- black 5.25W" x 11L" x 5.25H" 7 compartments 27.69
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/1F887323-3BA1-4C4F-BAA3CE6ADDCCB95B_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/88002436-7EE5-433F-8F66EB61159A262A_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/391E5B3C-238E-4587-A40A287C170F051E_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/E812DAA3-17E6-48AA-A3C6DB7BD3AFF372_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/9465C5FB-441F-43E9-ADEBB8AC9CD159C2_sc7?wid=700&hei=700'),
-- pink 
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/B3CA0957-B05B-4FD9-A32B78AD750AAB94_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/504A8707-4D21-4405-93A9622B261E73C9_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/8794E559-10F3-460A-BA01B3D50A2F7AA2_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/DA11281B-8DEE-4903-8A22BE589425A0AC_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/ABAA2A50-1B6C-47B6-A544347AD5305F9E_sc7?wid=700&hei=700'),
-- silver
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/829D8BC4-DC53-4179-BA5438890711EE71_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/8439118D-F7FB-4F8D-A284480CFDE9B151_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/36978FEA-E001-4079-BF3F455FA0FB3201_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/503F7B41-9DF3-465E-99DDF54C9665257C_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/2DC18375-3B4B-4B78-B73023CA08BBF405_sc7?wid=700&hei=700'),
-- white
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/82068D18-8D2F-4DD1-8D9536785755C703_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/E0B006F3-1F86-4405-823CAD52E600AECD_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/2453C7E1-7E49-4CC9-81F4101EF4D1234A_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/66AACB70-BFA1-4219-AC170E8C746EEB6A_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/36DBAE3C-670A-4309-A90295F92E111C0F_sc7?wid=700&hei=700'),

-- Mind Reader Metal Pen and Accessory Holder Desk Organizer
-- black
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/EAFE6FC1-C70F-472E-A535E1B2D364FD44_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/CE3AE701-6FCB-4B4A-8463CD2F7EEC34DD_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/DA84883B-8A05-4EEE-937500DCC90F2F3B_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/AE869E10-3E96-4E71-A5586300CAEF0E5F_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/2E5D9327-0071-4820-94FC720AE517A249_sc7?wid=700&hei=700'),
-- silver
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/B373203F-45BB-4503-8DAC620D77B4D631_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/566B7A9E-2FFE-474E-BB0E3DE5F7BBEFD1_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/D5EA984E-6D97-4214-95616B57E76B422C_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/14EA91ED-FDE1-4D18-9739621044A730D9_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/BB2A9237-E6AC-4713-A02EAA789FFD958E_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/C1E11F2A-C574-46BD-8F79CA9D2D5513D5_sc7?wid=700&hei=700'),
-- white
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/77C938F9-544F-417E-992773A8E7DC9AE2_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/5766BE21-AABF-49C0-8C0940730BD232B9_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/4381D588-FC53-4AFC-9F7F001599988586_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/51E14056-51AC-42D6-A0491CA2FBB925E0_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/61E4FFA7-4BEA-4011-919E37F4E3140CE3_sc7?wid=700&hei=700'),

-- mind reader 8 compartment desk organizer black
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/EF941F83-0BFB-47E2-BF73FC54D7094891_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/C0AB5825-FE6E-4DEE-8CD9A5B2B724016A_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/0564E03D-7354-4F18-9A43A0C7D64EF97D_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/D1C60796-ABD3-48C5-BE5AD45BA67B1C19_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/172816F2-3BC4-4FBF-98C7883E3E2CF459_sc7?wid=700&hei=700'),

-- bostitch electric desktip 3 hole punch 52.59
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/F6204164-3C12-4DD6-BA567DDBCFCAC154_sc7?wid=700&hei=700'),

-- bostich ez squeeze 1-hole punch
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/s1153400_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/s1153401_sc7?wid=700&hei=700'),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/s1153403_sc7?wid=700&hei=700'),


-- hammermill copy paper --
-- letter
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072084_sc7?wid=700&hei=700', ''),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700', ''),
    
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/DC2712FE-A922-4E5F-B9B9CF5677D6BE83_sc7?wid=700&hei=700', ''),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700', ''),
    
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/A2C4AC65-2CB3-4263-BB0C166AE240F3D8_sc7?wid=700&hei=700', ''),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700', ''),
    
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp167250067_sc7?wid=700&hei=700', ''),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700', ''),
    
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/95CBC599-9581-4384-AB7E87134750EEBE_sc7?wid=700&hei=700', ''),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700', ''),
    
-- legal
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072261_sc7?wid=700&hei=700', ''),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700', ''),
    
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072238_sc7?wid=700&hei=700', ''),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700', ''),

-- A4
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp167250076_sc7?wid=700&hei=700', ''),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700', ''),
    
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/95CBC599-9581-4384-AB7E87134750EEBE_sc7?wid=700&hei=700', ''),
(iid, 'https://www.staples-3p.com/s7/is/image/Staples/sp167072089_sc7?wid=700&hei=700', ''),


(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),
(iid, ''),