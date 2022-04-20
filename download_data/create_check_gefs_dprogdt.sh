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

mkdir -p ${DATA_PATH}/output
mkdir -p ${DATA_PATH}/check_data/scripts

if [[ -s ${DATA_PATH}/check_data/results_check_gefs_dprogdt.out ]] ; then
	/bin/rm -rf ${DATA_PATH}/check_data/results_check_gefs_dprogdt.out
fi

file="${DATA_PATH}/${CASE}_init_dates.txt"

export INIT_FHR_temp='`echo $line`'
export INIT_FHR_same='${INIT_FHR}'
export INIT_temp='`echo ${INIT_FHR} | cut -c 1-10`'
export INIT_same='${INIT}'
export YYYYMMDD_temp='`echo ${INIT_FHR} | cut -c 1-8`'
export YYYYMMDD_same='${YYYYMMDD}'
export HH_temp='`echo ${INIT_FHR} | cut -c 9-10`'
export HH_same='${HH}'
export FHHH_temp='`echo ${INIT_FHR} | cut -c 11-13`'
export FHHH_same='${FHHH}'
export mem_same='${mem}'

#-----------------------------------------------------------------------------------------
# Creating a job to check for downloaded analyses on a particular valid date (VALID)
#-----------------------------------------------------------------------------------------

cat > ${DATA_PATH}/check_data/scripts/check_gefs_dprogdt.sh <<EOF
#!/bin/bash
#PBS -N check_dprogdt
#PBS -o ${DATA_PATH}/check_data/results_check_gefs_dprogdt.out
#PBS -e ${OUTPUT_PATH}/out_check_gefs_dprogdt.err
#PBS -l select=1:ncpus=1:mem=1GB
#PBS -q dev
#PBS -l walltime=00:05:00
#PBS -A VERF-DEV

cd ${DATA_PATH}/dprogdt/

echo "*****************************************************************************"
echo "********Checking for files. If blank until end, all files are present!*******"
echo "*****************************************************************************"
file="${DATA_PATH}/${CASE}_init_dates.txt"
while IFS= read -r line ; do
	#echo "Reading the next line of "${file}
	export INIT_FHR=${INIT_FHR_temp}
	echo $INIT_FHR
	export INIT=${INIT_temp}
	export YYYYMMDD=${YYYYMMDD_temp}
	export HH=${HH_temp}
	export FHHH=${FHHH_temp}

for mem in c00 p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20 p21 p22 p23 p24 p25 p26 p27 p28 p29 p30 ; do

	if [[ ! -s ${DATA_PATH}/dprogdt/${INIT_same}/ge${mem_same}.v12.${YYYYMMDD_same}.t${HH_same}z.pgrb2a.0p50.f${FHHH_same}.grb2 ]] ; then
		echo "MISSING ${DATA_PATH}/dprogdt/${INIT_same}/ge${mem_same}.v12.${YYYYMMDD_same}.t${HH_same}z.pgrb2a.0p50.f${FHHH_same}.grb2"
	fi
	if [[ ! -s ${DATA_PATH}/dprogdt/${INIT_same}/ge${mem_same}.v12.${YYYYMMDD_same}.t${HH_same}z.pgrb2b.0p50.f${FHHH_same}.grb2 ]] ; then
		echo "MISSING ${DATA_PATH}/dprogdt/${INIT_same}/ge${mem_same}.v12.${YYYYMMDD_same}.t${HH_same}z.pgrb2b.0p50.f${FHHH_same}.grb2"
	fi
        if [[ ! -s ${DATA_PATH}/dprogdt/${INIT_same}/ge${mem_same}.v13.${YYYYMMDD_same}.t${HH_same}z.pgrb2a.0p50.f${FHHH_same}.grb2 ]] ; then
		echo "MISSING ${DATA_PATH}/dprogdt/${INIT_same}/ge${mem_same}.v13.${YYYYMMDD_same}.t${HH_same}z.pgrb2a.0p50.f${FHHH_same}.grb2"
	fi
	if [[ ! -s ${DATA_PATH}/dprogdt/${INIT_same}/ge${mem_same}.v13.${YYYYMMDD_same}.t${HH_same}z.pgrb2b.0p50.f${FHHH_same}.grb2 ]] ; then
		echo "MISSING ${DATA_PATH}/dprogdt/${INIT_same}/ge${mem_same}.v13.${YYYYMMDD_same}.t${HH_same}z.pgrb2b.0p50.f${FHHH_same}.grb2"
	fi

done

done < ${file}

echo "*****************************************************************************"
echo "**********************Finished checking for files!***************************"
echo "*****************************************************************************"


exit

EOF

#-----------------------------------------------------------------------

qsub ${DATA_PATH}/check_data/scripts/check_gefs_dprogdt.sh
sleep 3

exit

