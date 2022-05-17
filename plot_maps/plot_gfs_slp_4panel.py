#!/bin/env/python

import grib2io
import pyproj
import cartopy.crs as ccrs
from cartopy.mpl.gridliner import LONGITUDE_FORMATTER, LATITUDE_FORMATTER
import cartopy.feature as cfeature
import matplotlib
#matplotlib.use('Agg')
import io
import matplotlib.pyplot as plt
from PIL import Image
import matplotlib.image as image
from matplotlib.gridspec import GridSpec
import numpy as np
import time,os,sys,multiprocessing
import multiprocessing.pool
import ncepy
from scipy import ndimage
from netCDF4 import Dataset
import cartopy
import copy

#--------------Set some classes------------------------#
# Make Python process pools non-daemonic
class NoDaemonProcess(multiprocessing.Process):
  # make 'daemon' attribute always return False
  @property
  def daemon(self):
    return False

  @daemon.setter
  def daemon(self, value):
    pass

class NoDaemonContext(type(multiprocessing.get_context())):
  Process = NoDaemonProcess

# We sub-class multiprocessing.pool.Pool instead of multiprocessing.Pool
# because the latter is only a wrapper function, not a proper class.
class MyPool(multiprocessing.pool.Pool):
  def __init__(self, *args, **kwargs):
    kwargs['context'] = NoDaemonContext()
    super(MyPool, self).__init__(*args, **kwargs)


#--------------Define some functions ------------------#

def clear_plotables(ax,keep_ax_lst,fig):
  #### - step to clear off old plottables but leave the map info - ####
  if len(keep_ax_lst) == 0 :
    print("clear_plotables WARNING keep_ax_lst has length 0. Clearing ALL plottables including map info!")
  cur_ax_children = ax.get_children()[:]
  if len(cur_ax_children) > 0:
    for a in cur_ax_children:
      if a not in keep_ax_lst:
       # if the artist isn't part of the initial set up, remove it
        a.remove()

def compress_and_save(filename):
  #### - compress and save the image - ####
#  ram = io.StringIO()
  ram = io.BytesIO()
  plt.savefig(ram, format='png', bbox_inches='tight', dpi=300)
#  plt.savefig(filename, format='png', bbox_inches='tight', dpi=300)
  ram.seek(0)
  im = Image.open(ram)
  im2 = im.convert('RGB').convert('P', palette=Image.ADAPTIVE)
  im2.save(filename, format='PNG')

def cmap_t2m():
 # Create colormap for 2-m temperature
 # Modified version of the ncl_t2m colormap from Jacob's ncepy code
    r=np.array([255,128,0,  70, 51, 0,  255,0, 0,  51, 255,255,255,255,255,171,128,128,36,162,255])
    g=np.array([0,  0,  0,  70, 102,162,255,92,128,185,255,214,153,102,0,  0,  0,  68, 36,162,255])
    b=np.array([255,128,128,255,255,255,255,0, 0,  102,0,  112,0,  0,  0,  56, 0,  68, 36,162,255])
    xsize=np.arange(np.size(r))
    r = r/255.
    g = g/255.
    b = b/255.
    red = []
    green = []
    blue = []
    for i in range(len(xsize)):
        xNorm=float(i)/(float(np.size(r))-1.0)
        red.append([xNorm,r[i],r[i]])
        green.append([xNorm,g[i],g[i]])
        blue.append([xNorm,b[i],b[i]])
    colorDict = {"red":red, "green":green, "blue":blue}
    cmap_t2m_coltbl = matplotlib.colors.LinearSegmentedColormap('CMAP_T2M_COLTBL',colorDict)
    return cmap_t2m_coltbl


