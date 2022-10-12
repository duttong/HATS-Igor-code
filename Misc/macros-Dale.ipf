#pragma rtGlobals=1		// Use modern global access method.
#include <remove points>

function TimeMatchData(wv1,wv2,wv3,wv4, tol,meth)

wave wv1	// target timestamps (write output data at these timestamps)
wave wv2	// time wave of input data
wave wv3	// input data wave
wave wv4	// OUTPUT:  data wave based on target timestamps (wv1)
variable tol  // data gap tolerance (in seconds) for match to occur (> tol will not be written to output wave)
variable meth // method for time stamp matching:  0=closest timestamp; 1=closest timestamp before; 2=closest timestamp after; 3=interpolated

make /o time2
variable inc, inc1
string str1

make /o/n=(numpnts(wv1)) xyz = nan
duplicate /o xyz wv4

if(meth==3)  // Linear interpolation method
	wavestats /q wv1
	if(V_numnans > 0)
		print "You must first remove all NaNs from the target timestamp wave"
	else
		duplicate /o wv1 time2   // make bogus output x wave because it gets slightly messed up
	
		sprintf str1, "interpolate2 /A=0/J=0/T=1/I=3 /X=%s /Y=%s  %s, %s", nameofwave(time2), nameofwave(wv4), nameofwave(wv2), nameofwave(wv3)
		execute(str1)
	
		// Toss interpolated data that are outside of input data time range
		wavestats /q wv2	
		wv4 = selectnumber(((wv1>=V_min)*(wv1<=V_max)),nan,wv4)
	
		duplicate /o wv2 time1 revtime1 
		extract /o wv2, time1, ((numtype(wv2) != 2) * (numtype(wv3) != 2))	// input time wave rid of both time and data nans
		reversewave(time1, revtime1)								// reverse input time wave rid of nans
	
		inc = firstpoint(wv1); inc1 = lastpoint(wv1)
		do
			if(numtype(wv1[inc])!=2)		// Don't try to match data to missing target timestamps
				if(abs(time1[binarysearch(time1, wv1[inc])] - revtime1[binarysearch(revtime1, wv1[inc])]) >  tol)	   // diff between understamp (with data) and target timestamp
					wv4[inc]=nan
				endif
			else
				wv4[inc]=nan		// assign missing target timestamps data = NaN
			endif			
			inc += 1
		while (inc <= inc1)
		killwaves xyz, time1, time2, revtime1
	endif
endif

if(meth< 3)   // Non-interpolation methods
	duplicate /o wv2 time1 revtime1
	duplicate /o wv3 data1 revdata1
	
	// Create input data and time waves (and their reverse waves) without NaNs and times outside of the target time range
	extract /o wv2, time1, ((numtype(wv2) != 2) * (numtype(wv3) != 2))
	extract /o wv3, data1, ((numtype(wv2) != 2) * (numtype(wv3) != 2))
	reversewave(time1, revtime1)
	reversewave(data1, revdata1)		// reverse input time and data waves
	
	inc = firstpoint(wv1); inc1 = lastpoint(wv1)
	do	
		wavestats /q wv2
		if((numtype(wv1[inc])!=2) * (wv1[inc]>= V_min) * (wv1[inc]<= V_max))  // Don't try to match data to missing target timestamps or outside data time range
			if(meth==1)
				if(abs(time1[binarysearch(time1,wv1[inc])] - wv1[inc]) <= tol)	// does understamp pass tolerance test?
					wv4[inc]=data1[binarysearch(time1,wv1[inc])]
				endif
			endif	
	
			if(meth==2)
				if(abs(revtime1[binarysearch(revtime1,wv1[inc])] - wv1[inc]) <= tol)	// does overstamp pass tolerance test?	
					wv4[inc]=revdata1[binarysearch(revtime1,wv1[inc])]
				endif		
			endif
	
			if(meth==0)		// test for understamp time diff less than or equal to overstamp time diff
				if((abs(time1[binarysearch(time1,wv1[inc])] - wv1[inc])) <= (abs(revtime1[binarysearch(revtime1,wv1[inc])] - wv1[inc])))  
					if(abs(time1[binarysearch(time1,wv1[inc])] - wv1[inc]) <= tol)   // does understamp pass tolerance test?	
						wv4[inc]=data1[binarysearch(time1,wv1[inc])]
					endif				
				endif
								// test for overstamp time diff less than understamp time diff
				if((abs(time1[binarysearch(time1,wv1[inc])] - wv1[inc])) > (abs(revtime1[binarysearch(revtime1,wv1[inc])] - wv1[inc])))
					if(abs(revtime1[binarysearch(revtime1,wv1[inc])] - wv1[inc]) <= tol)   // does overstamp pass tolerance test?	
						wv4[inc]=revdata1[binarysearch(revtime1,wv1[inc])]
					endif				
				endif
			endif	
		endif
		inc += 1
	while (inc <= inc1)

	killwaves  xyz, time1, revtime1, data1, revdata1
endif
end

function TimeMatchDataOld(wv1,wv2,wv3,wv4, tol)

wave wv1	// time wave for output data wave (match data to these timestamps)
wave wv2	// time wave of data
wave wv3	// data wave
wave wv4	// OUTPUT:  data wave synched to wv1 timestamps
variable tol  // data gap tolerance (in seconds) for interpolation to occur (>tol will not be interpolated)

variable inc=0
variable inc1=lastpoint(wv1)

duplicate /o wv1 time1; time1=nan
duplicate /o wv1 index; index=nan
duplicate /o wv1 revtime1; revtime1=nan
duplicate /o wv1 revindex; revindex=nan

duplicate /o wv3 revtime revdata

wavestats /q wv2
if(V_numnans >0)
	print "There can't be any NaNs in the timestamp wave for the data to be interpolated.  You must first remove them and the associated data points"
else

	make /o/d/n=(numpnts(wv1)) xyz=nan
	duplicate /o xyz wv4
	
	//  Find timestamps in wv2 that are closest to wv1
	
	time1=wv2[binarysearch(wv2,wv1)]   // Timestamps in wv2 closest to, but not greater than wv1 timesmaps ("understamps")
	index=binarysearch(wv2,wv1)		// Indices of timestamps in wv2 closest to, but not greater than wv1 timesmaps
	
	reversewave(wv2, revtime)		// reverse the order of timestamps in wv2 (for descending binary search)
	reversewave(wv3, revdata)			// reverse the data ....
	
	revtime1=revtime[binarysearch(revtime,wv1)]   // Timestamps in wv2 closest to, but not less than than wv1 timesmaps ("overstamps")
	revindex=binarysearch(revtime,wv1)		// Indices of timestamps in wv2 closest to, but not less than wv1 timesmaps	
	
	time1 = abs(time1-wv1)				// absolute value of difference between understamps and target timestamps
	revtime1 = abs(revtime1-wv1)		// absolute value of difference between overstamps and target timestamps
	
do	
	
	if(numtype(wv3[index[inc]])!=2)		// Is there is data for understamp?
		if((time1[inc] <= revtime1[inc]) * (time1[inc] < tol))   // Is the time difference less that for the overstamp and lower than the tolerance?
			wv4[inc]=wv3[index[inc]]
		endif
	endif

	if(numtype(revdata[revindex[inc]])!=2)		// Is there is data for overstamp?
		if((revtime1[inc]< time1[inc]) * (revtime1[inc] < tol))   // Is the time difference less that for the understamp and lower than the tolerance?
			wv4[inc]=revdata[revindex[inc]]
		endif		
	endif

	inc += 1
	while (inc<= inc1)


killwaves xyz, time1, index, revtime1, revindex, revtime, revdata
endif
end

function Match2DataSets(wv1,wv2,wv3,wv4, tol)

wave wv1	// Time Wave of lower temporal resolution data    (timetamps for output wave)
wave wv2	// Time Wave of higher temporal resolution data
wave wv3	// Higher temporal resolution data wave  (data for output data wave)
wave wv4	// OUTPUT:   Wave of data (wv3) at lower resolution timestamps (wv1)  
variable tol	// tolerance (+/-) for timestamp match (in timestamp units)

variable inc=0					//  counter for lower temp resolution data
variable inc1=lastpoint(wv1)
variable inc2=0				// counter for higher temp resolution data
variable inc3=lastpoint(wv2)
variable flag=0					// flag for timestamp match found
variable tolcntr = 0
wv4=nan

//wv1=round(wv1)		// round timestamps to nearest second
//wv2=round(wv2)

do
	if(flag==0)		// if no match was made for previous search
		inc2=0		// start next search at beginning of high res wave
	else
		flag=0		// reset flag, but leave inc2 where it was
	endif
	do
		tolcntr = 0		//  start with a tolerance of zero
		do
			if((abs(wv1[inc]-wv2[inc2]))<=(tolcntr))		// temporal match within tolerance found
				wv4[inc]=wv3[inc2]
				flag=1
			endif	
			tolcntr += 1
		while((tolcntr<= tol)*(flag==0))
		inc2 += 1
	while((inc2<=inc3)*(flag==0))
	inc+=1	
while(inc<=inc1)
end



function dispresp(wv, type)
wave wv
string type

display wv
if(cmpstr(type, "flight") == 0)
	ModifyGraph mode=3,marker=19,msize=2,zColor={selpos,0,1,BlueRedGreen}
