"""Tests for the greeter module."""

import pytest

from hello import Greeter, greet


class TestGreeter:
    """Tests for the Greeter class."""

    def test_default_greeting(self) -> None:
        """Test greeting with default name."""
        greeter = Greeter()
        assert greeter.greet() == "Hello, World!"

    def test_custom_greeting(self) -> None:
        """Test greeting with custom name."""
        greeter = Greeter("Claude")
        assert greeter.greet() == "Hello, Claude!"

    def test_formal_greeting(self) -> None:
        """Test formal greeting."""
        greeter = Greeter("Claude")
        assert greeter.formal_greet() == "Good day, Claude. How may I assist you?"

    def test_name_attribute(self) -> None:
        """Test that name attribute is set correctly."""
        greeter = Greeter("Test")
        assert greeter.name == "Test"


class TestGreetFunction:
    """Tests for the greet convenience function."""

    def test_default_greet(self) -> None:
        """Test greet function with default name."""
        assert greet() == "Hello, World!"

    def test_custom_greet(self) -> None:
        """Test greet function with custom name."""
        assert greet("Claude") == "Hello, Claude!"

    @pytest.mark.parametrize(
        "name,expected",
        [
            ("Alice", "Hello, Alice!"),
            ("Bob", "Hello, Bob!"),
            ("", "Hello, !"),
            ("Claude Code", "Hello, Claude Code!"),
        ],
    )
    def test_various_names(self, name: str, expected: str) -> None:
        """Test greet function with various names."""
        assert greet(name) == expected
