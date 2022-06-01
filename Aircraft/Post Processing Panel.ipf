#pragma rtGlobals=1		// Use modern global access method.
#pragma version=1.3

// version 1.2 added Dry mole fraction option for the exchange file.  GSD 20100701
// version 1.3 added ICARTT file format.   GSD 20130121

//  Exchange file control structure
Structure XC_struct
	SVAR participants
	SVAR participantsShort
	SVAR affiliation
	SVAR affiliationShort
	SVAR xcPrefix
	SVAR xcSuffix
	SVAR mission
	SVAR instrument
	SVAR xcMolLst
	//  added by fred to get submitied files to have Wolfsy format
	SVAR xcMolLst_Wolfsy
	//  second place by fred approx 20 lines down and in post Prossessing.ipf near end.
	NVAR useDMF
	
	Wave /T comments
	Wave /T scales
	Wave /T missing
	Wave /T units
	Wave /T fullmols
	Wave /T shortmols
	Wave sigfigs
EndStructure


// global structure for exchange file
function GetXCstructure(xcs)
	STRUCT XC_struct &xcs
	
	String dfsav= GetDataFolder(1)
	NewDataFolder /O/S $kDFpan
	
	SVAR/Z xcs.affiliation = S_affiliation
	if ( !SVAR_Exists(xcs.affiliation) )
		String /G S_affiliation = "U.S. DEPT OF COMMERCE, NOAA/ESRL/GMD, and University of Colorado/CIRES"
		String /G S_affiliationShort = S_affiliation
		if ( strlen(S_affiliation) > 45 )
			S_affiliationShort = S_affiliation[0,45]+"..."
		endif
	endif

	SVAR/Z xcs.participants  = S_participants
	if ( !SVAR_Exists(xcs.participants) )
		String /G S_participants = "HINTSA, ERIC; MOORE, FRED; DUTTON, GEOFF; HALL, BRAD; ELKINS, JAMES"
		String /G S_participantsShort = S_participants
		if ( strlen(S_participants) > 45 )
			S_participantsShort = S_participants[0,45] + "..."
		endif
		String /G S_xcPrefix = "GC"
		String /G S_xcSuffix = ".GH"
		String /G S_mission = "START08"
		String /G S_instrument = "UCATS"
		String /G S_xcMolLst = "N2O;SF6;CH4;H2;CO"
	endif
	
	// used to add new global variable G_useDMF, GSD 20100701
	NVAR /Z xcs.useDMF = G_useDMF
	if (!NVAR_Exists(xcs.useDMF) )
		Variable /G G_useDMF = 0
	endif		
	
	SVAR xcs.participants = S_participants
	SVAR xcs.participantsShort = S_participantsShort
	SVAR xcs.affiliation = S_affiliation
	SVAR xcs.affiliationShort = S_affiliationShort
	SVAR xcs.xcPrefix = S_xcPrefix
	SVAR xcs.xcSuffix = S_xcSuffix
	SVAR xcs.mission = S_mission
	SVAR xcs.instrument = S_instrument
	SVAR xcs.xcMolLst = S_xcMolLst
	// added fred to get submitied files to have Wolfsy format
	SVAR xcs.xcMolLst_Wolfsy = S_xcMolLst_Wolfsy
	//  end fred mod
	Wave/T xcs.comments = comments
	Wave/T xcs.scales = xc_scale
	Wave/T xcs.missing = xc_nan
	Wave/T xcs.units = xc_unit
	Wave/T xcs.fullmols = xc_mols
	Wave/T xcs.shortmols = xc_molsShort
	
	if (exists("xc_sigfigs") == 0 )
		Make /n=(numpnts(xcs.fullmols)) xc_sigfigs = 2
	endif
	Wave xcs.sigfigs = xc_sigfigs
	
	SetDataFolder dfsav
	
end