def cmap_t850():
 # Create colormap for 850-mb equivalent potential temperature
    r=np.array([255,128,0,  70, 51, 0,  0,  0, 51, 255,255,255,255,255,171,128,128,96,201])
    g=np.array([0,  0,  0,  70, 102,162,225,92,153,255,214,153,102,0,  0,  0,  68, 96,201])
    b=np.array([255,128,128,255,255,255,162,0, 102,0,  112,0,  0,  0,  56, 0,  68, 96,201])
    xsize=np.arange(np.size(r))
    r = r/255.
    g = g/255.
    b = b/255.
    red = []
    green = []
    blue = []
    for i in range(len(xsize)):
        xNorm=float(i)/(float(np.size(r))-1.0)
        red.append([xNorm,r[i],r[i]])
        green.append([xNorm,g[i],g[i]])
        blue.append([xNorm,b[i],b[i]])
    colorDict = {"red":red, "green":green, "blue":blue}
    cmap_t850_coltbl = matplotlib.colors.LinearSegmentedColormap('CMAP_T850_COLTBL',colorDict)
    return cmap_t850_coltbl


def cmap_terra():
 # Create colormap for terrain height
 # Emerald green to light green to tan to gold to dark red to brown to light brown to white
    r=np.array([0,  152,212,188,127,119,186])
    g=np.array([128,201,208,148,34, 83, 186])
    b=np.array([64, 152,140,0,  34, 64, 186])
    xsize=np.arange(np.size(r))
    r = r/255.
    g = g/255.
    b = b/255.
    red = []
    green = []
    blue = []
    for i in range(len(xsize)):
        xNorm=float(i)/(float(np.size(r))-1.0)
        red.append([xNorm,r[i],r[i]])
        green.append([xNorm,g[i],g[i]])
        blue.append([xNorm,b[i],b[i]])
    colorDict = {"red":red, "green":green, "blue":blue}
    cmap_terra_coltbl = matplotlib.colors.LinearSegmentedColormap('CMAP_TERRA_COLTBL',colorDict)
    cmap_terra_coltbl.set_over(color='#E0EEE0')
    return cmap_terra_coltbl


def extrema(mat,mode='wrap',window=100):
    # find the indices of local extrema (max only) in the input array.
    mx = ndimage.filters.maximum_filter(mat,size=window,mode=mode)
    # (mat == mx) true if pixel is equal to the local max
    return np.nonzero(mat == mx)

def __copy__(self):
    #Create new object with the same class and update attributes
    #If object is initialized, copy the elements of _lut list
    cls = self.__class__
    newCMapObj = cls.__new__(cls)
    newCMapObj.__dict__.update(self.__dict__)
    if self._isinit:
        newCMapObj._lut = np.copy(self._lut)
    return newCMapObj

#-------------------------------------------------------#

# Necessary to generate figs when not running an Xserver (e.g. via PBS)
plt.switch_backend('agg')

# Read date/time and forecast hour from command line
ymdh = str(sys.argv[1])
ymd = ymdh[0:8]
year = int(ymdh[0:4])
month = int(ymdh[4:6])
day = int(ymdh[6:8])
hour = int(ymdh[8:10])
cyc = str(hour).zfill(2)
print(year, month, day, hour)

fhr = int(sys.argv[2])
fhrm1 = fhr - 1
fhrm2 = fhr - 2
fhrm6 = fhr - 6
fhrm24 = fhr - 24
fhour = str(fhr).zfill(3)
fhour1 = str(fhrm1).zfill(3)
fhour2 = str(fhrm2).zfill(3)
fhour6 = str(fhrm6).zfill(3)
fhour24 = str(fhrm24).zfill(3)
print('fhour '+fhour)

# Forecast valid date/time
itime = ymdh
vtime = ncepy.ndate(itime,int(fhr))
print(vtime)
vymd = vtime[0:8]
vyear = int(vtime[0:4])
vmonth = int(vtime[4:6])
vday = int(vtime[6:8])
vhour = int(vtime[8:10])
vcyc = str(hour).zfill(2)

