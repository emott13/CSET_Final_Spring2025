from flask import Flask, render_template, request, url_for, redirect
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import create_engine, text, insert, Table, MetaData, update
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from scripts.shhhh_its_a_secret import customHash
# from werkzeug.security import generate_password_hash, check_password_hash


# USEFUL flask_login COMMANDS
# @app.route("/foo")
# @login_required # (requires the user to be logged in. Redirects to login if not logged in)
# def foo() ...
#
# current_user # (has current_user data like current_user.email or current_user.type)


# Initialize Flask app
app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = "mysql://root:cset155@localhost/goods"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["SECRET_KEY"] = "i)\xe8\th\x89x9dZwP"

# Initialize database and login manager
db = SQLAlchemy(app)
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = "login"

# Initialize DB the way we did the other times
conn_str = "mysql://root:cset155@localhost/cset170final"                                
engine = create_engine(conn_str, echo=True)                                             
conn = engine.connect()                                                                 

# User model (required for flask-login)
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

# Create database
# with app.app_context():
#     db.create_all()

# Load user for Flask-Login
@login_manager.user_loader
def load_user(user_id):
    return Users.query.get(user_id)

# -- LOGIN PAGE -- #
@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        email = request.form.get("username")
        password = request.form.get("password")

        if not email or not password:
            return render_template("login.html", error="Invalid input")

        user = Users.query.filter_by(email=email).first()
        user_username = Users.query.filter_by(username=email).first()

        # first checks email, then checks username
        if user and user.hashed_pswd == customHash(password):
            login_user(user)
            return redirect(url_for("test"))
        elif user_username and  user_username.hashed_pswd == customHash(password):
            login_user(user_username)
            return redirect(url_for("test"))
        
        else:
            return render_template("login.html", error="Invalid username or password")

    return render_template("login.html")


# -- SIGNUP PAGE -- #
@app.route("/signup", methods=["GET", "POST"])
def signup():
    if request.method == "POST":
        email = request.form.get('email')
        username = request.form.get('username')
        hashed_pswd = customHash(request.form.get('password'))
        first_name = request.form.get('first_name')
        last_name = request.form.get('last_name')
        type = request.form.get('type')

        # Check if the values are not null (tampered with website)
        if not email or not username or not hashed_pswd \
            or not first_name or not last_name or not type:
            return render_template("signup.html", error="Error: Invalid input")
        elif Users.query.filter_by(email=email).first():
            return render_template("signup.html", error="Error: Email already exists")
        elif Users.query.filter_by(username=username).first():
            return render_template("signup.html", error="Error: Username already exists")

        new_user = Users(email=email, username=username, hashed_pswd=hashed_pswd, 
                        first_name=first_name, last_name=last_name, type=type)
        db.session.add(new_user)
        db.session.commit()
        return render_template("signup.html", success="Created account. <a href=\"/login\">Login</a>") 

    return render_template("signup.html")

# -- TEST PAGE -- #
# Shows current_user data (whoever is logged in)
@app.route("/test")
@login_required
def test():
    return render_template("test.html", current_user=current_user)

# -- LOGOUT PAGE -- #
@app.route("/logout")
@login_required
def logout():
    logout_user()
    return redirect(url_for("login"))


if __name__ == '__main__':
    app.run(debug=True)