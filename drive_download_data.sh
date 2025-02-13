#!/bin/bash
###################################################
# Script to download forecasts/analyses from HPSS
# for official GFSv17 and GEFSv13 evaluations
#
# Contributors: Alicia.Bentley@noaa.gov
# NOAA/NWS/NCEP/Environmental Modeling Center
# Verification and Products Group (VPG)
###################################################
module reset
module load intel/${intel_ver}
module load PrgEnv-intel/${PrgEnvintel_ver}
module load craype/${craype_ver}
module load cray-mpich/${craympich_ver}
module load imagemagick/${imagemagick_ver}
module load wgrib2/${wgrib2_ver}

#Load Python
module load python/3.8.6
module load proj/7.1.0
module load geos/3.8.1
module use /lfs/h1/mdl/nbm/save/apps/modulefiles
module load python-modules/3.8.6
export PYTHONPATH="${PYTHONPATH}:/lfs/h2/emc/vpppg/noscrub/Alicia.Bentley/python"

#Start Counter
counter=0
#===============================================================================================================
#==============================================  BEGIN CHANGES  ================================================
#===============================================================================================================

# ******************************************************
# ****Specify case name, paths, sections to execute*****
# ******************************************************
# Specify case study name (e.g., dorian2019)
export CASE='Nov292022'

# Location of your saved GFS/GEFS evaluation /download_data directory
export SCRIPTS_PATH='/lfs/h2/emc/vpppg/save/'${USER}'/gfs_gefs_eval/download_data'

# Location to store downloaded forecasts/analyses files 
###export DATA_PATH='/lfs/h2/emc/stmp/'${USER}'/gfs_gefs_eval/'${CASE}'/data'
export DATA_PATH='/lfs/h2/emc/vpppg/noscrub/'${USER}'/eval_case_study/'${CASE}'/data'

# Location to write output from submitted download data jobs
export OUTPUT_PATH=${DATA_PATH}'/output'

# Select which sections of code to execute (YES/NO)
export GET_ANALYSES=YES
export GET_FORECASTS=YES
export CHECK_DATA=NO

# *****************************************
# ****This is the GET_ANALYSES section*****
# *****************************************
# Select which analysis types to download (YES/NO)
export GET_GFS_ANL=YES
export GET_RAP_ANL=NO
export GET_ST4_ANL=NO
export GET_NOHRSC_ANL=NO

# Select analyses start, end, and increment to download
export ANL_START=0 			 # Start downloading analysis files for the first initialization date if set to 0
export ANL_END=48                       # Download analyses until 480 hours after first init date (i.e., 10 days after last 10-day forecast)
export ANL_INC=6 			 # Typically 6 hours timestep between analysis files

# ******************************************
# ****This is the GET_FORECASTS section*****
# ******************************************
# Select which model forecasts to download (YES/NO)
export GET_GFS_FCSTS=YES
export GET_GEFS_FCSTS=NO
export GET_GEFS_DPROGDT=NO

# Select forecast start, end, and increment to download (applies to GFS_FCSTS and GEFS_FCSTS)
export FHR_START=0			 # Typically 0 hours (beginning of forecast)
export FHR_END=48                       # Typically 240 hours (10-day forecast)
export FHR_INC=6                         # Typically 6-hour timestep between forecast files

# Select DPROGDT valid date and increment to download (applies to GEFS_DPROGDT)
export DPROGDT_VDATE=2022112900    	 # The date and hour of the main event; YYYYMMDDHH
export DPROGDT_INC=24              	 # Typically 24-hour timestep between dprogdt forecasts

# ***************************************
# ****This is the CHECK_DATA section*****
# ***************************************
# If you've downloaded data, you can check that it exists (YES/NO)
export CHECK_ANALYSES=NO
export CHECK_GFS_FCST=NO
export CHECK_GEFS_FCST=NO
export CHECK_GEFS_DPROGDT=NO

# ******************************************
# ****Select initialization dates/hours*****
# ******************************************
# Specify initialization dates to download (typically 11 dates [YYYYMMDD], ending on the date of the event)
for longdate in 20221129
do

