#pragma TextEncoding = "MacRoman"
#include "macros-strings and lists"
//#include <strings as lists>
// Removed dependance on <strings as lists> obsoleted proceedure file.  GSD 080327

// I striped out all string arrays from these macros.  The string array utilities are now located in
// macros-string arrays.

//macros-Utilities
//
// Igor macros/function of general usefulness. This file may be added to any experiment 
// to provide additional functionality.  Most of the routines are not dependent on any global variables or
// waves.  Some, however, must return values, which in Igor, must be done via a global variable.
// The "prompting" functions require pre-declared globals.  All global variable names begin with "G_"
//||||||||||||||||||||||||||||||
// Updates: Dec '94 TJB
//			Mar '95 TJB -- added makeIndexWave
//==============================================================
// еееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееее
//     contents:
// ееееееееееее Batch Processing 
// bat -- batch processing of waves.
// lbat -- batch processing of list.
// cmvbat -- similar to bat, but substitutes the wildcard (instead of the full wave name) into the command string
// ееееееееееее Math
// xLocIntvlMax --  returns the x-coordinate of the maximum y-value in an interval of a wave.
// intvlMax -- returns the maximum y-value found in an interval of a wave.
// intvlMin -- returns the minimum y-value in an interval of a wave.
// odd -- not even
// replaceNANs -- replaces all NaN's, INF's, -INF's, in a wave with a normal number
// ееееееееееее Time and date 
// date2julian -- computes julian day from yyyy mm dd format
// date2ParsedDate -- converts Igor date to a different format
// QBdate2ParsedDate -- converts Microsoft quick basic 4.5 formatted date and time into yyyy mm dd
// ееееееееееее Desktop
// saveRecreationMacro -- Stores recreation macro for top graph/layout/panel/table to a notebook.
// printAllDisplayedGraphs -- ditto
// removeDisplayedObjects -- ditto
// removeDisplayedGraphs -- ditto
// removeDisplayedTables -- ditto
// ееееееееееее Wave: utility
// isWaveSorted -- determines if a wave is sorted
// redimWv -- redimensions a wave or makes it if it doesn't exist, initializes to -1 or 0... see code...
// wDup -- duplicates or makes a new wave, and initializes it to NaN
// copyLenAndScale -- copies length and scale from one wave to another.
// seqSearch -- searchs a wave for a specific value
// WaveDiff --  determines if two waves are identical or different.
// Replace -- Replaces all occurrances of a value in a wave
// compareWv -- tests all elements of a wave
// removeDuplicates -- removes duplicate values from a wave.
// baselineSegmentAverage -- Returns average value of a segment of a wave.
// makeIndexWave -- Index wave gets pointers to unique integers in source wv.
// ееееееееееее Wave: interpolating/adjusting
// ConvertXYToScaledWave -- interpolates from an X-Y pair of waves to a single scaled wave.
// ChangeDataSpacing -- interpolates from a scaled wave to an X-Y pair
// ChangeDataSpacingMedian -- grabs median value to convert from a scaled wave to an X-Y pair?
// interpVal -- interpolates between two points
// mkInterpWv -- Creates a new wave which is a point by point interpolation between two others.
// interpolateBetweenCsrs -- linearly interpolates all points between two cursors
// DeletePointsBetweenCursors -- deletes all wave points between cursors, shortening wave.
// XYpairs2sameX -- adjusts a collection of X-Y wave pairs to a common X spacing, without losing values.// // 
// ееееееееееее Wave: smoothing
// removeSpikes -- averages out single point spikes in a wave.
// doLoess -- loess fit
// ееееееееееее Cursors
// setCsrRng -- sets a range of a wave to a value.  Range defined by the cursors.// 
// chkCsrsOrder -- puts cursors in A-B order
// chkCsrsSameWv -- determines if cursors are on the same wave
// ееееееееееее Paths
// getUniquePathName -- creates a string which is not the name of any existing path.
// uniquePathName -- returns a string which would be a unique path name
// ееееееееееее Set Operations
// wvsAND -- treats two waves as sets, and does set AND.
// wvsOR -- treats two waves as sets, and does set OR.
// wvsXOR -- treats two waves as sets, and does set XOR.
// wvsDIFF -- treats two waves as sets, and does set DIFF.
// ееееееееееее Files
// Fexists --  determines if a file exists.
// еееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееее


menu "macros"
end


//--------------------------------------------------------------
//Extensions to the string array XOPs
//--------------------------------------------------------------
function bat(op,wcDesc)
	string op, wcDesc
	
	if (strsearch(wcDesc,"?", 0) != -1)  // use the old method
		batch ("WAV", op, wcDesc)
	else

		string lst = WaveList(wcDesc, ";", ""), com
		variable n = NumElementsInList(lst, ";"), inc=0
		
		if (n > 0) 
			do 
				com = genCom("@", op, StringFromList(inc, lst))
		      	execute com
		      	inc += 1
			while (inc < n)
		endif
	endif
	
end	

function batch (objectType, op, wcDesc)
	string objectType, op, wcDesc
	
	string lstNm = WaveList ("*",";",""), com, wvNm
	variable n = FindListItem(wcDesc, lstNm, ";", 0)
	variable numLst = NumElementsInList(lstNm, ";")
	
	if (n >= 0) 
		do 
			wvNm = StringFromList(n, lstNm)
			com = genCom ("@", op, wvNm)
			execute com
	
			n = FindListItem(wcDesc, lstNm, ";", n+1)
		while ((n < numLst) * (n >=0))
	endif

end	 


function lBat(op,Lst)
	string op, Lst

	string com, wvNm
	variable n = NumElementsInList(lst, ";"), inc=0
	
	if (n > 0) 
		do 
			wvNm = StringFromList(inc, lst)
			com = genCom("@", op, wvNm)
	      	execute com
	      	inc += 1
		while (inc < n)
	endif
	
end 

	
//Similar to bat, but instead of inserting the whole wavename in place of "@" into the command string, only
//inserts the part represented by the wildcard "*".  Only one wildcard "*" is allowed (no "?")!
macro cmvbat (op, wcDesc)
	string op, wcDesc
	silent 1; pauseUpdate
	
	string lstNm, com, wvNm, prefix, suffix, wc
	variable n, wcpos, numLst
	
	lstNm = WaveList (wcDesc,";","")
	
	numLst = NumElementsInList(lstNm, ";")
	
	wcpos=strsearch(wcDesc, "*", 0)
	prefix=wcDesc[0, wcpos-1]
	suffix=wcDesc[wcpos+1, strlen(wcDesc)-1]
	
	if (n >= 0) 
		do 
			wvNm = StringFromList(n, lstNm)
			
			wc = wvNm[strlen(prefix), strlen(wvNm)- 1- strlen(suffix)]
			com = genCom ("@", op, wc)
      		execute com
      		
      		n += 1
	
		while ((n <numLst) * (n >=0))
	endif

