from flask import Flask, render_template, request, url_for, redirect
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import create_engine, text, insert, Table, MetaData, update
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from flask_bcrypt import Bcrypt


# USEFUL flask_login COMMANDS
# @app.route("/foo")
# @login_required # (requires the user to be logged in. Redirects to login if not logged in)
# def foo() ...
# current_user # (has current_user data like current_user.email or current_user.type)
# current_user.is_authenticated
# getCurrentType() # gets the current type. Is None if the user isn't signed in


# Initialize Flask app
app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = "mysql://root:cset155@localhost/goods"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["SECRET_KEY"] = b'\xdak\xd2\xf7\x80,8\x0f\xbdG\xb7\x87\xe4h\xcf\xae'

# Initialize bcrypt
bcrypt = Bcrypt(app)

# Initialize database and login manager
db = SQLAlchemy(app)
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = "login.login"

# Initialize DB the way we did the other times
conn_str = "mysql://root:cset155@localhost/cset170final"                                
engine = create_engine(conn_str, echo=True)                                             
conn = engine.connect()                                                                 

# User model (required for flask-login)
# Create database
# with app.app_context():
#     db.create_all()

class Users(UserMixin, db.Model):
    email = db.Column(db.String(255), primary_key=True)
    username = db.Column(db.String(255), unique=False, nullable=False)
    hashed_pswd = db.Column(db.String(300), nullable=False)
    first_name = db.Column(db.String(60), nullable=False)
    last_name = db.Column(db.String(60), nullable=False)
    type = db.Column(db.Enum('vendor', 'admin', 'customer'), nullable=False)

    def get_id(self):
        return self.email

    def get_email(self):
        return self.email

def getCurrentType():
    """Returns the current_user type. Returns None if the user isn't logged in"""
    return None if not current_user.is_authenticated else current_user.type

# Load user for Flask-Login
@login_manager.user_loader
def load_user(user_id):
    return Users.query.get(user_id)
