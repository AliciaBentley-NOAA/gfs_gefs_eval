#!/bin/bash
##############################################
# Script for submitting jobs on WCOSS2
# that download data from HPSS
##############################################

echo data path: ${DATA_PATH}/gfs/${CYCLE}
echo output path: ${OUTPUT_PATH}
#echo fhr_inc: ${FHR_INC}
#echo fhr_start: ${FHR_START}
#echo fhr_end: ${FHR_END}

mkdir -p ${OUTPUT_PATH}
mkdir -p ${DATA_PATH}/gfs/${CYCLE}/untar_ops
mkdir -p ${DATA_PATH}/gfs/${CYCLE}/untar_retro

export YYYY=`echo $CYCLE | cut -c 1-4`
export YYYYMM=`echo $CYCLE | cut -c 1-6`
export YYYYMMDD=`echo $CYCLE | cut -c 1-8`
export HH=`echo $CYCLE | cut -c 9-10`

export FHHH_temp='`echo $line`'
export FHHH_same='${FHHH}'

file="${DATA_PATH}/${CASE}_fhrs.txt"

#################################################################################################
#----------------------- Info. to download ops GFS forecasts ------------------------------------
export GFS_CHANGE_DATE4=2021031812
export GFS_CHANGE_DATE3=2020022600
export GFS_CHANGE_DATE2=2019061200
export GFS_CHANGE_DATE1=2017072000


if ((${CYCLE} >= ${GFS_CHANGE_DATE4})) ; then
	GFS_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/com_gfs_prod_gfs.${YYYYMMDD}_${HH}.gfs_pgrb2.tar
        GFS_FILENAME=./gfs.${YYYYMMDD}/${HH}/atmos/gfs.t${HH}z.pgrb2.0p25.f${FHHH_same}

elif (((${CYCLE} >= ${GFS_CHANGE_DATE3}) && (${CYCLE} < ${GFS_CHANGE_DATE4}))) ; then
	GFS_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/com_gfs_prod_gfs.${YYYYMMDD}_${HH}.gfs_pgrb2.tar
        GFS_FILENAME=./gfs.${YYYYMMDD}/${HH}/gfs.t${HH}z.pgrb2.0p25.f${FHHH_same}

elif (((${CYCLE} >= ${GFS_CHANGE_DATE2}) && (${CYCLE} < ${GFS_CHANGE_DATE3}))) ; then
	GFS_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/gpfs_dell1_nco_ops_com_gfs_prod_gfs.${YYYYMMDD}_${HH}.gfs_pgrb2.tar
        GFS_FILENAME=./gfs.${YYYYMMDD}/${HH}/gfs.t${HH}z.pgrb2.0p25.f${FHHH_same}

elif (((${CYCLE} >= ${GFS_CHANGE_DATE1}) && (${CYCLE} < ${GFS_CHANGE_DATE2}))) ; then
	GFS_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/gpfs_hps_nco_ops_com_gfs_prod_gfs.${CYCLE}.pgrb2_0p25.tar
        GFS_FILENAME=./gfs.t${HH}z.pgrb2.0p25.f${FHHH_same}

elif ((${CYCLE} < ${GFS_CHANGE_DATE1})) ; then
	GFS_ARCHIVE=/NCEPPROD/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/com2_gfs_prod_gfs.${CYCLE}.pgrb2_0p25.tar
        GFS_FILENAME=./gfs.t${HH}z.pgrb2.0p25.f${FHHH_same}
fi


#-----------------------------------------------------------------------------------------
# Creating a job to download data on a particular ops GFS forecast cycle (CYCLE)
#-----------------------------------------------------------------------------------------

cat > ${DATA_PATH}/gfs/${CYCLE}/untar_ops/htar_gfs_opsfcst.sh <<EOF
#!/bin/bash
#PBS -N gfsops_htar
#PBS -o ${OUTPUT_PATH}/out_htar_gfs_opsfcst_${CYCLE}.out
#PBS -e ${OUTPUT_PATH}/out_htar_gfs_opsfcst_${CYCLE}.err
#PBS -l select=1:ncpus=1:mem=4GB
#PBS -q dev_transfer
#PBS -l walltime=01:30:00
#PBS -A VERF-DEV

cd ${DATA_PATH}/gfs/${CYCLE}/untar_ops

#/bin/rm -rf ${DATA_PATH}/htar_gfs_opsfcst_${CYCLE}_done

file="${DATA_PATH}/${CASE}_fhrs.txt"

while IFS= read -r line ; do
	#echo "Reading the next line of "${file}
	export FHHH=${FHHH_temp}

