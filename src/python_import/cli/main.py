# ruff: noqa: UP007
from __future__ import annotations

import json
import subprocess
from collections import defaultdict
from os import PathLike
from pathlib import Path

import tree_sitter
import tree_sitter_python as tspython
import typer
from tree_sitter import Language, Parser

PY_LANGUAGE = Language(tspython.language())

app = typer.Typer(context_settings={"help_option_names": ["-h", "--help"]})


def _get_node(tree: tree_sitter.Tree, row_col: tuple[int, int]):
    named_node = tree.root_node.named_descendant_for_point_range(row_col, row_col)
    # named_node = tree.root_node.descendant_for_point_range((row, col), (row, col))
    return named_node


def relative_import_to_absolute_import(
    project_root: str | PathLike,
    python_file_path: str | PathLike,
    from_import_name: str,
):
    count_num_dots = 0
    for i in range(len(from_import_name)):
        if from_import_name[i] == ".":
            count_num_dots += 1
        else:
            break

    if count_num_dots == 0:
        # absolute import
        return from_import_name

    module_path = Path(python_file_path)
    for _ in range(count_num_dots):
        module_path = module_path.parent

    module_path = module_path / from_import_name[count_num_dots:]

    # get relative path from project root or src/ directory in project root
    project_root = Path(project_root)
    if project_root.is_dir():
        src_dir = project_root / "src"
        if src_dir.is_dir():
            project_root = src_dir

    try:
        relative_path = module_path.relative_to(project_root)
    except ValueError:
        # not in project root
        if project_root.stem == "src":
            # try without src/ directory
            project_root = project_root.parent
            relative_path = module_path.relative_to(project_root)
        else:
            # just return the original import name
            return from_import_name
    return str(relative_path).replace("/", ".")


