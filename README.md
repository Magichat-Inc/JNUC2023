# JNUC 2023: Attacks and Suspicious Events’ Cause Analysis Workflow

- [Introduction](#introduction)
- [Overview](#overview)
- [0checkInstallation-rundepNotifyscript.sh](#0checkInstallation-rundepNotifyscript.sh)

## [Introduction](#introduction)

Right as most companies were finally getting used to remote work, the work environment changed once again: many companies now have employees asking to work back in the office, to stay at home or for some form of hybrid option.

This brings up more unique security concerns as companies now have more entry points that outside attacks can target with a multitude of different types of malware. This makes it much harder for the security team to properly identify how the attack got through their defense, and to patch those holes effectively. Thanks to Jamf Protect, we can now get alerts when these types of attacks present themselves, but without knowing what caused the security breach leading to the attack, there is no way to effectively prevent the same issue from occurring again.

In this session, I will walk through how to create a “cause analysis workflow” using a combination of Jamf Pro, Jamf Protect, Splunk (SIEM product), Slack, DepNotify and Aftermath (open-source incident response tool), which will present a map they can use to find the source of the problem and fix it at its root.

Session details & video: <https://reg.jamf.com/flow/jamf/jnuc2023/home23/page/sessioncatalog/session/1682577708226001MoLa> 

## [Overview](#overview)
These scripts are used for setting up the workflow shown in "Attacks and Suspicious Events’ Cause Analysis Workflow" session on JNUC 2023 Conference.

There are 4 scripts:
- 0checkInstallation-rundepNotifyscript.sh
- 1depNotifyRun.sh
- 2networkisolation-enforce.sh
- 3sendInfotoSplunk.sh

## [0checkInstallation-rundepNotifyscript.sh](#0checkInstallation-rundepNotifyscript.sh)

This script is for checking installation of afterMath (Incident Response tool) and depNotify (Graphical User Interface Popup tool) and run installation if the machine hasn't installed those tools yet.

## 1depNotifyRun.sh

This script is main script for showing the progress popup while running below the settings
- attack/breach's remedial command
- incident response and forward those information to third party SIEM tool (Splunk)

## 2networkisolation-enforce.sh
To remediate the attack or breach (Reverse shell attack is used as a sample in the workflow), we kill the interactive shell process, following by enforcing network isolation to make sure that during analysis, there is no further attempts from the attackers. So, no communication is allowed except Jamf and Splunk communication. 

## 3sendInfotoSplunk.sh
For incident response, AfterMath tool is used to gather all the evidences and events happened on the affected computers. Then, those information will be forwarded to Splunk for further analysis.

