#!/bin/bash

decho () {
  echo `date +"%H:%M:%S"` $1
}

cat <<'FIG'
 __  __                             _
|  \/  | ___  _ __   ___   ___  ___(_)
| |\/| |/ _ \| '_ \ / _ \ / _ \/ __| |
| |  | | (_) | | | | (_) |  __/ (__| |
|_|  |_|\___/|_| |_|\___/ \___|\___|_|
FIG

echo -e "\nStarting Monoeci masternode update. This will take a few minutes...\n"

## Check if root user

# Check if executed as root user
if [[ $EUID -ne 0 ]]; then
   echo -e "This script has to be run as \033[1mroot\033[0m user"
   exit 1
fi

## Ask for monoeci user name
echo "\nPlease enter the user name that runs monoeci core /!\ case sensitive /!\ : "
read whoami

if ![ getent passwd $whoami > /dev/null 2>&1 ]; then
    echo "$whoami user does not exist"
	exit 3
fi

## Stop active core
decho "Stoping active monoeci core"
pkill -f monoecid

## Wait to kill properly
sleep 5

## Download and Install new bin
decho "Downloading new core and installing it"
wget https://github.com/monacocoin-net/monoeci-core/releases/download/0.12.2.3/monoeciCore-0.12.2.3-linux64-cli.Ubuntu16.04.tar.gz
sudo tar xvf monoeciCore-0.12.2.3-linux64-cli.Ubuntu16.04.tar.gz
sudo rm monoeciCore-0.12.2.3-linux64-cli.Ubuntu16.04.tar.gz
sudo cp monoecid /usr/bin/ && rm -fr monoecid 
sudo cp monoeci-cli /usr/bin/ && rm -fr monoeci-cli 
sudo cp monoeci-tx /usr/bin/ && rm -fr monoeci-tx 

## Backup configuration
decho "Backup configuration file"

if [ "$(whoami)" != "root" ]; then
	cd /home/$whoami
else
	cd /root
fi

cp -R .monoeciCore monoeciCore_`date`

## Remove old configuration
decho "Removing old configuration file (except monoeci.conf)"

cd .monoeciCore

shopt -s extglob 
rm -rf !(monoeci.conf)

#relunch core
decho "Relunching monoeci core"
monoecid

## Update sentinel
decho "Updating sentinel"
cd ../sentinel
git pull

sudo -H -u $whoami bash -c 'virtualenv ./venv'
sudo -H -u $whoami bash -c './venv/bin/pip install -r requirements.txt'

decho "Update script finish !"
echo "Now, you need to finally restart your masternode in the following order: "
echo "Go to your windows/mac wallet on the Masternode tab."
echo "Select the updated masternode and then click on start-alias."
echo "Once completed please return to VPS and wait for the wallet to be synced."
echo "Then you can try the command 'monoeci-cli masternode status' to get the masternode status."
##End