function init()

	String /G S_unit = "ppt"
	
	NewDataFolder /O/S $kDFpan
	Variable /G G_makeplots = 1
	Variable /G G_dispmodeC = 1
	Variable /G G_dispmodeR = 0
	Variable /G G_dispprec = 1
	Variable /G G_useDMF = 0
	SetDataFolder root:
	
end

function ppp() : Panel
	PauseUpdate; Silent 1		// building window...
	string win = "PostProcPanel"
	
	STRUCT XC_struct xcs
	GetXCstructure(xcs)
	if ( strlen(WinList("PostProcPanel", ";", "")) > 0 )
		DoWindow /F $win
	else
		NewPanel /K=1/W=(41,46,481,447) as "Post Processing Panel"
		DoWindow /C $win
	endif
	
	SetDrawLayer UserBack
	SetDrawEnv fillbgc= (63534,65353,60977)
	DrawRRect 13,270,424,353
	SetDrawEnv fillbgc= (63534,65353,60977)
	DrawRRect 11,34,427,236
	SetDrawEnv fillfgc= (58335,57851,59009)
	DrawRRect 245,161,418,199
	SetDrawEnv fillfgc= (59391,63594,65535)
	DrawRRect 331,151,419,131
	SetDrawEnv fstyle= 1
	DrawText 136,52,"Flight Dates"
	SetDrawEnv fstyle= 1
	DrawText 36,52,"Molecules"
	SetDrawEnv fsize= 10,fstyle= 1
	DrawText 64,346,"Participants:"
	SetDrawEnv fsize= 10,fstyle= 1
	DrawText 64,289,"Prefix:"
	SetDrawEnv fsize= 10,fstyle= 1
	DrawText 193,289,"Suffix:"
	SetDrawEnv fsize= 10,fstyle= 1
	DrawText 64,308,"Instrument:"
	SetDrawEnv fsize= 10,fstyle= 1
	DrawText 64,327,"Mission:"
	DrawText 18,266,"Exchange File Control (OLD NASA FORMAT)"
	SetDrawEnv fillbgc= (63534,65353,60977)
	DrawRRect 13,270,425,371
	SetDrawEnv fillbgc= (63534,65353,60977)
	DrawRRect 11,34,427,236
	SetDrawEnv fillfgc= (58335,57851,59009)
	DrawRRect 245,161,418,199
	SetDrawEnv fillfgc= (59391,63594,65535)
	DrawRRect 331,151,419,131
	SetDrawEnv fstyle= 1
	DrawText 136,52,"Flight Dates"
	SetDrawEnv fstyle= 1
	DrawText 36,52,"Molecules"
	SetDrawEnv fsize= 10,fstyle= 1
	DrawText 64,346,"Participants:"
	SetDrawEnv fsize= 10,fstyle= 1
	DrawText 64,289,"Prefix:"
	SetDrawEnv fsize= 10,fstyle= 1
	DrawText 193,289,"Suffix:"
	SetDrawEnv fsize= 10,fstyle= 1
	DrawText 64,308,"Instrument:"
	SetDrawEnv fsize= 10,fstyle= 1
	DrawText 64,327,"Mission:"
	SetDrawEnv fsize= 10,fstyle= 1
	DrawText 64,365,"Affiliations:"
	Button EditMols,pos={12,7},size={150,20},proc=Post_ButtonProc,title="Edit Molecule List"
	Button EditMols,fColor=(57346,65535,49151)
	ListBox Molecules,pos={23,56},size={100,150},listWave=root:Molecules
	ListBox Molecules,selWave=root:MoleculesSel,mode= 4
	ListBox Flights,pos={131,56},size={100,150},fSize=10,listWave=root:Flights
	ListBox Flights,selWave=root:FlightsSel,mode= 4
	Button LoadCM,pos={273,7},size={150,20},proc=Post_ButtonProc,title="Load All Cal Matrices"
	Button LoadCM,fColor=(49151,65535,57456)
	Button LoadFlights,pos={244,45},size={174,21},proc=Post_ButtonProc,title="Load Flight Responses"
	Button LoadFlights,fColor=(36860,56507,14105)
	Button EditCurveDB,pos={245,104},size={174,21},proc=Post_ButtonProc,title="\\f01Assign\\f00 Cal Curves"
	Button EditCurveDB,fColor=(49267,56878,58982)
	Button ApplyCurves,pos={244,131},size={124,21},proc=Post_ButtonProc,title="\\f01Apply\\f00 Cal Curves"
	Button ApplyCurves,fColor=(49267,56878,58982)
	Button MakeExchange,pos={244,208},size={124,21},proc=Post_ButtonProc,title="Make Exchange Files"
	Button MakeExchange,fSize=11,fColor=(50202,53687,30632)
	CheckBox makeplots,pos={372,134},size={45,14},title="plots?"
	CheckBox makeplots,labelBack=(59391,63594,65535)
	CheckBox makeplots,variable= root:Panel:G_makeplots
	Button FlightDisp,pos={243,159},size={87,21},proc=Post_ButtonProc,title="Correlation Plot"
	Button FlightDisp,fSize=10,fColor=(46792,43413,48542)
	CheckBox dispconc,pos={250,183},size={39,14},proc=Post_CheckProc,title="conc"
	CheckBox dispconc,labelBack=(58335,57851,59009)
	CheckBox dispconc,variable= root:Panel:G_dispmodeC,mode=1
	CheckBox dispresp,pos={292,183},size={37,14},proc=Post_CheckProc,title="resp"
	CheckBox dispresp,labelBack=(58335,57851,59009)
	CheckBox dispresp,variable= root:Panel:G_dispmodeR,mode=1
	CheckBox dispprec,pos={339,183},size={75,14},title="include precs"
	CheckBox dispprec,labelBack=(58335,57851,59009),variable= root:Panel:G_dispprec
	CheckBox drymolefraction,pos={374,212},size={37,14},title="dry?"
	CheckBox drymolefraction,help={"Click to submit dry mole fraction mixing ratios."}
	CheckBox drymolefraction,labelBack=(65535,65535,65535)
	CheckBox drymolefraction,variable= root:Panel:G_useDMF
	Button allmols,pos={23,210},size={100,20},proc=Post_ButtonProc,title="All mols"
	Button allmols,fColor=(58377,61375,49936)
	Button allflts,pos={131,210},size={100,20},proc=Post_ButtonProc,title="All flights"
	Button allflts,fColor=(58377,61375,49936)
	Button DispCalCurve,pos={245,78},size={174,21},proc=Post_ButtonProc,title="Display a Cal Curve"
	Button DispCalCurve,fColor=(49267,56878,58982)
	TitleBox paricipants,pos={146,334},size={235,12},fSize=9,frame=0
	TitleBox paricipants,variable= root:Panel:S_participantsShort
	Button edit_part,pos={22,332},size={40,16},proc=Post_ButtonProc,title="edit"
	Button edit_part,fSize=10
	Button edit_prefix,pos={22,275},size={40,16},proc=Post_ButtonProc,title="edit"
	Button edit_prefix,fSize=10
	Button edit_suffix,pos={151,275},size={40,16},proc=Post_ButtonProc,title="edit"
	Button edit_suffix,fSize=10
	TitleBox paricipants1,pos={113,276},size={16,16},fSize=12,frame=0
	TitleBox paricipants1,variable= root:Panel:S_xcPrefix
	TitleBox suffixDisp,pos={239,276},size={20,16},fSize=12,frame=0
	TitleBox suffixDisp,variable= root:Panel:S_xcSuffix
	Button edit_comments,pos={294,313},size={120,16},proc=Post_ButtonProc,title="edit comments"
	Button edit_comments,fSize=10
	Button edit_instrument,pos={22,294},size={40,16},proc=Post_ButtonProc,title="edit"
	Button edit_instrument,fSize=10
	TitleBox instrument,pos={140,295},size={39,16},fSize=12,frame=0
	TitleBox instrument,variable= root:Panel:S_instrument
	Button edit_mission,pos={22,313},size={40,16},proc=Post_ButtonProc,title="edit"
	Button edit_mission,fSize=10
	TitleBox mission,pos={120,314},size={46,16},fSize=12,frame=0
	TitleBox mission,variable= root:Panel:S_Mission
	Button edit_mollst,pos={294,293},size={120,16},proc=Post_ButtonProc,title="molecules to export"
	Button edit_mollst,fSize=10
	Button RemoveGraphs,pos={20,376},size={120,16},proc=Post_ButtonProc,title="Remove Graphs"
	Button RemoveGraphs,fSize=10,fColor=(65535,59218,56220)
	Button MakeStat,pos={298,376},size={120,16},proc=Post_ButtonProc,title="Make Stationery"
	Button MakeStat,fSize=10,fColor=(65535,49151,49151)
	Button RemoveTables,pos={144,376},size={120,16},proc=Post_ButtonProc,title="Remove Tables"
	Button RemoveTables,fSize=10,fColor=(65535,59218,56220)
	Button edit_affil,pos={22,351},size={40,16},proc=Post_ButtonProc,title="edit"
	Button edit_affil,fSize=10
	TitleBox affiliations,pos={139,353},size={227,12},fSize=9,frame=0
	TitleBox affiliations,variable= root:Panel:S_affiliationShort
	Button TimeDisp,pos={334,159},size={88,21},proc=Post_ButtonProc,title="Time Series Plot"
	Button TimeDisp,fSize=10,fColor=(46792,43413,48542)
	Button ICARTT,pos={319,243},size={70,40},proc=Post_ButtonProc,title="ICARTT \rPanel"
	Button ICARTT,fColor=(49151,53155,65535)


