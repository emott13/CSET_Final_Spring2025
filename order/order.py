from flask import Blueprint, render_template, request, redirect, url_for
from flask_login import current_user, login_required
from sqlalchemy import text
from datetime import datetime
from extensions import conn, getCurrentType, sql_enum_list, dict_db_data
from search.search import toCents, toDollar

order_bp = Blueprint('order', __name__, static_folder='static_order', template_folder='templates_order')

@order_bp.route('/order', methods=['GET', 'POST'])
@login_required
def order():
    user = current_user.email
    total = request.form.get('total')
    error = request.args.get('error')
    # print('* * * * * *TOTAL', total)
    totalInCents = toCents(total)
    now = datetime.now()
    if total == '$0.00':
        request.method = 'GET'
        message = 'There was an issue placing your order.'

    if getCurrentType() == 'vendor':
        return redirect(url_for("order.vendor"))

    if request.method == 'GET':
        orders_map, orderCount = getOrders(user)
        try:
            # print('! ! ! ! !', message)
            return redirect(url_for('cart.cart', message=message))                                # user orders, message, order count
        except UnboundLocalError:
            return render_template('order_get.html',orders=orders_map,                          # render order page with
                                count=orderCount)                                               # user orders, message, order count
        
    elif request.method == 'POST':
        address = request.form.get("address", "")
        address2 = request.form.get('address2', "")
        city = request.form.get('city', "")
        state = request.form.get('state', "")
        country = request.form.get('country', "")
        creditCard = request.form.get('credit-card', "")
        cardName = request.form.get('card-name', "")
        cvc = request.form.get('cvc', "")
        error = None

        if len(address) > 255 or len(address2) > 255 or not address:
            error = "Invalid address"
        elif len(city) > 255 or not city:
            error = "Invalid city"
        elif len(state) > 255 or not state:
            error = "Invalid state / province / territory"
        elif len(country) > 255 or not country:
            error = "Invalid country"
        elif len(creditCard) > 255 or len(creditCard) < 13 or not creditCard or creditCard.isalpha():
            error = "Invalid credit card"
        elif len(cardName) > 255 or not cardName:
            error = "Invalid card name"
        elif len(cvc) > 4 or len(cvc) < 3 or cvc.isalpha() or not cvc:
            error = "Invalid card cvc"
        print(f"error\n{error}")

        if error:
            return redirect(url_for('cart.cart', message=error))

        currentCart = conn.execute(
            text('''
                SELECT * FROM cart_items
                WHERE cart_id 
                IN (SELECT cart_id FROM carts
                    WHERE customer_email = :user)
                 '''),
                {'user': user}
        ).fetchall()
        # print('curr cart', currentCart)
        if currentCart is None or currentCart == []:
            return render_template('cart.html', messageString='There was an error placing your order.')

        conn.execute(                                                                       # create new order
            text('''
                INSERT INTO orders (customer_email, status, order_date, total_price, 
                    address, address2, city, state, country, credit_card, card_name, card_cvc)
                VALUES (:user, :status, :date, :total,
                    :address, :address2, :city, :state, :country, :creditCard,
                    :cardName, :cvc)
            '''), 
            {'user': user, 'status': 'pending', 'date': now, 'total': totalInCents,
             'address': address, 'address2': address2, 'city': city, 'state': state,
             'country': country, 'creditCard': creditCard, 'cardName': cardName, 'cvc': cvc}
        )

        order_id_result = conn.execute(                                                     # get new order id
            text('''
                SELECT order_id FROM orders
                WHERE customer_email = :user
                ORDER BY order_id DESC
                LIMIT 1
            '''), {'user': user}
        ).fetchone()

        order_id = order_id_result[0] if order_id_result else None                          # handle None/debug
        if not order_id:
            return "Order creation failed", 500

        cart_items = conn.execute(                                                          # get all cart items
            text('''
                SELECT variant_id, quantity
                FROM cart_items
                WHERE cart_id = (
                    SELECT cart_id FROM carts WHERE customer_email = :user
                )
            '''), {'user': user}
        ).fetchall()

        for variant_id, quantity in cart_items:                                             # get price and insert into order_items
            price_result = conn.execute(                                                    # for each result in cart_items 
                text('''
                    SELECT price FROM product_variants WHERE variant_id = :vid
                '''), {'vid': variant_id}
            ).fetchone()

            if not price_result:                                                            # skips if no variant
                continue  

            price_at_order_time = price_result[0]                                           # define price

            conn.execute(                                                                   # insert into order_items
                text('''
                    INSERT INTO order_items 
                    (order_id, variant_id, quantity, price_at_order_time)
                    VALUES (:oid, :vid, :qty, :price)
                '''), {
                    'oid': order_id,
                    'vid': variant_id,
                    'qty': quantity,
                    'price': price_at_order_time
                }
            )

            conn.execute(                                                                   # decrement inventory based on order
                text('''
                    UPDATE product_variants
                    SET current_inventory = current_inventory - :qty
                    WHERE variant_id = :vid
                '''), {
                    'qty': quantity,
                    'vid': variant_id
                }
            )

        conn.execute(                                                                       # clear user cart
            text('''
                DELETE FROM cart_items 
                WHERE cart_id = (
                    SELECT cart_id FROM carts WHERE customer_email = :user
                )
            '''), {'user': user}
        )

        conn.commit()                                                                       # commit changes
        orders_map, orderCount = getOrders(user)
        success = 'Your order has been placed.'                                             # success message

        return render_template('order_post.html',orders=orders_map,                         # render order page with
                            count=orderCount, message=success)                              # user orders, message, order count

