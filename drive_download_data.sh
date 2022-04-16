#!/bin/bash
###################################################
# Script to download forecasts/analyses from HPSS
###################################################
module purge
module load envvar/1.0
module load intel/19.1.3.304
module load PrgEnv-intel/8.1.0
module load craype/2.7.10
module load cray-mpich/8.1.9
module load imagemagick/7.0.8-7
module load wgrib2
#Load Python
module load python/3.8.6
module load proj/7.1.0
module load geos/3.8.1
module use /lfs/h1/mdl/nbm/save/apps/modulefiles
module load python-modules/3.8.6
export PYTHONPATH="${PYTHONPATH}:/lfs/h2/emc/vpppg/noscrub/Alicia.Bentley/python"
counter=0

#==============================================  BEGIN CHANGES  ================================================

# Location of your saved GFSv17/GEFSv13 evaluation scripts
export SCRIPTS_PATH='/lfs/h2/emc/vpppg/noscrub/Alicia.Bentley/gfs_gefs_eval/download_data'

# Specify case name and forecast length
export CASE='SNODissue'
export FHR_START=0
export FHR_END=240       # Typically 240 (hours = 10 days)
export FHR_INC=6         # Typically 6 (hours)

# Location to store downloaded forecasts/analyses files
export DATA_PATH='/lfs/h2/emc/ptmp/Alicia.Bentley/gfs_gefs_eval/'${CASE}

# Location to write output from submitted jobs
export OUTPUT_PATH=${DATA_PATH}/'output'

# Select forecast files to download (true/false)
export GET_GFS_FCSTS=true
export GET_GEFS_FCSTS=true
export GET_GEFS_DPROGDT=true

# Select valid date/forecast increment (if GET_GEFS_DPROGDT=true)
export DPROGDT_VDATE=2022021100    	#YYYYMMDDHH
export DPROGDT_INC=24              	#Typically 24 (hours)

# Select analysis files to download (true/false)
export GET_GFS_ANL=true
export GET_RAP_ANL=true
export GET_ST4_ANL=true
export GET_NOHRSC_ANL=true

# Specify initialization dates/times to download
#for cycle in 20190827 20190828 20190829 20190830 20190831 20190901 20190902 20190903 20190904 20190905 20190906
#do

for longdate in 20220201            #20200829   #20191124
do

for hour in 00 12
do

#===============================================  END CHANGES  =================================================

if [ $counter = 0 ]; then
    echo " "
    echo "Starting drive_download_data.sh for: "$CASE $FHR_START $FHR_END $FHR_INC
fi

echo "*********************"
export CYCLE=${longdate}${hour}
echo "CYCLE: "$CYCLE
counter=$(($counter+1))
#echo "counter: "$counter

echo "*********************"
if [ $counter = 1 ]; then	
   mkdir -p ${DATA_PATH}

   echo "Creating lists of valid dates (for analysis files)"
   python ${SCRIPTS_PATH}/list_valid_dates.py ${CYCLE} ${FHR_START} ${FHR_END} ${FHR_INC} ${CASE}
   mv ${SCRIPTS_PATH}/../${CASE}_valid_dates.txt ${DATA_PATH}/${CASE}_valid_dates.txt
   sleep 1

   echo "Create list of forecast hours (${FHR_START} ${FHR_END} ${FHR_INC})"
   python ${SCRIPTS_PATH}/list_fhrs.py ${CYCLE} ${FHR_START} ${FHR_END} ${FHR_INC} ${CASE}
   mv ${SCRIPTS_PATH}/../${CASE}_fhrs.txt ${DATA_PATH}/${CASE}_fhrs.txt
   sleep 1

   if [ $GET_GEFS_DPROGDT = true ]; then
      echo "Creating a list of intialization times for GEFS dprog/dt"
      python ${SCRIPTS_PATH}/list_init_dates.py ${DPROGDT_VDATE} ${FHR_START} ${FHR_END} ${DPROGDT_INC} ${CASE}
      mv ${SCRIPTS_PATH}/../${CASE}_init_dates.txt ${DATA_PATH}/${CASE}_init_dates.txt
      sleep 1
   fi   

fi

echo "*********************"
if [ $GET_GFS_FCSTS = true ]; then
   echo "Create/submit script to download ops/retro GFS forecasts (Init.: ${CYCLE})"
   ${SCRIPTS_PATH}/create_htar_gfs_fcsts.sh
   sleep 5
fi

echo "*********************"
if [ $GET_GEFS_FCSTS = true ]; then
    echo "Create/submit script to download ops/retro GEFS forecasts (Init.: ${CYCLE})"
    ${SCRIPTS_PATH}/create_htar_gefs_fcsts.sh
    sleep 5
fi

echo "*********************"
if [ $GET_GEFS_DPROGDT = true ] && [ $counter = 1 ]; then
    echo "Create/submit script to download ops/retro GEFS members (Valid: ${DPROGDT_VDATE})"
    ${SCRIPTS_PATH}/create_htar_gefs_dprogdt.sh
    sleep 5
fi


echo "*********************"
if [ $GET_GFS_ANL = true ] && [ $counter = 1 ]; then
   echo "Copy/submit script to download GFS analysis data"
   ${SCRIPTS_PATH}/create_htar_gfs_anl.sh
   sleep 5
fi

echo "*********************"
if [ $GET_RAP_ANL = true ] && [ $counter = 1 ]; then
   echo "Copy/submit script to download RAP analysis data"
   ${SCRIPTS_PATH}/create_htar_rap_anl.sh
   sleep 5
fi

echo "*********************"
if [ $GET_ST4_ANL = true ] && [ $counter = 1 ]; then
   echo "Copy/submit script to download Stage-IV analysis data"
   ${SCRIPTS_PATH}/create_htar_st4_anl.sh
   sleep 5
fi

echo "*********************"
if [ $GET_NOHRSC_ANL = true ] && [ $counter = 1 ]; then
   echo "Copy/submit script to download NOHRSC analysis data"
   ${SCRIPTS_PATH}/create_htar_nohrsc_anl.sh
   sleep 5
fi


done
done

exit
