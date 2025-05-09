from flask import Blueprint, render_template, request, redirect, url_for
from flask_login import current_user, login_required
from sqlalchemy import text
from extensions import conn, dict_db_data, getCurrentType
from ast import literal_eval

chat_bp = Blueprint('chat', __name__, static_folder='static_chat', 
                         template_folder='templates_chat', url_prefix="/chat")

@chat_bp.route("/", methods=["GET"])
@login_required
def home():
    error = request.args.get("error")
    chatsData = conn.execute(text("SELECT complaint_id, product_id, JSON_OBJECTAGG('user_from', " \
        "user_from), JSON_OBJECTAGG('user_to', user_to) FROM chats " \
        "WHERE (user_to = :email or user_from = :email )" \
        "GROUP BY complaint_id, product_id"),
        {'email': current_user.email}).all()
    # list of dictionaries for each row
    chats = []
    for chat in chatsData:
        chats.append({'complaint_id': chat[0], 'product_id': chat[1], 
                      'user_from': literal_eval(chat[2])['user_from'], 
                      'user_to': literal_eval(chat[3])['user_to']})
    complaintIds = {}
    productIds = {}
    toEmailsComplaints = {}
    for chat in chats:
        if chat['complaint_id']:
            complaints = dict_db_data("chats", 
                f"WHERE complaint_id = {chat['complaint_id']} AND "
                f"   (user_to = '{current_user.email}' OR user_from = '{current_user.email}' ) "\
                "ORDER BY date_time") 
            for chats in complaints:
                other = chat['user_to'] if chat['user_to'] != current_user.email else chat['user_from']
                print()
                print(chat)
                if other not in toEmailsComplaints.keys():
                    toEmailsComplaints[other] = []
                toEmailsComplaints[other].append(chats)
            print(toEmailsComplaints)
            # complaintIds[chat['complaint_id']]
        elif chat['product_id']:
            productIds[chat['product_id']] = dict_db_data("chats", 
                f"WHERE product_id = {chat['product_id']} AND "
                f"   (user_to = '{current_user.email}' OR user_from = '{current_user.email}' ) "\
                "ORDER BY date_time")
    # print(chats)
    print(complaintIds)
    # print(productIds)


    return render_template('chat.html', error=error, complaintIds=complaintIds, 
                           productIds=productIds, toEmailsComplaints=toEmailsComplaints)

@chat_bp.route("/<type>/<int:combined_id>/<string:recieverEmail>", 
               methods=["GET", "POST"])
@login_required
def room(type, combined_id, recieverEmail):
    error = request.args.get("error")
    type_id = f"{type}_id"
    senderEmail = current_user.email
    recieverExists = bool(
        conn.execute(text(
        "SELECT email FROM users WHERE email = :recieverEmail"),
        {'recieverEmail': recieverEmail}).fetchone()
    )
    if not recieverExists or (type != "complaint" and type != "product"):
        return redirect(url_for('chat.home', error="Invalid URL"))

    ids = dict_db_data(f"{type}s", f"WHERE {type}_id = {combined_id}")

    idExists = False
    for id in ids:
        if id[type_id] == combined_id:
            if ("submitted_by" in id.keys()):
                idExists = True
                break
    if not idExists:
        return redirect(url_for('chat.home', error="Invalid URL"))

    messages = dict_db_data("chats", 
        f"WHERE ((user_from = '{senderEmail}' \
            AND user_to = '{recieverEmail}') " +
        f"  OR  (user_from = '{recieverEmail}' \
            AND user_to = '{senderEmail}')) "+
        f"  AND {type}_id = {combined_id} " +
        "ORDER BY date_time")

    if request.method == "POST":
        message = request.form.get("message")

        if len(message) > 500:
            return redirect(url_for('chat.room', type=type, combined_id=combined_id, 
                                    recieverEmail=recieverEmail, 
                                    error="Message is too long"))

        if message:
            try:
                conn.execute(text(f"INSERT INTO chats ({type_id}, text, user_from, user_to)"
                    "VALUES (:combined_id, :message, :senderEmail, :recieverEmail)"),
                    {'combined_id': combined_id, 'message': message, 
                    'senderEmail': senderEmail, 'recieverEmail': recieverEmail})
                conn.commit()
                return redirect(url_for("chat.room", type=type, combined_id=combined_id, recieverEmail=recieverEmail))
            except Exception as e:
                print(f"\n {e} \n")
                return redirect(url_for('chat.room', type=type, combined_id=combined_id, 
                                        recieverEmail=recieverEmail, 
                                        error="Error in sending message"))
            
    return render_template('room.html', 
        senderEmail=senderEmail, recieverEmail=recieverEmail, combined_id=combined_id, 
        type=type, messages=messages, error=error)