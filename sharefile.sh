#Auther : vaisakh MK
#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: sharefile <filename>"
    exit 1
fi

TARGET_FILE="$1"

if [ ! -f "$TARGET_FILE" ]; then
    echo "Error: File '$TARGET_FILE' not found."
    exit 1
fi

ABS_FILE_PATH=$(realpath "$TARGET_FILE")
FILENAME=$(basename "$ABS_FILE_PATH")

TMP_DIR=$(mktemp -d -t sharefile.XXXXXX)
ln -s "$ABS_FILE_PATH" "$TMP_DIR/$FILENAME"

# --- NEW TRAP LOGIC FOR CTRL+C ---
cleanup() {
    echo -e "\nStopping server and cleaning up..."
    if [ -n "$SERVER_PID" ]; then
        kill "$SERVER_PID" 2>/dev/null
    fi
    rm -rf "$TMP_DIR"
    exit 0
}
# Catch Ctrl+C (SIGINT) and termination (SIGTERM)
trap cleanup SIGINT SIGTERM
# ----------------------------------

IP_ADDR=$(hostname -I | awk '{print $1}')
echo "Server URL: http://$IP_ADDR"
echo "To download, click: $FILENAME"

cd "$TMP_DIR" || exit 1
python3 -m http.server 80 > /dev/null 2>&1 &
SERVER_PID=$!

echo "Waiting for Windows client to download..."
while ! ss -tinp | grep -q "python3"; do
    sleep 1
done

echo "Transfer started..."
while ss -tinp | grep -q "python3"; do
    sleep 2
done

sleep 5
cleanup
