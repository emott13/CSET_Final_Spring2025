from flask import Blueprint, render_template
from sqlalchemy import text
from extensions import conn, dict_db_data

complaint_bp = Blueprint('complaint', __name__, static_folder='static_complaint', template_folder='templates_complaint')

@complaint_bp.route('/complaint/<int:orderId>')
def complaint(orderId):
    order = dict_db_data("orders", f"WHERE order_id = {orderId}")[0]
    print(order)
    return render_template("complaint.html", order=order)