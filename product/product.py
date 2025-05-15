from flask import Blueprint, render_template, request, redirect, url_for
from flask_login import current_user
from sqlalchemy import text
from extensions import conn, getCurrentType, dict_db_data

product_bp = Blueprint("product", __name__, static_folder="static_product",
                        template_folder="templates_product")

def isValidProductURL(product_id, variant_id=None):
    """
    Checks to make sure the product URL is correct. 
    If not, it either returns 404, the correct link, or None (link is correct)
    """
    # check if the product ID exists
    if conn.execute(text(
        f"SELECT product_id FROM products WHERE product_id = {product_id}")
        ).all() == []:
        return 404

    isValid = True
    productVariants = conn.execute(text(
        f"SELECT variant_id FROM product_variants "
        f"WHERE product_id = {product_id} ORDER BY variant_id")
        ).all()

    if productVariants == []:
        return url_for("home.home")

    variantValue = variant_id
    # if variant_id exists. Sets variantValue to either the current 
    # variant_id (if valid), or a valid variant_id
    if variant_id:
        # checks if the variant_id is in the variants table with the correct product ID
        variantExists = False
        for variant in productVariants:
            if variant_id == variant[0]:
                variantExists = True
                break

        if not variantExists:
            variantValue = productVariants[0][0] # sets the variable to the first variant
            isValid = False
    else:
        isValid = False
        variantValue = productVariants[0][0] # sets the variable to the first variant

    if isValid:
        return None
    else:
        return f"/product/{product_id}/{variantValue}"
        

@product_bp.route("/product/<int:product_id>/", methods=["GET", "POST"])
@product_bp.route("/product/<int:product_id>/<int:variant_id>", methods=["GET", "POST"])
def product(product_id, variant_id=None, error=None):
    # Returns 404 (product_id doesn't exist), new URL (if the parameters are invalid),
    # or None (parameters are already fine)
    invalidURL = isValidProductURL(product_id, variant_id)
    if invalidURL == 404:
        return "Error: Page not found :("
    elif invalidURL:
        return redirect(invalidURL)

    email = None if not current_user.is_authenticated else current_user.email

    pi = { # product indexes
        'product_id': 0,
        'vendor_id': 1,
        'product_title': 2,
        'product_description': 3,
        'warranty_months': 4,
        'username': 5,
        'full_name': 6
    }
    vi = { # variant indexes
        'variant_id': 0,
        'product_id': 1,
        'color_id': 2,
        'size_id': 3,
        'price': 4,
        'current_inventory': 5,
        'color_name': 6,
        'color_hex': 7,
        'size_description': 8
    }
    ii = { # image indexes
        'variant_id': 0,
        'file_path': 1
    }
    ri = { # review indexes
        'review_id': 0,
        'customer_email': 1,
        'product_id': 2,
        'rating': 3,
        'description': 4,
        'image': 5,
        'date': 6,
        'full_name': 7,
        'date_time': 8
    }
    # product data. Index like this productData[pi['product_title']]
    productData = conn.execute(text(
        "SELECT product_id, vendor_id, product_title, "
        "product_description, warranty_months, username, "
        "CONCAT(users.first_name, ' ', users.last_name) AS full_name FROM products "
        "JOIN users ON products.vendor_id = users.email "
        f"WHERE product_id = {product_id}")).first()
    print(f"productData:\n{productData}\n")
    # variant data. Index like this variantData[vi['price']]
    variantData = conn.execute(text(
        "SELECT variant_id, product_id, pv.color_id, pv.size_id, "
        "price, current_inventory, color_name, color_hex, size_description "
        "FROM product_variants AS pv LEFT JOIN colors ON pv.color_id=colors.color_id "
        "LEFT JOIN sizes ON pv.size_id=sizes.size_id " \
        f"WHERE product_id = {product_id} AND variant_id = {variant_id} "
        "ORDER BY variant_id")).first()
    # all variant data. Index like this variantData[<index>][vi['price']]
    allVariantData = conn.execute(text(
        "SELECT variant_id, product_id, pv.color_id, pv.size_id, "
        "price, current_inventory, color_name, color_hex, size_description "
        "FROM product_variants AS pv LEFT JOIN colors ON pv.color_id=colors.color_id "
        "LEFT JOIN sizes ON pv.size_id=sizes.size_id "
        f"WHERE product_id = {product_id} ORDER BY variant_id")).all()
    allDiscountData = dict( conn.execute(text(
        "SELECT variant_id, MIN(discount_price) FROM discounts " \
        "NATURAL JOIN product_variants " \
        "WHERE (start_date <= NOW() OR start_date IS NULL) AND (end_date >= NOW() OR end_date IS NULL) " \
       f"AND (product_id = {product_id}) " \
        "GROUP BY variant_id;"
    )).all() )

    bestDiscount = dict_db_data("discounts", 
        "WHERE (start_date <= NOW() OR start_date IS NULL) " +
        f"   AND (end_date >= NOW() OR end_date IS NULL) AND variant_id = {variant_id} "
        "ORDER BY discount_price")

    print("\n" + str(variantData) + "\n")

    if bestDiscount:
        bestDiscount = bestDiscount[0]


    reviewsData = conn.execute(text("SELECT review_id, customer_email, product_id, rating, description, "
        "image, date(date), CONCAT(first_name, ' ', last_name) AS 'full_name', date AS 'date_time' "
       f"FROM reviews JOIN users ON reviews.customer_email = users.email WHERE product_id = {product_id} "
        "ORDER BY date DESC")).all()
    reviewsAvg = conn.execute(text(f"SELECT ROUND(AVG(rating), 1) FROM reviews WHERE product_id = {product_id}")).first()[0]

    # image data. Index like this imageData[0][ii['file_path']]
    imageData = conn.execute(text(f"SELECT variant_id, file_path FROM images WHERE variant_id = {variant_id}")).all()



    if request.method == "GET":
        return render_template("product.html", error=error, product_id=product_id, 
                            productData=productData, pi=pi,
                            variant_id=variant_id, variantData=variantData, vi=vi, imageData=imageData, ii=ii,
                            allVariantData=allVariantData, allDiscountData=allDiscountData, reviewsAvg=reviewsAvg,
                            reviewsData=reviewsData, ri=ri, getCurrentType=getCurrentType(),
                            bestDiscount=bestDiscount, email=email)

    elif request.method == "POST":
        amount = request.form.get("number")
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
                if variant[0] == variant_id:
                    inCart = True
                    break


            if not inCart:
                conn.execute(text(
                    "INSERT INTO cart_items (cart_id, variant_id, quantity)"
                f"VALUES ({cartId}, {variant_id}, {amount})"))
            else:
                conn.execute(text("UPDATE cart_items "
                                f"SET quantity = (quantity + {amount})"
                                f"WHERE cart_id = {cartId} AND variant_id = {variant_id}"))
            conn.commit()

        return render_template("product.html", error=error, product_id=product_id,    
                            productData=productData, pi=pi,
                            variant_id=variant_id, variantData=variantData, vi=vi, imageData=imageData, ii=ii,
                            allVariantData=allVariantData, allDiscountData=allDiscountData, reviewsAvg=reviewsAvg,
                            reviewsData=reviewsData, ri=ri, getCurrentType=getCurrentType(),
                            bestDiscount=bestDiscount, email=email)


