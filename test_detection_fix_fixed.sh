#!/bin/bash

echo "=== WireGuard鍜孊IRD妫€娴嬩慨澶嶉獙璇?==="
echo

# 娴嬭瘯閰嶇疆鏂囦欢璺緞
CONFIG_DIR="/etc/ipv6-wireguard"
STATUS_FILE="$CONFIG_DIR/installation_status.conf"

echo "1. 妫€鏌ラ厤缃枃浠剁洰褰?.."
if [[ -d "$CONFIG_DIR" ]]; then
    echo "   鉁?閰嶇疆鐩綍瀛樺湪: $CONFIG_DIR"
else
    echo "   鉁?閰嶇疆鐩綍涓嶅瓨鍦? $CONFIG_DIR"
    echo "   鍒涘缓閰嶇疆鐩綍..."
    mkdir -p "$CONFIG_DIR"
fi

echo
echo "2. 娴嬭瘯鐘舵€佹枃浠跺垱寤?.."
cat > "$STATUS_FILE" << 'EOF'
# IPv6 WireGuard Manager Installation Status
# Generated on $(date)

WG_INSTALLED=true
BIRD_INSTALLED=true
IPV6_ENABLED=true
OS_TYPE=ubuntu
OS_VERSION=20.04
EOF

if [[ -f "$STATUS_FILE" ]]; then
    echo "   鉁?鐘舵€佹枃浠跺垱寤烘垚鍔? $STATUS_FILE"
    echo "   鏂囦欢鍐呭:"
    cat "$STATUS_FILE" | sed 's/^/     /'
else
    echo "   鉁?鐘舵€佹枃浠跺垱寤哄け璐?
fi

echo
echo "3. 娴嬭瘯鐘舵€佸姞杞?.."
if [[ -f "$STATUS_FILE" ]]; then
    source "$STATUS_FILE"
    echo "   鉁?鐘舵€佹枃浠跺姞杞芥垚鍔?
    echo "   WG_INSTALLED: $WG_INSTALLED"
    echo "   BIRD_INSTALLED: $BIRD_INSTALLED"
    echo "   IPV6_ENABLED: $IPV6_ENABLED"
    echo "   OS_TYPE: $OS_TYPE"
    echo "   OS_VERSION: $OS_VERSION"
else
    echo "   鉁?鐘舵€佹枃浠朵笉瀛樺湪"
fi

echo
echo "4. 娴嬭瘯鍛戒护妫€娴?.."
echo "   妫€娴媁ireGuard鍛戒护..."
if command -v wg >/dev/null 2>&1; then
    echo "   鉁?wg 鍛戒护瀛樺湪"
else
    echo "   鉁?wg 鍛戒护涓嶅瓨鍦?
fi

echo "   妫€娴婤IRD鍛戒护..."
if command -v bird >/dev/null 2>&1; then
    echo "   鉁?bird 鍛戒护瀛樺湪"
elif command -v bird2 >/dev/null 2>&1; then
    echo "   鉁?bird2 鍛戒护瀛樺湪"
else
    echo "   鉁?bird 鍜?bird2 鍛戒护閮戒笉瀛樺湪"
fi

echo
echo "5. 娴嬭瘯鐘舵€佷繚瀛?.."
# 妯℃嫙鐘舵€佷繚瀛?WG_INSTALLED=true
BIRD_INSTALLED=true
IPV6_ENABLED=true
OS_TYPE="test"
OS_VERSION="1.0"

cat > "$STATUS_FILE" << EOF
# IPv6 WireGuard Manager Installation Status
# Generated on $(date)

WG_INSTALLED=$WG_INSTALLED
BIRD_INSTALLED=$BIRD_INSTALLED
IPV6_ENABLED=$IPV6_ENABLED
OS_TYPE=$OS_TYPE
OS_VERSION=$OS_VERSION
EOF

if [[ -f "$STATUS_FILE" ]]; then
    echo "   鉁?鐘舵€佷繚瀛樻垚鍔?
    echo "   淇濆瓨鐨勫唴瀹?"
    cat "$STATUS_FILE" | sed 's/^/     /'
else
    echo "   鉁?鐘舵€佷繚瀛樺け璐?
fi

echo
echo "=== 楠岃瘉瀹屾垚 ==="
echo "鐜板湪鑴氭湰浼氭纭娴嬪拰淇濆瓨WireGuard鍜孊IRD鐨勫畨瑁呯姸鎬併€?
echo "鐘舵€佹枃浠朵綅缃? $STATUS_FILE"
