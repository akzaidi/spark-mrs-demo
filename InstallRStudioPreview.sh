#!/usr/bin/env bash

echo "Sample action script to install RStudio Server (community edition)..."

RSTUDIO_VERSION=0.99.1249
RSTUDIO_FILE=rstudio-server-"$RSTUDIO_VERSION"-amd64.deb

#hostname identifiers
HEADNODE=^hn0
EDGENODE=^ed0

# We only want to install on the head-node or edge node
if hostname | grep $HEADNODE'\|'$EDGENODE 2>&1 > /dev/null
then
	if [ -f /usr/bin/R ]
	then

		echo "Install system dependencies required by RStudio Server..."
		apt-get  -y -f install gdebi-core

		echo "Download and install RStudio Server..."
		wget https://s3.amazonaws.com/rstudio-dailybuilds/"$RSTUDIO_FILE"
		if [ -f "$RSTUDIO_FILE" ]
		then
			gdebi -n "$RSTUDIO_FILE"
		else
			echo "RStudio Server failed to download"
			exit 1
		fi

		echo "Update R_HOME_DIR variable..."

		RRO_LIB_DIR=$(ls -d /usr/lib64/MRO-for-MRS-*/R-*/lib/R)
		if [ -d $RRO_LIB_DIR ]
		then
			RRO_BIN_EXE="$RRO_LIB_DIR"/bin/R
			if [ -f "$RRO_BIN_EXE" ]
			then
				sed -i.bk -e "s@R_HOME_DIR=.*@R_HOME_DIR=$RRO_LIB_DIR@" $RRO_BIN_EXE
				sed -i 's/\r$//' $RRO_BIN_EXE
			else
				echo "$RRO_BIN_EXE does not exist"
				exit 1
			fi
		else
			echo "$RRO_LIB_DIR does not exist"
			exit 1
		fi

		echo "Write hadoop classpath to jar file..."
		RPROFILE_DIR=$(ls -d /usr/lib64/MRO-for-MRS-*/R-*/lib/R/etc)
		hadoop classpath --jar $RPROFILE_DIR/cp_rre.jar

		RPROFILE=$RPROFILE_DIR/Rprofile.site
		RRE_CLASSPATH='Sys.setenv(CLASSPATH=\"'$RPROFILE_DIR'/cp_rre.jar\")\n'

		if [ -f $RPROFILE ]
		then
			# Make sure the CLASSPATH is not already in Rprofile.site
			if ! grep 'aSys.setenv(CLASSPATH' $RPROFILE 2>&1 > /dev/null
			then
				echo "Add CLASSPATH in Rprofile.site for use by RStudio..."
				sed -i.bk -e "1s@^@$RRE_CLASSPATH@" $RPROFILE

				echo "Add the HADOOP variables in Rprofile.site for use by RStudio..."

				REVO_HADOOP_ENV=$(ls /usr/lib64/MRS-*/scripts/RevoHadoopEnvVars.site)
				source $REVO_HADOOP_ENV

                env | grep 'HADOOP_CMD\|LIBHDFS_OPTS\|HADOOP_HOME\|REVOHADOOPPREFIX\|REVOHADOOPSWITCHES\|HADOOP_STREAMING' | while read -r line ; do
                        line2=$(sed -e "s@\(=\)\(.*\)@\1\"\2@g" <<< $line)
                        sed -i -e "1s@^@Sys.setenv($line2\")\n@" $RPROFILE
                done

				echo "Add the SPARK variables in Rprofile.site for use by RStudio..."

				HDI_SH='Sys.setenv(SPARK_HOME=\"/usr/hdp/current/spark-client\")\n'
                sed -i -e "1s@^@$HDI_SH@" $RPROFILE

				HDI_AS='Sys.setenv(AZURE_SPARK=1)\n'
                sed -i -e "1s@^@$HDI_AS@" $RPROFILE


				sed -i 's/\r$//' $RPROFILE
			fi
		else
			echo "$RPROFILE does not exist"
			exit 1
		fi
		rstudio-server stop
		rstudio-server verify-installation
	else
		echo "R not installed"
		exit 1
	fi
else
	echo "RStudio Server can only be installed on the headnode or edgenode of an HDI cluster"
fi