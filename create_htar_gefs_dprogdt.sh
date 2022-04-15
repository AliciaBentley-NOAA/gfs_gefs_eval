#!/bin/bash
##############################################
# Script for submitting jobs on WCOSS2
# that download data from HPSS
##############################################

echo data path: ${DATA_PATH}/gefs/dprogdt
echo output path: ${OUTPUT_PATH}
echo fhr_inc: ${FHR_INC}
echo fhr_start: ${FHR_START}
echo fhr_end: ${FHR_END}

mkdir -p ${OUTPUT_PATH}

file="${DATA_PATH}/${CASE}_init_times.txt"

while IFS= read -r line ; do
	#echo "Reading the next line of "${file}
	export INIT_FHR="`echo $line`"
	echo $INIT_FHR
	export YYYY=`echo ${INIT_FHR} | cut -c 1-4`
	export YYYYMM=`echo ${INIT_FHR} | cut -c 1-6`
	export YYYYMMDD=`echo ${INIT_FHR} | cut -c 1-8`
        export INIT=`echo ${INIT_FHR} | cut -c 1-10`
	export HH=`echo ${INIT_FHR} | cut -c 9-10`
        export FHHH=`echo ${INIT_FHR} | cut -c 11-13`

mkdir -p ${DATA_PATH}/gefs/dprogdt/${INIT}/untar_ops
mkdir -p ${DATA_PATH}/gefs/dprogdt/${INIT}/untar_retro

export mem_temp='`echo $line`'
export mem_same='${mem}'

#################################################################################################
#----------------------- Info. to download ops GEFS forecasts ------------------------------------
export GEFS_CHANGE_date2=2020092312
export GEFS_CHANGE_DATE1=2019082000


if ((${INIT} >= ${GEFS_CHANGE_DATE2})) ; then
	GEFS_ARCHIVE=/NCEPPROD/5year/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/com_gefs_prod_gefs.${YYYYMMDD}_${HH}.atmos_pgrb2sp25.tar
        GEFS_FILENAME=./atmos/pgrb2sp25/ge${mem_same}.t${HH}z.pgrb2s.0p25.f${FHHH}

elif (((${INIT} >= ${GEFS_CHANGE_DATE1}) && (${INIT} < ${GEFS_CHANGE_DATE2}))) ; then
	GEFS_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/gpfs_dell2_nco_ops_com_gens_prod_gefs.${YYYYMMDD}_${HH}.pgrb2a.tar
        GEFS_FILENAME=./pgrb2a/ge${mem_same}.t${HH}z.pgrb2af${FHHH}

elif ((${INIT} < ${GEFS_CHANGE_DATE1})) ; then
	GEFS_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/com2_gens_prod_gefs.${YYYYMMDD}_${HH}.pgrb2a.tar
        GEFS_FILENAME=./pgrb2a/ge${mem_same}.t${HH}z.pgrb2af${FHHH}
fi

#-----------------------------------------------------------------------------------------
# Creating a job to download data on a particular ops GEFS forecast cycle (CYCLE)
#-----------------------------------------------------------------------------------------

cat > ${DATA_PATH}/gefs/dprogdt/${INIT}/untar_ops/htar_gefs_dprogdt_opsfcst.sh <<EOF
#!/bin/bash
#PBS -N dprogops_htar
#PBS -o ${OUTPUT_PATH}/out_htar_gefs_dprogdt_opsfcst_${INIT}.out
#PBS -e ${OUTPUT_PATH}/out_htar_gefs_dprogdt_opsfcst_${INIT}.err
#PBS -l select=1:ncpus=1:mem=4GB
#PBS -q dev_transfer
#PBS -l walltime=02:00:00
#PBS -A VERF-DEV

cd ${DATA_PATH}/gefs/dprogdt/${INIT}/untar_ops

/bin/rm -rf ${DATA_PATH}/htar_gefs_dprogdt_opsfcst_${INIT}_done

export input="${DATA_PATH}/${CASE}_gefs_members.txt"

while IFS= read -r line ; do
	#echo "Reading the next line of "${input}
	export mem=${mem_temp}

        /bin/rm -rf ${DATA_PATH}/gefs/dprogdt/${INIT}/ge*v12.${YYYYMMDD}.t${HH}z.pgrb2s.0p25.f${FHHH}.grb2

        if [[ -s ${DATA_PATH}/gefs/dprogdt/${INIT}/ge${mem_same}v12.${YYYYMMDD}.t${HH}z.pgrb2s.0p25.f${FHHH}.grb2 ]] ; then
		echo ${CYCLE} "F"${FHHH}" ops GEFS ${mem_same} forecast files exists"
	else
		echo "Extracting "${INIT}" ops GEFS ${mem_same} forecast file "${FHHH}
		htar -xvf $GEFS_ARCHIVE $GEFS_FILENAME
        	sleep 3
	        mv $GEFS_FILENAME ${DATA_PATH}/gefs/dprogdt/${INIT}/ge${mem_same}v12.${YYYYMMDD}.t${HH}z.pgrb2s.0p25.f${FHHH}.grb2
	fi

done < ${input}
	
touch ${DATA_PATH}/htar_gefs_opsmems_${INIT}_done

exit

EOF

#----------------------------------------------------------------------------------------

qsub ${DATA_PATH}/gefs/dprogdt/${INIT}/untar_ops/htar_gefs_dprogdt_opsfcst.sh
sleep 3

#----------------------------------------------------------------------------------------

exit

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

done < "${file}"

exit

