#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method.
//#include <Strings as Lists>
#include <remove points>
#include <concatenate waves>

Menu "GraphMarquee"
	"WaveStats In Marquee", WaveStatsInMarquee()
	"Fit Points In Marquee", FitPointsInMarquee()
	"NaN Points In Marquee", NaNInMarquee()
end

// replaces fReplace with SelectNumber function (this is a bit faster)
function gReplace( wv, OrgVal, ReplacedVal )
	wave wv
	Variable /d OrgVal, ReplacedVal
	
	Variable slop = 0.0001
	wv = SelectNumber((wv >= OrgVal-slop) && (wv <= OrgVal+slop), wv, ReplacedVal)
	
end

function HighChop(wv, value)
	wave wv
	variable value
	
	wv = SelectNumber(wv >= value, wv, NaN)
	
end

//Replaces all values with NaN in wv less than 'value'
function LowChop(wv, value)
	wave wv
	variable value
	
	wv = SelectNumber(wv <= value, wv, NaN)

end
		
// bug fix GSD 070920
function KillNaN(w1, w2)
	wave w1, w2

	if ( cmpstr(NameOfWave(w1), NameOfWave(w2)) == 0 )
		RemoveNaNs(w1)
	else
		RemoveNaNsXY(w1, w2)
	endif
	
	return numpnts(w1)
end

//Kills all rows of four waves that contain an Nan in either of them.
//If you have only three waves put a duplicate call to one of the waves in position four.
// re-written GSD 070920
function killNaN4 (w1, w2, w3, w4)
	wave w1, w2, w3, w4

	Variable p, numPoints, numNaNs
	Variable w1v, w2v, w3v, w4v
	
	numNaNs = 0
	p = 0											// the loop index
	numPoints = numpnts(w1)			// number of times to loop

	do
		w1v = w1[p]
		w2v = w2[p]
		w3v = w3[p]
		w4v = w4[p]
		if ((numtype(w1v)==2) %| (numtype(w2v)==2) %| (numtype(w3v)==2) %| (numtype(w4v)==2))		// either is NaN?
			numNaNs += 1
		else										// if not an outlier
			w1[p - numNaNs] = w1v		// copy to input wave
			w2[p - numNaNs] = w2v		// copy to input wave
			w3[p - numNaNs] = w3v		// copy to input wave
			w4[p - numNaNs] = w4v		// copy to input wave
		endif
		p += 1
	while (p < numPoints)
	
	// Truncate the wave
	DeletePoints numPoints-numNaNs, numNaNs, w1, w2, w3, w4
	
	return numpnts(w1)
	
end

Function IfExistDuplicate (wvOrg, wvDup)
	string wvOrg, wvDup
	
	if (exists(wvOrg))
		duplicate /o $wvOrg $wvDup
	endif
end

Proc con (wv1,wv2)
	string wv1,wv2
	prompt wv1, "1st wave (the second is append to this wave)"
	prompt wv2, "2nd wave"
	
	silent 1; PauseUpdate
	
	ConcatenateWaves(wv1, wv2)

end

function concatdaWaves (wv1,wv2)
	wave wv1, wv2
	
	variable pt = numpnts (wv1)
		
	redimension /n=(numpnts (wv1) + numpnts (wv2)) wv1	
	wv1[pt, numpnts(wv1) - 1] = wv2[p - pt]
end

proc Insertvalue (comp, ins, oper, compVal, insVal)
	string comp, ins, oper="=="
	variable compVal, insVal
	prompt comp, "Wave to compare to"
	prompt ins, "Wave to insert into"
	prompt oper, "Comparison operation", popup, "==;>=;<=;>;<"
	prompt compVal, "Comparison value"
	prompt insVal, "Insert value"
	
	silent 1
	
	InsertvalueFUNCT ($comp, $ins, oper, compVal, insVal)
end

