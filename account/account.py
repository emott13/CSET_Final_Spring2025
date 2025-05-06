from flask import Blueprint, render_template, request, redirect, url_for
from flask_login import LoginManager, UserMixin, current_user
from sqlalchemy import text
from extensions import conn
from search.search import toDollar

account_bp = Blueprint('account', __name__, static_folder='static_account', template_folder='templates_account')

@account_bp.route('/account')
def account():
    user = current_user.email
    userData = conn.execute(
        text('''
            SELECT email, username, CONCAT(first_name, ' ', last_name), type
            FROM users
            WHERE email = :user
            '''),
            {'user': user}
    ).fetchone()
    print('************* user data', userData)
    userData_map = {
        'email': userData[0],
        'username': userData[1],
        'name': userData[2],
        'type': userData[3]
    }
    print('**************** user data map:', userData_map)
    userChats = conn.execute(
        text('''
            SELECT chat_id, complaint_id, product_id, text, user_from, user_to, date_time 
            FROM chats 
            WHERE user_from = :user 
                OR user_to = :user;
        '''),
        {'user': user}).fetchall()
    userChats_map = []
    # for chat in userChats:
    #     userChats_map.append({
    #         'user':,
    #         'email':,
    #         'cid':,
    #         '':,
    #         'text':,
    #         'datetime':,
    #         '':,
    #         '':
    #     })
    return render_template('account.html', account = userData_map)