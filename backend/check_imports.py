#!/usr/bin/env python
import sys
import traceback

try:
    print("Python version:", sys.version)
    print("Current directory:", sys.path[0])
    print("Python path:", sys.path)
    
    print("\nTrying to import app.core.config_enhanced...")
    import app.core.config_enhanced
    print("Config imported successfully!")
    
    print("\nTrying to import app.core.database...")
    import app.core.database
    print("Database imported successfully!")
    
    print("\nTrying to import app.models...")
    import app.models
    print("Models imported successfully!")
    
    print("\nTrying to import app.main...")
    import app.main
    print("Main imported successfully!")
    
except ImportError as e:
    print(f"ImportError: {e}")
    traceback.print_exc()
except Exception as e:
    print(f"Error: {e}")
    traceback.print_exc()