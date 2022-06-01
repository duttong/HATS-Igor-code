#pragma rtGlobals=1		// Use modern global access method.


function PlotPanelINIT()

	SVAR mollst = root:G_MolLst
	SVAR sitelst = root:G_siteLst
	variable i
	
	NewDataFolder /O/S root:plot
	
	// molecules loaded
	MakeTextWaveFromList(mollst, "MolLstWave", ";")
	Sort MolLstWave, MolLstWave
	Wave /t MolLstWave

	// sites
	MakeTextWaveFromList(sitelst, "SiteLstWave", ";")
	
	// met parameters
	Make /o/t MetLst = {"_MET_", "Temp", "Press", "Precip", "WindDIR", "WindSP"}
	
	// matrix for station time series panel
	Variable len = numpnts(MolLstWave) + numpnts(MetLst)
	Make /o/t/n=(len, 2) MolLstMultWave = ""
	Make /o/n=(len, 2) MolLstMultWaveSel = 0
	MolLstMultWave[][0] = MolLstWave
	for(i=numpnts(MolLstWave);i<len; i+=1)
		MolLstMultWave[i][0] = MetLst[i-numpnts(MolLstWave)]
	endfor
	MolLstMultWave[][1] = MolLstMultWave[p][0]

	String /G S_site = "brw"
	String /G S_mol = "N2O"
	String /G S_molL = "N2O"
	String /G S_molR = "SF6"
	
	// variables for "Global time series" panel
	Variable /G CB_Global = 1
	Variable /G CB_GlobalHem = 0
	Variable /G CB_GlobalSD = 0
	Variable /G CB_GlobalRITS = 0
	Variable /G CB_GlobalStations = 0
	
	// variables for "Station time series" panel
	Variable /G CB_StationSD = 0
	Variable /G CB_StationRITS = 0
	Variable /G CB_StationFlask = 0
	Variable /G CB_StationCCGG = 0
	Variable /G CB_StationRITS = 0
	Variable /G CB_StationTypeHour = 0
	Variable /G CB_StationTypeDay = 0
	Variable /G CB_StationTypeMonth = 1
	
	
	SetDataFolder root:
	
end

Proc CATSPlotPanel()

	DoWindow /K CATS_PlotPanel
	PlotPanel()
	DoWindow /C CATS_PlotPanel
end

