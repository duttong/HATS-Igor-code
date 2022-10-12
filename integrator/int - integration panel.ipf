#pragma rtGlobals=1		// Use modern global access method.


Window INTconfigPanel() : Table

	if (Exists("config") != 1)
		make /t/n=5 config, configNotes
	endif
	configNotes[0] = "Number of Channels"
	configNotes[1] = "Instrument Name"
	configNotes[2] = ""
	configNotes[4] = "Experiment Date"

	if ( !DataFolderExists("chroms") )
		NewDataFolder root:chroms
	endif

	if ( !DataFolderExists("DB") )
		NewDataFolder root:DB
	endif

	if ( !DataFolderExists("AS") )
		NewDataFolder root:AS
	endif

	if ( !DataFolderExists("temp") )
		NewDataFolder root:temp
	endif

	if (exists("root:V_chans") == 0)
		Variable /g root:V_chans = 1
	endif
	execute "V_chans := str2num(root:config[0])"		// sets dependence
	
	if (exists("root:S_instrument") == 0)
		String /G root:S_instrument=""
	endif
	execute "S_instrument	:= root:config[1]"
	
	if (exists("root:S_date") == 0)
		String /G S_date = "000000"
	endif


	DoWindow /K INTconfig
	Edit/K=1/W=(31,72,436,261) configNotes,config as "Integrator Configuration"
	ModifyTable size(Point)=8,font(configNotes)="Century Schoolbook",size(configNotes)=14
	ModifyTable style(configNotes)=1,width(configNotes)=170,font(config)="Century Schoolbook"
	ModifyTable size(config)=14,style(config)=1,width(config)=134
	DoWindow /C INTconfig
	
EndMacro

Function PrepConfigTable() 

	NVAR chans = root:V_chans
	variable ch
	
	if (numtype(chans) != 0 )
		abort "Define the number of channels first.  Run \"Integrator Configuration\" and edit the number of channels."
	endif

	if (Exists("PrepConfig") != 1)
		make /o/t/n=(chans) PrepConfig, PrepNotes
		for (ch=1; ch<=chans; ch+= 1)
			prepConfig[ch-1] = "1/0"
		endfor
	endif
	if (Exists("SmoothConf") != 1)
		make /o/t/n=(chans) SmoothConf, SmoothNotes
		for (ch=1; ch<=chans; ch+= 1)
			SmoothConf[ch-1] = "4/25"
		endfor
	endif
	for (ch=1; ch<=chans; ch+= 1)
		prepNotes[ch-1] = "Chan" + num2str(ch) + " concat/shift"
	endfor
	for (ch=1; ch<=chans; ch+= 1)
		SmoothNotes[ch-1] = "algo/Iter"
	endfor

	DoWindow /K PRPconfig
	Edit/K=1/W=(27,287,573,481) prepNotes,prepConfig,SmoothNotes,SmoothConf as "Prep Chrom Config"
	ModifyTable font(prepNotes)="Arial",size(prepNotes)=12,style(prepNotes)=1,alignment(prepNotes)=1
	ModifyTable width(prepNotes)=174,font(prepConfig)="Arial",size(prepConfig)=12,style(prepConfig)=1
	ModifyTable alignment(prepConfig)=1,width(prepConfig)=92,rgb(prepConfig)=(0,0,65535)
	ModifyTable font(SmoothNotes)="Arial",size(SmoothNotes)=12,style(SmoothNotes)=1
	ModifyTable alignment(SmoothNotes)=1,width(SmoothNotes)=94,font(SmoothConf)="Arial"
	ModifyTable size(SmoothConf)=12,style(SmoothConf)=1,alignment(SmoothConf)=1,rgb(SmoothConf)=(0,0,65535)
	DoWindow /C PRPconfig
	
End


Window INTdatabasePanel1() : Table
	PauseUpdate; Silent 1		// building window...
	DoWindow /K INTdb1
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:DB:
	Edit/K=1/W=(2,441,935,674) DB_mols,DB_chan,DB_peakStart,DB_peakStop,DB_expStart,DB_expStop as "Integrator Database"
	AppendToTable DB_meth,DB_methParam1,DB_edgePoints,DB_activePeak 
	ModifyTable style(DB_mols)=1,rgb(DB_mols)=(0,0,65535),width(DB_methParam1)=90,width(DB_edgePoints)=88
	SetDataFolder fldrSav0
	DoWindow /C INTdb1
EndMacro

Window INTdatabasePanel2() : Table
	PauseUpdate; Silent 1		// building window...
	string DBchan = "root:DB:DB_chan"
	
	// add DB_calval wave to DB if it does not exist
	if (exists("root:DB:DB_calval") == 0)
		Setdatafolder db
		make /n=(numpnts($DBchan)) DB_calval = 1
		Setdatafolder root:
	endif
	// add DB_manERR wave to DB if it does not exits
	if (exists("root:DB:DB_manERR") == 0)
		Setdatafolder db
		make /n=(numpnts($DBchan)) DB_manERR = 0
		Setdatafolder root:
	endif

	DoWindow /K INTdb2
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:DB:
	Edit/K=1/W=(20,492,1188,755) DB_mols,DB_chan,DB_respTconst,DB_respPconst,DB_respTmeth as "Integrator Database"
	AppendToTable DB_respPmeth,DB_respMeth,DB_normMeth,DB_normSmooth,DB_normFirst,DB_normLast, DB_calval, DB_manERR
	ModifyTable style(DB_mols)=1,rgb(DB_mols)=(0,0,65535)
	SetDataFolder fldrSav0
	DoWindow /C INTdb2
