"""
Writes etc/python_reserved_words: the keywords, soft keywords and builtins of
the Python version in .python-version, which generated names must not hide.
Python.thy reserves every name in that file.

Run it with that Python, as the make target does through uv:

    make reserved-words
"""

import builtins
import keyword
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "etc" / "python_reserved_words"


def main():
    version = (ROOT / ".python-version").read_text().strip()
    running = ".".join(map(str, sys.version_info[:len(version.split("."))]))
    if running != version:
        sys.exit(f"{Path(__file__).name}: running Python {running}, but "
                 f".python-version names {version}")

    # _ is the wildcard pattern the generator prints, so it stays usable
    names = keyword.kwlist + [k for k in keyword.softkwlist if k != "_"] + dir(builtins)
    lines = [f"# Keywords and builtins of Python {version}, written by "
             f"etc/{Path(__file__).name}"]
    lines += list(dict.fromkeys(names))
    OUT.write_text("\n".join(lines) + "\n")
    print(f"wrote {len(lines) - 1} names to {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
