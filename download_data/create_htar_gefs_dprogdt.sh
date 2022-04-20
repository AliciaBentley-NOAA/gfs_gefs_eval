#!/bin/bash
##############################################
# Script for submitting jobs on WCOSS2
# that download data from HPSS
##############################################

echo data path: ${DATA_PATH}/dprogdt
echo output path: ${OUTPUT_PATH}
#echo fhr_inc: ${FHR_INC}
#echo fhr_start: ${FHR_START}
#echo fhr_end: ${FHR_END}

mkdir -p ${OUTPUT_PATH}

file="${DATA_PATH}/${CASE}_init_dates.txt"

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

mkdir -p ${DATA_PATH}/dprogdt/${INIT}/untar_ops
mkdir -p ${DATA_PATH}/dprogdt/${INIT}/untar_retro

export mem_same='${mem}'

#################################################################################################
#----------------------- Info. to download ops GEFS forecasts ------------------------------------
export GEFS_CHANGE_DATE2=2020092312
export GEFS_CHANGE_DATE1=2019082000

if ((${INIT} >= ${GEFS_CHANGE_DATE2})) ; then
	GEFSA_ARCHIVE=/NCEPPROD/2year/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/com_gefs_prod_gefs.${YYYYMMDD}_${HH}.atmos_pgrb2ap5.tar
        GEFSA_FILENAME=./atmos/pgrb2ap5/ge${mem_same}.t${HH}z.pgrb2a.0p50.f${FHHH}
        GEFSB_ARCHIVE=/NCEPPROD/2year/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/com_gefs_prod_gefs.${YYYYMMDD}_${HH}.atmos_pgrb2bp5.tar
	GEFSB_FILENAME=./atmos/pgrb2bp5/ge${mem_same}.t${HH}z.pgrb2b.0p50.f${FHHH}

elif (((${INIT} >= ${GEFS_CHANGE_DATE1}) && (${INIT} < ${GEFS_CHANGE_DATE2}))) ; then
	GEFSA_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/gpfs_dell2_nco_ops_com_gens_prod_gefs.${YYYYMMDD}_${HH}.pgrb2a.tar
        GEFSA_FILENAME=./pgrb2a/ge${mem_same}.t${HH}z.pgrb2af${FHHH}
        GEFSB_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/gpfs_dell2_nco_ops_com_gens_prod_gefs.${YYYYMMDD}_${HH}.pgrb2b.tar
	GEFSB_FILENAME=./pgrb2b/ge${mem_same}.t${HH}z.pgrb2bf${FHHH}

elif ((${INIT} < ${GEFS_CHANGE_DATE1})) ; then
	GEFSA_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/com2_gens_prod_gefs.${YYYYMMDD}_${HH}.pgrb2a.tar
        GEFSA_FILENAME=./pgrb2a/ge${mem_same}.t${HH}z.pgrb2af${FHHH}
        GEFSB_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/com2_gens_prod_gefs.${YYYYMMDD}_${HH}.pgrb2b.tar
	GEFSB_FILENAME=./pgrb2b/ge${mem_same}.t${HH}z.pgrb2bf${FHHH}
fi

#-----------------------------------------------------------------------------------------
# Creating a job to download data on a particular ops GEFS forecast cycle (CYCLE)
#-----------------------------------------------------------------------------------------

cat > ${DATA_PATH}/dprogdt/${INIT}/untar_ops/htar_gefs_dprogdt_opsfcst.sh <<EOF
#!/bin/bash
#PBS -N dprogops_htar
#PBS -o ${OUTPUT_PATH}/out_htar_gefs_dprogdt_opsfcst_${INIT}.out
#PBS -e ${OUTPUT_PATH}/out_htar_gefs_dprogdt_opsfcst_${INIT}.err
#PBS -l select=1:ncpus=1:mem=4GB
#PBS -q dev_transfer
#PBS -l walltime=02:00:00
#PBS -A VERF-DEV

cd ${DATA_PATH}/dprogdt/${INIT}/untar_ops

#/bin/rm -rf ${DATA_PATH}/htar_gefs_dprogdt_opsfcst_${INIT}_done

for mem in c00 p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20 p21 p22 p23 p24 p25 p26 p27 p28 p29 p30 ; do

#        /bin/rm -rf ${DATA_PATH}/dprogdt/${INIT}/ge${mem_same}.v12.${YYYYMMDD}.t${HH}z.pgrb2a.0p50.f${FHHH}.grb2
#        /bin/rm -rf ${DATA_PATH}/dprogdt/${INIT}/ge${mem_same}.v12.${YYYYMMDD}.t${HH}z.pgrb2b.0p50.f${FHHH}.grb2

        if [[ -s ${DATA_PATH}/dprogdt/${INIT}/ge${mem_same}.v12.${YYYYMMDD}.t${HH}z.pgrb2a.0p50.f${FHHH}.grb2 ]] ; then
		echo ${CYCLE} "F"${FHHH}" ops GEFSA ${mem_same} forecast files exists"
	else
		echo "Extracting "${INIT}" ops GEFSA ${mem_same} forecast file "${FHHH}
		htar -xvf $GEFSA_ARCHIVE $GEFSA_FILENAME
        	sleep 3
	        mv $GEFSA_FILENAME ${DATA_PATH}/dprogdt/${INIT}/ge${mem_same}.v12.${YYYYMMDD}.t${HH}z.pgrb2a.0p50.f${FHHH}.grb2
	fi

        if [[ -s ${DATA_PATH}/dprogdt/${INIT}/ge${mem_same}.v12.${YYYYMMDD}.t${HH}z.pgrb2b.0p50.f${FHHH}.grb2 ]] ; then
		echo ${CYCLE} "F"${FHHH}" ops GEFSB ${mem_same} forecast files exists"
	else
		echo "Extracting "${INIT}" ops GEFSB ${mem_same} forecast file "${FHHH}
		htar -xvf $GEFSB_ARCHIVE $GEFSB_FILENAME
		sleep 3
		mv $GEFSB_FILENAME ${DATA_PATH}/dprogdt/${INIT}/ge${mem_same}.v12.${YYYYMMDD}.t${HH}z.pgrb2b.0p50.f${FHHH}.grb2
	fi

