from flask import Flask, render_template, request, url_for, redirect
from sqlalchemy import create_engine, text, insert, Table, MetaData, update
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from extensions import *
from login import login_bp
from register import register_bp
from product import product_bp

# -- LOGIN PAGE -- #
app.register_blueprint(login_bp)

# -- SIGNUP PAGE -- #
app.register_blueprint(register_bp)

# -- PRODUCT PAGE -- #
app.register_blueprint(product_bp)

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

# -- HOME PAGE -- #
@app.route('/home')
def home():
    return render_template('home.html')


if __name__ == '__main__':
    app.run(debug=True)