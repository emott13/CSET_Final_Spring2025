from flask import Blueprint, render_template, request, redirect, url_for
from flask_login import current_user
from sqlalchemy import text
from extensions import conn, getCurrentType, dict_db_data

product_bp = Blueprint("product", __name__, static_folder="static_product",
                        template_folder="templates_product")

def getUser():
    return None if not current_user.is_authenticated else current_user.email

def getProductData(product_id):
    result = conn.execute(
        text("SELECT product_id, vendor_id, product_title, product_description, " \
            "warranty_months, CONCAT(first_name, ' ', last_name) " \
            "FROM products " \
            "JOIN users ON users.email = products.vendor_id " \
            "WHERE product_id = :pid"),
        {'pid': product_id}).first()
    return result if result else None

def getVariantData(product_id):
    data = conn.execute(
        text("""
            SELECT variant_id, product_id, color_id, color_name,
                color_hex, size_id, size_description, price,
                spec_id, spec_description, current_inventory
            FROM product_variants 
                NATURAL JOIN colors 
                NATURAL JOIN sizes 
                NATURAL JOIN specifications
            WHERE product_id = :pid ORDER BY variant_id
            """),
            {'pid': product_id}).fetchall()
    print('.................... data', data)
    return data

def getReviewData(product_id):
    reviews = conn.execute(
        text("SELECT * FROM reviews WHERE product_id = :pid ORDER BY date DESC"),
        {'pid': product_id}
    ).fetchall()
    average = conn.execute(
        text("SELECT ROUND(AVG(rating), 1) FROM reviews WHERE product_id = :pid"),
        {'pid': product_id}).first()[0]
    return reviews, average

def getCartId(user):
    result = conn.execute(
        text("SELECT cart_id FROM carts WHERE customer_email = :uid"),
        {'uid': user}).first()
    return result[0] if result else None

def getImageData(variant_id):
    images = conn.execute(text("""
        SELECT variant_id, file_path
        FROM images
        WHERE variant_id = :vid
        """),
        {'vid': variant_id}).all()
    return images

def getDiscount(variant_id): # FIX VID INFORMATION ################################################
    bestDiscount = conn.execute(
        text("""
            SELECT * FROM discounts
            WHERE (start_date <= NOW() OR start_date IS NULL)
            AND (end_date >= NOW() OR end_date IS NULL) AND variant_id = :vid
            ORDER BY discount_price;
        """), {'vid': variant_id}).fetchone()
    
    # dict_db_data("discounts", 
    #     """
    #         WHERE (start_date <= NOW() OR start_date IS NULL)
    #         AND (end_date >= NOW() OR end_date IS NULL) AND variant_id = :vid
    #         ORDER BY discount_price
    #     """)
    print('.................... bestdiscount', bestDiscount)
    if bestDiscount: 
        return bestDiscount[0]
    else: 
        return None    
    
def getAllDiscounts(product_id):
    allDiscountData = conn.execute(
        text("""
        SELECT variant_id, MIN(discount_price) 
        FROM discounts
        NATURAL JOIN product_variants
        WHERE (start_date <= NOW() OR start_date IS NULL) 
            AND (end_date >= NOW() OR end_date IS NULL)
            AND (product_id = :pid)
        GROUP BY variant_id;
        """), {'pid': product_id}).all()
    print('.................... alldiscountdata', allDiscountData)
    return allDiscountData
    
def isValidProductURL(product_id, variant_id=None):
    variants = conn.execute(                                                            # fetch variant ids related to passed product id
        text("SELECT variant_id FROM product_variants WHERE product_id = :pid"),
        {'pid': product_id}
    ).fetchall()

    if not variants:                                                                    # if none, product does not exist
        return 404  
    
    variant_ids = [row[0] for row in variants]

    if variant_id and variant_id in variant_ids:                                        # if condition: variant id exists, and variant id is in list of variant ids
        return None                                                                     # true: valid and returns none
    return f"/product/{product_id}/{variant_ids[0]}"                                    # false: returns valid url


