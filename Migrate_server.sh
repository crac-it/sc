#!/bin/bash
# @Description Migrate A Ubuntu Server
# @Usage Copy to the source server and run with: sh migrate_server.sh

# @Returns success or failure
function is_root_user() {
	[ $(id -u) -eq 0 ] && return 0 || return 1
}

# @Returns text and if not root user exits with code 1 (error)
function require_root_user() {	
	if is_root_user
	then
		echo "Are We Runnning As Root? [ Yes ]"
	else
		echo "Are We Running As Root? [ No ]"
		echo "Fatal Error: You must be logged in as root to execute this shell script."
		exit 1
	fi	
}

require_root_user

read -p "Provide the destination server IP address or hostname: " destination_ip_address

echo -e "\n"
echo "##########################################################################"
echo "###   WHEN PROMPTED, PROVIDE THE DESTINATION SERVERS ROOT PASSWORD.    ###"
echo "##########################################################################"
echo -e "\n"

#Install rsync on the destination
ssh root@$destination_ip_address apt-get -y install rsync

#Make sure we were able to ssh successfully
rc=$?
[ "$rc" = "255" ] && exit 1

#Install rsync on the source
yum -y install rsync

#Yum clean all on the source, to free up some disk space
yum -y clean all

#Create the rsync_excludes file on the source
echo -e "/boot\n/proc\n/sys\n/tmp\n/dev\n/etc/fstab\n/etc/resolv.conf\n/etc/conf.d/net\n/etc/network/interfaces\n/etc/sysconfig/network-scripts/ifcfg-eth*" > /rsync_excludes.txt

#Stop critical services on source
for i in lighttpd httpd nginx mysqld postgresql proftpd postfix
do
	#Set rc equal to status code
	service $i status 2>/dev/null
	rc=$?
	
	#If status equals 0, we know its running, and can stop it
	[ "$rc" == "0" ] && service $i stop
done

echo -e "\n"
echo "##########################################################################"
echo "###   WHEN PROMPTED, PROVIDE THE DESTINATION SERVERS ROOT PASSWORD.    ###"
echo "##########################################################################"
echo -e "\n"

#Do the rsync
rsync -avz --delete --exclude-from=/rsync_excludes.txt / root@${destination_ip_address}:/

#Make sure we were able to login successfully
rc=$?
[ "$rc" = "255" ] && exit 1

echo -e "\n"
echo "##########################################################################"
echo "###   WHEN PROMPTED, PROVIDE THE DESTINATION SERVERS ROOT PASSWORD.    ###"
echo "##########################################################################"
echo -e "\n"

#First we have to clear the source known_hosts file
echo > ~/.ssh/known_hosts

#Delete the rsync_excludes.txt file on the destination
ssh root@$destination_ip_address rm -f /rsync_excludes.txt

#Complete
echo -e "\n"
echo "########################################################################"
echo "#                          ! VERY IMPORTANT !                          #"
echo "# You MUST go into the destination server and modify the network file. #"
echo "#  The destination GATEWAY ADDRESS must be updated before you reboot.  #"
echo "#                                                                      #"
echo "#                     Modify /etc/sysconfig/network                    #"
echo "#                                                                      #"
echo "# Update the gateway address to the proper destination server address. #"
echo "#                                                                      #"
echo "#  AGAIN, THE DESTINATION GATEWAY ADDRESS MUST BE UPDATED BEFORE YOU   #"
echo "#  REBOOT. FAILURE TO DO THIS, MAY RESULT IN THE DESTINATION SERVER    #"
echo "#  BEING INACCESSIBLE.                                                 #"
echo "########################################################################"
echo -e "\n"
echo "########################################################################"
echo "### PLEASE --REBOOT-- THE DESTINATION SERVER TO FINALIZE MIGRATION.  ###"
echo "########################################################################"
echo -e "\n"

exit 0