#        /bin/rm -rf ${DATA_PATH}/gfs/${CYCLE}/gfs.v16.${YYYYMMDD}.t${HH}z.pgrb2.0p25.f${FHHH_same}.grb2

        if [[ -s ${DATA_PATH}/gfs/${CYCLE}/gfs.v16.${YYYYMMDD}.t${HH}z.pgrb2.0p25.f${FHHH_same}.grb2 ]] ; then
		echo ${CYCLE} "F"${FHHH_same}" ops GFS forecast files exists"
	else
		echo "Extracting "${CYCLE}" ops GFS forecast file "${FHHH_same}
		htar -xvf $GFS_ARCHIVE $GFS_FILENAME
        	sleep 3
	        mv $GFS_FILENAME ${DATA_PATH}/gfs/${CYCLE}/gfs.v16.${YYYYMMDD}.t${HH}z.pgrb2.0p25.f${FHHH_same}.grb2
	fi

done < ${file}
	
#touch ${DATA_PATH}/htar_gfs_opsfcst_${CYCLE}_done

exit

EOF

#----------------------------------------------------------------------------------------

qsub ${DATA_PATH}/gfs/${CYCLE}/untar_ops/htar_gfs_opsfcst.sh
sleep 3

#----------------------------------------------------------------------------------------


#########################################################################################
#----------------------- Info. to download retro GFS forecasts --------------------------
export GFS_CHANGE_DATE1=2020082012

if ((${CYCLE} >= ${GFS_CHANGE_DATE1})) ; then
	GFS_ARCHIVE=/NCEPDEV/emc-global/5year/emc.glopara/WCOSS_D/gfsv16/v16rt2/${YYYYMMDD}${HH}/gfsa.tar
	GFS_FILENAME=./gfs.${YYYYMMDD}/${HH}/atmos/gfs.t${HH}z.pgrb2.0p25.f${FHHH_same}

elif ((${CYCLE} < ${GFS_CHANGE_DATE1})) ; then
        GFS_ARCHIVE=/NCEPDEV/emc-global/5year/emc.glopara/WCOSS_D/gfsv16/v16rt2/${YYYYMMDD}${HH}/gfsa.tar
	GFS_FILENAME=./gfs.${YYYYMMDD}/${HH}/gfs.t${HH}z.pgrb2.0p25.f${FHHH_same}
fi

#-----------------------------------------------------------------------------------------
# Creating a job to download data on a particular GFS retro cycle (CYCLE)
#-----------------------------------------------------------------------------------------

cat > ${DATA_PATH}/gfs/${CYCLE}/untar_retro/htar_gfs_retrofcst.sh <<EOF
#!/bin/bash
#PBS -N gfsretro_htar
#PBS -o ${OUTPUT_PATH}/out_htar_gfs_retrofcst_${CYCLE}.out
#PBS -e ${OUTPUT_PATH}/out_htar_gfs_retrofcst_${CYCLE}.err
#PBS -l select=1:ncpus=1:mem=4GB
#PBS -q dev_transfer
#PBS -l walltime=01:30:00
#PBS -A VERF-DEV

cd ${DATA_PATH}/gfs/${CYCLE}/untar_retro

#/bin/rm -rf ${DATA_PATH}/htar_gfs_retrofcst_${CYCLE}_done

file="${DATA_PATH}/${CASE}_fhrs.txt"

while IFS= read -r line ; do
	echo "Reading the next line of "${file}
	export FHHH=${FHHH_temp}

#	/bin/rm -rf ${DATA_PATH}/gfs/${CYCLE}/gfs.v17.${YYYYMMDD}.t${HH}z.pgrb2.0p25.f${FHHH_same}.grb2

	if [[ -s ${DATA_PATH}/gfs/${CYCLE}/gfs.v17.${YYYYMMDD}.t${HH}z.pgrb2.0p25.f${FHHH_same}.grb2 ]] ; then
		echo ${CYCLE} "F"${FHHH_same}" retro GFS forecast files exists"
	else
		echo "Extracting "${CYCLE}" retro GFS forecast file "${FHHH_same}
		htar -xvf $GFS_ARCHIVE $GFS_FILENAME
        	sleep 3
	        mv $GFS_FILENAME ${DATA_PATH}/gfs/${CYCLE}/gfs.v17.${YYYYMMDD}.t${HH}z.pgrb2.0p25.f${FHHH_same}.grb2
	fi

done < ${file}

#touch ${DATA_PATH}/htar_gfs_retrofcst_${CYCLE}_done

exit

EOF

#----------------------------------------------------------------------------------------

qsub ${DATA_PATH}/gfs/${CYCLE}/untar_retro/htar_gfs_retrofcst.sh
sleep 3

#----------------------------------------------------------------------------------------

exit

