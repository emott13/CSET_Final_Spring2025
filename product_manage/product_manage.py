from flask import Blueprint, render_template, request, redirect, url_for
from flask_login import current_user, login_required
from sqlalchemy import text
from extensions import conn, getCurrentType, dict_db_data

product_manage_bp = Blueprint("product_manage", __name__, 
                        static_folder="static_product_manage",
                        template_folder="templates_product_manage")


@product_manage_bp.route("/manage", methods=["GET"])
@product_manage_bp.route("/manage/<error>", methods=["GET"])
@login_required
def manage(error=None):
    if current_user.type == "customer":
        return redirect(url_for('login.login'))

    productData = dict_db_data("products", f"WHERE vendor_id = '{current_user.email}'")
    categoryData = dict_db_data("categories")
    colorData = dict_db_data("colors")
    imageData = dict_db_data("images")
    variantData = dict_db_data("product_variants", 
        f"NATURAL JOIN products NATURAL JOIN colors NATURAL JOIN sizes WHERE vendor_id = '{current_user.email}'", 
        select="color_name, color_hex, size_description")

    productIdVariants = dict()
    for variant in variantData:
        if variant['product_id'] in productIdVariants.keys():
            productIdVariants[variant['product_id']].append(variant)
        else:
            productIdVariants[variant['product_id']] = [variant]


    return render_template("product_manage.html", type=current_user.type, error=error,
        productData=productData, categoryData=categoryData, colorData=colorData, 
        productIdVariants=productIdVariants, imageData=imageData)

@product_manage_bp.route("/manage/add/<method>", methods=["POST"])
@product_manage_bp.route("/manage/add/<method>/<productId>", methods=["POST"])
@login_required
def product(method, productId=None):
    vendor_id = current_user.email if current_user.type == "vendor" else request.form.get("vendor_id")
    title = request.form.get("title")
    desc = request.form.get("description")
    warranty_months = request.form.get("warranty_months")
    category = request.form.get("category")

    # error checks
    error = productChecks(vendor_id, title, desc, warranty_months, category)

    if error:
        return redirect(url_for("product_manage.manage", error=error))

    if warranty_months == 0 or warranty_months == "":   
        warranty_months = "NULL"
    try:
        if method == "create":
            conn.execute(text(
                "INSERT INTO products (vendor_id, product_title, "
                "product_description, warranty_months, cat_num) "
                f"VALUES ('{vendor_id}', '{title}', '{desc}', {warranty_months}, {category})"))
        elif method == "edit":
            conn.execute(text(
                f"UPDATE products SET product_title='{title}', product_description='{desc}', "
                f"warranty_months={warranty_months}, cat_num={category} "
                f"WHERE product_id={productId}"))
        conn.commit()
    except Exception as e:
        print(e)
        return redirect(url_for("product_manage.manage", error="Unknown error"))

    return redirect(url_for("product_manage.manage"))

@product_manage_bp.route("/manage/delete/<productId>", methods=["POST"])
@login_required
def productDelete(productId):
    error = None
    if request.form.get("delete") == "I WANT TO DELETE THIS PRODUCT":
        conn.execute(text(f"DELETE FROM products WHERE product_id = {productId}"))
        conn.commit()
    else:
        error = "Invalid deletion confirmation text"
    return redirect(url_for("product_manage.manage", error=error))