Window PlotPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1012,52,1439,542) as "CATS Plotting Panel"
	ModifyPanel cbRGB=(34952,34952,34952)
	SetDrawLayer UserBack
	SetDrawEnv fillbgc= (61166,61166,61166)
	DrawRRect 8,40,184,304
	SetDrawEnv fname= "Georgia",fstyle= 5,textrgb= (1,16019,65535)
	DrawText 34,59,"Global Time Series"
	SetDrawEnv fillbgc= (61166,61166,61166)
	DrawRRect 190,6,413,304
	SetDrawEnv fname= "Georgia",fstyle= 5,textrgb= (1,16019,65535)
	DrawText 202,24,"Station Time Series"
	SetDrawEnv fsize= 10
	DrawText 294,42,"left"
	SetDrawEnv fsize= 10
	DrawText 348,41,"right"
	SetDrawEnv fillfgc= (65535,65534,49151),fillbgc= (65535,65534,49151)
	DrawRRect 12,378,412,440
	SetDrawEnv fstyle= 1,textrgb= (0,0,65535)
	DrawText 21,404,"Saving"
	SetDrawEnv fillfgc= (49151,65535,65535),fillbgc= (65535,65534,49151)
	DrawRRect 12,309,412,369
	SetDrawEnv fstyle= 1,textrgb= (0,0,65535)
	DrawText 19,337,"Loading"
	Button MakeGlobalPlot,pos={97,261},size={82,22},proc=ButtonProc,title="\\K(0,0,65535)Make Plot"
	Button MakeGlobalPlot,font="Lucida Grande"
	ListBox GlobalMol,pos={18,62},size={74,223},proc=ListBoxSelection
	ListBox GlobalMol,listWave=root:plot:MolLstWave,row= 4,mode= 2,selRow= 15
	CheckBox CB_Global,pos={96,68},size={70,14},proc=CheckBoxProc,title="Global Mean"
	CheckBox CB_Global,labelBack=(61166,61166,61166),variable= root:plot:CB_Global
	CheckBox CB_GlobalHem,pos={96,86},size={68,14},proc=CheckBoxProc,title="Hemisphers"
	CheckBox CB_GlobalHem,labelBack=(61166,61166,61166)
	CheckBox CB_GlobalHem,variable= root:plot:CB_GlobalHem
	CheckBox CB_GlobalSD,pos={96,104},size={61,14},proc=CheckBoxProc,title="Error Bars"
	CheckBox CB_GlobalSD,labelBack=(61166,61166,61166)
	CheckBox CB_GlobalSD,variable= root:plot:CB_GlobalSD
	CheckBox CB_GlobalRITS,pos={96,122},size={70,14},proc=CheckBoxProc,title="Include RITS"
	CheckBox CB_GlobalRITS,labelBack=(61166,61166,61166)
	CheckBox CB_GlobalRITS,variable= root:plot:CB_GlobalRITS
	CheckBox CB_GlobalStations,pos={96,141},size={76,14},proc=CheckBoxProc,title="\\f04Hide Stations"
	CheckBox CB_GlobalStations,labelBack=(61166,61166,61166)
	CheckBox CB_GlobalStations,variable= root:plot:CB_GlobalStations
	Button LoadData,pos={10,8},size={173,25},proc=ButtonProc,title="Load CATS Data"
	Button LoadData,font="Geneva",fSize=16,fStyle=1
	Button CloseGraphs,pos={20,447},size={110,23},proc=ButtonProc,title="\\K(52428,1,1)Close All Plots"
	Button CloseGraphs,font="Geneva",fSize=12,fStyle=0
	ListBox StationMol,pos={286,45},size={115,187},proc=ListBoxSelection
	ListBox StationMol,listWave=root:plot:MolLstMultWave
	ListBox StationMol,selWave=root:plot:MolLstMultWaveSel,row= 13,mode= 8
	CheckBox CB_StationSD,pos={200,178},size={61,14},proc=CheckBoxProc,title="Error Bars"
	CheckBox CB_StationSD,labelBack=(61166,61166,61166)
	CheckBox CB_StationSD,variable= root:plot:CB_StationSD
	CheckBox CB_StationRITS,pos={200,196},size={70,14},proc=CheckBoxProc,title="Include RITS"
	CheckBox CB_StationRITS,labelBack=(61166,61166,61166)
	CheckBox CB_StationRITS,variable= root:plot:CB_StationRITS
	CheckBox CB_StationFlasks,pos={200,214},size={77,14},proc=CheckBoxProc,title="Include Flasks"
	CheckBox CB_StationFlasks,labelBack=(61166,61166,61166)
	CheckBox CB_StationFlasks,variable= root:plot:CB_StationFlask
	CheckBox CB_StationCCGG,pos={200,233},size={75,14},proc=CheckBoxProc,title="Include CCGG"
	CheckBox CB_StationCCGG,labelBack=(61166,61166,61166)
	CheckBox CB_StationCCGG,variable= root:plot:CB_StationCCGG
	ListBox StationSite,pos={203,37},size={68,127},proc=ListBoxSelection
	ListBox StationSite,listWave=root:plot:SiteLstWave,mode= 2,selRow= 4
	Button MakeStationPlot,pos={351,245},size={54,49},proc=ButtonProc,title="\\K(0,0,65535)Make\rPlot"
	CheckBox CB_StationTypeHour,pos={294,239},size={38,14},proc=CheckBoxProc,title="Hour"
	CheckBox CB_StationTypeHour,labelBack=(61166,61166,61166),value= 0,mode=1
	CheckBox CB_StationTypeDay,pos={294,260},size={34,14},proc=CheckBoxProc,title="Day"
	CheckBox CB_StationTypeDay,labelBack=(61166,61166,61166),value= 0,mode=1
	CheckBox CB_StationTypeMonth,pos={293,280},size={45,14},proc=CheckBoxProc,title="Month"
	CheckBox CB_StationTypeMonth,labelBack=(61166,61166,61166),value= 1,mode=1
	Button CATSweb,pos={273,450},size={132,27},proc=ButtonProc,title="\\K(39321,1,31457)Goto CATS website"
	Button SaveDF,pos={65,384},size={150,22},proc=ButtonProc,title="\\K(2,39321,1)Save a CATS data file"
	Button SaveDFglb,pos={230,387},size={150,22},proc=ButtonProc,title="\\K(2,39321,1)Save \"global\" data file"
	Button SaveDF1mol,pos={17,412},size={200,22},proc=ButtonProc,title="\\K(2,39321,1)Save all CATS data files 1 mol"
	Button SaveDFglbAll,pos={224,414},size={169,21},proc=ButtonProc,title="\\K(2,39321,1)Save all \"global\" data file"
	Button LoadMSDbutt,pos={79,318},size={150,22},proc=ButtonProc,title="\\K(2,39321,1)Load All MSD"
	Button LoadOTTObutt,pos={238,318},size={150,22},proc=ButtonProc,title="\\K(2,39321,1)Load All OTTO"
	Button LoadCCGGbutt,pos={81,344},size={150,22},proc=ButtonProc,title="\\K(2,39321,1)Load CCGG N2O/SF6"
