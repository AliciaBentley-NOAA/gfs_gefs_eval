#!/usr/bin/env python

import numpy as np
import datetime as dt
import time, os, sys, subprocess
from datetime import datetime, timedelta

DIR = os.getcwd()

valid = str(sys.argv[1])
YYYY = int(valid[0:4])
MM   = int(valid[4:6])
DD   = int(valid[6:8])
HH   = int(valid[8:10])
date_str = datetime(YYYY,MM,DD,HH)
#print(date_str)

fhrb = int(sys.argv[2])
fhre = int(sys.argv[3])
step = int(sys.argv[4])
case = str(sys.argv[5])
fhrs = np.arange(fhrb,int((fhre)+(step)),step)
#print(fhrs)

valid_list = [date_str - dt.timedelta(hours = int(x)) for x in fhrs]

f = open(DIR+'/'+case+'_init_dates.txt',"w+")

for k in range(len(valid_list)):
    if (fhrs[k] < 10):
        fhr_new = "00"+str(fhrs[k])
    elif ((fhrs[k] > 10) and (fhrs[k] < 100)):
        fhr_new = "0"+str(fhrs[k])
    elif (fhrs[k] >= 100):
        fhr_new = str(fhrs[k])
    f.write(valid_list[k].strftime("%Y%m%d%H")+fhr_new+" \n")

f.close()