end	 


function/S genCom (repl, op, subst)
	string repl, op, subst  // character to replace;  operation containing repl character; text to substitute for repl
	
	string com = ""
	variable pc = 0
	
	if (pc <= strlen (op) - 1)
		do 
			if (cmpstr(op[pc,pc], repl) == 0)
				com += subst
			else
				com += op[pc,pc]
			endif
		
			pc += 1
		while (pc <= strlen (op) - 1)
	endif
	
	return com
end
	


//--------------------------------------------------------------
// Math functions.
//--------------------------------------------------------------
	
function xLocIntvlMax(wv,x1,x2)
	Wave wv
	variable x1,x2
	
	variable p1=x2pnt(wv,x1),p2=x2pnt(wv,x2),pt=p1
	do
		p1+=1
		if (wv[p1]>wv[pt])
			pt=p1
		endif
	while(p1<p2)
	return pnt2x(wv,pt)
end		
	
function intvlMax(wv,x1,x2)
	Wave wv
	variable x1,x2
	
	variable p1=x2pnt(wv,x1),p2=x2pnt(wv,x2),pt=p1
	do
		p1+=1
		if (wv[p1]>wv[pt])
			pt=p1
		endif
	while(p1<p2)
	return wv[pt]
end		
	
function intvlMin(wv,x1,x2)
	Wave wv
	variable x1,x2
	
	variable p1=x2pnt(wv,x1),p2=x2pnt(wv,x2),pt=p1
	do
		p1+=1
		if (wv[p1]<wv[pt])
			pt=p1
		endif
	while(p1<p2)
	return wv[pt]
end		

// Returns TRUE if the arguement is odd,  FALSE if not...
Function Odd (num)
	Variable num
	return (Mod (num, 2))
end	

// If "val" is a normal number, returns it. Otherwise, returns "replaceVal." To replace all NaN's in 
// wave "wv" with 9999, execute the following command: wv=replaceNANs (wv[p],9999)
function replaceNANs (val, replaceVal)
	variable val, replaceVal
	
	if (numtype(val) == 0)
		return val
	else
		return replaceVal
	endif
end


//--------------------------------------------------------------
// Date/Time functions.
//--------------------------------------------------------------

function /D date2julian (yr,mo,day)
	variable yr,mo,day
	return (date2Secs(yr,mo,day) - date2secs(yr,1,0)) / 86400
end

// Takes date string "mm/dd/yyyy" and separates it into the global date component Variables.
//
macro date2ParsedDate(theDate)
	String theDate
	prompt theDate, "Input the date as a string (format: \"mm/dd/yyyy\"):"
	
	silent 1
	variable ch=0
	
	G_mo = str2num (theDate[0,StrSearch (theDate, "/", 0) - 1])
	theDate =  theDate[StrSearch (theDate, "/", 0) + 1, strlen (theDate)]
	
	G_day = str2num (theDate[0,StrSearch (theDate, "/", 0) - 1])
	theDate =  theDate[StrSearch (theDate, "/", 0) + 1, strlen (theDate)]
	
	G_yr = str2num (theDate)
		
	G_sec = 0
end


//#pragma rtGlobals=1		// Use modern global access method to prevent g_sec, g_day, etc. being created globaly.
// Takes date string "mm-dd-yyyy" and the time string "hh:mm:ss" separates it into the global date 
// component Variables.  It is ok for the string params to be empty.
// For parsing date and time as output by QuickBASIC.
function QBdate2ParsedDate(theDate, theTime)
	String theDate, theTime
	
	variable ch=0
	if (! exists("g_mo"))
		variable /g g_mo, g_day, g_yr, g_sec
	endif
	
	if (strlen (theDate) > 0)
		G_mo = str2num (theDate[0,StrSearch (theDate, "-", 0) - 1])
		theDate =  theDate[StrSearch (theDate, "-", 0) + 1, strlen (theDate)]
		
		G_day = str2num (theDate[0,StrSearch (theDate, "-", 0) - 1])
		theDate =  theDate[StrSearch (theDate, "-", 0) + 1, strlen (theDate)]
		
		G_yr = str2num (theDate)
	else
		G_mo = 0
		G_day = 0
		G_yr = 0
	endif
		
	if (strlen (theTime) > 0)
		G_sec = str2num (theTime[0,StrSearch (theTime, ":", 0) - 1]) * 3600
		theTime =  theTime[StrSearch (theTime, ":", 0) + 1, strlen (theTime)]

		G_sec += str2num (theTime[0,StrSearch (theTime, ":", 0) - 1]) * 60
		theTime =  theTime[StrSearch (theTime, ":", 0) + 1, strlen (theTime)]

		G_sec += str2num (theTime)
	else
		G_sec = 0
	endif
end
#pragma rtGlobals=0		// Use modern global access method.


//--------------------------------------------------------------
// Printing/Display functions.
//--------------------------------------------------------------

// Prints all currently displayed graphs, printing gpp graphs-per-page.
//
macro printAllDisplayedGraphs (gpp)
	variable gpp=G_gpp
	prompt gpp,"How many graphs per page?"
	
	silent 1
	G_gpp=gpp
	String graphSpecs,grNm
	variable grNum=0
	
	do
		graphSpecs=""
		iterate (gpp)
			grNm=WinName (grNum,1)
			grNum+=1
			if (strlen (grNm)==0)
				break
			else
				if (i>0)
					graphSpecs+=", "
				endif
				graphSpecs+=(grNm+" /F=2 ")
			endif
		loop			
		
		if (strlen (graphSpecs)>0)
			graphSpecs="printGraphs /T " + graphSpecs
			print "***** ", graphSpecs
			execute graphSpecs
			sleep 00:00:02
		endif
		
	while (strlen (grNm)>0)
end
	