# Define the input files
data1 = grib2io.open(sys.argv[4]+'/gfs/'+ymd+cyc+'/gfs.v16.'+ymd+'.t'+cyc+'z.pgrb2.0p25.f'+fhour+'.grb2')
data2 = grib2io.open(sys.argv[4]+'/gfs/'+ymd+cyc+'/gfs.v17.'+ymd+'.t'+cyc+'z.pgrb2.0p25.f'+fhour+'.grb2')
#data2 = grib2io.open(sys.argv[4]+'/analyses/gfs.'+vymd+'.t'+vcyc+'z.pgrb2.0p25.anl.grb2')
data4 = grib2io.open(sys.argv[4]+'/analyses/gfs.'+vymd+'.t'+vcyc+'z.pgrb2.0p25.anl.grb2')

#print(data1[1])
msg = data1[1][0] 	# msg is a Grib2Message object

case = str(sys.argv[5])
counter = str(sys.argv[6])

# Get the lats and lons
lats = []
lons = []
lats_shift = []
lons_shift = []

# Unshifted grid for contours and wind barbs
lat, lon = msg.latlons()
lats.append(lat)
lons.append(lon)

#print("Before grid shift for pcolormesh") 
# Shift grid for pcolormesh
#lat1 = msg.latitudeFirstGridpoint
#lon1 = msg.longitudeFirstGridpoint
#nx = msg.nx
#ny = msg.ny
#dx = msg.gridlengthXDirection
#dy = msg.gridlengthYDirection
#print(msg.projparams)
#pj = pyproj.Proj(msg.projparams)
#llcrnrx, llcrnry = pj(lon1,lat1)
#llcrnrx = llcrnrx - (dx/2.)
#llcrnry = llcrnry - (dy/2.)
#x = llcrnrx + dx*np.arange(nx)
#y = llcrnry + dy*np.arange(ny)
#x,y = np.meshgrid(x,y)
#lon, lat = pj(x, y, inverse=True)
#lats_shift.append(lat)
#lons_shift.append(lon)
#print("After grid shift for pcolormesh")

# Unshifted lat/lon arrays grabbed directly using latlons() method
lat = lats[0]
lon = lons[0]

# Shifted lat/lon arrays for pcolormesh
#lat_shift = lats_shift[0]
#lon_shift = lons_shift[0]
lat_shift = lat
lon_shift = lon

# Specify plotting domains
str = str(sys.argv[3])
domains = str.split(',')
print(domains)

###################################################
# Read in all variables and calculate differences #
###################################################
t1a = time.perf_counter()

# MSLP
slp_1 = data1.select(shortName='PRMSL',level='mean sea level')[0].data() * 0.01
slp_2 = data2.select(shortName='PRMSL',level='mean sea level')[0].data() * 0.01
slp_4 = data4.select(shortName='PRMSL',level='mean sea level')[0].data() * 0.01
slp_dif_fcst = slp_2 - slp_1
slp_dif_anl = slp_2 - slp_4

#print(slp_1)

t2a = time.perf_counter()
t3a = round(t2a-t1a, 3)
print(("%.3f seconds to read all messages") % t3a)

# colors for difference plots, only need to define once
#difcolors = ['blue','#1874CD','dodgerblue','deepskyblue','turquoise','paleturquoise','white','white','#EEEE00','#EEC900','darkorange','orangered','red','firebrick']
difcolors = ['#094296','#0f66a8','#158ec2','#42b3e3','#79d5fc','#b0e7ff','white','white','#ffea94','#fcc75b','#fca22b','#f76931','#f73a25','#b02d1e']
difcolors2 = ['white']
difcolors3 = ['blue','dodgerblue','turquoise','white','white','#EEEE00','darkorange','red']

########################################
#    START PLOTTING FOR EACH DOMAIN    #
########################################

def main():

  # Number of processes must coincide with the number of domains to plot
#  pool = multiprocessing.Pool(len(domains))
  pool = MyPool(len(domains))
  pool.map(plot_all,domains)

def plot_all(domain):

  global dom
  dom = domain
  print(('Working on '+dom))

  global fig,axes,ax1,ax2,ax3,ax4,keep_ax_lst_1,keep_ax_lst_2,keep_ax_lst_3,keep_ax_lst_4,xextent,yextent,im,par,transform
  fig,axes,ax1,ax2,ax3,ax4,keep_ax_lst_1,keep_ax_lst_2,keep_ax_lst_3,keep_ax_lst_4,xextent,yextent,im,par,transform = create_figure()

  # Split plots into 2 sets with multiprocessing
  sets = [1]
  pool2 = multiprocessing.Pool(len(sets))
  pool2.map(plot_sets,sets)

