#!/bin/bash

################################################
# Script by François YoYae GINESTE - 03/04/2018
# For monoeciCore V0.12.2
# https://monoeci.io/tutorial-masternode/
################################################

decho () {
  echo && echo `date +"%H:%M:%S"` $1
}

clear

cat <<'FIG'
 __  __                             _
|  \/  | ___  _ __   ___   ___  ___(_)
| |\/| |/ _ \| '_ \ / _ \ / _ \/ __| |
| |  | | (_) | | | | (_) |  __/ (__| |
|_|  |_|\___/|_| |_|\___/ \___|\___|_|
FIG


# Check for systemd
systemctl --version >/dev/null 2>&1 || { decho "systemd is required. Are you using Ubuntu 16.04?"  >&2; exit 1; }

#print variable on a screen
decho "Make sure you double check before hitting enter !"

read -e -p "User that will run Monoeci core : " whoami
if [[ "$whoami" == "" ]]; then
    decho "WARNING: No user entered, exiting !!!"
    exit 3
fi
if [[ "$whoami" == "root" ]]; then
    decho "WARNING: user root entered? It is recommended to use a non-root user, exiting !!!"
    exit 3
fi
read -e -p "Server IP Address : " ip
if [[ "$ip" == "" ]]; then
    decho "WARNING: No IP entered, exiting !!!"
    exit 3
fi
read -e -p "Masternode Private Key (e.g. 3bsTPBdDf3USqoAAnHmfmSyHqZ4fACkUDNezE7ZVKQyxEKiy8MK # THE KEY YOU GENERATED EARLIER) : " key
if [[ "$key" == "" ]]; then
    decho "WARNING: No masternode private key entered, exiting !!!"
    exit 3
fi
read -e -p "(Optional) Install Fail2ban? (Recommended) [Y/n] : " install_fail2ban
read -e -p "(Optional) Install UFW and configure ports? (Recommended) [Y/n] : " UFW

decho "Updating system and installing required packages."   

# update package and upgrade Ubuntu
sudo apt-get -y update
sudo apt-get -y upgrade
# Add Berkely PPA
decho "Installing bitcoin PPA..."

sudo apt-get -y install software-properties-common
sudo apt-add-repository -y ppa:bitcoin/bitcoin
sudo apt-get -y update

# Install required packages
decho "Installing base packages and dependencies..."

sudo apt-get -y install \
     wget \
     git \
     unzip \
     libevent-dev \
     libboost-dev \
     libboost-chrono-dev \
     libboost-filesystem-dev \
     libboost-program-options-dev \
     libboost-system-dev \
     libboost-test-dev \
     libboost-thread-dev \
     libdb4.8-dev \
     libdb4.8++-dev \
     libminiupnpc-dev \
     build-essential \
     libtool \
     autotools-dev \
     automake \
     pkg-config \
     libssl-dev \
     libevent-dev \
     bsdmainutils \
     libzmq3-dev \
	 virtualenv \
	 pwgen

decho "Optional installs (fail2ban and ufw)"
if [[ ("$install_fail2ban" == "y" || "$install_fail2ban" == "Y" || "$install_fail2ban" == "") ]]; then
	cd ~
	sudo apt-get -y install fail2ban
	sudo systemctl enable fail2ban
	sudo systemctl start fail2ban
fi

if [[ ("$UFW" == "y" || "$UFW" == "Y" || "$UFW" == "") ]]; then
	sudo apt-get install ufw
	sudo ufw default deny incoming
	sudo ufw default allow outgoing
	sudo ufw allow ssh/tcp
	sudo ufw allow sftp/tcp
	sudo ufw allow 24157/tcp
	sudo ufw logging on
	sudo ufw enable -y
fi

#Create user (if necessary)
if ![ getent passwd $whoami > /dev/null 2>&1 ]; then
    sudo adduser --disabled-password --gecos "" $whoami
fi

#Create monoeci.conf
decho "Setting up monoeci Core" 
#Generating Random Passwords
user=`pwgen -s 16 1`
password=`pwgen -s 64 1`

sudo -H -u monoeci bash -c 'mkdir -p /home/$whoami/.monoeciCore/'
cat << EOF > /home/$whoami/.monoeciCore/monoeci.conf
rpcuser='$user'
rpcpassword='$password'
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
maxconnections=24
masternode=1
masternodeprivkey='$key'
externalip='$ip'
EOF
sudo chmod 0755 /home/$whoami/.monoeciCore/monoeci.conf

echo 'monoeci.conf created'

#Install Dinero Daemon
cd
wget https://github.com/monacocoin-net/monoeci-core/releases/download/0.12.2.3/monoeciCore-0.12.2.3-linux64-cli.Ubuntu16.04.tar.gz
sudo tar xvf monoeciCore-0.12.2.3-linux64-cli.Ubuntu16.04.tar.gz
sudo rm monoeciCore-0.12.2.3-linux64-cli.Ubuntu16.04.tar.gz
sudo cp monoecid /usr/bin/ && rm -fr monoecid 
sudo cp monoeci-cli /usr/bin/ && rm -fr monoeci-cli 
sudo cp monoeci-tx /usr/bin/ && rm -fr monoeci-tx 

sudo -H -u $whoami bash -c 'monoecid'

echo 'Monoeci Core prepared and lunched'

sleep 10

#Setting up coin

decho "Setting up sentinel"

#Install Sentinel
sudo apt-get install -y git python-virtualenv
sudo -H -u monoeci bash -c 'git clone https://github.com/monacocoin-net/sentinel.git /home/$whoami/sentinel'
cd /home/$whoami/sentinel
sudo -H -u monoeci bash -c 'virtualenv ./venv'
sudo -H -u monoeci bash -c './venv/bin/pip install -r requirements.txt'

#Starting coin
sudo -H -u monoeci bash -c "(crontab -l 2>/dev/null; echo '@reboot sleep 30 && monoecid') | crontab"
sudo -H -u monoeci bash -c "(crontab -l 2>/dev/null; echo '* * * * * cd /home/$whoami/sentinel && ./venv/bin/python bin/sentinel.py >/$') | crontab"

decho "Starting your masternode"
echo "Now, you need to finally start your masternode in the following order: "
echo "Go to your windows/mac wallet and modify masternode.conf as required, then restart and from the Masternode tab"
echo "Select the newly created masternode and then click on start-alias."
echo "Once completed please return to VPS and wait for the wallet to be synced."
echo "Then you can try the command 'monoeci-cli masternode status' to get the masternode status."

su $whoami