function removeDisplayedObjects()
	silent 1
	string grNm
	variable inc=0
	do 
		inc += 1
		grNm=WinName (0,7)
		if (strlen (grNm) <= 0)
			break
		endif
		if (mod(inc,5)==0) 
			printf "%s\r", grNm
		else
			printf "%s,", grNm
		endif
		doWindow /K $grNm
	while (1)
	printf "\r"
end
	
function removeDisplayedGraphs()
	silent 1
	string grNm
	variable inc=0
	do 
		inc += 1
		grNm=WinName (0,5)
		if (strlen (grNm) <= 0)
			break
		endif
		if (mod(inc,5)==0) 
			printf "%s\r", grNm
		else
			printf "%s,", grNm
		endif
		doWindow /K $grNm
	while (1)
	printf "\r"
end

function removeDisplayedTables()
	silent 1
	string grNm
	variable inc=0
	do 
		inc += 1
		grNm=WinName (0,2)
		if (strlen (grNm) <= 0)
			break
		endif
		if (mod(inc,5)==0) 
			printf "%s\r", grNm
		else
			printf "%s,", grNm
		endif
		doWindow /K $grNm
	while (1)
	printf "\r"
end

//--------------------------------------------------------------
// Wave functions.
//--------------------------------------------------------------
	
function isWaveSorted (wv)
	Wave wv
	
	variable pnt=1
	Do
		if (wv[pnt-1]>wv[pnt])
			return 0
		endif
		pnt+=1
	while (pnt<numpnts(wv))
	return 1
end 	
	
function redimWv (wv, len)
	String wv
	Variable len

	wave wvNm = $wv
	Variable defaultVal,oldLen
	
	if (CmpStr (wv,"flag") == 0)
		defaultVal = 0
	else 
		defaultVal = -1
	endif

	if (exists (wv) == 1)
		oldLen=numpnts(wvNm)
		redimension /n=(len) wvNm
		if (oldLen<len)
			wvNm[oldLen,]=defaultVal
		endif
	else
		make /n=(len) wvNm=defaultVal 
	endif
end


// Copies the length and scale from the source wave to the destination wave.  If it must extend the 
// dest wave, initializes new points to the value of the last old point (rather than just letting Igor
// initialize them to 0).
// 
function copyLenAndScale (srcNm, destNm)
	string srcNm,destNm
	
	variable oldLastPt, oldLastY
	
	if (exists(destNm) != 1)
		make /n=(numpnts($srcNm)) $destNm

		Wave src = $srcNm
		Wave dest = $destNm		
	else
		if (numpnts ($srcNm) != numpnts ($destNm))
			Wave src = $srcNm
			Wave dest = $destNm
			
			oldLastPt = numpnts (dest) - 1
			oldLastY = dest[oldLastPt]
			redimension /n=(numpnts(src)) dest
			dest[oldLastPt, numpnts (dest) - 1] = oldLastY
		endif
	endif
	
	copyScales /p $srcNm, $destNm
end	
	

// Returns the first x value associated with the y-value, "val" in the wave "wv".  Starts the search for val from 
// the first point of the wave, assumes the wave is monotonic increasing, and stops as soon as a point is found.
// pnt is the starting value
Function seqSearch (wv, val, pnt)
	Wave	wv
	Variable val, pnt
	
	do 
		if (wv[pnt] > val) 
			return pnt2x (wv, pnt)
		endif
		pnt += 1
	while (pnt < numpnts (wv))
	return -99
end
	


//---------------------------------------------------
// Interpolating functions 
//---------------------------------------------------


// Takes an xy pair of waves and interpolates the data to create a matching scaled wave.  
Macro ConvertXYToScaledWave (ywv, xwv, outwv, npnts)
	String	xwv, ywv, outwv = "interpolated"
	Variable npnts=1024
	Prompt ywv, "Data wave (y-wave) to interpolate: "
	Prompt xwv, "Corresponding x-wave: "
	Prompt outwv, "Input name of \"equivalent\" output scaled wave:"
	Prompt npnts, "Number points in output wave:"
	
	silent 1; pauseUpdate
 	if (exists (outwv) == 1) 
		DoAlert 1, "Wave  "+outwv+" already exists.    Overwrite it ??"
		if (V_flag != 1) 
			abort 
		endif
	endif
	
	make /o/n=(npnts) $outwv
	setScale /i  x, $xwv[0],$xwv[numpnts ($xwv) -1] , "", $outwv
	$outwv = interp (x, $xwv, $ywv)
end

// Takes a scaled wave and creates from it an xy wave. The x values come from xtemplate, and a new copy of this x-wave
//  is not created.  Each Y value is the average of boxSz points from the source wave.  This box of points includes the
//  point at the xtemplate value and the boxSz-1 preceding points. 
Macro ChangeDataSpacing (ywv, xtemplate,outwv, boxSz, boxOffset)
	String ywv,xtemplate,outwv
	Variable boxSz=1, boxOffset=0
	
	Prompt ywv, "Data wave (scaled in seconds) to be re-spaced ?"
	Prompt xtemplate, "Template of desired X spacing ?"
	Prompt outwv, "Name for re-spaced, result wave?"
	Prompt boxSz, "Number of data seconds to average per resulting point?"
	Prompt boxOffset, "Offset (in points) of right-most box point from template points?"
	
	silent 1; pauseUpdate
	Variable nPnts
	
	make /o/n=(numpnts ($xtemplate)) $outwv
	
	npnts = extractTemplateValues ($xtemplate,$ywv,$outWv, boxSz, boxOffset)
end

// Used by ChangeDataSpacing to compute the values of the new y-wave.  Also used by convertACATSchroms to determine
// individual values corresponding to injection times.
// Original version ssumed one point per second in ywv.  Changes in boxRight, boxLeft make remove this problem....
// however, in new version, boxSz and boxOffset still measured in seconds. 
Function extractTemplateValues (xtemplate, ywv, outWv, boxSz, boxOffset)
	wave	xtemplate, ywv, outWv
	Variable	boxSz, boxOffset
	
	Variable pnt = 0, boxRight, boxAve, boxLeft, boxPnt, cnt, tot
	do
		if ((xtemplate[pnt] <  leftx(ywv)) + (xtemplate[pnt] >  rightx(ywv))) 
			outwv[pnt] = NaN
		else
			boxRight = x2pnt (ywv, xtemplate[pnt]  + boxOffset)					//  boxRight = x2pnt (ywv, xtemplate[pnt]) + boxOffset
			boxLeft = x2pnt (ywv, xtemplate[pnt]  + boxOffset - boxSz + 1) 		//  boxLeft = boxRight - boxSz + 1 
			
			// Compute the box total
			boxPnt = boxLeft
			tot = 0
			cnt = 0
			do
				if (numtype(ywv[boxPnt]) ==0) 
					tot += ywv[boxPnt]
					cnt += 1
				endif
				boxPnt += 1
			while (boxPnt <= boxRight)
			
			// Compute the average
	 		if (cnt == 0) 
				outWv[pnt] =  NaN
			else
				outWv[pnt] = tot / cnt
			endif
		endif
		pnt+=1
	while (pnt < numpnts (outwv))
	return pnt
