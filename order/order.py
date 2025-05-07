from flask import Blueprint, render_template, request, redirect, url_for
from flask_login import LoginManager, UserMixin, current_user, login_required
from sqlalchemy import text
from datetime import datetime
from extensions import conn
from search.search import toCents, toDollar

order_bp = Blueprint('order', __name__, static_folder='static_order', template_folder='templates_order')

@order_bp.route('/order', methods=['GET', 'POST'])
@login_required
def order():
    user = current_user.email
    total = request.form.get('total')
    totalInCents = toCents(total)
    now = datetime.now()

    if request.method == 'POST':
        currentCart = conn.execute(
            text('''
                SELECT * FROM cart_items
                WHERE cart_id 
                IN (SELECT cart_id FROM carts
                    WHERE customer_email = :user)
                 '''),
                {'user': user}
        ).fetchall()
        print('curr cart', currentCart)
        if currentCart is None or currentCart == []:
            return render_template('cart.html', messageString='There was an error placing your order.')

        conn.execute(                                                                       # create new order
            text('''
                INSERT INTO orders (customer_email, status, order_date, total_price)
                VALUES (:user, :status, :date, :total)
            '''), 
            {'user': user, 'status': 'pending', 'date': now, 'total': totalInCents}
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

        return render_template('order_post.html',orders=orders_map,                              # render order page with
                            count=orderCount, message=success)                              # user orders, message, order count
    
    elif request.method == 'GET':
        orders_map, orderCount = getOrders(user)
        return render_template('order_get.html',orders=orders_map,                              # render order page with
                            count=orderCount)                                               # user orders, message, order count


def getOrders(user):
    orders_map = []
    orders = conn.execute(                                                                  # get user orders
        text('''
            SELECT order_id, status, order_date, total_price
            FROM orders
            WHERE customer_email = :user
            ORDER BY order_id DESC;
        '''),
        {'user': user}).fetchall()
    for row in orders:                                                                      # map user orders
        print(row)
        date, time = row[2].strftime("%B %d, %Y"), row[2].strftime("%H:%M:%S %p")
        orders_map.append({
            'id': row[0],
            'status': row[1].title(),
            'date': date,
            'time': time,
            'total': toDollar(toCents(row[3]))
        })
    orderCount = len(orders)                                                                # get length of orders
    return orders_map, orderCount