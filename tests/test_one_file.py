from __future__ import annotations

import logging
from pathlib import Path

import tree_sitter_python as tspython
from tree_sitter import Language, Parser

from python_import.utils import get_all_imports_in_file_as_absolute_with_word

logger = logging.getLogger(__name__)


SCRIPT_DIR = Path(__file__).parent
PY_LANGUAGE = Language(tspython.language())
parser = Parser(PY_LANGUAGE)


def test_multiple_counts():
    imports = get_all_imports_in_file_as_absolute_with_word(
        SCRIPT_DIR / "sample_projects/project1",
        SCRIPT_DIR / "sample_projects/project1/src/myproject1/a/b/c/d.py",
        parser,
        "foo",
    )

    # not "from python_import import foo as bar"
    # not from foo import bar
    assert imports == {
        "from python_import import foo": 3,
    }


def test_multiple_statements():
    imports = get_all_imports_in_file_as_absolute_with_word(
        SCRIPT_DIR / "sample_projects/project1",
        SCRIPT_DIR / "sample_projects/project1/src/myproject1/a/b/c/d.py",
        parser,
        "bar",
    )

    assert imports == {
        "from foo import bar": 1,
        "from python_import import foo as bar": 1,
    }


def test_relative1():
    imports = get_all_imports_in_file_as_absolute_with_word(
        SCRIPT_DIR / "sample_projects/project1",
        SCRIPT_DIR / "sample_projects/project1/src/myproject1/a/b/c/d.py",
        parser,
        "relative1",
    )

    assert imports == {
        "from myproject1.utils.a.b.c import relative1": 1,
    }


def test_relative_three_dots():
    # from ... import relative_three_dots1
    imports = get_all_imports_in_file_as_absolute_with_word(
        SCRIPT_DIR / "sample_projects/project1",
        SCRIPT_DIR / "sample_projects/project1/src/myproject1/a/b/c/d.py",
        parser,
        "relative_three_dots",
    )

    assert imports == {
        "from myproject1.a import relative_three_dots": 1,
    }