end

Macro ChangeDataSpacingMedian (ywv, xtemplate,outwv, boxSz, boxOffset,threshold)
	String ywv,xtemplate,outwv
	Variable boxSz=1, boxOffset=0,threshold = 5
	
	Prompt ywv, "Data wave (scaled in seconds) to be re-spaced ?"
	Prompt xtemplate, "Template of desired X spacing ?"
	Prompt outwv, "Name for re-spaced, result wave?"
	Prompt boxSz, "Number of data seconds to average per resulting point?"
	Prompt boxOffset, "Offset (in points) of right-most box point from template points?"
	Prompt threshold,"Min number of good data points per box?"
	
	silent 1; pauseUpdate
	Variable nPnts
	
	make /o/n=(numpnts ($xtemplate)) $outwv
	
	npnts = extractMedianTemplateValues ($xtemplate,$ywv,$outWv, boxSz, boxOffset,threshold)
end



Function extractMedianTemplateValues (xtemplate, ywv, outWv, boxSz, boxOffset,threshold)
	wave	xtemplate, ywv, outWv
	Variable	boxSz, boxOffset,threshold				//boxSz and boxOffset in secs
	
	Variable pnt = 0, boxRight, boxAve, boxLeft, boxPnt, cnt, maxBoxPnt, boxwd  		//boxwd in points
	
	Silent 1; PauseUpdate
	
	Make /O /N=2 TemplateBox	
		
	do
		if ((xtemplate[pnt] <  leftx(ywv)) + (xtemplate[pnt] >  rightx(ywv))) 
			outwv[pnt] = NaN
		else
			boxRight = x2pnt (ywv, xtemplate[pnt]  + boxOffset)					//  boxRight = x2pnt (ywv, xtemplate[pnt]) + boxOffset
			boxLeft = x2pnt (ywv, xtemplate[pnt]  + boxOffset - boxSz + 1) 		//  boxLeft = boxRight - boxSz + 1 
			
			
			boxwd = 1 + boxRight - boxLeft
			// Redimension box wave to span boxwd points
			if (numpnts(TemplateBox)!=boxwd)
				if(boxwd> 1)
					Redimension  /N=(boxwd) TemplateBox
				else
					Redimension  /N=(2) TemplateBox	
				endif
			endif
			
			boxPnt = BoxLeft
			TemplateBox = NaN
			maxBoxPnt = numpnts(ywv)
			cnt = 0
			do
				if ((numtype(ywv[BoxPnt])==0) * (boxPnt >= 0) * (boxPnt < maxBoxPnt))
					TemplateBox[cnt] = ywv[BoxPnt]
					cnt += 1
				else
				endif
				BoxPnt += 1
			while (BoxPnt <= BoxRight)
						
			if ((cnt < threshold)+(cnt<1))
				outwv[pnt] = NaN
			else
				if (cnt == 1)
					outwv[pnt] = TemplateBox[0]
				else
					ReDimension /N=(cnt) TemplateBox
					Sort TemplateBox TemplateBox
					outwv[pnt] = TemplateBox((cnt - 1)/2)
					ReDimension /N=(boxwd) TemplateBox
				endif				
			endif			
		endif
		
		pnt+=1
	while (pnt < numpnts (outwv))
	
	killwaves /Z/F TemplateBox
	
	return pnt
end


// Returns the average of boxSz points in wv, starting with the point "left."
Function doAverage (left, boxSz, wv)
	Variable		left, boxSz
	Wave			wv
	
	Variable pnt = left, tot=0, cnt=0
	do
		if ((pnt >= 0) * (pnt < numpnts (wv))) 
			if (numtype(wv[pnt])==0) 
				tot += wv[pnt]
				cnt += 1
			endif
		endif
		pnt += 1
	while (pnt < left + boxSz)
	if (cnt == 0) 
		return NaN
	else
		return tot / cnt
	endif
end


//==========================================================
// Wave smoothing functions
//==========================================================


// removeSpikes:
// Searches wv between x1 and x2 for single point spikes.  When it finds one, it replaces it by the
// ave of the adjacent two points.  A spike is defined as being greater than both of the adjacent points,
// and greater than the ave of them plus minH.   	

// The search range is specified in x-values, and if it is out of range, will be adjusted to the size of 
// the wave.
function removeSpikes (wv, x1, x2, minH)
	wave wv
	variable   x1, x2,minH
	
	variable p1, p2, pt, n
		
	p1=max (0, x2pnt(wv,x1))
	p2=min (numpnts (wv) - 1, x2pnt(wv,x2))
	pt=p1
	n=0
	
	if (p2 <= p1)
		return 0
	endif

	do
		if ((wv[pt] > wv[pt-1]) * (wv[pt]> wv[pt+1]) * (wv[pt]>((wv[pt-1]+wv[pt+1])/2)+minH))		
			wv[pt] = (wv[pt-1]+wv[pt+1]) / 2
			n+=1
		endif
		pt += 1
	while (pt <= p2)

	return n
end




// For the x range defined by the cursors (their order does not matter), sets
// wv to val.  Used to interactively define curve fit exclude zones.
macro setCsrRng (wvNm, val)
	string wvNm
	variable val
	
	silent 1				// NOTE: leave this as a macro.  need to set x-range in order to allow cursors to be on different waves.
	
	if ((strlen (csrWave(A)) > 0) * (strlen (csrWave(B)) > 0))
		$wvNm(xcsr(A),xcsr(B)) = val
	endif
end


// Reverses order of cursors if A is to the right of B.
function chkCsrsOrder()
	if ((strlen(csrWave(A)) > 0) * strlen(csrWave(B)) > 0)
		if (xcsr(A) > xcsr(B))
			variable tmp = xcsr(A)
			cursor A, $csrWave(A), xcsr(B)
			cursor B, $csrWave(B), tmp
		endif
	endif