else
	ModifyGraph mode=3,marker=19,msize=2,zColor={selpos,1,4,BlueRedGreen}
endif
end

function ConvertCalSelpos(wv, wv1)
wave wv	// selpos
wave wv1

end

function firstpoint(wv)	//RETURNS POINT NUMBER OF FIRST REAL DATA POINT IN A WAVE
	wave wv
	variable inc = 0
	do
		if (numtype(wv[inc]) != 2)
			return inc
		endif
		inc += 1
	while (inc < (numpnts(wv)-1))
	return numpnts(wv)
end

function lastpoint(wv)	//RETURNS POINT NUMBER OF LAST REAL DATA POINT IN A WAVE
	wave wv
	variable inc = numpnts(wv)-1
	do
		if (numtype(wv[inc]) != 2)
			return inc
		endif
		inc -= 1
	while (inc > 0)
	return 0
end

function MidChop(wv, value1,value2)	//NaNs values between low and high cutoffs
	wave wv
	variable value1  // low cutoff
	variable value2	// high cutoff
	variable n=numpnts (wv)
	do
		n-=1 
	 	
		if ((wv[n] >= value1) * (wv[n] <= value2))
			wv[n] = nan
		endif 	
	 while (n > 0) 
end

function PercentileOfWave (wv, inc)	//Calculates specified percentile of wave
	Wave wv
	variable inc		// percentile desired (0.00 to 1.00)
	variable result

	if((inc < 0) + (inc > 1))
		print "Percentile must be between 0 and 1"
		abort
	endif
	
	duplicate /o wv, tempMedianWave
	wavestats /q tempMedianWave
	variable incase1 = V_avg

	RemoveNaNs(tempMedianWave)
	
	
	Sort tempMedianWave, tempMedianWave
	SetScale /P x 0, 1, tempMedianWave
	result = tempMedianWave((numpnts(tempMedianWave)*inc)-(inc))

	if (exists("tempMedianWave") == 0)
		return incase1
	else
		return result
	endif
end

function SmartSum(wv1)	//RETURNS SUM OF ALL POINTS IN WAVE THAT ARE NOT NaN
wave wv1

variable inc=firstpoint(wv1)
variable inc1=0
do
	if(numtype(wv1[inc]) == 0)
		inc1 += wv1[inc]
	endif
inc += 1
while(inc <= lastpoint(wv1))
return inc1
end


function SmartSumLimits(wv1,inc2,inc3)	//RETURNS SUM OF ALL POINTS BETWEEN inc2 and inc3 THAT ARE NOT NaN
wave wv1
variable inc2, inc3
variable inc=0
variable inc1=0
do
	if((numtype(wv1[inc]) == 0) * (inc >= (inc2)))
		inc1 += wv1[inc]
	endif
inc += 1
while((inc <= lastpoint(wv1))*(inc <= inc3))
print inc
return inc1
end

function gettextwvpnt(wv, str)	// RETURNS THE FIRST POINT OF TEXT WAVE THAT MATCHES SPECIFIED STRING

wave /T wv
string str
variable inc=firstpoint(wv)
variable inc1=lastpoint(wv)
variable flag=0
do
	if(cmpstr(wv[inc],str)==0)
		flag=1
	else
		inc +=1
	endif
while((flag==0) * (inc <= inc1))
return inc
end


//COMPARES TWO WAVES FOR V_npnts, V_nans, total length, and point-by-point for data type agreement (e.g. NaN is NaN, Datum is datum) and numerical agreement within the specified tolerance (variable toler)

function CompTwoWvs(wv1, wv2, toler, verbose)

wave wv1
wave wv2
variable toler
variable verbose

variable inc=0, inc1=0, inc2=0
variable flag=0

wavestats /q wv1
inc=V_npnts; inc1=V_numnans; inc2=V_npnts+V_numnans

wavestats /q wv2
inc -= V_npnts; inc1-= V_numnans; inc2 -= (V_npnts+V_numnans)

if((inc2 !=0) * (flag==0))
	print "Waves  "+nameofwave(wv1)+" and "+nameofwave(wv2)+" are not matched in length"
	flag=1
endif
if((inc !=0) * (flag==0))
	print "Waves "+nameofwave(wv1)+" and "+nameofwave(wv2)+" are not matched in V_npnts"
	flag=1
endif
if((inc1 !=0) * (flag==0))
	print "Waves  "+nameofwave(wv1)+" and "+nameofwave(wv2)+" are not matched in V_numnans"
	flag=1
endif

if((((firstpoint(wv1)) != (firstpoint(wv2))) + ((lastpoint(wv1)) != (lastpoint(wv2)))) * (flag==0))
	print "First or Last Point of "+nameofwave(wv1)+" and "+nameofwave(wv2)+" do not match"
	flag=1
endif

inc = 0
wavestats /q wv1
inc1 = V_npnts+V_numnans

if (flag==0)
	do
		if(((numtype(wv1[inc])) != (numtype(wv2[inc])))*(flag==0))
			print "Data type mismatch between "+nameofwave(wv1)+" and "+nameofwave(wv2)+" at Point ",inc
			flag=1
		endif
	
		if((numtype(wv1[inc]) == 0) * (numtype(wv2[inc]) == 0)*(flag==0))
			if(abs(wv1[inc] - wv2[inc]) > toler)
				print "Numerical difference between "+nameofwave(wv1)+" and "+nameofwave(wv2)+" at Point ",inc
				flag=1
			endif
		endif
	
	inc += 1
	while (inc < inc1)
endif

if (verbose ==1)
	if (flag==0)
		print "No difference found between "+nameofwave(wv1)+" and "+nameofwave(wv2)
	endif
endif
end

//TWO WAVES (WV1, WV2) SAME LENGTH AS TIMESTAMP WAVE (WV3) ARE COMPARED FOR REAL DATA AT EACH TIMESTAMP.  INC1= #DATA POINTS IN WV1. INC2= #DATA POINTS IN WV2.  INC3= #DATA POINTS IN WV1 NOT IN WV2.  INC4= #DATA POINTS IN WV2 NOT IN WV1.
//WAVES TRASH1 AND TRASH2 = POINT NUMBERS AND TIMESTAMPS OF DATA POINTS IN WV1 NOT IN WV2. WAVES TRASH3 AND TRASH4 = POINT NUMBERS AND TIMESTAMPS OF DATA POINTS IN WV2 NOT IN WV1. 

function CompTimeStamps(wv1,wv2,wv3)

wave wv1
wave wv2
wave wv3
variable inc=0, inc1=0, inc2=0, inc3=0, inc4=0

make /o/n=170 trash1=nan
make /o/n=170 trash2=nan
make /o/n=170 trash3=nan
make /o/n=170 trash4=nan

wavestats /q wv1

do
	if(numtype(wv1[inc])==0)
		inc1 +=1
		if(numtype(wv2[inc])!=0)
			trash1[inc3]=inc
			trash2[inc3]=wv3[inc]
			inc3+=1
		endif
	endif
	
	if(numtype(wv2[inc])==0)
		inc2 +=1
		if(numtype(wv1[inc])!=0)
			trash3[inc4]=inc
			trash4[inc4]=wv3[inc]
			inc4+=1
		endif
	endif
	
	inc +=1
	
while (inc < (V_npnts + V_numnans))	

if ((inc3 != 0) + (inc4 != 0))
print nameofwave(wv1),",",inc1,",", inc2,",", inc3,",", inc4
endif

end


function MakeLocationLabelsLite(wv1, wv2)		//	DELETES POINTS IN NUMERIC TIME WAVE (WV1) AND TEXT WAVE (WV2) WHEN THERE IS NO DATUM IN WV2.  
//	HANDY FOR CREATING 'LABEL' WAVES FOR PLOTS (E.G. STATION NAME INDICATORS ON TROICA DATA TIMESERIES PLOTS).  
//	TO SHOW STATION NAMES ALONG X_AXIS: APPEND A BOGUS DATA WAVE VS WV1 TO A PLOT,  THEN CHANGE THE MARKERS TO TEXT FROM WV2.

wave wv1
wave /T wv2
variable inc=0, inc1=0, inc2=0
make /o trash = nan

wavestats /q wv1
inc1=(V_npnts+V_numnans)
inc2=numpnts(wv2)
do
	if (cmpstr(wv2[inc], "") == 0)
		wv1[inc]=nan
	endif
	inc += 1
while (inc < inc2)

DeletePoints inc, (inc1+1-inc), wv1

wavestats /q wv1
inc=0;inc1=0;inc2=V_npnts

do
	if (numtype(wv1[inc]) != 2)
		trash[inc1]=inc
		inc1 += 1
	endif
	inc +=1
 while(inc1 < inc2)	

wavestats /q trash
inc=V_npnts-2

do
	Deletepoints (trash[inc]+1), (trash[inc+1]-trash[inc]-1), wv1
	Deletepoints (trash[inc]+1), (trash[inc+1]-trash[inc]-1), wv2
	inc -=1
while (inc >= 0)

	Deletepoints 0, trash[0], wv1
	Deletepoints 0, trash[0], wv2
end


// WRITES NANS TO INTERPOLATED DATA WAVE IF ORIGINAL DATA WERE ABSENT
function nan_interp_timegaps(wv, wv1, wv2, wv3, wv4, crit)
wave wv	//  time base of data wave
wave wv1	//  data wave
wave wv2   //   interpolated data time wave
wave wv3	//  interpolated data wave 
wave wv4	// OUTPUT  interpolated data wave with gaps NAN
variable crit	//  time criteria for data gap that requires removal

