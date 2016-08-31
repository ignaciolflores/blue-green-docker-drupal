#!/bin/bash

######################################
# GREEN BLUE DEPLOYMENT USING DOCKER #
######################################

# Get the status of the application from the
# properties file, and if it does not exists
# init the variables to the first version
getProperties () {
	if [ ! -f $PROPERTIES_FILE ]; then
		echo "Properties File not found!"
		echo "Initializing variables"
		running_color="blue"
		running_version="1.0"
		new_color="green"
		previous_version="0"
	else
		. $PROPERTIES_FILE
		if [ "$running_color" = "green" ]; then
			new_color="blue"
		else
			new_color="green"
		fi
	fi

	echo "Running configuration:"
	echo "running_color: $running_color"
	echo "running_version: $running_version"
	echo "previous_version: $previous_version"
	echo "new_color: $new_color"
	echo ""

}

# Updates a param in the config file with a new value
# $1 - param name
# $2 - new param value
updateProperty () {
	/bin/sed -i "s/^\($1\s*=\s*\).*\$/\1$2/" $PROPERTIES_FILE
}

pull() {
	echo "Pulling..."
	/usr/local/bin/docker-compose pull $new_color
}


deploy () {
	containers=$1
	echo "Deploying $containers containers of color $new_color"

	for i in $(/usr/bin/seq 1 $containers)
	do
		/usr/local/bin/docker-compose scale "$running_color"=$(( containers - i )) "$new_color"=$i

		# This if should be done in a more elegant way...
		if [ $i == 1 ]; then
			updateApp
		fi
	done
}

updateApp () {
	for i in 1 2 3
	do
		echo "Updating the app...$i"
		/usr/local/bin/docker-compose exec "$new_color" sleep 1
	done


}

############################################
#                                          #
#                    Main                  #
#                                          #
############################################

# 1- Preparation
PATH=/var/dockers/gbtest
PROPERTIES_FILE_NAME=blue-green.properties
PROPERTIES_FILE=$PATH/$PROPERTIES_FILE_NAME

IMAGE_NAME="ignacio/apache"

# Test the param numbers

if [ "$#" -ne 1 ]; then
	echo "Usage: ./blue-green new_version"
	exit 1
fi

IMAGE_NEW_VERSION="$1"

echo "Let's deploy $IMAGE_NAME:$IMAGE_NEW_VERSION"

# TODO: test that the requirements fit our needs
# docker exists
# sed exists
# docker-compose exists
# seq exists
# test permission


# 1.1- Get information
getProperties

# 1.2- Backup

# 2- Pull
# Update the docker-compose.yml to the new version
/bin/sed -i "s~$IMAGE_NAME\:$previous_version~$IMAGE_NAME\:$IMAGE_NEW_VERSION~g" docker-compose.yml

# TODO: add a param to set that the image is a local one and doesn't need to be pulled
#pull


# 3- Deploy

# 4- Loop until all instances have been updated 

# TODO: 8 must be a param
deploy 8

# 5- Update properties file
updateProperty previous_version $running_version
updateProperty running_color $new_color
updateProperty running_version $IMAGE_NEW_VERSION