function InsertvalueFUNCT (compwv, inswv, oper, compVal, insVal)
	wave compwv, inswv
	variable compVal, insVal
	string oper
	
	variable nComp = numpnts (compwv), nIns = numpnts (inswv)
	
	if (nComp != nIns ) 
		printf  "Wave:  %s and Wave:  %s are not the same length.\r", NameOfWave(compwv), NameOfWave(inswv)
		abort "The compare wave and the insert wave are not the same length"
	endif
	
	if (cmpstr(oper, "==") == 0)
		do
			nComp -= 1
			if ( compwv[nComp] == compVal )
				inswv[nComp] = insVal
			endif
		while (nComp != 0)
	endif
	
	if (cmpstr(oper, ">=") == 0)
		do
			nComp -= 1
			if ( compwv[nComp] >= compVal )
				inswv[nComp] = insVal
			endif
		while (nComp != 0)
	endif

	if (cmpstr(oper, "<=") == 0)
		do
			nComp -= 1
			if ( compwv[nComp] <= compVal )
				inswv[nComp] = insVal
			endif
		while (nComp != 0)
	endif

	if (cmpstr(oper, ">") == 0)
		do
			nComp -= 1
			if ( compwv[nComp] > compVal )
				inswv[nComp] = insVal
			endif
		while (nComp != 0)
	endif

	if (cmpstr(oper, "<") == 0)
		do
			nComp -= 1
			if ( compwv[nComp] < compVal )
				inswv[nComp] = insVal
			endif
		while (nComp != 0)
	endif
	
end

// Solutions to y = a*x^2 + b*x + c
function QuadSolution(a, b, c, sign)
	variable a, b, c
	string sign
	
	variable Xout
	if (cmpstr(sign,"-") == 0)
		Xout = (-b - sqrt(b^2 - 4*a*c)) / (2*a)
	else
		Xout = (-b + sqrt(b^2 - 4*a*c)) / (2*a)
	endif
	return Xout
end		

// Uncertainty of quadratic solution  y = a*x^2 + b*x + c
function QuadSolutionERR(coefWv, errWv, errAB, errAC, errBC, y, errY, sign, prt)
	wave coefWv, errWv
	string sign
	variable prt, y, errY, errAB, errAC, errBC
	
	variable a = coefWv[2], b = coefWv[1], c = coefWv[0] - y
	variable errA = errWv[2], errB = errWv[1], errC = errWv[0] 
	variable s
	
	if (cmpstr(sign, "+") == 0)
		s = 1
	else
		s = -1
	endif
	
	variable q = SQRT(b^2 - 4*a*c)
	variable r = (b^2 - 4*a*c)^(3/2)
	variable Aout = (-s*c/(a*q) + b/(2*a*a) -s*q/(2*a*a)) * errA
	variable Bout = (-1 + s*b/q)/(2*a) * errB
	variable Cout = -s/q * errC
	variable Yout = s/q * errY
	variable ABout = ( (-(-1 + s*b / q) / (2*a*a)) + s*(b*c)/(a*r) ) * errAB
	variable ACout = ((-s*2*c) / r) * errAC
	variable BCout = s*(b / r) * errBC
	
	if (prt == 1)
		printf "a = %g  b = %g  c = %g \r", a, b, c
		printf "q = %g \r", q
		printf "Err in a = %g  Err in b = %g  Err in c = %g Err in y = %g \r", abs(Aout), abs(Bout), abs(Cout), abs(Yout)
		printf "Covariance AB = %g, AC = %g, BC = %g \r", ABout, ACout, BCout
	endif
	
	return SQRT(Aout^2 + Bout^2 + Cout^2 + Yout^2 + ABout^2 + ACout^2 + BCout^2)
end
	
//Uncertainty of y in y = ax^2 + bx + c
function PolyERR(coefwv, errwv, x, xerr)
	variable x, xerr
	wave coefwv, errwv
	
	variable a = coefwv[2], b = coefwv[1], c = coefwv[0]
	variable aerr = errwv[2], berr = errwv[1], cerr = errwv[0]
	variable Aout = x^2*aerr
	variable Bout = x*berr
	variable Cout = cerr
	variable Xout = (2*a*x + b)*xerr
	
	return SQRT(Aout^2 + Bout^2 + Cout^2 + Xout^2)
end

function /s SigFigwERR (num, err)
	variable num, err
	
	variable mult = 1, check
	string fixed
	
	if (err >= 1)
		fixed = num2str(round(num)) + " ± " + num2str(round(err))
		return fixed
	endif
	
	do
		check = err * mult
		mult *= 10
	while ( check < 1)
	mult /= 10				// step back once
	
	err = round(err*mult)/mult
	num = round(num*mult)/mult
	
	fixed = num2str(num) + " ± " + num2str(err)
	return fixed	
	
end

Function /D Linear_Fit (w, x)
	Wave /D w; Variable /D x
	
	return w[1]*x + w[0]
end

Function /D Poly3_Fit (w, x)
	Wave /D w; Variable /D x
	
	return w[2]*x^2 + w[1]*x + w[0]
end

