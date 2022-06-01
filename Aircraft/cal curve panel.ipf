#pragma rtGlobals=1		// Use modern global access method.

Window CalCurvePanel() : Panel
	PauseUpdate; Silent 1		// building window...
	string win = "CalCurvePanel"
	
	if ( strlen(WinList("CalCurvePanel", ";", "")) > 0 )
		DoWindow /F $win
	else
		NewPanel /W=(425,48,883,334) as "Cal Curve Panel"
		DoWindow /C $win
	endif
	
	ModifyPanel cbRGB=(39321,39321,39321)
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (60514,65535,61571)
	DrawRRect 5,9,306,68
	DrawRRect 5,71,447,221
	SetDrawEnv fsize= 14
	DrawText 35,98,"Molecule"
	SetDrawEnv fsize= 14
	DrawText 132,98,"Norm. Meth."
	SetDrawEnv fsize= 14
	DrawText 249,98,"Cal Curve"
	SetDrawEnv fsize= 14
	DrawText 354,98,"Data Date"
	Button DoIt,pos={339,187},size={100,29},proc=Cal_ButtonProc,title="\\K(2,39321,1)\\f01Do it!"
	Button DoIt,labelBack=(49151,65535,65535),fColor=(57346,65535,49151)
	Button KillGraphs,pos={184,228},size={107,38},proc=Cal_ButtonProc,title="\\K(52428,1,1)Remove All\rGraphs"
	Button ReLoad,pos={315,18},size={126,45},proc=Cal_ButtonProc,title="\\f01\\K(0,0,65535)Load Integration\rResults"
	Button MolList,pos={10,17},size={140,20},proc=Cal_ButtonProc,title="\\K(1,26214,0)Edit Molecule List"
	Button SelposAssign,pos={10,42},size={140,20},proc=Cal_ButtonProc,title="\\K(1,26214,0)Selpos Assignments"
	Button viewCals,pos={159,18},size={140,20},proc=Cal_ButtonProc,title="\\K(1,26214,0)View/Edit Cal. Tanks"
	ListBox MolLst,pos={13,103},size={104,80},proc=Cal_ListBoxProc,frame=4
	ListBox MolLst,listWave=root:panel:Molecules,mode= 2,selRow= ReturnMolRow(),editStyle= 1
	ListBox DriftMethods,pos={121,103},size={104,80},proc=Cal_ListBoxProc,frame=4
	ListBox DriftMethods,listWave=root:panel:DriftMethods,mode= 2,selRow= Return_Pansel(0)
	ListBox DriftMethods,editStyle= 1
	ListBox CalCurveMethod,pos={229,103},size={104,80},proc=Cal_ListBoxProc,frame=4
	ListBox CalCurveMethod,listWave=root:panel:CalCurveMethods,mode= 2,selRow= Return_Pansel(1)
	ListBox CalCurveMethod,editStyle= 1
	ListBox CalDates,pos={337,103},size={104,80},proc=Cal_ListBoxProc,frame=4
	ListBox  CalDates,listWave=root:CalDates,mode= 1,selRow= Return_CalDateRow(),editStyle= 1
	Button DispCalCurve,pos={10,228},size={165,38},proc=Cal_ButtonProc,title="Display a Cal Curve"
	PopupMenu NormCyl,pos={13,191},size={231,20},proc=Cal_PopMenuProc,title="Normalizing Cylinder"
	PopupMenu NormCyl,fSize=9,fStyle=0
	PopupMenu NormCyl,mode=2,popvalue=Return_NormCyl(),value= ReturnSelposCylLst()
	Button MakeStationery,pos={299,228},size={148,38},proc=Cal_ButtonProc,title="\\K(52428,1,1)Make Stationery"
	Button AddTank,pos={159,42},size={70,20},proc=Cal_ButtonProc,title="\\K(1,26214,0)Add Tank"
	Button DelTank,pos={230,42},size={70,20},proc=Cal_ButtonProc,title="\\K(52428,1,1)Del Tank"
	Button DataTable,pos={253,187},size={80,29},proc=Cal_ButtonProc,title="Data Table"

