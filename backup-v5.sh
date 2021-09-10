#!/bin/bash
set -e
# Global Directiories

CURRENT_DIR=$(pwd)
BACKUP_DIR=$CURRENT_DIR/.subrc/backup-${PWD##*/}-$(date +%Y-%m-%d)
RSYNC_DIR=$CURRENT_DIR/.subrc/rsync_logs/
CONFIG_FILE=$CURRENT_DIR/.subrc/config

# Function to check and creating required folders.

function folders() {

    if [ -d "$BACKUP_DIR" ]; then
        echo "Temporary Backup Point exist!"
    else
        mkdir -p $BACKUP_DIR
        echo "Creating temporary ${BACKUP_DIR}..."
    fi

    if [ -d "$RSYNC_DIR" ]; then
        echo "Rsync log file exist!"
    else
        mkdir -p $RSYNC_DIR
        echo "Creating ${RSYNC_DIR}..."
    fi

    if [ -f "$CONFIG_FILE" ] && [ -s "$CONFIG_FILE" ]; then
        echo "Config file exist!"
        source $CONFIG_FILE

    else
        touch $CONFIG_FILE
        echo "Creating ${CONFIG_FILE}..."
        read -p "Enter recipient email: " RECIPIENT && echo "RECIPIENT='$RECIPIENT'" >> $CONFIG_FILE
	bold=$(tput bold) && normal=$(tput sgr0) && read -p "Enter password to unlock GPG key${bold} (NOTE! The password will be stored as plain text.):${normal} " PASSWORD && echo "PASSWORD='$PASSWORD'" >> $CONFIG_FILE
        read -p "Enter destination machine User name: " DESTINATION_USER && echo "DESTINATION_USER='$DESTINATION_USER'" >> $CONFIG_FILE
        read -p "Enter destination IP: " DESTINATION_IP && echo "DESTINATION_IP='$DESTINATION_IP'" >> $CONFIG_FILE
        read -p "Enter destination file path: " DESTINATION_LOCATION && echo "DESTINATION_LOCATION='$DESTINATION_LOCATION'" >> $CONFIG_FILE

        echo "Config file can be found at $CONFIG_FILE"
        sleep 1
fi
}

# Values and variables.

CURRENT_DIR_NAME=${PWD##*/}
SOURCE_FILE=$CURRENT_DIR_NAME
DATE=$(date +%Y-%m-%d)
SNAR=${BACKUP_DIR}/${SOURCE_FILE}-${DATE}.snar
TAR=${BACKUP_DIR}/${SOURCE_FILE}-${DATE}.tar.gz
BACKED_UP_SOURCE_FILE=$BACKUP_DIR
LOG_FILE=$RSYNC_DIR/${DATE}.log

# Function to Tar and zipping the backup files.

function archiving() {
    echo "Creating tar.gz file using Tar command."
    tar  --exclude=".subrc" \
	    --auto-compress \
            --create \
            --listed-incremental=${SNAR} \
            --file=${TAR} \
            -C ${CURRENT_DIR}/.. \
            $SOURCE_FILE
    echo "Archiving and zipping completed."
}

# Function to encrypt the Tar file using gpg keys.

function encryption() {
    gpg --encrypt \
	--pinentry-mode loopback \
	--passphrase=$PASSWORD \
        --sign \
        --armor \
        -r $RECIPIENT \
        $TAR
    rm $BACKUP_DIR/*.tar.gz
    echo "Archive Encrypted."
}

# Function to rsync the encrypted file to a remote machine

function rsyncing(){
    echo "Please enter password for the remote machine!"
    rsync -azh \
        --progress \
        --stats \
        --log-file=$LOG_FILE \
        ${BACKED_UP_SOURCE_FILE} \
        ${DESTINATION_USER}@${DESTINATION_IP}:${DESTINATION_LOCATION}
    echo "Encrypted archive sent to remote machine."
}

# Function to Delete local backup files from the backup_point.

function deletion() {
    rm -rf \
        $BACKUP_DIR
    echo "Deleted Local Backup."

}

# Calling all the functions

folders
archiving
encryption
rsyncing
deletion

echo "Success!!"
