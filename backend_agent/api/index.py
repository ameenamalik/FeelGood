import sys
import os

# Ensure backend_agent directory is on sys.path so modules (main, models, graph, catalog) resolve cleanly
parent_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if parent_dir not in sys.path:
    sys.path.insert(0, parent_dir)

from main import app
