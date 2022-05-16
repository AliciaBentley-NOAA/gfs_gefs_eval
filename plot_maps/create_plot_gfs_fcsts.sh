#!/bin/bash
##############################################
# Script for submitting jobs on WCOSS2
# that plot forecast maps and analyses
##############################################

echo data path: ${MAP_PATH}/gfs/${CYCLE}
echo output path: ${OUTPUT_PATH}

mkdir -p ${OUTPUT_PATH}
mkdir -p ${MAP_PATH}/gfs/${CYCLE}/scripts

export YYYY=`echo $CYCLE | cut -c 1-4`
export YYYYMM=`echo $CYCLE | cut -c 1-6`
export YYYYMMDD=`echo $CYCLE | cut -c 1-8`
export HH=`echo $CYCLE | cut -c 9-10`

export FHHH_temp='`echo $line`'
export FHHH_same='${FHHH}'
export COUNTER_same='${COUNTER}'
export COUNTER_update='$(($COUNTER+1))'

file="${MAP_PATH}/${CASE}_fhrs.txt"

#################################################################################################
#-----------------------------------------------------------------------------------------
# Creating a job to plot GFS forecasts for a particular initialization time (CYCLE)
#-----------------------------------------------------------------------------------------

cat > ${MAP_PATH}/gfs/${CYCLE}/scripts/plot_gfs_fcst.sh <<EOF
#!/bin/bash
#PBS -N gfs_plot
#PBS -o ${OUTPUT_PATH}/out_plot_gfs_fcst_${CYCLE}.out
#PBS -e ${OUTPUT_PATH}/out_plot_gfs_fcst_${CYCLE}.err
#PBS -l select=1:ncpus=1:mem=100GB
#PBS -q dev
#PBS -l walltime=02:00:00
#PBS -A VERF-DEV

cd ${MAP_PATH}/gfs/${CYCLE}/scripts
cp ${SCRIPTS_PATH}/plot_gfs*.py .

#/bin/rm -rf ${MAP_PATH}/plot_gfs_fcst_${CYCLE}_done

COUNTER=0

file="${MAP_PATH}/${CASE}_fhrs.txt"

while IFS= read -r line ; do
	#echo "Reading the next line of "${file}
	export FHHH=${FHHH_temp}

        /bin/rm -rf ${MAP_PATH}/gfs/${CYCLE}/gfs_${DOMAIN}_slp_${CASE}_${COUNTER_same}.png

	echo "Plotting "${CYCLE}" "${FHHH_same}" over "${DOMAIN}
	#python plot_gfs_slp_4panel.py 2022042000 24 conus,upper_midwest /path/to/data SNODissue 0
	python plot_gfs_slp_4panel.py ${CYCLE} ${FHHH_same} ${DOMAIN_ARRAY} ${DATA_PATH} ${CASE} ${COUNTER_same}
        sleep 3

	COUNTER=${COUNTER_update}

done < ${file}

mv gfs_*_slp_${CASE}_*.png ${MAP_PATH}/gfs/${CYCLE}/.

#touch ${MAP_PATH}/plot_gfs_fcst_${CYCLE}_done

exit

EOF

#----------------------------------------------------------------------------------------

qsub ${MAP_PATH}/gfs/${CYCLE}/scripts/plot_gfs_fcst.sh
sleep 3

#----------------------------------------------------------------------------------------

exit

