import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    from h4deploy import deploy
    deploy()
except Exception:
    pass
