from main import Blueprint, render_template, request, text, conn

search_bp = Blueprint('search', __name__, static_folder='static_search', template_folder='templates_search')

# -- SEARCH PAGE -- #
@search_bp.route('/search/search.py', methods=['GET', 'POST'])
def search():
    # --- Fetch all product data at once ---
    product_data = conn.execute(text('''
        SELECT p.product_id, p.product_title, p.cat_num,
               MIN(v.price) AS min_price, MAX(v.price) AS max_price,
               u.username AS vendor_name
        FROM products p
        LEFT JOIN product_variants v ON p.product_id = v.product_id
        JOIN users u ON p.vendor_id = u.email
        GROUP BY p.product_id
        ORDER BY p.product_id
    ''')).fetchall()

    product_options = conn.execute(                                 # get variant counts
        text('''                         
        SELECT product_id, COUNT(variant_id) as option_count
        FROM product_variants
        GROUP BY product_id
    ''')).fetchall()
    option_map = {pid: count for pid, count in product_options}

    products = []                                                   # create product list
    for row in product_data:
        pid, title, cat_num, min_price, max_price, vendor = row
        if pid in (850561, 850562):                                 # skips unwanted products
            continue                                                # products will be removed from db later

        price = toDollar(min_price) if min_price == max_price \
            else f"{toDollar(min_price)} - {toDollar(max_price)}"

        products.append({                                           # append product dict to products list
            'id': pid,
            'title': title or 'No Title',
            'options': option_map.get(pid, 0),
            'price': price or 'N/A',
            'vendor': vendor or 'No Vendor',
            'category': cat_num,
            'display': True
        })


    vendors = conn.execute(                                         # fetch vendors
        text('''                                 
        SELECT username, CONCAT(first_name, " ", last_name) 
        FROM users WHERE type = "vendor"
    ''')).fetchall()

    category_queries = {                                            # seperate categories by cat_num range
        'SO': (1, 99),
        'SC': (100, 199),
        'OF': (200, 299),
        'TX': (300, 399),
        'TC': (400, 499),
        'FT': (500, 599)
    }
    categories = {}                                                 # create categories dictionary
    for key, (start, end) in category_queries.items():
        print('key', key)
        print('nums:', (start, end))
        categories[key] = conn.execute(text('''
            SELECT cat_num, cat_name 
            FROM categories
            WHERE cat_num BETWEEN :start AND :end
        '''), {'start': start, 'end': end}).fetchall()

    if request.method == 'POST':
        formCategories = request.form.getlist('categories')
        formPrice = request.form.get('price')
        formName = request.form.getlist('vendor-options')

        # -- handles navigation to page from search bar -- #
        if not formPrice and not formName and not formCategories:   
            return render_template(                                 # this code can potentially be removed when search
            'search.html',                                          # bar functionality has been completed
            products=products,
            vendors=vendors,
            categories=categories,
            priceValue=1000,
            clearDisplay='none'
        )
        print('********** made to filter')
        # -- handles product filtering -- #
        filterProducts(formName, formCategories, formPrice, products)

        print('# # # # # FORMS')
        print(formCategories)
        print(formPrice)
        print(formName)
        
        
        flattened_categories = {                                    # flatten the categories and map each cat_num
            num: catName
            for key, catList in categories.items()                  # iterate over categories
            for num, catName in catList                             # iterate over category numbers and names
        }
        checkedCategories = {}
        for num, catName in flattened_categories.items():
            print('num, catName in flattened_categories.items():', num, catName)
            if str(num) in formCategories:
                checkedCategories.update({num: catName})

        formName_map = []                                                       # map selected vendors for checkbox pre-filling
        for name in formName:
            brand = next((vendor[1] for vendor in vendors if vendor[0] == name), None)
            if brand:
                formName_map.append((name, brand))

        priceValue = toDollar(formPrice, html=True) if formPrice else 1000      # handle price slider or set initial value
        clearDisplay = 'block' if formPrice else 'none'

        return render_template(
            'search.html',
            products=products,
            vendors=vendors,
            categories=categories,
            checkedCategories=checkedCategories,
            checkedVendors=formName_map,
            priceValue=priceValue,
            clearDisplay=clearDisplay
        )

    # -- handles GET requests -- #
    return render_template(
        'search.html',
        products=products,
        vendors=vendors,
        categories=categories,
        priceValue=1000,
        clearDisplay='none'
    )






# @search_bp.route('/search/search.py', methods=['GET', 'POST'])
# def search():
#     productIDs = conn.execute(
#         text('SELECT product_id FROM products;')).fetchall()
#     productOptions = conn.execute(
#         text(''' 
#             SELECT product_id, COUNT(variant_id)
#             FROM product_variants GROUP BY product_id
#             ORDER BY product_id;
#             ''')).fetchall()
#     productPriceRange = []
#     productVendor = conn.execute(
#         text('''
#             SELECT p.product_id, u.username
#             FROM products p
#             JOIN users u ON p.vendor_id = u.email
#         ''')).fetchall()
    
#     for id_tuple in productIDs:
#         id = id_tuple[0]

#         productTS = conn.execute(
#             text('''
#                 SELECT product_id, product_title
#                 FROM products
#                 WHERE product_id IN :ids;
#             '''),
#         {'ids': tuple(pid[0] for pid in productIDs)}).fetchall()

#         prodCG = conn.execute(
#             text('''
#                 SELECT product_id, cat_num FROM products 
#                 WHERE product_id IN :ids;
#             '''), 
#             {'ids': tuple(pid[0] for pid in productIDs)}).fetchall()
#         print('prodCG:', prodCG)

