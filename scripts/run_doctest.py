"""
Run doctest for all modules in `src/` directory.

It will run all modules in `src/` directory and print the result of doctest.

It also has to load all modules in `src/` directory, so it will run all modules and test if they can be imported.
So if any module doesn't run (e.g. syntax error, import error, etc.), it will also fail.
"""

# flake8: noqa: T201
from __future__ import annotations

import doctest
import importlib
import os
from pathlib import Path

if __name__ == "__main__":
    # find all modules in src/
    modules = []
    for root, _dirs, files in os.walk("src"):
        for file in files:
            if file.endswith(".py"):
                # convert path to module name
                root = root.replace("src/", "")
                root = root.replace("/", ".")
                modules.append(root + "." + Path(file).stem)

    # run doctest for all modules
    failed_modules = []
    num_failed = 0
    num_attempted = 0
    num_modules_with_doctest = 0
    for module_name in modules:
        module = importlib.import_module(module_name)
        result = doctest.testmod(module, verbose=True)
        if result.failed > 0:
            print(f"🚨 doctest failed for module: {module_name}")
            print(f"🚨 {result.failed} failed out of {result.attempted} tests")
            num_failed += result.failed

        if result.attempted > 0:
            num_modules_with_doctest += 1
            num_attempted += result.attempted

    if num_failed == 0:
        print(
            f"✅ All {num_attempted} tests passed in {num_modules_with_doctest} modules."
        )
    else:
        print(
            f"🚨 {num_failed} failed out of {num_attempted} tests in {num_modules_with_doctest} modules."
        )
        exit(1)
