#!/web_app_venv/bin/python
from flask import Flask, request, jsonify, abort, render_template, session, Response
from db import Comments
import json
app = Flask(__name__)

@app.route('/', methods=['GET'])
def get_landing():
    # return Comments.select().get().comment
    return render_template('landing_page.html')

@app.route('/thanks', methods=['GET'])
def get_thanks():
    # return Comments.select().get().comment
    return render_template('thanks_page.html')

@app.route('/submit_comment', methods=['POST'])
def submit_comment():
    if request.values.get("is_positive") != 'true' and request.values.get("is_positive") != 'false':
        return json.dumps({'result':'error'}), 400 # covers the case where someone is bypassing website to post to this route/end point.
    is_positive = request.values.get("is_positive") == 'true' # TODO JS request coming through on server as str, even though is bool in client obj
    comment = request.values.get("comment")
    Comments.create(comment=comment,is_positive=is_positive)
    import pudb; pudb.set_trace()
    return json.dumps({'result':'success'}), 200

if __name__ == '__main__':
    app.run(host= '0.0.0.0', port=80) # TODO port 80 rework when using https