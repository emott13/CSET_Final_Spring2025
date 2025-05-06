-- select * from images where variant_id between 100227 AND 100240;
select image_id, file_path from images where variant_id in (100261, 100262);
select * from products where cat_num = 101;
select * from products natural join product_variants natural join images where vendor_id = 'g_pitts@supplies4school.org' order by image_id;
select * from carts where customer_email = 'j_prescott@gmail.com';
select * from cart_items where cart_id = 2;
SELECT * FROM cart_items WHERE cart_id IN (SELECT cart_id FROM carts WHERE customer_email = 'j_prescott@gmail.com');
select * from carts natural join cart_items where customer_email = 'j_prescott@gmail.com';
select * from orders natural join order_items where customer_email = 'j_prescott@gmail.com';
SELECT *
FROM order_items
WHERE order_id
ORDER BY order_id DESC
LIMIT 1;
delete from order_items
where order_id between 17 and 79;
delete from orders
where order_id between 17 and 49;
select * from orders;
select * from product_variants;

select * from cart_items;
select * from order_items;
-- select * from users;
-- select variant_id from product_variants where product_id = 850555;
-- select product_title, product_description from products where product_id = 850555;
-- select product_id, COUNT(variant_id) from product_variants group by product_id order by product_id;
-- select MIN(price), MAX(price) from product_variants where product_id = 850555;
-- select product_id, product_title, size_description from products natural join product_variants natural join sizes where product_id = 850555 and variant_id IN(100200, 100201, 100202);

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
	OR user_to = 'j_prescott@gmail.com';

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