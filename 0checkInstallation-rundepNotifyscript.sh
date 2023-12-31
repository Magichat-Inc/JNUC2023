#!/bin/bash

#===================================
# For JNUC 2023 conference
# https://reg.rainfocus.com/flow/jamf/jnuc2023/home23/page/sessioncatalog/session/1682577708226001MoLa
# Natnicha Sangsasitorn - Magic Hat Inc. 
# 28/08/2023
#===================================

#check if DEPNotify app is installed
#DEPNotify app can be downloaded from below link
#https://gitlab.com/Mactroll/DEPNotify/-/releases
if [[ ! -d /Applications/Utilities/DEPNotify.app ]]
then
	echo "Not yet installed DEPNotify.\n Start installing DEPNotify."
	jamf policy -event depnotifyInstall
	echo "finished installing DEPNotify"
else
	echo "already installed DEPNotify"
fi

#check if Aftermath app is installed
#AfterMath app (The version I'm using: 1.2.0) can be downloaded from below link
#https://github.com/jamf/aftermath/releases
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