# Specify the initialization hours to download on each initalization date (typically 00 and 12)
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
if [ $GET_ANALYSES = YES ]; then
        echo "Creating lists of valid dates (for analysis files)"
        python ${SCRIPTS_PATH}/list_valid_dates.py ${CYCLE} ${ANL_START} ${ANL_END} ${ANL_INC} ${CASE}
        mv ${SCRIPTS_PATH}/../${CASE}_valid_dates.txt ${DATA_PATH}/${CASE}_valid_dates.txt
	sleep 3
	echo "*********************"
	if [ $GET_GFS_ANL = YES ]; then
   		echo "Copy/submit script to download GFS analysis data"
   		${SCRIPTS_PATH}/create_htar_gfs_anl.sh
   		sleep 3
	fi
	echo "*********************"
	if [ $GET_RAP_ANL = YES ]; then
   		echo "Copy/submit script to download RAP analysis data"
   		${SCRIPTS_PATH}/create_htar_rap_anl.sh
   		sleep 3
	fi
	echo "*********************"
	if [ $GET_ST4_ANL = YES ]; then
   		echo "Copy/submit script to download Stage-IV analysis data"
   		${SCRIPTS_PATH}/create_htar_st4_anl.sh
   		sleep 3
	fi
	echo "*********************"
	if [ $GET_NOHRSC_ANL = YES ]; then
   		echo "Copy/submit script to download NOHRSC analysis data"
   		${SCRIPTS_PATH}/create_htar_nohrsc_anl.sh
   		sleep 3
	fi
export GET_ANALYSES=NO
fi


echo "*********************"
if [ $GET_FORECASTS = YES ]; then
	if [ $counter = 1 ]; then
		echo "Create list of forecast hours (${FHR_START} ${FHR_END} ${FHR_INC})"
      		python ${SCRIPTS_PATH}/list_fhrs.py ${CYCLE} ${FHR_START} ${FHR_END} ${FHR_INC} ${CASE}
        	mv ${SCRIPTS_PATH}/../${CASE}_fhrs.txt ${DATA_PATH}/${CASE}_fhrs.txt
		sleep 3
	fi	
	echo "*********************"
	if [ $GET_GFS_FCSTS = YES ]; then
	  	echo "Create/submit script to download ops/retro GFS forecasts (Init.: ${CYCLE})"
	      	${SCRIPTS_PATH}/create_htar_gfs_fcsts.sh
	        sleep 3
	fi
	echo "*********************"
	if [ $GET_GEFS_FCSTS = YES ]; then
		echo "Create/submit script to download ops/retro GEFS forecasts (Init.: ${CYCLE})"
		${SCRIPTS_PATH}/create_htar_gefs_fcsts.sh
		sleep 3
	fi
	echo "*********************"
	if [ $GET_GEFS_DPROGDT = YES ]; then
      		echo "Creating a list of intialization times for GEFS dprog/dt"
            	python ${SCRIPTS_PATH}/list_init_dates.py ${DPROGDT_VDATE} ${FHR_START} ${FHR_END} ${DPROGDT_INC} ${CASE}
	        mv ${SCRIPTS_PATH}/../${CASE}_init_dates.txt ${DATA_PATH}/${CASE}_init_dates.txt
		sleep 3
		echo "Create/submit script to download ops/retro GEFS members (Valid: ${DPROGDT_VDATE})"
		${SCRIPTS_PATH}/create_htar_gefs_dprogdt.sh
		sleep 3
		export GET_GEFS_DPROGDT=NO
	fi
fi


echo "*********************"
if [ $CHECK_DATA = YES ]; then
	if [ $CHECK_ANALYSES = YES ]; then
		echo "Create/submit script to check that all analysis files were downloaded"
		${SCRIPTS_PATH}/create_check_analyses.sh
		sleep 3
		export CHECK_ANALYSES=NO
	fi
        echo "*********************"
	if [ $CHECK_GEFS_DPROGDT = YES ]; then
		echo "Create/submit script to check that all GEFS DPROGDT files were downloaded"
		${SCRIPTS_PATH}/create_check_gefs_dprogdt.sh
		sleep 3
		export CHECK_GEFS_DPROGDT=NO
	fi
	echo "*********************"
	if [ $CHECK_GFS_FCST = YES ]; then
		echo "Create/submit script to check that all GFS forecasts were downloaded (Init.: ${CYCLE})"
		${SCRIPTS_PATH}/create_check_gfs_fcsts.sh
		sleep 3
	fi
	echo "*********************"
	if [ $CHECK_GEFS_FCST = YES ]; then
		echo "Create/submit script to check that all GEFS forecasts were downloaded (Init.: ${CYCLE})"
		${SCRIPTS_PATH}/create_check_gefs_fcsts.sh
		sleep 3 
	fi
fi

done
done

exit
