from flask import Blueprint, render_template, request, redirect, url_for
from flask_login import current_user, login_required
from sqlalchemy import text
from extensions import conn, dict_db_data, getCurrentType

chat_bp = Blueprint('chat', __name__, static_folder='static_chat', 
                         template_folder='templates_chat', url_prefix="/chat")

@chat_bp.route("/", methods=["GET"])
@login_required
def home():
    return render_template('chat.html')