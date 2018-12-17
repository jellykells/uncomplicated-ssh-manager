#!/bin/bash
##Currently unused include
#. $HOME/Documents/sshmanagerfunctions.sh
DIR="$(cd "$(dirname "$0")"&& pwd)"
##For testing array storage/retrieval
#INSTANCES=`cat $DIR/sshinstances.sh`
INPUT_ATTEMPTS=0
MAX_ATTEMPTS=3
INSTANCES_FILE="$HOME/.simple-ssh/data/instances"

if [ ! -d "$HOME/.simple-ssh" ]; then
	mkdir $HOME/.simple-ssh
fi
if [ ! -d "$HOME/.simple-ssh/temp" ]; then
	mkdir $HOME/.simple-ssh
fi
if [ ! -d "$HOME/.simple-ssh/data" ]; then
	mkdir $HOME/.simple-ssh/data
fi
if [ ! -e "$HOME/.simple-ssh/data/instances" ]; then
	touch $HOME/.simple-ssh/data/instances
fi

declare -a instances
read -a instances <"$INSTANCES_FILE"

##For testing array storage/retrieval
#ARRAY_SIZE=${#instances[*]}
#echo "Array size is "$ARRAY_SIZE

DIR="$(cd "$(dirname "$0")" && pwd)"

ssh_add() {
	LASTMENU="ssh_add"
	read -r -p "$(echo -e 'Please enter the username you would like to use for this session:\n')" username
	USERNAME=$username
	read -r -p "$(echo -e 'Please enter the IP address you would like to use for this session:\n')" address
	ADDRESS=$address
	usernames+=($USERNAME)
	addresses+=($ADDRESS)
	#sed -i -e 1's/$/ "$username"' "$HOME/.simple-ssh/instances"
	#sed -i -e 2's/$/ "$address"' "$HOME/.simple-ssh/instances"
	printf "${usernames[@]}"; printf "${addresses[@]}" >"$HOME/.simple-ssh/instances"
	read -r -p "$(echo -e 'Instance added. Add another? (Y/n)')" answer
	case "$answer" in
		[yY]|[Yy][Ee][Ss] ) menu_check;;
		[Nn]|[Nn][Oo] ) main_menu;;
		* ) invalid_input;;
	esac
}

main_menu() {
	LASTMENU="main_menu"
	read -r -p "$(echo -e 'Please select an option, User: \n\n[1] Start an SSH instance.\n[2] Add an SSH instance.\n[3] Exit.\n\b')" selection
	case "$selection" in
		[1] ) ssh_start;;
		[2] ) ssh_add;;
		[3] ) close;;
		*   ) invalid_input;;
	esac
}

menu_check() {
	$LASTMENU
	}

close() {
	return 0;
	exit;
	}

input_attempts_max() {
	echo -e "Maximum input attempts exceeded.\nPlease ensure all your fingers are intact and try again, User.";
	close;
	}

ssh_start() {
	LASTMENU=ssh_start
	echo 'Please select an SSH instance, User:'
	read -r -p "${usernames[0]}@${addresses[0]}" selection
	case "$selection" in
		[1] ) echo -e "Starting session... \n" && ssh "${usernames[0]}@${addresses[0]}";;
		[2] ) echo -e "Starting session... \n" && ssh "${usernames[1]}@${addresses[1]}";;
		[3] ) echo "test 3 success";;
		*   ) invalid_input;;
	esac
	}

invalid_input() {
	((INPUT_ATTEMPTS++));
	if [[ "$INPUT_ATTEMPTS" -eq "$MAX_ATTEMPTS" ]]; then
		input_attempts_max;
	else
		echo "Invalid input. Please try again.";
		menu_check;
	fi
	}

main_menu