EndMacro

Function Post_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			StrSwitch( ba.ctrlName )
				case "EditMols":
					MolTable()
					break
				case "LoadCM":
					LoadCalibrationMatrices()
					break
				case "LoadFlights":
					LoadRespData()
					break
				case "EditCurveDB":
					CalCurveTable()
					break
				case "ApplyCurves":
					ApplyCalCurves()
					break
				case "FlightDisp":
					CorrelationPlot()
					break
				case "TimeDisp":
					TimeSeriesPlot()
					break
				case "allmols":
					Wave MoleculesSel = root:MoleculesSel
					MoleculesSel = 1
					break
				case "allflts":
					Wave FlightsSel = root:FlightsSel
					FlightsSel = 1
					break
				case "DispCalCurve":
					DisplayACalCurve()
					break
				case "edit_part":
					XC_Participants()
					break
				case "edit_affil":
					XC_Affiliation()
					break
				case "edit_prefix":
					XC_Prefix()
					break
				case "edit_suffix":
					XC_Suffix()
					break
				case "edit_comments":
					XC_Comments()
					break
				case "edit_mission":
					XC_Mission()
					break
				case "edit_table":
					execute "XC_molTable()"
					break
				case "edit_instrument":
					XC_Instrument()
					break
				case "edit_mollst":
					XC_mollst()
					break
				case "MakeExchange":
					WriteExchangeFiles()
					break
				case "RemoveGraphs":
					removeDisplayedGraphs()
					break
				case "RemoveTables":
					removeDisplayedTables()
					break
				case "MakeStat":
					MakeStationery()
					break
				case "ICARTT":
					execute"ICARTT_Data_panel()"
					SVAR df = root:ICARTT:G_ICARTTdf
					NVAR dloc = root:ICARTT:G_datasetloc
					df = "root:ICARTT:UCATS_GC"
					dloc = 3
					ICARTT_Refresh()
					break			
			endswitch
			break
	endswitch

	return 0
