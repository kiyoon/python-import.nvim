from ._version import get_version_dict

__version__ = get_version_dict()["version"]

from __future__ import annotations

from . import _version

__version__ = _version.get_versions()["version"]
