#!/usr/bin/env python3
"""Hello World CLI application."""

import argparse

from hello import Greeter


def main() -> None:
    """Main entry point for the Hello World application."""
    parser = argparse.ArgumentParser(
        description="A simple Hello World application",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python main.py                  # Prints "Hello, World!"
  python main.py --name Claude    # Prints "Hello, Claude!"
  python main.py -n Claude -f     # Prints formal greeting
        """,
    )
    parser.add_argument(
        "-n",
        "--name",
        default="World",
        help="Name to greet (default: World)",
    )
    parser.add_argument(
        "-f",
        "--formal",
        action="store_true",
        help="Use formal greeting style",
    )

    args = parser.parse_args()

    greeter = Greeter(args.name)

    if args.formal:
        print(greeter.formal_greet())
    else:
        print(greeter.greet())


if __name__ == "__main__":
    main()