end



// returns true if cusrsors on same wave/ false otherwise.... leaves cursors in position, A < B.
function chkCsrsSameWv ()
	if ((strlen(csrWave(A)) > 0) * strlen(csrWave(B)) > 0)
		if (CmpStr (csrWave(A), csrWave(B)) == 0)
			if (xcsr(A) > xcsr(B))
				variable tmp = xcsr(A)
				cursor A, $csrWave(A), xcsr(B)
				cursor B, $csrWave(B), tmp
			endif
			return 1
		endif
	endif
	return 0
end

// given 2 points on a line, (x1,y1) and (x2,y2), and an x value, returns the y value associated with the x value.
function interpVal (xUnknown, x1, y1, x2, y2)
	variable xUnknown, x1, y1, x2, y2
	return (((y2-y1) / (x2-x1)) * (xUnknown-x1) + y1)
end	

macro interpolateBetweenCsrs ()
	interpolateBetweenCsrsFUNC ()
end

// Changes all values in the y wave marked with the cursors between the cursors. Their final values
// are interpolated between the points actually marked by the cursors.
function interpolateBetweenCsrsFUNC ()
	variable x1, x2, y1, y2
	variable pnt, xUnknown
	string wvNm
	
	if (! chkCsrsSameWv ())
		doAlert 0, "Both cursors must be on same wave."
		return 0
	endif
	
	wvNm = CsrWave (A)
	Wave ywv = $wvNm
	
	
	
	
	if (strlen (CsrXWave(A)) > 0)		// X-Y plot
	
		wvNm = CsrXWave (A)
		Wave xwv = $wvNm

		x1 = xwv[pcsr (A)]
		x2 = xwv[pcsr (B)]
		y1 = ywv[pcsr (A)]
		y2 = ywv[pcsr (B)]
		
	
		pnt = pcsr(A)
		if (pnt < pcsr(B))	
			do 
				xUnknown = xwv[pnt]
				ywv[pnt] = interpVal (xUnknown, x1, y1, x2, y2)
				pnt+=1	
			while (pnt < pcsr(B))
		endif
	else

		// Scaled plot: ie, there is no xwave.

		x1 = pnt2x (ywv, pcsr (A))
		x2 = pnt2x (ywv, pcsr (B))
		y1 = ywv[pcsr (A)]
		y2 = ywv[pcsr (B)]
		
	
		pnt = pcsr(A)
		if (pnt < pcsr(B))	
			do 
				xUnknown = pnt2x (ywv, pnt)
				ywv[pnt] = interpVal (xUnknown, x1, y1, x2, y2)
				pnt+=1	
			while (pnt < pcsr(B))
		endif
	endif
end		
		

// Allows user to graphically select ranges of points to delete from a data wave and its corresponding x wave.
Macro DeletePointsBetweenCursors (xwv)
     	string		xwv=G_xwave
	prompt xwv,"Delete same points from an X-Wave [enter x-wave name or leave empty if no]?"
	G_xwave=xwv
	
	silent 1; pauseUpdate
	if ((StrLen(CsrWave(a))==0)+(StrLen(CsrWave(b))==0)) 
		DoAlert 0,"Put both cursors on the subject wave.  They mark range to delete (inclusive)."
		return
	endif
	if (CmpStr (CsrWave(a),CsrWave(b)) != 0) 
		DoAlert 0,"Cursors must both be on same wave"
		return
	endif
	
	Variable a = pcsr(a), b=pcsr(b), npnts, tmp
	String wv = CsrWave(a)
	if (b < a) 
		tmp = a; a = b; b = tmp
	endif
	npnts = b-a+1
	deletePoints a,npnts, $(CsrWave(a))
	printf "The following range of points, %d-%d, deleted from %s", a, b, CsrWave(a)
	if (StrLen (xwv) > 0) 
		deletePoints a,npnts, $xwv
		printf " and %s", xwv
	endif
	printf ".\r"
	cursor a,$wv, a-1; cursor b,$wv, a
	//
End	
	
//
// Appends a numeric suffix to root, creating a unique path name.  Returns the name via the
// global string "G_pathName".
// Coverted to the Igor built in function.  GSD 980106.
macro getUniquePathName (root)
	string root
	silent 1

	if (exists("G_pathName") !=	2)
		string /g G_pathName
	endif
	
	G_pathName = UniqueName(root, 12, 0)

end

//
// Returns the name of a potential path.  The name will start with root, and have a number appended.
// Coverted to the Igor built in function.  GSD 980106.
function /S uniquePathName (root)
	string root
	return UniqueName(root, 12, 0)
end


//=====|=====|=====|=====|=====|=====|=====|=====|=====|=====|=====
// 
//=====|=====|=====|=====|=====|=====|=====|=====|=====|=====|=====

// Returns a wave of point numbers from the src wave whose value compares positively
// with val, according to the comparison function.  Does not return the actual values.  Returns
// the row numbers.
function compareWv (srcWv, destRowsWv, strtRow, endRow, val, cmpFct)
 	wave srcWv, destRowsWv
 	variable strtRow, endRow, val
 	string cmpFct
 	
 	variable srcPt = strtRow, destPt = 0
 	
 	
 	//
 	// verify search bounds are in range
 	//
 	if ((strtRow > endRow) + (strtRow >= numpnts (srcWv)) + (endRow < 0))
 		return numpnts (destRowsWv)
 	endif
 	
 	if (strtRow < 0)
 		strtRow = 0
 	endif
 	
 	if (endRow >= numpnts (srcWv))
 		endRow = numpnts (srcWv) -  1
 	endif
  		

 	
 	redimension /n=(numpnts (srcWv)) destRowsWv
 	destRowsWv = -1
 	
 	
 	if (CmpStr (cmpFct, "EQUAL TO") == 0)
 		do
 			if (srcWv[srcPt] == val)
 				destRowsWv[destPt] = srcPt	
 				destPt += 1
 			endif
 			srcPt += 1
 		while (srcPt <= endRow)
 	else	
 	
 	if (CmpStr (cmpFct, "NOT EQUAL TO") == 0)
 		do
 			if (srcWv[srcPt] != val)
 				destRowsWv[destPt] = srcPt	
 				destPt += 1
 			endif
 			srcPt += 1
 		while (srcPt <= endRow)
 	else	
 	
 	if (CmpStr (cmpFct, "LESS THAN") == 0)
 		do
 			if (srcWv[srcPt] < val)
 				destRowsWv[destPt] = srcPt	
 				destPt += 1
 			endif
 			srcPt += 1
 		while (srcPt <= endRow)
 	else	
 	
 	if (CmpStr (cmpFct, "GREATER THAN") == 0)
 		do
 			if (srcWv[srcPt] > val)
 				destRowsWv[destPt] = srcPt	
 				destPt += 1
 			endif
 			srcPt += 1
 		while (srcPt <= endRow)
 	endif
 	endif
 	endif
 	endif
 
 	redimension /n=(max (2, destPt)) destRowsWv
 	return destPt
 end	
 	
 		
 			
