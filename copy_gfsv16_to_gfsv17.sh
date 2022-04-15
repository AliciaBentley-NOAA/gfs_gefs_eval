#!/bin/bash

export CASE='SNODissue'
export DATA_PATH='/lfs/h2/emc/stmp/Alicia.Bentley/gfsv17_eval/'${CASE}
export CYCLE='2022020112'

#---------------------------------------------------------------------

cd ${DATA_PATH}/gfs/${CYCLE}
echo ${DATA_PATH}/gfs/${CYCLE}

export YYYY=`echo $CYCLE | cut -c 1-4`
export YYYYMM=`echo $CYCLE | cut -c 1-6`
export YYYYMMDD=`echo $CYCLE | cut -c 1-8`
export HH=`echo $CYCLE | cut -c 9-10`

file="${DATA_PATH}/${CASE}_fhrs.txt"

while IFS= read -r line ; do
#	echo "Reading the next line of "${file}
	export FHHH=`echo $line`
	echo "Copying gfsv16 to gfsv17 for F"${FHHH}
	cp gfsv16.${YYYYMMDD}.t${HH}z.pgrb2.0p25.f${FHHH}.grb2 gfsv17.${YYYYMMDD}.t${HH}z.pgrb2.0p25.f${FHHH}.grb2

done < ${file}

exit
