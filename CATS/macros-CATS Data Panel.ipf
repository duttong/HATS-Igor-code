#pragma rtGlobals=1		// Use modern global access method.

Function CATSpanel()
	string win = "CATS_Panel"
	MolWave()
	MakeAttribString()
	MakeSmoothList()
	SVAR /Z AttribList = root:S_AttribList
	SVAR mol = G_mol
		
	Dowindow /K $win
	execute "CATS_Panel()"
	Dowindow /C $win

	SetWindow kwTopWin,hook(datapanalhook)= DataPanelWindowHook
	
end

Window CATS_Panel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(18,488,374,691) as "CATS Data Panel"
	SetDrawLayer UserBack
	DrawRect 8,8,208,123
	DrawText 31,24,"Mols"
	SetDrawEnv fsize= 9
	DrawText 92,114,"Response Smooth Factor"
	Button Load,pos={15.00,129.00},size={100.00,20.00},proc=CATS_ButtonProc,title="Load Only"
	Button Load,fColor=(65535,65533,32768)
	ListBox mols,pos={13.00,26.00},size={67.00,94.00},proc=CATS_ListBoxProc
	ListBox mols,listWave=root:molecules,mode= 2,selRow= 0
	Button LoadandGo,pos={14.00,151.00},size={100.00,20.00},proc=CATS_ButtonProc,title="Load and Go"
	Button LoadandGo,fColor=(65535,65532,16385)
	Button Recalc,pos={14.00,174.00},size={100.00,20.00},proc=CATS_ButtonProc,title="Recalculate"
	Button Recalc,fColor=(52428,52425,1)
	PopupMenu attrib,pos={88.00,29.00},size={110.00,23.00},proc=CATS_PopMenuProc,title="Attribute"
	PopupMenu attrib,mode=1,popvalue="Height",value= #"\"Height;Area\""
	Slider smoothfact,pos={92.00,55.00},size={100.00,47.00},proc=CATS_SliderProc
	Slider smoothfact,labelBack=(65535,65535,65535)
	Slider smoothfact,limits={1,40,1},value= 2,side= 2,vert= 0,ticks= 5
	Button ExportToWeb,pos={221.00,44.00},size={120.00,20.00},proc=CATS_ButtonProc,title="Export to GMD"
	Button ExportToWeb,fColor=(49151,49152,65535)
	Button MonthlyMeans,pos={221.00,14.00},size={120.00,20.00},proc=CATS_ButtonProc,title="Monthly Means"
	Button MonthlyMeans,fColor=(49151,60031,65535)
	CheckBox last2yrs,pos={126.00,133.00},size={83.00,30.00},title="Load only \nlast 2 years"
	CheckBox last2yrs,fSize=12,variable= G_load2yrs
	SetWindow kwTopWin,hook(datapanalhook)=DataPanelWindowHook
EndMacro


Function MolWave()
	SVAR loadMol = root:G_loadMol
	MakeTextWaveFromList(loadMol, "molecules", ";")
end

Function MakeAttribString()
	SVAR loadMol = root:G_loadMol
	SVAR /Z AttribList = root:S_AttribList			// integration choice H or A

	if ( SVAR_Exists(AttribList) == 1 )
		return 1
	endif
	
	String /G S_AttribList = ""
	SVAR /Z AttribList = root:S_AttribList
	Variable i
	String mol
	
	for(i=0;i<ItemsInList(loadMol); i+=1)
		mol = StringFromList(i, loadMol)
		AttribList = AddListItem(mol + ":" + "Height", AttribList, ";", i)
	endfor
end

Function MakeSmoothList()
	SVAR loadMol = root:G_loadMol
	SVAR /Z SmoothList = root:S_SmoothList		// Cal response smooth factor

	if ( SVAR_Exists(SmoothList) == 1 )
		return 1
	endif
	
	String /G S_SmoothList = ""
	SVAR /Z SmoothList = root:S_SmoothList
	Variable i
	String mol
	
	for(i=0;i<ItemsInList(loadMol); i+=1)
		mol = StringFromList(i, loadMol)
		SmoothList = AddListItem(mol + ":" + "1", SmoothList, ";", i)
	endfor
end

// returns the row location of G_mol in the molecules wave
Function FindMolRow()
	SVAR mol = G_mol
	return WhichListItem(mol, WaveToList("molecules", ";"))
end

ThreadSafe Function ReturnSmoothFactor()
	SVAR mol = G_mol
	SVAR SmoothList = root:S_SmoothList
	return NumberByKey(mol, SmoothList)
end

Function/S ReturnIntAttrib([mol])
	string mol

	SVAR Gmol = G_mol
	SVAR AttribList = root:S_AttribList

	if ( ParamIsDefault(mol) )
		mol = Gmol
	endif

	if (  cmpstr(StringByKey(mol, AttribList), "Area") == 0 )
		return "A"
	else
		return "H"
	endif
end


Function CATS_ListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba
	
	SVAR mol = root:G_mol
	SVAR AttribList = root:S_AttribList
	Wave /t molecules

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave

	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 3: // double click
			mol = molecules[row]
			PopupMenu attrib,mode=1,popvalue=StringByKey(mol, AttribList)
			Slider smoothfact,value= ReturnSmoothFactor()
			ReloadAndCalc()
			break
		case 4: // cell selection
			mol = molecules[row]
			PopupMenu attrib,mode=1,popvalue=StringByKey(mol, AttribList)
			Slider smoothfact,value= ReturnSmoothFactor()
			break
		case 5: // cell selection plus shift key
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			break
	endswitch

	return 0