EndMacro

Window INTerrorPanel() : Table
	PauseUpdate; Silent 1		// building window...

	Setdatafolder root:
	string DBchan = "root:DB:DB_chan"
	
	// add DB_calval wave to DB if it does not exist
	if (exists("root:DB:DB_calval") == 0)
		Setdatafolder db
		make /n=(numpnts($DBchan)) DB_calval = 1
		Setdatafolder root:
	endif
	// add DB_manERR wave to DB if it does not exits
	if (exists("root:DB:DB_manERR") == 0)
		Setdatafolder db
		make /n=(numpnts($DBchan)) DB_manERR = 0
		Setdatafolder root:
	endif
	
	DoWindow /K INTerr
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:DB:
	Edit/K=1/W=(428,52,876,317) DB_mols,DB_chan,DB_calval,DB_manERR as "Integration Errors"
	ModifyTable style(DB_mols)=1,rgb(DB_mols)=(0,0,65535)
	SetDataFolder fldrSav0
	DoWindow /C INTerr

	DoUpdate	
	DoAlert 0, "Edit the DB_manERR wave.  The value should be interms of % error relative to the cal.  Precision will be calculated automatically if the value <= 0."

EndMacro


// creates database variables and waves, if needed.
function InitialDBvars()

	if (exists("root:V_ASselect") != 2 )
		Variable /G root:V_ASselect = 1
	endif


	if (! DataFolderExists("root:DB") )
		NewDataFolder root:DB
	endif

	SetDataFolder root:DB

	if (exists("V_currMolRow") != 2)
		variable /G root:DB:V_currMolRow = 0
	endif
	if (exists("V_currMeth") != 2)
		variable /G root:DB:V_currMeth = 0
	endif
	if (exists("S_currMol") != 2)
		string /G root:DB:S_currMol = ""
	endif
	if (exists("V_currExp1") != 2)
		variable /G root:DB:V_currExp1 = 0
	endif
	if (exists("V_currExp2") != 2)
		variable /G root:DB:V_currExp2 = 0
	endif
	if (exists("V_allpeaks") != 2)
		variable /G root:DB:V_allpeaks = 0
	endif
	if (exists("V_currCh") != 2)
		variable /G root:DB:V_currCh = 1
	endif
	
	make /o/t methods = {"Fixed Window","Fixed Start","Fixed Stop","Tangent Skim", "Gauss Fit"}
	
	if (! WaveExists(DB_mols))
		make /n=0/t/O DB_mols, DB_peakStart, DB_peakStop
		make /n=0/O DB_chan, DB_meth, DB_methParam1, DB_edgePoints, DB_expStart, DB_expStop, DB_activePeak
		make /n=0/O DB_respMeth, DB_respPmeth, DB_respTmeth, DB_respPconst, DB_respTconst
		make /n=0/O DB_normMeth, DB_normSmooth, DB_normFirst, DB_normLast, DB_calval, DB_manERR
	endif

	DBupdatePoints()
	
	setDataFolder root:	

end


