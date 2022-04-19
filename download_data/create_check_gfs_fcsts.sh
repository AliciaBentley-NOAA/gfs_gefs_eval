#!/bin/bash
##############################################
# Script for submitting jobs on WCOSS2
# that check for download data from HPSS
##############################################

echo data path: ${DATA_PATH}/gfs/${CYCLE}
echo output path: ${DATA_PATH}/check_data
#echo fhr_inc: ${FHR_INC}
#echo fhr_start: ${FHR_START}
#echo fhr_end: ${FHR_END}

mkdir -p ${DATA_PATH}/check_data/scripts

export YYYY=`echo $CYCLE | cut -c 1-4`
export YYYYMM=`echo $CYCLE | cut -c 1-6`
export YYYYMMDD=`echo $CYCLE | cut -c 1-8`
export HH=`echo $CYCLE | cut -c 9-10`

export FHHH_temp='`echo $line`'
export FHHH_same='${FHHH}'

file="${DATA_PATH}/${CASE}_fhrs.txt"

if [[ -s ${DATA_PATH}/check_data/results_check_gfs_fcsts_${CYCLE}.out ]] ; then
	/bin/rm -rf ${DATA_PATH}/check_data/results_check_gfs_fcsts_${CYCLE}.out
fi

#-----------------------------------------------------------------------------------------
# Creating a job to check for downloaded GFS forecasts for a particular cycle (CYCLE)
#-----------------------------------------------------------------------------------------

cat > ${DATA_PATH}/check_data/scripts/check_gfs_fcsts_${CYCLE}.sh <<EOF
#!/bin/bash
#PBS -N check_gfs
#PBS -o ${DATA_PATH}/check_data/results_check_gfs_fcsts_${CYCLE}.out
#PBS -e ${OUTPUT_PATH}/out_check_gfs_fcsts_${CYCLE}.err
#PBS -l select=1:ncpus=1:mem=4GB
#PBS -q dev
#PBS -l walltime=02:00:00
#PBS -A VERF-DEV

cd ${DATA_PATH}/gfs/${CYCLE}

echo "*****************************************************************************"
echo "********Checking for files. If blank until end, all files are present!*******"
echo "*****************************************************************************"
file="${DATA_PATH}/${CASE}_fhrs.txt"
while IFS= read -r line ; do
	#echo "Reading the next line of "${file}
        export FHHH=${FHHH_temp}
	echo $FHHH

if [[ ! -s ${DATA_PATH}/gfs/${CYCLE}/gfs.v16.${YYYYMMDD}.t${HH}z.pgrb2.0p25.f${FHHH_same}.grb2 ]] ; then
	echo "Missing ${DATA_PATH}/gfs/${CYCLE}/gfs.v16.${YYYYMMDD}.t${HH}z.pgrb2.0p25.f${FHHH_same}.grb2"
fi
if [[ ! -s ${DATA_PATH}/gfs/${CYCLE}/gfs.v17.${YYYYMMDD}.t${HH}z.pgrb2.0p25.f${FHHH_same}.grb2 ]] ; then
	echo "Missing ${DATA_PATH}/gfs/${CYCLE}/gfs.v17.${YYYYMMDD}.t${HH}z.pgrb2.0p25.f${FHHH_same}.grb2"
fi

done < ${file}

echo "***********************************************************"
echo "*************Finished checking for files!******************"
echo "***********************************************************"

exit

EOF

#-----------------------------------------------------------------------

qsub ${DATA_PATH}/check_data/scripts/check_gfs_fcsts_${CYCLE}.sh
sleep 3

exit

