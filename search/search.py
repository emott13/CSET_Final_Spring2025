from flask import Blueprint, render_template, request
from sqlalchemy import text
from extensions import conn
from colorsys import rgb_to_hls

search_bp = Blueprint('search', __name__, static_folder='static_search', template_folder='templates_search')


# -- SEARCH PAGE -- #
@search_bp.route('/search', methods=['GET', 'POST'])
@search_bp.route('/search/search.py', methods=['GET', 'POST'])
def search():
    product_data = conn.execute(                                    # fetch all product data
        text('''
            SELECT v.product_id, v.variant_id, p.product_title,
                p.cat_num, u.email, v.price, v.current_inventory,
                c.color_name, c.color_hex
            FROM product_variants v
            JOIN products p ON p.product_id = v.product_id
            LEFT JOIN users u ON p.vendor_id = u.email
            LEFT JOIN colors c ON v.color_id = c.color_id;
    ''')).fetchall()

    product_options = conn.execute(                                 # get variant counts
        text('''                         
        SELECT product_id, COUNT(variant_id) AS option_count
        FROM product_variants
        GROUP BY product_id;
    ''')).fetchall()
    option_map = {pid: count for pid, count in product_options}

    product_variants = conn.execute(
        text('''
        SELECT variant_id FROM product_variants;
             ''')).fetchall()
    photos = {}
    for vid in product_variants:
        vid = int(vid[0])
        product_photo = conn.execute(
            text('''
                SELECT file_path, image_id
                FROM images 
                WHERE variant_id = :vid 
                ORDER BY image_id
                LIMIT 1;
                '''),
                {'vid': vid}).fetchone()
        photos[vid] = product_photo[0] if product_photo is not None else None
    

    products = []                                                   # create product list
    for row in product_data:
        pid, vid, title, cat_num, vendor, price, inventory, c_name, c_hex = row

        price = toDollar(price)
        # if min_price == max_price \
        #     else f"{toDollar(min_price)} - {toDollar(max_price)}"
        # 'options': option_map.get(pid, 0),
        products.append({                                           # append product dict to products list
            'id': pid,
            'vid': vid,
            'title': title or 'No Title',
            'price': price or 'N/A',
            'vendor': vendor or 'No Vendor',
            'category': cat_num,
            'color': c_name,
            'hex': c_hex,
            'stock': inventory,
            'photo': photos.get(vid),
            'options': option_map.get(pid, 0),
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
        categories[key] = conn.execute(text('''
            SELECT cat_num, cat_name 
            FROM categories
            WHERE cat_num BETWEEN :start AND :end
        '''), {'start': start, 'end': end}).fetchall()

    formCategories = request.form.getlist('categories')

    colors = conn.execute(
        text("""
            SELECT color_id, color_name, color_hex
            FROM colors
            ORDER BY color_id ASC;
        """)).fetchall()
    sizes = conn.execute(
        text("""
            SELECT size_id, size_description
            FROM sizes
            ORDER BY size_id ASC;
        """)).fetchall()
    specs = conn.execute(
        text("""
            SELECT spec_id, spec_description
            FROM specifications
            ORDER BY spec_id ASC;
        """)).fetchall()
    
    colors_map = []
    for color in colors:
        colors_map.append({
            'cid': color[0],
            'name': color[1],
            'hex': color[2]
        })
    
    sizes_map = []
    for size in sizes:
        sizes_map.append({
            'sid': size[0],
            's_descr': size[1]
        })

    specs_map = []
    for spec in specs:
        specs_map.append({
            'spid': spec[0],
            'sp_descr': spec[1]
        })

    if request.method == 'POST':
        formPrice = request.form.get('price')
        formName = request.form.getlist('vendor-options')
        formColor = request.form.getlist('color-options')

        # -- handles navigation to page from search bar -- #
        if not formPrice and not formName and not formCategories and not formColor: 
            formSearch = request.form.get('product_search')
            searchInput = formSearch.strip().replace(' ', '%')
            searchInput = '%' + searchInput + '%'
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
                userInput = formSearch,
                sizes = sizes_map,
                specs = specs_map
            )
        print('********** made to filter')
        # -- handles product filtering -- #
        filterProducts(products, formVendors=formName, formCategories=formCategories, formPrice=formPrice, formColor=formColor)

        print('# # # # # FORMS')
        print(formCategories)
        print(formPrice)
        print(formName)
        print(formColor)
        
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
            checkedColors = formColor,
            clearDisplay=clearDisplay,
            sizes = sizes_map,
            specs = specs_map
        )

    # -- handles GET requests -- #

    if formCategories is None:
        return render_template(
            'search.html',
            products=products,
            vendors=vendors,
            categories=categories,
            priceValue=1000,
            clearDisplay='none',
            sizes = sizes_map
        )
    
    checkedCategories = getCheckedCategories(formCategories, categories)
    return render_template(
        'search.html',
        products=products,
        vendors=vendors,
        categories=categories,
        checkedCategories=checkedCategories,
        priceValue=1000,
        clearDisplay='none',
        sizes = sizes_map
    )
    

