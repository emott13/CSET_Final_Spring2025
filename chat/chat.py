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
    # chatsData = conn.execute(text("SELECT complaint_id, product_id, JSON_OBJECTAGG('user_from', " \
    #     "user_from), JSON_OBJECTAGG('user_to', user_to) FROM chats " \
    #     "WHERE (user_to = :email or user_from = :email )" \
    #     "GROUP BY complaint_id, product_id"),
    #     {'email': current_user.email}).all()
    # # list of dictionaries for each row
    # chatsIds = []
    # for chat in chatsData:
    #     chatsIds.append({'complaint_id': chat[0], 'product_id': chat[1], 
    #                   'user_from': literal_eval(chat[2])['user_from'], 
    #                   'user_to': literal_eval(chat[3])['user_to']})
    
    complaintChats = conn.execute(text("SELECT a.* FROM chats a "
        "INNER JOIN ( "
        "SELECT complaint_id, MAX(date_time) max_d FROM chats "
        "WHERE user_from = :email OR user_to = :email "
        "GROUP BY complaint_id, GREATEST(user_from, user_to) "
        ") b ON a.complaint_id = b.complaint_id AND a.date_time = b.max_d "
        "ORDER BY date_time DESC"),
        {'email': current_user.email}).all()
    complaintKeys = [ key[0] for key in conn.execute(text("DESC chats")).all() ]
    # print(complaintChats)
    # print(complaintKeys)
    
    complaintRowDict = []
    for row in complaintChats:
        dictRow = {}
        for key, value in zip(complaintKeys, row):
            dictRow[key] = value
        complaintRowDict.append(dictRow)

    productChats = conn.execute(text("SELECT a.* FROM chats a "
        "INNER JOIN ( "
        "SELECT product_id, MAX(date_time) max_d FROM chats "
        "WHERE user_from = :email OR user_to = :email "
        "GROUP BY product_id, GREATEST(user_from, user_to) "
        ") b ON a.product_id = b.product_id AND a.date_time = b.max_d "
        "ORDER BY date_time DESC"),
        {'email': current_user.email}).all()
    productKeys = [ key[0] for key in conn.execute(text("DESC chats")).all() ]
    # print(productChats)
    # print(productKeys)
    
    productRowDict = []
    for row in productChats:
        dictRow = {}
        for key, value in zip(productKeys, row):
            dictRow[key] = value
        productRowDict.append(dictRow)
    
    print()
    print(productRowDict)
    print()

    return render_template('chat.html', error=error, complaintRowDict=complaintRowDict, 
                           productRowDict=productRowDict, email=current_user.email)

@chat_bp.route("/<type>/<int:combined_id>/<string:recieverEmail>", 
               methods=["GET", "POST"])
@login_required
def room(type, combined_id, recieverEmail):
    itype = type
    error = request.args.get("error")
    itype_id = f"{itype}_id"
    senderEmail = current_user.email
    recieverExists = bool(
        conn.execute(text(
        "SELECT email FROM users WHERE email = :recieverEmail"),
        {'recieverEmail': recieverEmail}).fetchone()
    )
    
    if not recieverExists or (itype != "complaint" and itype != "product"):
        return redirect(url_for('chat.home', error="Recieving email does not exist"))

    ids = dict_db_data(f"{itype}s", f"WHERE {itype}_id = {combined_id}")

    idExists = False
    # Checks if product_id or complaint_id exist
    for id in ids:
        if id[itype_id] == combined_id:
            if ("submitted_by" in id.keys()): # must be a complaint
                idExists = True
                break
            elif ("product_id" in id.keys()):
                idExists = True
                break

    if not idExists:
        return redirect(url_for('chat.home', error="Invalid URL"))

    messages = dict_db_data("chats", 
        f"WHERE ((user_from = '{senderEmail}' \
            AND user_to = '{recieverEmail}') " +
        f"  OR  (user_from = '{recieverEmail}' \
            AND user_to = '{senderEmail}')) "+
        f"  AND {itype}_id = {combined_id} " +
        "ORDER BY date_time")

    if request.method == "POST":
        message = request.form.get("message")

        if len(message) > 500:
            return redirect(url_for('chat.room', type=itype, combined_id=combined_id, 
                                    recieverEmail=recieverEmail, 
                                    error="Message is too long"))

        if message:
            try:
                conn.execute(text(f"INSERT INTO chats ({itype_id}, text, user_from, user_to)"
                    "VALUES (:combined_id, :message, :senderEmail, :recieverEmail)"),
                    {'combined_id': combined_id, 'message': message, 
                    'senderEmail': senderEmail, 'recieverEmail': recieverEmail})
                conn.commit()
                return redirect(url_for("chat.room", type=itype, combined_id=combined_id, recieverEmail=recieverEmail))
            except Exception as e:
                print(f"\n {e} \n")
                return redirect(url_for('chat.room', type=itype, combined_id=combined_id, 
                                        recieverEmail=recieverEmail, 
                                        error="Error in sending message"))
            
    return render_template('room.html', 
        senderEmail=senderEmail, recieverEmail=recieverEmail, combined_id=combined_id, 
        type=itype, messages=messages, error=error)