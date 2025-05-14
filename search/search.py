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
                c.color_name, c.color_hex, v.size_id, v.spec_id,
                CONCAT(u.first_name, ' ', u.last_name)
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
        pid, vid, title, cat_num, vendor, price, inventory, c_name, c_hex, size, spec, brand = row

        price = toDollar(price)
        products.append({                                           # append product dict to products list
            'id': pid,
            'vid': vid,
            'title': title or 'No Title',
            'price': price or 'N/A',
            'vendor': vendor or 'No Vendor',
            'category': cat_num,
            'sid': size,
            'spid': spec,
            'color': c_name,
            'hex': c_hex,
            'stock': inventory,
            'photo': photos.get(vid),
            'options': option_map.get(pid, 0),
            'brand': brand,
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
    
    individual_cat_queries = {                                            # seperate categories by cat_num range
        'Writing Supplies': 11,
        'Notetaking': 12,
        'Folders & Filing': 13,
        'Bags, Lunchboxes, & Backpacks': 14,
        'School Basics': 101,
        'Calculators': 102,
        'Art Supplies': 103,
        'Office Basics': 201,
        'Paper & Mailing Supplies': 202,
        'Art Textbooks': 301,
        'Business & Economics Textbooks': 302,
        'Computer Textbooks': 303,
        'Design Textbooks': 304,
        'English Textbooks': 305,
        'Foreign Language Textbooks': 306,
        'Health & Fitness Textbooks': 307,
        'History Textbooks': 308,
        'Law Textbooks': 309,
        'Mathematics Textbooks': 310,
        'Medical Textbooks': 311,
        'Music Textbooks': 312,
        'Philosophy Textbooks': 313,
        'Photography Textbooks': 314,
        'Science Textbooks': 315,
        'Study Aids Textbooks': 316,
        'Tech & Engineering Textbooks': 317,
        'Batteries': 401,
        'Cables': 402,
        'Computers': 403,
        'Computer Accessories': 404,
        'Computer Monitors': 405,
        'Extension Cords': 406,
        'External Device Storage': 407,
        'Laptops': 408,
        'Printers, Scanners & Accessories': 409,
        'Classroom Chairs': 501,
        'Classroom Desks': 502,
        'Classroom Mats & Rugs': 503,
        'Classroom Storage': 504,
        'Office Chairs': 505,
        'Office Desks': 506,
        'Office Storage': 507,
        'Office Mats & Rugs': 508
    }

    category_sizes = {}                                                 # create categories dictionary
    for key, value in individual_cat_queries.items():
        category_sizes[key] = conn.execute(text('''
            SELECT s.size_id, s.size_description
            FROM products p
            JOIN product_variants v ON p.product_id = v.product_id
            LEFT JOIN sizes s ON v.size_id = s.size_id
            WHERE p.cat_num = :value
        '''), {'value': value}).fetchall()
    # redefine each dict key value to distinct tuples
    for key, value in category_sizes.items():
        cat_size_set = []
        for tuple in value:
            if tuple in cat_size_set:
                continue
            cat_size_set.append(tuple)
        category_sizes[key] = cat_size_set
    
    size_map = []
    for key, value in category_sizes.items():
        for tuple in value:
            size_map.append({
                'cat': individual_cat_queries[key],
                'id': tuple[0],
                'descr': tuple[1]
            })

    # fetch specs by category 
    category_specs = {}
    for key, value in individual_cat_queries.items():
        category_specs[key] = conn.execute(text('''
            SELECT sp.spec_id, sp.spec_description
            FROM products p 
            JOIN product_variants v ON p.product_id = v.product_id
            LEFT JOIN specifications sp ON v.spec_id = sp.spec_id
            WHERE p.cat_num BETWEEN :start AND :end
            ORDER BY sp.spec_id ASC;
        '''), {'start': start, 'end': end}).fetchall()
    # redefine each dict key value to distinct tuples
    for key, value in  category_specs.items():
        cat_spec_set = []
        for tuple in value:
            if tuple in cat_spec_set:
                continue
            cat_spec_set.append(tuple)
        category_specs[key] = cat_spec_set

    spec_map = []
    for key, value in category_specs.items():
        for tuple in value:
            spec_map.append({
                'cat': individual_cat_queries[key],
                'id': tuple[0],
                'descr': tuple[1]
            })

    colors_map = []
    for color in colors:
        colors_map.append({
            'cid': color[0],
            'name': color[1],
            'hex': color[2]
        })
    

    checkAvailability(products)
    
    if request.method == 'POST':
        formPrice = request.form.get('price')
        formName = request.form.getlist('vendor-options')
        formColor = request.form.getlist('color-options')
        formSizes = request.form.getlist('cat-sizes')
        formStock = request.form.get('stock-options')

        # -- handles navigation to page from search bar -- #
        if not formPrice and not formName and not formCategories and not formColor and not formSizes and not formStock: 
            formSearch = request.form.get('product_search')
            searchInput = formSearch.strip().replace(' ', '%')
            searchInput = '%' + searchInput + '%'
            searchMatches = []
            searchInputMatches = conn.execute(
                text('''
                    SELECT product_id
                    FROM products p 
                    JOIN users u 
                    ON p.vendor_id = u.email
                    WHERE p.product_title
                    LIKE :input
                    OR p.product_description
                    LIKE :input
                    OR CONCAT(u.first_name, ' ', u.last_name)
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
                cat_sizes =  size_map,
                cat_specs = spec_map
            )
        # -- handles product filtering -- #
        filterProducts(products, 
                       formVendors=formName, 
                       formCategories=formCategories, 
                       formPrice=formPrice, 
                       formColor=formColor,
                       formSizes=formSizes,
                       formStock=formStock)

        print('# # # # # FORMS')
        print('cat', formCategories)
        print('price', formPrice)
        print('name', formName)
        print('color', formColor)
        print('size/spec', formSizes)
        
        checkedCategories = getCheckedCategories(formCategories, categories)
        size_options = [item for sublist in [size_map, spec_map] for item in sublist]
        print(size_options)
        checkedSizes = getCheckedSizes(formSizes, size_options)

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
            checkedSizes=checkedSizes,
            checkedVendors=formName_map,
            priceValue=priceValue,
            checkedColors = formColor,
            clearDisplay=clearDisplay,
            cat_sizes =  size_map,
            cat_specs = spec_map
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
            cat_sizes =  size_map,
            cat_specs = spec_map
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
        cat_sizes =  size_map,
        cat_specs = spec_map
    )
    

# -- FUNCTIONS -- #

def toCents(num):
    numFloat = 0
    if num is not None:
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

def checkAvailability(products):
    for product in products:
        count = int(product.get('stock'))
        if count > 5:
            product['availability'] = None
        elif 0 < count <= 5:
            product['availability'] = 'Less than 5 left'
        else:
            product['availability'] = 'Out of Stock'

def filterProducts(products, formVendors=None, 
                   formCategories=None, formPrice=None, 
                   formSearch=None, formColor=None,
                   formSizes=None, formStock=None):
    for product in products:
        should_display = True                                                   # assume product should be displayed
        
        if formSearch:                                                          # filter by search input
            if product.get('id') not in formSearch:
                should_display = False

        if formVendors:                                                         # filter by vendors
            selected_vendors = set(formVendors)
            if product.get('vendor') not in selected_vendors:           
                should_display = False

        if formCategories:                                                      # filter by category
            selected_categories = set(formCategories)
            if str(product.get('category')) not in selected_categories:
                should_display = False
        
        if formSizes:                                                           # filter by size & spec
            selected_sizes = set(formSizes)
            prod_size, prod_spec = str(product.get('sid')), str(product.get('spid'))
            if prod_size not in selected_sizes and prod_spec not in selected_sizes:
                print('PROD SIZE / SPEC FALSE', prod_size, prod_spec)
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
            
            if color_name not in selected_colors:                           # if product color not in selected colors,
                should_display = False                                      # product display changed to avoid display

        if formStock:
            if formStock == 'in' and int(product.get('stock')) == 0:
                should_display = False
            if formStock == 'out' and int(product.get('stock')) > 0:
                should_display = False

        if formPrice:
            max_price_cents = toCents(formPrice)
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
        if str(num) in formCategories:
            checkedCategories.update({num: catName})
    return checkedCategories

def getCheckedSizes(formSizes, size_options):
    checkedSizes = {}
    for size in size_options:
        if str(size['id']) in formSizes:
            checkedSizes.update({size['id']: size['descr']})
    return checkedSizes

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
                return 'red' if name == 'red2' else name
    elif saturation <=10:
        for name, (low, high) in light_map.items():
            if low <= light <= high:
                return name
    return 'undefined'