//=====|=====|=====|=====|=====|=====|=====|=====|=====|=====|=====
// Set operations: treat Waves as sets.
// Properties of sets:  No duplicates, and order is irrelevant.  Thus, when required for 
// optimal speed or space, these routines sort and/or remove duplicates from the input
// waves.
//=====|=====|=====|=====|=====|=====|=====|=====|=====|=====|=====

// Removes duplicate values from the wave.  On return, the wave will be sorted. 
function removeDuplicates (wv)
	wave wv
	
	variable pt = 0, cnt = 0
	
	sort wv wv
	
	do
		if (wv[pt] == wv[pt + 1])
			wv[pt] = NaN
			cnt += 1
		endif	
		pt += 1
	while (pt < numpnts (wv) - 1)

	if (cnt > 0)
		sort wv wv
		redimension /n=(max (2, numpnts(wv) - cnt)) wv
	endif
end

// resWv == wv1 INTERSECTION wv2.   Expects wv1 and wv2 and resWv to exist, but redimensions
// resWv to actual result length and sorts wv1 and wv2.
function wvsAND (wv1,wv2,resWv)
	wave wv1,wv2,resWv
	
	variable pt1=0, pt2=0, resPt=0

	redimension /n = (min (numpnts(wv1), numpnts(wv2))) resWv 

	
	sort wv1 wv1
	sort wv2 wv2
	
	do
		if (wv1[pt1] == wv2[pt2])
			resWv[resPt] = wv1[pt1]
			resPt+=1
		endif

		if  (wv1[pt1] > wv2[pt2])
			pt2 += 1
		else
			pt1+=1
		endif				
	while ((pt1 < numpnts(wv1)) * (pt2 < numpnts(wv2)))
	
	redimension /n=(max (2,resPt)) resWv
	return resPt
end
	
// resWv == wv1 UNION wv2.    Expects wv1 and wv2 and resWv to exist, but redimensions
// resWv to actual result length.	
function wvsOR (wv1,wv2,resWv)
	wave wv1,wv2,resWv
	
	redimension /n = (numpnts(wv1) + numpnts(wv2)) resWv 
	
	resWv[0, numpnts(wv1) - 1] = wv1[p]
	resWv[numpnts(wv1), numpnts(wv1) + numpnts(wv2)] = wv2[p - numpnts(wv1)]
		
	removeDuplicates (resWv)
 	return numpnts (resWv)
end


// resWv == wv1 MINUS wv2.   This means that resWv will contain all the elements
// of wv1 which do not exists in wv2.  This is the only set operation which is not 
// commutative (ie, order of parameters, wv1 and wv2 matters).  Expects wv1 and wv2 and resWv to exist, but redimensions
// resWv to actual result length and sorts wv1 and wv2.
function wvsDIFF (wv1,wv2,resWv)
	wave wv1,wv2,resWv
	
	variable pt1=0, pt2=0, resPt=0, sharedPt = 0
	
	redimension /n = (numpnts(wv1)) resWv 
	make /o/n = (numpnts(wv1)) sharedIndexWv = -1

	resWv = -1
	
	sort wv1 wv1
	sort wv2 wv2
	
	// 
	// Create wave containing the point numbers of all the values in common to 
	// both wv1 and wv2.
	//
	
	do
		if (wv1[pt1] == wv2[pt2])
			sharedIndexWv[sharedPt] = pt1
			sharedPt+=1
		endif

		if  (wv1[pt1] > wv2[pt2])
			pt2 += 1
		else
			pt1+=1
		endif				
	while ((pt1 < numpnts(wv1)) * (pt2 < numpnts(wv2)))
	
	redimension /n=(max (2,numpnts(wv1) - sharedPt)) resWv
	redimension /n=(max (2, sharedPt)) sharedIndexWv
	
	
	//
	// Set resWv to the values of the wv1 points which are not shared by wv1 and wv2.
	//
	pt1 = 0
	resPt = 0
	sharedPt = 0
	
	do
		if (pt1 == sharedIndexWv[sharedPt])
			sharedPt+=1
		else
			resWv[resPt] = wv1[pt1]
			resPt += 1
		endif
		pt1 += 1
	while (pt1 < numpnts (wv1))
	
	killwaves sharedIndexWv
	
	return resPt	
end


// resWv == wv1 EXCLUSIVE-OR wv2.   This means that resWv will contain all the elements
// which exist in either wv1 or wv2 but not both.   Expects wv1 and wv2 and resWv to exist, but redimensions
// resWv to actual result length and sorts wv1 and wv2.
function wvsXOR (wv1,wv2,resWv)
	wave wv1,wv2,resWv
	
	make /o/n=(2) tmpANDwv, tmpORwv
	
	wvsOR (wv1, wv2, tmpORwv)
	wvsAND (wv1, wv2, tmpANDwv)
	wvsDIFF (tmpORwv, tmpANDwv, resWv)
	
	killwaves tmpORwv, tmpANDwv
	return numpnts (resWv)
end


//===============================================================
// Friendly macro interface to complicted XOPs and igor functions...
//===============================================================

