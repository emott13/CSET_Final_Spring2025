-- select * from images where variant_id between 100227 AND 100240;
select image_id, file_path from images where variant_id <= 100241;
select * from products;
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

-- VENDORS 
SELECT email, CONCAT(first_name, ' ', last_name) FROM users WHERE type = 'vendor';
select * from products;
