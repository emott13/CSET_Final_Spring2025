from flask import Flask, render_template, request, url_for, redirect
from sqlalchemy import create_engine, text, insert, Table, MetaData, update
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from extensions import *
from login import login_bp
from register import register_bp
from product import product_bp
import json

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
    productVendor = conn.execute(
        text('''
            SELECT p.product_id, u.username
            FROM products p
            JOIN users u ON p.vendor_id = u.email
        ''')).fetchall()
    
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
    productVendor_map = {
    int(pid): username
    for pid, username in productVendor if pid is not None
    }

    products = []
    for id_tuple in productIDs:
        pid = int(id_tuple[0])
        vendor = productVendor_map.get(pid, 'No vendor') 
        title = productTS_map.get(pid, ('No title'))
        options = productOptions_map.get(pid, 0)
        if pid in productPrice_map:
            min_price, max_price = productPrice_map[pid]
            price = toDollar(min_price) if min_price == max_price else f"{toDollar(min_price)} - {toDollar(max_price)}"
        else:
            price = "N/A"
        if pid != 850561 and pid != 850562:
            products.append({
                'id': pid,
                'title': title,
                'options': options,
                'price': price,
                'vendor': vendor,
                'display': True
            })
    vendors = conn.execute(
        text('SELECT username, CONCAT(first_name, " ", last_name) FROM users WHERE type = "vendor";')).fetchall()
    
    if request.method == 'POST':

        formPrice = request.form.get('price')
        displayPrices(formPrice, products)

        formName = request.form.getlist('vendor-options') 
        displayVendors(formName, products)

        print('formname:', formName)
        formName_map = []

        for name in formName:
            for vendor in vendors:
                if vendor[0] == name:
                    brand = vendor[1]
            print('Name', name, 'Brand:', brand)
            formName_map.append((name, brand))

        return render_template(
            'search.html', 
            products = products,
            checkedVendors = formName_map,
            vendors = vendors, 
            priceValue = toDollar(formPrice, html=True),
            clearDisplay = 'block'
        )
    
    else:
        return render_template(
            'search.html', 
            products = products, 
            vendors = vendors, 
            priceValue = 1000,
            clearDisplay = 'none'
        )

def toCents(num):
    try:
        num.find('$') != -1
        numFloat = float(num.replace('$', ''))
    except:
        numFloat = int(num)
    return int(round(numFloat * 100))

def toDollar(num, html=False):
    try:
        numDollar = num / 100
    except:
        return num
    if html is False:
        return f'${numDollar:.2f}'
    elif html is True:
        return f'{numDollar:.2f}'

def getSecondPrice(string):
    priceList = string.split(' - ')
    try:
        price = priceList[1]
        # print('PRICE 163:', price)
        return price
    except IndexError:
        price = priceList[0]
        # print('PRICE 166:', price)
        return price
    except Exception:
        return '$00.00'

def displayVendors(formName, products):
    if formName != [] and formName is not None:
        for product in products:
            if product.get('vendor') not in formName:
                product.update({'display': False})

def displayPrices(formPrice, products):
    if formPrice != [] and formPrice is not None:
        for product in products:
            productPrice = getSecondPrice(product['price'])
            productPrice = toCents(productPrice)
            inputMaxPrice = toCents(formPrice)
            if productPrice > inputMaxPrice:
                product.update({'display': False})


if __name__ == '__main__':
    app.run(debug=True)