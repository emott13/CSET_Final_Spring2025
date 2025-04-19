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
    officeProdIDs = [100220, 100225, 100226, 100227, 100228, 100235, 100236, 100239, 100240]
    officePhotos = []
    for id in officeProdIDs:
        photo = conn.execute(
        text('SELECT product_title, size_description, file_path, alt_text ' \
        'FROM products natural join product_variants natural join sizes natural join images ' \
        'WHERE product_id IN(850565, 850566, 850567, 850568, 850569, 850570) ' \
        'AND variant_id=:id LIMIT 1'), {'id': id}).fetchone()
        officePhotos.append(photo)
    print('Office products: ', officePhotos)
    schoolSupplyProd = conn.execute(
            text('SELECT product_title, size_description, file_path, alt_text ' \
            'FROM products natural join product_variants natural join sizes natural join images ' \
            'WHERE vendor_id="g_pitts@supplies4school.org" and image_id IN(1, 3, 5, 7, 19, 21);'),
            {'id': id}).fetchall()
    
    print('school supplies:', schoolSupplyProd)
    print('first:', schoolSupplyProd[0])
    print('second:', schoolSupplyProd[1])
    print('third:', schoolSupplyProd[2])
    print('fourth:', schoolSupplyProd[3])
    print('fifth:', schoolSupplyProd[4])
    print('sixth:', schoolSupplyProd[5])
    return render_template('home.html', officePhotos = officePhotos, schoolSupplies = schoolSupplyProd)

@app.route('/search')
def search():
    return render_template('search.html')

if __name__ == '__main__':
    app.run(debug=True)