function INTpanel() : Panel

	PauseUpdate; Silent 1		// building window...

	InitialDBvars()
	DoWindow IntegrationPanel
	if (V_flag == 0)
		NewPanel /K=1/W=(4,48,843,455) as "Integration Panel"
		DoWindow /C IntegrationPanel
	else
		DoWindow /F IntegrationPanel
		abort
	endif
	
	InitNormVars()
	InitNormDB()
	
	ModifyPanel cbRGB=(16385,16388,65535), frameStyle=1, frameInset=3
	SetDrawLayer UserBack
	SetDrawEnv linethick= 2,fillpat= 7,fillfgc= (65535,65534,49151)
	DrawRect 825,52,539,349
	SetDrawEnv linethick= 2,fillpat= 11,fillfgc= (49151,65535,65535)
	DrawRect 10,219,245,351
	SetDrawEnv linethick= 2,fillfgc= (49151,53155,65535)
	DrawRect 10,10,828,47
	SetDrawEnv linethick= 2,linebgc= (49151,60031,65535),fillpat= 7,fillfgc= (49151,65535,65535)
	DrawRect 10,52,245,215
	SetDrawEnv fname= "Georgia",fstyle= 4
	DrawText 292,36,"Instrument:"
	SetDrawEnv fname= "Georgia",fstyle= 4
	DrawText 457,36,"Experiment Date:"
	SetDrawEnv linethick= 2,fillpat= 8,fillfgc= (49151,65535,65535)
	DrawRect 249,52,536,215
	SetDrawEnv fname= "Georgia",fsize= 16,fstyle= 1
	DrawText 59,82,"Peaks"
	SetDrawEnv fname= "Georgia",fsize= 16,fstyle= 1
	DrawText 44,244,"Detection Method"
	SetDrawEnv fname= "Georgia",fsize= 16,fstyle= 1
	DrawText 301,78,"Peak Edge Detection"
	SetDrawEnv fname= "Georgia",fsize= 16,fstyle= 1
	DrawText 263,148,"Int Start Point"
	SetDrawEnv fname= "Georgia",fsize= 16,fstyle= 1
	DrawText 409,149,"Int End Point"
	SetDrawEnv fname= "Georgia",fsize= 16,fstyle= 1
	DrawText 593,76,"Active Peaks"
	SetDrawEnv linethick= 2,fillpat= 12,fillfgc= (49151,65535,65535)
	DrawRect 250,220,536,350
	SetDrawEnv fname= "Georgia",fsize= 16,fstyle= 1
	DrawText 313,246,"Response Method"
	SetDrawEnv fname= "Georgia",fsize= 16,fstyle= 1
	DrawText 568,235,"Active Chroms & Integration"
	SetDrawEnv fname= "Georgia"
	DrawText 657,259,"Current AS:"
	SetDrawEnv linethick= 2,fillpat= 7,fillfgc= (49151,65535,49151)
	DrawRect 825,352,10,396
	TitleBox instrument,pos={372,18},size={54,22},labelBack=(49151,65535,65535)
	TitleBox instrument,font="Georgia",fSize=12,fStyle=1,variable= S_instrument
	TitleBox expdate,pos={565,16},size={75,22},labelBack=(49151,65535,65535)
	TitleBox expdate,font="Georgia",fSize=12,fStyle=1,variable= S_date
	ListBox mols,pos={137,66},size={98,139},proc=INTlistBoxProc
	ListBox mols,help={"Molecules in current database."},font="Georgia",fSize=12
	ListBox mols,frame=4,listWave=root:DB:DB_mols,mode= 2,selRow= 2
	Button addmol,pos={31,86},size={100,20},proc=INTButtonProc,title="Add Peak"
	Button addmol,font="Arial"
	Button delmol,pos={31,114},size={100,20},proc=INTButtonProc,title="Delete Peak"
	Button delmol,font="Arial"
	ValDisplay chdisp,pos={53,140},size={60,16},title="Ch #:"
	ValDisplay chdisp,help={"Channel number assigned to selected molecule."}
	ValDisplay chdisp,labelBack=(65535,65535,65535),font="Georgia",fSize=12
	ValDisplay chdisp,format="%2d",limits={0,0,0},barmisc={0,25},mode= 3
	ValDisplay chdisp,value= #"root:DB:V_currCh"
	ListBox meth,pos={30,247},size={125,73},proc=INTlistBoxProc
	ListBox meth,help={"Peak detections methods."},font="Georgia",fSize=12,frame=4
	ListBox meth,listWave=root:DB:methods,mode= 2,selRow= 0,editStyle= 1
	SetVariable InitialStart,pos={297,87},size={180,17},proc=INTsetVarProc,title="Initial Peak Start"
	SetVariable InitialStart,labelBack=(65535,65535,65535),font="Georgia",fSize=12
	SetVariable InitialStart,format="%3.1f"
	SetVariable InitialStart,limits={0,2000,1},value= root:DB:V_currExp1
	SetVariable InitialStop,pos={297,110},size={180,17},proc=INTsetVarProc,title="Initial Peak Stop"
	SetVariable InitialStop,labelBack=(65535,65535,65535),font="Georgia",fSize=12
	SetVariable InitialStop,format="%3.1f"
	SetVariable InitialStop,limits={0,2000,1},value= root:DB:V_currExp2
	ListBox PeakStart,pos={258,149},size={129,59},proc=INTlistBoxProc
	ListBox PeakStart,help={"Starting point in which the baseline is measured."}
	ListBox PeakStart,font="Georgia",fSize=12,frame=4,listWave=root:DB:points2
	ListBox PeakStart,mode= 2,selRow= 0
	ListBox PeakStop,pos={401,149},size={129,59},proc=INTlistBoxProc
	ListBox PeakStop,help={"Ending point in which the baseline is measured."}
	ListBox PeakStop,font="Georgia",fSize=12,frame=4,listWave=root:DB:points2
	ListBox PeakStop,mode= 2,selRow= 1
	SetVariable edgeAvg,pos={23,325},size={201,17},proc=INTsetVarProc,title="Num points in edge avg"
	SetVariable edgeAvg,help={"Number of points in chromatogram used to average peak \"start\" and \"stop\"."}
	SetVariable edgeAvg,labelBack=(65535,65535,65535),font="Georgia",fSize=12
	SetVariable edgeAvg,limits={1,40,1},value= root:DB:DB_edgePoints[2],bodyWidth= 60
	Button doall,pos={775,272},size={40,65},proc=INTButtonProc,title="All"
	Button doall,font="Arial"
	CheckBox edgeParam1,pos={160,249},size={71,42},proc=INTedgeParamCheckProc,title="Use\rRetention\rTime?"
	CheckBox edgeParam1,help={"If checked, the window will move with the peaks retention time."}
	CheckBox edgeParam1,font="Arial",fSize=12,value= 0
	ValDisplay numchans,pos={729,15},size={93,13},title="Num Chans"
	ValDisplay numchans,help={"Number of channels defined."}
	ValDisplay numchans,labelBack=(49151,53155,65535),font="Georgia",fSize=10
	ValDisplay numchans,frame=0,limits={0,5,0},barmisc={0,1000},bodyWidth= 30
	ValDisplay numchans,value= #"root:V_chans"
	ValDisplay numchroms,pos={661,29},size={161,13},title="Chroms Loaded (per chan)"
	ValDisplay numchroms,help={"Number of chromatograms loaded (per channel)."}
	ValDisplay numchroms,labelBack=(49151,53155,65535),font="Georgia",fSize=10
	ValDisplay numchroms,format="%g",frame=0
	ValDisplay numchroms,limits={0,0,0},barmisc={0,1000},bodyWidth= 30
	ValDisplay numchroms,value= #"returnMAXchromNum(1)-returnMINchromNum(1)+1"
	Button findret,pos={656,271},size={115,20},proc=INTButtonProc,title="Retetion Times"
	Button findret,font="Arial"
	Button findedges,pos={656,294},size={115,20},proc=INTButtonProc,title="Find Peak Edges"
	Button findedges,font="Arial"
	Button integrate,pos={656,317},size={115,20},proc=INTButtonProc,title="Integrate Peaks"
	Button integrate,font="Arial"
	Button DBtable,pos={114,358},size={90,30},proc=INTButtonProc,title="view\rdatabase"
	Button DBtable,labelBack=(65535,54611,49151),font="Arial"
	Button DBtable,fColor=(49151,65535,65535)
	PopupMenu respMeth,pos={260,250},size={143,20},proc=INTpopMenuProc,title="response from"
	PopupMenu respMeth,help={"Response calculation uses either peak height or area."}
	PopupMenu respMeth,font="Georgia",fSize=12
	PopupMenu respMeth,mode=1,bodyWidth= 60,popvalue="height",value= #"\"height;area\""
	CheckBox respPres,pos={292,276},size={111,24},proc=INTcheckProc,title="use constant\rsample pressure"
	CheckBox respPres,font="Georgia",fSize=11,value= 0
	CheckBox respTemp,pos={292,311},size={92,24},proc=INTcheckProc,title="use constant\rsample temp"
	CheckBox respTemp,font="Georgia",fSize=11,value= 0
	SetVariable respConst_press,pos={413,281},size={86,15},disable=1,proc=INTsetVarProc,title="mbar"
	SetVariable respConst_press,labelBack=(65535,65535,65535),font="Georgia"
	SetVariable respConst_press,fSize=11,limits={-inf,inf,0},bodyWidth= 50
	SetVariable respConst_temp,pos={406,317},size={92,15},disable=1,proc=INTsetVarProc,title="celsius"
	SetVariable respConst_temp,labelBack=(65535,65535,65535),font="Georgia",fSize=11
	SetVariable respConst_temp,limits={-inf,inf,0},bodyWidth= 50
	Button chromload,pos={19,18},size={100,20},proc=INTButtonProc,title="Load chroms"
	Button chromload,help={"Press button to load chromatograms (.itx) from a folder."}
	Button chromload,font="Arial",fColor=(65535,54607,32768)
	Button prepchroms,pos={188,18},size={90,20},proc=INTButtonProc,title="Prep chroms"
	Button prepchroms,help={"Press button to pre-process loaded chromatograms."}
	Button prepchroms,font="Arial",fColor=(65535,65534,49151)
	Button viewAStable,pos={551,319},size={90,20},proc=INTbuttonProc,title="view AS table"
	Button viewAStable,help={"Set active chromatograms to \"manual\" flag."}
	Button viewAStable,font="Arial",fColor=(32768,54615,65535)
	Button viewAll,pos={551,238},size={90,18},proc=INTbuttonProc,title="AS all"
	Button viewAll,help={"Sets active chromatograms to \"all\"."},font="Arial"
	Button viewAll,fColor=(49151,65535,65535)
	Button viewManual,pos={551,258},size={90,18},proc=INTbuttonProc,title="AS manual"
	Button viewManual,help={"Set active chromatograms to \"manual\" flag."}
	Button viewManual,font="Arial",fColor=(49151,65535,65535)
	Button viewBad,pos={551,278},size={90,18},proc=INTbuttonProc,title="AS bad"
	Button viewBad,help={"Sets active chromatograms to \"bad\" flag."},font="Arial"
	Button viewBad,fColor=(49151,65535,65535)
	Button viewSelpos,pos={551,298},size={90,18},proc=INTbuttonProc,title="AS by selpos"
	Button viewSelpos,help={"Sets active chromatograms to choosen selpos (ssv position)."}
	Button viewSelpos,font="Arial",fColor=(49151,65535,65535)
	TitleBox ASselected,pos={735,241},size={31,21},title="All"
	TitleBox ASselected,labelBack=(65535,65534,49151),font="Arial",fSize=13
	Button prepchromsCfg,pos={121,18},size={65,20},proc=INTButtonProc,title="Prep Cfg"
	Button prepchromsCfg,help={"Press button to pre-process loaded chromatograms."}
	Button prepchromsCfg,font="Arial",fColor=(65535,65533,32768)

	Button response,pos={413,250},size={115,20},proc=INTButtonProc,title="recalc resp"
	Button response,help={"Re-calculate the response of the active set."}
	Button response,font="Arial"
	Button selposTable,pos={18,358},size={90,30},proc=INTButtonProc,title="Edit Selpos\rTable"
	Button selposTable,help={"Edit the selpos table."},labelBack=(65535,54611,49151)
	Button selposTable,font="Arial",fColor=(49151,65535,65535)
	Button SaveStat,pos={210,358},size={90,30},proc=INTButtonProc,title="Save as\rStationery"
	Button SaveStat,labelBack=(65535,54611,49151),font="Arial"
	Button SaveStat,fColor=(65535,54611,49151)

	UpdateMolButtons()

	SetWindow IntegrationPanel, hookevents=0, hook=INTrefresh

