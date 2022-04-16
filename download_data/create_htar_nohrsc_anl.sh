#!/bin/bash
##############################################
# Script for submitting jobs on WCOSS2
# that download data from HPSS
##############################################

echo data path: ${DATA_PATH}/analyses
echo output path: ${OUTPUT_PATH}
#echo fhr_inc: ${FHR_INC}
#echo fhr_start: ${FHR_START}
#echo fhr_end: ${FHR_END}

mkdir -p ${OUTPUT_PATH}
mkdir -p ${DATA_PATH}/analyses/untar_nohrsc

export YYYY=`echo $CYCLE | cut -c 1-4`
export YYYYMM=`echo $CYCLE | cut -c 1-6`
export YYYYMMDD=`echo $CYCLE | cut -c 1-8`
export HH=`echo $CYCLE | cut -c 9-10`

file="${DATA_PATH}/${CASE}_valid_dates.txt"

while IFS= read -r line ; do
        #echo "Reading the next line of "${file}
	export VALID="`echo $line`"
        echo $VALID
	export VYYYY=`echo ${VALID} | cut -c 1-4`
	export VYYYYMM=`echo ${VALID} | cut -c 1-6`
	export VYYYYMMDD=`echo ${VALID} | cut -c 1-8`
	export VHH=`echo ${VALID} | cut -c 9-10`

#export NOHRSC_CHANGE_DATE1=2017042700

NOHRSC_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${VYYYY}/${VYYYYMM}/${VYYYYMMDD}/dcom_prod_${VYYYYMMDD}.tar


#-----------------------------------------------------------------------------------------
# Creating a job to download data on a particular valid date (VALID)
#-----------------------------------------------------------------------------------------

cat > ${DATA_PATH}/analyses/untar_nohrsc/htar_nohrsc_anl_${VALID}.sh <<EOF
#!/bin/bash
#PBS -N nohrsc_htar
#PBS -o ${OUTPUT_PATH}/out_htar_nohrsc_anl_${VALID}.out
#PBS -e ${OUTPUT_PATH}/out_htar_nohrsc_anl_${VALID}.err
#PBS -l select=1:ncpus=1:mem=4GB
#PBS -q dev_transfer
#PBS -l walltime=00:15:00
#PBS -A VERF-DEV

cd ${DATA_PATH}/analyses/untar_nohrsc

#/bin/rm -rf ${DATA_PATH}/htar_nohrsc_anl_${VALID}_done
#/bin/rm -rf ${DATA_PATH}/analyses/nohrsc_conus.${VALID}.06h.grb2

if [[ -s ${DATA_PATH}/analyses/nohrsc_conus.${VALID}.06h.grb2 ]] ; then
	echo ${VALID}" NOHRSC analysis exists"
else
	echo "Using wget to download NOHRSC data from noaa.gov"
	wget --tries=2 http://www.nohrsc.noaa.gov/snowfall_v2/data/${VYYYYMM}/sfav2_CONUS_6h_${VALID}_grid184.grb2
        sleep 3
	mv sfav2_CONUS_6h_${VALID}_grid184.grb2 ${DATA_PATH}/analyses/nohrsc_conus.${VALID}.06h.grb2

#	echo "Extracting "${VALID}" NOHRSC analysis"
#	htar -xvf $NOHRSC_ARCHIVE ./wgrbbul/nohrsc_snowfall/sfav2_CONUS_6h_${VALID}_grid184.grb2
#       sleep 3
#       mv ./wgrbbul/nohrsc_snowfall/sfav2_CONUS_6h_${VALID}_grid184.grb2 ${DATA_PATH}/analyses/nohrsc_conus.${VALID}.06h.grb2
fi

#touch ${DATA_PATH}/htar_nohrsc_anl_${VALID}_done

exit

EOF

#-----------------------------------------------------------------------

qsub ${DATA_PATH}/analyses/untar_nohrsc/htar_nohrsc_anl_${VALID}.sh
sleep 3

done < ${file}

exit

