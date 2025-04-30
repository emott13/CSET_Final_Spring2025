from flask import Blueprint, render_template, request, redirect, url_for
from flask_login import current_user, login_required
from sqlalchemy import text
from extensions import conn, getCurrentType

product_manage_bp = Blueprint("product_manage", __name__, 
                        static_folder="static_product_manage",
                        template_folder="templates_product_manage")


@product_manage_bp.route("/manage", methods=["GET"])
@product_manage_bp.route("/manage/<error>", methods=["GET"])
@login_required
def manage(error=None):
    if current_user.type == "customer":
        return redirect(url_for('login.login'))

    return render_template("product_manage.html", type=current_user.type, error=error)


@product_manage_bp.route("/manage/add", methods=["POST"])
@login_required
def create():
    error = None
    vendor_id = current_user.email if current_user.type == "vendor" else request.form.get("vendor_id")
    title = request.form.get("title")
    desc = request.form.get("description")
    warranty_months = request.form.get("warranty_months")

    # error checks
    vendorExists = conn.execute(text(f"SELECT email FROM users WHERE email = '{vendor_id}'")).first()
    print(vendorExists)
    if len(vendor_id) > 255 or not vendorExists:
        error = "Invalid vendor email" 
    elif len(title) > 255:
        error = "Title is too long"
    elif len(desc) > 500:
        error = "Description is too long"
    elif not warranty_months.isdigit() or int(warranty_months) > 2147483647 \
        or int(warranty_months) < -2147483648:
        error = "Invalid warranty"


    if error:
        return redirect(url_for("product_manage.manage", error=error))

    if warranty_months == 0 or warranty_months == "":   
        warranty_months = "NULL"
    try:
        conn.execute(text("INSERT INTO products (vendor_id, product_title, "
                        "product_description, warranty_months) " \
                        f"VALUES ('{vendor_id}', '{title}', '{desc}', {warranty_months})"))
        conn.commit()
    except:
        return redirect(url_for("product_manage.manage", error="Unknown error"))

    return redirect(url_for("product_manage.manage"))