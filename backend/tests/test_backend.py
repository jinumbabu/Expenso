import os
import sys
import unittest

# Add parent directory to path so we can import app
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import init_db, create_user, get_user_by_id, update_user
from app.routers.ai import parse_expense_with_rules

class TestBackendComponents(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        from app.database import DB_PATH
        if os.path.exists(DB_PATH):
            try:
                os.remove(DB_PATH)
            except Exception:
                pass
        # Initialize the db (creates backend.db in data/ folder)
        init_db()

    def test_database_operations(self):
        user_id = "test-user-123"
        google_id = "test-google-id-456"
        email = "tester@expenso.ai"
        name = "Test User"
        
        # Test Create User
        user = create_user(
            user_id=user_id,
            google_id=google_id,
            email=email,
            display_name=name,
            currency="INR",
            country="IN"
        )
        
        self.assertIsNotNone(user)
        self.assertEqual(user["id"], user_id)
        self.assertEqual(user["email"], email)
        self.assertEqual(user["currency"], "INR")
        
        # Test Get User
        fetched = get_user_by_id(user_id)
        self.assertIsNotNone(fetched)
        self.assertEqual(fetched["display_name"], name)
        
        # Test Update User
        updated = update_user(
            user_id=user_id,
            display_name="Updated Jinu",
            currency="USD",
            country="US"
        )
        self.assertIsNotNone(updated)
        self.assertEqual(updated["display_name"], "Updated Jinu")
        self.assertEqual(updated["currency"], "USD")
        self.assertEqual(updated["country"], "US")

    def test_rule_based_parser(self):
        # Test 1: Food parsing
        res = parse_expense_with_rules("spent 250 on tea")
        self.assertIsNotNone(res)
        self.assertEqual(res.amount, 250.0)
        self.assertEqual(res.category, "Food")
        self.assertEqual(res.merchant, "Tea")
        self.assertEqual(res.type, "expense")
        self.assertGreaterEqual(res.confidence, 0.80)
        
        # Test 2: Fuel parsing
        res = parse_expense_with_rules("fuel 1500")
        self.assertIsNotNone(res)
        self.assertEqual(res.amount, 1500.0)
        self.assertEqual(res.category, "Fuel")
        self.assertEqual(res.type, "expense")
        
        # Test 3: Income parsing
        res = parse_expense_with_rules("received salary 35000")
        self.assertIsNotNone(res)
        self.assertEqual(res.amount, 35000.0)
        self.assertEqual(res.category, "Salary")
        self.assertEqual(res.type, "income")
        
        # Test 4: Shopping parsing
        res = parse_expense_with_rules("amazon order 2500")
        self.assertIsNotNone(res)
        self.assertEqual(res.amount, 2500.0)
        self.assertEqual(res.category, "Shopping")
        self.assertEqual(res.merchant, "Amazon Order")

if __name__ == "__main__":
    unittest.main()
