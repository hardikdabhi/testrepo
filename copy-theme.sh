#!/bin/bash
########################################
# user variables
########################################
default_protocol="http"
default_host="localhost"
default_port="10039"
default_username="wsadmin"
default_password="wsadmin"
default_profilePath="/opt/IBM/WebSphere/wp_profile"
default_portalPath="/opt/IBM/WebSphere/PortalServer"
default_server="WebSphere_Portal"
default_themeId="generatedTheme"
default_themeName="Generated Theme"

########################################
# common functions
########################################

# $1	variable to be assigned with value 
# $2	text to be dispayed to user
# $3	[optional] default value variable
# $4	[optional] true - remove spaces
readInput(){
	local temp
	if [ "$3" = "" ]; then
		echo -n "Enter $2: "
	else 
		echo -n "Enter $2 [$3]: "
	fi 
	read temp
	if [ "$4" != "true" ]; then
		temp=${temp//[[:blank:]]/}
	fi
	export $1="$temp"
	if [ "$temp" = "" ] ; then
		if [ "$3" = "" ] ; then 
			echo "---------------------------------------"
			echo "Invalid $2. Please try again."
			readInput $1 "$2"
		else
			export $1="$3"
		fi
	fi
}

# $1	gvfs source directory ending with "/"
# $2	destination directory ending with "/"
copyFilesFromGvfs(){
	for i in $(gvfs-ls $1); do
		IFS=": " read -a fileType <<< $(gvfs-info $1$i | grep ^type)
		if [[ "${fileType[1]}" == "directory" ]]; then
			mkdir $2$i
			copyFiles $1$i/ $2$i/
		else
			gvfs-copy "$1$i" $2
		fi
	done
}

# $1	source directory ending with "/"
# $2	gvfs destination directory ending with "/"
copyFilesToGvfs(){
	for i in $(ls $1); do
		#local path="$(pwd $i)/$1$i"
		#echo $path
		if [[ -d "$(pwd $i)/$1$i" ]]; then
			#echo "*********** $i is a directory..."
			gvfs-mkdir $2$i
			copyFilesToGvfs $1$i/ $2$i/
		else
			#echo "----------- $i is a file, going to copy!!"
			gvfs-copy "$1$i" $2
		fi
	done
}

# $1	file to write
# $2	content
writeToFile(){
	if [ ! -f "$1" ] ; then
		touch "$1"
	fi
	echo "$2" > $1
}

########################################
# specific functions
########################################
getInputs(){
	readInput protocol "Protocol" $default_protocol
	readInput host "Portal Host" $default_host
	readInput port "Portal Port" $default_port
	readInput username "Portal Username" $default_username
	readInput password "Portal Password" $default_password
	readInput profilePath "Portal Profile Path" $default_profilePath
	readInput portalPath "Portal Server Root" $default_portalPath
	readInput server "Portal Server Name" $default_server
	readInput themeId "New Theme ID" $default_themeId
	readInput themeName "New Theme Name" "$default_themeName"
}
generateStaticTheme(){
	echo "|--- creating static theme"
	mv $dirTemp/ibm.portal.85Theme $dirTemp/$themeId
	cd $dirTemp/$themeId
	#....metadata.properties
	local fileData=$(cat metadata.properties)
	local cFileData=${fileData//__THEME_ID__/$themeId}
	writeToFile metadata.properties "$cFileData"
	#....metadata/localized_en.properties
	fileData=$(cat metadata/localized_en.properties)
	cFileData=${fileData//__THEME_NAME__/$themeName}
	writeToFile metadata/localized_en.properties "$cFileData"
	#....profiles/profile_*.json
	fileData=$(cat profiles/profile_deferred.json)
	cFileData=${fileData//__THEME_ID__/$themeId}
	writeToFile profiles/profile_deferred.json "$cFileData"
	#...
	fileData=$(cat profiles/profile_dojo_deferred.json)
	cFileData=${fileData//__THEME_ID__/$themeId}
	writeToFile profiles/profile_dojo_deferred.json "$cFileData"
	#...
	fileData=$(cat profiles/profile_dojo_lightweight.json)
	cFileData=${fileData//__THEME_ID__/$themeId}
	writeToFile profiles/profile_dojo_lightweight.json "$cFileData"
	#...
	fileData=$(cat profiles/profile_lightweight.json)
	cFileData=${fileData//__THEME_ID__/$themeId}
	writeToFile profiles/profile_lightweight.json "$cFileData"
	#...
	fileData=$(cat profiles/profile_personalization.json)
	cFileData=${fileData//__THEME_ID__/$themeId}
	writeToFile profiles/profile_personalization.json "$cFileData"
	#...
	fileData=$(cat profiles/profile_wcmauthoring.json)
	cFileData=${fileData//__THEME_ID__/$themeId}
	writeToFile profiles/profile_wcmauthoring.json "$cFileData"
	#....nls/theme_en.html
	fileData=$(cat nls/theme_en.html)
	cFileData=${fileData//__THEME_ID__/$themeId}
	writeToFile nls/theme_en.html "$cFileData"
	
	cd "$scriptDir"
}
generateDynamicTheme(){
	echo "|--- creating dynamic theme"
	cd $dirTemp
	mv DefaultTheme85".ear" $themeId"_ear"
	cd $themeId"_ear"
	mv DefaultTheme85".war" $themeId"_war"
	cd $themeId"_war"
	#....WEB-INF/web.xml
	local fileData=$(cat WEB-INF/web.xml)
	local cFileData=${fileData//__THEME_ID__/$themeId}
	cFileData=${cFileData//__THEME_NAME__/$themeName}
	writeToFile WEB-INF/web.xml "$cFileData"
	#....WEB-INF/plugin.xml
	fileData=$(cat WEB-INF/plugin.xml)
	cFileData=${fileData//__THEME_ID__/$themeId}
	cFileData=${cFileData//__THEME_NAME__/$themeName}
	writeToFile WEB-INF/plugin.xml "$cFileData"
	
	echo "	|--- creation of war started"
	zip -r $themeId.war * &> /dev/null
	echo "	|--- creation of war completed"
	cd ..
	mv $themeId"_war"/$themeId".war" $themeId".war"
	rm -rf $themeId"_war"
	echo "	|--- creation of ear started"
	zip -r $themeId.ear * &> /dev/null
	echo "	|--- creation of ear completed"
	cd ..
	mv $themeId"_ear"/$themeId".ear" $themeId".ear"
	rm -rf $themeId"_ear"
	
	cd "$scriptDir"
}
deployStaticTheme(){
	echo "|--- deploying static resources started"
	#gvfs-mount dav://$username@$host:$port/wps/mycontenthandler/dav/themelist <<< "$username" &> /dev/null
	gvfs-mkdir dav://$host:$port/wps/mycontenthandler/dav/themelist/$themeId &> /dev/null
	copyFilesToGvfs $dirTemp/$themeId/ dav://$host:$port/wps/mycontenthandler/dav/themelist/$themeId/ &> /dev/null
	echo "|--- deploying static resources completed"
}
deployDynamicTheme(){
	echo "|--- installation of ear on was started"
	local command="\$AdminApp install $dirTemp/$themeId.ear {-contextroot /$themeId -usedefaultbindings}"
	sudo $profilePath/bin/wsadmin.sh -user $username -password $password -c "$command"
	echo "|--- installation of ear on was completed"
	echo "|--- saving configurations"
	command="\$AdminConfig save"
	sudo $profilePath/bin/wsadmin.sh -user $username -password $password -c "$command"
	echo "|--- starting dynamic theme"
	command="\$AdminControl invoke [\$AdminControl queryNames type=ApplicationManager,process=$server,*] startApplication $themeId"
	sudo $profilePath/bin/wsadmin.sh -user $username -password $password -c "$command"
	echo "|--- dynamic theme started"
}
bindTheme(){
	cd $dirTemp
	echo "|--- binding of theme started"
	echo "	|--- generating necessary files"
	$portalPath/bin/xmlaccess.sh -user $username -password $password -url $protocol://$host:$port/wps/config -in input.xml -out output.xml &> /dev/null
	local fileData=$(cat output.xml)
	local str1=${fileData%%"$themeName"*}
	local str2=${fileData##*"$themeName"}
	str1=$(echo "$str1" | tr "\n" "\f" | sed "s/\(.*\)\/wps\/defaultTheme85/\1\/$themeId\" uniquename=\"$themeId/" | tr "\f" "\n")
	writeToFile output.xml "$str1""$themeName""$str2"
	echo "	|--- varifying theme binding"
	$portalPath/bin/xmlaccess.sh -user $username -password $password -url $protocol://$host:$port/wps/config -in output.xml -out output2.xml &> /dev/null
	echo "	|--- theme binding completed"
	
	cd "$scriptDir"
}
restartPortal(){
	echo "|--- restarting portal"
	sudo $default_profilePath/bin/stopServer.sh $server -username $username -password $password &> /dev/null
	echo "	|--- portal stopped"
	sudo $default_profilePath/bin/startServer.sh $server &> /dev/null
	echo "	|--- portal started"
}
########################################
# script
########################################
dirTemp="tmp"
tmpScriptDir=${0}
tmpScriptDir=${tmpScriptDir//${0##*/}/}
cd "$tmpScriptDir"
scriptDir=$(pwd)
echo "*******************************************************************************"
getInputs
echo "*******************************************************************************"
mkdir -p $dirTemp
tar xf ${0##*/}.bin -C $dirTemp
generateStaticTheme
generateDynamicTheme
deployStaticTheme
deployDynamicTheme
bindTheme
restartPortal
rm -rf $dirTemp
echo "*********************    theme deployed successfully     *********************"
