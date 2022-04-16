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
mkdir -p ${DATA_PATH}/analyses/untar_rap

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

if (($((${VHH})) <= 5)) ; then
	export tar_suffix="00-05.awip32"
elif ((($((${VHH})) >= 6) && ($((${VHH})) <= 11))) ; then
	export tar_suffix="06-11.awip32"
elif ((($((${VHH})) >= 12) && ($((${VHH})) <= 17))) ; then
	export tar_suffix="12-17.awip32"
elif ((($((${VHH})) >= 18) && ($((${VHH})) <= 23))) ; then
	export tar_suffix="18-23.awip32"
fi
#echo ${tar_suffix}


export RAP_CHANGE_DATE2=2020022618
export RAP_CHANGE_DATE1=2018071118

if ((${VALID} >= ${RAP_CHANGE_DATE2})) ; then
	RAP_ARCHIVE=/NCEPPROD/hpssprod/runhistory/2year/rh${VYYYY}/${VYYYYMM}/${VYYYYMMDD}/com_rap_prod_rap.${VYYYYMMDD}${tar_suffix}.tar
        RAP_FILENAME=./rap.t${VHH}z.awip32f00.grib2

elif (((${VALID} >= ${RAP_CHANGE_DATE1}) && (${VALID} <= ${RAP_CHANGE_DATE2}))) ; then
        RAP_ARCHIVE=/NCEPPROD/hpssprod/runhistory/2year/rh${VYYYY}/${VYYYYMM}/${VYYYYMMDD}/gpfs_hps_nco_ops_com_rap_prod_rap.${VYYYYMMDD}${tar_suffix}.tar
	RAP_FILENAME=./rap.t${VHH}z.awip32f00.grib2

elif ((${VALID} <= ${RAP_CHANGE_DATE1})) ; then
        RAP_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${VYYYY}/${VYYYYMM}/${VYYYYMMDD}/com2_rap_prod_rap.${VYYYYMMDD}${tar_suffix}.tar
	RAP_FILENAME=./rap.t${VHH}z.awip32f00.grib2

fi

#echo ${RAP_ARCHIVE}
#echo ${RAP_FILENAME}

#-----------------------------------------------------------------------------------------
# Creating a job to download data on a particular valid date (VALID)
#-----------------------------------------------------------------------------------------

cat > ${DATA_PATH}/analyses/untar_rap/htar_rap_anl_${VALID}.sh <<EOF
#!/bin/bash
#PBS -N rap_htar
#PBS -o ${OUTPUT_PATH}/out_htar_rap_anl_${VALID}.out
#PBS -e ${OUTPUT_PATH}/out_htar_rap_anl_${VALID}.err
#PBS -l select=1:ncpus=1:mem=4GB
#PBS -q dev_transfer
#PBS -l walltime=02:00:00
#PBS -A VERF-DEV

cd ${DATA_PATH}/analyses/untar_rap

#/bin/rm -rf ${DATA_PATH}/htar_rap_anl_${VALID}_done
#/bin/rm -rf ${DATA_PATH}/analyses/rap.${VYYYYMMDD}.t${VHH}z.awip32f00.grb2

if [[ -s ${DATA_PATH}/analyses/rap.${VYYYYMMDD}.t${VHH}z.awip32f00.grb2 ]] ; then
	echo ${VALID}" RAP analysis exists"
else
	echo "Extracting "${VALID}" RAP analysis"
	htar -xvf $RAP_ARCHIVE $RAP_FILENAME
	sleep 3
	mv $RAP_FILENAME ${DATA_PATH}/analyses/rap.${VYYYYMMDD}.t${VHH}z.awip32f00.grb2
fi

#touch ${DATA_PATH}/htar_rap_anl_${VALID}_done

exit

EOF

#-----------------------------------------------------------------------

qsub ${DATA_PATH}/analyses/untar_rap/htar_rap_anl_${VALID}.sh
sleep 3

done < ${file}

exit