EndMacro



Function CheckBoxProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	NVAR G_global = root:plot:CB_Global
	NVAR G_globalHem = root:plot:CB_GlobalHem
	NVAR G_globalRITS = root:plot:CB_GlobalRITS
	NVAR G_globalSD = root:plot:CB_GlobalSD
	NVAR G_globalSta = root:plot:CB_GlobalStations 

	NVAR G_stationSD = root:plot:CB_StationSD
	NVAR G_stationRITS = root:plot:CB_StationRITS
	NVAR G_stationFlasks = root:plot:CB_StationFlask
	NVAR G_stationCCGG = root:plot:CB_StationCCGG
	NVAR G_stationTypeDay = root:plot:CB_StationTypeDay
	NVAR G_stationTypeHour = root:plot:CB_StationTypeHour
	NVAR G_stationTypeMonth = root:plot:CB_StationTypeMonth
	
	NVAR dur = root:G_dur

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			break
	endswitch
	
	strswitch( cba.ctrlName )
	
		// global time series variables
		case "CB_Global":
			G_global = checked
			break
		case "CB_GlobalHem":
			G_globalHem = checked			
			break
		case "CB_GlobalRITS":
			G_globalRITS = checked
			if ( checked )
				G_GlobalSD = 0
				G_GlobalSta = 0
			endif
			break
		case "CB_GlobalSD":
			G_GlobalSD = checked		
			if ( G_globalRITS )
				G_GlobalSD = 0		// can't use SD with RITS on
			endif				
			break
		case "CB_GlobalStations":
			G_GlobalSta = checked			
			if ( G_globalRITS )
				G_GlobalSta = 0		// can't hide stations with RITS on
			endif				
			break
		
		// station time series variables	
		case "CB_StationSD":
			G_StationSD = checked
			break
		case "CB_StationRITS":
			G_StationRITS = checked
			break
		case "CB_StationFlasks":
			G_StationFlasks = checked
			break
		case "CB_StationCCGG":
			G_StationCCGG = checked
			break
		case "CB_stationTypeDay":
			G_stationTypeDay = 1
			G_stationTypeHour = 0
			G_stationTypeMonth = 0
			dur = 2
			break
		case "CB_stationTypeHour":
			G_stationTypeDay = 0
			G_stationTypeHour = 1
			G_stationTypeMonth = 0
			dur = 1
			break
		case "CB_stationTypeMonth":
			G_stationTypeDay = 0
			G_stationTypeHour = 0
			G_stationTypeMonth = 1
			dur = 4
			break
		
	endswitch
	
	CheckBox CB_StationTypeHour value=G_StationTypeHour
	CheckBox CB_StationTypeDay value=G_StationTypeDay
	CheckBox CB_StationTypeMonth value=G_StationTypeMonth

	return 0
