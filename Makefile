ISABELLE = isabelle
PYTEST = uv run pytest
PYTHON = uv run python3
# ty finds the casts that are there for mypy redundant
TY = uv run ty check --python-version 3.12 --no-progress --ignore redundant-cast

default: build

build-test-slow:
	$(ISABELLE) build -d . -e Python_Test_Slow

test-slow: build-test-slow
	$(PYTHON) -m py_compile test/slow/generated_basic/*.py
	$(PYTHON) -m py_compile test/slow/generated_full/*.py
	$(PYTEST) test/slow/run_test.py

build-test-quick:
	$(ISABELLE) build -d . -e Python_Test_Quick
	
test-quick:
	$(PYTEST) test/quick/run_test.py

# -c: a changed python_type_annotations does not rebuild the session by itself
build-examples:
	$(ISABELLE) build -d . -c -e Python_Examples

test-diff: build-examples
	$(PYTEST) test/diff/run_test.py

build-test-oracle:
	$(ISABELLE) build -d . -e Python_Test_Oracle

test-oracle: build-test-oracle
	$(PYTEST) test/oracle/run_test.py

typecheck-diff:
	$(ISABELLE) build -d . -c -o python_type_annotations -e Python_Examples
	$(PYTEST) test/diff/run_test.py
	status=0; for d in examples/python_out/*/code; do uv run mypy $$d || status=1; done; exit $$status
	status=0; for d in examples/python_out/*/code; do $(TY) --extra-search-path $$d $$d || status=1; done; exit $$status

typecheck-slow:
	$(ISABELLE) build -d . -c -o python_type_annotations -e Python_Test_Slow
	uv run mypy test/slow/generated_basic
	uv run mypy test/slow/generated_full
	$(TY) --extra-search-path test/slow/generated_basic test/slow/generated_basic
	$(TY) --extra-search-path test/slow/generated_full test/slow/generated_full

reseed:	build-examples
	$(PYTHON) test/diff/reseed_goldens.py

reseed-annotated:
	$(ISABELLE) build -d . -c -o python_type_annotations -e Python_Examples
	$(PYTHON) test/diff/reseed_goldens.py

reserved-words:
	$(PYTHON) etc/update_reserved_words.py

test-all: test-quick test-slow test-diff test-oracle

test: test-quick

build:
	$(ISABELLE) build -d . -e Python

.PHONY: default build-test-slow test-slow build-test-quick test-quick build-examples test-diff typecheck-diff typecheck-slow reseed reseed-annotated test-all test build-test-oracle test-oracle build reserved-words