# -- FUNCTIONS -- #

def toCents(num):
    numFloat = 0
    if num is not None:
        print(type(num))
        match type(num):
            case "<class 'int'>":
                numFloat = num
            case _:
                try: 
                    if num.find('$') != -1:
                        numFloat = float(num.replace('$', ''))
                    else:
                        numFloat = float(num)
                except:
                    numFloat = num
    return int(round(numFloat * 100))

def toDollar(num, html=False, thousand=False):
    try:
        numDollar = num / 100
    except:
        return num
    match html, thousand:
        case False, True:
            return f'${numDollar:,.2f}'
        case False, False:
            return f'${numDollar:.2f}'
        case True, True:
            return f'{numDollar:,.2f}'
        case True, False:
            return f'${numDollar:.2f}'
        case _:
            return f'${numDollar:.2f}'

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

def filterProducts(products, formVendors=None, 
                   formCategories=None, formPrice=None, 
                   formSearch=None, formColor=None):
    for product in products:
        should_display = True                                                   # assume product should be displayed
        
        if formSearch:                                                          # filter by search input
            if product.get('id') not in formSearch:
                print('formsearch FALSE:', product.get('id'), product.get('title'))
                should_display = False

        if formVendors:                                                         # filter by vendors
            selected_vendors = set(formVendors)
            if product.get('vendor') not in selected_vendors:           
                print('formvendor FALSE:', product.get('vendor'))
                should_display = False

        if formCategories:                                                      # filter by category
            selected_categories = set(formCategories)
            if str(product.get('category')) not in selected_categories:
                print('formcat FALSE:', product.get('category'))
                should_display = False
        
        if formColor:                                                       # filter by color
            selected_colors = set(formColor)                                # get selected colors
            db_color = str(product.get('hex'))                              # get hex code from product
            if db_color == 'None':                                          # if hex code is Null/None 
                db_c_name = product.get('color')                                # get color name from product
                match db_c_name.lower():                                        # match potential colors with
                    case 'assorted':                                            # related input color
                        color_name = 'assorted'
                    case 'assorted pastels':
                        color_name = 'assorted'
                    case 'assorted metallics':
                        color_name = 'assorted'
                    case 'multicolor':
                        color_name = 'multicolor'
                    case 'pattern':
                        color_name = 'multicolor'
            else:
                hsl_color = hexToHLS(db_color)                              # else hex code, convert to hsl code
                color_name = getColorName(hsl_color)                        # call func with hsl to get color category
            
            # if color_name in selected_colors:
            #     print('in colors:', color_name)
            if color_name not in selected_colors:                           # if product color not in selected colors,
                print('not in colors:', color_name)
                should_display = False                                      # product display changed to avoid display

        if formPrice:
            print('FORM PRICE', formPrice)
            max_price_cents = toCents(formPrice)
            print('MAX CENTS', max_price_cents)
            if max_price_cents is not None:                                         # filter by price
                product_price_cents = toCents(getSecondPrice(product['price']))
                if product_price_cents > max_price_cents:
                    print('formprice FALSE:', product_price_cents, max_price_cents)
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
        # print('num, catName in flattened_categories.items():', num, catName) 
        if str(num) in formCategories:
            checkedCategories.update({num: catName})
    return checkedCategories

def hexToHLS(hex):
    color = hex.lstrip('#')
    r = int(color[0:2], 16) / 255
    g = int(color[2:4], 16) / 255
    b = int(color[4:6], 16) / 255

    h, l, s = rgb_to_hls(r, g, b)
    h = round(h*360)
    s = round(float(s * 100))
    l = round(float(l * 100))

    result = (h, s, l)
    return result

def getColorName(color):
    hue_map = {
        'red': (0, 15),
        'orange': (16, 45),
        'yellow': (46, 60),
        'green': (61, 150),
        'blue': (151, 255),
        'purple': (256, 285),
        'pink': (286, 335),
        'red2': (336, 360)
    }
    light_map = {
        'black': (0, 10),
        'grey': (11, 95),
        'white': (96, 100)
    }
    hue = int(color[0])
    saturation = int(color[1])
    light = int(color[2])

    if saturation > 10:
        for name, (low, high) in hue_map.items():
            if low <= hue <= high:
                print('check hue:', color)
                return 'red' if name == 'red2' else name
    elif saturation <=10:
        for name, (low, high) in light_map.items():
            if low <= light <= high:
                print('check lightness:', color)
                return name
    return 'undefined'