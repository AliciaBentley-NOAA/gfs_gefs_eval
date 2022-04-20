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
module load wgrib2/2.0.8_wmo
#Load Python
module load python/3.8.6
module load proj/7.1.0
module load geos/3.8.1
module use /lfs/h1/mdl/nbm/save/apps/modulefiles
module load python-modules/3.8.6
export PYTHONPATH="${PYTHONPATH}:/lfs/h2/emc/vpppg/noscrub/Alicia.Bentley/python"
counter=0

#===============================================================================================================
#==============================================  BEGIN CHANGES  ================================================
#===============================================================================================================

# Specify case name, forecast length, and forecast timestep (increment)
export CASE='SNODissue'

# Location of your saved GFSv17/GEFSv13 evaluation /download_data directory
export SCRIPTS_PATH='/lfs/h2/emc/vpppg/noscrub/Alicia.Bentley/gfs_gefs_eval/download_data'

# Location to store downloaded forecasts/analyses files
export DATA_PATH='/lfs/h2/emc/ptmp/Alicia.Bentley/gfs_gefs_eval/'${CASE}

# Location to write output from submitted download data jobs
export OUTPUT_PATH=${DATA_PATH}/'output'

# Select analysis files to download (true/false)
export GET_ANALYSES=false           	 # Set to true if downloading GFS, RAP, ST4, or NOHRSC analyses are true
export GET_GFS_ANL=true
export GET_RAP_ANL=true
export GET_ST4_ANL=true
export GET_NOHRSC_ANL=true

# Specify which analyses you want to download
export ANL_START=0 			 # Start downloading analysis files for the first initialization date
export ANL_END=480                       # Download analyses until 480 hours after first init date (10 days after last 10-day forecast)
export ANL_INC=6 			 # Typically 6 hours

# Select forecast files to download (true/false)
export GET_FORECASTS=false		 # Set to true if downloading GFS, GEFS, or DPROGDT forecasts are true
export GET_GFS_FCSTS=true
export GET_GEFS_FCSTS=false
export GET_GEFS_DPROGDT=false

# Specify which forecast hours to downlaod
export FHR_START=0			 # Typically 0 hours (beginning of forecast)
export FHR_END=240                       # Typically 240 hours (10-day forecast)
export FHR_INC=6                         # Typically 6 hourS
export DPROGDT_VDATE=2022021100    	 # The date and time of the the event; YYYYMMDDHH
export DPROGDT_INC=24              	 # Typically 24 hours between dprogdt forecasts

# If you've already downloaded data, you can check that it exists (true/false)
export CHECK_DATA=true			 # Set to true if checking for any data are true (analysis, forecasts, dprogdt)
export CHECK_ANALYSES=true
export CHECK_GFS_FCST=true
export CHECK_GEFS_FCST=true
export CHECK_GEFS_DPROGDT=true

# Specify initialization dates to download (typically 11 dates, ending on the date of the event)
for longdate in 20220201
do

# Specify the initialization hours to download (typically 00 and 12)
for hour in 00 12
do

#===============================================================================================================	
#===============================================  END CHANGES  =================================================
#===============================================================================================================

if [ $counter = 0 ]; then
    	echo " "
    	echo "Starting drive_download_data.sh for: "$CASE
   	mkdir -p ${DATA_PATH}
fi

counter=$(($counter+1))
export CYCLE=${longdate}${hour}

