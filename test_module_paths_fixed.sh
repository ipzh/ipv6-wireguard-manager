#!/bin/bash

echo "=== 妯″潡璺緞淇娴嬭瘯 ==="
echo

# 娴嬭瘯鑴氭湰鐩綍鑾峰彇
echo "1. 娴嬭瘯鑴氭湰鐩綍鑾峰彇..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "   鑴氭湰鐩綍: $SCRIPT_DIR"

# 娴嬭瘯妯″潡鐩綍妫€鏌?echo
echo "2. 娴嬭瘯妯″潡鐩綍妫€鏌?.."
if [[ -d "$SCRIPT_DIR/modules" ]]; then
    echo "   鉁?妯″潡鐩綍瀛樺湪: $SCRIPT_DIR/modules"
    module_count=$(ls "$SCRIPT_DIR/modules"/*.sh 2>/dev/null | wc -l)
    echo "   妯″潡鏂囦欢鏁伴噺: $module_count"
else
    echo "   鉁?妯″潡鐩綍涓嶅瓨鍦? $SCRIPT_DIR/modules"
    if [[ -d "./modules" ]]; then
        echo "   鉁?褰撳墠鐩綍鏈夋ā鍧楁枃浠跺す"
        SCRIPT_DIR="$(pwd)"
        echo "   浣跨敤褰撳墠鐩綍: $SCRIPT_DIR"
    fi
fi

# 娴嬭瘯鍏抽敭妯″潡鏂囦欢
echo
echo "3. 娴嬭瘯鍏抽敭妯″潡鏂囦欢..."
key_modules=("server_management" "client_management" "network_management" "firewall_management" "system_maintenance" "backup_restore" "update_management")
for module in "${key_modules[@]}"; do
    if [[ -f "$SCRIPT_DIR/modules/${module}.sh" ]]; then
        echo "   鉁?$module.sh 瀛樺湪"
    else
        echo "   鉁?$module.sh 涓嶅瓨鍦?
    fi
done

# 娴嬭瘯妯″潡鍔犺浇鍑芥暟
echo
echo "4. 娴嬭瘯妯″潡鍔犺浇鍑芥暟..."
if [[ -f "ipv6-wireguard-manager.sh" ]]; then
    # 妯℃嫙妯″潡鍔犺浇
    MODULES_DIR="$SCRIPT_DIR/modules"
    test_module="server_management"
    module_file="$MODULES_DIR/${test_module}.sh"
    
    if [[ -f "$module_file" ]]; then
        echo "   鉁?妯″潡鏂囦欢璺緞姝ｇ‘: $module_file"
    else
        echo "   鉁?妯″潡鏂囦欢璺緞閿欒: $module_file"
    fi
else
    echo "   鉁?涓昏剼鏈枃浠朵笉瀛樺湪"
fi

# 娴嬭瘯纭紪鐮佽矾寰勪慨澶?echo
echo "5. 娴嬭瘯纭紪鐮佽矾寰勪慨澶?.."
echo "   妫€鏌ユ槸鍚﹁繕鏈?/opt/ipv6-wireguard 纭紪鐮佽矾寰?.."

if grep -r "/opt/ipv6-wireguard" modules/ 2>/dev/null | grep -v "SCRIPT_DIR" >/dev/null; then
    echo "   鉁?鍙戠幇纭紪鐮佽矾寰?"
    grep -r "/opt/ipv6-wireguard" modules/ 2>/dev/null | grep -v "SCRIPT_DIR"
else
    echo "   鉁?娌℃湁鍙戠幇纭紪鐮佽矾寰?
fi

echo
echo "=== 娴嬭瘯瀹屾垚 ==="
echo "妯″潡璺緞閿欒宸蹭慨澶嶏紝椤圭洰鐜板湪鍙互姝ｇ‘鎵惧埌妯″潡鏂囦欢銆?