variable inc=0
variable inc1= 0
variable inc2=lastpoint(wv)
variable inc3
variable flag=0

duplicate /o wv3 wv4
duplicate /o wv gapstart
duplicate /o wv gapend
gapstart=nan; gapend=nan
duplicate /o wv trash
trash=nan
duplicate /o wv trash1
trash1=nan
do
	inc=1
	if((numtype(wv[inc1])!=2)*(numtype(wv1[inc1])==2))		// find  first NAN data for an existing timestamp
		if(inc1==(firstpoint(wv)))					//  if first timestamp has NAN data
			gapstart[inc1]=wv[inc1]					// write that first timestamp of first NaN to gapstart			
		else												// if >first timestamp has NaN data
			gapstart[inc1]=wv[inc1-1]					// write timestamp of last number to gapstart
		endif
		flag=1											//  first NAN found
	endif

	if(flag==1)								// do only after first NAN was found	
		do
			if(numtype(wv1[inc1+inc])!=2)		// find first number after the NAN
				gapend[inc1]=wv[inc1+inc]		// write timestamp of first number after the NAN to gapend
				flag=0								//  move on and look for another first NAN	
				trash[inc1]=inc
				trash1[inc1]=inc1
			else
				inc+=1
				if((inc+inc1)>inc2)				// if end of wave has been reached
					if(wv[inc2]>=wv2[lastpoint(wv2)])	//  if last raw data timestamp >= last interp data timestamp
						gapend[inc1]=wv[inc2]		// write last raw data timestamp to gapend
					else
						gapend[inc1]=wv2[lastpoint(wv2)]		// else write last interp data timestamp to gapend
					endif
					flag=0							//  end of wave has been reached
				endif
			endif	
			
		while(flag==1)		//  stop looking for a  number if one has been found or end of wave has been reached
	endif

	inc1+=inc
while ((inc1)<=inc2)

duplicate /o gapend gap
gap -= gapstart
lowchop(gap, crit)
killnan4(gapstart, gapend, gap, gap)

wavestats /q gapstart

if(V_npnts > 0)
	inc=0				//  counters for gapstart and gapend waves
	inc1=V_npnts-1	//  counters for gapstart and gapend waves
	inc2=firstpoint(wv3)	// counters for interpolated data wave	
	inc3=lastpoint(wv3)	// counters for interpolated data wave

	do
		flag=0
		inc2=0
		do
			if(wv2[inc2]>=gapstart[inc])		// is the interpolated timestamp >= gapstart?
				if(wv2[inc2]<=gapend[inc])		// is the interpolated timestamp also <= gapend?
					wv4[inc2]=nan				//  then NaN the interpolated data point
				else	
					flag=1						// if the interpolated timestamp is >gap end, move on
				endif				
			endif
			inc2+=1
		while((inc2<=inc3)*(flag==0))
		inc+=1
	while(inc<=inc1)				// move to next gapstart-gapend pair
endif

inc=wv[firstpoint(wv1)]		// timestamps of first and last data in data wave
inc1=wv[lastpoint(wv1)]

duplicate /o wv2 trash
lowchop(trash, inc-0.00001)
highchop(trash,inc1+0.00001)

wv4 *= trash/trash

end





//Extracts numeric data from data wave at station name timestamps.  Wv1 is the very short stn_time wave (same length as stn_name text wave), Wv2 and Wv3 are long time and data waves.  Output wv4 is very short data wave.

function GetStnData(wv1,wv2,wv3, wv4)

wave wv1	// stn_time wave
wave wv2	// data time wave
wave wv3	// data wave
wave wv4	// output wave of data at station timestamp

variable inc=0, inc1=0, inc2=0
variable flag=0

duplicate /o wv1 wv4
wv4=nan

inc=firstpoint(wv1)

do

	do
		if (abs(wv1[inc]-wv2[inc1]) < 0.1)
			wv4[inc]=wv3[inc1]
			flag = 1
			inc +=1
		endif

	inc1 += 1
	
	while((inc1 <= lastpoint(wv3))*(flag==0))

while(inc <= lastpoint(wv1))

end



//ADDS DATA POINT FROM PREVIOUS DAY'S LAST TIMESTAMP TO BEGINNING OF CURRENT DAY'S DATA,
// AND ADDS DATA POINT FROM NEXT DAY'S FIRST TIMESTAMP TO END OF CURRENT DAY'S DATA.  THIS IS USEFUL WHEN CALCULATING MOVING OR WEIGHTED AVERAGES, 
//SO THAT FIRST AND LAST DATA POINTS IN FILE DON'T BECOME NAN FOR LACK OF BEFORE AND AFTER DATA.  CAN SUPPRESS DAY BEFORE OR DAY AFTER ADDITIONS BY 
//MAKING WV1=TEST OR WV3=TEST.

function MakeAltWaves(wv1,wv2,wv3,wv4)
 
wave wv1	// day before wave
wave wv2	// day of wave
wave wv3	// day after wave
wave wv4	// output alt wave
variable inc=0
variable inc1=0

duplicate /o wv2 wv4

wavestats /q wv2
inc = V_npnts+V_numnans

if (cmpstr(nameofwave(wv3), "test") !=0)
	Insertpoints inc, 1, wv4
	wv4[inc] = wv3[0]
endif

if (cmpstr(nameofwave(wv1), "test") !=0)
	wavestats /q wv1
	inc1 = V_npnts+V_numnans-1
	Insertpoints 0, 1, wv4
	wv4[0] = wv1[inc1]
endif

end

  
//COMPUTES WEIGHTED AVERAGE AT EACH TIMESTAMP (WV1) OF FASTER DATA (WV3)  WITH TIMESTAMPS (WV2).  
//GOOD FOR SYNCHING FASTER DATA WITH SLOWER (ACATS) DATA AT THE SLOWER TIMESTAMPS.  
//WEIGHTED AVERAGES ARE OF TWO FASTER TIMESTAMPS SURROUNDING SLOWER TIMESTAMPS THAT ARE BOTH LESS THAN 10 SECONDS AWAY FROM THE SLOWER TIMESTAMP. 
// WEIGHTINGS ARE INVERSE TIME FROM THE SLOWER TIMESTAMP.  THE OUTPUT WAVE IS SAME LENGTH AS THE SLOW TIMESTAMP WAVE (WV1).

function CompWtAvg(wv1,wv2,wv3, wv4)
 
 wave wv1        // time wave to sync to
 wave wv2        // time wave of raw data
 wave wv3        // wave of raw data
 wave wv4        // output wave
 
 variable inc=0, inc1=0, inc2=0, inc3=0
 variable flag=0

duplicate /o wv1 wv4
wv4 = nan

 wavestats /q wv1
 inc=V_npnts
 
wavestats /q wv2
inc2=V_npnts

do

flag=0
inc3=0

	do
		if (abs(wv2[inc3] - wv1[inc1]) < 0.1)    // exact time match with a little slop
			wv4[inc1]=wv3[inc3]
		endif
		
		if((abs(wv2[inc3] - wv1[inc1]) < 10) * (abs(wv2[inc3+1] - wv1[inc1]) < 10))	// time diffs < 10
			wv4[inc1]= wv3[inc3]*(10-(abs(wv2[inc3] - wv1[inc1])))/10 + wv3[inc3+1]*(10-(abs(wv2[inc3+1] - wv1[inc1])))/10
			flag=1
		endif
		
		inc3 += 1
	while ((inc3 < (inc2-1)) * (flag ==0))

	inc1 += 1
while (inc1 < inc)
 
end



// Geoff's convert date wave to decimal date wave in one line!

//F11decimalwave = (brw_F11_time / (Date2secs(Str2Num(StringFromList(2, Secs2Date(brw_F11_time, 3), ",")), 1, 1) / (Str2Num(StringFromList(2, Secs2Date(brw_F11_time, 3), ",")) -1904)) + 1904) - secs2decday(brw_F11_time)


//Geoff's elegant convert date wave to decimal date wave

//function /d secs2decday(secs)
	variable /d secs

	variable YYYY = Str2Num(StringFromList(2, Secs2Date(secs, 3), ","))
	variable MM = Str2Num(StringFromList(1, Secs2Date(secs, -1), "/"))
	variable DD = Str2Num(StringFromList(0, Secs2Date(secs, -1), "/"))
	variable HH = Str2Num(StringFromList(0, Secs2Time(secs, 3), ":"))
	variable MN = Str2Num(StringFromList(1, Secs2Time(secs, 3), ":"))
	variable SC = Str2Num(StringFromList(2, Secs2Time(secs, 3), ":"))
	variable LY = (mod(YYYY,4) == 0)
	variable day, daysInYear

	if (YYYY == 2000)
		LY = 0
	endif

	daysInYear = 365 + LY

	if (MM == 1)
		day = DD
	elseif (MM == 2)
		day = 31 + DD + LY
	elseif (MM == 3)
		day = 31 + 28 + DD + LY
	elseif (MM == 4)
		day = 31 + 28 + 31 + DD + LY
	elseif (MM == 5)
		day = 31 + 28 + 31 + 30 + DD + LY
	elseif (MM == 6)
		day = 31 + 28 + 31 + 30 + 31 + DD + LY
	elseif (MM == 7)
		day = 31 + 28 + 31 + 30 + 31 + 30 + DD + LY
	elseif (MM == 8)
		day = 31 + 28 + 31 + 30 + 31 + 30 + 31 + DD + LY
	elseif (MM == 9)
		day = 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + DD + LY
	elseif (MM == 10)
		day = 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + DD + LY
	elseif (MM == 11)
		day = 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + DD + LY
	elseif (MM == 12)
		day = 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30 + DD + LY
	endif

	//print YYYY, MM, DD, HH, MN, SC
	//print /d  day/(365 + LY)
	//print /d HH/(24 * (365 + LY))
	//print /d MN/(60 * 24 * (365 + LY))
	//print /d SC/(60 * 60 * 24 * (365 + LY))

	return YYYY + (day-1)/daysInYear + HH/(24 * daysInYear) + MN/(60 * 24 * daysInYear) + SC/(60 * 60 * 24 * daysInYear)