End

Function ListBoxSelection(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave

	SVAR molalt = root:G_mol
	SVAR mol = root:plot:S_mol
	SVAR site = root:plot:S_site
	SVAR molL = root:plot:S_molL
	SVAR molR = root:plot:S_molR
	Wave /t molWave = root:plot:molLstWave
	Wave /t siteWave = root:plot:siteLstWave
	Wave /t molMult = root:plot:molLstMultWave
	Wave molSel = root:plot:molLstMultWaveSel

	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 3: // double click
			break
		case 4: // cell selection

			strswitch ( lba.ctrlName )
				case "GlobalMol":
					mol = molWave[row]
					molalt = mol
					ListBox GlobalMol, selRow= row
					break
				case "StationMol":
					if (col==0)
						molL = molMult[row][0]
						molR = ""
					elseif (col==1)
						molR = molMult[row][1]
						molL = ""
					endif
					mol = molMult[row][col]
					molalt = mol
					ListBox GlobalMol, selRow= row
					break
				case "StationSite":
					site = siteWave[row]
					break
			endswitch
			break

		case 5: // cell selection plus shift key
			strswitch ( lba.ctrlName )
				case "StationMol":
					molSel[][col] = 0
					molSel[row][col] = 1
					if (col==0)
						molL = molMult[row][0]
					elseif (col==1)
						molR = molMult[row][1]
					endif
					break
			endswitch
			break
			
		case 6: // begin edit
			break
		case 7: // finish edit
			break
	endswitch

	return 0
End

// returns the row number the molecule (selected by S_mol) is located at
// in the MolLstWave
function molRow ( )

	SVAR mol = root:plot:S_mol
	wave /t molwv = root:plot:MolLstWave
	variable i
	
	for( i=0; i<numpnts(molwv); i+=1 )
		if (cmpstr(molwv[i], mol) == 0 )
			return i
		endif		
	endfor
	
	return -1	
end


Function ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			strswitch( ba.ctrlName )
				case "MakeGlobalPlot":
					GlobalPlotting()
					break
				case "MakeStationPlot":
					StationPlotting()
					break
				case "LoadData":
					LoadALLCATS()
					break
				case "CloseGraphs":
					removeDisplayedGraphs()
					break
				case "CATSweb":
					BrowseURL "http://www.esrl.noaa.gov/gmd/hats/insitu/cats/"
					break
				case "CorButton":
					CorrelateCATSdata()
					break
				case "LoadMSDbutt":
					LoadMSD_All()
					break
				case "LoadOTTObutt":
					LoadOTTO_All()
					break
				case "LoadCCGGbutt":
					LoadCCGGfile("N2O")
					LoadCCGGfile("SF6")
					break
///				case "LoadMET":
//					execute "LoadMetData()"
//					break
//				case "LoadSurfO3":
//					execute "LoadSurfaceO3()"
//					break
					
				// saving section
				case "SaveDF":
					execute "SaveDataFile()"
					break
				case "SaveDFglb":
					SaveGlobalData()
					break
				case "SaveDF1mol":
					SaveDataFiles_mol()
					break
				case "SaveDFglbAll":
					execute "SaveAllGlobalData()"
					break
				endswitch
			break
	endswitch

	return 0
End


Function GlobalPlotting()

	SVAR mol = root:plot:S_mol
	NVAR G_global = root:plot:CB_Global
	NVAR G_globalHem = root:plot:CB_GlobalHem
	NVAR G_globalRITS = root:plot:CB_GlobalRITS
	NVAR G_globalSD = root:plot:CB_GlobalSD
	NVAR G_globalSta = root:plot:CB_GlobalStations 
	
	// other vars
	NVAR dur = root:G_dur
	NVAR err = root:G_err
	NVAR insitu = root:G_insitu
	NVAR comb = root:G_CATS
	SVAR Gmol = root:G_mol
	
	Gmol = mol
		
	err = 1
	if (G_globalSD)
		err = 2
	endif
	
	comb = 1
	insitu =1
	if (G_globalRITS)
		comb = 2
		insitu = 3
	endif

	String GDF = "root:global:"

	PlotTimeSeriesFUNCT(mol, 4, err, insitu)

	// update global means	
	if (( G_global ) || ( G_globalHem ))
		// GlobalMeansWithHemisphersFUNCT(mol)
		Global_Mean(insts="cats;", prefix="insitu", mol=mol, plot=1, offsets=1)
	endif
	
	// append global mean trace
	if ( G_global )
		String Gy = "insitu_global_" + mol
		String Gx = "insitu_" + mol + "_date"
		String Gsd = Gy + "_sd"
	
		SetDataFolder $GDF
		
		AppendToGraph $Gy vs $Gx
		ModifyGraph lsize($Gy)=3,rgb($Gy)=(0,0,0)
		
		if (G_globalSD)
			ErrorBars $Gy Y,wave=($Gsd,$Gsd)
		endif
	
		SetDataFolder root:
	endif 
	
	// append hemisphere traces
	if ( G_globalHem )

		String Ny = "insitu_NH_" + mol
		String Sy = "insitu_SH_" + mol
		Gx = "insitu_" + mol + "_date"
		
		SetDataFolder $GDF
		
		AppendToGraph $Ny vs $Gx
		ModifyGraph lsize($Ny)=3,rgb($Ny)=(0,0,65535)
		AppendToGraph $Sy vs $Gx
		ModifyGraph lsize($Sy)=3,rgb($Sy)=(52428,1,1)
		
		SetDataFolder root:
		
	endif
	

end


function StationPlotting()

	SVAR molL = root:plot:S_molL
	SVAR molR = root:plot:S_molR
	SVAR site = root:plot:S_site
	NVAR G_stationSD = root:plot:CB_stationSD
	NVAR G_stationRITS = root:plot:CB_stationRITS
	NVAR G_stationFlask = root:plot:CB_stationFlask
	NVAR G_stationCCGG = root:plot:CB_stationCCGG

	NVAR G_stationTypeHour = root:plot:CB_StationTypeHour
	NVAR G_stationTypeDay = root:plot:CB_StationTypeDay
	NVAR G_stationTypeMonth = root:plot:CB_StationTypeMonth
	
	NVAR G_dur = root:G_dur
	SVAR Sdur = root:S_dur

	String Yl, Yr, X, SDl, SDr, DFl = "", DFr = ""

	// make the G_dur variable reflect the radio buttons
	if ( G_stationTypeHour == 1 )
		G_dur = 1
	elseif ( G_stationTypeDay == 1 )
		G_dur = 2
	else
		G_dur = 4
	endif
	
	// check to see if met or O3 data is selected
	Variable metL = MetVariableCheck(molL)
	Variable metR = MetVariableCheck(molR)
	Variable O3L, O3R
	O3L = cmpstr(molL, "O3") == 0 ? 1 : 0
	O3R = cmpstr(molR, "O3") == 0 ? 1 : 0
	
	CATSdataFolder( 1 )
	
	string winTitle, win
	if ( strlen(molR) > 0 )
		winTitle = UpperStr(site) + " " + molL + " & " + molR + " " + Sdur + " time series"
		win = site+molL+molR+Sdur
	else
		winTitle = UpperStr(site) + " " + molL + " " + Sdur + " time series"
		win = site+molL+Sdur
	endif
	
	// handle variable type: CATS, CCGG, otto or met
	Yl = site + "_" + molL
	if ( metL )
		Yl = "met_" + site + "_" + molL
		DFl = "root:met:"
	elseif ( O3L )
		DFl = "root:O3:"
	else
		SDl = Yl + "_SD"
	endif
	X = site + "_time"

	Yr = site + "_" + molR
	if ( metR )
		Yr = "met_" + site + "_" + molR
		DFr = "root:met:"
	elseif ( O3R )
		DFr = "root:O3:"
	else
		SDr = Yr + "_SD"
	endif
	
	// plot if left mol exists
	if ( exists(DFl+Yl) == 1 )
		DoWindow /K $win
		Display /K=1/W=(31,346,861,719) $DFl+Yl vs $X as winTitle
		DoWindow /C $win
		
		Label left "\\K(52428,1,1)\\f01" + molL + " " + ReturnMolUnits(molL)
		Label bottom "\\f01Date"
		SetAxis/A/N=1 left
		SetAxis/A/N=1 bottom
		
		ModifyGraph wbRGB=(65535,65534,49151)
		ModifyGraph marker=19
		ModifyGraph dateInfo(bottom)={0,0,0}
		
		if (( G_stationSD ) && ( exists(SDl) == 1 ))
			ErrorBars $Yl Y,wave=($SDl,$SDl)
		endif

		// plot right axis if mol exists
		if ( exists(DFr+Yr) == 1 )
			AppendToGraph /r $DFr+Yr vs $X
			if ( G_stationSD )
				ErrorBars $Yr Y,wave=($SDr,$SDr)
			endif
			ModifyGraph rgb($Yr)=(2,39321,1), marker($Yr)=19

			Label right "\\K(2,39321,1)\\f01" + molR + " " + ReturnMolUnits(molR)
			SetAxis/A/N=1 right
			ModifyGraph grid(bottom)=1,mirror(bottom)=2
		else
			ModifyGraph grid=1,mirror=2
		endif
				
		if ( G_stationFlask )
			// first try MSD flasks
			SetDataFolder root:MSD:
			String FYl = "MSD_" + site + "_" + molL
			String FXl = "MSD_" + site + "_" + molL + "_date"
			String FSDl = "MSD_" + site + "_" + molL + "_sd"

			if ( exists(FYl) == 1)
				AppendToGraph $FYl vs $FXl
				ModifyGraph marker($FYl)=5, rgb($FYl)=(0,0,65000)
				if ( G_stationSD )
					ErrorBars $FYl Y, wave=($FSDl, $FSDl)
				endif
			endif
			
			// now try otto flasks
			SetDataFolder root:otto:
			String Oy = "otto_" + site + "_" + molL
			String Oysd = "otto_" + site + "_" + molL + "_sd"
			String Ox = "otto_" + site + "_" + molL + "_date"
			if ( exists(Oy) == 1)
				AppendToGraph $Oy vs $Ox
				ModifyGraph marker($Oy)=5, rgb($Oy)=(1,52428,52428)
				if ( G_stationSD )
					ErrorBars $Oy Y, wave=($Oysd, $Oysd)
				endif
			endif
			
		endif
	
		// CCGG flasks	
		if (G_StationCCGG)
			SetDataFolder root:CCGG:
			String CCy = "CCGG_" + site + "_" + molL + "_mn"
			String CCysd = "CCGG_" + site + "_" + molL + "_sd"
			String CCx = "CCGG_" + molL + "_date"
			if ( exists(CCy) == 1)
				AppendToGraph $CCy vs $CCx
				ModifyGraph marker($CCy)=12, rgb($CCy)=(8738,8738,8738)
				if ( G_stationSD )
					if (exists(CCysd))
						ErrorBars $CCy Y, wave=($CCysd, $CCysd)
					endif
				endif
			endif
		endif


		if ( G_stationRITS )
			SetDataFolder root:rits:
			FYl = "rits_" + site + "_" + molL + "_new"
			FXl = FYl + "_date"
			FSDl = FYl + "_sd"
			if ( exists(FYl) == 1)
				AppendToGraph $FYl vs $FXl
				ModifyGraph marker($FYl)=5, rgb($FYl)=(0,0,65000)
				if ( G_stationSD )
					ErrorBars $FYl Y, wave=($FSDl, $FSDl)
				endif
			endif
		endif
	
		ModifyGraph msize=2
		ModifyGraph mode=4
		ModifyGraph gaps=0
	
		Legend/C/N=legend/X=70/Y=2
		
		// correlation button?
		if ( exists(DFr+Yr) == 1)
			ModifyGraph margin(top)=43
			Button CorButton,pos={61,7},size={120,20},proc=ButtonProc,title="Plot Correlation"
		endif
		
	endif
	
	SetDataFolder root:

end

function MetVariableCheck( var )
	string var
	
	Wave /T MetLst = root:plot:MetLst
	variable i
	
	// start a 1 to ignore the "_MET_" header (non-variable)
	for( i=1; i < numpnts(MetLst); i+=1 )
		if (cmpstr(MetLst[i], var) == 0 )
			return 1
		endif		
	endfor
	
	return 0

end


function CorrelateCATSdata()

	String Y = StringFromList(0, TraceNameList("", ";", 1))
	String X = StringFromList(1, TraceNameList("", ";", 1))
	Wave Yw = TraceNameToWaveRef("", Y)
	Wave Xw = TraceNameToWaveRef("", X)
	Wave T = XWaveRefFromTrace("", Y)
	
	String sta = Y[0,2]				// station 3 letter code
	String Ymol = Y[strsearch(Y, sta, 0)+4, 1000]
	String Xmol = X[strsearch(X, sta, 0)+4, 1000]
	
	String YcorStr = sta + "_" + Ymol + "vs" + Xmol + "_corY"
	String XcorStr = sta + "_" + Ymol + "vs" + Xmol + "_corX"

	NewDataFolder /O/S Correlate
	
	// detrend data
	String suf 
	suf = "_" + sta +"_" + Xmol + "_" +Ymol+"v"+Xmol
	DetrendHourlyData( T, Xw,  suf )
	Wave detX = $"det" + suf
	suf = "_" + sta +"_" + Ymol + "_" +Ymol+"v"+Xmol
	DetrendHourlyData( T, Yw,  suf )
	Wave detY = $"det" + suf
	Duplicate /O detY, $YcorStr
	Duplicate /O detX, $XcorStr

	Duplicate /O T, Twave
	Wave Ycor = $YcorStr
	Wave Xcor = $XcorStr
	
	GetAxis /Q bottom
		
	// trim wave size to current displayed data
	Variable /D ptL = BinarySearchInterp(Twave, V_min)
	Variable /D ptR = BinarySearchInterp(Twave, V_max)
	DeletePoints ptR+1, numpnts(Ycor)-ptR+1, Ycor, Xcor, Twave
	DeletePoints 0, ptL-1, Ycor, Xcor, Twave

	
	// Display
	String win = sta + "_" + Ymol + "v" + Xmol
	String winTitle = sta + " " + Ymol + " vs " + Xmol
	DoWindow /K $win	
	Display /W=(35,44,505,315)/K=1 Ycor vs Xcor as winTitle
	DoWindow /C $win
	ModifyGraph mode=3
	ModifyGraph marker=8
	ModifyGraph rgb=(0,0,65535)
	ModifyGraph msize=2
	ModifyGraph grid=1
	ModifyGraph mirror=2
	ModifyGraph margin(top)=36
	Label left Ymol + " " + ReturnMolUnits(Ymol)
	Label bottom Xmol + " " + ReturnMolUnits(Xmol)
	SetAxis/A/N=1 left
	SetAxis/A/N=1 bottom
	
	String DurStr = "\\Z09Correlation for duration: \r" + Secs2Date(V_min, 0) + " to " +  Secs2Date(V_max, 0)
	TextBox/C/N=dur/F=0/S=3/B=1/X=-6.13/Y=-17.01 DurStr
	
	Killwaves Twave
	
	SetDataFolder root:

end