Function /D Poly4_Fit (w, x)
	Wave /D w; Variable /D x
	
	return w[3]*x^3 + w[2]*x^2 + w[1]*x + w[0]
end

Function /d Gauss_Fit (w, x)
	wave /d w
	variable /d x
	
	return w[0] + w[1]*exp(-((x - w[2])/w[3])^2)
end

function /d SumPortionOfWave(wv, strt, end)
	wave wv
	variable strt, end
	
	variable /d sum=0
	variable inc = strt
	
	do
		if (numtype(wv[inc])==0)
			sum += wv[inc]
		endif
		inc += 1
	while (inc <= end)
	
	return sum
end

// Updated 20020410 to have x1 and x2 range.
Function MedianOfWave(w, x1, x2)
	Wave w
	Variable x1, x2
	
	Variable result

	// Removes any dependance
	make /o/n=(numpnts(w)) tempMedianWave=nan
	tempMedianWave = w
	
	Duplicate/o/R=(x1, x2) tempMedianWave, tempMedianWave1			// Make a clone of wave
	RemoveNaNs(tempMedianWave1)
	Sort tempMedianWave1 tempMedianWave1			// Sort clone
	SetScale/P x 0,1,tempMedianWave1
	result = tempMedianWave1((numpnts(tempMedianWave1)-1)/2)
	KillWaves tempMedianWave, tempMedianWave1

	return result
End

function CompareWvLength (wv1, wv2)
	string wv1, wv2
	
	if ((exists(wv1) != 1) * (exists(wv2) != 1))
		return 0
	endif
	
	if (numpnts($wv1) != numpnts($wv2))
		return 0
	endif
	
	return 1
end
	
function FitPointsInMarquee ()

	string ywvlst, xwvlst, fitType="line"
	prompt ywvlst, "Y-axis wave", popup, TraceNameList("", ";", 1)
	prompt fitType,"Fit type:", popup,"gauss;lor;exp;dblexp;sin;line;poly 3;poly 4;poly 5;poly 6;poly 7;poly 8;poly 9"
	DoPrompt "Fit Points In Marquee", ywvlst, fitType

	wave wvY = TraceNameToWaveRef("", ywvlst)
	string com

	GetMarquee left, bottom
	
	// check for XY pairing
	if ( WaveExists(XWaveRefFromTrace("", ywvlst)) )
		wave wvX = XWaveRefFromTrace("", ywvlst)
		Extract /O wvY, JunkY, ( (wvX > V_left) && (wvX < V_right) && (wvY < V_top) && (wvY > V_bottom) )
		Extract /O wvX, JunkX, ( (wvX > V_left) && (wvX < V_right) && (wvY < V_top) && (wvY > V_bottom) )
	else
		Make /O/n=(numpnts(wvY)) JunkXorg = pnt2x(wvY, p)
		Extract /O wvY, JunkY, ( (pnt2x(wvY, p) > V_left) && (pnt2x(wvY,p) < V_right) && (wvY < V_top) && (wvY > V_bottom) )
		Extract /O JunkXorg, JunkX, ( (JunkXorg > V_left) && (JunkXorg < V_right) && (wvY < V_top) && (wvY > V_bottom) )
	endif

	sprintf com, "CurveFit %s, JunkY /X=JunkX /D", fitType
	execute com
	wave fit_junkY
	Duplicate /o fit_JunkY, $"fit_" + ywvlst
	AppendToGraph $"fit_" + ywvlst

	Killwaves /Z fit_JunkY, JunkXorg, JunkY, JunkX
	
end

// updated to be aware of horizontal and vertical axis. GSD 210709
function WaveStatsInMarquee ()

	string traceName
	Prompt traceName, "Stats on which wave?", popup, TraceNameList("", ";", 1)
	DoPrompt "WaveStatsInMarquee wave choice", traceName

	Wave/Z wy= TraceNameToWaveRef("",traceName)

	String info= TraceInfo("", traceName, 0)
	String hAxis= StringByKey("XAXIS", info)
	String vAxis= StringByKey("YAXIS", info)
	GetMarquee $hAxis, $vAxis
	Variable xMin= min(V_right, V_left)
	Variable xMax= max(V_right, V_left)
	Variable yMin= min(V_top, V_bottom)
	Variable yMax= max(V_top, V_bottom)
	
	// Save backup of wy for Undo
	//SaveTraceBackup(graphName, traceName, wy)
	
	// make a mask wave indicating points which lie within the marquee
	String maskName=UniqueName("mask",1,0)
	Duplicate/O wy, $maskName
	WAVE mask = $maskName
	
	Wave/Z wx = XWaveRefFromTrace("",traceName)
	if( WaveExists(wx) )    // Y vs x
	    mask = (wy > yMin) && (wy < yMax) && (wx > xMin) && (wx < xMax) ? wy : NaN
	else        // just a waveform, use X scaling
	    mask = (wy > yMin) && (wy < yMax) && (pnt2x(wy,p) > xMin) && (pnt2x(wy,p) < xMax) ? wy : NaN
	endif
	wavestats mask
	KillWaves/Z mask
	
