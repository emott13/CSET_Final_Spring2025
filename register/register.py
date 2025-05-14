from flask import Blueprint, render_template, request, url_for, redirect
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from sqlalchemy import text
from extensions import Users, db, bcrypt, getCurrentType, conn, dict_db_data
register_bp = Blueprint("register", __name__, static_folder="static",
                  template_folder="templates_register")

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
        elif conn.execute(text("SELECT email FROM admin_appli WHERE email = :email"), 
            {'email': email}).first():
            error = "Error: Email already pending"
        elif email.find('@') == -1 or email.find('.') == -1:
            error = "Error: Invalid email"
        elif Users.query.filter_by(username=username).first():
            error = "Error: Username already exists"
        elif conn.execute(text("SELECT username FROM admin_appli WHERE username = :username"), 
            {'username': username}).first():
            error = "Error: Username already pending"
        elif password != repassword:
            error = "Error: Passwords do not match"
        # elif type == 'admin' and getCurrentType() != 'admin':
        #     error = "Error: Insufficient permissions"

        if error:
            return render_template("register.html", error=error, isAdmin=isAdmin)

        # if there is still an error after the checks
        try:
            hashed_pswd = bcrypt.generate_password_hash(request.form.get('password')).decode('utf-8')
            # If the user selected admin and they aren't an admin
            if type == 'admin' and getCurrentType() != 'admin':
                print("Making admin as a non-admin")
                conn.execute(text("INSERT INTO admin_appli "
                                  "VALUES (:email, :username, :hashed_pswd, :first_name, :last_name)"),
                                  {'email': email, 'username': username, 'hashed_pswd': hashed_pswd, 
                                   'first_name': first_name, 'last_name': last_name})
                conn.commit()
                success = "Successfully applied."
            else: # Either the user didn't select admin or the user is an admin so 
                #   they can create another admin account
                print("Making a normal account or admin as an admin")
                new_user = Users(email=email, username=username, hashed_pswd=hashed_pswd, 
                                first_name=first_name, last_name=last_name, type=type)
                db.session.add(new_user)
                db.session.commit()
                conn.commit()
                success = "Created account. <a href=\"/login\">Login</a>"

            return render_template("register.html", success=success, isAdmin=isAdmin) 
        except Exception as e:
            print(f"\n{e}\n")
            return render_template("register.html", error="Error", isAdmin=isAdmin)

    return render_template("register.html", isAdmin = isAdmin)

@register_bp.route("/register/applications", methods=["GET"])
@login_required
def applications():
    if getCurrentType() != 'admin':
        return redirect(url_for('login.login'))
    
    appli = dict_db_data('admin_appli')

    return render_template("applications.html", appli=appli)

@register_bp.route("/register/applications/<accept>/<string:email>", methods=["POST"])
@login_required
def applicationsPost(accept, email):
    if getCurrentType() != 'admin':
        return redirect(url_for('login.login'))
    print(accept)
    print(email)

    if accept == 'True':
        print('in accept')
        appli = conn.execute(text("SELECT username, hashed_pswd, first_name, last_name "
                                  "FROM admin_appli WHERE email = :email"), {'email': email}).first()
        username, hashed_pswd, first_name, last_name = appli[0], appli[1], appli[2], appli[3]
        new_user = Users(email=email, username=username, hashed_pswd=hashed_pswd, 
                        first_name=first_name, last_name=last_name, type='admin')
        db.session.add(new_user)
        db.session.commit()
    conn.execute(text("DELETE FROM admin_appli WHERE email = :email"), {'email': email})
    conn.commit()

    return redirect(url_for("register.applications"))