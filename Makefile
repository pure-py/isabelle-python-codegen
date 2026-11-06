ISABELLE = isabelle
# The build targets delete their python_out/ first: export_files only adds and
# overwrites, so modules a build no longer produces would otherwise linger
# (and end up in test/diff/golden/ on the next reseed).
PYTEST = uv run pytest
PYTHON = uv run python3

default: build

build-test-slow:
	$(ISABELLE) build -d . -e Python_Test_Slow

test-slow: build-test-slow
	$(PYTHON) -m py_compile test/slow/generated_basic/*.py
	$(PYTHON) -m py_compile test/slow/generated_full/*.py
	$(PYTEST) test/slow/run_test.py

build-test-quick:
	rm -rf test/quick/python_out
	$(ISABELLE) build -d . -e -c Python_Test_Quick
	
test-quick: build-test-quick
	$(PYTEST) test/quick/run_test.py

build-examples:
	rm -rf examples/python_out
	$(ISABELLE) build -d . -e -c Python_Examples

test-diff: build-examples
	$(PYTEST) test/diff/run_test.py

build-test-oracle:
	rm -rf test/oracle/python_out
	$(ISABELLE) build -d . -e -c Python_Test_Oracle

test-oracle: build-test-oracle
	$(PYTEST) test/oracle/run_test.py

test-names:
	$(PYTEST) test/test_unique_names.py

reseed:	build-examples
	$(PYTHON) test/diff/reseed_goldens.py

reserved-words:
	$(PYTHON) etc/update_reserved_words.py

test-all: test-quick test-slow test-diff test-oracle test-names

test: test-quick

build:
	$(ISABELLE) build -d . -e -c Python

.PHONY: default build-test-slow test-slow build-test-quick test-quick build-examples test-diff reseed test-all test build-test-oracle test-oracle test-names build reserved-words




