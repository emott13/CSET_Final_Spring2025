from flask import Blueprint, render_template, request, url_for, redirect
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from sqlalchemy import text, insert, Table, MetaData, update
from extensions import Users, bcrypt, conn

product_bp = Blueprint("product", __name__, static_folder="static",
                  template_folder="templates")

def isValidProductURL(productId, variantId=None):
    """
    Checks to make sure the product URL is correct. 
    If not, it either returns 404, the correct link, or None (link is correct)
    """
    # check if the product ID exists
    if conn.execute(text(
        f"SELECT product_id FROM products WHERE product_id = {productId}")
        ).all() == []:
        return 404

    isValid = True
    productVariants =  conn.execute(text(
        f"SELECT variant_id FROM product_variants "
        f"WHERE product_id = {productId}")
        ).all()


    variantValue = variantId
    # if variantId exists. Sets variantValue to either the current 
    # variantId (if valid), or a valid variantId
    if variantId:
        # checks if the variantId is in the variants table with the correct product ID
        variantExists = False
        for variant in productVariants:
            if variantId == variant[0]:
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
        return f"/product/{productId}/{variantValue}"
        

@product_bp.route("/product/<int:productId>/", methods=["GET", "POST"])
@product_bp.route("/product/<int:productId>/<int:variantId>", methods=["GET", "POST"])
def product(productId, variantId=None, error=None):
    print(error)
    # Returns 404 (productId doesn't exist), new URL (if the parameters are invalid),
    # or None (parameters are already fine)
    invalidURL = isValidProductURL(productId, variantId)
    if invalidURL == 404:
        return "Error: Page not found :("
    elif invalidURL:
        return redirect(invalidURL)

    pi = { # product indexes
        'product_id': 0,
        'vendor_id': 1,
        'product_title': 2,
        'product_description': 3,
        'warranty_months': 4,
        'username': 5
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
    # product data. Index like this productData[pi['product_title']]
    productData = conn.execute(text(
        "SELECT product_id, vendor_id, product_title, "
        "product_description, warranty_months, username FROM products "
        "JOIN users ON products.vendor_id = users.email "
        f"WHERE product_id = {productId}")).first()
    # variant data. Index like this variantData[vi['price']]
    variantData = conn.execute(text(
        "SELECT variant_id, product_id, color_id, size_id, "
        "price, current_inventory, color_name, color_hex, size_description "
        "FROM product_variants NATURAL JOIN colors NATURAL JOIN sizes " \
        f"WHERE product_id = {productId} AND variant_id = {variantId}")).first()
    # all variant data. Index like this variantData[<index>][vi['price']]
    allVariantData = conn.execute(text(
        "SELECT variant_id, product_id, color_id, size_id, "
        "price, current_inventory, color_name, color_hex, size_description "
        "FROM product_variants NATURAL JOIN colors NATURAL JOIN sizes " \
        f"WHERE product_id = {productId}")).all()
    allDiscountData = dict( conn.execute(text(
        "SELECT variant_id, MIN(discount_price) FROM discounts " \
        "NATURAL JOIN product_variants " \
        "WHERE (start_date <= NOW() OR start_date IS NULL) AND (end_date >= NOW() OR end_date IS NULL) " \
       f"AND (product_id = {productId}) " \
        "GROUP BY variant_id;"
    )).all() )

    # image data. Index like this imageData[0][ii['file_path']]
    imageData = conn.execute(text(f"SELECT variant_id, file_path FROM images WHERE variant_id = {variantId}")).all()
    print("Discount Data:")
    print(allDiscountData)
    if variantData[vi['variant_id']] in allDiscountData.keys():
        print(allDiscountData[ variantData[vi['variant_id']] ])
        print(variantData[vi['price']])


    if request.method == "GET":
        return render_template("product.html", error=error, productId=productId, productData=productData, pi=pi,
                            variantData=variantData, vi=vi, imageData=imageData, ii=ii,
                            allVariantData=allVariantData, allDiscountData=allDiscountData)
    elif request.method == "POST":
        print("POST")
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
            print(cartItemVariants)
            
            inCart = False
            for variant in cartItemVariants:
                if variant[0] == variantId:
                    inCart = True
                    break


            if not inCart:
                print("Variant_id not in cartItemsVariants")
                conn.execute(text(
                    "INSERT INTO cart_items (cart_id, variant_id, quantity)"
                f"VALUES ({cartId}, {variantId}, {amount})"))
            else:
                conn.execute(text("UPDATE cart_items "
                                f"SET quantity = (quantity + {amount})"
                                f"WHERE cart_id = {cartId} AND variant_id = {variantId}"))
            conn.commit()

            print(cartItemVariants)
        print(error)
        return render_template("product.html", error=error, productId=productId, productData=productData, pi=pi,
                            variantData=variantData, vi=vi, imageData=imageData, ii=ii,
                            allVariantData=allVariantData, allDiscountData=allDiscountData)

