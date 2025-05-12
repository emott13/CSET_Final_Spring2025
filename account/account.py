from flask import Blueprint, render_template, request, redirect, url_for
from flask_login import LoginManager, UserMixin, current_user, login_required
from sqlalchemy import text
from extensions import conn
from search.search import toDollar

account_bp = Blueprint('account', __name__, static_folder='static_account', template_folder='templates_account')

@account_bp.route('/account')
@login_required
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
    chat = conn.execute(
        text('''
            SELECT chat_id, complaint_id, product_id, text, user_from, user_to, date_time 
            FROM chats 
            WHERE user_from = :user 
                OR user_to = :user
            ORDER BY date_time DESC
            LIMIT 1;
        '''),
        {'user': user}).fetchone()
    print(chat)
    if not chat:
        return render_template('account.html', account = userData_map)

    if chat[1] is not None:
        id = chat[1]
    else:
        id = chat[2]

    if chat[4] == user:
        sender = chat[4]
        other = chat[5]
    else:
        sender = chat[5]
        other = chat[4]

    chatText = f'{chat[3][0:25]}...'
    userChats_map = {
        'user': sender,
        'from': other,
        'cid': chat[0],
        'id': id,
        'text': chatText,
        'datetime': chat[6]
    }

    return render_template('account.html', account = userData_map, chat = userChats_map)

# # temp to print passed data. 
# # html action can be changed to go to chats when we create chats.py,
# # and then this could be deleted
# @account_bp.route('/chat')
# def chat():
#     chat = request.args.get('data')
#     print('chat', chat)
#     return redirect(url_for('account.account'))