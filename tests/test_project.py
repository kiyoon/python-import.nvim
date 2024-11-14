from __future__ import annotations

from contextlib import redirect_stdout
from io import StringIO
from pathlib import Path

from python_import.cli.main import count

SCRIPT_DIR = Path(__file__).parent


def test_cli_count():
    with redirect_stdout(StringIO()) as stdout:
        count(
            project_root=SCRIPT_DIR / "sample_projects/project1",
            module_name="foo",
        )

    assert stdout.getvalue() == "00003:from python_import import foo\n"
