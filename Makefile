ISABELLE = isabelle
PYTEST = uv run pytest
PYTHON = uv run python3

default: build

build-test-slow:
	$(ISABELLE) build -d . -e Python_Test_Slow

test-slow: build-test-slow
	$(PYTHON) -m py_compile test/slow/generated_basic/*.py
	$(PYTHON) -m py_compile test/slow/generated_full/*.py

build-test-quick:
	$(ISABELLE) build -d . -e Python_Test_Quick
	
test-quick:
	$(PYTEST) test/quick/run_test.py

build-examples:
	$(ISABELLE) build -d . -e Python_Examples

test-diff: build-examples
	$(PYTEST) test/diff/run_test.py

build-test-oracle:
	$(ISABELLE) build -d . -e Python_Test_Oracle

test-oracle: build-test-oracle
	$(PYTEST) test/oracle/run_test.py

reseed:	build-examples
	$(PYTHON) test/diff/reseed_goldens.py

test-all: test-quick test-slow test-diff test-oracle

test: test-quick

build:
	$(ISABELLE) build -d . -e Python

.PHONY: default build-test-slow test-slow build-test-quick test-quick build-examples test-diff reseed test-all test build-test-oracle test-oracle build




