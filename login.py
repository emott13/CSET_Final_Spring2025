from flask import Blueprint, render_template, request, url_for, redirect
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from scripts.shhhh_its_a_secret import customHash
from extensions import Users, bcrypt

login_bp = Blueprint("login", __name__, static_folder="static",
                  template_folder="templates")


@login_bp.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        email = request.form.get("username")
        password = request.form.get("password")

        if not email or not password:
            return render_template("login.html", error="Invalid input")

        user = Users.query.filter_by(email=email).first()
        user_username = Users.query.filter_by(username=email).first()
        print(bcrypt.generate_password_hash(password).decode('utf-8'))

        # first checks email, then checks username
        if user and bcrypt.check_password_hash(user.hashed_pswd, password):
            login_user(user)
            return redirect(url_for("test"))
        elif user_username and bcrypt.check_password_hash(user_username.hashed_pswd, password):
            login_user(user_username)
            return redirect(url_for("test"))
        
        else:
            return render_template("login.html", error="Invalid username or password")

    return render_template("login.html")