end


function flaglowconcs(wv1,wv2,crit)

wave wv1	 // XXX_concat_idl or XXX_concat_igor wave
wave wv2	//  XXX_flag_concat
variable crit	//  low criteria for flagging

variable inc=0
variable inc1=lastpoint(wv1)

do
	if((numtype(wv1[inc])!=2) * (wv1[inc] < crit))
		wv2[inc]=1
	endif
inc+=1
while(inc<=inc1)
end

function CombineWaves(wv1,wv2,wv3)
wave wv1	// data wave to "fill in"
wave wv2	// data wave will "fill in" data when no data in wv1
wave wv3	// output wave
variable inc=0
variable inc1=numpnts(wv1)-1

duplicate /o wv1 wv3
do
	if(numtype(wv1[inc])==2)
		wv3[inc]=wv2[inc]
	endif

inc+=1
while (inc <= inc1)

end




function makehghtconcwvs(wv,wv1,wv2, wv3,wv4, flt)

wave wv	// tsecs_yymmdd
wave wv1	// n2o_concat_XXX     XXX = idl or igor
wave wv2	// n2o_flag_concat
wave wv3	//  flightnum_concat
wave wv4	//  n2o_hght_conc_yymmdd

variable flt	// flt number

variable inc=0
variable inc1=lastpoint(wv1)
variable inc2=0
variable inc3=lastpoint(wv)

duplicate /o wv wv4
wv4=nan

do
	if(wv3[inc]==flt)
		if((numtype(wv1[inc])!=2) * (wv2[inc]!=1))
			wv4[inc2]=wv1[inc]
		endif
		inc2+=1
	endif
	inc += 1
while ((inc <= inc1)*(inc2 <= inc3))
end	



function makeextpresswaves(wv1, wv2, wv3)

wave wv1	//  tsecs_
wave wv2	//  xp_ext_press_
wave wv3	//  extpress_

variable inc=firstpoint(wv1)
variable inc1=lastpoint(wv1)

duplicate /o wv1 wv3
wv3=nan

do
	if(numtype(wv1[inc])!=2)
		wv3[inc]=wv2[x2pnt(wv2,wv1[inc])]
	endif


inc+=1
while (inc <= inc1)

end


function CalcDistanceFromLatLon(lat1,lon1,lat2,lon2)
variable lat1	// in degrees
variable lon1	
variable lat2
variable lon2

lat1 = pi*lat1/180		// conversion to radians
lon1 = pi*lon1/180	
lat2 = pi*lat2/180	
lon2 = pi*lon2/180	

variable dist=6378 * acos(sin(lat1)*sin(lat2) + cos(lat1)*cos(lat2)*cos(lon1-lon2))
return dist		// in km
end

function ReverseWave(wv,wv1)
wave wv  //  original wave
wave wv1  // output wave (reversed order)

variable inc=0
variable inc1=numpnts(wv)-1

duplicate /o wv wv1
wv1=nan

do

	wv1[inc1-inc]=wv[inc]
	inc +=1
while(inc <= inc1)
end

function GetDataDuringInterval(wv,wv1,wv2, wv3, wv4, wv5, wv6)
wave wv	// timestamps of data wave
wave wv1	// data wave
wave wv2	// intervals start time wave
wave wv3	// intervals stop time wave
wave wv4	// output: number of data points within each interval
wave wv5	// output: mean of data points within each interval
wave wv6	// output: std dev of data points within each interval

wave cosd_concat
make /o/n=(numpnts(wv2)) junk=nan
duplicate /o junk wv4 wv5 wv6

variable inc=0
variable inc1=lastpoint(wv2)

do
	duplicate /o wv1 junk; junk=nan
	junk = selectnumber((wv>=wv2[inc])*(wv<=wv3[inc]), nan, wv1)
		wavestats /q junk
		wv4[inc]=V_npnts
		wv5[inc]=V_avg
		wv6[inc]=V_sdev
	
inc += 1
while(inc <= inc1)
end


function TimeAverageData(wv,wv1,wv2,wv3,int, crit)  //  Centers the averaging periods at wv2 timestamps
wave wv	//  timestamps of data wave to average
wave wv1	//  data wave to average
wave wv2	//  timestamps that define averaging period
wave wv3	//  output wave of time-avearaged  data written at wv2 timestamps
variable int  //  time interval to average over
variable crit   //  threshold number of data points to compute average

variable inc = firstpoint(wv2)
variable inc1 = lastpoint(wv2)
variable lower
variable upper

duplicate /o wv2 wv3; wv3 = nan
//duplicate /o wv1 junk

do
	if(numtype(wv2[inc]) != 2)
		lower = binarysearch(wv, (wv2[inc]-int/2))+1      // index of  first point in range
		upper = binarysearch(wv, (wv2[inc]+int/2))		//  index of last point in range
		if((lower >= 0) * (upper >= 0))
			wavestats /q/R=[lower, upper]   wv1
			if(V_npnts >= crit)
				wv3[inc] = V_avg
			endif
		endif
	endif
inc += 1
while (inc <= inc1)
SetScale d 0,0,"", wv3

end


function FindMissingPoints(wv1, wv2)
wave wv1
wave wv2
variable inc=0
variable inc1 = numpnts(wv1)-1

if((numpnts(wv1))==(numpnts(wv2)))
	do
		if(numtype(wv1[inc])!=(numtype(wv2[inc])))
			print inc
		endif
	inc += 1
	while (inc <= inc1)
else
	print "The two waves must be matched in length"
endif
end


function PressCorrLongPathWater(wv,wv1,wv2)
wave wv	// Long Path Water Vapor Mixing Ratio
wave wv1	// Cell Pressure (mbar)
wave wv2	// OUTPUT:  corrected Long Path Water Vapor Mixing Ratio

// From Fred March 2008
//tdllh2oC= tdllh2o/(1.15-0.0008123*PC+ 5.283e-7*PC*PC) - 1.5

//variable a = 5.283e-7		// second order coefficient
//variable b = -0.0008123	// linear coefficient
//variable c = 1.15 			// intercept

// Long-Path Pressure correction from Dale March 26 2008    THIS WAS THE ONE USED!
//variable a = 5.372e-7		// second order coefficient
//variable b = -0.000757	// linear coefficient
//variable c = 1.135 			// intercept

// Long-Path Pressure correction from Dale June 6 2008
//variable a = 3.3914e-07		// second order coefficient
//variable b = -0.00054068	// linear coefficient
//variable c = 1.0943 			// intercept
//variable offset = -1.5		// zero correction  for cals A and B

// Long-Path Pressure correction from Dale November 25, 2008
variable a = 3.929e-7		// second order coefficient
variable b = -0.0006361	// linear coefficient
variable c = 1.124 			// intercept

duplicate /o wv wv2

wv2 *= 1/((a * (wv1)^2) + (b * wv1) + c )    // Pressure correction only

//lowchop(wv2, 0)
wv2 = round(wv2*10)/10
end

function TempCorrLongPathWater(wv1,wv2,wv3)
wave wv1	// Pressure corrected long path water
wave wv2	// Sample Loop #2 Temp on same time basis as wv1
wave wv3	// OUTPUT:  temp corrected long path water

duplicate /o wv1 wv3
wv3 = nan

//  Based on Final START08 TDL Calibrations (New TDL Corrections.pxp)
wv3 = (wv1 / (1.749 - (wv2 * 0.0257))) - 4.5

//wv3 = selectnumber(wv2>=35.8, wv1*wv2/(0.85*wv2), wv1/(1.73 - 0.0246 * wv2))
end

function CorrShortPathWater(fittype, wv, wv1)
string fittype		//	"line" or "poly"
wave wv			//  raw tdlsh2o wave
wave wv1			// output tdlsh2o_corr  wave

if((cmpstr(fittype, "line") == 0) +(cmpstr(fittype, "poly") == 0))
	duplicate /o wv wv1
	wv1 = nan
	
	if(cmpstr(fittype, "line") == 0)
		wv1 = (wv * 0.985) - 4
	endif
	
	if(cmpstr(fittype, "poly") == 0)
		wv1 = (-1.67e-4)*(wv)^2 + 1.19 * wv - 33
	endif
else
	print "Correction types are line or poly"
endif
end


//function ChopTDLBestWv(wv, wv1,wv2,wv3,wv4,wv5,wv6)

