# Usage Guide

## Setting Up the Repository

To set up the repository structure, run:

```bash
./setup.sh
```

This script will create all necessary files and folders for the project.

## Running the Application

To run the main application:

```bash
python src/main.py
```

## Running Tests

To run the tests:

```bash
python -m unittest discover tests
```

## Project Structure

- `src/`: Contains the source code for the application
  - `main.py`: The main entry point for the application
  - `__init__.py`: Package initialization file

- `tests/`: Contains unit tests
  - `test_main.py`: Tests for the main module
  - `__init__.py`: Test package initialization file

- `docs/`: Contains documentation
  - `index.md`: Main documentation page
  - `usage.md`: This usage guide

- `config/`: Contains configuration files
  - `settings.json`: Application settings