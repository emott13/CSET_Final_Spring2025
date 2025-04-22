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

# -- SEARCH PAGE -- #
@app.route('/search', methods=['GET', 'POST'])
def search():
    productIDs = conn.execute(
        text('SELECT product_id FROM products;')).fetchall()
    productOptions = conn.execute(
        text(''' 
            SELECT product_id, COUNT(variant_id)
            FROM product_variants GROUP BY product_id
            ORDER BY product_id;
            ''')).fetchall()
    productPriceRange = []
    for id_tuple in productIDs:
        id = id_tuple[0]
        productTS = conn.execute(
        text('''
            SELECT p.product_id, p.product_title
            FROM products p
            INNER JOIN product_variants pv ON p.product_id = pv.product_id
            INNER JOIN sizes s ON pv.size_id = s.size_id
            WHERE p.product_id IN :ids;
        '''),
        {'ids': tuple(pid[0] for pid in productIDs)}).fetchall()
        prodPR = conn.execute(
            text('''
                SELECT MIN(price), MAX(price)
                FROM product_variants
                WHERE product_id = :id;
                 '''), {'id': id}).fetchone()
        productPriceRange.append((id, prodPR[0], prodPR[1]))

    productTS_map = {
        int(pid): (title or 'No Title')
        for pid, title in productTS if pid is not None
    }
    productOptions_map = {int(pid): count for pid, count in productOptions if pid is not None}
    productPrice_map = {
        int(pid): (min_price, max_price) 
        for pid, min_price, max_price in productPriceRange if pid is not None
    }

    products = []
    for id_tuple in productIDs:
        pid = int(id_tuple[0])
        title = productTS_map.get(pid, ('No title'))
        options = productOptions_map.get(pid, 0)
        if pid in productPrice_map:
            min_price, max_price = productPrice_map[pid]
            min_price, max_price = min_price / 100, max_price / 100
            price = f"${min_price:.2f}" if min_price == max_price else f"${min_price:.2f} - ${max_price:.2f}"
        else:
            price = "N/A"
        if pid != 850561 and pid != 850562:
            products.append({
                'id': pid,
                'title': title,
                'options': options,
                'price': price
            })

    if request.method == 'POST':
        searchInput = request.form['product_search']
        print(searchInput)
        return render_template('search.html', products = products)
    if request.method == 'GET':
        return render_template('search.html', products = products)

if __name__ == '__main__':
    app.run(debug=True)