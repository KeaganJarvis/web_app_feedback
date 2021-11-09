import unittest
from post_feedback_to_asana import get_results_from_db
from db import Comments

class TestApplication(unittest.TestCase):

    def test_creating_comment_positive(self):
        Comments.create(comment="test_comment",
                        is_positive=True,
                        user_agent = "Test Agent",
                        url = "test URL",
                        search_terms = "Test terms",
                        email = "test@t.com"
                        )
        positive_comments = Comments.select().where(Comments.is_positive==True)
        self.assertEqual(len(positive_comments), 1, f"Should be 1")
        # clean up:
        positive_comments.get().delete_instance(recursive=True)

    def test_creating_comment_negative(self):
        Comments.create(comment="test_comment",
                        is_positive=False,
                        user_agent = "Test Agent",
                        url = "test URL",
                        search_terms = "Test terms",
                        email = "test@t.com"
                        )
        negative_comments = Comments.select().where(Comments.is_positive==False)
        self.assertEqual(len(negative_comments), 1, f"Should be 1")
        # clean up:
        negative_comments.get().delete_instance(recursive=True)

    def test_summarise_last_24_hours_no_posts(self):
        results = {
            "num_of_positive": 0,
            "num_of_negative": 0,
            "percentage_of_positive": "NaN",
            "percentage_of_negative": "NaN",
        }
        self.assertEqual(get_results_from_db(), results, f"Should be {results}")

    def test_summarise_last_24_hours_existing_posts(self):
        # create 3x negative comments
        for i in range(3):
            Comments.create(comment="test_comment",
                        is_positive=False,
                        user_agent = "Test Agent",
                        url = "test URL",
                        search_terms = "Test terms",
                        email = "test@t.com"
                        )
        # create 1x positive
        Comments.create(comment="test_comment",
                        is_positive=True,
                        user_agent = "Test Agent",
                        url = "test URL",
                        search_terms = "Test terms",
                        email = "test@t.com"
                        )
        results = {
            "num_of_positive": 1,
            "num_of_negative": 3,
            "percentage_of_positive": 25,
            "percentage_of_negative": 75,
        }
        self.assertEqual(get_results_from_db(), results, f"Should be {results}")
        # clean up:
        for c in Comments.select():
            c.delete_instance(recursive=True)

# Tests against application_server be testing the `Flask` library, which gets tested itself before builds/releases,
# therefore not necessary.
# Testing post_results_to_asana is testing the `asana` library which gets tested itself before builds/releases
if __name__ == '__main__':
    """
    Unit tests that cover the ability to create comments correctly, as well as to summarize the results
    of comments within the last 24 hours.
    """
    unittest.main()