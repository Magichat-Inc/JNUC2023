#!/bin/bash

#===================================
# For JNUC 2023 conference
# https://reg.rainfocus.com/flow/jamf/jnuc2023/home23/page/sessioncatalog/session/1682577708226001MoLa
# Natnicha Sangsasitorn - Magic Hat Inc. 
# 15/07/2023
#===================================

#check if DEPNotify app is installed
if [[ ! -d /Applications/Utilities/DEPNotify.app ]]
then
	echo "Not yet installed DEPNotify.\n Start installing DEPNotify."
	jamf policy -event depnotifyInstall
	echo "finished installing DEPNotify"
else
	echo "already installed DEPNotify"
fi

#check if Aftermath app is installed
if [[ ! -x /usr/local/bin/aftermath ]]
then
	echo "Not yet installed Aftermath.\n Start installing Aftermath."
	jamf policy -event aftermathInstall
	echo "finished installing Aftermath"
else
	echo "already installed Aftermath"
fi

sleep 10

#Running the main workflow script
echo "Running DEPNotify's workflow script"
jamf policy -event depnotifyScript