wave  wv		// h2o_best
wave wv1		// timew
wave wv2		// timewh2o
wave wv3		// interval_yymmdd
wave wv4		// output wave:  uwv_yymmdd
wave wv5		// output wave:  uwvgmts_yymmdd
wave wv6		// output wave:  uwvdate_yymmdd

duplicate /o wv wv4
duplicate /o wv1 wv5
duplicate /o wv2 wv6

// write NaN to output data wave before initial pump on and after final pump off
wv4 = selectnumber((wv1 > wv3[0])*(wv1 < wv3[3]), nan, wv)

if((wv3[1] !=0)*(wv3[2] != 0))	//  if there was a mid-flight stop and re-start of pumps
	wv4 = selectnumber((wv1 >= wv3[1])*(wv1 < wv3[2]), wv4, 99999)	// write 99999 to output data wave in this interim
endif

wv4 = selectnumber(wv4 >= 100, wv4, round(wv4))		//  round to integers all data >= 100 ppb

//  trim the output waves before initial pump on and after final pump off
duplicate /o wv4 trash
killnan(trash, wv5)
duplicate /o wv4 trash
killnan(trash,wv6)
duplicate /o wv4 trash
killnan(trash,wv4)

wv5 = round(wv5)
wv6 = round(wv6)
end

function FlagBadOzone(wv, wv1, wv2, tol1, tol2, tol3)
wave wv	//  wave of data that is the target of flagging
wave wv1	//  wave of data that targeted wave is judged against
wave wv2	//  output:  flag wave (1= good,  0 = bad, -1 = no wv1 data
variable tol1	//  absolute ± tolerance in ppb
variable tol2	//  relative ± tolerance in decimal  (0.01 = 1 percent)
variable tol3	//  absolute maximum tolerance for differences in ppb

duplicate /o wv trash; trash -= wv1				//  difference wave
duplicate /o trash trash1; trash1 /= wv1		//  relative difference wave

duplicate /o wv1 wv2

wv2 = selectnumber((numtype(wv1)!=2), 0, 1)	//  set flag= -1 for missing wv1 values, +1 for data there

wv2 = selectnumber((((trash1 > tol2)   * (trash > tol1)) + (trash > tol3)), wv2, -1)		// set flag = -1 for  positive differences exceeding relative threshold
wv2 = selectnumber((((trash1 < -tol2) * (trash < -tol1)) + (trash < -tol3)), wv2, -1)		// set flag = -1 for negative differences exceeding relative threshold

end

function ChopBestO3H2OWv(wv, wv1,wv2, wv3, wv4, wv5, wv6, thresh)

wave  wv		// o3   or   h2o  data wave
wave wv1		// tsecs_o3  or  tsecs_h2o
wave wv2		// timewo3  or timewh2o
wave wv3		// OUTPUT: chopped o3 or h2o data
wave wv4		// OUTPUT: chopped tsecs_o3  or tsecs_h2o wave
wave wv5		// OUTPUT: chopped date wave
wave wv6		// interval_yymmdd
variable thresh   //  time (sec) to wait after pump on before allowing good data

variable strt1  	//  initial pump start time
variable end1	//  intermediate pump stop time  (if any, if not set to 0)
variable strt2	//  intermediate pump start time (if any, if not set to 0)
variable end2	//  final pump stop time 

variable inc
variable inc1

duplicate /o wv wv3
duplicate /o wv1 wv4
duplicate /o wv2 wv5

strt1 = wv6[0] + thresh          //  Don't accept any data reports less than "thresh" sec after pump on

// write NaN to output data wave before initial pump on and after final pump off
wv3 = selectnumber((wv1 > strt1)*(wv1 < wv6[3]), nan, wv)

if((wv6[1] !=0)*(wv6[2]!= 0))
	strt2 = wv6[2] + thresh	//  Don't accept any data reports less than "thresh" sec after pump on
	wv3 = selectnumber((wv1 >= wv6[1])*(wv1 < strt2), wv3, nan)
endif

//  trim the output waves before initial pump on and after final pump off
inc = firstpoint(wv3)
inc1 = lastpoint(wv3)

DeletePoints (inc1+1), (numpnts(wv) - inc1 -1), wv3
DeletePoints 0, inc, wv3

DeletePoints (inc1+1), (numpnts(wv) - inc1 -1), wv4
DeletePoints 0, inc, wv4

DeletePoints (inc1+1), (numpnts(wv) - inc1 -1), wv5
DeletePoints 0, inc, wv5

// Put 99999 in for any NaNs in data wave
wv3 = selectnumber((numtype(wv3)!=2), 99999, wv3)
wv4 = round(wv4)
wv5 = round(wv5)
end


// For wv1 and wv2 the same wave, makes an output wave (wv3) of unique values of the input wave 
// For wv1 and wv2 different waves, makes two output waves (wv3, wv4) of the unique side-by-side combinations of two input waves
function Unique(wv1,wv2, wv3, wv4)
wave wv1, wv2, wv3, wv4

variable inc=1
variable inc1= numpnts(wv1) - 1

duplicate /o wv1 wv3
duplicate /o wv2 wv4

do
	if(wv1[inc] == wv1[inc-1])
		if ( cmpstr(NameOfWave(wv1), NameOfWave(wv2)) == 0 )	// Are wv1 and wv2 the same wave?  Then find unique values of wv1.
			wv3[inc] = NaN
		else
			if(wv2[inc] == wv2[inc-1])	// When wv1 and wv2 are different waves, also find unique values of wv2.
				wv3[inc] = NaN
				wv4[inc] = NaN
			endif
		endif
	endif
	inc += 1
while(inc <= inc1)

killnan(wv3,wv4)
end


function CalcMonthlyMeans(wv,wv1,wv2,wv3,wv4,wv5,wv6,wv7)

wave wv	// input year
wave wv1	// input month
wave wv2	// input data
wave wv3	// input err of data
wave wv4	// output decdate
wave wv5	// output mean data
wave wv6	// output sdev data
wave wv7	// output npnts data

duplicate /o wv wv4; duplicate /o wv wv5; duplicate /o wv wv6; duplicate /o wv wv7; 
wv4=nan; wv5=nan; wv6=0; wv7=nan

duplicate /o wv trash
duplicate /o wv1 trash1

 variable inc=1
 variable inc1=lastpoint(trash)
variable inc2=0

// make waves of unique year/month combinations (trash, trash1)
do
	if(((wv[inc]) == (wv[inc-1]))*((wv1[inc])==(wv1[inc-1])))
		trash[inc]=nan
		trash1[inc]=nan	// Set year/month repeats to NaN
	endif
inc += 1
while (inc <= inc1)

killnan(trash,trash1)

// Use the unique year/month combinations to find statistics for each
inc=0
inc1=lastpoint(trash)

duplicate /o wv2 trash2
duplicate /o wv3 trash3

do
	trash2 = selectnumber((wv==trash[inc])*(wv1==trash1[inc]), nan, wv2)
//	trash3 = selectnumber((wv==trash[inc])*(wv1==trash1[inc])*(numtype(wv2[inc])!=2), nan, wv3)	
	trash3 = selectnumber((wv==trash[inc])*(wv1==trash1[inc]), nan, wv3)
	wavestats /q trash2
	wv4[inc2] = trash[inc] + (trash1[inc]-0.5)/12
	wv7[inc2]= V_npnts
		if(V_npnts > 1)
			wv5[inc2]= V_avg
			wavestats /q trash3
			wv6[inc2] = V_rms*sqrt(1/V_npnts)
		endif

		inc2 += 1
inc += 1
while(inc <= inc1)

killnan4(wv4,wv5,wv6,wv7)
end


// Makes a data wave with outliers removed.  User specifices fit type ("line" or "polyN") 
// and tolerance for outliers based on Average Deviation of Residuals (V_adev)
function RmOutliersFromFit(wv1, wv2, wv3, fittype, tolerance)
wave wv1	// x-axis data to fit
wave wv2	// y-axis data to fit
wave wv3	// output y-axis data with outliers removed
string fittype	// "line" or "polyN"
variable tolerance	// number of average deviations of residuals

wave W_coef

duplicate /o wv2 wv3; wv3=nan
duplicate /o wv1 trash; trash = nan

if (cmpstr(fittype, "line") == 0)
	CurveFit /Q/NTHR=1 line,  wv2 /X=wv1
	trash   = W_coef[0] + W_coef[1]*wv1
endif

if (strsearch(fittype, "poly", 0,2)!= -1)
	CurveFit /Q/NTHR=1 poly str2num(fittype[4]),  wv2 /X=wv1
	trash=poly(W_coef,wv1)
endif

	trash -= wv2
	wavestats /q trash
	wv3 = selectnumber((abs(trash) <= (tolerance*V_adev)), nan, wv2)

end


// Rescales Line and Poly3 Fit Waves to match the x-axis span of target fit wave
// For Poly3 fits, will produce a uniform interval fit wave OR fit wave with same x-axis values as the target fit wave
function ReScaleFitWave(wv,wv1,xmatch)
wave wv	//  Fit Wave that will be rescaled to x-values of the wv1 fit wave
wave wv1	//  This target fit wave contains the x-values that will be used to rescale wv
variable xmatch    //  Do you want to exactly match the x-wave of wv1 ??  0=No, 1=Yes
				    //  If No, wv will be re-scaled at uniform intervals
wave W_coef

wavestats /q wv		//  Check if linear or poly3 fitwave

