#!/web_app_venv/bin/python
import datetime

# db commands needed :
one_day_ago = datetime.datetime.now() - datetime.timedelta(hours=24)
cs = Comments.select().where(Comments.creation_timestamp>five_mins_ago)