end

// updated to be aware of horizontal and vertical axis. GSD 210709
function NaNInMarquee ()

	string traceName
	Prompt traceName, "NaN point on which wave?", popup, TraceNameList("", ";", 1)
	DoPrompt "NaNStatsInMarquee wave choice", traceName

	Wave/Z wy= TraceNameToWaveRef("",traceName)

	String info= TraceInfo("", traceName, 0)
	String hAxis= StringByKey("XAXIS", info)
	String vAxis= StringByKey("YAXIS", info)
	GetMarquee $hAxis, $vAxis
	Variable xMin= min(V_right, V_left)
	Variable xMax= max(V_right, V_left)
	Variable yMin= min(V_top, V_bottom)
	Variable yMax= max(V_top, V_bottom)
	
	// Save backup of wy for Undo
	//SaveTraceBackup(graphName, traceName, wy)
	
	// make a mask wave indicating points which lie within the marquee
	String maskName=UniqueName("mask",1,0)
	Duplicate/O wy, $maskName
	WAVE mask = $maskName
	
	Wave/Z wx = XWaveRefFromTrace("",traceName)
	if( WaveExists(wx) )    // Y vs x
	    mask = (wy > yMin) && (wy < yMax) && (wx > xMin) && (wx < xMax) ? NaN : 1
	else        // just a waveform, use X scaling
	    mask = (wy > yMin) && (wy < yMax) && (pnt2x(wy,p) > xMin) && (pnt2x(wy,p) < xMax) ? NaN : 1
	endif
	wy *= mask
	KillWaves/Z mask
	
end


// Very similar to the Igor function NumVarOrDefault but also creates a global variable
function NumMakeOrDefault(varStr, varVal)
	string varStr
	variable varVal
	
	string com
	variable retVal = NumVarOrDefault(varStr, varVal)
		
	if (exists(varStr) != 2)
		sprintf com, "variable /g %s=%f", varStr, varVal
		execute com
	endif
	
	return retVal
		
end

function/s StrMakeOrDefault(varStr, varVal)
	string varStr,varVal
	
	string com
	string retVal = StrVarOrDefault(varStr, varVal)
		
	if (exists(varStr) != 2)
		sprintf com, "string /g %s=\"%s\"", varStr, varVal
		execute com
	endif
	
	return retVal
		
end


// Function rutuns the current year
function ReturnCurrentYear()

	return str2num(StringFromList(2, Secs2date(DateTime,-1), "/")[0,3])
	
end

// Function returns mid point of month
function ReturnMidDayOfMonth(year, month)
	variable month, year
	
	variable ly = 0
	
	if (mod(year,4) == 0)
		if (year == 2000)
			ly = 0
		else
			ly = 1
		endif
	endif
	
	if (month == 1)
		return 31/2
	elseif ((month == 2) * (ly == 1))
		return 29/2
	elseif ((month == 2) * (ly == 0))
		return 28/2
	elseif (month == 3)
		return 31/2
	elseif (month == 4)
		return 30/2
	elseif (month == 5)
		return 31/2
	elseif (month == 6)
		return 30/2
	elseif (month == 7)
		return 31/2
	elseif (month == 8)
		return 31/2
	elseif (month == 9)
		return 30/2
	elseif (month == 10)
		return 31/2
	elseif (month == 11)
		return 30/2
	elseif (month == 12)
		return 31/2
	endif
end


// same as function above but without a for loop
// handles leap year
//function/d decday2secs(dec)
//	variable /d dec
//	
//	variable numleap = (dec < 2000) ? floor((dec-1904)/4) : floor((dec-1904)/4)-1
//	variable numNONleap = max(floor(dec-1904) - numleap,0)
//	variable currYearLP = (dec != 2000) ? (mod(floor(dec),4) == 0) : 0
//	return 60*60*24 * (366*numleap +  365*numNONleap + (365+currYearLP)*(dec-floor(dec)) + (currYearLP==0) )
//end