#         prodPR = conn.execute(
#             text('''
#                 SELECT MIN(price), MAX(price)
#                 FROM product_variants
#                 WHERE product_id = :id;
#                  '''), {'id': id}).fetchone()
#         productPriceRange.append((id, prodPR[0], prodPR[1]))

#     productTS_map = {
#         int(pid): (title or 'No Title')
#         for pid, title in productTS if pid is not None
#     }
#     productOptions_map = {int(pid): count for pid, count in productOptions if pid is not None}
#     productPrice_map = {
#         int(pid): (min_price, max_price) 
#         for pid, min_price, max_price in productPriceRange if pid is not None
#     }
#     productVendor_map = {
#         int(pid): username
#         for pid, username in productVendor if pid is not None
#     }
#     prodCG_map = {
#         int(pid): prod
#         for pid, prod in prodCG if pid is not None
#     }

#     products = []
#     for id_tuple in productIDs:
#         pid = int(id_tuple[0])
#         vendor = productVendor_map.get(pid, 'No vendor') 
#         title = productTS_map.get(pid, ('No title'))
#         options = productOptions_map.get(pid, 0)
#         if pid in productPrice_map:
#             min_price, max_price = productPrice_map[pid]
#             price = toDollar(min_price) if min_price == max_price else f"{toDollar(min_price)} - {toDollar(max_price)}"
#         else:
#             price = "N/A"
#         print(pid)
#         category = prodCG_map.get(pid)
#         print('category:', category)
#         if pid != 850561 and pid != 850562:
#             products.append({
#                 'id': pid,
#                 'title': title,
#                 'options': options,
#                 'price': price,
#                 'vendor': vendor,
#                 'category': category,
#                 'display': True
#             })
#     vendors = conn.execute(
#         text('SELECT username, CONCAT(first_name, " ", last_name) FROM users WHERE type = "vendor";')).fetchall()
#     categorySO = conn.execute(
#         text('SELECT cat_num, cat_name FROM categories ' \
#         'WHERE cat_num BETWEEN 1 AND 99;')).fetchall()
#     categorySC = conn.execute(
#         text('SELECT cat_num, cat_name FROM categories ' \
#         'WHERE cat_num BETWEEN 100 AND 199;')).fetchall()
#     categoryOF = conn.execute(
#         text('SELECT cat_num, cat_name FROM categories ' \
#         'WHERE cat_num BETWEEN 200 AND 299;')).fetchall()
#     categoryTX = conn.execute(
#         text('SELECT cat_num, cat_name FROM categories ' \
#         'WHERE cat_num BETWEEN 300 AND 399;')).fetchall()
#     categoryTC = conn.execute(
#         text('SELECT cat_num, cat_name FROM categories ' \
#         'WHERE cat_num BETWEEN 400 AND 499;')).fetchall()
#     categoryFT = conn.execute(
#         text('SELECT cat_num, cat_name FROM categories ' \
#         'WHERE cat_num BETWEEN 500 AND 599;')).fetchall()
#     # print('category queries:', categoryFT, categoryOF, categorySC, categorySO, categoryTC, categoryTX)

#     if request.method == 'POST':

#         formSC = request.form.getlist('sc-options')
#         formOF = request.form.getlist('of-options')
#         formTC = request.form.getlist('tc-options')
#         formTX = request.form.getlist('tx-options')
#         formFT = request.form.getlist('ft-options')
#         formCategories = [formSC, formOF, formTC, formTX, formFT,]
#         print('******formCat:', formCategories)
#         displayCategories(formCategories, products)

#         formPrice = request.form.get('price')
#         displayPrices(formPrice, products)

#         formName = request.form.getlist('vendor-options') 
#         displayVendors(formName, products)

#         print('formname:', formName)
#         formName_map = []

#         for name in formName:
#             for vendor in vendors:
#                 if vendor[0] == name:
#                     brand = vendor[1]
#             print('Name', name, 'Brand:', brand)
#             formName_map.append((name, brand))

#         priceValue = toDollar(formPrice, html=True)
#         clearDisplay = 'block'
#         if formPrice is None:
#             priceValue = 1000
#             clearDisplay = 'none'

#         return render_template(
#             'search.html', 
#             products = products,
#             SO = categorySO,
#             SC = categorySC,
#             OF = categoryOF,
#             TX = categoryTX,
#             TC = categoryTC,
#             FT = categoryFT,
#             checkedVendors = formName_map,
#             vendors = vendors, 
#             priceValue = priceValue,
#             clearDisplay = clearDisplay
#         )
    
#     else:
#         return render_template(
#             'search.html', 
#             products = products,
#             SO = categorySO,
#             SC = categorySC,
#             OF = categoryOF,
#             TX = categoryTX,
#             TC = categoryTC,
#             FT = categoryFT,
#             vendors = vendors, 
#             priceValue = 1000,
#             clearDisplay = 'none'
#         )
    

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
        return price
    except IndexError:
        price = priceList[0]
        return price
    except Exception:
        return '$00.00'

def filterProducts(formVendors, formCategories, formPrice, products):
    selected_vendors = set(formVendors)
    selected_categories = set(formCategories)
    max_price_cents = toCents(formPrice) if formPrice else None

    for product in products:
        should_display = True                                                   # assume product should be displayed

        if selected_vendors:                                                    # filter by vendors
            if product.get('vendor') not in selected_vendors:           
                should_display = False

        if selected_categories:                                                 # filter by category
            if str(product.get('category')) not in selected_categories:
                should_display = False

        if max_price_cents is not None:                                         # filter by price
            product_price_cents = toCents(getSecondPrice(product['price']))
            if product_price_cents > max_price_cents:
                should_display = False

        product['display'] = should_display                                     # set product display
