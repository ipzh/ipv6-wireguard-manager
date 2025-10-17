import sys
import os

print("Python executable:", sys.executable)
print("Python version:", sys.version)
print("Current working directory:", os.getcwd())
print("Python path:", sys.path[:3])  # 只显示前3个路径

# 检查模块是否可导入
modules_to_check = [
    "fastapi",
    "uvicorn",
    "sqlalchemy",
    "pydantic",
    "pydantic_settings",
    "pymysql",
    "aiomysql"
]

for module in modules_to_check:
    try:
        __import__(module)
        print(f"✓ {module} is available")
    except ImportError as e:
        print(f"✗ {module} is not available: {e}")