//ееееееееееееееееееееееееееееееееееееееееееееееееееееееееее
// LOWESS XOP
//
//  еееее  Igor Command Line Calling Sequence:
//
//  loess xDataWave yDataWave fVariable, nSteps, delta, computedYWave residualWave
//weightFactorsWave
//
//  еееее Description:
//
//LOWESS computes the smooth of a scatterplot of yDataWave against xDataWave using
//robust locally
//weighted regression.  Fitted values, computedYWave, are computed at each of the
//values of the horizontal axis in xDataWave.
//
//  еееее Arguments:
//
//        xDataWave {input}: abscissas of the points on the scatterplot; the values in
//              xDataWave will be sorted from smallest to largest.
//
//        yDataWave {input}: ordinates of the points on the scatterplot.
//
//        fVariable {input}: specifies the amount of smoothing: fVariable is the fraction
//        of points used to compute eache fitted value;  as fVariable increases the
//        smoothed values become smoother.  Try fVarible in the range from 0.2 to 0.5.
//
//       nSteps    {input}: the number of iterations in the robust fit;  if nSteps = 0,the
//                  nonrobust fit is returned.  nSteps = 2 is usually sufficient.
//
//      delta     {input}: nonnegative parameter which may be used to save computations; 
//                      if the wave size is less than 100, set delta = 0.0.
//
//       computedYWave     {output}: fitted ordinates.
//
//       residualWave      {output}: residuals: yDataWave[i] - computedYWave[i].
//
//       weightFactorsWave {output]: robustness weights.
//еееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееее
macro  doLoess (ywvNm, xwvNm,frac, smNm, resNm,wghtFactNm)
	string xwvNm,ywvNm, smNm, resNm="_NONE_",wghtFactNm="_NONE_"
	variable frac=.3
	prompt ywvNm, "Data Wave (Y-values)", popup WaveList ("*",";","WIN:")
	prompt xwvNm, "X-values of Data Wave", popup "_CALCULATED_;"+WaveList ("*",";","WIN:")
	prompt frac, "Loess Fraction"
	prompt smNm, "Output (smoothed) wave"
	prompt resNm, "Output residual wave"
	prompt wghtFactNm, "Output weights wave"
	
	silent 1;pauseUpdate
	
	if (cmpstr (xwvNm, "_CALCULATED_") == 0)
		xwvNm = "temp_Loess_xwv"
		make /o/n=(numpnts ($ywvNm)) $xwvNm
		$xwvNm = pnt2x ($ywvNm, p)
	else
		if (numpnts ($ywvNm) != numpnts ($xwvNm))
			doAlert 0, ywvNm+" and "+xwvNm+" must have same number of points."
			return
		endif
	endif
	
	if (strlen (smNm) > 0)
		make /o/n=(numpnts ($ywvNm)) $smNm
	else
		doAlert 0, "You must specify name for the smoothed wave.... (was left blank this time)."
		return
	endif
	
	if (cmpstr (resNm, "_NONE_") == 0)
		resNm = "temp_Loess_reswv"
	endif	
	duplicate /o $ywvNm, $resNm


	if (cmpstr (wghtFactNm, "_NONE_") == 0)
		wghtFactNm = "temp_Loess_wghtwv"
	endif	
	duplicate /o $ywvNm, $wghtFactNm
	
	print "Loess", xwvNm ,ywvNm, frac, 2, 1, smNm, resNm, wghtFactNm
	loess $xwvNm $ywvNm frac, 2, 1, $smNm $resNm $wghtFactNm
	copyScales/P $ywvNm, $smNm
end


// Index wave gets pointers to unique integers in source wv.
//		
//	chwave={104,101,103,nan,nan,-10,333}
//	makeIndexWave (chwave)
//	print $(chWvNm + "_index")(chan), chan
//
function makeIndexWave (wv)
	wave wv
	
	string wvIndexNm = (nameOfWave (wv)) + "_index"
	wavestats/Q wv
	
	// Give index wave an extra NaN above and below actual channel range so 
	// accidental out of range inquiries will return NaN.
	
	make /o/n=(max (2, (V_max - V_min + 3))) $wvIndexNm = nan
	wave indexWv = $wvIndexNm

	SetScale /P x, (V_min - 1), 1, indexWv
	
	variable pt = 0
	do
		if (numtype (wv[pt]) == 0) 
			indexWv[x2pnt(indexWv, wv[pt])] = pt
		endif
		
		pt+=1
	while (pt < numpnts (wv))	
End

Function WaveDiff(w1,w2)
	string w1,w2
	variable index, npts
	
	if ((exists(w1) != 1) + (exists(w2) != 1))
		return 1
	endif
	
	wave wave1 = $w1, wave2 = $w2
		
	if(numpnts(wave1) != numpnts(wave2))
		return 1
	endif
	
	if  ((leftx(wave1) != leftx(wave2)) + (deltax(wave1) != deltax(wave2)))
		return 1
	endif
	
	index = 0
	npts = numpnts(wave1)
	do
		if (wave1[index] != wave2[index])
			return 1
		endif
		index += 1
	while (index < npts)
	return 0
End

Macro Replace(xwave, old, new)
	String xwave
	Variable old=0, new=NaN
	Prompt xwave,"Replace Wave: ",popup, WaveList("*", ";" , "WIN:"+WinName(0,3))
	Prompt old,"Old Value"
	Prompt new,"New Value"
	Silent 1
	DelayUpdate
	Variable a=numpnts($xwave)
	Variable g=Compare($xwave,old,new,a)
	Print "Replaced " + num2str(g) + " points out of " + num2str(a) + "."
EndMacro

Macro qReplace(xwave, old, new)
	String xwave
	Variable old=0, new=NaN
	Prompt xwave,"Replace Wave: ",popup, WaveList("*", ";" , "WIN:"+WinName(0,3))
	Prompt old,"Old Value"
	Prompt new,"New Value"
	Silent 1
	DelayUpdate
	Variable a=numpnts($xwave)
	Variable g=Compare($xwave,old,new,a)
EndMacro

//function version of qReplace
Function fReplace(xwave, old, new)
	wave xwave
	Variable old, new
	
	Compare(xwave,old,new,numpnts(xwave))
	
End

	
Function Compare(pwave, old,new,a) 
	Wave pwave
	Variable old,new,a
	Variable i=0, NumChanged = 0, slop=.0001
	
	if (numtype(old)==0)
		do 
			if ((pwave[i] >= old-slop)*(pwave[i] <= old+slop))
			pwave[i]=new
			NumChanged += 1
			endif
			i += 1
		while (i<a)
	else
		old = numtype(old)
		do
			if (numtype(pwave[i]) == old)
				pwave[i] = new
				NumChanged += 1
			endif
			i += 1
		while (i < a)
	endif
	
	return NumChanged
end
	
