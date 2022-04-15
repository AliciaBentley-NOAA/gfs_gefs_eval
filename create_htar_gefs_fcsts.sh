#!/bin/bash
##############################################
# Script for submitting jobs on WCOSS2
# that download data from HPSS
##############################################

echo data path: ${DATA_PATH}/gefs/${CYCLE}
echo output path: ${OUTPUT_PATH}
echo fhr_inc: ${FHR_INC}
echo fhr_start: ${FHR_START}
echo fhr_end: ${FHR_END}

mkdir -p ${OUTPUT_PATH}
mkdir -p ${DATA_PATH}/gefs/${CYCLE}/untar_ops
mkdir -p ${DATA_PATH}/gefs/${CYCLE}/untar_retro

export YYYY=`echo $CYCLE | cut -c 1-4`
export YYYYMM=`echo $CYCLE | cut -c 1-6`
export YYYYMMDD=`echo $CYCLE | cut -c 1-8`
export HH=`echo $CYCLE | cut -c 9-10`

export FHHH_temp='`echo $line`'
export FHHH_same='${FHHH}'

file="${DATA_PATH}/${CASE}_fhrs.txt"

#################################################################################################
#----------------------- Info. to download ops GEFS forecasts ------------------------------------
export GEFS_CHANGE_DATE2=2020092312
export GEFS_CHANGE_DATE1=2019082000


if ((${CYCLE} >= ${GEFS_CHANGE_DATE2})) ; then
	GEFS_ARCHIVE=/NCEPPROD/5year/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/com_gefs_prod_gefs.${YYYYMMDD}_${HH}.atmos_pgrb2sp25.tar
        GEFS_AVG_FILENAME=./atmos/pgrb2sp25/geavg.t${HH}z.pgrb2s.0p25.f${FHHH_same}
	GEFS_SPR_FILENAME=./atmos/pgrb2sp25/gespr.t${HH}z.pgrb2s.0p25.f${FHHH_same}

elif (((${CYCLE} >= ${GEFS_CHANGE_DATE1}) && (${CYCLE} < ${GEFS_CHANGE_DATE2}))) ; then
	GEFS_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/gpfs_dell2_nco_ops_com_gens_prod_gefs.${YYYYMMDD}_${HH}.pgrb2a.tar
        GEFS_AVG_FILENAME=./pgrb2a/geavg.t${HH}z.pgrb2af${FHHH_same}
	GEFS_SPR_FILENAME=./pgrb2a/geavg.t${HH}z.pgrb2af${FHHH_same}

elif ((${CYCLE} < ${GEFS_CHANGE_DATE1})) ; then
	GEFS_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/com2_gens_prod_gefs.${YYYYMMDD}_${HH}.pgrb2a.tar
        GEFS_AVG_FILENAME=./pgrb2a/geavg.t${HH}z.pgrb2af${FHHH_same}
	GEFS_SPR_FILENAME=./pgrb2a/geavg.t${HH}z.pgrb2af${FHHH_same}
fi


#-----------------------------------------------------------------------------------------
# Creating a job to download data on a particular ops GEFS forecast cycle (CYCLE)
#-----------------------------------------------------------------------------------------

cat > ${DATA_PATH}/gefs/${CYCLE}/untar_ops/htar_gefs_opsfcst.sh <<EOF
#!/bin/bash
#PBS -N gefsops_htar
#PBS -o ${OUTPUT_PATH}/out_htar_gefs_opsfcst_${CYCLE}.out
#PBS -e ${OUTPUT_PATH}/out_htar_gefs_opsfcst_${CYCLE}.err
#PBS -l select=1:ncpus=1:mem=4GB
#PBS -q dev_transfer
#PBS -l walltime=01:30:00
#PBS -A VERF-DEV

cd ${DATA_PATH}/gefs/${CYCLE}/untar_ops

#/bin/rm -rf ${DATA_PATH}/htar_gefs_opsfcst_${CYCLE}_done