done
	
#touch ${DATA_PATH}/htar_gefs_dprogdt_opsfcst_${INIT}_done

exit

EOF

#----------------------------------------------------------------------------------------

qsub ${DATA_PATH}/dprogdt/${INIT}/untar_ops/htar_gefs_dprogdt_opsfcst.sh
sleep 3

#----------------------------------------------------------------------------------------


#########################################################################################
#----------------------- Info. to download retro GEFS forecasts --------------------------
export GEFS_CHANGE_DATE2=2020092312
export GEFS_CHANGE_DATE1=2019082000


if ((${INIT} >= ${GEFS_CHANGE_DATE2})) ; then
	GEFS_ARCHIVE=/NCEPPROD/5year/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/com_gefs_prod_gefs.${YYYYMMDD}_${HH}.atmos_pgrb2sp25.tar
	GEFS_AVG_FILENAME=./atmos/pgrb2sp25/ge${mem_same}.t${HH}z.pgrb2s.0p25.f${FHHH}

elif (((${INIT} >= ${GEFS_CHANGE_DATE1}) && (${INIT} < ${GEFS_CHANGE_DATE2}))) ; then
	GEFS_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/gpfs_dell2_nco_ops_com_gens_prod_gefs.${YYYYMMDD}_${HH}.pgrb2a.tar
	GEFS_AVG_FILENAME=./pgrb2a/ge${mem_same}.t${HH}z.pgrb2af${FHHH}

elif ((${INIT} < ${GEFS_CHANGE_DATE1})) ; then
	GEFS_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/com2_gens_prod_gefs.${YYYYMMDD}_${HH}.pgrb2a.tar
	GEFS_AVG_FILENAME=./pgrb2a/ge${mem_same}.t${HH}z.pgrb2af${FHHH}
fi


#-----------------------------------------------------------------------------------------
# Creating a job to download data on a particular GEFS retro cycle (CYCLE)
#-----------------------------------------------------------------------------------------

cat > ${DATA_PATH}/dprogdt/${INIT}/untar_retro/htar_gefs_dprogdt_retrofcst.sh <<EOF
#!/bin/bash
#PBS -N dprogretro_htar
#PBS -o ${OUTPUT_PATH}/out_htar_gefs_dprogdt_retrofcst_${INIT}.out
#PBS -e ${OUTPUT_PATH}/out_htar_gefs_dprogdt_retrofcst_${INIT}.err
#PBS -l select=1:ncpus=1:mem=4GB
#PBS -q dev_transfer
#PBS -l walltime=02:00:00
#PBS -A VERF-DEV

cd ${DATA_PATH}/dprogdt/${INIT}/untar_retro

#/bin/rm -rf ${DATA_PATH}/htar_gefs_dprogdt_retrofcst_${INIT}_done

for mem in c00 p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20 p21 p22 p23 p24 p25 p26 p27 p28 p29 p30 ; do

#        /bin/rm -rf ${DATA_PATH}/dprogdt/${INIT}/ge${mem_same}.v13.${YYYYMMDD}.t${HH}z.pgrb2a.0p50.f${FHHH}.grb2
#        /bin/rm -rf ${DATA_PATH}/dprogdt/${INIT}/ge${mem_same}.v13.${YYYYMMDD}.t${HH}z.pgrb2a.0p50.f${FHHH}.grb2


        if [[ -s ${DATA_PATH}/dprogdt/${INIT}/ge${mem_same}.v13.${YYYYMMDD}.t${HH}z.pgrb2a.0p50.f${FHHH}.grb2 ]] ; then
		echo ${CYCLE} "F"${FHHH}" retro GEFSA ${mem_same} forecast files exists"
	else
		echo "Extracting "${INIT}" retro GEFSA ${mem_same} forecast file "${FHHH}
		htar -xvf $GEFSA_ARCHIVE $GEFSA_FILENAME
		sleep 3
		mv $GEFSA_FILENAME ${DATA_PATH}/dprogdt/${INIT}/ge${mem_same}.v13.${YYYYMMDD}.t${HH}z.pgrb2a.0p50.f${FHHH}.grb2
	fi

	if [[ -s ${DATA_PATH}/dprogdt/${INIT}/ge${mem_same}.v13.${YYYYMMDD}.t${HH}z.pgrb2b.0p50.f${FHHH}.grb2 ]] ; then
		echo ${CYCLE} "F"${FHHH}" ops GEFSB ${mem_same} forecast files exists"
	else
		echo "Extracting "${INIT}" ops GEFSB ${mem_same} forecast file "${FHHH}
		htar -xvf $GEFSB_ARCHIVE $GEFSB_FILENAME
		sleep 3
		mv $GEFSB_FILENAME ${DATA_PATH}/dprogdt/${INIT}/ge${mem_same}.v13.${YYYYMMDD}.t${HH}z.pgrb2b.0p50.f${FHHH}.grb2
	fi

done

#touch ${DATA_PATH}/htar_gefs_dprogdt_retrofcst_${CYCLE}_done

exit

EOF

#----------------------------------------------------------------------------------------

qsub ${DATA_PATH}/dprogdt/${INIT}/untar_retro/htar_gefs_dprogdt_retrofcst.sh
sleep 3

#----------------------------------------------------------------------------------------

done < ${file}

exit

