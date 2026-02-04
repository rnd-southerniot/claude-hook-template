"""Greeter module with customizable greetings."""


class Greeter:
    """A class that generates personalized greetings."""

    def __init__(self, name: str = "World") -> None:
        """Initialize the greeter with a name.

        Args:
            name: The name to greet. Defaults to "World".
        """
        self.name = name

    def greet(self) -> str:
        """Generate a greeting message.

        Returns:
            A personalized greeting string.
        """
        return f"Hello, {self.name}!"

    def formal_greet(self) -> str:
        """Generate a formal greeting message.

        Returns:
            A formal greeting string.
        """
        return f"Good day, {self.name}. How may I assist you?"


def greet(name: str = "World") -> str:
    """Convenience function for simple greetings.

    Args:
        name: The name to greet. Defaults to "World".

    Returns:
        A personalized greeting string.
    """
    return Greeter(name).greet()