file="${DATA_PATH}/${CASE}_fhrs.txt"

while IFS= read -r line ; do
	#echo "Reading the next line of "${file}
	export FHHH=${FHHH_temp}

#        /bin/rm -rf ${DATA_PATH}/gefs/${CYCLE}/geavgv12.${YYYYMMDD}.t${HH}z.pgrb2s.0p25.f${FHHH_same}.grb2
#        /bin/rm -rf ${DATA_PATH}/gefs/${CYCLE}/gesprv12.${YYYYMMDD}.t${HH}z.pgrb2s.0p25.f${FHHH_same}.grb2

        if [[ -s ${DATA_PATH}/gefs/${CYCLE}/geavgv12.${YYYYMMDD}.t${HH}z.pgrb2s.0p25.f${FHHH_same}.grb2 ]] ; then
		echo ${CYCLE} "F"${FHHH_same}" ops GEFS mean forecast files exists"
	else
		echo "Extracting "${CYCLE}" ops GEFS mean forecast file "${FHHH_same}
		htar -xvf $GEFS_ARCHIVE $GEFS_AVG_FILENAME
        	sleep 3
	        mv $GEFS_AVG_FILENAME ${DATA_PATH}/gefs/${CYCLE}/geavgv12.${YYYYMMDD}.t${HH}z.pgrb2s.0p25.f${FHHH_same}.grb2
	fi

        if [[ -s ${DATA_PATH}/gefs/${CYCLE}/gesprv12.${YYYYMMDD}.t${HH}z.pgrb2s.0p25.f${FHHH_same}.grb2 ]] ; then
		echo ${CYCLE} "F"${FHHH_same}" ops GEFS spread forecast files exists"
	else
		echo "Extracting "${CYCLE}" ops GEFS spread forecast file "${FHHH_same}
		htar -xvf $GEFS_ARCHIVE $GEFS_SPR_FILENAME
		sleep 3
		mv $GEFS_SPR_FILENAME ${DATA_PATH}/gefs/${CYCLE}/gesprv12.${YYYYMMDD}.t${HH}z.pgrb2s.0p25.f${FHHH_same}.grb2
	fi

done < ${file}
	
#touch ${DATA_PATH}/htar_gefs_opsfcst_${CYCLE}_done

exit

EOF

#----------------------------------------------------------------------------------------

qsub ${DATA_PATH}/gefs/${CYCLE}/untar_ops/htar_gefs_opsfcst.sh
sleep 3

#----------------------------------------------------------------------------------------


#########################################################################################
#----------------------- Info. to download retro GEFS forecasts --------------------------
export GEFS_CHANGE_DATE2=2020092312
export GEFS_CHANGE_DATE1=2019082000


if ((${CYCLE} >= ${GEFS_CHANGE_DATE2})) ; then
	GEFS_ARCHIVE=/NCEPPROD/5year/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/com_gefs_prod_gefs.${YYYYMMDD}_${HH}.atmos_pgrb2sp25.tar
	GEFS_AVG_FILENAME=./atmos/pgrb2sp25/geavg.t${HH}z.pgrb2s.0p25.f${FHHH_same}
	GEFS_SPR_FILENAME=./atmos/pgrb2sp25/gespr.t${HH}z.pgrb2s.0p25.f${FHHH_same}

elif (((${CYCLE} >= ${GEFS_CHANGE_DATE1}) && (${CYCLE} < ${GEFS_CHANGE_DATE2}))) ; then
	GEFS_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/gpfs_dell2_nco_ops_com_gens_prod_gefs.${YYYYMMDD}_${HH}.pgrb2a.tar
	GEFS_AVG_FILENAME=./pgrb2a/geavg.t${HH}z.pgrb2af${FHHH_same}
	GEFS_SPR_FILENAME=./pgrb2a/geavg.t${HH}z.pgrb2af${FHHH_same}

