from __future__ import annotations

import tree_sitter


def get_node(tree: tree_sitter.Tree, row_col: tuple[int, int]):
    named_node = tree.root_node.named_descendant_for_point_range(row_col, row_col)
    # named_node = tree.root_node.descendant_for_point_range((row, col), (row, col))
    return named_node