@app.command()
def count(
    project_root: str,
    module_name: str,
) -> None:
    """
    Todo:
        - [ ] Test import abcd
        - [ ] Test import abcd as efg
        - [ ] Test import a, b, c as d, e
        - [ ] Test import a, b, c, d
        - [ ] Test from a import b
        - [ ] Test from a import b as c
        - [ ] Test from a import b, c
        - [ ] Test from a import b, c as d, e
        - [ ] Test imports within a function
        - [ ] Test relative imports
    """
    parser = Parser(PY_LANGUAGE)
    tree = parser.parse(bytes("import " + module_name, "utf8"))

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

    for file_path, rowcols in file_path_to_rowcol.items():
        with open(file_path) as f:
            lines: str = f.read()

        tree = parser.parse(bytes(lines, "utf8"))

        # tree.root_node_with_offset(
        # get node at position

        # import .. as ..
        #
        # (import_statement ; [15, 0] - [15, 18]
        #   name: (aliased_import ; [15, 7] - [15, 18]
        #     name: (dotted_name ; [15, 7] - [15, 12]
        #       (identifier)) ; [15, 7] - [15, 12]
        #     alias: (identifier))) ; [15, 16] - [15, 18]
        #
        # from .. import .. as ..
        #
        # (import_from_statement ; [2, 0] - [7, 1]
        #   module_name: (dotted_name ; [2, 5] - [2, 40]
        #     (identifier) ; [2, 5] - [2, 20]
        #     (identifier) ; [2, 21] - [2, 27]
        #     (identifier) ; [2, 28] - [2, 31]
        #     (identifier)) ; [2, 32] - [2, 40]
        #   name: (dotted_name ; [3, 4] - [3, 25]
        #     (identifier)) ; [3, 4] - [3, 25]
        #   name: (dotted_name ; [4, 4] - [4, 30]
        #     (identifier)) ; [4, 4] - [4, 30]
        #   name: (dotted_name ; [5, 4] - [5, 17]
        #     (identifier)) ; [5, 4] - [5, 17]
        #   name: (aliased_import ; [6, 4] - [6, 32]
        #     name: (dotted_name ; [6, 4] - [6, 25]
        #       (identifier)) ; [6, 4] - [6, 25]
        #     alias: (identifier))) ; [6, 29] - [6, 32]

        # query = PY_LANGUAGE.query("""
        #     (import_statement name: (dotted_name) @import)
        #     (import_statement name: (aliased_import alias: (identifier) @import_as))
        #     (import_from_statement name: (dotted_name) @from_import)
        #     (import_from_statement name: (aliased_import alias: (identifier) @from_import_as))
        #     """)

        for row_col in rowcols:
            # match = query.matches(
            #     tree.root_node,
            #     start_point=(row_col_colend[0], row_col_colend[1]),
            #     end_point=(row_col_colend[0], row_col_colend[1]),
            # )
            # print(match)

            node = _get_node(tree, row_col)
            if node is None or node.type != "identifier":
                continue

            # print(node)
            # print(node.type)
            # print("node.text ", node.text)
            # print("node.parent ", node.parent)
            # print("node.parent.text ", node.parent.text)

            if node.parent is None or node.parent.type not in [
                "dotted_name",
                "aliased_import",
            ]:
                continue

            if node.parent.type == "aliased_import":
                assert node.parent.parent is not None

                if node.parent.parent.type == "import_statement":
                    # import .. as ..
                    import_name_node = node.parent.child_by_field_name("name")
                    assert import_name_node is not None
                    import_name = import_name_node.text
                    assert import_name is not None
                    import_name = import_name.decode("utf-8")

                    import_as_node = node.parent.child_by_field_name("alias")
                    assert import_as_node is not None
                    import_as = import_as_node.text
                    assert import_as is not None
                    import_as = import_as.decode("utf-8")

                    import_statement_to_count[
                        f"import {import_name} as {import_as}"
                    ] += 1

                elif node.parent.parent.type == "import_from_statement":
                    # from .. import .. as ..
                    import_from_node = node.parent.parent.child_by_field_name(
                        "module_name"
                    )
                    assert import_from_node is not None
                    if import_from_node == node.parent:
                        # we found the dotted_name node in the module_name node
                        # e.g. from logging import getLogger
                        # but we only want to find import logging
                        continue
                    import_from = import_from_node.text
                    assert import_from is not None
                    import_from = import_from.decode("utf-8")
                    import_from = relative_import_to_absolute_import(
                        project_root, file_path, import_from
                    )

                    import_name_node = node.parent.child_by_field_name("name")
                    assert import_name_node is not None
                    import_name = import_name_node.text
                    assert import_name is not None
                    import_name = import_name.decode("utf-8")

                    import_as_node = node.parent.child_by_field_name("alias")
                    assert import_as_node is not None
                    import_as = import_as_node.text
                    assert import_as is not None
                    import_as = import_as.decode("utf-8")

                    import_statement_to_count[
                        f"from {import_from} import {import_name} as {import_as}"
                    ] += 1
            elif node.parent.type == "dotted_name":
                assert node.parent.parent is not None

                if node.parent.parent.type == "import_statement":
                    # import logging
                    import_name = node.parent.text
                    assert import_name is not None
                    import_name = import_name.decode("utf-8")

                    import_statement_to_count[f"import {import_name}"] += 1
                elif node.parent.parent.type == "import_from_statement":
                    # from logging import getLogger
                    import_from_node = node.parent.parent.child_by_field_name(
                        "module_name"
                    )
                    assert import_from_node is not None

                    if import_from_node == node.parent:
                        # we found the dotted_name node in the module_name node
                        # e.g. from logging import getLogger
                        # but we only want to find import logging
                        continue

                    import_from = import_from_node.text
                    assert import_from is not None
                    import_from = import_from.decode("utf-8")
                    import_from = relative_import_to_absolute_import(
                        project_root, file_path, import_from
                    )

                    import_name = node.parent.text
                    assert import_name is not None
                    import_name = import_name.decode("utf-8")

                    import_statement_to_count[
                        f"from {import_from} import {import_name}"
                    ] += 1

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


if __name__ == "__main__":
    app()
    # find_python_import_in_project("/home/kiyoon/project/dti-db-curation", "abcd")
    # find_python_import_in_project(
    #     "/Users/kiyoon/project/dti-db-curation", "ManualCurationUpdater"
    # )