// Given 2 source waves (wv1 and wv2), allows user to create a result wave.  Each y-value in 
// the result wave will be the linear interpolation between the corresponding y-values in the
// source waves.  Y-values correspond if they have the same x value in all three waves.  The 
// user must supply the "time" of each wave which is used for weighting in the interpolation.
//
// User may also specify a range of x-values in the range of the waves over which to do the
// interpolation.  These are xStrt and xEnd.  To interpolate the entire wave, input xStrt>=xEnd.
//
// function will "make" the result wave if it doesn't already exist.
//
// Idea here is that 2 chromatograms are sampled at times tWv1 and tWv2, and user wants
// to estimate what a chrom sampled at some other time, tResWv, would look like, based on 
// point-by-point interpolation.
//
// ex: make t1=p, t2=2+p; mkInterpWv ("t1", 10, "t2", 25, -1, -1, "res", 20); display t1, t2, res
function mkInterpWv (wv1Nm, tWv1, wv2Nm, tWv2, xStrt, xEnd, resWvNm, tResWv)
	string  wv1Nm, wv2Nm, resWvNm
	variable  tWv1, tWv2, xStrt, xEnd, tResWv

	if (tWv1 == tWv2)
		doAlert 0, "Error in mkInterpWv: \"time\" of the two source waves may not be equal"
		return -1
	endif
		
	if ((exists (wv1Nm) == 1) * (exists (wv2Nm) == 1))
		wave wv1=$wv1Nm
		wave wv2=$wv2Nm
	else
		doAlert 0, "Error in mkInterpWv: Expected names of existing waves"
		return -1
	endif

	// If user gives an invalid x-range, then this is a flag to compute a valid range based
	// on the entire range of the result wave.  If result wave doesn't exist, use wv1
	if (xStrt >= xEnd) 
		if (exists (resWvNm) == 1)
			wave resWv = $resWvNm
			xStrt = pnt2x (resWv,0)
			xEnd =  pnt2x (resWv, numpnts (resWv) - 1)
		else
			xStrt = pnt2x (wv1,0)
			xEnd =  pnt2x (wv1, numpnts (wv1) - 1)
		endif
	endif		
		
	if ((leftx(wv1) > xStrt) + (leftx(wv2) > xStrt) + (rightx(wv1) < xEnd) + (rightx(wv2) < xEnd))
		doAlert 0, "Error in mkInterpWv: Range of x-values invalid.  Exceeds the range of the source waves."
		return -1
	endif

	// Create result wave, if it doesn't exist.  The duplicate function takes care of scaling.
	if (exists (resWvNm) != 1)
		duplicate /r=(xStrt, xEnd) wv1, $resWvNm
	endif
	wave resWv=$resWvNm
					
					
	// Interpolate all points in the result wave in specified x-interval.  Base this on x-values of
	// source waves, in case they do not have same scale as each other or the result wave.
	
	variable timeNormConst, resPt, resX
	
	timeNormConst = (tResWv - tWv1) / (tWv2 - tWv1)
	
	resX = xStrt
	resPt = x2pnt (resWv, resX)
	do
		resX = pnt2x( resWv, resPt)		
		resWv[resPt] = wv1(resX) + (wv2(resX) - wv1(resX)) * timeNormConst 		// Interpolate one x-val

		resPt += 1
	while (pnt2x (resWv, resPt) <= xEnd)
end

function wDup(source,dest,len)
	string source,dest
	variable len
	
	if (exists(source) != 1)
		make /O/N=(len) $dest = NaN
	else
		duplicate /O $source $dest
	endif
end

//
// Returns 1 if file exists, 0 otherwise
//
Function Fexists(pname,fname)
	string pname, fname
	
	variable handle
	
	open /Z /R /P=$pname handle as fname
	if (V_flag)
		return 0
	else
		close handle
		return 1
	endif
End Function

//
// Appends a recreation macro for the top object (graph, table, panel, or layout) to a notebook window.
// The macro text can later be pasted into a procedure window, compiled, and run to recreate the 
// display.  If the notebook doesn't exist, creates it.
//
// Provides a default notebook name, which can be overridden in either of two ways: by either typing in 
// a different name, or by asking the macro to derive the notebook name from the object name.
//
macro saveRecreationMacro (nameType, optionalName, rmObj, optionalDoc)	
        variable  nameType = 1, rmObj = 1
        string optionalName = "displayMacros", optionalDoc= date() + "; " + time()
        prompt nameType, "Source for the name of notebook?", popup "Use \"Notebook name\" below;Derive from object name"
        prompt optionalName, "Notebook name: "
        prompt rmObj, "Remove display after saving it?", popup "Yes;No"
        prompt optionalDoc, "Optional documentation for the recreation macro:"

        silent 1; pauseUpdate
	
        string objNm, nb
        objNm = WinName(0,1+2+4+64) 
        if (strlen (objNm) == 0) 
                return
        endif

        if (nameType == 1)
        nb = optionalName
        else
                nb = "saved" + objNm
        endif
	
	
        if  (strlen (WinList (nb, ";","WIN:16")) == 0)
                newnotebook  /n=$nb /f=0 /v=0
        endif
	
        notebook $nb, selection={endoffile,endoffile}	
		
        if (strlen (optionalDoc) > 0)
                notebook $nb, text="\r// " + optionalDoc 
        endif
        notebook $nb, text="\r" + WinRecreation(objNm,0) +"\r"
		
        if (rmObj == 1)
                doWindow /k $objNm
        endif		
end

// Returns the average of a continuous segment of a wave.  Initially intended to compute chrom
// baseline average.
function baselineSegmentAverage (wv, xStrt, xEnd)
	wave wv
	variable xStrt, xEnd
	
	variable pt,  avg, tmp
	variable /D sum=0, strtPt, endPt
	
	if (xStrt > xEnd) 
		tmp = xStrt
		xStrt = xEnd
		xEnd = tmp
	endif
	
	strtPt = x2pnt (wv,xStrt)
	endPt = x2pnt (wv, xEnd)
	
	pt = strtPt
	do
		sum += wv[pt]
		pt += 1
	while (pt <= endPt)

	avg = sum / (endPt - strtPt +1)
	
	return avg
end

// concatenates wv2 onto the end of wv1.  Wv2 is not altered.
function concatWvs(wv1,wv2)
	wave wv1, wv2
	
	variable strtPt = numpnts (wv1), nPts = numpnts (wv2)

	InsertPoints strtPt, nPts, wv1
	wv1[strtPt,] = wv2[p - strtPt]	
end


