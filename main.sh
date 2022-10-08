#!/usr/bin/env bash

curr=$(pwd)
data=$curr/data/issues.db
logFile=$curr/logs/$(date "+%Y%m%d")_jira_api.log
if [ ! -d "$curr/logs" ]; then mkdir $curr/logs; fi


while getopts "a:N:e:m:t:I:P:c:d:U:C:h:" opt; do
    case $opt in
		a)	ACCOUNTID="$OPTARG"
			;;
		N)	FULL_NAME="$OPTARG"
			;;
		e)	EMAIL="$OPTARG"
			;;
		m)	MESSAGE="$OPTARG"
			;;
		t)	TOKEN="$OPTARG"
			;;
		I)	ISSUE_TYPE="$OPTARG"
			;;
		P)	PROJECT_KEY="$OPTARG"
			;;
		U)	URL="$OPTARG"
			;;
		C)	COMMENT="$OPTARG"
			;;
		d)	DISMISS="$OPTARG"
			;;
		h)	helpFlag="$OPTARG"
			;;
    esac
done

# Need to export this variables to pass to external *.api script.
export ACCOUNTID=$ACCOUNTID
export FULL_NAME=$FULL_NAME
export ISSUE_TYPE=$ISSUE_TYPE
export PROJECT_KEY=$PROJECT_KEY
export EMAIL=$EMAIL
export MESSAGE=$MESSAGE
export TOKEN=$TOKEN
export URL=$URL
export COMMENT=$COMMENT
export DISMISS=$DISMISS

helpFunction() {
	echo ""
	echo "LIMITED OPERAIONS WITH JIRA API V3"
	echo ""
	echo "Author: Fariz Muradov"
	echo "Mail: fariz.muradov@inno2grid.com"
	echo ""
	echo "-a		Account ID"
	echo "-N		Full Name, this ususally need when you make ticket"
	echo "-e		Owner Jira email"
	echo "-t		Owner Jira token"
	echo "-I		Issue type on Jira. i.e Task"
	echo "-P		Project ID on Jira"
	echo "-U		URL of issue"
	echo "-C		Comment on Jira ticket"
	echo "-d		Dismiss flag 0 or 1. If -d 1 then provided ticket will dismissed"
	echo ""
	echo "EXAMPLE:"
	echo './main.sh \
	-a "<accountID> " \
	-e "fariz.muradov@inno2grid.com" \
	-N "Fariz Muradov"
	-t "<Token>" \
	-I "<IssueTypeID>" \
	-P "<ProjectI?D>" \
	-U "https://inno2grid.atlassian.net/rest/api/3/issue/17058" \
	-C "Cpu is very high on device. More than 90%" \
	-d 0 \
	-m "HIGH CPU on IoT sensor: DeviceN"'
	echo ""
	echo ""
	echo "You can use below URL to get necessary inforation/IDs about JIRA:"
	echo "*	Get project ID by Project name:"
	echo '		$ curl -s --url "https://<JIRA URL>/rest/api/3/project" \'
	echo ' 		  --user "<EMAIL>:<TOKEN>"	\'
	echo '		  --header "Accept: application/json" \'
	echo '		  --header "Content-Type: application/json" | jq ".[] | select(.key=="<PROJECT KEY>")" | jq .id"'
	echo ''
	echo "*	Get issue type ID by Project ID (Task, Bug, etc.):"
	echo '		$ curl -s --url "https://<JIRA URL>/rest/api/3/project/<PROJECT ID>" \ '
	echo '		--user  "<EMAIL>:<TOKEN>" \'   
	echo '		--header "Accept: application/json" \'   
	echo '		--header "Content-Type: application/json" | jq ".issueTypes" | jq ".[] | select(.name=="Task")'
	echo ''
	echo '*	Get Account ID information:'
	echo '		On browser or curl (via auth):'
	echo '		https://<JIRA URL>/rest/api/latest/user/search?query=fariz.muradov@inno2grid.com'
	echo
	echo 'Free to use'
}