@product_bp.route("/product/<int:product_id>/<int:variant_id>/review", methods=["POST"])
def submitReview(product_id, variant_id):
    rating = int(request.form.get('rating'))
    desc = request.form.get('description', None)
    url = request.form.get('image', None)
    reviewExists = bool(conn.execute(text("SELECT review_id FROM reviews "
        f"WHERE product_id = {product_id} AND customer_email = '{current_user.email}'"
        )).first())

    if reviewExists:
        return redirect(url_for("product.product", product_id=product_id, variant_id=variant_id))

    if  (rating >= 1 and rating <= 5 ) and \
        not (desc and len(desc) > 500) and \
        not (url and len(url) > 255
    ):
        print(f"\n\n\nTo else\n\n\n")
        conn.execute(text(f"INSERT INTO reviews (customer_email, product_id, rating\
                        {', description' if desc else ''} {', image' if url else ''}) "
                        "VALUES (:email, :product_id, :rating "
                        f"{', :desc' if desc else ''}{', :url' if url else ''})"),
                        {'email': current_user.email, 'product_id': product_id, 
                        'rating': rating, 'desc': desc, 'url': url})
        conn.commit()

    return redirect(url_for("product.product", product_id=product_id, variant_id=variant_id))

@product_bp.route("/product/<int:product_id>/<int:variant_id>/<int:review_id>", methods=["POST"])
def reviewDelete(product_id, variant_id, review_id):
    review_email = conn.execute(text("SELECT customer_email FROM reviews "
                                     f"WHERE review_id = {review_id}")).first()[0]
    print(review_email)
    if review_email != current_user.email:
        return redirect(url_for("product.product", product_id=product_id, variant_id=variant_id))

    try:
        conn.execute(text(f"DELETE FROM reviews WHERE review_id = {review_id}"))
        conn.commit()
    except Exception as e:
        print("\n" + str(e) + "\n")


    return redirect(url_for("product.product", product_id=product_id, variant_id=variant_id))