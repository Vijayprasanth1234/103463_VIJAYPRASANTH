"""
Tests for the main module.
"""
import unittest
import sys
import os

# Add the parent directory to the path so we can import the src module
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src.main import main

class TestMain(unittest.TestCase):
    """Test cases for the main module."""
    
    def test_main_runs_without_error(self):
        """Test that the main function runs without raising an exception."""
        try:
            main()
            self.assertTrue(True)  # If we get here, no exception was raised
        except Exception as e:
            self.fail(f"main() raised {type(e).__name__} unexpectedly!")

if __name__ == '__main__':
    unittest.main()