if(xmatch <= 1)
	if(V_npnts == 2)	// Line Fit
		CurveFit /Q/NTHR=1 line,  wv	// Get slope and intercept
		duplicate /o wv1 wv
		wv = W_coef[1]*x + W_coef[0]
	endif
	
	if(V_npnts > 2)		// Quadratic Fit
		CurveFit /Q/NTHR=1 poly 3,  wv	// Get quadratic fit coefficients
		if(xmatch == 1)
			duplicate /o wv1 wv
			wv = W_coef[2]*x^2 + W_coef[1]*x + W_coef[0]
		else
			SetScale/I x pnt2x(wv1,0),pnt2x(wv1,(numpnts(wv1)-1)),"", wv
			wv = W_coef[2]*x^2 + W_coef[1]*x + W_coef[0]
		endif
	endif
endif

end

function FindMonthFromDecdate(wv,wv1)
wave wv	// decdate wave
wave wv1	// output wave of month

variable inc=0
variable inc1 = lastpoint(wv)

duplicate /o wv wv1
wv1=nan

//string wvstr1 = "decimalmonthend"
//wave decmonthend = $wvstr1
make /o decmonthend = {0,31,59,90,120,151,181,212,243,273,304,334,365}
decmonthend /= 365

//string wvstr2 = "decimalmonthendleap"
//wave decmonthendleap = $wvstr2
make /o decmonthendleap = {0,31,60,91,121,152,182,213,244,274,305,335,366}
decmonthendleap /= 366

do
	if(numtype(wv[inc]) != 2)
		if((mod(trunc(wv[inc]),4)==0) && (mod(trunc(wv[inc]),100)!=0))		// Leap Year
			wv1[inc]=binarysearch(decmonthendleap, mod(wv[inc],1)) + 1
		else			
			wv1[inc]=binarysearch(decmonthend, mod(wv[inc],1)) + 1	// Non-Leap Year
		endif
	endif

inc += 1
while (inc <= inc1)

killwaves decmonthend, decmonthendleap

end


function CalcHemisphereMeans(wv,wv1,wv2,wv3,wv4,wv5,wv6,wv7,wv8,wv9)
wave wv,wv1, wv2, wv3	// data waves
wave wv4,wv5,wv6,wv7	// sdev waves
wave wv8					// output wave of weighted average
wave wv9					// output wave of error on weighted average

variable inc=0
variable inc1=numpnts(wv) - 1

duplicate /o wv wv8 wv9
wv8=0; wv9=0

// NH SITES:
//variable weight   = cos(82.45*pi/180)		// ALT
//variable weight1 = cos(71.32*pi/180)		//BRW
//variable weight2 = cos(40.04*pi/180)		// NWR
//variable weight3 = cos(19.54*pi/180)		// MLO

// SH SITES:
variable weight = cos(64.92*pi/180)		// PAL
variable weight1   = cos(40.68*pi/180)	//CGO
variable weight2 = cos(60*pi/180)		// SPO
variable weight3 = cos(14.24*pi/180)		//SMO

variable sitecount
variable sitecount1
variable totweightmean
variable totweightsdev
do
	totweightmean = 0
	totweightsdev = 0
	sitecount = 0
	sitecount1 = 0
	
	if(numtype(wv[inc])!=2)
		wv8[inc] += wv[inc]*weight
		wv9[inc] += wv4[inc]*wv4[inc]*weight*weight    // will be zero if data was filled in (sdev = 0)
		totweightmean += weight
		sitecount1 += 1
		if(wv4[inc]!=0)		// if sdev != 0, add the weight
			totweightsdev += weight
		endif
	endif
	if(numtype(wv1[inc])!=2)
		wv8[inc] += wv1[inc]*weight1
		wv9[inc] += wv5[inc]*wv5[inc]*weight1*weight1
		totweightmean += weight1
		sitecount1 += 1
			if(wv5[inc]!=0)		// if sdev != 0, add the weight
				totweightsdev += weight1
			endif
		endif
	
	if(sitecount1 >= 1)	// MUST HAVE AT LEAST ONE DATA POINT FROM SITE1 OR SITE2
		sitecount = 1
	endif
	
	if(numtype(wv2[inc])!=2)
		wv8[inc] += wv2[inc]*weight2
		wv9[inc] += wv6[inc]*wv6[inc]*weight2*weight2
		totweightmean += weight2
		sitecount += 1
			if(wv6[inc]!=0)		// if sdev != 0, add the weight
				totweightsdev += weight2
			endif
	endif

	if(numtype(wv3[inc])!=2)
		wv8[inc] += wv3[inc]*weight3
		wv9[inc] += wv7[inc]*wv7[inc]*weight3*weight3
		totweightmean+= weight3
		sitecount += 1
			if(wv7[inc]!=0)		// if sdev != 0, add the weight
				totweightsdev += weight3
			endif
	endif

		if(sitecount >= 3)			// Southern Hemisphere also requires 2 sites to have data
			wv8[inc] /= totweightmean
			wv9[inc] = sqrt(wv9[inc])/totweightsdev
		else
			wv8[inc] = Nan
			wv9[inc] = 0
		endif
	inc += 1
while (inc <= inc1)

end


function FillInMissing(wv,wv1,wv2,wv3,wv4)
wave wv	// time wave
wave wv1	// data wave
wave wv2	// error wave
wave wv3	// output data wave
wave wv4	// output error wave

wave W_coef
variable inc = firstpoint(wv1)
variable inc1=lastpoint(wv1)

duplicate /o wv1 wv3
duplicate /o wv2 wv4

CurveFit /Q/NTHR=1 poly 3,  wv1 /X=wv /W=wv2 /I=1

do
	if(numtype(wv1[inc])==2)
		wv3[inc]=W_coef[0] + W_coef[1]*wv[inc] + W_coef[2]*(wv[inc]^2)
		wv4[inc]=0
	endif
	
inc += 1
while(inc <= inc1)
end

// Makes wv1 from x-scaling of wv
function MakeXWave(wv,wv1)

wave wv, wv1
variable inc=0
variable inc1=numpnts(wv)-1

duplicate /o wv wv1
wv1=nan

do

	wv1[inc] = pnt2x(wv, inc)

inc += 1
while (inc <= inc1)
end


function InterpWave(wv,wv1,wv2,wv3)
wave wv	// interpolation target x-values (wv3 will be written at these x-values)
wave wv1	// x-values of data wave to be interpolated (wv2) 
wave wv2	// data wave to be interpolated at wv1 values
wave wv3	// output wave of interpolated data

string str1
sprintf str1, "interpolate2 /A=0/J=0/T=1/I=3 /X=%s /Y=%s  %s, %s", nameofwave(wv), nameofwave(wv3), nameofwave(wv1), nameofwave(wv2)
execute(str1)
	
end

function GetBinStats(wv, wv1, wv2, wv3, tol, str1)
wave wv	// data wave to bin
wave wv1	// bin wave
wave wv2	// time-matched data wave to compute statistics based on bins of wv
wave wv3	// output wave of selected statistic for each bin
variable tol // number tolerance for bin
string str1	// type of statistical output wanted ("avg", "sdev", "npnts", "median")

wavestats /q wv1
make /o/n=(V_npnts) junk=nan
duplicate /o junk wv3

variable inc=0
variable inc1 = (V_npnts-1)

duplicate /o wv2 junk	
do
	junk = selectnumber((wv >= wv1[inc]) * (wv < wv1[inc+1]), nan, wv2)
	wavestats /q junk
	if(V_npnts >= tol)
		if(cmpstr(str1, "avg")==0)
			wv3[inc]=V_avg
		endif
		if(cmpstr(str1, "sdev")==0)
			wv3[inc]=V_sdev
		endif
		if(cmpstr(str1, "npnts")==0)
			wv3[inc]=V_npnts
		endif
		if(cmpstr(str1, "median")==0)
			wv3[inc]=medianofwave(junk, -inf, inf)
		endif
endif
inc += 1
while(inc < inc1)

wv3[inc]=nan
end

function mklevtry(wv, wv1, wv2, wv3, wv4, wv5, wv6, wv7, wv8, flagvar)
wave wv	// flag wave
wave wv1	// alt wave
wave wv2	//  data1 wave
wave wv3	//  data2 wave
wave wv4	//  data3 wave
wave wv5	// output LEVEL wave
wave wv6	// output LEV data1 wave
wave wv7	// output LEV data2 wave
wave wv8	// output LEV data3 wave
variable flagvar

wavestats /q wv1
variable minlev = floor(V_min/0.25)
variable maxlev = floor(V_max/0.25)
variable inc = 0
variable inc1 = (maxlev-minlev + 1)

make /o/n=(inc1) junk
duplicate /o junk wv5 wv6 wv7 wv8

duplicate /o wv2 junk
duplicate /o wv3 junk1
duplicate /o wv4 junk2

	junk = selectnumber((wv1 < (0.25*(minlev + 1))), nan, wv2)
	junk1 = selectnumber((wv1 < (0.25*(minlev + 1))), nan, wv3)
	junk2 = selectnumber((wv1 < (0.25*(minlev + 1))), nan, wv4)
	
if(flagvar ==1)
	junk2 = selectnumber((wv == 1) * (wv1 < (0.25*(minlev + 1))), nan, wv4)
endif

wv5[inc] = minlev
wavestats /q junk
wv6[inc] = V_avg
wavestats /q junk1
wv7[inc] = V_avg
wavestats /q junk2
wv8[inc] = V_avg

