from flask import Blueprint, render_template, request, redirect, url_for
from flask_login import current_user, login_required
from sqlalchemy import text
from extensions import conn, getCurrentType

product_manage_bp = Blueprint("product_manage", __name__, 
                        static_folder="static_product_manage",
                        template_folder="templates_product_manage")


@product_manage_bp.route("/manage", methods=["GET"])
@login_required
def manage():
    if current_user.type == "customer":
        return redirect(url_for('login.login'))

    
    return render_template("product_manage.html", type=current_user.type)


@product_manage_bp.route("/manage/add", methods=["POST"])
@login_required
def create():
    print(request.form)
    vendor_id = current_user.email if current_user.type == "vendor" else request.form.get("vendor_id")
    title = request.form.get("title")
    desc = request.form.get("description")
    warranty_months = request.form.get("warranty_months")
    if warranty_months == 0 or warranty_months == "":   
        warranty_months = "NULL"
    conn.execute(text("INSERT INTO products (vendor_id, product_title, "
                      "product_description, warranty_months) " \
                      f"VALUES ('{vendor_id}', '{title}', '{desc}', {warranty_months})"))
    conn.commit()
    return redirect(url_for("product_manage.manage"))