echo "*********************"
if [ $GET_ANALYSES = true ]; then
        echo "Creating lists of valid dates (for analysis files)"
        python ${SCRIPTS_PATH}/list_valid_dates.py ${CYCLE} ${ANL_START} ${ANL_END} ${ANL_INC} ${CASE}
        mv ${SCRIPTS_PATH}/../${CASE}_valid_dates.txt ${DATA_PATH}/${CASE}_valid_dates.txt
	sleep 3
	echo "*********************"
	if [ $GET_GFS_ANL = true ]; then
   		echo "Copy/submit script to download GFS analysis data"
   		${SCRIPTS_PATH}/create_htar_gfs_anl.sh
   		sleep 3
	fi
	echo "*********************"
	if [ $GET_RAP_ANL = true ]; then
   		echo "Copy/submit script to download RAP analysis data"
   		${SCRIPTS_PATH}/create_htar_rap_anl.sh
   		sleep 3
	fi
	echo "*********************"
	if [ $GET_ST4_ANL = true ]; then
   		echo "Copy/submit script to download Stage-IV analysis data"
   		${SCRIPTS_PATH}/create_htar_st4_anl.sh
   		sleep 3
	fi
	echo "*********************"
	if [ $GET_NOHRSC_ANL = true ]; then
   		echo "Copy/submit script to download NOHRSC analysis data"
   		${SCRIPTS_PATH}/create_htar_nohrsc_anl.sh
   		sleep 3
	fi
export GET_ANALYSES=false
fi

echo "*********************"
if [ $GET_FORECASTS = true ]; then
	if [ $counter = 1 ]; then
		echo "Create list of forecast hours (${FHR_START} ${FHR_END} ${FHR_INC})"
      		python ${SCRIPTS_PATH}/list_fhrs.py ${CYCLE} ${FHR_START} ${FHR_END} ${FHR_INC} ${CASE}
        	mv ${SCRIPTS_PATH}/../${CASE}_fhrs.txt ${DATA_PATH}/${CASE}_fhrs.txt
		sleep 3
	fi	
	echo "*********************"
	if [ $GET_GFS_FCSTS = true ]; then
	  	echo "Create/submit script to download ops/retro GFS forecasts (Init.: ${CYCLE})"
	      	${SCRIPTS_PATH}/create_htar_gfs_fcsts.sh
	        sleep 3
	fi
	echo "*********************"
	if [ $GET_GEFS_FCSTS = true ]; then
		echo "Create/submit script to download ops/retro GEFS forecasts (Init.: ${CYCLE})"
		${SCRIPTS_PATH}/create_htar_gefs_fcsts.sh
		sleep 3
	fi
	echo "*********************"
	if [ $GET_GEFS_DPROGDT = true ]; then
      		echo "Creating a list of intialization times for GEFS dprog/dt"
            	python ${SCRIPTS_PATH}/list_init_dates.py ${DPROGDT_VDATE} ${FHR_START} ${FHR_END} ${DPROGDT_INC} ${CASE}
	        mv ${SCRIPTS_PATH}/../${CASE}_init_dates.txt ${DATA_PATH}/${CASE}_init_dates.txt
		sleep 3
		echo "Create/submit script to download ops/retro GEFS members (Valid: ${DPROGDT_VDATE})"
		${SCRIPTS_PATH}/create_htar_gefs_dprogdt.sh
		sleep 3
		export GET_GEFS_DPROGDT=false
	fi
fi

echo "*********************"
if [ $CHECK_DATA = true ]; then
	if [ $CHECK_ANALYSES = true ]; then
		echo "Create/submit script to check that all analysis files were downloaded"
		${SCRIPTS_PATH}/create_check_analyses.sh
		sleep 3
		export CHECK_ANALYSES=false
	fi
	echo "*********************"
	if [ $CHECK_GFS_FCST = true ]; then
		echo "Create/submit script to check that all GFS forecasts were downloaded (Init.: ${CYCLE})"
		${SCRIPTS_PATH}/create_check_gfs_fcsts.sh
		sleep 3
	fi
	echo "*********************"
	if [ $CHECK_GEFS_FCST = true ]; then
		echo "Create/submit script to check that all GEFS forecasts were downloaded (Init.: ${CYCLE})"
		${SCRIPTS_PATH}/create_check_gefs_fcsts.sh
		sleep 3 
	fi
	echo "*********************"
	if [ $CHECK_GEFS_DPROGDT = true ]; then
		echo "Create/submit script to check that all DPROGDT files were downloaded (Init.: ${CYCLE})"
		${SCRIPTS_PATH}/create_check_gefs_dprogdt.sh
		sleep 3
		export CHECK_GEFS_DPROGDT=false
	fi
fi

done
done

exit
