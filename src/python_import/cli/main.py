# ruff: noqa: UP007, T201
from __future__ import annotations

import json
import subprocess
from collections import defaultdict
from pathlib import Path

import tree_sitter_python as tspython
import typer
from tree_sitter import Language, Parser

import python_import
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
            module_name,
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
def dummy_do_not_use() -> None:
    print(count.__doc__)


def version():
    print(python_import.__version__)


if __name__ == "__main__":
    app()
