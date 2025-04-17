from flask import Blueprint, render_template, request, url_for, redirect
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from sqlalchemy import text, insert, Table, MetaData, update
from extensions import Users, bcrypt, conn

product_bp = Blueprint("product", __name__, static_folder="static",
                  template_folder="templates")


@product_bp.route("/product/<int:productId>", methods=["GET", "POST"])
def product(productId):
    error_404 = True
    pi = { # product indexes
        'product_id': 0,
        'vendor_id': 1,
        'product_title': 2,
        'product_description': 3,
        'warranty_months': 4
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
    productData = conn.execute(text(
        "SELECT product_id, vendor_id, product_title, "
        "product_description, warranty_months FROM products")).all()
    variantData = conn.execute(text(
        "SELECT variant_id, product_id, color_id, size_id, "
        "price, current_inventory, color_name, size_description "
        "FROM product_variants NATURAL JOIN colors NATURAL JOIN sizes")).all()

    print(productData)
    print(variantData)

    for product in productData:
        if product[pi['product_id']] == productId:
            error_404 = False
            break
    if error_404:
        return "Page not found :("
    if request.method == "POST":
        return
    return render_template("product.html", productId=productId, productData=productData, pi=pi,
                           variantData=variantData, vi=vi)
