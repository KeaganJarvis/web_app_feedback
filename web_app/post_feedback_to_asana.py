#!/web_app_venv/bin/python
from db import Comments
import datetime
import asana
import os
import traceback

# TODO NB how to keep Asana token out of commits? Secrets manager?

def get_results_from_db():
    results = {
        "num_of_positive": 0,
        "num_of_negative": 0,
        "percentage_of_positive": "NaN", #default to NaN in case no comments
        "percentage_of_negative": "NaN",
    }
    one_day_ago = datetime.datetime.now() - datetime.timedelta(hours=24)
    postive_comments = Comments.select().where(Comments.creation_timestamp>one_day_ago, Comments.is_positive==True)
    negative_comments = Comments.select().where(Comments.creation_timestamp>one_day_ago, Comments.is_positive==False)
    num_of_positive = len(postive_comments)
    num_of_negative = len(negative_comments)
    results['num_of_positive'] = num_of_positive
    results['num_of_negative'] = num_of_negative
    if num_of_positive + num_of_negative != 0:
        results['percentage_of_positive'] = (num_of_positive / (num_of_positive + num_of_negative)) * 100
        results['percentage_of_negative'] = (num_of_negative / (num_of_positive + num_of_negative)) * 100
    return results


def post_results_to_asana(asana_client, results):
    asana_client = asana.Client.access_token(os.environ['ASANA_ACCESS_TOKEN'])
    task_description = f"""
Positive comments: {results['percentage_of_positive']}%
negative comments: {results['percentage_of_negative']}%
Total postive: {results['num_of_positive']}
Total negative: {results['num_of_negative']}
"""
# TODO check tabbing/formatting of above
    todays_date = datetime.date.today()
    data = {
        "completed": False,
        "name": f"Daily summary from feedback site for {todays_date}",
        "notes": task_description,
        "resource_subtype": "default_task",
        "projects": ["1201154200912959"]
    }
    asana_client.tasks.create_task(data)

def post_failure_to_asana(asana_client, msg):
    data = {
        "completed": False,
        "name": f"Error in script creating daily summary task",
        "notes": msg,
        "resource_subtype": "default_task",
        "projects": ["1201154200912959"]
    }
    asana_client.tasks.create_task(data)

if __name__ == "__main__":
    asana_client = asana.Client.access_token(os.environ['ASANA_ACCESS_TOKEN'])
    try:
        results = get_results_from_db()
        post_results_to_asana(asana_client,results)
    except:
        # If this script ever fails this will create an asana ticket letting us know about it,
        # therefore it does not fail silently (caveat is if the asana auth/posting steps fails then that gets missed)
        post_failure_to_asana(asana_client, traceback.format_exc())