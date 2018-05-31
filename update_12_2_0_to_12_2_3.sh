#!/bin/bash

LOG_FILE=update.log

decho () {
  echo `date +"%H:%M:%S"` $1
  echo `date +"%H:%M:%S"` $1 >> $LOG_FILE
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
read -e -p "Please enter the user name that runs Monoeci core /!\ case sensitive /!\ : " whoami

## Check if monoeci user exist
getent passwd $whoami > /dev/null 2&>1
if [ $? -ne 0 ]; then
	echo "$whoami user does not exist"
	exit 3
fi

## Stop active core
decho "Stoping active monoeci core"
pkill -f monoecid  >> $LOG_FILE 2>&1

## Wait to kill properly
sleep 5

## Download and Install new bin
decho "Downloading new core and installing it"
wget https://github.com/monacocoin-net/monoeci-core/releases/download/v0.12.2.3/monoeciCore-0.12.2.3-linux64.tar.gz >> $LOG_FILE 2>&1
sudo tar xvzf monoeciCore-0.12.2.3-linux64.tar.gz >> $LOG_FILE 2>&1
sudo cp monoeciCore-0.12.2/bin/monoecid /usr/bin/ >> $LOG_FILE 2>&1
sudo cp monoeciCore-0.12.2/bin/monoeci-cli /usr/bin/ >> $LOG_FILE 2>&1
sudo cp monoeciCore-0.12.2/bin/monoeci-tx /usr/bin/ >> $LOG_FILE 2>&1
rm -rf monoeciCore-0.12.2 >> $LOG_FILE 2>&1

## Backup configuration
decho "Backup configuration file"

if [ "$whoami" != "root" ]; then
	path=/home/$whoami
else
	path=/root
fi

cd $path

cp -R .monoeciCore "monoeciCore_"`date '+%Y-%m-%d_%H:%M:%S'` >> $LOG_FILE 2>&1

## Remove old configuration
decho "Removing old configuration file (except monoeci.conf)"

cd $path/.monoeciCore

shopt -s extglob >> $LOG_FILE 2>&1
rm -rf !(monoeci.conf) >> $LOG_FILE 2>&1

#relunch core
decho "Relaunching monoeci core"
sudo -H -u $whoami bash -c 'monoecid' >> $LOG_FILE 2>&1

## Update sentinel
decho "Updating sentinel"
cd $path/sentinel
git pull >> $LOG_FILE 2>&1

sudo -H -u $whoami bash -c 'virtualenv ./venv' >> $LOG_FILE 2>&1
sudo -H -u $whoami bash -c './venv/bin/pip install -r requirements.txt' >> $LOG_FILE 2>&1

decho "Update finish !"
echo "Now, you need to finally restart your masternode in the following order: "
echo "Go to your windows/mac wallet on the Masternode tab."
echo "Select the updated masternode and then click on start-alias."
echo "Once completed please return to VPS and wait for the wallet to be synced."
echo "Then you can try the command 'monoeci-cli masternode status' to get the masternode status."

su $whoami
##End