def create_figure():

  # Map corners for each domain
  if dom == 'conus':
    llcrnrlon = -125.5
    llcrnrlat = 20.0 
    urcrnrlon = -63.5
    urcrnrlat = 51.0
    cen_lat = 35.4
    cen_lon = -97.6
    xextent=-2500000
    yextent=-840000
  elif dom == 'northeast':
    llcrnrlon = -81.0
    llcrnrlat = 39.497
    urcrnrlon = -66.5
    urcrnrlat = 48.0
    cen_lat = 44.0
    cen_lon = -76.0
    xextent=-265000
    yextent=-332791
  elif dom == 'midatlantic':
    llcrnrlon = -85.5
    llcrnrlat = 33.6
    urcrnrlon = -72.25
    urcrnrlat = 42.3
    cen_lat = 38.0
    cen_lon = -79.0
    xextent=-440000
    yextent=-312500
  elif dom == 'southeast':
    llcrnrlon = -92.25
    llcrnrlat = 24.0
    urcrnrlon = -76.0
    urcrnrlat = 35.315
    cen_lat = 29.0
    cen_lon = -88.0
    xextent=-221000
    yextent=-342500
  elif dom == 'ohiovalley':
    llcrnrlon = -95.75
    llcrnrlat = 33.6
    urcrnrlon = -81.75
    urcrnrlat = 42.779
    cen_lat = 37.0
    cen_lon = -89.0
    xextent=-455000
    yextent=-192000
  elif dom == 'midwest':
    llcrnrlon = -98.75
    llcrnrlat = 38.5
    urcrnrlon = -80.75
    urcrnrlat = 49.28
    cen_lat = 40.0
    cen_lon = -91.5
    xextent=-422500
    yextent=52500
  elif dom == 'southcentral':
    llcrnrlon = -108.25
    llcrnrlat = 24.027
    urcrnrlon = -90.0
    urcrnrlat = 37.25
    cen_lat = 29.0
    cen_lon = -98.0
    xextent=-817500
    yextent=-287000
  elif dom == 'centralplains':
    llcrnrlon = -108.25
    llcrnrlat = 34.490
    urcrnrlon = -92.75
    urcrnrlat = 44.5
    cen_lat = 38.0
    cen_lon = -100.0
    xextent=-567500
    yextent=-185000
  elif dom == 'northernplains':
    llcrnrlon = -111.0
    llcrnrlat = 40.425
    urcrnrlon = -95.5
    urcrnrlat = 49.5
    cen_lat = 45.0
    cen_lon = -102.0
    xextent=-586000
    yextent=-324500
  elif dom == 'northwest':
    llcrnrlon = -128.5
    llcrnrlat = 40.0
    urcrnrlon = -111.0
    urcrnrlat = 50.375
    cen_lat = 44.0
    cen_lon = -119.0
    xextent=-610000
    yextent=-228000
  elif dom == 'southwest':
    llcrnrlon = -127.75
    llcrnrlat = 30.0
    urcrnrlon = -108.95
    urcrnrlat = 42.559
    cen_lat = 35.0
    cen_lon = -116.0
    xextent=-899000
    yextent=-302000
  elif dom == 'northamerica':
    llcrnrlon = -145.0
    llcrnrlat = 7.0
    urcrnrlon = -55.0
    urcrnrlat = 72.0
    cen_lat = 40.0
    cen_lon = -100.0
    xextent=-4139000
    yextent=-2125000



  # create figure and axes instances
  im = image.imread('/lfs/h2/emc/vpppg/noscrub/Alicia.Bentley/python/noaa.png')
  par = 1

  # Define where Cartopy maps are located
  cartopy.config['data_dir'] = '/lfs/h2/emc/vpppg/noscrub/Alicia.Bentley/python/NaturalEarth'

  back_res='50m'
  back_img='off'

  # set up the map background with cartopy
  if dom == 'conus':
    fig = plt.figure(figsize=(9,7))
    gs = GridSpec(18,18,wspace=0.0,hspace=0.0)
    extent = [llcrnrlon-1,urcrnrlon-6,llcrnrlat,urcrnrlat+1]
    myproj=ccrs.LambertConformal(central_longitude=cen_lon, central_latitude=cen_lat,
            false_easting=0.0,false_northing=0.0, secant_latitudes=None,
            standard_parallels=None,globe=None)
    ax1 = fig.add_subplot(gs[0:9,0:9], projection=myproj)
    ax2 = fig.add_subplot(gs[0:9,9:], projection=myproj)
    ax3 = fig.add_subplot(gs[9:,0:9], projection=myproj)
    ax4 = fig.add_subplot(gs[9:,9:], projection=myproj)
  elif dom == 'northamerica':
    fig = plt.figure(figsize=(8,8))
    gs = GridSpec(19,18,wspace=0.0,hspace=0.0)
    extent = [llcrnrlon,urcrnrlon,llcrnrlat,urcrnrlat]
    myproj=ccrs.LambertConformal(central_longitude=cen_lon, central_latitude=cen_lat,
            false_easting=0.0,false_northing=0.0, secant_latitudes=None,
            standard_parallels=None,globe=None)
    ax1 = fig.add_subplot(gs[0:9,0:9], projection=myproj)
    ax2 = fig.add_subplot(gs[0:9,9:], projection=myproj)
    ax3 = fig.add_subplot(gs[4:,0:9], projection=myproj)
    ax4 = fig.add_subplot(gs[4:,9:], projection=myproj)
  else:
    fig = plt.figure(figsize=(8,8))
    gs = GridSpec(19,18,wspace=0.0,hspace=0.0)
    extent = [llcrnrlon,urcrnrlon,llcrnrlat,urcrnrlat]
    myproj=ccrs.LambertConformal(central_longitude=cen_lon, central_latitude=cen_lat,
            false_easting=0.0,false_northing=0.0, secant_latitudes=None,
            standard_parallels=None,globe=None)
    ax1 = fig.add_subplot(gs[0:9,0:9], projection=myproj)
    ax2 = fig.add_subplot(gs[0:9,9:], projection=myproj)
    ax3 = fig.add_subplot(gs[9:,0:9], projection=myproj)
    ax4 = fig.add_subplot(gs[9:,9:], projection=myproj)      
