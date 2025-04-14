from flask import Blueprint, render_template, request, url_for, redirect
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from scripts.shhhh_its_a_secret import customHash
from extensions import Users, db, bcrypt

register_bp = Blueprint("register", __name__, static_folder="static",
                  template_folder="templates")

@register_bp.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        email = request.form.get('email')
        username = request.form.get('username')
        hashed_pswd = bcrypt.generate_password_hash(request.form.get('password')).decode('utf-8')
        first_name = request.form.get('first_name')
        last_name = request.form.get('last_name')
        type = request.form.get('type')

        # Check if the values are not null (tampered with website)
        if not email or not username or not request.form.get('password') \
            or not first_name or not last_name or not type:
            return render_template("register.html", error="Error: Invalid input")
        elif Users.query.filter_by(email=email).first():
            return render_template("register.html", error="Error: Email already exists")
        elif Users.query.filter_by(username=username).first():
            return render_template("register.html", error="Error: Username already exists")

        new_user = Users(email=email, username=username, hashed_pswd=hashed_pswd, 
                        first_name=first_name, last_name=last_name, type=type)
        db.session.add(new_user)
        db.session.commit()
        return render_template("register.html", success="Created account. <a href=\"/login\">Login</a>") 

    return render_template("register.html")