USE goods;

SELECT * FROM carts;
SELECT * FROM cart_items WHERE cart_id = (SELECT cart_id FROM carts WHERE customer_email = "bluemario812@gmail.com");
SELECT * FROM users;
SELECT * FROM products;
SELECT * FROM discounts;
SELECT * FROM product_variants;
SELECT * FROM colors;
SELECT * FROM sizes;
SELECT * FROM reviews 
JOIN users ON reviews.customer_email = users.email
WHERE product_id = 850556;

DESC product_variants;
DELETE FROM cart_items WHERE cart_id = (SELECT cart_id FROM carts WHERE customer_email = "bluemario812@gmail.com");
DELETE FROM carts WHERE customer_email = "bluemario812@gmail.com";

INSERT INTO reviews (customer_email, product_id, rating, description, image)
VALUES 
	("bluemario812@gmail.com", 850556, 4, "Product worked great. Had slight issues as the pages were a little stuck together but after that it worked perfectly", "https://m.media-amazon.com/images/I/81y2PkckqSL._AC_SL1500_.jpg")
-- 	("bluemario812@gmail.com", 850556, 5, NULL, NULL),
-- 	("bluemario812@gmail.com", 850556, 3, NULL, NULL)
;
DELETE FROM reviews WHERE customer_email = "bluemario812@gmail.com";

SELECT * FROM products
NATURAL JOIN product_variants
NATURAL JOIN colors
NATURAL JOIN sizes
ORDER BY product_id;           

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