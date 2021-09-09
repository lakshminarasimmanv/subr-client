# Simple Unix Backup and Restore Client
This Bash Script helps you take incremental backup and save it to a remote machine which is encrypted using your GPG Key, so no one can extract and read your contents.

## Install
git clone this repository anywhere and run the following commands from inside the subrc-client directory
'chmod +x install.sh'

## Usage
Run this from any directory to backup the entire directory
'backup'
Enter the prompted values
The config file is stored in the same directory from which you ran the command, under the name .subrc/config