#  else:
#    fig = plt.figure(figsize=(8,8))
#    gs = GridSpec(19,18,wspace=0.0,hspace=0.0)
#    extent = [llcrnrlon,urcrnrlon,llcrnrlat,urcrnrlat]
#    myproj=ccrs.LambertConformal(central_longitude=cen_lon, central_latitude=cen_lat,
#          false_easting=0.0,false_northing=0.0, secant_latitudes=None, 
#          standard_parallels=None,globe=None)
#    ax1 = fig.add_subplot(gs[0:9,0:9], projection=myproj)
#    ax2 = fig.add_subplot(gs[0:9,9:], projection=myproj)
#    ax3 = fig.add_subplot(gs[10:,0:9], projection=myproj)
#    ax4 = fig.add_subplot(gs[10:,9:], projection=myproj)

  ax1.set_extent(extent)
  ax2.set_extent(extent)
  ax3.set_extent(extent)
  ax4.set_extent(extent)
  axes = [ax1,ax2,ax3,ax4]

  fline_wd = 0.3  # line width
  fline_wd_lakes = 0.3  # line width
  falpha = 0.5    # transparency

  # natural_earth
#  land=cfeature.NaturalEarthFeature('physical','land',back_res,
#                    edgecolor='face',facecolor=cfeature.COLORS['land'],
#                    alpha=falpha)
  lakes=cfeature.NaturalEarthFeature('physical','lakes',back_res,
                    edgecolor='black',facecolor='none',
                    linewidth=fline_wd_lakes,zorder=1)
  coastlines=cfeature.NaturalEarthFeature('physical','coastline',
                    back_res,edgecolor='black',facecolor='none',
                    linewidth=fline_wd,zorder=1)
  states=cfeature.NaturalEarthFeature('cultural','admin_1_states_provinces',
                    back_res,edgecolor='black',facecolor='none',
                    linewidth=fline_wd,zorder=1)
  borders=cfeature.NaturalEarthFeature('cultural','admin_0_countries',
                    back_res,edgecolor='black',facecolor='none',
                    linewidth=fline_wd,zorder=1)

  # All lat lons are earth relative, so setup the associated projection correct for that data
  transform = ccrs.PlateCarree()

  # high-resolution background images
  if back_img=='on':
    img = plt.imread('/lfs/h2/emc/vpppg/noscrub/Alicia.Bentley/python/NaturalEarth/raster_files/NE1_50M_SR_W.tif')
    ax1.imshow(img, origin='upper', transform=transform)
    ax2.imshow(img, origin='upper', transform=transform)
    ax3.imshow(img, origin='upper', transform=transform)
    ax4.imshow(img, origin='upper', transform=transform)

