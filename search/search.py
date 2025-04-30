from flask import Blueprint, render_template, request
from sqlalchemy import text
from extensions import conn

search_bp = Blueprint('search', __name__, static_folder='static_search', template_folder='templates_search')

# -- SEARCH PAGE -- #
@search_bp.route('/search', methods=['GET', 'POST'])
@search_bp.route('/search/search.py', methods=['GET', 'POST'])
def search():
    product_data = conn.execute(                                    # fetch all product data
        text('''
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
            formSearch = request.form.get('product_search')
            print('form search:', formSearch)
            searchInput = formSearch.strip().replace(' ', '%')
            searchInput = '%' + searchInput + '%'
            print('search input:', searchInput)
            searchMatches = []
            searchInputMatches = conn.execute(
                text('''
                    SELECT product_id 
                    FROM products
                    WHERE product_title
                        LIKE :input
                    OR product_description
                        LIKE :input;
                '''), {'input': searchInput}).fetchall()
            for input in searchInputMatches:
                searchMatches.append(input[0])

            filterProducts(products, formSearch=searchMatches)
            if searchInput == '%%':
                formSearch = None
            return render_template(                                 # this code can potentially be removed when search
                'search.html',                                          # bar functionality has been completed
                products=products,
                vendors=vendors,
                categories=categories,
                priceValue=1000,
                clearDisplay='none',
                userInput = formSearch 
            )
        print('********** made to filter')
        # -- handles product filtering -- #
        filterProducts(products, formVendors=formName, formCategories=formCategories, formPrice=formPrice)

        print('# # # # # FORMS')
        print(formCategories)
        print(formPrice)
        print(formName)
        
        checkedCategories = getCheckedCategories(formCategories, categories)

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

    if formCategories == 0:
        return render_template(
            'search.html',
            products=products,
            vendors=vendors,
            categories=categories,
            priceValue=1000,
            clearDisplay='none'
        )
    
    checkedCategories = getCheckedCategories(formCategories, categories)
    return render_template(
        'search.html',
        products=products,
        vendors=vendors,
        categories=categories,
        checkedCategories=checkedCategories,
        priceValue=1000,
        clearDisplay='none'
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
        return price
    except IndexError:
        price = priceList[0]
        return price
    except Exception:
        return '$00.00'

def filterProducts(products, formVendors=None, formCategories=None, formPrice=None, formSearch=None):
    for product in products:
        should_display = True                                                   # assume product should be displayed
        
        if formSearch:                                                          # filter by search input
            if product.get('id') not in formSearch:
                should_display = False

        if formVendors:                                                         # filter by vendors
            selected_vendors = set(formVendors)
            if product.get('vendor') not in selected_vendors:           
                should_display = False

        if formCategories:                                                 # filter by category
            selected_categories = set(formCategories)
            if str(product.get('category')) not in selected_categories:
                should_display = False

        max_price_cents = toCents(formPrice) if formPrice else None
        if max_price_cents is not None:                                         # filter by price
            product_price_cents = toCents(getSecondPrice(product['price']))
            if product_price_cents > max_price_cents:
                should_display = False

        product['display'] = should_display                                     # set product display

def getCheckedCategories(formCategories, categories):
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
    return checkedCategories