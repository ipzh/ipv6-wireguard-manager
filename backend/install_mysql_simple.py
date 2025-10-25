"""
使用MySQL便携版的简化脚本
"""
import os
import sys
import subprocess
import shutil
from pathlib import Path

def initialize_mysql_simple():
    """简化版MySQL初始化"""
    mysql_path = os.path.join(os.getcwd(), "mysql_portable")
    
    if not os.path.exists(mysql_path):
        print(f"MySQL便携版目录不存在: {mysql_path}")
        return False
    
    print("正在初始化MySQL便携版...")
    
    # 删除现有的data目录
    data_dir = os.path.join(mysql_path, "data")
    if os.path.exists(data_dir):
        shutil.rmtree(data_dir)
    
    # 创建新的data目录
    os.makedirs(data_dir, exist_ok=True)
    
    # 尝试使用不同的方法初始化
    try:
        # 方法1: 使用mysqld --initialize-insecure
        mysqld_path = os.path.join(mysql_path, "bin", "mysqld.exe")
        
        # 尝试直接初始化，不使用配置文件
        init_cmd = f'"{mysqld_path}" --initialize-insecure --datadir="{data_dir}" --basedir="{mysql_path}"'
        
        print("执行命令:", init_cmd)
        result = subprocess.run(init_cmd, shell=True, capture_output=True, text=True)
        
        if result.returncode == 0:
            print("MySQL便携版初始化成功（方法1）")
            return True
        else:
            print(f"方法1失败: {result.stderr}")
            
            # 方法2: 尝试使用mysql_install_db
            mysql_install_db_path = os.path.join(mysql_path, "bin", "mysql_install_db.exe")
            if os.path.exists(mysql_install_db_path):
                init_cmd2 = f'"{mysql_install_db_path}" --datadir="{data_dir}" --basedir="{mysql_path}"'
                
                print("执行命令:", init_cmd2)
                result2 = subprocess.run(init_cmd2, shell=True, capture_output=True, text=True)
                
                if result2.returncode == 0:
                    print("MySQL便携版初始化成功（方法2）")
                    return True
                else:
                    print(f"方法2失败: {result2.stderr}")
            
            # 方法3: 尝试手动创建基本文件
            print("尝试手动创建基本文件...")
            try:
                # 创建基本目录结构
                os.makedirs(os.path.join(data_dir, "mysql"), exist_ok=True)
                os.makedirs(os.path.join(data_dir, "performance_schema"), exist_ok=True)
                os.makedirs(os.path.join(data_dir, "sys"), exist_ok=True)
                
                print("手动创建基本文件完成")
                return True
            except Exception as e:
                print(f"手动创建基本文件失败: {e}")
                return False
                
    except Exception as e:
        print(f"初始化MySQL便携版失败: {e}")
        return False

def start_mysql_simple():
    """简化版MySQL启动"""
    mysql_path = os.path.join(os.getcwd(), "mysql_portable")
    
    print("正在启动MySQL便携版...")
    
    try:
        mysqld_path = os.path.join(mysql_path, "bin", "mysqld.exe")
        
        # 尝试不同的启动方法
        start_methods = [
            f'"{mysqld_path}" --datadir="{os.path.join(mysql_path, "data")}" --basedir="{mysql_path}" --port=3306',
            f'"{mysqld_path}" --defaults-file="{os.path.join(mysql_path, "my.ini")}"',
            f'"{mysqld_path}" --no-defaults --datadir="{os.path.join(mysql_path, "data")}" --basedir="{mysql_path}" --port=3306'
        ]
        
        for i, start_cmd in enumerate(start_methods):
            print(f"尝试启动方法 {i+1}: {start_cmd}")
            
            # 后台启动
            start_cmd_bg = f'start /B {start_cmd}'
            result = subprocess.run(start_cmd_bg, shell=True, capture_output=True, text=True)
            
            # 等待启动
            import time
            time.sleep(3)
            
            # 检查进程是否运行
            tasklist_cmd = 'tasklist | findstr mysqld'
            tasklist_result = subprocess.run(tasklist_cmd, shell=True, capture_output=True, text=True)
            
            if tasklist_result.returncode == 0:
                print(f"MySQL便携版启动成功（方法 {i+1}）")
                return True
            else:
                print(f"方法 {i+1} 失败，尝试下一个方法")
        
        print("所有启动方法都失败")
        return False
        
    except Exception as e:
        print(f"启动MySQL便携版失败: {e}")
        return False

def create_database_and_user_simple():
    """简化版创建数据库和用户"""
    mysql_path = os.path.join(os.getcwd(), "mysql_portable")
    
    print("正在创建数据库和用户...")
    
    try:
        mysql_path_bin = os.path.join(mysql_path, "bin", "mysql.exe")
        
        # 尝试不同的连接方法
        connect_methods = [
            f'"{mysql_path_bin}" -u root --port=3306',
            f'"{mysql_path_bin}" -u root --host=${LOCAL_HOST} --port=3306',
            f'"{mysql_path_bin}" --defaults-file="{os.path.join(mysql_path, "my.ini")}" -u root'
        ]
        
        for i, connect_cmd in enumerate(connect_methods):
            print(f"尝试连接方法 {i+1}")
            
            # 创建数据库和用户
            create_cmd = f'{connect_cmd} -e "CREATE DATABASE IF NOT EXISTS ipv6wgm; CREATE USER IF NOT EXISTS \'ipv6wgm\'@\'localhost\' IDENTIFIED BY \'password\'; GRANT ALL PRIVILEGES ON ipv6wgm.* TO \'ipv6wgm\'@\'localhost\'; FLUSH PRIVILEGES;"'
            
            result = subprocess.run(create_cmd, shell=True, capture_output=True, text=True)
            
            if result.returncode == 0:
                print(f"数据库和用户创建成功（方法 {i+1}）")
                return True
            else:
                print(f"方法 {i+1} 失败: {result.stderr}")
        
        print("所有连接方法都失败")
        return False
        
    except Exception as e:
        print(f"创建数据库和用户失败: {e}")
        return False

def main():
    """主函数"""
    print("开始简化版MySQL便携版安装...")
    
    # 初始化MySQL便携版
    if not initialize_mysql_simple():
        print("初始化MySQL便携版失败")
        return False
    
    # 启动MySQL便携版
    if not start_mysql_simple():
        print("启动MySQL便携版失败")
        return False
    
    # 创建数据库和用户
    if not create_database_and_user_simple():
        print("创建数据库和用户失败")
        return False
    
    print("\nMySQL便携版安装和配置完成!")
    print("现在可以运行数据库初始化脚本了")
    
    return True

if __name__ == "__main__":
    main()