#pragma rtGlobals=1		// Use modern global access method.

function DetrendHourlyData( Xw, Yw, suf )
	wave Xw, Yw
	string suf

	String Y = NameOfWave(Yw)
	String sta = Y[0,2]				// station 3 letter code
	String Ymol = Y[strsearch(Y, sta, 0)+4, 1000]

	PercentileBlock(Xw, Yw, 7, 0.10, suf )

	wave AvgX = $"avg_T" + suf
	wave AvgY = $"avg_Y" + suf
	string Detstr = "det" + suf
	variable inc, pnt
	
	duplicate /o AvgX, interpX
	duplicate /o AvgY, interpY
	duplicate /o Yw, $Detstr
	wave detrend = $Detstr

	// first interpolate any missing Weekly mean data
	Interpolate2/T=1/N=(numpnts(AvgY))/I=3/Y=interpY/X=interpX AvgX, AvgY
	
	// a little smoothing
	Smooth 10, interpY
	
	// subtract
	do
		pnt = BinarySearchInterp(interpX, Xw[inc])
		if ( numtype(pnt) == 0)
			detrend[inc] = Yw[inc] - interpY[pnt]
		else
			detrend[inc] = nan
		endif
		inc += 1
	while (inc < numpnts(Yw))
	
	Killwaves InterpX, InterpY, AvgX, AvgY

end

// xwv is time wave (in seconds)
// ywv is data
// width in days
function PercentileBlock( xwv, ywv, width, percentile, suf )
	wave xwv, ywv
	variable width, percentile
	string suf

	variable ws = width * 24 * 60 * 60 		// seconds
	variable lp = 0 , rp, inc = 0
	string XavgStr = "avg_T" + suf
	string YavgStr = "avg_Y" + suf
	
	Make /n=(1000) /d/o $XavgStr, $YavgStr
	Wave xavg = $XavgStr
	Wave yavg = $YavgStr
		
	xavg = floor(xwv[0]) + ws*p 

	do
		lp = BinarySearchInterp(xwv, xavg[inc]-ws/2)
		lp = (numtype(lp) != 0 ) ? 0 : lp
		rp = BinarySearchInterp(xwv, xavg[inc]+ws/2)
		rp = (numtype(rp) != 0 ) ? numpnts(xwv)-1 : rp

		Duplicate /o/R=[lp, rp] ywv, tmpmed
		Sort tmpmed, tmpmed
		if ( (rp-lp) > 20 )
			yavg[inc] = tmpmed[(rp-lp)*percentile]
		else
			yavg[inc] = NaN
		endif
		inc += 1
	while (xwv[numpnts(xwv)-1] >= xavg[inc-1]+ws/2)
		
	DeletePoints inc,5000, xavg, yavg
	Killwaves tmpmed
	
end

// ywv is data
// width in days
function AvgBlock( xwv, ywv, width, suf )
	wave xwv, ywv
	variable width
	string suf

	variable ws = width * 24 * 60 * 60 		// seconds
	variable lp = 0 , rp, inc = 0
	string XavgStr = "avg_T" + suf
	string YavgStr = "avg_Y" + suf
	
	Make /n=(1000) /d/o $XavgStr, $YavgStr
	Wave xavg = $XavgStr
	Wave yavg = $YavgStr
		
	xavg = floor(xwv[0]) + ws*p 

	do
		lp = BinarySearchInterp(xwv, xavg[inc]-ws/2)
		lp = (numtype(lp) != 0 ) ? 0 : lp
		rp = BinarySearchInterp(xwv, xavg[inc]+ws/2)
		rp = (numtype(rp) != 0 ) ? numpnts(xwv)-1 : rp
		
		Wavestats /Q/R=[lp, rp] ywv
		if ( (rp-lp) > 20 )
			yavg[inc] = V_avg
		else
			yavg[inc] = NaN
		endif

		inc += 1
	while (xwv[numpnts(xwv)-1] >= xavg[inc-1]+ws/2)
		
	DeletePoints inc,5000, xavg, yavg
end