#  ax1.add_feature(lakes)
#  ax1.add_feature(states)
#  ax1.add_feature(borders)
#  ax1.add_feature(coastlines)
  ax1.add_feature(cfeature.LAND.with_scale('50m'),facecolor='lightgray',edgecolor='face') #Fill continents
  ax1.add_feature(cfeature.LAKES.with_scale('50m'),facecolor='lightblue',edgecolor='face') #Fill lakes
  ax1.add_feature(cfeature.STATES.with_scale('50m'),linewidths=0.3,linestyle='solid',edgecolor='k',zorder=4)
  ax1.add_feature(cfeature.BORDERS.with_scale('50m'),linewidths=0.5,linestyle='solid',edgecolor='k',zorder=4)
  ax1.add_feature(cfeature.COASTLINE.with_scale('50m'),linewidths=0.6,linestyle='solid',edgecolor='k',zorder=4)
#  ax2.add_feature(lakes)
#  ax2.add_feature(states)
#  ax2.add_feature(borders)
#  ax2.add_feature(coastlines)
  ax2.add_feature(cfeature.LAND.with_scale('50m'),facecolor='lightgray',edgecolor='face') #Fill continents
  ax2.add_feature(cfeature.LAKES.with_scale('50m'),facecolor='lightblue',edgecolor='face') #Fill lakes
  ax2.add_feature(cfeature.STATES.with_scale('50m'),linewidths=0.3,linestyle='solid',edgecolor='k',zorder=4)
  ax2.add_feature(cfeature.BORDERS.with_scale('50m'),linewidths=0.5,linestyle='solid',edgecolor='k',zorder=4)
  ax2.add_feature(cfeature.COASTLINE.with_scale('50m'),linewidths=0.6,linestyle='solid',edgecolor='k',zorder=4)
#  ax3.add_feature(lakes)
#  ax3.add_feature(states)
#  ax3.add_feature(borders)
#  ax3.add_feature(coastlines)
  ax3.add_feature(cfeature.LAND.with_scale('50m'),facecolor='lightgray',edgecolor='face') #Fill continents
  ax3.add_feature(cfeature.LAKES.with_scale('50m'),facecolor='lightblue',edgecolor='face') #Fill lakes
  ax3.add_feature(cfeature.STATES.with_scale('50m'),linewidths=0.3,linestyle='solid',edgecolor='k',zorder=4)
  ax3.add_feature(cfeature.BORDERS.with_scale('50m'),linewidths=0.5,linestyle='solid',edgecolor='k',zorder=4)
  ax3.add_feature(cfeature.COASTLINE.with_scale('50m'),linewidths=0.6,linestyle='solid',edgecolor='k',zorder=4)
