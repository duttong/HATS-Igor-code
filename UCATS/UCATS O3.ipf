#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Set of functions to merge UCATS O3 and O3x data sets.
// GSD 140301
// A few adjustments for DCOTSS - only O3x EJH 201230

#include <FunctionProfiling>

menu "UCATS_Ozone"
	"Plot All Ozone parameters<B", OzonePlots()
	" Ozone concentration", OzoneConcFigure()
	" cell temp", O3Plot1(o3temp, "Ozone Cell Temp (C)"); appendtograph o3xtemp vs timewo3x; legend
	" cell press", O3Plot1(o3pres, "Ozone Cell Pressure (C)"); appendtograph o3xpres vs timewo3x; legend
	"-"
	"Backup Both O3 data sets", BackupO3()
	"Backup O3x data set", BackupO3x()
	"Restore O3 Backup"
	"Restore O3x Backup"
	"-"
	"O3 Diff in Time"
	"O3 correlation", O3vsO3x()
	"-"
	"Use O3x directly", UseO3x(o3xbest)
	"Adj O3x Waves"
	"Merge O3 and O3x", BinO3x(o3xbest)
	"O3 merged data figure", o3mergplot()
end

Function BackupO3()
	wave o3xbest, TimeWo3x
	wave o3best, TimeWo3
	Duplicate /o o3xbest, o3xbest_org
	Duplicate /o TimeWo3x, TimeWo3x_org
	Duplicate /o o3best, o3best_org
	Duplicate /o TimeWo3, TimeWo3_org
end

Function BackupO3x()
	wave o3xbest, TimeWo3x
	Duplicate /o o3xbest, o3xbest_org
	Duplicate /o TimeWo3x, TimeWo3x_org
end

Function RestoreO3Backup()
	wave o3best_org, TimeWo3_org
	Duplicate /o o3best_org, o3best
	Duplicate /o TimeWo3_org, TimeWo3
end

Function RestoreO3xBackup()
	wave o3xbest_org, TimeWo3x_org
	Duplicate /o o3xbest_org, o3xbest
	Duplicate /o TimeWo3x_org, TimeWo3x
end

Function OzoneConcFigure()
	Wave o3best, o3xbest, timeWo3x
	O3Plot1(o3best, "Ozone (ppm)")
	appendtograph o3xbest vs timewo3x
	legend
	ModifyGraph mode=3,msize=2,marker(o3best)=19
	ReorderTraces o3best,{o3xbest}
end

Function AdjO3xWaves()
	wave o3xbest, TimeWo3x	
	CalcO3_fitparams(o3xbest, TimeWo3x)
end
		

// "all-in-one" fit function to o3best
Function OzoneFit(pw, yw, xw) : fitfunc
	Wave pw, yw, xw
	
	Wave o3 = o3_sm
	Variable ptL = pnt2x(o3, 0), ptR = pnt2x(o3, numpnts(o3)-1)
	xw = SelectNumber(xw < ptL, xw, ptL)
	xw = SelectNumber(xw > ptR, xw, ptR)
	yw = pw[0] + pw[1]*o3(xw + pw[2])
end

// wrapper function for the OzoneFit FuncFit.  Creates a smooth o3best wave that
// o3xbest is fitted too.  The regression calculates offset, gain and time shift.  These
// values are applied to o3xbest.
Function CalcO3_fitparams(o3x, o3xT)
	wave o3x, o3xT
	
	Wave o3 = o3best
	Wave o3t = TimeWo3
	Variable num = numpnts(o3)

	// Can't have nans in the o3, o3t waves.  Interpolated wave will be nan free.	
	Interpolate2/T=1/N=(num/2)/Y=o3_sm o3t, o3
	Smooth 1, o3_sm
	
	// Waves used in the fit function.
	Make /o/d coefs = {1,1,0}, eps = {1e-6, 1e-6, 0.01}

	FuncFit/L=2000 /NTHR=0 OzoneFit coefs  o3x /X=o3xT/E=eps
	
	printf "%s Offset: %3.5f ppb, Gain: %3.5f\r", Nameofwave(o3x), -coefs[0], 1/coefs[1]
	printf "O3 time-shift: %2.3f secs\r", -coefs[2]
	
	// apply shifts
	o3x -= coefs[0]
	o3x /= coefs[1]
	o3t -= coefs[2]		// shift the o3t wave (not o3xt)

end

