# ruff: noqa: T201
from __future__ import annotations

import json
import subprocess
from collections import defaultdict
from pathlib import Path

import tree_sitter_python as tspython
import typer
from tree_sitter import Language, Parser

import python_import
from python_import.ts_utils import get_node
from python_import.utils import get_all_imports_in_file_as_absolute

PY_LANGUAGE = Language(tspython.language())

app = typer.Typer(context_settings={"help_option_names": ["-h", "--help"]})


def version_callback(value: bool):
    if value:
        print(f"python-import v{python_import.__version__}")
        raise typer.Exit()


@app.callback()
def common(
    ctx: typer.Context,
    version: bool = typer.Option(None, "-v", "--version", callback=version_callback),
):
    pass


def find_matches(project_root: str, keyword: str) -> dict[str, list[tuple[int, int]]]:
    # NOTE: rg json outputs are (1, 0)-indexed
    rg_outputs = subprocess.run(
        [
            "fd",
            "-e",
            "py",
            "-x",
            "rg",
            "--word-regexp",
            "--fixed-strings",
            "--json",
            keyword,
        ],
        cwd=project_root,
        capture_output=True,
    )
    # print(rg_outputs)

    # 0-indexed row, col
    file_path_to_rowcol: dict[str, list[tuple[int, int]]] = defaultdict(list)
    for line in rg_outputs.stdout.decode("utf-8").split("\n"):
        if not line:
            continue
        # print(line)
        rg_output = json.loads(line)
        # print(rg_output["type"])
        if rg_output["type"] == "match":
            file_path = str(
                (Path(project_root) / rg_output["data"]["path"]["text"]).resolve()
            )
            row = rg_output["data"]["line_number"] - 1
            col = rg_output["data"]["submatches"][0]["start"]
            # col_end = rg_output["data"]["submatches"][0]["end"]
            file_path_to_rowcol[file_path].append((row, col))

    # print(file_path_to_rowcol)
    return file_path_to_rowcol


@app.command()
def count(
    project_root: str,
    module_name: str,
) -> None:
    """
    Count python imports in a project and print them in descending order of count.

    For example,
    00002:from my_module import logging
    00001:import logging

    Todo:
        - [ ] Test import abcd
        - [ ] Test import abcd as efg
        - [ ] Test import a.b.c
        - [ ] Test import a, b, c as d, e
        - [ ] Test import a, b, c, d
        - [ ] Test from a import b
        - [ ] Test from a import b as c
        - [ ] Test from a import b, c
        - [ ] Test from a import b, c as d, e
        - [ ] Test from a.keyword.c import d  (should not be counted. keyword has to be import or as, not in from)
        - [ ] Test imports within a function
        - [ ] Test relative imports
    """
    parser = Parser(PY_LANGUAGE)

    file_path_to_rowcol = find_matches(project_root, module_name)
    import_statement_to_count: dict[str, int] = defaultdict(int)

    for python_file_path, rowcols in file_path_to_rowcol.items():
        import_statement_to_count_file = get_all_imports_in_file_as_absolute(
            project_root=project_root,
            python_file_path=python_file_path,
            parser=parser,
            rowcols=rowcols,
        )

        # merge counts
        for import_statement, count in import_statement_to_count_file.items():
            import_statement_to_count[import_statement] += count

    # sort and print as json-line
    for import_statement, count in sorted(
        import_statement_to_count.items(), key=lambda x: x[1], reverse=True
    ):
        print(f"{count:05d}:{import_statement}")
    #     print(
    #         json.dumps(
    #             {"import_statement": import_statement, "count": count},
    #             indent=None,
    #             separators=(",", ":"),
    #         )
    #     )


@app.command()
def from_definition(
    project_root: str,
    name_to_find: str,
) -> None:
    """
    Find all definitions of a module in a project and print like `from found_module import name_to_find`.

    For example, it will find `def name_to_find():` or `class name_to_find:` or `name_to_find = 123`.
    """
    parser = Parser(PY_LANGUAGE)

    file_path_to_rowcol = find_matches(project_root, name_to_find)
    for python_file_path, rowcols in file_path_to_rowcol.items():
        # find `def name_to_find():` but it has to be module-level. Decorators may be present.
        with open(python_file_path) as f:
            lines: str = f.read()

        tree = parser.parse(bytes(lines, "utf8"))

        for rowcol in rowcols:
            node = get_node(tree, rowcol)
            if node.type == "identifier":
                print(node.parent)
                print(node.parent.parent.text)


def version():
    print(python_import.__version__)


if __name__ == "__main__":
    app()