End

Function INTrefresh( infoStr )
	String infoStr

	String event= StringByKey("EVENT",infoStr)
		
	if ( cmpstr(event, "activate") == 0)
		UpdateINTpanel( )
		UpdateMolButtons()
	endif
	
End


Function UpdateMolButtons()
	variable xstart = 600, ystart = 80, xsize = 100, ysize = 14
	variable yinc = 15, xinc = 80
	variable MAXmolsincolumn = 8
	
	String savedDF= GetDataFolder(1)
	setDataFolder root:DB
	
	wave /t DBmols = DB_mols
	wave DBchan = DB_chan
	NVAR chans = root:V_chans
	NVAR all = root:DB:V_allpeaks
	
	string IntWin = "IntegrationPanel"
	variable inc, ch, xloc, yloc, chinc
	string boxname
	
	wave active = DB_activePeak

	for (inc=0; inc<numpnts(DBmols); inc+= 1)
		boxname = "box_" + DBmols[inc]
		ch = DBchan[inc]
		xloc = xstart
		if (inc >= MAXmolsincolumn) 
			xloc += xinc
		endif
		yloc = ystart + mod(inc,MAXmolsincolumn) * yinc
		CheckBox $boxname,pos={xloc,yloc},size={xsize,ysize},proc=INTcheckProc,title=DBmols[inc]
		CheckBox $boxname,help={"When checked, this peak will be apart of the active peak list."}
		CheckBox $boxname,font="Georgia",fSize=12,value= active[inc],mode=0, win=$IntWin
	endfor

	if ( inc > 0 )
		xloc = xstart
		if (inc >= MAXmolsincolumn) 
			xloc += xinc
		endif
		yloc = ystart + mod(inc,MAXmolsincolumn) * yinc
		CheckBox box_ALL,pos={xloc,yloc},size={xsize,ysize},proc=INTcheckProc,title="All Peaks"
		CheckBox box_ALL,help={"When checked, all peaks will be apart of the active peak list."}
		CheckBox box_ALL,font="Georgia",fSize=12, fstyle=1, value= all,mode=0, win=$IntWin
	endif

	setDataFolder savedDF
