.PHONY: test build venv

# pick 'venv' if it exists, otherwise pick '.venv'
VENV:=$(shell test -d venv && echo 'venv' || echo '.venv')

PY = $(VENV)/bin/python
PIP = $(PY) -m pip
SRC_DIR=./src/
TEST_DIR=./tests/
# Uses git diff to get changed files, and filters down to '.py' files.
DIFF=git diff --name-only | grep *.py | cat

build: dist

dist: install clean
	$(PY) -m hatchling build

untar:
	tar -xzf dist/*.tar.gz -C dist/

test: venv
	set -a; source ./tests.env; set +a;  PYTHONPATH=$(SRC_DIR) $(PY) -m unittest discover $(TEST_DIR)

coverage:
	echo 'todo'
lint:
	@echo "Applying isort to diff"
	@$(DIFF) | xargs -r $(PY) -m isort
	@echo "Applying black formatter to diff"
	@$(DIFF) | xargs -r $(PY) -m black

lint-project:
	@echo "Applying isort"
	@$(PY) -m isort .
	@echo "Applying black formatter"
	@$(PY) -m black .

clean:
	@echo rm -rf dist
	@test -d dist && rm -rf dist || :
	@$(PY) clean.py $(SRC_DIR)
	@$(PY) clean.py $(TEST_DIR)


requirements:
	@# Take requirements from pyproject, and put them in a separate file (-o <filename).
	@# --strip-extras means the 'extra' should not be included by default.
	@# --extra  means taking the optional based on a specific install spec (like myproject[dev]).

	@echo "Compiling requirements.txt"
	@test -d $(VENV) && $(PY) -m piptools compile -q --strip-extras -o requirements.txt pyproject.toml > /dev/null

	@echo "Compiling requirements-dev.txt"
	@test -d $(VENV) && $(PY) -m piptools compile -q --strip-extras --extra dev -o requirements-dev.txt pyproject.toml > /dev/null

install: venv
	@echo test -f requirements-dev.txt || exit 1
	@test -f requirements-dev.txt || (echo "Developer requirements not found, please make requirements." && exit 1)
	$(PIP) install -r requirements-dev.txt

venv:
	test -d $(VENV) || python -m venv $(VENV)

_piptools:
	@echo "Installing pip-tools to compile requirements"
	$(PIP) install pip-tools hatchling

dev: venv _piptools requirements install