# /*	If any of above variable is not set, then help Function will execute.
if	[ -z "$ACCOUNTID" ]		||
	[ -z "$FULL_NAME" ]		||
	[ -z "$ISSUE_TYPE" ]		||
	[ -z "$PROJECT_KEY" ]		||
	[ -z "$EMAIL" ]			||
	[ -z "$TOKEN" ]			||
	[ -z "$URL" ]			||
	[ -z "$COMMENT" ]		||
	[ -z "$DISMISS" ]; then
		helpFunction			
		exit 0
fi
	

initDB() {
	# */ Create configuration table if not exist.
	echo "CREATE TABLE IF NOT EXISTS issues (issueID text, issueName text,issueComment text, issueSummary text, key text, RESERVED text);" | sqlite3 $data
}

checkTicketExist() {
	issueID=$(echo "select issueID from issues where issueSummary=\"$MESSAGE\" ORDER by 1 DESC LIMIT 1 ;" | sqlite3 $data)
	ret=$?
	[ $ret -ne 0 ] && echo "ERROR| $(date)| Somehow reading database is ERROR" >> $logFile ;
	[ $ret -ne 0 ] && exit 1
	[ "$issueID" == "null" ] && issueID=0           # /* Act based on return message from SQLITE   
	[ ${#issueID} -eq 0 ] && issueID=0		# /* no ticket exist. Need to create
	if  [ ${#issueID} -ge 5 ] && 
		[[ ${issueID} == ?(-)+([[:digit:]]) ]]; then
			issueID=$issueID                           	 
	fi
	echo $issueID
}

installPackages() {
	# */ if packages are not exist then install.
	repoUpdate=0
	for i in $(cat requirements.txt ); do
		if [ ! -f $(which  ${i}) ]; then
			if [ $repoUpdate -eq 0 ]; then sudo apt-get update; repoUpdate=1 ; fi   ## No need to apt update for each package
			echo "$i package not found. Going to install"
			sudo apt-get install $i -y
		fi
	done
	}


main() {
	# Main scenario here.
	installPackages
	initDB
	export issueID=$(checkTicketExist)   # /* Get issueID via -m argument. where issueSummary=$m

	if		[ $issueID -eq 0 ] && [ $DISMISS -ne 1 ]; then
				# * It means ticket is not exist. 
				# * I am going to add Ticket and save return data to database
				returnData=$(${curr}/api/addIssue.api)  		 		# * Send Add Ticket to API
					issueID=$(echo ${returnData}	| jq .id -r)		# * get IssueID. It needs for build URL for other API.
					key=$(echo ${returnData}		| jq .key -r)		# * Not necessary. I don't know why I am extracting.
					issueLink=$(echo ${returnData}	| jq .self -r)		# * This is will return api link of ticket
				echo	"insert into issues \
								(issueID,issueSummary,issueName,key) \
						values \
								(\"$issueID\",\"$MESSAGE\",\"$issueLink\",\"$key\");" \
				| sqlite3 $data    # */ save created ticket
				
				echo "INFO| $(date)| There is no ticket, but no worries, Zabbix will do for you" >> $logFile			  
				
	elif	[ $issueID -eq $issueID ] && [ ${#issueID} -ge 5 ] && [ $DISMISS -ne 1 ] && [ $DISMISS -ne 1 ] ; then
				$curr/api/updateIssue.api > /dev/null   							# will update existing ticket with MESSAGE var.
				echo "INFO| $(date)| Ticket $issueID is updated" >> $logFile
	elif	[ $issueID -eq $issueID ] && [ ${#issueID} -ge 5 ] && [ $DISMISS -eq 1 ] ; then
				req=$(${curr}/api/dismissIssue.api) 		  # will dismiss this ticket if Resolve by Zabbix.
				# /* Control return message from Jira
				if	[ ${#req} -gt 0 ] &&
					[ $(echo $req | jq '.errorMessages | length' ) -eq 0 ] ; then
					echo "ERROR $(date)| $req" && exit 1
				fi								# will dismiss this ticket if Resolve by Zabbix.
				echo "delete from issues where issueID=$issueID;" | sqlite3 $data
				echo "INFO| $(date)| Well done. Zabbix found $issueID issue is not relavant anymore" >> $logFile
	elif	[ $issueID -eq 1 ]; then	
				echo "ERROR| $(date)| Some ERROR. Please check what your dummy script !!! " >> $logFile
	fi
}

main