end

// maintains global string lists of peak names in each channel.
Function UpdateMolLists()
	
	String savedDF= GetDataFolder(1)
	SetDataFolder root:DB

	NVAR V_chans = root:V_chans
	wave /t mols = DB_mols
	wave chans = DB_chan
	variable ch, inc
	string com
	
	for (ch=1; ch<=V_chans; ch+= 1)
		sprintf com, "string /g S_molLst%d =\"\"", ch
		execute com
		for (inc=0; inc<numpnts(mols); inc+=1)
			if ( chans[inc] == ch )
				sprintf com "S_molLst%d += \"%s;\"", ch, mols[inc]
				execute com
			endif
		endfor
	endfor

	SetDataFolder savedDF

end

Function INTButtonProc(ctrlName) : ButtonControl
	String ctrlName

	strswitch ( ctrlName )
		case "chromload":
			ChromLoader()
			Button prepchroms disable=0
			break
			
		case "prepchromsCfg":
			PrepConfigTable()
			break
			
		case "prepchroms":
			PrepareChroms()
			Button prepchroms disable=2
			UpdateINTpanel()
			break
			
		case "addmol":
			execute "DBaddMol()"
			break
		
		case "delmol":
			execute "DBdelMol()"
			break
			
		case "findret":
			FindRetAS()
			break
		
		case "findedges":
			FindEdgesAS()
			break
			
		case "integrate":
			IntegrateAS()
			ResponseAS()
			break
		
		case "response":
			ResponseAS()
			break
			
		case "doall":
			FindRetAS()
			FindEdgesAS()
			IntegrateAS()
			ResponseAS()
			break
			
		case "DBtable":
			execute "SortDB()"
			execute "INTdatabasePanel2()"
			execute "INTdatabasePanel1()"
			break
		
		case "selposTable":
			SelposTable()
			break
			
		case "viewAll":
			SetASchroms(1)
			UpdateINTpanel()
			break
			
		case "viewManual":
			SetASchroms(2)
			UpdateINTpanel()
			break
			
		case "viewBad":
			SetASchroms(3)
			UpdateINTpanel()
			break
			
		case "viewSelpos":
			SetASusingSelpos()
			UpdateINTpanel()
			break

		case "viewAStable":
			ASviewTable()
			break
			
		case "SaveStat":
			ConvertToStationary()
			break
							
	endswitch
		
End

Function INTPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	wave respMeth = root:DB:DB_respMeth

	NVAR currMolRow = root:DB:V_currMolRow
	
	strswitch( ctrlName )
		case "respMeth":
			respMeth[currMolRow] = popNum-1
			break
	endswitch

End

