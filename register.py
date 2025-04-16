from flask import Blueprint, render_template, request, url_for, redirect
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from extensions import Users, db, bcrypt, getCurrentType

register_bp = Blueprint("register", __name__, static_folder="static",
                  template_folder="templates")

@register_bp.route("/register", methods=["GET", "POST"])
def register():
    isAdmin = current_user.is_authenticated and current_user.type == 'admin'
    if request.method == "POST":
        email = request.form.get('email')
        username = request.form.get('username')
        password = request.form.get('password')
        repassword = request.form.get('re-password')
        first_name = request.form.get('first_name')
        last_name = request.form.get('last_name')
        type = request.form.get('type')

        error = ""
        # Check if the values are not null (tampered with website)
        if not email or not username or not password \
            or not first_name or not last_name or not type:
            error = "Error: Invalid input"
        elif Users.query.filter_by(email=email).first():
            error = "Error: Email already exists"
        elif email.find('@') == -1 or email.find('.') == -1:
            error = "Error: Invalid email"
        elif Users.query.filter_by(username=username).first():
            error = "Error: Username already exists"
        elif password != repassword:
            error = "Error: Passwords do not match"
        elif getCurrentType() == 'admin':
            error = "Error: Insufficient permissions"

        if error:
            return render_template("register.html", error=error, isAdmin=isAdmin)

        # if there is still an error after the checks
        try:
            hashed_pswd = bcrypt.generate_password_hash(request.form.get('password')).decode('utf-8')
            new_user = Users(email=email, username=username, hashed_pswd=hashed_pswd, 
                            first_name=first_name, last_name=last_name, type=type)
            db.session.add(new_user)
            db.session.commit()

            return render_template("register.html", success="Created account. <a href=\"/login\">Login</a>", isAdmin=isAdmin) 
        except:
            return render_template("register.html", error="Error", isAdmin=isAdmin)

    return render_template("register.html", isAdmin = isAdmin)