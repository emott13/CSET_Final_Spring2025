from flask import Flask, render_template, request, url_for, redirect
from sqlalchemy import create_engine, text, insert, Table, MetaData, update
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from scripts.shhhh_its_a_secret import customHash
# from werkzeug.security import generate_password_hash, check_password_hash
from login import login_bp
from extensions import *

# -- LOGIN PAGE -- #
app.register_blueprint(login_bp)

# -- SIGNUP PAGE -- #
@app.route("/signup", methods=["GET", "POST"])
def signup():
    if request.method == "POST":
        email = request.form.get('email')
        username = request.form.get('username')
        hashed_pswd = customHash(request.form.get('password'))
        first_name = request.form.get('first_name')
        last_name = request.form.get('last_name')
        type = request.form.get('type')

        # Check if the values are not null (tampered with website)
        if not email or not username or not hashed_pswd \
            or not first_name or not last_name or not type:
            return render_template("signup.html", error="Error: Invalid input")
        elif Users.query.filter_by(email=email).first():
            return render_template("signup.html", error="Error: Email already exists")
        elif Users.query.filter_by(username=username).first():
            return render_template("signup.html", error="Error: Username already exists")

        new_user = Users(email=email, username=username, hashed_pswd=hashed_pswd, 
                        first_name=first_name, last_name=last_name, type=type)
        db.session.add(new_user)
        db.session.commit()
        return render_template("signup.html", success="Created account. <a href=\"/login\">Login</a>") 

    return render_template("signup.html")

# -- TEST PAGE -- #
# Shows current_user data (whoever is logged in)
@app.route("/test")
@login_required
def test():
    return render_template("test.html", current_user=current_user)

# -- LOGOUT PAGE -- #
@app.route("/logout")
@login_required
def logout():
    logout_user()
    return redirect(url_for("login.login"))


if __name__ == '__main__':
    app.run(debug=True)