elif ((${CYCLE} < ${GEFS_CHANGE_DATE1})) ; then
	GEFS_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/com2_gens_prod_gefs.${YYYYMMDD}_${HH}.pgrb2a.tar
	GEFS_AVG_FILENAME=./pgrb2a/geavg.t${HH}z.pgrb2af${FHHH_same}
	GEFS_SPR_FILENAME=./pgrb2a/geavg.t${HH}z.pgrb2af${FHHH_same}
fi


#-----------------------------------------------------------------------------------------
# Creating a job to download data on a particular GEFS retro cycle (CYCLE)
#-----------------------------------------------------------------------------------------

cat > ${DATA_PATH}/gefs/${CYCLE}/untar_retro/htar_gefs_retrofcst.sh <<EOF
#!/bin/bash
#PBS -N gefsretro_htar
#PBS -o ${OUTPUT_PATH}/out_htar_gefs_retrofcst_${CYCLE}.out
#PBS -e ${OUTPUT_PATH}/out_htar_gefs_retrofcst_${CYCLE}.err
#PBS -l select=1:ncpus=1:mem=4GB
#PBS -q dev_transfer
#PBS -l walltime=01:30:00
#PBS -A VERF-DEV

cd ${DATA_PATH}/gefs/${CYCLE}/untar_retro

#/bin/rm -rf ${DATA_PATH}/htar_gefs_retrofcst_${CYCLE}_done

file="${DATA_PATH}/${CASE}_fhrs.txt"

while IFS= read -r line ; do
	echo "Reading the next line of "${file}
	export FHHH=${FHHH_temp}

#	/bin/rm -rf ${DATA_PATH}/gefs/${CYCLE}/geavgv13.${YYYYMMDD}.t${HH}z.pgrb2s.0p25.f${FHHH_same}.grb2
#	/bin/rm -rf ${DATA_PATH}/gefs/${CYCLE}/gesprv13.${YYYYMMDD}.t${HH}z.pgrb2s.0p25.f${FHHH_same}.grb2

	if [[ -s ${DATA_PATH}/gefs/${CYCLE}/geavgv13.${YYYYMMDD}.t${HH}z.pgrb2s.0p25.f${FHHH_same}.grb2 ]] ; then
		echo ${CYCLE} "F"${FHHH_same}" ops GEFS mean forecast files exists"
	else
		echo "Extracting "${CYCLE}" ops GEFS mean forecast file "${FHHH_same}
		htar -xvf $GEFS_ARCHIVE $GEFS_AVG_FILENAME
		sleep 3
		mv $GEFS_AVG_FILENAME ${DATA_PATH}/gefs/${CYCLE}/geavgv13.${YYYYMMDD}.t${HH}z.pgrb2s.0p25.f${FHHH_same}.grb2
	fi

	if [[ -s ${DATA_PATH}/gefs/${CYCLE}/gesprv13.${YYYYMMDD}.t${HH}z.pgrb2s.0p25.f${FHHH_same}.grb2 ]] ; then
		echo ${CYCLE} "F"${FHHH_same}" ops GEFS spread forecast files exists"
	else
		echo "Extracting "${CYCLE}" ops GEFS spread forecast file "${FHHH_same}
		htar -xvf $GEFS_ARCHIVE $GEFS_SPR_FILENAME
		sleep 3
		mv $GEFS_SPR_FILENAME ${DATA_PATH}/gefs/${CYCLE}/gesprv13.${YYYYMMDD}.t${HH}z.pgrb2s.0p25.f${FHHH_same}.grb2
	fi

done < ${file}

#touch ${DATA_PATH}/htar_gefs_retrofcst_${CYCLE}_done

exit

EOF

#----------------------------------------------------------------------------------------

qsub ${DATA_PATH}/gefs/${CYCLE}/untar_retro/htar_gefs_retrofcst.sh
sleep 3

#----------------------------------------------------------------------------------------

exit