@order_bp.route('/order/<int:orderId>', methods=['GET', 'POST'])
@login_required
def orderDetails(orderId):
    if getCurrentType() != 'customer':
        return redirect(url_for("login.login"))
    orderEmail = conn.execute(text("SELECT customer_email FROM orders "
                                      "WHERE order_id = :orderId"),
                                      {'orderId': orderId}).first()
    orderItems = dict_db_data("order_items", 
        "NATURAL JOIN product_variants NATURAL JOIN products NATURAL JOIN colors "+ 
        "NATURAL JOIN sizes NATURAL JOIN specifications  "+
        f"WHERE order_id = {orderId} ",
        select="product_id, product_title, color_name, size_description, spec_description")
    print(orderItems)
    print(orderEmail)

    if orderEmail == None or orderEmail[0] != current_user.email:
        return redirect(url_for('home.home'))

    return render_template("order_details.html", orderId=orderId, orderItems=orderItems)

@order_bp.route('/order/vendor', methods=['GET'])
@login_required
def vendor():
    if getCurrentType() != 'vendor':
        redirect(url_for("home.home"))

    error = request.args.get("error")
    vendorOrders = getVendorOrders(current_user.email)
    statuses = sql_enum_list(
        conn.execute(text("SHOW COLUMNS FROM order_items LIKE 'status'")).all()[0][1])
    # print(statuses)

    return render_template("order_vendor.html", vendorOrders=vendorOrders, 
                           statuses=statuses, error=error)

@order_bp.route("/order/vendor/<int:orderItemId>", methods=["POST"])
@login_required
def updateOrder(orderItemId):
    if getCurrentType() != 'vendor':
        redirect(url_for("home.home"))
    userOwns = bool(conn.execute(text(
        """SELECT vendor_id FROM order_items NATURAL JOIN product_variants
           NATURAL JOIN products 
           WHERE vendor_id = :vendorId AND order_item_id = :orderItemId"""),
           {'vendorId': current_user.email, 'orderItemId': orderItemId}).first())
    newStatus = request.form.get("status")

    if userOwns:
        # try:
        conn.execute(text("""
            UPDATE order_items 
            SET status = :newStatus
            WHERE order_item_id = :orderItemId"""),
            {'newStatus': newStatus, 'orderItemId': orderItemId})
        conn.commit()

        orderId = conn.execute(text("SELECT order_id FROM order_items WHERE order_item_id = :orderItemId"),
                                    {'orderItemId': orderItemId}).first()[0]
        orderItems = conn.execute(text("SELECT order_items.status FROM order_items WHERE order_id = :orderId"),
                                       {'orderId': orderId}).all()
        print(f"orderId: {orderId}")
        print(f"orderItems: {orderItems}")
        status = None
        sameStatus = True
        for item in orderItems:
            if status == None:
                status = item[0]
            else:
                if status != item[0]:
                    sameStatus = False
                    break
        if sameStatus:
            conn.execute(text("UPDATE orders SET status = :status WHERE order_id = :orderId"),
                              {'status': status, 'orderId': orderId})
            conn.commit()
        
        # except Exception as e:
        #     print(f"\n{e}\n")
        # return redirect(url_for("order.vendor", error="Unable to update status"))

    return redirect(url_for("order.vendor"))


def getVendorOrders(user):
    orders_map = []
    orders = conn.execute(
        text('''
            SELECT order_items.order_id, order_items.status, orders.order_date, 
                orders.total_price, orders.customer_email, 
                quantity, price_at_order_time, vendor_id, product_title, 
                product_description, order_item_id, address, address2, city, 
                state, country, credit_card, card_name, card_cvc, product_id
            FROM order_items NATURAL JOIN product_variants NATURAL JOIN products
            INNER JOIN orders ON order_items.order_id = orders.order_id
            WHERE vendor_id = :user
            ORDER BY order_date, order_item_id DESC;
        '''),
        {'user': user}).fetchall()
    for row in orders:
        # print(row)
        date, time = row[2].strftime("%B %d, %Y"), row[2].strftime("%I:%M:%S %p")
        orders_map.append({
            'id': row[0],
            'status': row[1],
            'date': date,
            'time': time,
            'total': toDollar(row[3], thousand=True),
            'customer_email': row[4],
            'quantity': row[5],
            'price_at_order_time': row[6],
            'vendor_id': row[7],
            'product_title': row[8],
            'product_description': row[9],
            'order_item_id': row[10], 
            'address': row[11],
            'address2': row[12],
            'city': row[13],
            'state': row[14],
            'country': row[15],
            'credit_card': row[16],
            'card_name': row[17],
            'card_cvc': row[18],
            'product_id': row[19]
        })
    return orders_map


def getOrders(user):
    orders_map = []
    orders = conn.execute(                                                                  # get user orders
        text('''
            SELECT order_id, status, order_date, total_price,
            address, address2, city, state, country,
            credit_card, card_name, card_cvc
            FROM orders
            WHERE customer_email = :user
            ORDER BY order_id DESC;
        '''),
        {'user': user}).fetchall()
    for row in orders:                                                                      # map user orders
        # print(row)
        date, time = row[2].strftime("%B %d, %Y"), row[2].strftime("%I:%M:%S %p")
        orders_map.append({
            'id': row[0],
            'status': row[1].title(),
            'date': date,
            'time': time,
            'total': toDollar(row[3], thousand=True),
            'address': row[4],
            'address2': row[5],
            'city': row[6],
            'state': row[7],
            'country': row[8],
            'credit_card': row[9],
            'card_name': row[10],
            'card_cvc': row[11],
        })
    orderCount = len(orders)                                                                # get length of orders
    return orders_map, orderCount