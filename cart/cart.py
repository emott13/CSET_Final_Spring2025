from flask import Blueprint, render_template, request, redirect, url_for
from flask_login import current_user, login_required
from sqlalchemy import text
from extensions import conn, getCurrentType
from search.search import toDollar

cart_bp = Blueprint('cart', __name__, static_folder='static_cart', template_folder='templates_cart')

@cart_bp.route('/cart', methods = ['GET', 'POST'])
@login_required
def cart():
    if getCurrentType() != 'customer':
        return redirect(url_for('login.login', error="Error: You must be signed in as a customer to order items"))

    message = request.args.get('message')
    print('Message from param:', message)

    user = current_user.email
    cartItems = conn.execute(
        text('''
            SELECT product_title, quantity, price, variant_id
            FROM carts
            NATURAL JOIN cart_items
            NATURAL JOIN product_variants
            NATURAL JOIN products
            WHERE customer_email = :user;
        '''), {'user': user}
    ).fetchall()
    # print('cartItems')
    
    cartItems_map = []
    prices = []
    for item in cartItems:
        name = item[0]
        quantity = int(item[1])
        prices.append(int(item[2] * item[1]))
        price = toDollar(int(item[2] * item[1]))
        id = item[3]
        cartItems_map.append({
            'name': name,
            'quantity': quantity,
            'price': price,
            'id': id
        })
    
    subtotal = 0
    tax = 0
    total = 0
    for price in prices:
        subtotal += price
    tax = round(float(subtotal * 0.06))
    total = tax + subtotal

    subtotal = toDollar(subtotal)
    tax = toDollar(tax)
    total = toDollar(total)
    totals = [subtotal, tax, total]

    return render_template('cart.html', cartItems = cartItems_map, 
                           totals = totals, error = message)

@cart_bp.route('/update_cart', methods=['POST'])
@login_required
def update_cart():
    user = current_user.email
    form_data = request.form

    for variant_id_str, quantity_str in form_data.items():
        if variant_id_str == 'apply changes':
            continue
        try:
            variant_id = int(variant_id_str)
            quantity = int(quantity_str)
        except ValueError:
            continue

        conn.execute(
            text('''
                UPDATE cart_items
                SET quantity = :quantity
                WHERE variant_id = :variant_id
                AND cart_id = (
                    SELECT cart_id FROM carts WHERE customer_email = :user
                )
            '''), {
                'quantity': quantity,
                'variant_id': variant_id,
                'user': user
            }
        )

    return redirect(url_for('cart.cart'))

@cart_bp.route('/delete_item', methods=['POST'])
def delete_item():
    variant_id = request.form.get('variant_id')
    user = current_user.email
    if variant_id:
        conn.execute(
            text('''
                DELETE FROM cart_items
                WHERE variant_id = :variant_id
                AND cart_id = (
                    SELECT cart_id FROM carts WHERE customer_email = :user
                )
            '''), {
                'variant_id': variant_id,
                'user': user
            }
        )

    return redirect(url_for('cart.cart'))