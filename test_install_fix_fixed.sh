#!/bin/bash

echo "=== 瀹夎鑴氭湰淇楠岃瘉 ==="
echo

# 妫€鏌nstall.sh鏂囦欢
echo "1. 妫€鏌nstall.sh鏂囦欢..."
if [[ -f "install.sh" ]]; then
    echo "   鉁?install.sh 瀛樺湪"
    
    # 妫€鏌ユā鍧楁枃浠跺垪琛?    echo
    echo "2. 妫€鏌ユā鍧楁枃浠跺垪琛?.."
    if grep -q "server_management.sh" install.sh; then
        echo "   鉁?server_management.sh 鍦ㄤ笅杞藉垪琛ㄤ腑"
    else
        echo "   鉁?server_management.sh 涓嶅湪涓嬭浇鍒楄〃涓?
    fi
    
    if grep -q "network_management.sh" install.sh; then
        echo "   鉁?network_management.sh 鍦ㄤ笅杞藉垪琛ㄤ腑"
    else
        echo "   鉁?network_management.sh 涓嶅湪涓嬭浇鍒楄〃涓?
    fi
    
    if grep -q "firewall_management.sh" install.sh; then
        echo "   鉁?firewall_management.sh 鍦ㄤ笅杞藉垪琛ㄤ腑"
    else
        echo "   鉁?firewall_management.sh 涓嶅湪涓嬭浇鍒楄〃涓?
    fi
    
    if grep -q "system_maintenance.sh" install.sh; then
        echo "   鉁?system_maintenance.sh 鍦ㄤ笅杞藉垪琛ㄤ腑"
    else
        echo "   鉁?system_maintenance.sh 涓嶅湪涓嬭浇鍒楄〃涓?
    fi
    
    if grep -q "backup_restore.sh" install.sh; then
        echo "   鉁?backup_restore.sh 鍦ㄤ笅杞藉垪琛ㄤ腑"
    else
        echo "   鉁?backup_restore.sh 涓嶅湪涓嬭浇鍒楄〃涓?
    fi
    
    if grep -q "update_management.sh" install.sh; then
        echo "   鉁?update_management.sh 鍦ㄤ笅杞藉垪琛ㄤ腑"
    else
        echo "   鉁?update_management.sh 涓嶅湪涓嬭浇鍒楄〃涓?
    fi
    
    if grep -q "wireguard_diagnostics.sh" install.sh; then
        echo "   鉁?wireguard_diagnostics.sh 鍦ㄤ笅杞藉垪琛ㄤ腑"
    else
        echo "   鉁?wireguard_diagnostics.sh 涓嶅湪涓嬭浇鍒楄〃涓?
    fi
    
    # 妫€鏌ユ枃妗ｆ枃浠跺垪琛?    echo
    echo "3. 妫€鏌ユ枃妗ｆ枃浠跺垪琛?.."
    if grep -q "BIRD_PERMISSIONS.md" install.sh; then
        echo "   鉁?BIRD_PERMISSIONS.md 鍦ㄤ笅杞藉垪琛ㄤ腑"
    else
        echo "   鉁?BIRD_PERMISSIONS.md 涓嶅湪涓嬭浇鍒楄〃涓?
    fi
    
    if grep -q "INSTALLATION.md" install.sh; then
        echo "   鉁?INSTALLATION.md 鍦ㄤ笅杞藉垪琛ㄤ腑"
    else
        echo "   鉁?INSTALLATION.md 涓嶅湪涓嬭浇鍒楄〃涓?
    fi
    
    # 妫€鏌ョず渚嬫枃浠跺垪琛?    echo
    echo "4. 妫€鏌ョず渚嬫枃浠跺垪琛?.."
    if grep -q "bgp_neighbors.conf" install.sh; then
        echo "   鉁?bgp_neighbors.conf 鍦ㄤ笅杞藉垪琛ㄤ腑"
    else
        echo "   鉁?bgp_neighbors.conf 涓嶅湪涓嬭浇鍒楄〃涓?
    fi
    
    if grep -q "clients.csv" install.sh; then
        echo "   鉁?clients.csv 鍦ㄤ笅杞藉垪琛ㄤ腑"
    else
        echo "   鉁?clients.csv 涓嶅湪涓嬭浇鍒楄〃涓?
    fi
    
    # 妫€鏌ュ熀鏈ā鍧楀垱寤哄嚱鏁?    echo
    echo "5. 妫€鏌ュ熀鏈ā鍧楀垱寤哄嚱鏁?.."
    if grep -q "create_basic_modules" install.sh; then
        echo "   鉁?create_basic_modules 鍑芥暟瀛樺湪"
        
        # 妫€鏌ユ槸鍚﹀寘鍚墍鏈夊繀瑕佺殑妯″潡
        local modules=("server_management.sh" "client_management.sh" "network_management.sh" "firewall_management.sh" "system_maintenance.sh" "backup_restore.sh" "update_management.sh" "wireguard_diagnostics.sh")
        for module in "${modules[@]}"; do
            if grep -q "$module" install.sh; then
                echo "     鉁?$module 鍦ㄥ熀鏈ā鍧楀垪琛ㄤ腑"
            else
                echo "     鉁?$module 涓嶅湪鍩烘湰妯″潡鍒楄〃涓?
            fi
        done
    else
        echo "   鉁?create_basic_modules 鍑芥暟涓嶅瓨鍦?
    fi
    
else
    echo "   鉁?install.sh 涓嶅瓨鍦?
fi

echo
echo "=== 楠岃瘉瀹屾垚 ==="
echo "瀹夎鑴氭湰宸蹭慨澶嶏紝鐜板湪浼氫笅杞芥墍鏈夊繀瑕佺殑妯″潡鏂囦欢銆?