End


Function Post_CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba


	NVAR dspC = $kDFpan + ":G_dispmodeC"
	NVAR dspR = $kDFpan + ":G_dispmodeR"
	NVAR dspP = $kDFpan + ":G_dispprec"
	NVAR xchDMF = $kDFpan + ":G_useDMF"

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			break
	endswitch
	
	strswitch( cba.ctrlName )
		case "dispconc":
			dspC = 1
			dspR = 0
			CheckBox dispprec disable=0
			break
		case "dispresp":
			dspC = 0
			dspR = 1
			CheckBox dispprec disable=2
			break
		case "drymolefraction":
			xchDMF = checked
			break
	
	endswitch
	
	CheckBox dispresp,variable= dspR,mode=1
	CheckBox dispconc,variable= dspC,mode=1

	return 0
End

Function XC_Participants()

	STRUCT XC_struct xcs
	GetXCstructure(xcs)

	string new = xcs.participants
	Prompt new, "Update the list of participants"
	DoPrompt "Exchange file control", new
	if ( V_flag )
		return -1
	endif

	xcs.participants = new
	
	if ( strlen(xcs.participants) > 45 )
		xcs.participantsShort = xcs.participants[0,45] + "..."
	endif
end

Function XC_Affiliation()

	STRUCT XC_struct xcs
	GetXCstructure(xcs)

	string new = xcs.affiliation
	Prompt new, "Update the affiliations"
	DoPrompt "Exchange file control", new
	if ( V_flag )
		return -1
	endif

	xcs.affiliation = new
	
	if ( strlen(xcs.affiliation) > 45 )
		xcs.affiliationShort = xcs.affiliation[0,45] + "..."
	endif