#  ax4.add_feature(lakes)
#  ax4.add_feature(states)
#  ax4.add_feature(borders)
#  ax4.add_feature(coastlines)
  ax4.add_feature(cfeature.LAND.with_scale('50m'),facecolor='lightgray',edgecolor='face') #Fill continents
  ax4.add_feature(cfeature.LAKES.with_scale('50m'),facecolor='lightblue',edgecolor='face') #Fill lakes
  ax4.add_feature(cfeature.STATES.with_scale('50m'),linewidths=0.3,linestyle='solid',edgecolor='k',zorder=4)
  ax4.add_feature(cfeature.BORDERS.with_scale('50m'),linewidths=0.5,linestyle='solid',edgecolor='k',zorder=4)
  ax4.add_feature(cfeature.COASTLINE.with_scale('50m'),linewidths=0.6,linestyle='solid',edgecolor='k',zorder=4)


  # Map/figure has been set up here, save axes instances for use again later
  keep_ax_lst_1 = ax1.get_children()[:]
  keep_ax_lst_2 = ax2.get_children()[:]
  keep_ax_lst_3 = ax3.get_children()[:]
  keep_ax_lst_4 = ax4.get_children()[:]


  return fig,axes,ax1,ax2,ax3,ax4,keep_ax_lst_1,keep_ax_lst_2,keep_ax_lst_3,keep_ax_lst_4,xextent,yextent,im,par,transform


def plot_sets(set):
# Add print to see if dom is being passed in
  print(('plot_sets dom variable '+dom))

  global fig,axes,ax1,ax2,ax3,ax4,keep_ax_lst_1,keep_ax_lst_2,keep_ax_lst_3,keep_ax_lst_4,xextent,yextent,im,par,transform

  if set == 1:
    plot_set_1()
  elif set == 2:
    plot_set_2()
  elif set == 3:
    plot_set_3()

def plot_set_1():
  global fig,axes,ax1,ax2,ax3,ax4,keep_ax_lst_1,keep_ax_lst_2,keep_ax_lst_3,keep_ax_lst_4,xextent,yextent,im,par,transform


#################################
# Plot PRMSL
#################################
  t1dom = time.perf_counter()
  t1 = time.perf_counter()
  print(('Working on slp for '+dom))

  # Wind barb density settings
  if dom == 'conus':
    skip = 100
    thick = 0.75
  elif dom == 'northamerica':
    skip = 40
    thick = 0.6
  else:
    skip = 40
    thick = 1.0
  barblength = 3.5

  units = 'mb'
  clevs = [972,976,980,984,988,992,996,1000,1004,1008,1012,1016,1020,1024,1028,1032,1036,1040,1044,1048,1052]
  clevs_thin = [976,984,992,1000,1008,1016,1024,1032,1040,1048]
  clevsdif = [-14,-12,-10,-8,-6,-4,-2,0,2,4,6,8,10,12,14]
  cm = plt.cm.Spectral_r
  cm1 = copy.copy(cm)
  cm2 = copy.copy(cm)
  cm3 = copy.copy(cm)
  cm4 = copy.copy(cm)
  cmdif = matplotlib.colors.ListedColormap(difcolors)
  norm = matplotlib.colors.BoundaryNorm(clevs, cm.N)
  normdif = matplotlib.colors.BoundaryNorm(clevsdif, cmdif.N)

  xmin, xmax = ax1.get_xlim()
  ymin, ymax = ax1.get_ylim()
  xmax = int(round(xmax))
  ymax = int(round(ymax))

  cs_1 = ax1.pcolormesh(lon_shift,lat_shift,slp_1,vmin=5,norm=norm,transform=transform,cmap=cm1,zorder=2)
  cs_1.cmap.set_under('darkblue')
  cs_1.cmap.set_over('darkred')
  cs_1b = ax1.contour(lon_shift,lat_shift,slp_1,np.arange(940,1060,4),colors='black',linewidths=thick,transform=transform,zorder=3)
  cbar1 = plt.colorbar(cs_1,ax=ax1,orientation='horizontal',pad=0.01,ticks=clevs_thin,shrink=0.8,extend='both')
