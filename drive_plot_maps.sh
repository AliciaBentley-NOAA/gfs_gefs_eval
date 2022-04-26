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

# Location of your saved GFSv17/GEFSv13 evaluation /plot_maps directory
export SCRIPTS_PATH='/lfs/h2/emc/vpppg/noscrub/'${USER}'/gfs_gefs_eval/plot_maps'

# Location of downloaded forecasts/analyses files
export DATA_PATH='/lfs/h2/emc/ptmp/'${USER}'/gfs_gefs_eval/'${CASE}

# Location to plot maps
export MAP_PATH=${DATA_PATH}'/maps'

# Location to write output from submitted plot_maps jobs
export OUTPUT_PATH=${MAP_PATH}'/output'

# Select forecast files to download (true/false)
export PLOT_FORECASTS=true		 # Set to true if plotting GFS, GEFS, or DPROGDT forecasts are true
export PLOT_GFS_FCSTS=true
export PLOT_GEFS_FCSTS=false
export PLOT_GEFS_DPROGDT=false

# Specify which forecast hours to plot
export FHR_START=0			 # Typically 0 hours (beginning of forecast)
export FHR_END=240                       # Typically 240 hours (10-day forecast)
export FHR_INC=6                         # Typically 6 hourS
export DPROGDT_VDATE=2022021100    	 # The date and time of the the event; YYYYMMDDHH
export DPROGDT_INC=24              	 # Typically 24 hours between dprogdt forecasts

# Specify the domains to plot. This must be written as: 'domain1,domain2,...' (with no spaces)
export DOMAIN_ARRAY='conus,upper_midwest'

# Specify initialization dates to plot (typically 11 dates [YYYYMMDD], ending on the date of the event)
for longdate in 20220201
do

# Specify the initialization hours to plot on each initialization date (typically 00 and 12)
for hour in 00
do

#===============================================================================================================	
#===============================================  END CHANGES  =================================================
#===============================================================================================================

if [ $counter = 0 ]; then
    	echo " "
    	echo "Starting drive_plot_maps.sh for: "$CASE
   	mkdir -p ${MAP_PATH}
fi

counter=$(($counter+1))
export CYCLE=${longdate}${hour}

echo "*********************"
if [ $PLOT_FORECASTS = true ]; then
	if [ $counter = 1 ]; then
		echo "Create list of forecast hours (${FHR_START} ${FHR_END} ${FHR_INC})"
      		python ${SCRIPTS_PATH}/list_fhrs.py ${CYCLE} ${FHR_START} ${FHR_END} ${FHR_INC} ${CASE}
        	mv ${SCRIPTS_PATH}/../${CASE}_fhrs.txt ${MAP_PATH}/${CASE}_fhrs.txt
		sleep 3
	fi	
	echo "*********************"
	if [ $PLOT_GFS_FCSTS = true ]; then
	  	echo "Create/submit script to plot ops/retro GFS forecasts (Init.: ${CYCLE} for ${DOMAIN_ARRAY})"
	      	${SCRIPTS_PATH}/create_plot_gfs_fcsts.sh
	        sleep 3
	fi
	echo "*********************"
	if [ $PLOT_GEFS_FCSTS = true ]; then
		echo "Create/submit script to plot ops/retro GEFS forecasts (Init.: ${CYCLE} for ${DOMAIN_ARRAY})"
		${SCRIPTS_PATH}/create_plot_gefs_fcsts.sh
		sleep 3
	fi
	echo "*********************"
	if [ $PLOT_GEFS_DPROGDT = true ]; then
      		echo "Creating a list of intialization times for GEFS dprog/dt"
            	python ${SCRIPTS_PATH}/list_init_dates.py ${DPROGDT_VDATE} ${FHR_START} ${FHR_END} ${DPROGDT_INC} ${CASE}
	        mv ${SCRIPTS_PATH}/../${CASE}_init_dates.txt ${MAP_PATH}/${CASE}_init_dates.txt
		sleep 3
		echo "Create/submit script to plot ops/retro GEFS members (Valid: ${DPROGDT_VDATE} for ${DOMAIN_ARRAY})"
		${SCRIPTS_PATH}/create_plot_gefs_dprogdt.sh
		sleep 3
		export PLOT_GEFS_DPROGDT=false
	fi
fi

done
done

exit
