#!/bin/bash

sudo aftermath --cleanup
sleep 10

# my computer takes about 4 min
sudo aftermath --pretty
serialNumber=$(ioreg -l | awk -F'"' '/IOPlatformSerialNumber/{print $4}')
aftermathOriginalFile="/private/tmp/Aftermath_${serialNumber}.zip"
echo $aftermathOriginalFile
sleep 10

# my computer takes about 1.5 min
sudo aftermath --analyze ${aftermathOriginalFile} --pretty
aftermathAnalyzeResults="/private/tmp/Aftermath_Analysis_${serialNumber}.zip"
echo $aftermathAnalyzeResults
sleep 5

unzip ${aftermathAnalyzeResults} -d /private/tmp
aftermathTimeline="/private/tmp/Aftermath_Analysis_${serialNumber}/storyline.csv"
echo $aftermathTimeline

#=========================================================
# add serial information on json file
# compare the date put the information from ytd time to td time
# send to splunk HEC

hostName=$(scutil --get ComputerName)
#From which point of time do you like to send the data to splunk (for example, 9 hour or 1 day from NOW )
#now=$(date -v-1d +"%Y-%m-%dT%H:%M:%SZ")
now=$(date -v -9H +"%Y-%m-%dT%H:%M:%SZ")
echo $now
timestamp1=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$now" "+%s")
splunkHECURL="https://splunkhec.magichat.cloud"
endingHECtoken="00aba3c6-3000-49ed-b08a-f16dd2c2209a"
dashboardHECtoken="2c0263dc-7534-4720-be7d-fc381464398c"

while IFS='' read -r line || [ "$line" ]
do
	originalDate=$(echo "$line" | awk -F ',' '{print $1}') 
	echo "OriginalDateUTC= $originalDate" >> /private/tmp/aftermath_temp.txt
	originalDateEpoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" $originalDate +"%s" )
	originalDateEpochJST=$(( $originalDateEpoch+32400 ))
	originalDateJST=$(date -r $originalDateEpochJST +"%Y-%m-%dT%H:%M:%SZ")
	
	#In order to notify slack, we set separate HEC for sending the end message. Once Splunk got the message sent, it will notify Slack channel.
	if [[ "$timestamp1" -gt "$originalDateEpochJST" ]]; then
    	json="{\"event\": \"ENDING MESSAGE\", \"serialNumber\": \"$serialNumber\", \"hostName\": \"$hostName\"}"
        curl ${splunkHECURL}/services/collector/raw -H "Authorization: Splunk ${endingHECtoken}" -d "$json"
		break;
	fi
	
	json=$(echo "$line" | awk -F ',' '{printf "{ \"category\": \"%s\", \"event\": \"%s\"}\n", $2, $3}')
	hostInfo=", \"serialNumber\": \"$serialNumber\", \"hostName\": \"$hostName\"}"
	hostInfo1="{\"originalDate\": \"$originalDateJST\","
	json=$(echo $json | sed "s/}/$hostInfo/g")
	json=$(echo $json | sed "s/{/$hostInfo1/g")
	echo $json >> /private/tmp/aftermath_temp.txt
	
	# Sending the information to Splunk Analysis Dashboard
	curl ${splunkHECURL}/services/collector/raw -H "Authorization: Splunk ${dashboardHECtoken}" -d "$json"
	
done < ${aftermathTimeline}
