from flask import Blueprint, render_template, request, url_for, redirect
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from sqlalchemy import text, insert, Table, MetaData, update
from extensions import Users, bcrypt, conn

product_bp = Blueprint("product", __name__, static_folder="static",
                  template_folder="templates")


@product_bp.route("/product/<int:productId>/", methods=["GET", "POST"])
@product_bp.route("/product/<int:productId>/<int:variantId>/", methods=["GET", "POST"])
def product(productId, variantId=None):
    error_404 = False
    variantExists = False
    productVariants =  conn.execute(text(
        f"SELECT variant_id FROM product_variants "
        f"WHERE product_id = {productId}")
        ).all()

    # check if the product ID exists
    if conn.execute(text(
        f"SELECT product_id FROM products WHERE product_id = {productId}")
        ).all() == []:
        error_404 = True

    if error_404:
        return "Page not found :("
        
    # checks if the variantId is in the variants table with the correct product ID
    for variant in productVariants:
        if variantId == variant[0]:
            variantExists = True
            break

    # If the variantId doesn't exist (or empty)
    if not variantExists:
        return redirect(f"/product/{productId}/{productVariants[0][0]}")
        

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
        'size_description': 7
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
    # variant data. Index like this variantData[0][vi['price']]
    variantData = conn.execute(text(
        "SELECT variant_id, product_id, color_id, size_id, "
        "price, current_inventory, color_name, size_description "
        "FROM product_variants NATURAL JOIN colors NATURAL JOIN sizes " \
        f"WHERE product_id = {productId} AND variant_id = {variantId}")).all()

    # image data. Index like this imageData[0][ii['file_path']]
    imageData = conn.execute(text(f"SELECT variant_id, file_path FROM images WHERE variant_id = {variantId}")).all()

    print(f"productData: i\n{productData}")
    print(f"variantData: \n{variantData}")
    print(f"imageData: \n{imageData}")


    if request.method == "POST":
        return
    return render_template("product.html", productId=productId, productData=productData, pi=pi,
                           variantData=variantData, vi=vi, imageData=imageData, ii=ii)