@product_bp.route("/product/<int:product_id>/", methods=["GET", "POST"])
@product_bp.route("/product/<int:product_id>/<int:variant_id>", methods=["GET", "POST"])
def product(product_id, variant_id=None, error=None):
    
    redirect_url = isValidProductURL(product_id, variant_id)                            # validate product/variant url
    if redirect_url == 404:
        return "Error: Page not found :("
    elif redirect_url:
        return redirect(redirect_url)

    print(f"produc_id: {product_id}")

    user = getUser()
    product = getProductData(product_id)
    variants = getVariantData(product_id)
    reviews, review_avg = getReviewData(product_id)
    cart_id = getCartId(user)
    discount = getDiscount(variant_id)
    allDiscounts = getAllDiscounts(product_id)
    images = getImageData(variant_id)
    user_type = getCurrentType()

    product_map = {
        'pid': product[0],
        'vend_id': product[1],
        'title': product[2],
        'description': product[3],
        'warranty': product[4],
        'full_name': product[5]
    }
    allVariants_map = []
    for variant in variants:
        allVariants_map.append({
            'vid': variant[0],
            'pid': variant[1],
            'cid': variant[2],
            'c_name': variant[3],
            'hex': variant[4],
            'sid': variant[5],
            's_descr': variant[6],
            'price': variant[7],
            'spid': variant[8],
            'sp_descr': variant[9],
            'current_inventory': variant[10]
        })
    print('.................... allvariantsmap', allVariants_map)
    currVariant_map = next((v for v in allVariants_map if v['vid'] == variant_id), None)
    reviews_map = []
    for review in reviews:
        reviews_map.append({
            'rid': review[0],
            'email': review[1],
            'pid': review[2],
            'rating': review[3],
            'description': review[4],
            'image': review[5],
            'date': review[6]
        })
    allDiscounts_map = []
    for discount in allDiscounts:
        allDiscounts_map.append({
            discount[0]: discount[1]
        })
    discount_map = []
    if discount:
        for disc in discount:
            discount_map.append({
                'did': disc[0],
                'vid': disc[1],
                'price': disc[2],
                'start': disc[3],
                'end': disc[4]
            })
    images_map = []
    for image in images:
        images_map.append({
            'vid': image[0],
            'file': image[1]
        })


    if request.method == "GET":
        return render_template("product.html", error=error, productId=product_id, 
            productData=product_map, variantId=variant_id, variantData=currVariant_map, 
            allVariantsData=allVariants_map, imageData=images_map, allDiscountData=allDiscounts_map, 
            reviewsAvg=review_avg, reviewsData=reviews_map, getCurrentType=getCurrentType(), 
            bestDiscount=discount, email=user, userType=user_type)
    elif request.method == "POST":
        amount = request.form.get("number")
        variantId = currVariant_map['vid']
        if not current_user.is_authenticated:
            error = "You must be signed in to add to cart"
        elif current_user.type != 'customer':
            error = "You must be signed in as a customer"
        elif not amount.isdigit():
            error = "Amount value is invalid"
        elif int(amount) < 1 or int(amount) > 100:
            error = "Amount value is invalid"

        if not error:
            email = current_user.get_email()
            cartId = conn.execute(text(
                f"SELECT cart_id FROM carts WHERE customer_email = '{email}'"
            )).first()

            if not cartId:
                conn.execute(text(f"INSERT INTO carts (customer_email) VALUES ('{email}')"))
                conn.commit()

            cartId = conn.execute(text(
                f"SELECT cart_id FROM carts WHERE customer_email = '{email}'"
            )).first()[0]

            cartItemVariants = conn.execute(text(
                f"SELECT variant_id FROM cart_items WHERE cart_id = {cartId}")).all()
            
            inCart = False
            for variant in cartItemVariants:
                if variant[0] == variantId:
                    inCart = True
                    break


            if not inCart:
                conn.execute(text(
                    "INSERT INTO cart_items (cart_id, variant_id, quantity)"
                f"VALUES ({cartId}, {variantId}, {amount})"))
            else:
                conn.execute(text("UPDATE cart_items "
                                f"SET quantity = (quantity + {amount})"
                                f"WHERE cart_id = {cartId} AND variant_id = {variantId}"))
            conn.commit()

        return render_template("product.html", error=error, productId=product_id, 
            productData=product_map, variantId=variant_id, variantData=currVariant_map, 
            allVariantsData=allVariants_map, imageData=images_map, allDiscountData=allDiscounts_map, 
            reviewsAvg=review_avg, reviewsData=reviews_map, getCurrentType=getCurrentType(), 
            bestDiscount=discount, email=user, userType=user_type)
        
    # pi = { # product indexes
    #     'product_id': 0,
    #     'vendor_id': 1,
    #     'product_title': 2,
    #     'product_description': 3,
    #     'warranty_months': 4,
    #     'username': 5
    # }
    # vi = { # variant indexes
    #     'variant_id': 0,
    #     'product_id': 1,
    #     'color_id': 2,
    #     'size_id': 3,
    #     'price': 4,
    #     'current_inventory': 5,
    #     'color_name': 6,
    #     'color_hex': 7,
    #     'size_description': 8
    # }
    # ii = { # image indexes
    #     'variant_id': 0,
    #     'file_path': 1
    # }
    # ri = { # review indexes
    #     'review_id': 0,
    #     'customer_email': 1,
    #     'product_id': 2,
    #     'rating': 3,
    #     'description': 4,
    #     'image': 5,
    #     'date': 6,
    #     'full_name': 7,
    #     'date_time': 8
    # }

    # product data. Index like this productData[pi['product_title']]
    # productData = conn.execute(text(
    #     "SELECT product_id, vendor_id, product_title, "
    #     "product_description, warranty_months, username FROM products "
    #     "JOIN users ON products.vendor_id = users.email "
    #     f"WHERE product_id = {productId}")).first()
    # variant data. Index like this variantData[vi['price']]
    # variantData = conn.execute(text(
    #     "SELECT variant_id, product_id, color_id, size_id, "
    #     "price, current_inventory, color_name, color_hex, size_description "
    #     "FROM product_variants NATURAL JOIN colors NATURAL JOIN sizes " \
    #     f"WHERE product_id = {productId} AND variant_id = {variantId} "
    #     "ORDER BY variant_id")).first()
    # all variant data. Index like this variantData[<index>][vi['price']]
    # allVariantData = conn.execute(text(
    #     "SELECT variant_id, product_id, color_id, size_id, "
    #     "price, current_inventory, color_name, color_hex, size_description "
    #     "FROM product_variants NATURAL JOIN colors NATURAL JOIN sizes " \
    #     f"WHERE product_id = {productId}")).all()
    # allDiscountData = dict( conn.execute(text(
    #     "SELECT variant_id, MIN(discount_price) FROM discounts " \
    #     "NATURAL JOIN product_variants " \
    #     "WHERE (start_date <= NOW() OR start_date IS NULL) AND (end_date >= NOW() OR end_date IS NULL) " \
    #    f"AND (product_id = {productId}) " \
    #     "GROUP BY variant_id;"
    # )).all() )

    # bestDiscount = dict_db_data("discounts", 
    #     """
    #         WHERE (start_date <= NOW() OR start_date IS NULL)
    #         AND (end_date >= NOW() OR end_date IS NULL) AND variant_id = {variantId}
    #         ORDER BY discount_price
    #     """)

    # if bestDiscount:
    #     bestDiscount = bestDiscount[0]


    # reviewsData = conn.execute(text("SELECT review_id, customer_email, product_id, rating, description, "
    #     "image, date(date), CONCAT(first_name, ' ', last_name) AS 'full_name', date AS 'date_time' "
    #    f"FROM reviews JOIN users ON reviews.customer_email = users.email WHERE product_id = {productId} "
    #     "ORDER BY date DESC")).all()
    # reviewsAvg = conn.execute(text(f"SELECT ROUND(AVG(rating), 1) FROM reviews WHERE product_id = {productId}")).first()[0]

    # image data. Index like this imageData[0][ii['file_path']]


    # elif request.method == "POST":
    #     amount = request.form.get("number")
    #     if not current_user.is_authenticated:
    #         error = "You must be signed in to add to cart"
    #     elif current_user.type != 'customer':
    #         error = "You must be signed in as a customer"
    #     elif not amount.isdigit():
    #         error = "Amount value is invalid"
    #     elif int(amount) < 1 or int(amount) > 100:
    #         error = "Amount value is invalid"

    #     if not error:
    #         email = current_user.get_email()
    #         cartId = conn.execute(text(
    #             f"SELECT cart_id FROM carts WHERE customer_email = '{email}'"
    #         )).first()

    #         if not cartId:
    #             conn.execute(text(f"INSERT INTO carts (customer_email) VALUES ('{email}')"))
    #             conn.commit()

    #         cartId = conn.execute(text(
    #             f"SELECT cart_id FROM carts WHERE customer_email = '{email}'"
    #         )).first()[0]

    #         cartItemVariants = conn.execute(text(
    #             f"SELECT variant_id FROM cart_items WHERE cart_id = {cartId}")).all()
            
    #         inCart = False
    #         for variant in cartItemVariants:
    #             if variant[0] == variantId:
    #                 inCart = True
    #                 break


    #         if not inCart:
    #             conn.execute(text(
    #                 "INSERT INTO cart_items (cart_id, variant_id, quantity)"
    #             f"VALUES ({cartId}, {variantId}, {amount})"))
    #         else:
    #             conn.execute(text("UPDATE cart_items "
    #                             f"SET quantity = (quantity + {amount})"
    #                             f"WHERE cart_id = {cartId} AND variant_id = {variantId}"))
    #         conn.commit()

    #     return render_template("product.html", error=error, productId=productId,    
    #                         productData=productData, pi=pi,
    #                         variantId=variantId, variantData=variantData, vi=vi, imageData=imageData, ii=ii,
    #                         allVariantData=allVariantData, allDiscountData=allDiscountData, reviewsAvg=reviewsAvg,
    #                         reviewsData=reviewsData, ri=ri, getCurrentType=getCurrentType(),
    #                         bestDiscount=bestDiscount, email=current_user.email)


