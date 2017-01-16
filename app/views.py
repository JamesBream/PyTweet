# System imports
import re, json
# Package imports
import bleach
from flask import render_template, redirect, request, session
from flask_mysqldb import MySQL
from werkzeug import generate_password_hash, check_password_hash
from app import application

mysql = MySQL()
mysql.init_app(application)

@application.route('/')
@application.route('/index')
def index():
    # If user is logged in, redirect to feed
    if session.get('user'):
        return redirect('/feed')
    # Else present with Login/Register options
    return render_template('index.html')

@application.route('/register', methods=['GET', 'POST'])
def register():
    title = "Tweeter - Register"
    if request.method == "GET":
        return render_template('register.html',
                                title=title)

    elif request.method == "POST":
        try:
            # Request POST values and sanitise input of HTML for safety
            _firstname = bleach.clean(request.form['inputFirstName'])
            _lastname = bleach.clean(request.form['inputLastName'])
            _email = bleach.clean(request.form['inputEmail'])
            _password = request.form['inputPassword']
            _passconfirm = request.form['inputConfirmPassword']

            # Check all inputs are provided, we can't trust client side validation
            if _firstname and _lastname and _email and _password and _passconfirm:
                # Does the email look valid?
                if re.match(r"[^@\s]+@[^@\s]+\.[a-zA-Z0-9]+$", _email):
                    # Matching passwords?
                    if _password == _passconfirm:
                        cur = mysql.connection.cursor()

                        # Generate a hash of the password
                        _hashed_password = generate_password_hash(_password)
                        cur.callproc('sp_createUser', (_email, _firstname, _lastname, _hashed_password))

                        rv = cur.fetchall()
                        cur.close()

                        # Check for returned error message
                        if len(rv) is 0:
                            # Commit changes to database
                            mysql.connection.commit()
                            return json.dumps({'success':'User create success! You may now log in.'})

                        else:
                            # Return error from db, likely user already exists
                            return json.dumps({'error':str(rv[0][0])})
                    else:
                        error = "Passwords do not match."
                        return json.dumps({'error':'Passwords do not match.'})
                else:
                    error = "Email address is invalid"
                    return json.dumps({'error':'Email address invalid'})
            else:
                error = "Please enter all fields."
                return json.dumps({'error':'Enter all fields'})
        # Catch and return any errors during try block
        except Exception as e:
            return json.dumps({'error':str(e)})

@application.route('/login', methods=['GET', 'POST'])
def login():
    title = "Tweeter - Register"
    if request.method == "GET":
        return render_template('signin.html',
                                title=title)

    elif request.method == "POST":
        try:
            _email = request.form['inputEmail']
            _password = request.form['inputPassword']

            cur = mysql.connection.cursor()
            cur.callproc('sp_validateLogin', (_email,))
            rv = cur.fetchall()
            cur.close()

            if len(rv) > 0:
                if check_password_hash(str(rv[0][4]), _password):
                    session['user'] = rv[0][0]
                    return redirect('/feed')
                else:
                    return render_template('error.html', error = 'Invalid Email/Password combination.')
            else:
                return render_template('error.html', error = 'Invalid Email/Password combination.')
        except Exception as e:
            return render_template('error.html', error = str(e))

@application.route('/feed', methods=['GET'])
def feed():
    if session.get('user'):
        return render_template('feed.html')
    else:
        return render_template('error.html', error = 'Please login.')

@application.route('/profile')
def myProfile():
    if session.get('user'):
        try:
            _user = session.get('user')
            return redirect('/profile/' + str(_user))
        except Exception as e:
            return render_template('error.html', error=str(e))
    else:
        return render_template('error.html', error=str(e))

@application.route('/profile/<int:uid>')
def profile(uid):

    # Only allow logged in users
    if session.get('user'):
        try:
            cur = mysql.connection.cursor()
            cur.execute("SELECT * FROM tbl_user WHERE user_id = %s", str(uid))
            rv = cur.fetchall()
            cur.close()

            if len(rv) > 0:
                return render_template('userHome.html', u_id = rv[0][0],
                                                        u_f_name = rv[0][2],
                                                        u_l_name = rv[0][3])
            else:
                return render_template('error.html', error = 'Invalid.')
        except Exception as e:
            return render_template('error.html', error = str(e))

@application.route('/newPost', methods=['GET', 'POST'])
def newPost():
    if session.get('user'):
        if request.method == "GET":
            return render_template('newPost.html')
        elif request.method == "POST":
            _content = request.form['inputContent']
            _user = session.get('user')

        if _content and _user:
            print (_content, " ", _user)

            cur = mysql.connection.cursor()
            cur.callproc('sp_newPost', (0, _content, _user, "/"))
            rv = cur.fetchall()

            if len(rv) is 0:
                mysql.connection.commit()
                return redirect('/feed')
            else:
                return render_template('error.html', error=str(rv))
        else:
            return render_template('error.html', error='Enter all values')
    else:
        return render_template('error.html', error='Unauthorised')

@application.route('/getAllPosts')
def getAllPosts():
    try:
        if session.get('user'):
            _user = session.get('user')

            cur = mysql.connection.cursor()
            cur.callproc('sp_getAllPosts', (_user,))
            rv = cur.fetchall()

            posts_dict = []
            for post  in rv:
                post_dict = {
                    'Id': post[0],
                    'Text': post[1],
                    'Uid': post[2]
                }
                posts_dict.append(post_dict)
            cur.close()
            return json.dumps(posts_dict)
        else:
            return render_template('error.html', error = "Unauthorised")
    except Exception as e:
        return render_template('error.html', error = str(e))


@application.route('/getFriends/<int:uid>')
def getFriends(uid):
    if session.get('user'):
        try:
            cur = mysql.connection.cursor()
            cur.callproc('sp_getFriends', (uid))
            print("Result")
            print(rv)
            rv = cur.fetchall()
            cur.close()

            friends_dict = []

            if len(rv) > 0:
                for friend in rv:
                    fullName = str(friend[2]) + " " + str(friend[3])

                    friend_dict = {
                    'Id': friend[0],
                    'Name': fullName
                    }
                    friends_dict.append(friend_dict)
                return json.dumps(friends_dict)
        except Exception as e:
            return json.dumps({'error': str(e)})
    else:
        return json.dumps({'error': 'Unauthorised'})

@application.route('/logout')
def logout():

    # Set user session to null
    session.pop('user', None)
    return redirect('/')
