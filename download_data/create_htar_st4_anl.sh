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
mkdir -p ${DATA_PATH}/analyses/untar_st4

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

export ST4_CHANGE_DATE4=2020071900
export ST4_CHANGE_DATE3=2020021900
export ST4_CHANGE_DATE2=2019081300
export ST4_CHANGE_DATE1=2017042700

if ((${VALID} >= ${ST4_CHANGE_DATE4})) ; then
	ST4_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${VYYYY}/${VYYYYMM}/${VYYYYMMDD}/com_pcpanl_prod_pcpanl.${VYYYYMMDD}.tar
	ST4_FILENAME=./st4_conus.${VALID}.06h.grb2

elif (((${VALID} >= ${ST4_CHANGE_DATE3}) && (${VALID} <= ${ST4_CHANGE_DATE4}))) ; then
	ST4_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${VYYYY}/${VYYYYMM}/${VYYYYMMDD}/com_pcpanl_prod_pcpanl.${VYYYYMMDD}.tar
        ST4_FILENAME=./ST4.${VALID}.06h.gz

elif (((${VALID} >= ${ST4_CHANGE_DATE2}) && (${VALID} <= ${ST4_CHANGE_DATE3}))) ; then
	ST4_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${VYYYY}/${VYYYYMM}/${VYYYYMMDD}/gpfs_dell2_nco_ops_com_pcpanl_prod_pcpanl.${VYYYYMMDD}.tar
        ST4_FILENAME=./ST4.${VALID}.06h.gz

elif (((${VALID} >= ${ST4_CHANGE_DATE1}) && (${VALID} <= ${ST4_CHANGE_DATE2}))) ; then
	ST4_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${VYYYY}/${VYYYYMM}/${VYYYYMMDD}/com2_pcpanl_prod_pcpanl.${VYYYYMMDD}.tar
        ST4_FILENAME=./ST4.${VALID}.06h.gz

elif ((${VALID} <= ${ST4_CHANGE_DATE1})) ; then
	ST4_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${VYYYY}/${VYYYYMM}/${VYYYYMMDD}/com_hourly_prod_nam_pcpn_anal.${VYYYYMMDD}.tar
        ST4_FILENAME=./ST4.${VALID}.06h.gz
fi

#-----------------------------------------------------------------------------------------
# Creating a job to download data on a particular valid date (VALID)
#-----------------------------------------------------------------------------------------

cat > ${DATA_PATH}/analyses/untar_st4/htar_st4_anl_${VALID}.sh <<EOF
#!/bin/bash
#PBS -N st4_htar
#PBS -o ${OUTPUT_PATH}/out_htar_st4_anl_${VALID}.out
#PBS -e ${OUTPUT_PATH}/out_htar_st4_anl_${VALID}.err
#PBS -l select=1:ncpus=1:mem=4GB
#PBS -q dev_transfer
#PBS -l walltime=02:00:00
#PBS -A VERF-DEV

cd ${DATA_PATH}/analyses/untar_st4

#/bin/rm -rf ${DATA_PATH}/htar_st4_anl_${VALID}_done
#/bin/rm -rf ${DATA_PATH}/analyses/st4_conus.${VALID}.06h.grb2

if [[ -s ${DATA_PATH}/analyses/st4_conus.${VALID}.06h.grb2 ]] ; then
	echo ${VALID}" Stage IV analysis exists"
else
	echo "Extracting "${VALID}" Stage IV analysis"
	htar -xvf $ST4_ARCHIVE $ST4_FILENAME
	if ((${VALID} < ${ST4_CHANGE_DATE4})) ; then
		gunzip ST4.${VALID}.06h.gz
	        mv ST4.${VALID}.06h st4_conus.${VALID}.06h.grb2	
	fi
	sleep 3
	mv st4_conus.${VALID}.06h.grb2 ${DATA_PATH}/analyses/st4_conus.${VALID}.06h.grb2
fi

#touch ${DATA_PATH}/htar_st4_anl_${VALID}_done

exit

EOF

#-----------------------------------------------------------------------

qsub ${DATA_PATH}/analyses/untar_st4/htar_st4_anl_${VALID}.sh
sleep 3

done < ${file}

exit