// Measure the Difference between both ozone data sets over time
function O3diffinTime()

	Wave TO3 = TimeWO3
	Wave TO3x = TimeWO3x
	Wave O3 = o3best
	Wave O3x = o3xbest

	Variable i, pt, gp1
	Variable delta = 30
	Variable nm = ceil(TO3[numpnts(TO3)-1]-TO3[0])/delta
	Variable ptLo3x, ptL = 0
	Variable ptRo3x, ptR = BinarySearchInterp(TO3, TO3[0] + delta)
	Variable o3mean
	
	Make /o/D/n=(nm) O3diff = nan, O3diff_T = nan
	SetScale d 0,0,"dat", O3diff_T

	for(i=0; i<nm-1; i+=1)
		O3diff_T[i] = mean(TO3, ptL, ptR)
		if (numtype(O3diff_T[i]) == 2)
			O3diff_T[i] = O3diff_T[i-1] + (O3diff_T[i-2] - O3diff_T[i-1])
		endif
		Wavestats/Q/M=1/R=[ptL,ptR] O3
		O3mean = SelectNumber(V_npnts >2, nan, V_avg)
		ptLo3x = BinarySearchInterp(TO3x, TO3[ptL])
		ptRo3x = BinarySearchInterp(TO3x, TO3[ptR])
		Wavestats/Q/M=1/R=[ptLo3x,ptRo3x] O3x
		O3diff[i] = SelectNumber(V_npnts>2, nan, O3mean - v_avg)
		ptL = ptR
		ptR= BinarySearchInterp(TO3, TO3[0] + i*delta)
	endfor

	String win = "OzoneDiffs"
	DoWindow /K $win
	Display /K=1/W=(574,47,1206,305) O3diff vs O3diff_T
	ModifyGraph mode(O3diff)=3
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left "O3 - O3x (ppb)"
	Label bottom "Time"
	DoWindow /C $win

	// change the fit parameter here if the fit is bad
	//CurveFit/NTHR=1 poly_XOffset 5,  O3diff /X=O3diff_T /D 
	//Wave W_coef
	//Duplicate /O W_coef, Diff_coef
	//o3xbest_adj = O3x + poly(Diff_coef, (To3x-To3x[0]))
	//ModifyGraph rgb(fit_O3diff)=(16385,16388,65535)

	// Loess works better than a poly fit
	Duplicate/O O3diff, O3diff_smth
	DeletePoints numpnts(O3diff_smth)-1, 1, O3diff_smth, O3diff_T
	Loess/V=2/N=200/ORD=2/E=1 factors={O3diff_T}, srcWave= O3diff_smth
	AppendToGraph O3diff_smth vs O3diff_T
	ModifyGraph rgb(O3diff_smth)=(16385,16388,65535)
	gp1 = FirstGoodPt(O3diff)
	O3diff_smth[0,gp1] = nan
	
	// subtract off difference
	Duplicate /o O3x, o3xbest_adj
	for(i=0; i<numpnts(To3x); i+=1)
		pt = BinarySearchInterp(O3diff_T, To3x[i])
		if (numtype(pt) == 0) 
			o3xbest_adj[i] = O3x[i] + O3diff_smth[pt]
		endif
	endfor
end

//  Plots o3best vs o3xbest
Function O3vsO3x()
	Wave o3best, TimeWo3, o3xbest, TimeWo3x
	O3correlationPlot(o3best, TimeWo3, o3xbest, TimeWo3x)
end

// The function is fairly generic and does not need to be called with only o3best and o3xbest.
// Can call with a modified o3xbest wave like o3xbest_fix.  A wave that has been modified.
Function O3correlationPlot(o3, To3, o3x, To3x)
	Wave o3, To3, o3x, To3x
	
	// o3 is the shorter data set, o3x longer
	duplicate /o o3 o3xcorr o3corr
	
	O3xcorr = nan
	
	Variable i, ptL, ptR
	for(i=0; i<numpnts(o3)-1; i+=1)
		ptL = binarySearchInterp(To3x, To3[i])
		if (numtype(ptL) == 0)
			ptR = binarySearchInterp(To3x, To3[i+1])
			ptR = SelectNumber(numtype(ptR)==2, ptR, numpnts(To3x)-1)
			Wavestats/q/r=[ptL, ptR] o3x
			O3xcorr[i] = SelectNumber(v_npnts>1, nan, v_avg)
		endif
	endfor
	 
	DoWindow /K O3corrplot
	Display /K=1/W=(318,106,877,405) o3corr vs o3xcorr as "O3 correlation"
	DoWindow /C O3corrplot
	ModifyGraph mode(o3corr)=3
	Label left "Ozone (ppb)"
	Label bottom "Ozone X (ppb)"
	
	CurveFit/NTHR=0/TBOX=768 line  o3corr /X=o3xcorr /D 
	ModifyGraph rgb(fit_o3corr)=(0,0,0)
End


//  Uses the new ozone dataset (o3xdata) directly
//    check for bad values in large gaps
function UseO3x(o3xdata)
	wave o3xdata
	Wave TO3x = TimeWO3x

	Make/D/O/N=(numpnts(TO3x)) TimeWO3_merg
	Make/O/N=(numpnts(TO3x)) O3_merg = Nan
	SetScale d 0,0,"dat", TimeWO3_merg
	
	variable endP = numpnts(TimeWO3_merg) -1
	TimeWO3_merg[p,endP;1] = TO3x[p]
	
	// 10s ozone
	endP = numpnts(O3_merg) -1
	O3_merg[p,endP;1] = o3xdata[p]
	
end

