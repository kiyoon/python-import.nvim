from __future__ import annotations

import json
import subprocess
from collections import defaultdict
from pathlib import Path
from typing import TYPE_CHECKING

from .ts_utils import get_node

if TYPE_CHECKING:
    from os import PathLike

    from tree_sitter import Parser


def relative_import_to_absolute_import(
    project_root: str | PathLike,
    python_file_path: str | PathLike,
    from_import_name: str,
    *,
    check_dir_exists: bool = True,
):
    """
    Convert a relative import to an absolute import.

    Examples:
    >>> relative_import_to_absolute_import(
    ...     project_root="~/my_project",
    ...     python_file_path="~/my_project/src/my_project/utils.py",
    ...     from_import_name=".api",
    ...     check_dir_exists=False,
    ... )
    'my_project.api'

    >>> relative_import_to_absolute_import(
    ...     project_root="~/my_project",
    ...     python_file_path="~/my_project/src/my_project/a/utils.py",
    ...     from_import_name=".api",
    ...     check_dir_exists=False,
    ... )
    'my_project.a.api'

    >>> relative_import_to_absolute_import(
    ...     project_root="~/my_project",
    ...     python_file_path="~/my_project/src/my_project/a/utils.py",
    ...     from_import_name="..api",
    ...     check_dir_exists=False,
    ... )
    'my_project.api'
    """
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
    if project_root.is_dir() or not check_dir_exists:
        src_dir = project_root / "src"
        if src_dir.is_dir() or not check_dir_exists:
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


def get_all_imports_in_file_as_absolute(
    project_root: str | PathLike,
    python_file_path: str | PathLike,
    parser: Parser,
    rowcols: list[tuple[int, int]],
) -> dict[str, int]:
    """
    Given the locations of imports in a Python file, return the import statements as absolute imports.

    This will return in a simple one-liner format, even if the import statement is multi-line or multi-statement.
    The location has to be 0-based, indicating the actual variable/function name of the import.
    """
    with open(python_file_path) as f:
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

    import_statement_to_count = defaultdict(int)

    for row_col in rowcols:
        # match = query.matches(
        #     tree.root_node,
        #     start_point=(row_col_colend[0], row_col_colend[1]),
        #     end_point=(row_col_colend[0], row_col_colend[1]),
        # )
        # print(match)

        node = get_node(tree, row_col)
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

                import_statement_to_count[f"import {import_name} as {import_as}"] += 1

            elif node.parent.parent.type == "import_from_statement":
                # from .. import .. as ..
                import_from_node = node.parent.parent.child_by_field_name("module_name")
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
                    project_root, python_file_path, import_from
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
                import_from_node = node.parent.parent.child_by_field_name("module_name")
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
                    project_root, python_file_path, import_from
                )

                import_name = node.parent.text
                assert import_name is not None
                import_name = import_name.decode("utf-8")

                import_statement_to_count[
                    f"from {import_from} import {import_name}"
                ] += 1

    return import_statement_to_count


def get_all_imports_in_file_as_absolute_with_word(
    project_root: str | PathLike,
    python_file_path: str | PathLike,
    parser: Parser,
    word: str,
) -> dict[str, int]:
    """
    Just for testing purposes.

    The locations will be determined using ripgrep.
    """
    # NOTE: rg json outputs are (1, 0)-indexed
    rg_outputs = subprocess.run(
        [
            "rg",
            "--word-regexp",
            "--fixed-strings",
            "--json",
            word,
            str(python_file_path),
        ],
        cwd=project_root,
        capture_output=True,
        check=False,
    )
    # print(rg_outputs)

    # 0-indexed row, col
    rowcols: list[tuple[int, int]] = []
    for line in rg_outputs.stdout.decode("utf-8").split("\n"):
        if not line:
            continue
        rg_output = json.loads(line)
        if rg_output["type"] == "match":
            row = rg_output["data"]["line_number"] - 1
            col = rg_output["data"]["submatches"][0]["start"]
            # col_end = rg_output["data"]["submatches"][0]["end"]
            rowcols.append((row, col))

    return get_all_imports_in_file_as_absolute(
        project_root, python_file_path, parser, rowcols
    )