Proc DBaddMol(mol, ch)
	string mol=""
	variable ch=NumMakeOrDefault("root:DB:V_currCh", 1)
	prompt mol, "Molecule Name"
	prompt ch, "Channel", popup, ListNLong(root:V_chans, ";")
	
	silent 1
	
	if (cmpstr(CleanupName(mol, 0), mol) != 0)
		abort "Bad peak name!"
	endif
	
	String savedDF= GetDataFolder(1)
	setDataFolder root:DB

	S_currMol = mol
	V_currCh = ch
	variable inc, pt

	do
		if (cmpstr(DB_mols[inc],mol) == 0)
			abort "ABORTED:  This peak is already in the database."
		endif
		inc += 1
	while (inc < numpnts(DB_mols))

	insertpoints numpnts(DB_mols), 1, DB_respMeth, DB_respPmeth, DB_respTmeth, DB_respPconst, DB_respTconst, DB_normMeth, DB_normSmooth, DB_normFirst, DB_normLast
	insertpoints numpnts(DB_mols), 1, DB_mols, DB_chan, DB_meth, DB_methParam1, DB_edgePoints, DB_peakStart, DB_peakStop, DB_expStart, DB_expStop, DB_activePeak, DB_calval, DB_manERR
	pt = numpnts(DB_mols)-1
	DB_mols[pt] = mol
	DB_chan[pt] = ch
	DB_meth[pt] = 0
	DB_methParam1[pt] = 0
	DB_edgePoints[pt] = 4
	DB_peakStart[pt] = mol + "_Start"
	DB_peakStop[pt] = mol + "_Stop"
	DB_expStart[pt] = 10
	DB_expStop[pt] = 20
	DB_activePeak[pt] = 0
	DB_respMeth[pt] = 0
	DB_respPmeth[pt] = 0
	DB_respTmeth[pt] = 0
	DB_respPconst[pt] = 1000
	DB_respTconst[pt] = 30
	DB_normMeth[pt] = 1
	DB_normSmooth[pt] = 3
	DB_normFirst[pt] = 0
	DB_normLast[pt] = -1
	DB_calval[pt] = 1
	DB_manERR[pt] = 0
	
	SortDB()
	
	V_currMolRow = returnMolDBrow(mol)

	V_currCh = DB_chan[V_currMolRow]
	V_currMeth = DB_meth[V_currMolRow]
	S_currMol = DB_mols[V_currMolRow]
	V_currExp1 = DB_expStart[V_currMolRow]
	V_currExp2 = DB_expStop[V_currMolRow]
	
	ListBox mols,selRow= V_currMolRow
	ListBox meth,selRow= DB_meth[V_currMolRow]

	UpdateINTpanel()
		
	UpdateMolLists()
	UpdateMolButtons()
	
	setDataFolder savedDF
		
end

Proc SortDB()

	Silent 1
	
	String savedDF= GetDataFolder(1)
	setDataFolder root:DB

	sort /A {DB_chan,DB_expStart} DB_mols, DB_chan, DB_meth, DB_methParam1, DB_edgePoints, DB_peakStart, DB_peakStop, DB_expStart, DB_expStop, DB_activePeak, DB_respMeth, DB_respPmeth, DB_respTmeth, DB_respPconst, DB_respTconst, DB_normMeth, DB_normSmooth, DB_normFirst, DB_normLast, DB_calval, DB_manERR
	DBupdatePoints()

	setDataFolder savedDF

end
	
// creates text waves with start and stop point names (ie F11_Start and F11_Stop)
function DBupdatePoints()

	String savedDF= GetDataFolder(1)
	SetDataFolder root:DB
	
	make /t/o/n=0 points1, points2

	NVAR V_chans = root:V_chans
	wave /t mols = DB_mols
	wave chans = DB_chan
	variable ch, inc
	string com
	
	for (ch=1; ch<=V_chans; ch+= 1)
		sprintf com, "make /t/o/n=0 points%d", ch
		execute com
		wave /t pntwv = $"points"+num2str(ch)
		for (inc=0; inc<numpnts(mols); inc+= 1)
			if (chans[inc] == ch )
				insertpoints numpnts(pntwv), 2, pntwv
				pntwv[numpnts(pntwv) - 2] = mols[inc] + "_Start"
				pntwv[numpnts(pntwv) - 1] = mols[inc] + "_Stop"
			endif
		endfor
	endfor
	
	SetDataFolder savedDF
end

Proc DBdelMol(mol)
	string mol=StrMakeOrDefault("root:DB:S_currMol", "")
	prompt mol, "Molecule Name", popup, WaveToList("root:DB:DB_mols", ";")

	silent 1
	if (cmpstr(mol, "_none_") == 0)
		abort
	endif

	String savedDF= GetDataFolder(1)
	setDataFolder root:DB
	S_currMol = mol
	
	variable inc=0, loc
	
	loc = returnMolDBrow(mol)
	
	deletepoints loc, 1, DB_mols, DB_chan, DB_meth, DB_methParam1, DB_edgePoints, DB_peakStart, DB_peakStop, DB_expStart, DB_expStop, DB_activePeak
	deletepoints loc, 1, DB_respMeth, DB_respPmeth, DB_respTmeth, DB_respPconst, DB_respTconst, DB_normMeth, DB_normSmooth, DB_normFirst, DB_normLast, DB_calval, DB_manERR

	S_currMol = DB_mols[loc]
	V_currMolRow = returnMolDBrow(S_currMol)

	V_currCh = DB_chan[V_currMolRow]
	V_currMeth = DB_meth[V_currMolRow]
	V_currExp1 = DB_expStart[V_currMolRow]
	V_currExp2 = DB_expStop[V_currMolRow]
	ListBox mols,selRow= V_currMolRow
	ListBox meth,selRow= DB_meth[V_currMolRow]
	
	setDataFolder savedDF
	
	DBupdatePoints()
	
	CheckBox $"box_"+mol, disable=1
	UpdateMolButtons()
	UpdateMolLists()
	
	DeletePeakResWaves( mol )

end