// merges a 2s ozone dataset (o3xdata) with the 10s ozone dataset
//    check for bad values in large gaps
function BinO3x(o3xdata)
	wave o3xdata

	Wave TO3 = TimeWO3
	Wave TO3x = TimeWO3x
	Wave O3 = o3best

	Make/D/O/N=(numpnts(TO3)*2) TimeWO3_merg
	Make/O/N=(numpnts(TO3)*2) O3_merg = Nan
	SetScale d 0,0,"dat", TimeWO3_merg
	
	variable endP = numpnts(TimeWO3_merg) -1
	TimeWO3_merg[p,endP;2] = TO3[p/2]
	TimeWO3_merg[p+1,endP;2] = TO3[p/2] 
	
	// 10s ozone
	endP = numpnts(O3_merg) -1
	O3_merg[p,endP;2] = O3[p/2]
	
	// fill in every other point with an average of o3x
	Variable i, pt, lastpt, o3avg
	for(i=1; i<numpnts(TimeWO3_merg); i+=1)
		pt = BinarySearchInterp(To3x, TimeWO3_merg[i])
		if ((floor(pt) != floor(lastpt)) && (numtype(pt) == 0))
			Wavestats/Q/M=1/R=[pt-3, pt+3] o3xdata
			if (numtype(O3_merg[i])==2)
				o3avg = (O3_merg[i-1] + O3_merg[i+1])/2
				if (numtype(o3avg) == 2)
					// if o3 is missing use only o3x
					O3_merg[i] = SelectNumber(V_npnts > 2, nan, v_avg)
				else
					// equal o3 and o3x
					O3_merg[i] = SelectNumber(V_npnts > 2, nan, (v_avg+o3avg)/2)
				endif
			else
				// use the o3 point too
				O3_merg[i] = SelectNumber(V_npnts > 2, O3_merg[i], (v_avg+O3_merg[i])/2)
			endif
		else
			//O3_merg[i] = nan
		endif
		lastpt = pt
	endfor

end

function AddOzones()
	wave o3 = o3best
	wave o3t = TimeWo3
	wave o3x = o3xbest
	wave o3xt = TimeWo3x
	
	Duplicate /o o3, o3_merg
	Duplicate /o o3t, TimeWo3_merg
	wave o3_merg, TimeWo3_merg
	ConcatenateWaves("o3_merg", NameOfWave(o3x))
	ConcatenateWaves("TimeWo3_merg", NameOfWave(o3xt))
	Sort TimeWo3_merg, TimeWo3_merg, o3_merg
	
end
	

// a simple diagnostic timeseries figure
function o3mergplot()
	wave o3xbest, TimeWo3x, O3_merg, TimeWo3_merg, o3best, TimeWo3
	string win = "O3merg_plot"
	Dowindow /K $win
	Display /K=1/W=(69,281,743,694) o3xbest vs TimeWo3x
	Dowindow /C $win
	AppendToGraph O3_merg vs TimeWO3_merg
	AppendToGraph o3best vs TimeWo3
	ModifyGraph mode(o3xbest)=3,mode(O3_merg)=4,mode(o3best)=3
	ModifyGraph marker(o3xbest)=5,marker(o3best)=8
	ModifyGraph rgb(O3_merg)=(16385,16388,65535),rgb(o3best)=(3,52428,1)
	ModifyGraph msize(o3xbest)=2,msize(o3best)=4
	ModifyGraph mirror=2
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left "ozone (ppb)"
	Label bottom "Time"
	Legend/C/N=text0/J/X=80.32/Y=-0.90 "\\s(o3xbest) o3xbest\r\\s(O3_merg) O3_merg\r\\s(o3best) o3best"
EndMacro


// time shift functions to sync with NOAA O3 time.
//
function UCATStoNOAAo3time(UCATSo3, UCATStime, deltaT)
	wave UCATSo3, UCATStime
	Variable deltaT
	
	Wave NOAA = NOAAO3_O3
	wave NOAAutc = NOAAO3_UTC
	
	Make /O/N=(numpnts(NOAAutc)) NOAAO3_UCATSo3 = nan
	Wave o3 = NOAAO3_UCATSo3

	Variable i, pt
	for(i=0; i<numpnts(UCATSo3); i+=1)
		pt = BinarySearch(NOAAutc, UCATStime[i]+deltaT)
		o3[pt] = SelectNumber(pt >= 0, NaN, UCATSo3[i])
	endfor

end

Function TimeShiftCalc(start, stop, delt)
	variable start, stop, delt
	
	Variable nm = (stop-start)/delt, i
	Make /o/d/n=(nm) UCATSvNOAA_fit = nan, UCATSvNOAA_t = nan, UCATSvNOAA_num = nan
	
	Wave O3_merg, TimeWo3_merg, NOAAO3_UCATSo3, NOAAO3_O3
	
	for(i=0; i<nm; i+=1)
		UCATSvNOAA_t[i] = start + delt*i
		UCATStoNOAAo3time(O3_merg, TimeWo3_merg, UCATSvNOAA_t[i])
		CurveFit/Q/NTHR=0/TBOX=792 line  NOAAO3_UCATSo3 /X=NOAAO3_O3 /D
		UCATSvNOAA_fit[i] = V_chisq
		UCATSvNOAA_num[i] = V_npnts
	endfor
	
end