inc += 1

do

junk = selectnumber((wv1 >= (0.25*(minlev + inc) -0.125)) * (wv1 < (0.25*(minlev + inc) +0.125)), nan, wv2)
junk1 = selectnumber((wv1 >= (0.25*(minlev + inc) -0.125)) * (wv1 < (0.25*(minlev + inc) +0.125)), nan, wv3)
junk2 = selectnumber((wv1 >= (0.25*(minlev + inc) -0.125)) * (wv1 < (0.25*(minlev + inc) +0.125)), nan, wv4)

if(flagvar == 1)	
	junk2 = selectnumber((wv == 1) * (wv1 >= (0.25*(minlev + inc) -0.125)) * (wv1 < (0.25*(minlev + inc) +0.125)), nan, wv4)
endif
	
	wv5[inc]=minlev + inc		
	wavestats /q junk
	wv6[inc]=V_avg
	wavestats /q junk1
	wv7[inc]=V_avg
	wavestats /q junk2
	wv8[inc]=V_avg
	
	inc += 1
while (inc < inc1)

killwaves junk, junk1, junk2

end

function GetDataAtValue(wv, wv1, val, tol)
wave wv	// data wave to search
wave wv1	// wave to pull indexed find from
variable val	// value to search for
variable tol	// tolerance of search
//variable outpt	// index of find

findvalue /T=(tol)/V=(val)/Z wv
//print V_value

if(V_Value >=0)
	return wv1[V_value]
else
	return NaN
endif
end

//  compares one wave to another and reports points that are extra/missing in first wave
function PrintMissing(wv, wv1, out)
wave wv	//  data wave to examine
wave wv1	//  data wave to compare to
variable out	//  turn off(0) on(1) printing of missing points

variable inc=0
variable inc1 = (numpnts(wv1) - 1)
variable count1 = 0
variable count2 = 0
variable flag = 0

if ((numpnts(wv1) -1) != inc1)
	print "Waves are not the same length"
	flag = 1
endif

if (flag == 0)
	do
		if((numtype(wv[inc]) == 2) *  (numtype(wv1[inc]) == 0))
			count1 += 1
			if(out == 1)
				print "point ", inc, " is missing"
			endif
		endif
		if((numtype(wv[inc]) == 0) *  (numtype(wv1[inc]) == 2))
			count2 += 1
			if(out == 1)
				print "point ", inc, " is extra"
			endif
		endif
		inc += 1
	while (inc <= inc1)
endif

if(count1 != 0)
	print "total points missing = ", count1
endif

if(count2 != 0)
	print "total points extra     = ", count2
endif

if((count1 == 0) * (count2 == 0))
	print "POINTS ARE THE SAME"
endif
end

function MkAscDscWv(wv,wv3)

wave wv 	// Altitude Wave
wave wv3	// Data wave to divide into ascent and descent

string str1 = nameofwave(wv3) + "_asc"
string str2 = nameofwave(wv3) + "_dsc"

make /o $str1
make /o $str2

wave wv1 = $str1
wave wv2 = $str2

if ((numpnts(wv)) == (numpnts(wv3)))
	duplicate /o wv3 wv1 wv2

	wavestats /q wv
	wv1[(V_maxloc + 1),] = nan
	wv2[, V_maxloc] = nan
else
	print "Altitude and Data Waves are not the same length"
endif

end

function PumpLagTime(wv, wv1, interval, minlag, maxlag, corrsign)
wave wv	//  data wave with fixed timestamps (wv must have same exact timestamps as wv1)
wave wv1	//  data wave with shifting timestamps
variable interval	//  how many timestamp points to shift wv1 at each pass
variable minlag	//	how many intervals to shift timestamps back in time
variable maxlag	//  how many intervals to shift timestamps forward in time
variable corrsign	//  are positive (1) or negative (-1) correlation coefficients expected ?

variable inc = 0
duplicate /o wv1 trash

make /o/n=(minlag + maxlag + 1)  Pr_outwave = nan		//  wave of correlation coefficients for different time shifts
duplicate /o Pr_outwave Sec_outwave
Sec_outwave = x-(minlag*interval)		//  wave of time shifts in seconds, negative being a shift back in time

// START with zero time shift
inc = minlag
CurveFit/Q/NTHR=0 line  trash /X=wv
Pr_outwave[inc]=V_Pr

// Shift timestamps backward in time
inc=1
duplicate /o wv1 trash

do
	InsertPoints (numpnts(wv)), interval, trash		//  Add n=interval points at end of trash wave
	trash[((numpnts(wv))-interval), ]=nan			//  Set those added points = NaN
	DeletePoints 0,interval, trash						//  Delete n=interval points at start of trash wave
	CurveFit/Q/NTHR=0 line  trash /X=wv				//  Do curve fit on shifted wave vs fixed wave
	Pr_outwave[minlag - inc] = V_Pr					//  Write correlation coefficient at correct point of output wave
	inc += 1
while (inc <= minlag)

// Shift timestamps forward in time
inc = 1
duplicate /o wv1 trash

do
	DeletePoints ((numpnts(wv))-interval), interval, trash	  //  Delete n=interval points at end of trash wave
	InsertPoints 0, interval, trash								// Add n=interval points at the start of trash wave
	trash[,(interval-1)]=nan							//  Set those added points = NaN
	CurveFit/Q/NTHR=0 line  trash /X=wv				//  Do curve fit on shifted wave vs fixed wave
	Pr_outwave[minlag + inc] = V_Pr					//  Write correlation coefficient at correct point of output wave
	inc += 1
while (inc <= maxlag)

end

function CombineTDLChannels(wv, wv1, wv2, wv3, wv4, val1, val2, wv5, wv6)
wave wv	//  tdllh2o_tempcorr_@
wave wv1	//  tdlsh2o_corrpoly_@
wave wv2	//  tdlsh2o_corrline_@
wave wv3	//  tdlsh2o_@
wave wv4	//  tsecs_h2o_@
variable val1	//  value of tdlsh2o_@ where data will change from wv to wv1
variable val2	//  value of tdlsh2o_@ where data will change from wv1 to wv2
wave wv5	//   output wave of timestamps from wv4
wave wv6	//   output wave of H2O mixing ratio data

variable inc
variable inc1

duplicate /o wv4 wv5
duplicate /o wv wv6

if((numpnts(wv)) == (numpnts(wv1)))
	if((numpnts(wv)) == (numpnts(wv2)))
		if((numpnts(wv)) == (numpnts(wv3)))
			if((numpnts(wv)) == (numpnts(wv4)))
				wv6 = selectnumber((wv3 >= val1)*(wv3<val2), wv, wv1)   //  for val1 <=  tdlsh2o < val2  use  wv1 data
				wv6 = selectnumber(wv3 >= val2, wv6, wv2)   //  for  tdlsh2o >= val2  use  wv2 data

			//	inc = firstpoint(wv6) - 1
			//	DeletePoints 0, inc, wv5
			//	DeletePoints 0, inc, wv6
				
			//	inc = lastpoint(wv6) + 1
			//	inc1 = numpnts(wv6)
			//	DeletePoints inc, (inc1-inc), wv5
			//	DeletePoints inc, (inc1-inc), wv6
				
				// wv6 = selectnumber(numtype(wv6) == 2, wv6, 99999)
			else
				print nameofwave(wv) ," and ", nameofwave(wv4), " must be the same length"
			endif
		else
			print nameofwave(wv) ," and ", nameofwave(wv3) ," must be the same length"
		endif
	else
		print nameofwave(wv) ," and ", nameofwave(wv2) ," must be the same length"
	endif
else
	print nameofwave(wv) ," and ", nameofwave(wv1) ," must be the same length"
endif

end

function ConvertDateStringtoDate(wv,wv1,numchar)
wave /t  wv	// text wave of date strings
wave wv1	//  output numerical wave of dates 
variable numchar	//  number of characters in each date string

string str
variable inc=0
variable inc1 = numpnts(wv)
variable yyyymmdd
variable yyyy
variable mm
variable dd

if((numberbykey("numtype", waveinfo(wv1, 0))) == 4)
	do
		if(cmpstr(wv[inc], "") != 0)		//  if the text wave cell has a string other than ""
			yyyymmdd = str2num(wv[inc])
			if(numchar==6)		//  conver to 8-character dates
				if((floor(yyyymmdd/1e5) == 8) + (floor(yyyymmdd/1e5) == 9))
					yyyymmdd += 19000000
				else
					yyyymmdd += 20000000
				endif
			endif
			yyyy = floor(yyyymmdd/1e4)
			mm = mod(yyyymmdd,1e4)
			dd = mod(mm, 1e2)
			mm = floor(mm/1e2)
		//	wv1[inc]=dd
			wv1[inc]=date2secs(yyyy, mm, dd)
		else
			wv1[inc]=nan	
		endif
	inc += 1
	while (inc < inc1)
else
	print "Output wave must be double precision"
endif
end



function SigFigs(wv, wv1, sigfigs)
wave wv
wave wv1
variable sigfigs

variable minfigs=0
variable maxfigs=0
variable flag=0
variable inc = -5

wavestats /q wv

do
	if(V_max >= 10^inc)
		maxfigs=(inc+1)
	else
		flag=1
	endif
	inc+=1
while (flag==0)
print inc

flag=0
inc = 5

