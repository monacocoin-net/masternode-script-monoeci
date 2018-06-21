#!/bin/bash

################################################
# Script by François YoYae GINESTE - 03/04/2018
# For Monoeci
# https://monoeci.io/
################################################

LOG_FILE=/tmp/update.log

decho () {
  echo `date +"%H:%M:%S"` $1
  echo `date +"%H:%M:%S"` $1 >> $LOG_FILE
}

error() {
  local parent_lineno="$1"
  local message="$2"
  local code="${3:-1}"
  echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
  exit "${code}"
}
trap 'error ${LINENO}' ERR

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

#relunch core
decho "Relaunching monoeci core"
sudo -H -u $whoami bash -c 'monoecid -reindex' >> $LOG_FILE 2>&1

## Update sentinel
decho "Updating sentinel"
cd $path/sentinel
git pull >> $LOG_FILE 2>&1

sudo -H -u $whoami bash -c 'virtualenv ./venv' >> $LOG_FILE 2>&1
sudo -H -u $whoami bash -c './venv/bin/pip install -r requirements.txt' >> $LOG_FILE 2>&1

decho "Update finish !"

su $whoami
##End