@product_bp.route("/product/<int:productId>/<int:variantId>/review", methods=["POST"])
def submitReview(productId, variantId):
    rating = int(request.form.get('rating'))
    desc = request.form.get('description', None)
    url = request.form.get('image', None)
    reviewExists = bool(conn.execute(text("SELECT review_id FROM reviews "
        f"WHERE product_id = {productId} AND customer_email = '{current_user.email}'"
        )).first())

    if reviewExists:
        return redirect(url_for("product.product", product_id=productId, variantId=variantId))

    if  (rating >= 1 and rating <= 5 ) and \
        not (desc and len(desc) > 500) and \
        not (url and len(url) > 255
    ):
        print(f"\n\n\nTo else\n\n\n")
        conn.execute(text(f"INSERT INTO reviews (customer_email, product_id, rating\
                        {', description' if desc else ''} {', image' if url else ''}) "
                        "VALUES (:email, :productId, :rating "
                        f"{', :desc' if desc else ''}{', :url' if url else ''})"),
                        {'email': current_user.email, 'productId': productId, 
                        'rating': rating, 'desc': desc, 'url': url})
        conn.commit()

    return redirect(url_for("product.product", product_id=productId, variant_id=variantId))

@product_bp.route("/product/<int:productId>/<int:variantId>/<int:reviewId>", methods=["POST"])
def reviewDelete(productId, variantId, reviewId):
    review_email = conn.execute(text("SELECT customer_email FROM reviews "
                                     f"WHERE review_id = {reviewId}")).first()[0]
    if review_email != current_user.email:
        return redirect(url_for("product.product", product_id=productId, variant_id=variantId))

    try:
        conn.execute(text(f"DELETE FROM reviews WHERE review_id = {reviewId}"))
        conn.commit()
    except Exception as e:
        print("\n" + str(e) + "\n")

    return redirect(url_for("product.product", product_id=productId, variant_id=variantId))