@product_manage_bp.route("/manage/variant/<method>/<productId>", methods=["POST"])
@product_manage_bp.route("/manage/variant/<method>/<productId>/<variantId>", methods=["POST"])
@login_required
def variant(method, productId, variantId=None):
    colorSelect = request.form.get("color-select")
    size = request.form.get("size")
    price = request.form.get("price").replace("$", "")
    inventory = request.form.get("inventory")
    urls = request.form.getlist("url")

    print("form:")
    print(request.form)

    error = variantChecks(colorSelect, size, price, inventory, urls)

    if error:
        return redirect(url_for("product_manage.manage", error=error))

    if not (
        conn.execute(text(
        f"SELECT size_id FROM sizes WHERE size_description = '{size}'")).first()
        ):
        conn.execute(text("INSERT INTO sizes (size_description) "
                          f"VALUES ('{size}')")) 
        conn.commit()
    sizeId = conn.execute(text(
        f"SELECT size_id FROM sizes WHERE size_description = '{size}'")).first()[0]

    price = int( float(price) * 100 )

    try:
        if method == "create":
            conn.execute(text(
                "INSERT INTO product_variants (product_id, color_id, size_id, price, current_inventory) "
                f"VALUES ({productId}, {colorSelect}, {sizeId}, {price}, {inventory})"))

            variantId = conn.execute(text("SELECT LAST_INSERT_ID()")).first()[0]
            imageValues = ""
            comma = False
            for url in urls:
                if url:
                    if comma:
                        imageValues += ", "
                    imageValues += f"({variantId}, '{url}')"
                    comma = True
            print(imageValues)

            conn.execute(text(
                "INSERT INTO images (variant_id, file_path) "
                f"VALUES {imageValues}")) 
        elif method == "edit":
            conn.execute(text(
                
            ))
        conn.commit()
    except Exception as e:
        print("\n" + str(e) + "\n")
        return redirect(url_for("product_manage.manage", error="Unknown error"))
     
    return redirect(url_for("product_manage.manage"))

@product_manage_bp.route("/manage/variantDelete/<variantId>", methods=["POST"])
@login_required
def variantDelete(variantId=None):
    return redirect(url_for("product_manage.manage"))

@product_manage_bp.route("/manage/create-color", methods=["POST"])
@login_required
def createColor():
    colorName = request.form.get("color-name")
    colorHex = request.form.get("color-hex")
    colors = dict_db_data("colors")
    
    error = None
    colorExists = False
    for color in colors:
        if colorName == color['color_name']:
            colorExists = True
            break
    if colorExists:
        error = "Color already exists"
    elif len(colorName) > 50:
        error = "Color name is too long (max 50 characters)"
    elif len(colorHex) > 9 or colorHex[0] != "#" or not len(colorHex) in [4, 5, 7, 9]:
        error = "Invalid color hex" 
    
    if error:
        return redirect(url_for("product_manage.manage", error=error))

    try:
        conn.execute(text(
            "INSERT INTO colors (color_name, color_hex)"
            f"VALUES ('{colorName}', '{colorHex}')"))
        conn.commit()

        return redirect(url_for("product_manage.manage"))
    except Exception as e:
        print(e)
        return redirect(url_for("product_manage.manage", error="Unknown error"))

    




def productChecks(vendor_id, title, desc, warranty_months, category):
    vendorExists = conn.execute(text(
        f"SELECT email FROM users WHERE email = '{vendor_id}'")).first()
    categoryExists = conn.execute(text(
        f"SELECT cat_num FROM categories WHERE cat_num = {category}")).first()

    if not vendor_id or len(vendor_id) > 255 or not vendorExists:
        return "Invalid vendor email" 
    elif not title or len(title) > 255:
        return "Title is too long"
    elif not desc or len(desc) > 500:
        return "Description is too long"
    elif not warranty_months or not warranty_months.isdigit() or int(warranty_months) > 2147483647 \
        or int(warranty_months) < -2147483648:
        return "Invalid warranty"
    elif not category or not categoryExists:
        return "Invalid category"
    return None

def variantChecks(colorSelect, size, price, inventory, urls):
    colors = dict_db_data("colors")
    # check if the values exist
    if not colorSelect or not size or not price or not inventory or not urls:
        return "A value was not entered"

    containsColor = False
    for color in colors:
        if int(colorSelect) == int(color['color_id']):
            containsColor = True
            break
    if not containsColor or not colorSelect.isdigit():
        return "Invalid color"

    if len(size) > 100:
        return "Size is too long (max 100 characters)"
    elif not price.replace(".", "").isdigit() or int(float(price)*100) > 2147483647 or int(float(price)*100) < -2147483648:
        return "Invalid price"
    elif not inventory.isdigit() or int(inventory) > 2147483647 or int(inventory) < 0:
        return "Invalid inventory"
    for url in urls:
        if len(url) > 500:
            return "Invalid URL"
        
    return None