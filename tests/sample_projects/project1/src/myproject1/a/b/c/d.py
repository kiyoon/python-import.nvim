from __future__ import annotations

from foo import bar
from ....utils.a.b.c import relative1


def lazy_import():
    from ... import relative_three_dots


def foo1():
    from python_import import foo

def foo2():
    from python_import import foo

def foo3():
    from python_import import foo

def invalid1():
    from python_import import foo as bar
