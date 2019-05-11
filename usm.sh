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
#set a variable with the current directory as it's value
DIR="$(cd "$(dirname "$0")"&& pwd)"
#set variables for input attempt handling
INPUT_ATTEMPTS=0
MAX_ATTEMPTS=3
#set a variable with the instances file. this is where the sessions are stored
INSTANCES_FILE="$HOME/.usm/data/instances"
#set the default port value
PORT=22

#if the necessary folders and files do not exist, create them
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
  #this dummy entry ensures the instances array actually starts at 1 instead of 0
  echo "dummyentry" >> "$INSTANCES_FILE"
fi

#declare the instances array
declare -a instances
#and read the values from the instances file into the array
read -a instances <"$INSTANCES_FILE"

##For testing array storage/retrieval
#INSTANCES=`cat $DIR/sshinstances.sh`
#ARRAY_SIZE=${#instances[*]}
#echo "Array size is "$ARRAY_SIZE

#allows the addition of sessions to be saved
ssh_add() {
  #this variable is used to return to this menu
	LASTMENU="ssh_add"
  #read and store input as variable
  #'read' takes input from the command line
	read -r -p "$(echo -e 'Please enter the username you would like to use for this session:\n')" username
	USERNAME=$username
	read -r -p "$(echo -e 'Please enter the IP address you would like to use for this session:\n')" address
	ADDRESS=$address
  read -r -p "$(echo -e 'Please enter the port number you would like to use for this session(None for default):\n')" port
  #if the port is not empty, set the variable to the given port, otherwise keep the default
  if [ "$port" != "" ]; then PORT=$port; fi
  #add the combined given values to the instances array
	instances+=("$USERNAME"@"$ADDRESS":"$PORT")
	##Currently unused alternative method
	#sed -i -e 1's/$/ "$username"' "$HOME/.usm/instances"
	#sed -i -e 2's/$/ "$address"' "$HOME/.usm/instances"
  #save the array back to the instances file '>' overwrites the contents ('>>' would only append it)
	echo "${instances[*]}" > "$HOME/.usm/data/instances"
  #if the user wants to ad another instance now they can quickly return to the add menu here
	read -n1 -r -p "$(echo -e 'Instance added. Add another? (Y/n)')" answer
	case "$answer" in
    #'[yY]|[Yy][Ee][Ss]' and '[Nn]|[Nn][Oo]' allow the user to enter 'yes', 'no', 'y', or 'n' without regard for capitalization
		[yY]|[Yy][Ee][Ss] ) echo; menu_check;;
		[Nn]|[Nn][Oo] ) echo; main_menu;;
		* ) invalid_input;;
	esac
}

#allows the removal of saved sessions
ssh_remove() {
	LASTMENU="ssh_remove"
	echo -e 'Please select an SSH instance to remove, User:\n'
  #prints every saved session for choosing
  for ((i=1;i<${#instances[@]};i++)); do
		echo [$i] ${instances[$i]}
	done
	read -n1 -r -p "" selection
  #if the choice inputted (a number) is less than the total number of instances, continue, otherwise call the 'invalid_input' function
	if [[ "$selection" < "${#instances[@]}" ]]; then
		read -n1 -r -p "$(echo -e "\nDelete '${instances[$selection]}'? (Y/n)")" answer
		case "$answer" in
			[Nn]|[Nn][Oo] ) echo; menu_check;;
			[yY]|[Yy][Ee][Ss] ) instances=( ${instances[@]/${instances[$selection]}} ); #changes the instances array to itself minus the chosen instance
      #save the updated array to the instances file
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

#the main menu is where the program starts by default, and includes the basic actions that can be taken
main_menu() {
	LASTMENU="main_menu"
  #print the menu options
	read -n1 -r -p "$(echo -e 'Please select an option, User: \n\n[1] Start…\n[2] Add…\n[3] Remove…\n[4] Exit.\n\b')" selection
	case "$selection" in
		[1] ) echo; ssh_start;;
		[2] ) echo; ssh_add;;
		[3] ) echo; ssh_remove;;
		[4] ) echo; exit 0;;
		*   ) invalid_input;;
	esac
}

#this function just returns the value of the 'LASTMENU' variable
menu_check() {
	$LASTMENU
	}

#prints a message and exits. this is called by the 'invalid_input' function only
input_attempts_max() {
	echo -e "\nMaximum input attempts exceeded.\nPlease ensure all your fingers are intact and try again, User.";
	exit 0;
	}

#allows user to choose and start a saved ssh session
ssh_start() {
	LASTMENU=ssh_start
	echo -e 'Please select an SSH instance, User:\n'
  #print the instances (like in 'ssh_remove')
	for ((i=1;i<${#instances[@]};i++)); do
		echo [$i] ${instances[$i]}
	done
	read -n1 -r -p "" selection
  #check that the selection is less than the total number of instances
	if [[ "$selection" < "${#instances[@]}" ]]; then
    #set a variable to the username and host from the instances file. awk parses the strings on either side of the ':' delimiter
    SESSION="$(echo "${instances[$selection]}" | awk -F ':' '{print $1}')"
    #set a variable to the port from the instances file
    PORT="$(echo "${instances[$selection]}" | awk -F ':' '{print $2}')"
    echo -e "\nStarting session… \n"
		ssh "$SESSION" -p "$PORT"
	else
		invalid_input
	fi
	}

#handle invalid inputs (e.g. typos, out of bound selections, chars instead of ints)
invalid_input() {
  #increment the INPUT_ATTEMPTS variable by 1
	((INPUT_ATTEMPTS++));
  #if the number of attempts is equal to the maximum, call the 'input_attempts_max' function
	if [[ "$INPUT_ATTEMPTS" -eq "$MAX_ATTEMPTS" ]]; then
		input_attempts_max;
  #otherwise print a message and return to the last menu
	else
		echo -e "\nInvalid input. Please try again.";
		menu_check;
	fi
	}

#handles command line options
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

#call the main function
main_menu
