from flask import Flask

# Define the WSGI application object
application = Flask(__name__)

# Read config file
application.config.from_object('config')

# Import application views
from app import views
