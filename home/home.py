from flask import Blueprint, render_template
from sqlalchemy import text
from extensions import conn

home_bp = Blueprint('home', __name__, static_folder='static_home', template_folder='templates_home')

@home_bp.route('/')
@home_bp.route('/home')
def home():
    officeProdIDs = [100220, 100225, 100226, 100227, 100228, 100235, 100236, 100239, 100240]
    officePhotos = []
    for id in officeProdIDs:
        photo = conn.execute(
        text('SELECT product_title, size_description, file_path, alt_text ' \
        'FROM products natural join product_variants natural join sizes natural join images ' \
        'WHERE product_id IN(850565, 850566, 850567, 850568, 850569, 850570) ' \
        'AND variant_id=:id LIMIT 1'), {'id': id}).fetchone()
        officePhotos.append(photo)
    print('Office products: ', officePhotos)
    schoolSupplyProd = conn.execute(
            text('SELECT product_title, size_description, file_path, alt_text ' \
            'FROM products natural join product_variants natural join sizes natural join images ' \
            'WHERE vendor_id="g_pitts@supplies4school.org" and image_id IN(1, 3, 5, 7, 19, 21);'),
            {'id': id}).fetchall()
    return render_template('home.html', officePhotos = officePhotos, schoolSupplies = schoolSupplyProd)