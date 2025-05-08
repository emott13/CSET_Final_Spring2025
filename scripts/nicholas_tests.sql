USE goods;

SELECT * FROM carts;
SELECT * FROM cart_items WHERE cart_id = (SELECT cart_id FROM carts WHERE customer_email = "bluemario812@gmail.com");
SELECT * FROM users;
SELECT * FROM products;
SELECT * FROM discounts;
SELECT * FROM product_variants;
SELECT * FROM colors;
SELECT * FROM sizes;
SELECT * FROM images;
SELECT * FROM categories;
SELECT * FROM orders;
SELECT * FROM complaints;
DELETE FROM complaints WHERE complaint_id = 7;
SELECT * FROM reviews; 
JOIN users ON reviews.customer_email = users.email
WHERE product_id = 850556;

SELECT * FROM carts;
SELECT * FROM cart_items WHERE cart_id = 6;

DESC products;
DESC images;
DESC sizes;
DESC colors;
DESC complaints;
SHOW COLUMNS FROM complaints LIKE 'demand';
DESC product_variants;
DELETE FROM cart_items WHERE cart_id = (SELECT cart_id FROM carts WHERE customer_email = "bluemario8@gmail.com");
DELETE FROM carts WHERE customer_email = "bluemario812@gmail.com";

INSERT INTO reviews (customer_email, product_id, rating, description, image)
VALUES 
-- 	("bluemario812@gmail.com", 850556, 4, "Product worked great. Had slight issues as the pages were a little stuck together but after that it worked perfectly", "https://m.media-amazon.com/images/I/81y2PkckqSL._AC_SL1500_.jpg"),
-- 	("bluemario812@gmail.com", 850556, 5, NULL, NULL),
-- 	("bluemario812@gmail.com", 850556, 3, NULL, NULL),
    ("bluemario812@gmail.com", 850556, 2, NULL, NULL)
;
INSERT INTO reviews (customer_email, product_id, rating, description, image, date)
VALUES ("bluemario812@gmail.com", 850556, 4, NULL, NULL, '2024-04-28 07:31:00');

DELETE FROM reviews WHERE customer_email = "bluemario812@gmail.com";

SELECT * FROM products
NATURAL JOIN product_variants
NATURAL JOIN colors
NATURAL JOIN sizes
ORDER BY product_id;           

SELECT variant_id, product_id, pv.color_id, pv.size_id,
        price, current_inventory, color_name, color_hex, size_description
        FROM product_variants AS pv LEFT JOIN colors ON pv.color_id=colors.color_id
        LEFT JOIN sizes ON pv.size_id=sizes.size_id
		WHERE product_id = 850555 AND variant_id = 100200
        ORDER BY variant_id;

INSERT INTO discounts (variant_id, discount_price, start_date)
VALUES (100204, 149, NOW());
SELECT * FROM discounts
NATURAL JOIN product_variants;

SELECT variant_id, MIN(discount_price) FROM discounts
NATURAL JOIN product_variants
WHERE (start_date <= NOW() OR start_date IS NULL) AND (end_date >= NOW() OR end_date IS NULL)
	AND (product_id = 850560)
GROUP BY variant_id;
                       
UPDATE users    -- this hash is 'password'
SET hashed_pswd = '$+&091dmk_qdRDR@$+50_;oDiieR`~8D2q//KP=RR=88_=*G5KREqdko5Jk$;k9+533K;2`Eo;J/G`@_d35G&kqqdE@=P1`+PDeP0+=?LP;k*2$m2DK23E?_L+RR/E&`GJq13q=k+oid1o59iL0!8/5D0EKLo/*5$=R@;32_?2?dP`=Rk_iD`/J+Pq~8~oi2R8dG9K;i?P9?=#~L?k0*@i=+`159mG`@~&_m9i8$@k*9!mi?o3'
WHERE email != 'blue';