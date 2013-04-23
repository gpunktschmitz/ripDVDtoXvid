#!/bin/bash
#purpose: rip dvd to a target folder and send an email when done
#version: 1.5
#creation date: 2012-08-01 19:43:51
#author(s): Guenther Schmitz <gpunktscripts@outlook.com>
#license: CC0 1.0 Universal <http://creativecommons.org/publicdomain/zero/1.0/>

TARGET=/tmp/               #folder to rip dvd to
EMAIL=FALSE                #if is set to "FALSE": no mail is send
LANG=de                    #set to your preferred language to rip .. e.g. "en" for english .. seems it needs to be lowercase to work properly
MINFILESIZE=800            #minimum filesize (in MB) which qualifies to be the main film
LOGDIR=/tmp/               #output directory for log file

#changelog
# version 1.5
# +added '-forcedsubsonly' to add forced subtitles in the specified language
#--
# version 1.4
# +added and initialisied param "DVDMOUNTPOINT" and renamed "DVDDEV" to "DVDDEVICE"
# +eject param changed from the DVD mount point to the DVD device
#--
# version 1.3
# +fixed param "VOLUMENAME" which would not be correctly determined if drive was not "/dev/cdrom"
# +changed default drive to be "/dev/dvd" instead of "/dev/cdrom"
#--
# version 1.2
# +working (and logging) now with filesize in MB
# +added parameter awareness: passed parameter (DVD drive e.g. "/media/VolumeName") is checked whether folder "VIDEO_TS" exists ...
# --

EXTENSION=.avi
LOGFILE=$LOGDIR/ripDVDtoXvid.log
DVDDEVICE=
DVDMOUNTPOINT=
DVDMOUNTPOINTPARAMVALID=TRUE

logText () {
    date >> $LOGFILE
    echo -e "$1" >> $LOGFILE
    echo -e "" >> $LOGFILE
    echo -e "" >> $LOGFILE
}

if [ "$1" != "" ]; then
    DVDMOUNTPOINT=$1
    if [[ $DVDMOUNTPOINT == */ ]]; then
        DVDMOUNTPOINT=${DVDMOUNTPOINT%/}
    fi
    if [ -d "$DVDMOUNTPOINT/VIDEO_TS" ]; then
        DVDDEVICE=$( mount | grep $DVDMOUNTPOINT | awk '{ split( $0, arr, " "); print arr[1] }' )
        DVDMOUNTPOINT="-dvd-device $DVDMOUNTPOINT"
    else
        DVDMOUNTPOINTPARAMVALID=FALSE
    fi
else
    DVDDEVICE="/dev/dvd"
fi

echo -e "" > $LOGFILE

VOLUMENAME=$( volname $DVDDEVICE | tr -d ' ' )
OUTPUTNAME=$VOLUMENAME
COUNTER=1
FILESIZE=0
FILENAME=$TARGET$OUTPUTNAME$EXTENSION
#debug output
#logText "target: $TARGET"
#logText "outputname: $OUTPUTNAME"
#logText "extension: $EXTENSION"
#logText "filename: $FILENAME"

if [ $DVDMOUNTPOINTPARAMVALID ]; then
    logText "RIPPING $VOLUMENAME TO $FILENAME"

    while [ $FILESIZE -lt $MINFILESIZE ] && [ $COUNTER -lt 99 ]; do
        #http://savvyadmin.com/dvd-to-xvid-encoding-with-mencoder/
        mencoder dvd://$COUNTER -slang $LANG -forcedsubsonly -alang $LANG $DVDMOUNTPOINT -oac mp3lame -lameopts q=0:aq=0 -ovc xvid -xvidencopts fixed_quant=3:autoaspect:max_key_interval=25:vhq=2:bvhq=1:trellis:hq_ac:chroma_me:chroma_opt:quant_type=mpeg -o $FILENAME
        if [ -f $FILENAME ]; then
            FILESIZE=$( stat -c%s "$FILENAME" )
            FILESIZE=$(( $FILESIZE / 1024 / 1024 ))
        else
            FILESIZE=0
        fi

        logText "COUNTER $COUNTER :: FILESIZE $FILESIZE MB"

        let COUNTER=$COUNTER+1
    done

    eject $DVDDEVICE

    if [ $FILESIZE -gt $MINFILESIZE ]; then
        #if [ $TARGET ]; then
            #logText "DONE RIPPING .. TRYING MOVING IT TO $TARGET"
            #TODO CHECK IF FILE EXISTS ON TARGET
            #mv $FILENAME $TARGET >> $LOGFILE
            #TODO CHECK IF COPY OK
        #fi

        logText "PROCESS FINISHED ..."

        if [ $EMAIL ]; then
            logText "mail 1"
            mail -s "ripDVDtoXvid finished $VOLUMENAME" $EMAIL < $LOGFILE
        fi
    elif [ $COUNTER -eq 50 ]; then
        logText "COUNTER LIMIT HIT ..."

        if [ $EMAIL ]; then
            logText "mail 2"
            mail -s "ripDVDtoXvid failed as the counter limit was hit ..." $EMAIL < $LOGFILE
        fi
    fi
else
    logText "WRONG DVD PARAMETER SET \"$DVDMOUNTPOINT\" ..."
    if [ $EMAIL ]; then
        logText "mail 3"
        mail -s "ripDVDtoXvid failed as the parameter provided was wrong ..." $EMAIL < $LOGFILE
    fi
fi

#TODO CHECK FREE DISK SPACE

