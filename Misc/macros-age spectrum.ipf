#pragma rtGlobals=1		// Use modern global access method.

//Returns the Green's function.
// Equation from Hall and Plumb [1994]
function GreensFunct(z,K)	//z is in km.
	variable z,K	//K is in m^2/s, thus x is in seconds.
	
	variable H=7000
	variable /d year_coef=31536000, norm // year_coef = 60*60*24*365
	z*=1000
	
	// In the interest of speed, I have tried to reduce the Greens function wave size.  The difference in terms of Total Cl between using
	// a 4000 point wave compared with a 200 point wav is 1e-5.
	make /o/d/n=200 GreensWave
	wave gWv=GreensWave
	SetScale/I x 0,20,"", gWv  // 20 yr window width maybe overkill but we try it
	
	gWv = z/(2*sqrt(pi*K*(x*year_coef)^3))*exp(z/(2*H)-(K*(x*year_coef))/(4*H^2)-z^2/(4*K*(x*year_coef)))
	gWv[0] = 0

	// Normalize the function and recalculate
	norm=area(gWv,-Inf,Inf)
	gWv = (z/(2*sqrt(pi*K*(x*year_coef)^3))*exp(z/(2*H)-(K*(x*year_coef))/(4*H^2)-z^2/(4*K*(x*year_coef)))) / norm
	gWv[0] = 0

//	FindLevel /Q/R=(inf,-inf) gWv,faverage(GreensWave,-Inf, Inf)
//	print "Mean=",faverage(GreensWave,-Inf, Inf),"at",V_LevelX,"Total",Area(gWv,-inf,inf)
end

// From Darryn [2001 AGU poster]
function GreensFunct2(age, W)
	variable age, W
	
	make /o/d/n=200 GreensWave2
	wave gWv=GreensWave2
	SetScale/I x 0,20,"", gWv  // 20 yr window width maybe overkill but we try it

	gWv = 1/(2*W*sqrt(pi*(x/age)^3)) * exp(-(age^2 * (x/age - 1)^2)/(4*W^2*x/age))
	gWv[0] = 0

end		

function makeZplot()

	variable z = 1, inc=.5, maxz = 60, dinc
	make /o/n=((maxz-z)/inc) zwave, zagewave, mc_trendSm
	zwave = z + inc*p
	wave Greenswave = $"Greenswave"
	wave trend = $"mc_trendY"
	
	display  zwave vs Zagewave
	
	do
		GreensFunct(z,1.25)
		duplicate /o Greenswave test
		
		// find the mean of the greens function
		test = Greenswave[p]*pnt2x(Greenswave,p)
		zagewave[dinc] = area(test, -Inf, Inf)
		
		dinc += 1
		z += inc
	while (z < maxz)
	
end


Function GreensFofAge(age, width)
	variable age, width
	
	variable Zprime, K = width   // strickly speaking K is NOT width but about 1/2 the width!!!!
	
	if (exists("coef_ZvAge") != 1)
		make /n=2 coef_ZvAge = {-0.911630866082074, 6.05042035651964}
	endif
	wave coef = $"coef_ZvAge"

	Zprime = coef_ZvAge[0] + coef_ZvAge[1]*age
	if (Zprime <= 0)
		Zprime = 0.01
	endif
	
	GreensFunct(Zprime, K)
	
end

Function CalcTotalCl(age, yr, W)
	variable age, yr, W
	
	variable dur = 20
	if (exists("CCly_trend_sm") != 1)
		CalcSmoothTrend(CCly_trend, CCly_date)
	endif
	wave trend = $"CCly_trend_sm"
	
	GreensFofAge(age, W)
	wave GW = GreensWave

//	GreensFunct2(age, W)
//	wave GW = GreensWave2
	
	SetScale/I x yr, yr-dur,"", GW
	duplicate /o GW, Green_tmp
	
	Green_tmp = GW(pnt2x(GW, p))*trend(pnt2x(GW, p))
	return area(Green_tmp, -Inf, Inf)
	
end

Function CalcTotalBr(age, yr)
	variable age, yr
	
	variable dur = 20
	if (exists("CBry_trend_sm") != 1)
		CalcSmoothTrend(CBry_trend, CBry_date)
	endif
	wave trend = $"CBry_trend_sm"
	
	GreensFofAge(age, 1.25)
	
	wave GreensWave = $"GreensWave"
	SetScale/I x yr, yr-dur,"", GreensWave
	duplicate /o GreensWave, Green_tmp
	
	Green_tmp = GreensWave(pnt2x(Greenswave, p))*trend(pnt2x(Greenswave, p))
	return area(Green_tmp, -Inf, Inf)
	
end

function CalcSmoothTrend(wv, dates)
	wave wv, dates
	
	string sm = NameOfWave(wv) + "_sm"
	string intstr

	make /o/n=4000 $sm = NaN
	wave smWv = $sm
	
	sprintf intstr, "Interpolate/T=1/N=4000/Y=%s %s /X=%s", sm, NameOfWave(wv), NameOfWave(dates)
	execute intstr
	SetScale/I x dates[0],dates[numpnts(dates)-1],"", smWv	
	
end