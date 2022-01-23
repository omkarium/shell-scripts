#! /usr/bin/bash
echo "Is the first time you are trying to encrypt"
option="${1}"
case ${option} in
	-en) inFile=${2}
		echo "The file.to be encrypted is $FILE"
		$(openssl enc -aes-256-cbc -base64 -in ${inFile} -k ${3} -iv ${4})
		;;
	-ed) DIR="${2}"
		echo "Dir name is $DIR"
		;;
	-de)
		echo
		;;
	*)
		echo "`basename ${0}`:usage: [-f file] | [-d directory]"
		exit 1 # Command to come out of the program with status 1
		;;
esac