Function INTlistBoxProc(ctrlName,row,col,event) : ListBoxControl
	String ctrlName
	Variable row
	Variable col
	Variable event	//1=mouse down, 2=up, 3=dbl click, 4=cell select with mouse or keys
					//5=cell select with shift key, 6=begin edit, 7=end
					
	wave /t DB_mols = root:DB:DB_mols
	wave DB_meth = root:DB:DB_meth
	wave DB_chan = root:DB:DB_chan
	wave DB_expStart = root:DB:DB_expStart
	wave DB_expStop = root:DB:DB_expStop
	wave /t DB_peakStart = root:DB:DB_peakStart
	wave /t DB_peakStop = root:DB:DB_peakStop
	wave DBactive = root:DB:DB_activePeak
	
	NVAR V_currCh = root:DB:V_currCh
	NVAR V_currMolRow = root:DB:V_currMolRow
	NVAR V_currMeth = root:DB:V_currMeth
	NVAR V_currExp1 = root:DB:V_currExp1
	NVAR V_currExp2 = root:DB:V_currExp2
	NVAR all = root:DB:V_allpeaks
	SVAR S_currMol = root:DB:S_currMol
	
	strswitch (ctrlName)
	case "mols":
		if (event == 2)
			
			S_currMol = DB_mols[row]
			V_currMeth = DB_meth[row]
			V_currExp1 = DB_expStart[row]
			V_currExp2 = DB_expStop[row]
			all = 0
			
			SetDBvars(S_currMol)
						
			UpdateINTpanel()
			UpdateMolButtons()
		endif
		break
		
	case "meth":
		wave methparam1 = root:DB:DB_methParam1
		if (event == 2)
			DB_meth[V_currMolRow] = row
			if ( row == 0 )
				CheckBox edgeParam1, disable=0, value = methparam1[V_currMolRow]
			else
				CheckBox edgeParam1, disable=1
			endif
			if ( row == 4 )	// gauss fit selected
				execute "GaussFitTable(\"" + S_currMol + "\")"
				GaussFit_InitGuess()
			endif
		endif
		break
		
	case "PeakStart":
		wave /t pntWv = $"root:DB:points" + num2str(V_currCh)
		if (event == 4)
			DB_peakStart[V_currMolRow] = pntWv[row]
		endif
		break

	case "PeakStop":
		wave /t pntWv = $"root:DB:points" + num2str(V_currCh)
		if (event == 4)
			DB_peakStop[V_currMolRow] = pntWv[row]
		endif
		break
	
	endswitch

	return 0
End

// function updates pull down menus and checkboxs on the Integration Panel
Function UpdateINTpanel()

	if (exists("root:selpos") == 0)
		make /n=0 root:selpos
	endif
	if (exists("root:AS:CH1_AS") == 0)
		make /n=0 root:AS:CH1_AS
	endif

	wave selpos = root:selpos
	wave /t DB_mols = root:DB:DB_mols
	wave DB_meth = root:DB:DB_meth
	wave DB_methParam1 = root:DB:DB_methParam1
	wave DB_edgePoints = root:DB:DB_edgePoints
	wave DB_chan = root:DB:DB_chan
	wave DB_expStart = root:DB:DB_expStart
	wave DB_expStop = root:DB:DB_expStop
	wave /t DB_peakStart = root:DB:DB_peakStart
	wave /t DB_peakStop = root:DB:DB_peakStop
	wave AS = root:AS:CH1_AS

	wave respMeth = root:DB:DB_respMeth
	wave pmeth = root:DB:DB_respPmeth
	wave tmeth = root:DB:DB_respTmeth
	wave pconst = root:DB:DB_respPconst
	wave tconst = root:DB:DB_respTconst	
	
	NVAR ASsel = root:V_ASselect
	NVAR V_currCh = root:DB:V_currCh
	NVAR V_currMolRow = root:DB:V_currMolRow
	NVAR V_currMeth = root:DB:V_currMeth
	NVAR V_currExp1 = root:DB:V_currExp1
	NVAR V_currExp2 = root:DB:V_currExp2
	SVAR S_currMol = root:DB:S_currMol

	V_currExp1 = DB_expStart[V_currMolRow]
	V_currExp2 = DB_expStop[V_currMolRow]

	string pntStr
	variable pntrow

	ValDisplay numchans,value= #"root:V_chans"
	ValDisplay numchroms value=returnMAXchromNum(1)-returnMINchromNum(1)+1
	
	pntrow = Max(0, DB_meth[V_currMolRow]-3)
	ListBox meth,selRow= DB_meth[V_currMolRow], row = pntrow
	pntrow = Max(0, V_currMolRow-6)
	ListBox mols,frame=4,listWave=root:DB:DB_mols,mode= 2,selRow=V_currMolRow, row=pntrow
	
	if ( numpnts(DB_mols) == 0 )
		return 0
	endif
	
	// peak edge start and stop points
	pntStr = "root:DB:points" + num2str(V_currCh)
	pntrow = returnPointsLoc($pntStr, DB_peakStart[V_currMolRow])
	ListBox PeakStart,listWave=$pntStr,selRow = pntrow
	ListBox PeakStart row = pntrow
	if ( pntrow != 0 )
		ListBox PeakStart row=pntrow-1
	endif

	pntrow = returnPointsLoc($pntStr, DB_peakStop[V_currMolRow])
	ListBox PeakStop,listWave=$pntStr,selRow = pntrow
	ListBox PeakStop row=pntrow
	if ( pntrow != 0 )
		ListBox PeakStop row=pntrow-1
	endif
	
	//edge method parameters panel	
	if ( DB_meth[V_currMolRow] == 0 )
		CheckBox edgeParam1, disable=0, value = DB_methParam1[V_currMolRow]
	else
		CheckBox edgeParam1, disable=1
	endif
	SetVariable edgeAvg, value= DB_edgePoints[V_currMolRow]
	
	// response method panel
	PopupMenu respMeth,mode=respMeth[V_currMolRow]+1
	if ( pmeth[V_currMolRow] == 0 )
		CheckBox respPres,value= 0
		SetVariable respConst_press disable=1
	else
		CheckBox respPres,value= 1
		SetVariable respConst_press disable=0
		SetVariable respConst_press,value= pconst[V_currMolRow]
	endif
	if ( tmeth[V_currMolRow] == 0 )
		CheckBox respTemp,value= 0
		SetVariable respConst_temp disable=1
	else
		CheckBox respTemp,value= 1
		SetVariable respConst_temp disable=0
		SetVariable respConst_temp,value= tconst[V_currMolRow]
	endif
	
	// AS selected text
	if (ASsel == 1)
		TitleBox ASselected,title="All"
	elseif (ASsel == 2)
		TitleBox ASselected,title="Manual"
	elseif (ASsel == 3)
		TitleBox ASselected,title="Bad"
	elseif (ASsel == 4)
		TitleBox ASselected,title="Selpos = " + num2str(selpos[ReturnResRowNumber( 1, AS[0] )])
	elseif (ASsel == 5)
		TitleBox ASselected,title="Selpos ++"
	endif