EndMacro

Function Cal_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	switch( ba.eventCode )
		case 2: // mouse up
			StrSwitch(ba.ctrlName)
				case "MolList":
					execute "MolTable()"
					break
				case "SelposAssign":
					execute "SelposAssigns()"
					break
				case "viewCals":
					ViewCalCylinders()
					break
				case "AddTank":
					AddCalCylinder()
					break
				case "DelTank":
					DelCalCylinder()
					break
				case "ReLoad":
					LoadIntegrationResults()
					break
				case "DoIt":
					NormalizeData()
					CalCurve()
					break
				case "CalMatrix":
					MakeCalMatrix( )
					break
				case "DispCalCurve":
					DisplayACalCurve()
					break
				case "KillGraphs":
					removeDisplayedGraphs()
					break
				case "MakeStationery":
					MakeStationery()
					break
				case "DataTable":
					DataTable()
					break
			endswitch
			break
	endswitch

	return 0
End


Function Cal_ListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
	
	if ( lba.eventCode == 4 )		 // clicked
		SetDataFolder $kDFpan
		Wave/T mols = molecules
		Wave/T CalDates = root:CalDates
		SVAR mol = root:S_mol
		SVAR S_CalDate = root:S_caldate
		wave PS = $mol + "_pansel"
//		variable calrow = ReturnCalDateRow()
		variable dmeth,cmeth
		
		StrSwitch ( lba.ctrlName )

			case "MolLst":
				mol = mols[row]
				wave PS = $mol + "_pansel"
				dmeth = PS[0][0]		// look up saved drift method
				cmeth = PS[0][1]		// look up saved cal curve fit
				ListBox DriftMethods,selRow= dmeth
				ListBox CalCurveMethod,selRow= cmeth
				break
				
			case "DriftMethods":
				PS[0][0] = row		// save drift method
				break
			case "CalCurveMethod":
				PS[0][1] = row		// save cal curve fit type
				break
			case "CalDates":
				S_CalDate = CalDates[row]
				break
		endswitch
		SetDataFolder root:
	endif

	return 0
End


Function Cal_PopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			String /G S_NormCyl = popStr
			break
	endswitch

	return 0
End

Function ReturnMolRow()

	SVAR mol = root:S_mol
	variable i
	
	SetDataFolder $kDFpan
	Wave/T mols = molecules
	SetDataFolder root:
	
	for(i=0; i<numpnts(mols); i+=1 )
		if ( cmpstr(mols[i], mol) == 0 )
			return i
		endif
	endfor
	
	return NaN
	
end

Function Return_Pansel( item )
	variable item

	SVAR mol = root:S_mol
	variable i, dmeth, cmeth

	SetDataFolder $kDFpan
	wave PS = $mol + "_pansel"
	dmeth = PS[0][0]		// look up saved drift method
	cmeth = PS[0][1]		// look up saved cal curve fit
	SetDataFolder root:
	
	if (item)
		return cmeth
	endif
	return dmeth
	
end

Function Return_CalDateRow()

	SVAR S_CalDate = root:S_caldate
	Wave/T CalDates = root:CalDates
	variable i
	
	for ( i=0; i<numpnts(CalDates); i+=1 )
		if (cmpstr(CalDates[i], S_CalDate) == 0 )
			return i
		endif
	endfor
	
	return -1
	
end

function/T Return_NormCyl()

	string NCyl = kDFpan + ":S_NormCyl"
	if (exists(NCyl) == 0 )
		NewDataFolder /O/S $kDFpan
		String /G S_NormCyl = "---"
		SetDataFolder root:
	else
		SVAR S_NCyl = $NCyl
		return S_NCyl
	endif

end