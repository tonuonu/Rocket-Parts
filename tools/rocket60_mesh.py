"""The owner's CAD camera nose mesh (STL Files/Rocket60/NoseCone.stl).

Shared by canard_estimate.py and nose_mass_cg.py. Read from HEAD first
(once feature/rocket60 is merged), then origin/feature/rocket60, then the
local feature/rocket60 branch.
"""
import subprocess
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PATH = "STL Files/Rocket60/NoseCone.stl"
REFS = ("HEAD", "origin/feature/rocket60", "feature/rocket60")


def rocket60_nose_stl():
    """STL bytes of the camera nose mesh from the first ref that has it."""
    for ref in REFS:
        r = subprocess.run(["git", "-C", str(REPO), "show", "%s:%s" % (ref, PATH)],
                           capture_output=True)
        if r.returncode == 0:
            return r.stdout
    raise SystemExit("camera nose mesh not found: git fetch origin feature/rocket60")