// updated GSD 211006
function/d decday2secs(dec)
	variable /d dec

	variable currYearLP = (dec != 2000) ? (mod(floor(dec),4) == 0) : 0
	variable secs = (365 + currYearLP) * 86400
	
	return Date2secs(floor(dec), 1, 1) + (dec - floor(dec)) * secs
end



// ret == 0 will return the month
// ret == 1 will return the day
function DayOfYear2date( YYYY, DOY, ret )
	variable YYYY, DOY, ret

	variable M, D
	
	// leap year	
	variable LY = (mod(YYYY,4) == 0)
	if (YYYY == 2000)
		LY = 0
	endif

	if ( DOY <= 31 )				// Jan
		M = 1
		D = DOY
	elseif ( DOY <= 59 + LY )		// Feb
		M = 2
		D = DOY - 31
	elseif ( DOY <= 90 + LY )		// Mar
		M = 3
		D = DOY - 59 - LY
	elseif ( DOY <= 120 + LY )		// Apr
		M = 4
		D = DOY - 90 - LY
	elseif ( DOY <= 151 + LY )		// May
		M = 5
		D = DOY - 120 - LY
	elseif ( DOY <= 181 + LY )		// Jun
		M = 6
		D = DOY - 151 - LY
	elseif ( DOY <= 212 + LY )		// Jul
		M = 7
		D = DOY - 181 - LY
	elseif ( DOY <= 243 + LY )		// Aug
		M = 8
		D = DOY - 212 - LY
	elseif ( DOY <= 273 + LY )		// Sep
		M = 9
		D = DOY - 243 - LY
	elseif ( DOY <= 304 + LY )		// Oct
		M = 10
		D = DOY - 273 - LY
	elseif ( DOY <= 334 + LY )		// Nov
		M = 11
		D = DOY - 304 - LY
	elseif ( DOY <= 365 + LY )		// Dec
		M = 12
		D = DOY - 334 - LY
	endif
	
	if (ret == 0)
		return M
	else
		return D
	endif
	
end

// function to replace the XOP xFileNotExists
function FileNotExists (filename, path)
	string filename, path
	
	variable testref
	
	Open /Z=1/R/P=$path testref as filename

	if ( V_flag == 0 )
		Close testref
		return 0
	else
		print "File", filename, " was not found." 
		return 1
	endif
	
end


// Function to syncronize two data sets.
// BaseDate and Dat2sync need to be the same kind of time waves (either decimal date or seconds)
// A syncronized data wave will be created named: NameOfWave(Data2sync) + suffix
function SyncData( BaseDate, Date2sync, Data2sync, suffix )
	wave BaseDate, Date2sync, Data2sync 
	string suffix
	
	make /d/o/n=(numpnts(BaseDate)) tttindex = nan,  tttindex2 = nan, tttmp = nan

	tttindex = BinarySearchInterp(Date2sync, BaseDate)
	tttindex2 = tttindex[p] - tttindex[p+1]
	highchop(tttindex2, -0.02)
		
	tttmp = Data2sync[tttindex] * tttindex/tttindex * tttindex2/tttindex2
	duplicate/o tttmp $(Nameofwave(Data2sync)+suffix)
	
	Print "Created: " + (Nameofwave(Data2sync)+suffix)
	
	killwaves tttmp, tttindex, tttindex2
	
end

Function TimeAfunction( strToExecute )
	string strToExecute
	
	Variable timerRefNum, microSeconds
	timerRefNum = startMSTimer
	
	execute strToExecute
	
	microSeconds = stopMSTimer(timerRefNum)
	
	Print "It took ", num2str(microSeconds/1e6), " seconds to execute: ", strToExecute
	
end


// returns first data point number in wave
function FirstGoodPt(wv)
	wave wv
	
	Wavestats /M=1/Q wv
	if (numtype(v_avg) == 2)
		return -1
	endif
	
	variable i
	for (i=0; i<numpnts(wv); i+=1)
		if (numtype(wv[i]) != 2 )
			return i
		endif
	endfor
	
	return -1
end

// returns last data point number in wave
function LastGoodPt(wv)
	wave wv
	
	Wavestats /M=1/Q wv
	if (numtype(v_avg) == 2)
		return -1
	endif
	
	variable i
	for (i=numpnts(wv)-1; i>=0; i-=1)
		if (numtype(wv[i]) != 2 )
			return i
		endif
	endfor
	
	return -1
end
