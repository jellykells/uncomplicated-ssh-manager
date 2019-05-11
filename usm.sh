#!/bin/bash
##Currently unused include
#. $HOME/Documents/sshmanagerfunctions.sh
VERSION="Uncomplicated SSH Manager v1.1.1"
HELP="Usage: usm [OPTION…]\n
'Uncomplicated SSH Manager' saves multiple SSH instances for simple management
and connection. It can be run with or without options.

Examples:
  usm		# Start the program and load the main menu.
  usm -h	# Display this help information.
  usm -s	# Skip main menu and load SSH instance selection.

 Quick function options:

 	-a	add an instance
 	-h	displays help info
 	-r	remove an instance
 	-s	loads instance selection
 	-v	displays version info
"
DIR="$(cd "$(dirname "$0")"&& pwd)"
INPUT_ATTEMPTS=0
MAX_ATTEMPTS=3
INSTANCES_FILE="$HOME/.usm/data/instances"
PORT=22

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
  echo "dummyentry" >> "$INSTANCES_FILE"
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
  read -r -p "$(echo -e 'Please enter the port number you would like to use for this session(None for default):\n')" port
  if [ "$port" = "" ]; then PORT=$port; fi
	instances+=("$USERNAME"@"$ADDRESS":"$PORT")
	##Currently unused alternative method
	#sed -i -e 1's/$/ "$username"' "$HOME/.usm/instances"
	#sed -i -e 2's/$/ "$address"' "$HOME/.usm/instances"
	echo "${instances[*]}" > "$HOME/.usm/data/instances"
	read -n1 -r -p "$(echo -e 'Instance added. Add another? (Y/n)')" answer
	case "$answer" in
		[yY]|[Yy][Ee][Ss] ) echo; menu_check;;
		[Nn]|[Nn][Oo] ) echo; main_menu;;
		* ) invalid_input;;
	esac
}

ssh_remove() {
	LASTMENU="ssh_remove"
	echo -e 'Please select an SSH instance to remove, User:\n'
  for ((i=1;i<${#instances[@]};i++)); do
		echo [$i] ${instances[$i]}
	done
	read -n1 -r -p "" selection
	if [[ "$selection" < "${#instances[@]}" ]]; then
		read -n1 -r -p "$(echo -e "\nDelete '${instances[$selection]}'? (Y/n)")" answer
		case "$answer" in
			[Nn]|[Nn][Oo] ) echo; menu_check;;
			[yY]|[Yy][Ee][Ss] ) instances=( ${instances[@]/${instances[$selection]}} );
			echo "${instances[*]}" > "$HOME/.usm/data/instances";
			read -n1 -r -p "$(echo -e '\nInstance removed. Remove another? (Y/n)')" answer;
			case "$answer" in
				[yY]|[Yy][Ee][Ss] ) echo; menu_check;;
				[Nn]|[Nn][Oo] ) echo; main_menu;;
				* ) invalid_input;;
			esac;;
		esac
	else
		invalid_input
	fi
}

main_menu() {
	LASTMENU="main_menu"
	read -n1 -r -p "$(echo -e 'Please select an option, User: \n\n[1] Start…\n[2] Add…\n[3] Remove…\n[4] Exit.\n\b')" selection
	case "$selection" in
		[1] ) echo; ssh_start;;
		[2] ) echo; ssh_add;;
		[3] ) echo; ssh_remove;;
		[4] ) echo; exit 0;;
		*   ) invalid_input;;
	esac
}

menu_check() {
	$LASTMENU
	}

input_attempts_max() {
	echo -e "\nMaximum input attempts exceeded.\nPlease ensure all your fingers are intact and try again, User.";
	exit 0;
	}

ssh_start() {
	LASTMENU=ssh_start
	echo -e 'Please select an SSH instance, User:\n'
	for ((i=1;i<${#instances[@]};i++)); do
		echo [$i] ${instances[$i]}
	done
	read -n1 -r -p "" selection
	if [[ "$selection" < "${#instances[@]}" ]]; then
    SESSION="$(echo "${instances[$selection]}" | awk -F ':' '{print $1}')"
    PORT="$(echo "${instances[$selection]}" | awk -F ':' '{print $2}')"
    echo -e "\nStarting session… \n"
		ssh "$SESSION" -p "$PORT"
	else
		invalid_input
	fi
	}

invalid_input() {
	((INPUT_ATTEMPTS++));
	if [[ "$INPUT_ATTEMPTS" -eq "$MAX_ATTEMPTS" ]]; then
		input_attempts_max;
	else
		echo -e "\nInvalid input. Please try again.";
		menu_check;
	fi
	}

while getopts ahrsv option
	do
		case "$option" in
			a ) ssh_add;;
			h ) echo -e "$HELP"; exit 0;;
			r ) ssh_remove;;
			s ) ssh_start;;
			v ) echo $VERSION; exit 0;;
      * ) echo -e "Use option '-h' to view help."; exit 0;;
		esac
done

main_menu
