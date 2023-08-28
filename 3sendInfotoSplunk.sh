#!/bin/bash

#===================================
# For JNUC 2023 conference
# https://reg.rainfocus.com/flow/jamf/jnuc2023/home23/page/sessioncatalog/session/1682577708226001MoLa
# Natnicha Sangsasitorn - Magic Hat Inc. 
# 28/08/2023
#
# The script cleans up AfterMath log and run AfterMath to capture browser and system's activity logs.
# Then, unzip the file and process each events and send to Splunk through HTTP Endpoint Collection (HEC).
#
# The settings you need to set:
# 1. splunkHECURL (Splunk URL), dashboardHECtoken (Main HEC token), endingHECtoken (Separate HEC token for notifying Slack)
# 2. From which point of time you would like to send the AfterMath data to splunk (for example, 9 hours or 1 day from NOW ), you can change on line 59.
# Default setting is collecting information from 9 hours from now.
# 3. Due to this issue (https://github.com/jamf/aftermath/issues/49), We convert time of Syslog events to JST(Japan Standard Time) which is UTC+9. 
# If you would like to convert to your timezone, you can change Number of seconds added on line 71. (Number of seconds=Number of hours differ from UTC*60*60)
#===================================

# Clean up Aftermath file and log
sudo aftermath --cleanup

if [[ -f /private/tmp/aftermath_temp.txt ]]
then  rm -rf /private/tmp/aftermath_temp.txt 
fi

sleep 10

# Gather all logs
sudo aftermath --pretty
serialNumber=$(ioreg -l | awk -F'"' '/IOPlatformSerialNumber/{print $4}')
aftermathOriginalFile="/private/tmp/Aftermath_${serialNumber}.zip"
echo $aftermathOriginalFile
sleep 10

# Run analyze mode to make all log in timeline format
sudo aftermath --analyze ${aftermathOriginalFile} --pretty
aftermathAnalyzeResults="/private/tmp/Aftermath_Analysis_${serialNumber}.zip"
echo $aftermathAnalyzeResults
sleep 5

# Unzip the timeline file we would like to process
unzip ${aftermathAnalyzeResults} -d /private/tmp
aftermathTimeline="/private/tmp/Aftermath_Analysis_${serialNumber}/storyline.csv"
echo $aftermathTimeline

#=========================================================
# Set point of time of the events you'd like to send to Splunk (for example, send the event occurred 9 hour before until NOW )
# Convert Syslog events' time to local timezone (JST) 
# Compose the json file from the event data and add occurence time (in local timezone), serial number, and host name info to the event's json file

hostName=$(scutil --get ComputerName)
splunkHECURL=""
endingHECtoken=""
dashboardHECtoken=""

#Set point of time of the events you'd like to send to Splunk (for example, 9 hours or 1 day from NOW )
#now=$(date -v-1d +"%Y-%m-%dT%H:%M:%SZ") # 1 day from NOW
now=$(date -v -9H +"%Y-%m-%dT%H:%M:%SZ") # 9 hours from NOW
echo $now
timestamp1=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$now" "+%s")

while IFS='' read -r line || [ "$line" ]
do
	originalDate=$(echo "$line" | awk -F ',' '{print $1}') 
	category=$(echo "$line" | awk -F ',' '{print $2}') 
	echo "OriginalDateUTC= $originalDate" >> /private/tmp/aftermath_temp.txt
	originalDateEpoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" $originalDate +"%s" )
	if [[ $category != *"SYSLOG"* ]]
	then
		originalDateEpochJST=$(( $originalDateEpoch+32400 ))
	else
		originalDateEpochJST=$originalDateEpoch
	fi
	originalDateJST=$(date -r $originalDateEpochJST +"%Y-%m-%dT%H:%M:%SZ")
	
	#In order to notify slack, we set separate HEC for sending the end message. Once Splunk got this message, it will notify Slack channel.
	if [[ $category != *"SYSLOG"* && "$timestamp1" -gt "$originalDateEpochJST" ]]; then
		json="{\"event\": \"ENDING MESSAGE\", \"serialNumber\": \"$serialNumber\", \"hostName\": \"$hostName\"}"
		curl ${splunkHECURL}/services/collector/raw -H "Authorization: Splunk ${endingHECtoken}" -d "$json"
		break;
	elif [[ "$timestamp1" -le "$originalDateEpochJST" ]]; then
		json=$(echo "$line" | awk -F ',' '{printf "{ \"category\": \"%s\", \"event\": \"%s\"}\n", $2, $3}')
		hostInfo=", \"serialNumber\": \"$serialNumber\", \"hostName\": \"$hostName\"}"
		hostInfo1="{\"originalDate\": \"$originalDateJST\","
		json=$(echo $json | sed "s/}/$hostInfo/g")
		json=$(echo $json | sed "s/{/$hostInfo1/g")
		echo $json >> /private/tmp/aftermath_temp.txt
			
		# Sending the information to Splunk Analysis Dashboard
		curl ${splunkHECURL}/services/collector/raw -H "Authorization: Splunk ${dashboardHECtoken}" -d "$json"
	fi
	
done < ${aftermathTimeline}
