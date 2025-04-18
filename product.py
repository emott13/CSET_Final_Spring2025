from flask import Blueprint, render_template, request, url_for, redirect
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from sqlalchemy import text, insert, Table, MetaData, update
from extensions import Users, bcrypt, conn

product_bp = Blueprint("product", __name__, static_folder="static",
                  template_folder="templates")

def isValidProductURL(productId, variantId=None, sizeId=None, colorId=None):
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
        f"SELECT variant_id, size_id, color_id FROM product_variants "
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

    sizeValue = sizeId
    # if sizeId and variantId exist. Sets sizeValue to either the 
    # current sizeId (if valid), or a valid sizeId
    if sizeId:
        # checks if the sizeId is in the sizes table with the correct product ID
        sizeExists = False
        for variant in productVariants:
            if sizeId == variant[1]:
                sizeExists = True
                break

        if not sizeExists:
            sizeValue = productVariants[0][1] # sets the variable to the first variant
            isValid = False
    else:
        isValid = False
        sizeValue = productVariants[0][1] # sets the variable to the first variant

    colorValue = colorId
    # if colorId and variantId exist. Sets colorValue to either the 
    # current colorId (if valid), or a valid colorId
    if colorId:
        # checks if the colorId is in the colors table with the correct product ID
        colorExists = False
        for variant in productVariants:
            if colorId == variant[2]:
                colorExists = True
                break

        if not colorExists:
            colorValue = productVariants[0][2] # sets the variable to the first variant
            isValid = False
    else:
        isValid = False
        colorValue = productVariants[0][2] # sets the variable to the first variant
    
    print("variantValue")
    print(variantValue)
    print("sizeValue")
    print(sizeValue)
    print("sizeId")
    print(sizeId)
    print("colorValue")
    print(colorValue)

    if isValid:
        return None
    else:
        return f"/product/{productId}/{variantValue}/{sizeValue}/{colorValue}"
        

@product_bp.route("/product/<int:productId>/", methods=["GET", "POST"])
@product_bp.route("/product/<int:productId>/<int:variantId>/", methods=["GET", "POST"])
@product_bp.route("/product/<int:productId>/<int:variantId>/<int:sizeId>/", methods=["GET", "POST"])
@product_bp.route("/product/<int:productId>/<int:variantId>/<int:sizeId>/<int:colorId>", 
                  methods=["GET", "POST"])
def product(productId, variantId=None, sizeId=None, colorId=None):
    # Returns 404 (productId doesn't exist), new URL (if the parameters are invalid),
    # or None (parameters are already fine)
    invalidURL = isValidProductURL(productId, variantId, sizeId, colorId)
    print(f"invalidURL: {invalidURL}")
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
    # variant data. Index like this variantData[vi['price']]
    variantData = conn.execute(text(
        "SELECT variant_id, product_id, color_id, size_id, "
        "price, current_inventory, color_name, size_description "
        "FROM product_variants NATURAL JOIN colors NATURAL JOIN sizes " \
        f"WHERE product_id = {productId} AND variant_id = {variantId}")).first()
    allVariantData = conn.execute(text(
        "SELECT variant_id, product_id, color_id, size_id, "
        "price, current_inventory, color_name, size_description "
        "FROM product_variants NATURAL JOIN colors NATURAL JOIN sizes " \
        f"WHERE product_id = {productId}")).all()

    # image data. Index like this imageData[0][ii['file_path']]
    imageData = conn.execute(text(f"SELECT variant_id, file_path FROM images WHERE variant_id = {variantId}")).all()

    # print(f"productData: i\n{productData}")
    # print(f"variantData: \n{variantData}")
    # print(f"imageData: \n{imageData}")


    if request.method == "POST":
        return
    return render_template("product.html", productId=productId, productData=productData, pi=pi,
                           variantData=variantData, vi=vi, imageData=imageData, ii=ii,
                           allVariantData=allVariantData)