End

Function CATS_PopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	SVAR AttribList = root:S_AttribList
	SVAR mol = root:G_mol
	NVAR SD = root:G_recalcSD

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			AttribList = ReplaceStringByKey(mol, AttribList, popStr)
			SD = 1
			break
	endswitch

	return 0
End



Function CATS_SliderProc(sa) : SliderControl
	STRUCT WMSliderAction &sa
	
	SVAR mol = root:G_mol
	SVAR SmoothList = root:S_SmoothList

	switch( sa.eventCode )
		case -1: // kill
			break
		default:
			if( sa.eventCode & 1 ) // value set
				Variable curval = sa.curval
				SmoothList = ReplaceNumberByKey(mol, SmoothList, curval)
			endif
			break
	endswitch

	return 0
End



Function CATS_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	SVAR mol = root:G_mol
	NVAR recalc = root:G_recalcSD
	string mol_gr

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			strswitch( ba.ctrlName )
				case "Load":
					LoadIntegrationResults(mol=mol)
					break
				case "LoadandGo":
					ReloadAndCalc()
					break
				case "Recalc":
					BestConcCalc()
					break
				case "Recalc_graph":
					recalc=1
					mol_gr = MolFromGraph()
					BestConcCalc(mol=mol_gr)
					break
				case "refresh_graph":
					recalc = SelectNumber(recalc==1, 2, 1)
					mol_gr = MolFromGraph()
					BestConcCalc(mol=mol_gr)
					break
				case "togglecallines_graph":
					AppendCalLines()
					break
				case "togglecals_graph":
					CalValueLinesToPlot()
					break
				case "toggleairports_graph":
					AirSampColor()
					break
				case "togglecalresp_graph":
					AppendCalResp()
					break
				case "datatable_graph":
					dataTable()
					break
				case "export_graph":
					ExportForWebPagesFUNCT(MolFromGraph())
					break
				case "MonthlyMeans":
					execute "MonthMeansPlot()"
					break
				case "ExportToWeb":
					ExportForWebPagesFUNCT("_ALL_")
					break
				case "appendinterp":
					appendInterp()
					break
				case "Cal1":		// from the CalFlagging function
					SVAR attrib = G_attrib
					CalFlagging(mol=mol, meth="c1", attrib=attrib)
					break
				case "Cal2":		// from the CalFlagging function
					SVAR attrib = G_attrib
					CalFlagging(mol=mol, meth="c2", attrib=attrib)
					break
				case "lastyear":
					Wave day = $mol + "_date"
					variable pt = numpnts(day)-1
					SetAxis bottom day[pt]-60*60*24*100, day[pt]
					SetAxis/A=2 left
					SetAxis/A=2 right
					break
			endswitch
			break
	endswitch

	return 0
End

Function appendInterp()

	string wvs = TraceNameList("", ";", 1)
	if (strsearch(wvs, "c1i", 0) != -1)
		RemoveFromGraph c1i
		return 0
	endif
	if (strsearch(wvs, "c2i", 0) != -1)
		RemoveFromGraph c2i
		return 0
	endif
	if (strsearch(wvs, "c1r", 0) != -1)
		AppendToGraph c1i vs c1xi
		ModifyGraph rgb(c1i)=(39321,1,1)
	elseif (strsearch(wvs, "c2r", 0) != -1)
		AppendToGraph c2i vs c2xi
		ModifyGraph rgb(c2i)=(39321,1,1)
	endif

end

Function CATS_CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			break
	endswitch
	
	// toggle between local and GMT
	if (cmpstr(cba.ctrlName, "timezone") == 0)
		SVAR site = root:G_site3
		String TZ="brw:-9;sum:-3;nwr:-7;mlo:-10;smo:-11;spo:+12"	// all are standard time, only nwr and brw have DST
		Variable delta = NumberByKey(site, TZ)*60*60
		delta = checked == 1 ? delta : 0
		ModifyGraph offset={delta,0}
		return 0
	elseif (cmpstr(cba.ctrlName, "errorbars") == 0)
		string wvst = StringFromList(0, TraceNameList("", ";", 1))		// one wave from the graph
		string mol = wvst[0,strsearch(wvst, "_", 0)-1]
		Wave sd = $mol + "_H_sd"
		if (checked)
			ErrorBars $wvst Y,wave=(sd, sd)
		else
			ErrorBars $wvst off
		endif
		return 0
	endif

End



// refreshes data panel when activated.
Function DataPanelWindowHook(s)
	STRUCT WMWinHookStruct &s
	
	SVAR mol = root:G_mol
	SVAR AttribList = root:S_AttribList
	
	if ( s.eventCode == 0 )
		ListBox mols,listWave=root:molecules,mode= 2,selRow= FindMolRow()
		Slider smoothfact,value= ReturnSmoothFactor()
		PopupMenu attrib,mode=1, popvalue=StringByKey(mol, AttribList)
	endif
	
	return 0
End