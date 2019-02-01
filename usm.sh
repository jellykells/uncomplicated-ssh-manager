#!/bin/bash
##Currently unused include
#. $HOME/Documents/sshmanagerfunctions.sh
VERSION="Uncomplicated SSH Manager v1.0"
DIR="$(cd "$(dirname "$0")"&& pwd)"
INPUT_ATTEMPTS=0
MAX_ATTEMPTS=3
INSTANCES_FILE="$HOME/.usm/data/instances"

if [ ! -d "$HOME/.usm" ]; then
	mkdir $HOME/.usm
fi
##Code for temp file if needed
#if [ ! -d "$HOME/.usm/temp" ]; then
#	mkdir $HOME/.usm
#fi
if [ ! -d "$HOME/.usm/data" ]; then
	mkdir $HOME/.usm/data
fi
if [ ! -e "$HOME/.usm/data/instances" ]; then
	touch $HOME/.usm/data/instances
fi

declare -a instances
read -a instances <"$INSTANCES_FILE"

##For testing array storage/retrieval
#INSTANCES=`cat $DIR/sshinstances.sh`
#ARRAY_SIZE=${#instances[*]}
#echo "Array size is "$ARRAY_SIZE

ssh_add() {
	LASTMENU="ssh_add"
	read -r -p "$(echo -e 'Please enter the username you would like to use for this session:\n')" username
	USERNAME=$username
	read -r -p "$(echo -e 'Please enter the IP address you would like to use for this session:\n')" address
	ADDRESS=$address
	instances+=("$USERNAME"@"$ADDRESS")
	##Currently unused alternative method
	#sed -i -e 1's/$/ "$username"' "$HOME/.usm/instances"
	#sed -i -e 2's/$/ "$address"' "$HOME/.usm/instances"
	echo "${instances[*]}" > "$HOME/.usm/data/instances"
	read -r -p "$(echo -e 'Instance added. Add another? (Y/n)')" answer
	case "$answer" in
		[yY]|[Yy][Ee][Ss] ) menu_check;;
		[Nn]|[Nn][Oo] ) main_menu;;
		* ) invalid_input;;
	esac
}

ssh_remove() {
	LASTMENU="ssh_remove"
	echo 'Please select an SSH instance to remove, User:'
	for i in ${!instances[*]}; do
		echo [$i] ${instances[$i]}
	done
	read -r -p "" selection
	if [[ "$selection" < "${#instances[@]}" ]]; then
		read -r -p "Delete '${instances[$selection]}'? (Y/n)" answer
		case "$answer" in
			[Nn]|[Nn][Oo] ) menu_check;;
			[yY]|[Yy][Ee][Ss] ) instances=( ${instances[@]/${instances[$selection]}} );
													echo "${instances[*]}" > "$HOME/.usm/data/instances";
													read -r -p "Instance removed. Remove another? (Y/n)" answer;
													case "$answer" in
														[yY]|[Yy][Ee][Ss] ) menu_check;;
														[Nn]|[Nn][Oo] ) main_menu;;
														* ) invalid_input;;
													esac;;
		esac
	else
		invalid_input
	fi
}

main_menu() {
	LASTMENU="main_menu"
	read -r -p "$(echo -e 'Please select an option, User: \n\n[1] Start.\n[2] Add.\n[3] Remove.\n[4] Exit.\n\b')" selection
	case "$selection" in
		[1] ) ssh_start;;
		[2] ) ssh_add;;
		[3] ) ssh_remove;;
		[4] ) exit 0;;
		*   ) invalid_input;;
	esac
}

menu_check() {
	$LASTMENU
	}

input_attempts_max() {
	echo -e "Maximum input attempts exceeded.\nPlease ensure all your fingers are intact and try again, User.";
	exit 0;
	}

ssh_start() {
	LASTMENU=ssh_start
	echo 'Please select an SSH instance, User:'
	for i in ${!instances[*]}; do
		echo [$i] ${instances[$i]}
	done
	read -r -p "" selection
	if [[ "$selection" < "${#instances[@]}" ]]; then
		echo -e "Starting session... \n"
		ssh "${instances[$selection]}"
	else
		invalid_input
	fi
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

	while getopts ahrsv option
		do
			case "$option" in
				a ) ssh_add;;
				h ) help; exit 0;;
				r ) ssh_remove;;
				s ) ssh_start;;
				v ) echo $VERSION; exit 0;;
			esac
		done

main_menu
