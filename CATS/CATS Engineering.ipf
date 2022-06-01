#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "Macros-Geoff"
#include "Macros-Utilities"

strconstant kCATSsites = "brw;sum;nwr;mlo;smo;spo"


Function LoadEngineeringData([site])
	string site
	
	If (ParamIsDefault(site))
		Prompt site, "CATS station", popup kCATSsites
		DoPrompt "Loading longer engineering file", site
		if (V_flag==1)
			abort
		endif
	endif
	
	String /G G_eng_site = site
	
	string file = "a_" + site + "_eng.csv"
	string path = "Hats:gc:cats_results:eng:"
	string DF = "alleng_" + site
	
	NewDataFolder /O/S $DF
	
	// format string to correctly name CATS eng waves
	String fmt = "C=1,N=DecDate; C=1,T=80,F=0,N=YYYY; C=1,T=80,F=0,N=DDD; C=1,T=72,N=HH; C=1,T=72,N=MM;"
	fmt += "C=1,T=2,N=TempECD1; C=1,T=2,N=TempECD2; C=1,T=2,N=TempECD3; C=1,T=2,N=TempECD4;"
	fmt += "C=1,T=2,N=TempCol1; C=1,T=2,N=TempCol2; C=1,T=2,N=TempCol3; C=1,T=2,N=TempCol4;"
	fmt += "C=1,T=2,N=TempMisc;"
	fmt += "C=1,T=2,N=FlowM1; C=1,T=2,N=FlowM2; C=1,T=2,N=FlowM3;"
	fmt += "C=1,T=2,N=FlowBF1; C=1,T=2,N=FlowBF2; C=1,T=2,N=FlowBF3;"
	fmt += "C=1,T=2,N=TempExt; C=1,T=2,N=SampFlow; C=1,T=72,N=SSV;"
	LoadWave/A/O/J/K=0/V={","," $",0,0}/B=fmt path + file
	
	// Make a time wave
	Wave YYYY, DDD, HH, MM
	String dayStr = site +  "_date"
	Make/D/N=(numpnts(YYYY))/O $dayStr/WAVE=day=Nan
	day = Date2secs(YYYY, DayOfYear2date(YYYY, DDD, 0), DayOfYear2date(YYYY, DDD, 1)) + HH*60*60 + MM*60
	SetScale d 0,0,"dat", day

	bat("Killwaves @", "Wave*")
	Killwaves /Z YYYY, DDD, HH, MM
	
	Wave TempCol1, TempCol2, TempCol3, TempCol4
	FilterBadValues(TempCol1, 10, 400)
	FilterBadValues(TempCol2, 10, 400)
	FilterBadValues(TempCol3, 10, 400)
	FilterBadValues(TempCol4, 10, 400)

	Wave TempECD1, TempECD2, TempECD3, TempECD4
	FilterBadValues(TempECD1, 10, 400)
	FilterBadValues(TempECD2, 10, 400)
	FilterBadValues(TempECD3, 10, 400)
	FilterBadValues(TempECD4, 10, 400)
	
	Wave FlowM1, FlowM2, FlowM3
	FilterBadValues(FlowM1, 5, 100)
	FilterBadValues(FlowM2, 5, 100)
	FilterBadValues(FlowM3, 5, 100)
	
	Wave FlowBF1, FlowBF2, FlowBF3
	FilterBadValues(FlowBF1, 5, 100)
	FilterBadValues(FlowBF2, 5, 100)
	FilterBadValues(FlowBF3, 5, 100)
	
	Wave SampFlow
	FilterBadValues(SampFlow, 5, 400)

	cd root:
	
end

// filter bad values from CATS engineering data
Function FilterBadValues(wv, low, high)
	wave wv
	variable low, high
	
	wv = SelectNumber(wv > high, wv, NaN)
	wv = SelectNumber(wv <= low, wv, NaN)
end

Function LoadAllCATSEng()

	variable i
	for (i=0; i<ItemsInList(kCATSsites); i+=1)
		LoadEngineeringData(site=StringFromList(i, kCATSsites))
	endfor
	
end

Function SampleFlows([site])
	string site
	
	If (ParamIsDefault(site))
		Prompt site, "CATS station", popup kCATSsites
		DoPrompt "Loading longer engineering file", site
		if (V_flag==1)
			abort
		endif
	endif

	SVAR Gsite = root:G_eng_site
	Gsite = site
	
	string DF = "root:alleng_" + site
	string win = "SampleFlow_" + site
	cd $DF
	
	wave day = $site + "_date"
	wave flow = SampFlow
	wave ssv = ssv
	
	DoWindow /K $win
	Display /W=(24,64,626,419)/K=1 flow vs day
	DoWindow /C $win
	ModifyGraph mode=3
	ModifyGraph marker=5
	ModifyGraph zColor(SampFlow)={ssv,*,*,Rainbow}
	//ModifyGraph textMarker(SampFlow)={ssv,"default",0,0,5,0.00,0.00}
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label left site + " Sample Flow (cc/min)"
	Label bottom "Date"

	cd root:

end

Function Eng_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			if (cmpstr(ba.ctrlName, "ports")==0)
				print ba.win[0]
				//String site = ba.win[strsearch(ba.win, "_", 0)+1]
				//print site
			endif	
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