#  cbar1.set_label(units,fontsize=6)
  cbar1.ax.tick_params(labelsize=6)
  ax1.text(.5,1.03,'GFSv16 MSLP ('+units+') \n Initialized: '+itime+' Valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax1.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))
  ax1.imshow(im,aspect='equal',alpha=0.5,origin='upper',extent=(xmin,xextent,ymin,yextent),zorder=5)

  cs_2 = ax2.pcolormesh(lon_shift,lat_shift,slp_2,vmin=5,norm=norm,transform=transform,cmap=cm2,zorder=2)
  cs_2.cmap.set_under('darkblue')
  cs_2.cmap.set_over('darkred')
  cs_2b = ax2.contour(lon_shift,lat_shift,slp_2,np.arange(940,1060,4),colors='black',linewidths=thick,transform=transform,zorder=3)
  cbar2 = plt.colorbar(cs_2,ax=ax2,orientation='horizontal',pad=0.01,ticks=clevs_thin,shrink=0.8,extend='both')
#  cbar2.set_label(units,fontsize=6)
  cbar2.ax.tick_params(labelsize=6)
  ax2.text(.5,1.03,'GFSv17 MSLP ('+units+') \n Initialized: '+itime+' Valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax2.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))
  ax2.imshow(im,aspect='equal',alpha=0.5,origin='upper',extent=(xmin,xextent,ymin,yextent),zorder=5)

#  cs_3 = ax3.pcolormesh(lon_shift,lat_shift,slp_3,vmin=5,norm=norm,transform=transform,cmap=cm3,zorder=2)
  cs_3 = ax3.pcolormesh(lon_shift,lat_shift,slp_dif_fcst,transform=transform,cmap=cmdif,norm=normdif,zorder=2)
  cs_3.cmap.set_under('darkblue')
  cs_3.cmap.set_over('darkred')
  cbar3 = plt.colorbar(cs_3,ax=ax3,orientation='horizontal',pad=0.01,ticks=clevsdif,shrink=0.8,extend='both')
#  cbar3.set_label(units,fontsize=6)
  cbar3.ax.tick_params(labelsize=6)
  ax3.text(.5,1.03,'GFSv17 - GFSv16 MSLP ('+units+') \n Initialized: '+itime+' Valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax3.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))
  ax3.imshow(im,aspect='equal',alpha=0.5,origin='upper',extent=(xmin,xextent,ymin,yextent),zorder=5)

  cs_4 = ax4.pcolormesh(lon_shift,lat_shift,slp_dif_anl,transform=transform,cmap=cmdif,norm=normdif,zorder=2)
#  cs_4.cmap.set_under('gray')
#  cs_4.cmap.set_over('gray')
  cs_4b = ax4.contour(lon_shift,lat_shift,slp_4,np.arange(940,1060,4),colors='black',linewidths=thick,transform=transform,zorder=3)
  cbar4 = plt.colorbar(cs_4,ax=ax4,orientation='horizontal',pad=0.01,ticks=clevsdif,shrink=0.8,extend='both')
#  cbar4.set_label(units,fontsize=6)
  cbar4.ax.tick_params(labelsize=6)
  ax4.text(.5,1.03,'GFSv17 - GFS Anl. (fill), GFS Anl. (contour) MSLP ('+units+') \n Valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax4.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))
  ax4.imshow(im,aspect='equal',alpha=0.5,origin='upper',extent=(xmin,xextent,ymin,yextent),zorder=5)


  plt.savefig('gfs_'+dom+'_slp_'+case+'_'+counter+'.png', format='png', bbox_inches='tight', dpi=300)
#  compress_and_save('comparerefc_'+dom+'_f'+fhour+'.png')
  t2 = time.perf_counter()
  t3 = round(t2-t1, 3)
  print(('%.3f seconds to plot MSLP for: '+dom) % t3)



#  t3dom = round(t2-t1dom, 3)
#  print(("%.3f seconds to plot all set 1 variables for: "+dom) % t3dom)
  plt.clf()


################################################################################

main()

