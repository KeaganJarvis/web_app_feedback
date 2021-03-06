#!/web_app_venv/bin/python
from flask import Flask, request, jsonify, abort, render_template, session, Response
from db import Comments
import json
app = Flask(__name__)

@app.route('/', methods=['GET'])
def get_landing():
    return render_template('landing_page.html')

@app.route('/thanks', methods=['GET'])
def get_thanks():
    return render_template('thanks_page.html')

@app.route('/submit_comment', methods=['POST'])
def submit_comment():
    if request.values.get("is_positive") != 'true' and request.values.get("is_positive") != 'false':
        return json.dumps({'result':'error'}), 400 # covers the case where someone is bypassing website to post to this route/end point.
    is_positive = request.values.get("is_positive") == 'true' # JS request coming through on server as str, even though is bool in client obj
    user_agent = request.headers.get('User-Agent')
    comment = request.values.get("comment")
    url = request.values.get("url")
    search_terms = request.values.get("terms")
    email = request.values.get("email")
    # Data validation would go here against `comment` `url` `search_terms` and `email`
    # to prevent injections, for now trusting the ORM
    # also would do regex for email validation,
    try:
        Comments.create(comment=comment,
                        is_positive=is_positive,
                        user_agent = user_agent,
                        url = url,
                        search_terms = search_terms,
                        email = email
                        )
    except Exception as e: # blanket `except` for now
        app.logger.exception(e)
        return json.dumps({'result':'error'}), 400
    return json.dumps({'result':'success'}), 200


if __name__ == '__main__':
    """
    Main function, only necessary for quick testing/direct running, this does not get used when utilising
    uwsgi and ngnix services/daemons
    """
    app.run(host= '0.0.0.0', port=80)