end

Function XC_Suffix()

	STRUCT XC_struct xcs
	GetXCstructure(xcs)

	string new = xcs.xcSuffix
	Prompt new, "Change the exchange file suffix (please include .)"
	DoPrompt "Exchange file control", new
	if ( V_flag )
		return -1
	endif
	
	xcs.xcSuffix = new
end

Function XC_Prefix()

	STRUCT XC_struct xcs
	GetXCstructure(xcs)

	string new = xcs.xcPrefix
	Prompt new, "Change the exchange file prefix"
	DoPrompt "Exchange file control", new
	if ( V_flag )
		return -1
	endif
	
	xcs.xcPrefix = new
end

Function XC_Mission()

	STRUCT XC_struct xcs
	GetXCstructure(xcs)

	string new = xcs.mission
	Prompt new, "Enter Mission Name"
	DoPrompt "Exchange file control", new
	if (V_flag)
		return -1
	endif
	
	xcs.mission = new
	
end

Function XC_Instrument()

	STRUCT XC_struct xcs
	GetXCstructure(xcs)

	string new = xcs.instrument
	Prompt new, "Edit the instrument name"
	DoPrompt "Exchange file control", new
	if ( V_flag )
		return -1
	endif
	
	xcs.instrument = new
end

function XC_Comments()

	STRUCT XC_struct xcs
	GetXCstructure(xcs)
	
	DoWindow /K FlightCommentTable
	Edit/K=1/W=(5,42,680,415) xcs.comments as "Flight Comment Table"
	ModifyTable alignment(xcs.comments)=0,width(xcs.comments)=586
	DoWindow /C FlightCommentTable
	
end

function XC_molTable()

	STRUCT XC_struct xcs
	GetXCstructure(xcs)

	Edit/K=1/W=(5,44,533,572) xcs.shortmols,xcs.fullmols,xcs.units, xcs.sigfigs as "Exchange File Mol Table"
	ModifyTable format(Point)=1,style(xcs.shortmols)=1,width(xcs.shortmols)=104,width(xcs.fullmols)=140

EndMacro

function XC_mollst()

	STRUCT XC_struct xcs
	GetXCstructure(xcs)

	string new = xcs.xcMolLst
	Prompt new, "List of molecules saved in exchange file."
	DoPrompt "Exchange file control", new
	if ( V_flag )
		return -1
	endif
	
	xcs.xcMolLst = new
end