end

// Retruns the points wave location
Function returnPointsLoc(pntWv, pntval)
	wave /t pntWv
	string pntval
	
	variable inc, loc
	do
		if ( cmpstr(pntWv[inc],pntval) == 0 )
			loc = inc
			break
		endif
		inc += 1
	while( inc < numpnts(pntWv))
	
	return loc
	
end

Function INTsetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	String savedDF= GetDataFolder(1)
	SetDataFolder root:DB

	NVAR V_currMolRow = V_currMolRow
	
	wave DB_expStart = DB_expStart
	wave DB_expStop = DB_expStop
	wave Pconst = root:DB:DB_respPconst
	wave Tconst = root:DB:DB_respTconst	
	wave edgePoints = root:DB:DB_edgePoints
	
	strswitch( ctrlName )
		case "InitialStart":
			DB_expStart[V_currMolRow] = varNum
			break
			
		case "InitialStop":
			DB_expStop[V_currMolRow] = varNum
			break
			
		case "edgeAvg":
			edgePoints[V_currMolRow] = varNum
			break
			
		case "respConst_press":
			pconst[V_currMolRow] = varNum
			break
			
		case "respConst_temp":
			tconst[V_currMolRow] = varNum
			break
		
	endswitch
	
	SetDataFolder savedDF

End

Function INTcheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR all = root:DB:V_allpeaks
	NVAR currDBrow = root:DB:V_currMolRow
	
	wave active = root:DB:DB_activePeak
	wave pmeth = root:DB:DB_respPmeth
	wave tmeth = root:DB:DB_respTmeth
	
	variable row
	string mol
	
	strswitch( ctrlName )
		case "box_All":
			active = checked
			all = checked
			UpdateMolButtons()
			break
			
		case "respPres":
			pmeth[currDBrow] = checked
			UpdateINTpanel()
			break
			
		case "respTemp":
			tmeth[currDBrow] = checked
			UpdateINTpanel()
			break
			
		default:		// used for all of the specific peak check boxes
			mol = ctrlName[4,20]
			row = returnMolDBrow(mol)
			active[row] = checked
			break
	endswitch
	
End

Function INTedgeParamCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR currMolRow = root:DB:V_currMolRow

	strswitch( ctrlName )
		case "edgeParam1":
			wave methparam1 = root:DB:DB_methParam1
			methparam1[currMolRow] = checked
			break
			
	endswitch

End

// Creates at Selpos Table that associates position with cals or airs.
function SelposTable()

	if (exists("root:DB:V_shortLst") == 0)
		Variable /G root:DB:V_shortLst = 0
	endif
	NVAR shortLst = root:DB:V_shortLst

	string selpos = "root:selpos"
	string SelposVal_str = "root:DB:SelposVal"
	string SelposText_str = "root:DB:SelposText"
	string SelposExp_str = "root:DB:SelposExport"
	variable i
	string tbl = "SSVtable"

	if (exists(selpos) == 1)
		if (( numpnts($selpos) > 0 ) || (exists(SelposVal_str) == 1 ))
			shortLst = 1
			string sellst = SelposLst( 1 )
			shortLst = 0
			variable n = ItemsInList(sellst)
		else
			abort "To correctly create a Selpos Table, first load some chromatograms and then re-run this function."
		endif
	else
		if (exists(SelposVal_str) == 0 )
			abort "To correctly create a Selpos Table, first load some chromatograms and then re-run this function."
		endif
	endif	

	// make waves if they do not exist	
	if (exists(SelposVal_str) == 0 )
		make /n=(n) $SelposVal_Str
		wave SelposVal = $SelposVal_str
		for (i=0; i<n; i+= 1)
			SelposVal[i] = str2num(StringFromList(i, sellst))
		endfor
	else
		wave SelposVal = $SelposVal_str
	endif

	if (exists(SelposExp_str) == 0 )
		make /n=(n) $SelposExp_str = 1
	endif
	wave SelposExp = $SelposExp_str

	if (exists(SelposText_str) == 0 )
		make /t/n=(n) $SelposText_Str = "edit me"
	endif
	wave /T SelposText = $SelposText_str

	DoWindow /K $tbl
	Edit/K=1/W=(40,59,411,422) SelposText,SelposVal,SelposExp as "Selpos Table"
	ModifyTable style(SelposText)=1,style(SelposVal)=1,style(SelposExp)=1,rgb(SelposVal)=(0,0,65535),rgb(SelposExp)=(65535,0,0)
	DoWindow /C $tbl
	
	if ( n != numpnts(SelposVal) && numpnts($selpos) > 0 )
		DoUpdate
		abort "The number of Selpos positions is different than defined in the Selpos Table.  Edit the Selpos table to reflect the positions in the Selpos wave."
	endif
	
end