#!/bin/bash

# this condition is to check for username
if [ ${1,,} = adekunle ]; then
	# use this line to print welcome message
	echo "Welcome back boss you are welcome to the office"
	# this second condition is to check for help argument
elif [ ${1,,} = help ]; then
	# print out help message
	echo "Just type in the UserName"
else 
	# print out error message
	echo "I dont know you Mr Man, Fashi jhoor"
fi

