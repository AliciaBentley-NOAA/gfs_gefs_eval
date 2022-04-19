#!/bin/bash
##############################################
# Script for submitting jobs on WCOSS2
# that check for download data from HPSS
##############################################

echo data path: ${DATA_PATH}/analyses
echo output path: ${DATA_PATH}/check_data
#echo fhr_inc: ${FHR_INC}
#echo fhr_start: ${FHR_START}
#echo fhr_end: ${FHR_END}

mkdir -p ${DATA_PATH}/check_data/scripts

export YYYY=`echo $CYCLE | cut -c 1-4`
export YYYYMM=`echo $CYCLE | cut -c 1-6`
export YYYYMMDD=`echo $CYCLE | cut -c 1-8`
export HH=`echo $CYCLE | cut -c 9-10`

export VALID_temp='`echo $line`'
export VALID_same='${VALID}'
export VYYYYMMDD_temp='`echo $VALID | cut -c 1-8`'
export VYYYYMMDD_same='${VYYYYMMDD}'
export VHH_temp='`echo $VALID | cut -c 9-10`'
export VHH_same='${VHH}'

file="${DATA_PATH}/${CASE}_valid_dates.txt"

if [[ -s ${DATA_PATH}/check_data/results_check_analyses.out ]] ; then
	/bin/rm -rf ${DATA_PATH}/check_data/results_check_analyses.out
fi

#-----------------------------------------------------------------------------------------
# Creating a job to check for downloaded analyses on a particular valid date (VALID)
#-----------------------------------------------------------------------------------------

cat > ${DATA_PATH}/check_data/scripts/check_analyses.sh <<EOF
#!/bin/bash
#PBS -N check_anl
#PBS -o ${DATA_PATH}/check_data/results_check_analyses.out
#PBS -e ${OUTPUT_PATH}/out_check_analyses.err
#PBS -l select=1:ncpus=1:mem=4GB
#PBS -q dev
#PBS -l walltime=02:00:00
#PBS -A VERF-DEV

cd ${DATA_PATH}/analyses

echo "*****************************************************************************"
echo "********Checking for files. If blank until end, all files are present!*******"
echo "*****************************************************************************"
file="${DATA_PATH}/${CASE}_valid_dates.txt"
while IFS= read -r line ; do
	#echo "Reading the next line of "${file}
        export VALID=${VALID_temp}
        export VYYYYMMDD=${VYYYYMMDD_temp}
	export VHH=${VHH_temp}
	echo $VALID $VYYYYMMDD $VHH

if [[ ! -s ${DATA_PATH}/analyses/gfs.${VYYYYMMDD_same}.t${VHH_same}z.pgrb2.0p25.f000.grb2 ]] ; then
	echo "Missing ${DATA_PATH}/analyses/gfs.${VYYYYMMDD_same}.t${VHH_same}z.pgrb2.0p25.f000.grb2"
fi
if [[ ! -s ${DATA_PATH}/analyses/rap.${VYYYYMMDD_same}.t${VHH_same}z.awip32f00.grb2 ]] ; then
	echo "Missing ${DATA_PATH}/analyses/rap.${VYYYYMMDD_same}.t${VHH_same}z.awip32f00.grb2"
fi	
if [[ ! -s ${DATA_PATH}/analyses/st4_conus.${VALID_same}.06h.grb2 ]] ; then
	echo "Missing ${DATA_PATH}/analyses/st4_conus.${VALID_same}.06h.grb2"
fi
if [[ ! -s ${DATA_PATH}/analyses/nohrsc_conus.${VALID_same}.06h.grb2 ]] ; then
	echo "Missing ${DATA_PATH}/analyses/nohrsc_conus.${VALID_same}.06h.grb2"
fi

done < ${file}

echo "***********************************************************"
echo "*************Finished checking for files!******************"
echo "***********************************************************"

exit

EOF

#-----------------------------------------------------------------------

qsub ${DATA_PATH}/check_data/scripts/check_analyses.sh
sleep 3

exit

