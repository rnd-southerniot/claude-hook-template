# Hello World Example

A simple Python application demonstrating a project created with the Claude Code hooks template.

## Setup

```bash
# From template root, copy to new location
cp -r examples/hello-world ~/my-hello-world
cd ~/my-hello-world

# Add Claude Code hooks
~/claude-code-template/setup.sh
# When prompted: Target directory: .
# Choose [M]erge to add hooks to existing project
```

## Usage

```bash
# Run the application
python main.py                    # Hello, World!
python main.py --name Claude      # Hello, Claude!
python main.py -n "Your Name" -f  # Formal greeting

# Run tests
uv run pytest tests/ -v
```

## Project Structure

```
hello-world/
├── main.py              # CLI entry point
├── hello/
│   ├── __init__.py      # Package exports
│   └── greeter.py       # Greeter class
├── tests/
│   ├── __init__.py
│   └── test_greeter.py  # 10 test cases
└── pyproject.toml       # Project config
```

## Features Demonstrated

- Clean Python package structure
- CLI with argparse
- Pytest test suite with parametrized tests
- Type hints throughout
- pyproject.toml configuration