do
	if(V_min < 10^inc)
		minfigs=(inc-1)
	else
		flag=1
	endif
	inc-=1
while (flag==0)

duplicate /o wv wv1

inc=minfigs
do




inc+=1
while(inc <= maxfigs)

end


//function FixLongPathWaterFred(wv,wv1,wv2)
wave wv	// Long Path Water Vapor Mixing Ratio
wave wv1	// Cell Pressure (mbar)
wave wv2	// OUTPUT:  corrected Long Path Water Vapor Mixing Ratio

duplicate /o wv wv2

// From Fred March 2008
variable a = 5.283e-7		// second order coefficient
variable b = -0.0008123	// linear coefficient
variable c = 1.15 			// intercept

wv2 *= 1.13/(c + (b*wv1)+ (a*wv1*wv1))
wv2 +=  -1.5

//lowchop(wv2, 0)
wv2 = round(wv2*10)/10
end

//function FixLongPathWaterA(wv,wv1,wv2)
wave wv	// Long Path Water Vapor Mixing Ratio
wave wv1	// Cell Pressure (mbar)
wave wv2	// OUTPUT:  corrected Long Path Water Vapor Mixing Ratio

// From Fred March 2008
//tdllh2oC= tdllh2o/(1.15-0.0008123*PC+ 5.283e-7*PC*PC) - 1.5

//variable a = 5.283e-7		// second order coefficient
//variable b = -0.0008123	// linear coefficient
//variable c = 1.15 			// intercept

// Long-Path Pressure correction from Dale March 26 2008
variable a = 5.372e-7		// second order coefficient
variable b = -0.000757	// linear coefficient
variable c = 1.135 			// intercept
variable offset = -1.5		// zero correction  for cals A and B

// Long-Path Pressure correction from Dale June 6 2008
//variable a = 3.3914e-07		// second order coefficient
//variable b = -0.00054068	// linear coefficient
//variable c = 1.0943 			// intercept
//variable offset = -1.5		// zero correction  for cals A and B

duplicate /o wv wv2

wv2 *= 1.37/((a * (wv1)^2) + (b * wv1) + c )     // This is START-08 Calibration "A" March 26 2008
//wv2 *= 1.35/((a * (wv1)^2) + (b * wv1) + c )     // This is START-08 Calibration "A" June 6 2008
wv2 += offset

//lowchop(wv2, 0)
wv2 = round(wv2*10)/10
end

//function FixLongPathWaterB(wv,wv1,wv2)
wave wv	// Long Path Water Vapor Mixing Ratio
wave wv1	// Cell Pressure (mbar)
wave wv2	// OUTPUT:  corrected Long Path Water Vapor Mixing Ratio

// From Fred March 2008
//tdllh2oC= tdllh2o/(1.15-0.0008123*PC+ 5.283e-7*PC*PC) - 1.5

//variable a = 5.283e-7		// second order coefficient
//variable b = -0.0008123	// linear coefficient
//variable c = 1.15 			// intercept

// Long-Path Pressure correction from Dale March 26 2008
variable a = 5.372e-7		// second order coefficient
variable b = -0.000757	// linear coefficient
variable c = 1.135 			// intercept
variable offset = -1.5		// zero correction  for cals A and B

duplicate /o wv wv2

wv2 *= 1.58/((a * (wv1)^2) + (b * wv1) + c )     // This is START-08 Calibration "B"
wv2 += offset

//lowchop(wv2, 0)
wv2 = round(wv2*10)/10
end

//function FixLongPathWaterC(wv,wv1,wv2)
wave wv	// Long Path Water Vapor Mixing Ratio
wave wv1	// Cell Pressure (mbar)
wave wv2	// OUTPUT:  corrected Long Path Water Vapor Mixing Ratio

// From Fred March 2008
//tdllh2oC= tdllh2o/(1.15-0.0008123*PC+ 5.283e-7*PC*PC) - 1.5

//variable a = 5.283e-7		// second order coefficient
//variable b = -0.0008123	// linear coefficient
//variable c = 1.15 			// intercept

// Long-Path Pressure correction from Dale March 26 2008
variable a = 5.372e-7		// second order coefficient
variable b = -0.000757	// linear coefficient
variable c = 1.135 			// intercept
variable offset = -4.5		// zero correction  for cal C

duplicate /o wv wv2

wv2 += offset
wv2 *= 1.80/((a * (wv1)^2) + (b * wv1) + c )

//lowchop(wv2, 0)
wv2 = round(wv2*10)/10
end

//function FixLongPathWaterD(wv,wv1,wv2)
wave wv	// Long Path Water Vapor Mixing Ratio
wave wv1	// Cell Pressure (mbar)
wave wv2	// OUTPUT:  corrected Long Path Water Vapor Mixing Ratio


// Long-Path Pressure correction from Dale March 26 2008
variable a = 5.372e-7		// second order coefficient
variable b = -0.000757	// linear coefficient
variable c = 1.135 			// intercept
variable offset = -4.9		// zero correction  for cal C

duplicate /o wv wv2

wv2 /= ((a * (wv1)^2) + (b * wv1) + c )    //  Do pressure correction first

wv2 += offset
wv2 *= 1.36


//lowchop(wv2, 0)
wv2 = round(wv2*10)/10
end

//function MakeTDLBestWv(cal,wv,wv1,wv2,wv3)

string cal	// Identifier for calibration and corrections to use
wave wv	// RAW Long Path Water Vapor Mixing Ratio
wave wv1	// Cell Pressure (mbar)
wave wv2	// RAW Short Path Water Vapor Mixing Ratio
wave wv3	// OUTPUT:  Best Water output wave

if(cmpstr(cal, "A") == 0)
FixLongPathWaterA(wv, wv1,wv3)
	wv3 = selectnumber(wv2 > 900, wv3, wv2-50)      //Short-path correction is START-08 Calibration "A"
endif

if(cmpstr(cal, "B") == 0)
	FixLongPathWaterB(wv, wv1,wv3)	
		wv3 = selectnumber(wv2 > 900, wv3, wv2-25)       // Short-path correction is START-08 Calibration "B"
endif

if(cmpstr(cal, "C") == 0)
	FixLongPathWaterC(wv, wv1,wv3)
	wv3 = selectnumber(wv2 > 900, wv3, wv2)       // Short-path correction is START-08 Calibration "C"
endif

if(cmpstr(cal, "D") == 0)
	FixLongPathWaterD(wv, wv1,wv3)
	wv3 = selectnumber(wv2 > 900, wv3, wv2)       // Short-path correction is START-08 Calibration "C"
endif
end

//function FixWaterNew(cal, wv,wv1,wv2)
string cal	// Designation of new calibration and correction to use
wave wv	// Long Path Water Vapor Mixing Ratio
wave wv1	// Cell Pressure (mbar)
wave wv2	// OUTPUT:  corrected Long Path Water Vapor Mixing Ratio

duplicate /o wv wv2

variable a
variable b
variable c
variable gain

variable offset = -4.5		// zero correction

wv2 += offset

if(cmpstr(cal, "A") == 0)  // Long-Path Pressure correction "A" from Dale   June 5, 2008
	a = 3.5243e-07		// second order coefficient
	b = -0.00056104		// linear coefficient
	c = 1.0979 			// intercept
	gain = 1.40
endif

if(cmpstr(cal, "B") == 0)
	a = 5.372e-7		// second order coefficient
	b = -0.000757		// linear coefficient
	c = 1.135 			// intercept
	gain = 1.58
endif

if(cmpstr(cal, "C") == 0)
	a = 5.372e-7		// second order coefficient
	b = -0.000757		// linear coefficient
	c = 1.135 			// intercept
	gain = 1.80
endif

wv2 *= gain/((a * (wv1)^2) + (b * wv1) + c )

wv2 = round(wv2*10)/10

end



//function MakeTDLBestWvNew(cal,wv,wv1,wv2,wv3)

string cal	// Identifier for calibration and corrections to use
wave wv	// RAW Long Path Water Vapor Mixing Ratio
wave wv1	// Cell Pressure (mbar)
wave wv2	// RAW Short Path Water Vapor Mixing Ratio
wave wv3	// OUTPUT:  Best Water output wave

FixWaterNew(cal,wv, wv1,wv3)

if(cmpstr(cal, "A") == 0)
	wv3 = selectnumber(wv2 > 900, wv3, wv2-50)      //Short-path correction is START-08 Calibration "A"
endif

if(cmpstr(cal, "B") == 0)
		wv3 = selectnumber(wv2 > 900, wv3, wv2-25)       // Short-path correction is START-08 Calibration "B"
endif

if(cmpstr(cal, "C") == 0)
	wv3 = selectnumber(wv2 > 900, wv3, wv2)       // Short-path correction is START-08 Calibration "C"
endif
end

function TimeChopWave(wv0,wv,wv1,wv2)
wave wv0	// interval_yymmdd
wave wv	// tsecs wave
wave wv1	// data wave
wave wv2	// output wave

duplicate /o wv1 wv2

wv2 = selectnumber((wv > wv0[0])*(wv < wv0[3]), nan, wv1)

if((wv0[1] !=0)*(wv0[2] != 0))
	wv2 = selectnumber((wv >= wv0[1])*(wv < wv0[2]), wv2, nan)
endif

//wv2 = selectnumber(wv2 >= 100, wv2, round(wv2))

//killnan(wv2,wv2)
end
