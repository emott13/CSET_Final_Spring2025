from flask import Blueprint, render_template, request
from sqlalchemy import text
from extensions import conn

search_bp = Blueprint('search', __name__, static_folder='static_search', template_folder='templates_search')

# -- SEARCH PAGE -- #
@search_bp.route('/search/search.py', methods=['GET', 'POST'])
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
    

# -- FUNCTIONS -- #

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