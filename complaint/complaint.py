from flask import Blueprint, render_template, request, redirect, url_for
from flask_login import current_user, login_required
from sqlalchemy import text
from extensions import conn, dict_db_data, getCurrentType

complaint_bp = Blueprint('complaint', __name__, static_folder='static_complaint', 
                         template_folder='templates_complaint', url_prefix="/complaint")

@complaint_bp.route("/", methods=["GET"])
@login_required
def complaint():
    if getCurrentType() == "admin":
        return redirect(url_for("complaint.admin"))
    complaints = dict_db_data('complaints', f"WHERE submitted_by = '{current_user.email}'")
    print(complaints)
    return render_template("complaint.html", complaints=complaints)

@complaint_bp.route("/admin/", methods=["GET"])
@login_required
def admin():
    if getCurrentType() != "admin":
        return redirect(url_for("home.home"))

    complaints = dict_db_data('complaints', "ORDER BY date DESC")
    statuses = sql_enum_list(
        conn.execute(text("SHOW COLUMNS FROM complaints LIKE 'status'")).all()[0][1])
    error = request.args.get("error")

    return render_template("admin.html", complaints=complaints, statuses=statuses, error=error)

@complaint_bp.route("/admin/update/<int:complaintId>", methods=["POST"])
@login_required
def updateStatus(complaintId):
    if getCurrentType() != "admin":
        return redirect(url_for("home.home"))

    statuses = sql_enum_list(
        conn.execute(text("SHOW COLUMNS FROM complaints LIKE 'status'")).all()[0][1])
    newStatus = request.form.get("status")
    error = None

    if newStatus not in statuses:
        error = "Invalid status"
    if error:
        return redirect(url_for("complaint.admin", error=error))

    try:
        conn.execute(text("UPDATE complaints " +
            "SET status = :newStatus WHERE complaint_id = :complaintId"),
            {'newStatus': newStatus, 'complaintId': complaintId})
        conn.commit()
    except Exception as e:
        print(f"\n {e} \n")
        return redirect(url_for("complaint.admin", error="Unknown"))

    return redirect(url_for("complaint.admin"))

@complaint_bp.route('/create/<int:orderId>', methods=["GET", "POST"])
@login_required
def create(orderId):
    order = dict_db_data("orders", f"WHERE order_id = {orderId}")[0]
    demands = sql_enum_list( 
        conn.execute(text("SHOW COLUMNS FROM complaints LIKE 'demand'")).all()[0][1] 
    )
    title = request.form.get("title")
    desc = request.form.get("description")
    demand = request.form.get("demand")
    error = request.args.get("error")
    success = request.args.get("success")

    if request.method == "POST":
        try:
            conn.execute(text("INSERT INTO complaints (submitted_by, "
                "title, description, demand, status, order_id)"
                "VALUES (:submitted_by, :title, :desc, :demand, " \
                "'pending', :order_id)"), 
                {'submitted_by': current_user.email, 'title': title, 
                'desc': desc, 'demand': demand, 'order_id': orderId})
            conn.commit()
            success = f"Success. Complaint successfully submitted. <br>View all your complaints <a href=\"{url_for('complaint.complaint')}\">Here</a>"
        except Exception as e:
            print("\n" + str(e) + "\n")
            return redirect(url_for("complaint.create", orderId=orderId, error="Error"))
            
    return render_template("create.html", orderId=orderId, order=order, demands=demands, error=error, success=success)
        


def sql_enum_list(enum: str) -> list:
    arr = []
    for item in enum[5:-1].split(','):
        arr.append(item.replace("'", ""))
    return arr