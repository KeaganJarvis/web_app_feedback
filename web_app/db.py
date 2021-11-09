#!/web_app_venv/bin/python
from peewee import SqliteDatabase, Model, CharField, BooleanField, DateTimeField
import datetime

db = SqliteDatabase('/web_app_feedback/web_app/application.db')

class BaseModel(Model):
    class Meta:
        database = db

class Comments(BaseModel):
    comment = CharField()
    is_positive = BooleanField()
    creation_timestamp = DateTimeField(default=datetime.datetime.now)

db.connect()
db.create_tables([Comments])
