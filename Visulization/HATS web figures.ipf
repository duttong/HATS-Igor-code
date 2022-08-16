#pragma rtGlobals=1		// Use modern global access method.
#include <Image Contour Slicing>

Menu "Web"
	"Update CATS Web Figures", UpdateWebPlots_CATS(); SyncFigures()
	"-"
	"F11 Figures", F11figs(); SyncFigures()
	"F12 Figures", F12figs(); SyncFigures()
	"F113 Figures", F113figs(); SyncFigures()
	"SF6 Figures", SF6figs(); SyncFigures()
	"N2O Figures", N2Ofigs(); SyncFigures()
	"CCl4 Figures", CCl4figs(); SyncFigures()
	"Update All Combo Web Figs", UpdateAllWebFigs()
	"-"
	"HATS Datafigures"
	"-"
	"Sync Figures with website", SyncFigures()
end

strconstant userpath = "Macintosh HD:Users:gdutton:data:"

Function UpdateWebPlots_CATS()
	string sta, slst = "brw;sum;nwr;mlo;smo;spo"
	string mol, mlst = "N2O;SF6;H1211;F12;F11;F113;CHCl3;MC;CCl4;CH3Cl;HCFC22;HCFC142b;"
	Variable i, j
	
	for(i=0; i<ItemsInList(mlst); i+=1)
		mol = StringFromList(i, mlst)
		GlobalWebPlot(mol=mol, prefix="insitu", insts="CATS")
		for(j=0; j<ItemsInList(slst); j+=1)
			sta = StringFromList(j, slst)
			StationWebPlot_CATS(sta, mol)
		endfor
	endfor
	
End

Function StationWebPlot_CATS(sta, mol) 
	String sta, mol

	sta = LowerStr(sta)
	mol = LowerStr(mol)
	
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:month:
	
	String win = "StationPlot", com
	String s, slst = "brw;sum;nwr;mlo;smo;spo"
	Variable i
	
	DoWindow /k $win
	Display /W=(898,495,1543,895)/K=1
	DoWindow /c $win
	for(i=0; i<ItemsInList(slst); i+=1)
		s = StringFromList(i, slst)
		if (exists(s+"_" + mol) == 1)
			wave loc = $s + "_" + mol
			wave ttt = $s + "_time"
			AppendToGraph loc vs ttt
		endif
	endfor
	ModifyGraph rgb=(65535,49157,16385)
	string SSS = sta + "_" + mol 
	if ( exists(SSS) == 0 )
		SetDataFolder fldrSav0
		return 0
	endif
	wave loc = $SSS
	wave ttt = $sta + "_time"
	wave sd = $sta + "_" + mol + "_sd"
	AppendToGraph loc vs ttt
	ModifyGraph rgb($SSS#1)=(1,4,52428)
	ModifyGraph mode($SSS#1)=4
//	ErrorBars $SSS#1 Y,wave=(sd,sd)
	
	SetDataFolder fldrSav0
	
	ModifyGraph margin(left)=75,margin(bottom)=75,margin(top)=30,margin(right)=20,gFont="Helvetica"
	ModifyGraph gfSize=16,gmSize=2,width=600,height=300, marker=19

	ModifyGraph mode($SSS#1)=4, marker($SSS#1)=8

	ModifyGraph lSize=3
	ModifyGraph msize=3
	ModifyGraph grid=1
	ModifyGraph mirror=2
	ModifyGraph font="Helvetica"
	ModifyGraph lblMargin(left)=3,lblMargin(bottom)=10
	ModifyGraph axThick=2
	ModifyGraph lblPos(left)=78
	ModifyGraph manTick(bottom)={2966457600,2,0,0,yr},manMinor(bottom)={1,50}
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,3,1,2,"Year",-17}
	
	Label left "\\f01" + FullMolName(mol)
	Label bottom "\\f01Time"

	SetAxis/A/N=1 left
	SetAxis/N=1 bottom 2966457600,date2secs(ReturnCurrentYear()+1, 1, 1)
	
	sprintf com, "\\Z16\\JL\\s(%s#1) %s \\s(%s) other \\f02in situ\\f00 stations", SSS, FullStationName(sta), s + "_" + mol
	Legend/C/N=legend/J/F=0/A=LT/X=-0.91/Y=-9.00 com

	TextBox/C/N=NOAA/F=0/A=LB/X=-4.18/Y=-23.00 "\\F'Helvetica'\\Z11NOAA/GML in situ halocarbons program\r\\Z10" + date()[5,50]
//	TextBox/C/N=NOAA/F=0/B=1/A=MC/X=-38.18/Y=-67.33 "\\JL\\F'Helvetica'\\Z11NOAA/GML Halocarbons and other \rAtmospheric Trace Species group"
	SetDrawLayer UserFront
	DrawPICT -0.128031393067364,1.09407960199005,0.4,0.4,noaa_logo_png
	
	NewPath /q/o Web_CATS, userpath + "CATS:web-GML:webdata:insitu:cats:conc"
	sprintf com, "SavePICT/O/P=Web_CATS/E=-5/B=72 as \"%s_%s_monthly.png\"", sta, LowerStr(mol)
	execute com	

End

Function GlobalWebPlot([insts, prefix, mol, errors])
	string insts, prefix, mol
	variable errors

	SVAR mollst = root:G_molLst
	SVAR Gmol = root:G_mol
	SVAR GinstList = root:global:S_InstList
	SVAR Gpre = root:global:S_prefix

	if ( ParamIsDefault(mol) )
		mol = Gmol
	endif
	if ( ParamIsDefault(insts) )
		insts = GinstList
	endif
	if ( ParamIsDefault(prefix) )
		prefix = Gpre
	endif
	if ( ParamIsDefault(errors) )
		errors = 0
	endif
	if ( ParamIsDefault(mol) || ParamIsDefault(insts) || ParamIsDefault(prefix))
		Prompt insts, "Select a set of instruments", popup, AllInsts
		Prompt mol, "Which gas?", popup, mollst
		Prompt prefix, "Name waves with the following prefix:"
		Prompt errors, "Plot error bars?", popup, "Yes;No"
		DoPrompt "Global Mean:", insts, mol, prefix, errors
		if (V_flag)
			return -1
		endif
	endif

	Global_Mean(prefix=prefix, insts=insts, mol=mol, offsets=2)

	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:global:
	
	string com
	string GG = prefix + "_global_" + mol
	string GGsd = prefix + "_global_" + mol + "_sd"
	string NH = prefix + "_NH_" + mol
	string NHsd = prefix + "_NH_" + mol + "_sd"
	string SH = prefix + "_SH_" + mol
	string SHsd = prefix + "_SH_" + mol + "_sd"
	string TTT = prefix + "_" + mol + "_date"
	string win = prefix + "_GlobalMeansWebPlot"
	
	
	DoWindow /k $win
	Display /W=(898,495,1543,895)/K=1
	DoWindow /c $win
	AppendToGraph $NH vs $TTT
	AppendToGraph $SH vs $TTT
	AppendToGraph $GG vs $TTT

	ModifyGraph margin(left)=75,margin(bottom)=75,margin(top)=30,margin(right)=20,gFont="Helvetica"
	ModifyGraph gfSize=16,gmSize=2,width=600,height=300
	ModifyGraph lSize($NH)=2,lSize($SH)=2,lSize($GG)=3
	ModifyGraph rgb($NH)=(1,4,52428),rgb($GG)=(0,0,0)
	ModifyGraph grid(left)=1,grid(bottom)=2
	ModifyGraph mirror=2
	ModifyGraph lblMargin(left)=3,lblMargin(bottom)=10
	ModifyGraph axThick=2
	ModifyGraph lblPos(left)=78
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,3,1,2,"Year",-17}
	if (cmpstr(mol, "SF6") == 0)
		ModifyGraph manTick(bottom)={3029529600,2,0,0,yr},manMinor(bottom)={1,50}
	else
		ModifyGraph manTick(bottom)={3029529600,5,0,0,yr},manMinor(bottom)={4,5}
	endif
	
	if (errors)
		ErrorBars $NH Y,wave=($NHsd, $NHsd)
		ErrorBars $SH Y,wave=($SHsd, $SHsd)
		ErrorBars $GG Y,wave=($GGsd, $GGsd)
	endif

	SetDataFolder fldrSav0

	Label left "\\f01" + FullMolName(mol)
	Label bottom "\\f01Time"
	SetAxis/A/N=1 left
	SetAxis/A/N=1 bottom
	
	SetAxis bottom *,date2secs(ReturnCurrentYear()+1,1,1)

	sprintf com, "\\s(%s) Northern hemisphere  \\s(%s) Global  \\s(%s) Southern hemisphere ", NH, GG, SH
	Legend/C/N=leg/J/F=0/S=3/A=RC/X=-0.36/Y=55.33 com
	
//	TextBox/C/N=NOAA/F=0/B=1/A=MC/X=-38.18/Y=-67.33 "\\JL\\F'Helvetica'\\Z11NOAA/GML Halocarbons and other \rAtmospheric Trace Species group"
	if (cmpstr(mol, "N2O") != 0 )
		TextBox/C/N=NOAA/F=0/A=LB/X=-4.18/Y=-23.00 "\\F'Helvetica'\\Z11NOAA/GML halocarbons program\r\\Z10" + date()[5,50]
	else
		TextBox/C/N=NOAA/F=0/A=LB/X=-4.18/Y=-23.00 "\\F'Helvetica'\\Z11NOAA/GML Global Monitoring Laboratory\r\\Z10" + date()[5,50]
	endif
	SetDrawLayer UserFront
	DrawPICT -.117,1.08,0.4,0.4,noaa_logo_png
	
	if ( cmpstr(prefix, "insitu") == 0 )
		NewPath /q/o Web_CATS, userpath + "CATS:web-GML:webdata:insitu:cats:conc:"
		Sprintf com, "SavePICT/O/P=Web_CATS/E=-5/B=72 as \"%s_global.png\"", LowerStr(mol)
	else
		NewPath /q/o Web_HATS, userpath + "CATS:web-GML:webdata:hats:combined"
		Sprintf com, "SavePICT/O/P=Web_HATS/E=-5/B=72 as \"%s_%s_global.png\"", LowerStr(prefix), LowerStr(mol)
	endif
	execute com	
	
	// GSD 160115
//	if (cmpstr(mol, "MC")==0)
//		NanRecentData("MC", date2secs(2013,12,31))
//	endif

End

Function AppendNOAALogo(txt1, [txt2])
	string txt1, txt2

	String txt
	txt = "\\F'Geneva'\\Z10" + txt1
	if ( ! ParamIsDefault(txt2) ) 
		txt += "\r\\Z09" + txt2
	endif
	
	ModifyGraph margin(bottom)=85

	TextBox/C/N=NOAA/F=0/A=LB/X=7.08/Y=1.77/E=2 txt
	SetDrawLayer UserFront
	SetDrawEnv xcoord= abs,ycoord= abs
	DrawPICT 7.28,458.16,0.4,0.4,noaa_logo_png

end

Function F12figs()

	NVAR plt = root:global:G_plot
	variable oldplt = plt
	plt = 1

	Global_Mean(prefix="HATS", insts="oldgc;rits;otto;cats", mol="F12")
	Global_Mean(prefix="oldGC", insts="oldgc", mol="F12")
	Global_Mean(prefix="RITS", insts="rits", mol="F12")
	Global_Mean(prefix="Otto", insts="otto", mol="F12")
	Global_Mean(prefix="CATS", insts="cats", mol="F12")

	F12programsFig()
	F12_HATS_Latfigure()
	GlobalWebPlot(prefix="HATS", insts="oldgc;rits;otto;cats", mol="F12")
	ContourLatbin("HATS", "F12")
	NewPath /q/o Web_HATS, userpath + "CATS:web-GML:webdata:hats:combined"
	SavePICT/O/P=Web_HATS/E=-5/B=72 as "hats_f12_contour.png"

	plt = oldplt
		
end

Function F12programsFig()

	string win = "F12_programs"
	SetDataFolder root:global:
	DoWindow /K $win
	Display /K=1/W=(879,87,1524,507) oldGC_Global_F12 vs oldGC_F12_date
	DoWindow /C $win
	AppendToGraph RITS_Global_F12 vs RITS_F12_date
	AppendToGraph Otto_Global_F12 vs Otto_F12_date
	AppendToGraph CATS_Global_F12 vs CATS_F12_date
	AppendToGraph HATS_Global_F12 vs HATS_F12_date
	ModifyGraph margin(left)=75,margin(bottom)=70,margin(top)=50,margin(right)=20,gFont="Helvetica"
	ModifyGraph gfSize=14,gmSize=2,width=600,height=300
	ModifyGraph lSize(oldGC_Global_F12)=5,lSize(RITS_Global_F12)=5,lSize(Otto_Global_F12)=5
	ModifyGraph lSize(CATS_Global_F12)=5,lSize(HATS_Global_F12)=2
	ModifyGraph lStyle(oldGC_Global_F12)=2,lStyle(RITS_Global_F12)=2
	ModifyGraph rgb(oldGC_Global_F12)=(0,65535,0),rgb(RITS_Global_F12)=(52428,52425,1)
	ModifyGraph rgb(Otto_Global_F12)=(32768,32770,65535),rgb(HATS_Global_F12)=(0,0,0)
	ModifyGraph grid(left)=1,grid(bottom)=2
	ModifyGraph mirror=2
	ModifyGraph font="Geneva"
	ModifyGraph lblMargin(bottom)=6
	ModifyGraph axThick=2
	ModifyGraph lblPos(left)=78
	ModifyGraph manTick(bottom)={2240611200,5,0,0,yr},manMinor(bottom)={0,50}
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,3,1,2,"Year",-17}
	Label left "\\f01Global Mean CFC-12 (ppt)"
	Label bottom "\\f01Time"
	SetAxis left 200,550
	SetAxis/A/N=1 bottom
	Legend/C/N=text0/J/F=0/X=-0.55/Y=-13.33
	AppendText "\\JR\\s(HATS_Global_F12) Combined Global mean \\s(oldgc_Global_F12) Original ECD flask program  \\s(otto_Global_F12) Current flask ECD program"
	AppendText "\\s(rits_Global_F12) RITS in situ program \\s(cats_Global_F12) CATS in situ program"
	TextBox/C/N=NOAA/F=0/B=1/A=MC/X=-38.18/Y=-67.33 "\\JL\\F'Helvetica'\\Z11NOAA/GML halocarbons program"
	TextBox/C/N=datebox/F=0/B=1/A=MC/X=-48.36/Y=-70.67 "\\JL\\F'Helvetica'\\Z10" + date()[5,50]
	SetDrawLayer UserFront
	DrawPICT -.117,1.08,0.4,0.4,noaa_logo_png
	
	SetAxis bottom 2240611200,date2secs(ReturnCurrentYear()+1,1,1)
	SetDataFolder root:
	
	NewPath /q/o Web_HATS, userpath + "CATS:web-GML:webdata:hats:combined"
	SavePICT/O/P=Web_HATS/E=-5/B=72 as "hats_f12_progs.png"

End

Function F12_HATS_Latfigure()

	String fldrSav0= GetDataFolder(1)
	String win = "HATS_F12_latwebfig"
	SetDataFolder root:global:
	DoWindow /k $win
	Display /K=1/W=(905,603,1550,1009) HATS_LatBan_F12[*][0] vs HATS_F12_date
	DoWindow /c $win
	AppendToGraph HATS_LatBan_F12[*][1] vs HATS_F12_date
	AppendToGraph HATS_LatBan_F12[*][2] vs HATS_F12_date
	AppendToGraph HATS_LatBan_F12[*][3] vs HATS_F12_date
	AppendToGraph HATS_LatBan_F12[*][4] vs HATS_F12_date
	AppendToGraph HATS_LatBan_F12[*][5] vs HATS_F12_date
	AppendToGraph HATS_LatBan_F12[*][6] vs HATS_F12_date
	SetDataFolder fldrSav0
	ModifyGraph margin(left)=75,margin(bottom)=70,margin(top)=36,margin(right)=20,gFont="Helvetica"
	ModifyGraph gfSize=14,gmSize=2,width=600,height=300
	ModifyGraph lSize=2
	ModifyGraph lStyle(HATS_LatBan_F12#4)=2,lStyle(HATS_LatBan_F12#5)=2,lStyle(HATS_LatBan_F12#6)=2
	ModifyGraph rgb(HATS_LatBan_F12#1)=(24576,24576,65535),rgb(HATS_LatBan_F12#2)=(3,52428,1)
	ModifyGraph rgb(HATS_LatBan_F12#3)=(4369,4369,4369),rgb(HATS_LatBan_F12#4)=(3,52428,1)
	ModifyGraph rgb(HATS_LatBan_F12#5)=(0,0,65535),rgb(HATS_LatBan_F12#6)=(52428,1,1)
	ModifyGraph grid(left)=1,grid(bottom)=2
	ModifyGraph mirror=2
	ModifyGraph font="Geneva"
	ModifyGraph lblMargin(bottom)=6
	ModifyGraph axThick=2
	ModifyGraph lblPos(left)=78
	ModifyGraph manTick(bottom)={2240611200,5,0,0,yr},manMinor(bottom)={0,50}
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,3,1,2,"Year",-17}
	Label left "\\f01CFC-12 (ppt)"
	Label bottom "\\f01Time"
	SetAxis/A/N=1 left
	Legend/C/N=legd/J/X=3.27/Y=54.00 "\\Z16\\s(HATS_LatBAN_F12)60-90 N \r\\s(HATS_LatBAN_F12#1)45-60 N\r\\s(HATS_LatBAN_F12#2)20-45 N\r\\s(HATS_LatBAN_F12#3) 0-20 N"
	AppendText "\\s(HATS_LatBAN_F12#4) 0-20 S\r\\s(HATS_LatBAN_F12#5)20-45 S\r\\s(HATS_LatBAN_F12#6)45-90 S"
	TextBox/C/N=NOAA/F=0/B=1/A=MC/X=-38/Y=-66.33 "\\JL\\F'Helvetica'\\Z11NOAA Global Monitoring Laboratory"
	TextBox/C/N=datebox/F=0/B=1/A=MC/X=-48.91/Y=-70.33 "\\JL\\F'Helvetica'\\Z10" + date()[5,50]
	TextBox/C/N=text0/F=0/X=0.55/Y=-9.00 "Zonal Means"
	SetDrawLayer UserFront
	DrawPICT -.117,1.08,0.4,0.4,noaa_logo_png
	
	SetAxis bottom 2241820800,date2secs(ReturnCurrentYear()+1,1,1)
	SetDataFolder root:

	NewPath /q/o Web_HATS, userpath + "CATS:web-GML:webdata:hats:combined"
	SavePICT/O/P=Web_HATS/E=-5/B=72 as "hats_f12_zones.png"
EndMacro


Function F11figs()
	// added M3 MSD F11 data. 180713

	NVAR plt = root:global:G_plot
	variable oldplt = plt
	plt = 1

	Global_Mean(prefix="HATS", insts="oldgc;rits;otto;cats;MSD", mol="F11")
	Global_Mean(prefix="oldGC", insts="oldgc", mol="F11")
	Global_Mean(prefix="RITS", insts="rits", mol="F11")
	Global_Mean(prefix="Otto", insts="otto", mol="F11")
	Global_Mean(prefix="CATS", insts="cats", mol="F11")
	Global_Mean(prefix="M3", insts="MSD", mol="F11")

	F11programsFig()
	F11_HATS_Latfigure()
	GlobalWebPlot(prefix="HATS", insts="oldgc;rits;otto;cats;msd", mol="F11")
	ContourLatbin("HATS", "F11")
	NewPath /q/o Web_HATS, userpath + "CATS:web-GML:webdata:hats:combined"
	SavePICT/O/P=Web_HATS/E=-5/B=72 as "hats_f11_contour.png"

	plt = oldplt
	
end

// added M3 data 180713
Function F11programsFig()

	string win = "F11_programs"
	SetDataFolder root:global:
	DoWindow /K $win
	Display /W=(816,73,1511,507)/K=1  oldGC_Global_F11 vs oldGC_F11_date
	DoWindow /C $win
	AppendToGraph RITS_Global_F11 vs RITS_F11_date
	AppendToGraph Otto_Global_F11 vs Otto_F11_date
	AppendToGraph CATS_Global_F11 vs CATS_F11_date
	AppendToGraph HATS_Global_F11 vs HATS_F11_date
	AppendToGraph M3_Global_F11 vs M3_F11_date
	ModifyGraph margin(left)=75,margin(bottom)=70,margin(top)=64,margin(right)=20,gFont="Helvetica"
	ModifyGraph gfSize=14,gmSize=2,width=600,height=300
	ModifyGraph lSize(oldGC_Global_F11)=5,lSize(RITS_Global_F11)=5,lSize(Otto_Global_F11)=5
	ModifyGraph lSize(CATS_Global_F11)=5,lSize(HATS_Global_F11)=2,lSize(M3_Global_F11)=3
	ModifyGraph lStyle(oldGC_Global_F11)=2,lStyle(RITS_Global_F11)=2
	ModifyGraph rgb(oldGC_Global_F11)=(0,65535,0),rgb(RITS_Global_F11)=(52428,52425,1)
	ModifyGraph rgb(Otto_Global_F11)=(32768,32770,65535),rgb(HATS_Global_F11)=(0,0,0)
	ModifyGraph rgb(M3_Global_F11)=(1,52428,52428)
	ModifyGraph grid(left)=1,grid(bottom)=2
	ModifyGraph mirror=2
	ModifyGraph font="Geneva"
	ModifyGraph lblMargin(bottom)=6
	ModifyGraph axThick=2
	ModifyGraph lblPos(left)=78
	ModifyGraph manTick(bottom)={3029529600,5,0,0,yr},manMinor(bottom)={4,5}
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,3,1,2,"Year",-17}
	Label left "\\f01Global Mean CFC-11 (ppt)"
	Label bottom "\\f01Time"
	SetAxis/A/N=1 left
	SetAxis/N=1 bottom*,3629145600
	Legend/C/N=text0/J/F=0/X=-0.50/Y=-18.00 "\\JR\\s(HATS_Global_F11) \\f01Combined Global mean\\f00"
	AppendText "\\s(oldgc_Global_F11) Original flask ECD program  \\s(otto_Global_F11) Current flask ECD program \\s(M3_Global_F11) Current flask MSD program"
	AppendText "\\s(rits_Global_F11) RITS in situ program \\s(cats_Global_F11) CATS in situ program"
	TextBox/C/N=NOAA/F=0/B=1/A=MC/X=-38.5/Y=-66 "\\JL\\F'Helvetica'\\Z11NOAA/GML halocarbons program"
	TextBox/C/N=datebox/F=0/B=1/A=MC/X=-48.36/Y=-70.67 "\\JL\\F'Helvetica'\\Z10" + date()[5,50]
	SetDrawLayer UserFront
	DrawPICT -.117,1.08,0.4,0.4,noaa_logo_png
	
	SetAxis bottom *,date2secs(ReturnCurrentYear()+1,1,1)
	SetDataFolder root:
	
	NewPath /q/o Web_HATS, userpath + "CATS:web-GML:webdata:hats:combined"
	SavePICT/O/P=Web_HATS/E=-5/B=72 as "hats_f11_progs.png"
	
End

Function F11_HATS_Latfigure()

	String fldrSav0= GetDataFolder(1)
	String win = "HATS_F11_latwebfig"
	SetDataFolder root:global:
	DoWindow /k $win
	Display /K=1/W=(905,603,1550,1009) HATS_LatBan_F11[*][0] vs HATS_F11_date
	DoWindow /c $win
	AppendToGraph HATS_LatBan_F11[*][1] vs HATS_F11_date
	AppendToGraph HATS_LatBan_F11[*][2] vs HATS_F11_date
	AppendToGraph HATS_LatBan_F11[*][3] vs HATS_F11_date
	AppendToGraph HATS_LatBan_F11[*][4] vs HATS_F11_date
	AppendToGraph HATS_LatBan_F11[*][5] vs HATS_F11_date
	AppendToGraph HATS_LatBan_F11[*][6] vs HATS_F11_date
	SetDataFolder fldrSav0
	ModifyGraph margin(left)=75,margin(bottom)=70,margin(top)=36,margin(right)=20,gFont="Helvetica"
	ModifyGraph gfSize=14,gmSize=2,width=600,height=300
	ModifyGraph lSize=2
	ModifyGraph lStyle(HATS_LatBan_F11#4)=2,lStyle(HATS_LatBan_F11#5)=2,lStyle(HATS_LatBan_F11#6)=2
	ModifyGraph rgb(HATS_LatBan_F11#1)=(24576,24576,65535),rgb(HATS_LatBan_F11#2)=(3,52428,1)
	ModifyGraph rgb(HATS_LatBan_F11#3)=(4369,4369,4369),rgb(HATS_LatBan_F11#4)=(3,52428,1)
	ModifyGraph rgb(HATS_LatBan_F11#5)=(0,0,65535),rgb(HATS_LatBan_F11#6)=(52428,1,1)
	ModifyGraph grid(left)=1,grid(bottom)=2
	ModifyGraph mirror=2
	ModifyGraph font="Geneva"
	ModifyGraph lblMargin(bottom)=6
	ModifyGraph axThick=2
	ModifyGraph lblPos(left)=78
	ModifyGraph manTick(bottom)={2240611200,5,0,0,yr},manMinor(bottom)={4,50}
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,3,1,2,"Year",-17}
	Label left "\\f01CFC-11 (ppt)"
	Label bottom "\\f01Time"
	SetAxis/A/N=1 left
	Legend/C/N=legd/J/X=3.27/Y=54.00 "\\Z16\\s(HATS_LatBAN_F11)60-90 N \r\\s(HATS_LatBAN_F11#1)45-60 N\r\\s(HATS_LatBAN_F11#2)20-45 N\r\\s(HATS_LatBAN_F11#3) 0-20 N"
	AppendText "\\s(HATS_LatBAN_F11#4) 0-20 S\r\\s(HATS_LatBAN_F11#5)20-45 S\r\\s(HATS_LatBAN_F11#6)45-90 S"
	TextBox/C/N=NOAA/F=0/B=1/A=MC/X=-39/Y=-66 "\\JL\\F'Helvetica'\\Z11NOAA/GML halocarbons program"
	TextBox/C/N=datebox/F=0/B=1/A=MC/X=-48.91/Y=-70.33 "\\JL\\F'Helvetica'\\Z10" + date()[5,50]
	TextBox/C/N=text0/F=0/X=0.55/Y=-9.00 "Zonal Means"
	SetDrawLayer UserFront
	DrawPICT -.117,1.08,0.4,0.4,noaa_logo_png
	
	SetAxis bottom 2241820800,date2secs(ReturnCurrentYear()+1,1,1)
	SetDataFolder root:

	NewPath /q/o Web_HATS, userpath + "CATS:web-GML:webdata:hats:combined"
	SavePICT/O/P=Web_HATS/E=-5/B=72 as "hats_f11_zones.png"
EndMacro


Function f113figs()

	NVAR plt = root:global:G_plot
	variable oldplt = plt
	plt = 1

	Global_Mean(prefix="HATS", insts="otto;cats;msd", mol="F113", plot=1, offsets=2)
	Global_Mean(prefix="Otto", insts="otto", mol="F113", plot=1, offsets=2)
	Global_Mean(prefix="CATS", insts="cats", mol="F113", plot=1, offsets=2)
	Global_Mean(prefix="MSD", insts="msd", mol="F113", plot=1, offsets=2)

	F113programsFig()
	F113_HATS_Latfigure()
	GlobalWebPlot(prefix="HATS", insts="otto;cats;MSD", mol="F113")
	ContourLatbin("HATS", "f113")
	NewPath /q/o Web_HATS, userpath + "CATS:web-GML:webdata:hats:combined"
	SavePICT/O/P=Web_HATS/E=-5/B=72 as "hats_f113_contour.png"

	plt = oldplt
	
end

Function f113programsFig()

	string win = "f113_programs"
	SetDataFolder root:global:
	DoWindow /K $win
	Display /K=1/W=(879,87,1524,507) OTTO_Global_f113 vs otto_f113_date
	DoWindow /C $win
	AppendToGraph MSD_Global_f113 vs MSD_f113_date
	AppendToGraph CATS_Global_f113 vs CATS_f113_date
	AppendToGraph HATS_Global_f113 vs HATS_f113_date
	ModifyGraph margin(left)=75,margin(bottom)=70,margin(top)=50,margin(right)=20,gFont="Helvetica"
	ModifyGraph gfSize=14,gmSize=2,width=600,height=300
	ModifyGraph lSize(msd_Global_f113)=5,lSize(Otto_Global_f113)=5
	ModifyGraph lSize(CATS_Global_f113)=5,lSize(HATS_Global_f113)=2
	ModifyGraph lStyle(msd_Global_f113)=0
	ModifyGraph rgb(Otto_Global_f113)=(32768,32770,65535),rgb(HATS_Global_f113)=(0,0,0),rgb(MSD_Global_F113)=(1,52428,52428)
	ModifyGraph grid(left)=1,grid(bottom)=2
	ModifyGraph mirror=2
	ModifyGraph font="Geneva"
	ModifyGraph lblMargin(bottom)=6
	ModifyGraph axThick=2
	ModifyGraph lblPos(left)=78
	ModifyGraph manTick=0
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,3,1,2,"Year",-17}
	Label left "\\f01Global Mean CFC-113 (ppt)"
	Label bottom "\\f01Time"
	SetAxis/A/N=1 left
	SetAxis/A/N=1 bottom
	Legend/C/N=text0/J/F=0/X=-0.55/Y=-13.33
	AppendText "\\JR\\s(HATS_Global_f113) Combined Global mean  \\s(otto_Global_f113) Current flask ECD program \\s(msd_Global_f113) Current flask MSD program"
	AppendText "\\s(cats_Global_f113) CATS in situ program"
	TextBox/C/N=NOAA/F=0/B=1/A=MC/X=-38.18/Y=-67.33 "\\JL\\F'Helvetica'\\Z11NOAA/GML halocarbons program"
	TextBox/C/N=datebox/F=0/B=1/A=MC/X=-48.36/Y=-70.67 "\\JL\\F'Helvetica'\\Z10" + date()[5,50]
	SetDrawLayer UserFront
	DrawPICT -.117,1.08,0.4,0.4,noaa_logo_png
	
	SetAxis bottom date2secs(1990,1,1),date2secs(ReturnCurrentYear()+1,1,1)
	SetDataFolder root:
	
	NewPath /q/o Web_HATS, userpath + "CATS:web-GML:webdata:hats:combined"
	SavePICT/O/P=Web_HATS/E=-5/B=72 as "hats_f113_progs.png"
	
End

Function F113_HATS_Latfigure()

	String fldrSav0= GetDataFolder(1)
	String win = "HATS_f113_latwebfig"
	SetDataFolder root:global:
	DoWindow /k $win
	Display /K=1/W=(905,603,1550,1009) HATS_LatBan_f113[*][0] vs HATS_f113_date
	DoWindow /c $win
	AppendToGraph HATS_LatBan_f113[*][1] vs HATS_f113_date
	AppendToGraph HATS_LatBan_f113[*][2] vs HATS_f113_date
	AppendToGraph HATS_LatBan_f113[*][3] vs HATS_f113_date
	AppendToGraph HATS_LatBan_f113[*][4] vs HATS_f113_date
	AppendToGraph HATS_LatBan_f113[*][5] vs HATS_f113_date
	AppendToGraph HATS_LatBan_f113[*][6] vs HATS_f113_date
	SetDataFolder fldrSav0
	ModifyGraph margin(left)=75,margin(bottom)=70,margin(top)=36,margin(right)=20,gFont="Helvetica"
	ModifyGraph gfSize=14,gmSize=2,width=600,height=300
	ModifyGraph lSize=2
	ModifyGraph lStyle(HATS_LatBan_f113#4)=2,lStyle(HATS_LatBan_f113#5)=2,lStyle(HATS_LatBan_f113#6)=2
	ModifyGraph rgb(HATS_LatBan_f113#1)=(24576,24576,65535),rgb(HATS_LatBan_f113#2)=(3,52428,1)
	ModifyGraph rgb(HATS_LatBan_f113#3)=(4369,4369,4369),rgb(HATS_LatBan_f113#4)=(3,52428,1)
	ModifyGraph rgb(HATS_LatBan_f113#5)=(0,0,65535),rgb(HATS_LatBan_f113#6)=(52428,1,1)
	ModifyGraph grid(left)=1,grid(bottom)=2
	ModifyGraph mirror=2
	ModifyGraph font="Geneva"
	ModifyGraph lblMargin(bottom)=6
	ModifyGraph axThick=2
	ModifyGraph lblPos(left)=78
	ModifyGraph manTick(bottom)={2240611200,5,0,0,yr},manMinor(bottom)={0,50}
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,3,1,2,"Year",-17}
	Label left "\\f01CFC-113 (ppt)"
	Label bottom "\\f01Time"
	SetAxis/A/N=1 left
	Legend/C/N=legd/J/X=2.00/Y=4.33 "\\Z16\\s(HATS_LatBAN_f113)60-90 N \r\\s(HATS_LatBAN_f113#1)45-60 N\r\\s(HATS_LatBAN_f113#2)20-45 N\r\\s(HATS_LatBAN_f113#3) 0-20 N"
	AppendText "\\s(HATS_LatBAN_f113#4) 0-20 S\r\\s(HATS_LatBAN_f113#5)20-45 S\r\\s(HATS_LatBAN_f113#6)45-90 S"
	TextBox/C/N=NOAA/F=0/B=1/A=MC/X=-39/Y=-66 "\\JL\\F'Helvetica'\\Z11NOAA/GML halocarbons program"
	TextBox/C/N=datebox/F=0/B=1/A=MC/X=-48.91/Y=-70.33 "\\JL\\F'Helvetica'\\Z10" + date()[5,50]
	TextBox/C/N=text0/F=0/X=0.55/Y=-9.00 "Zonal Means"
	SetDrawLayer UserFront
	DrawPICT -.117,1.08,0.4,0.4,noaa_logo_png
	
	SetAxis bottom date2secs(1993,1,1),date2secs(ReturnCurrentYear()+1,1,1)
	SetDataFolder root:

	NewPath /q/o Web_HATS, userpath + "CATS:web-GML:webdata:hats:combined"
	SavePICT/O/P=Web_HATS/E=-5/B=72 as "hats_f113_zones.png"
EndMacro


Function SF6figs()

	NVAR plt = root:global:G_plot
	String /G root:S_sitesused = AllBKsitesOTTO
	variable oldplt = plt
	plt = 1
	Global_Mean(prefix="HATS", insts="otto;cats;ccgg", mol="SF6")
	Global_Mean(prefix="Otto", insts="otto", mol="SF6")
	Global_Mean(prefix="CATS", insts="cats", mol="SF6")
	Global_Mean(prefix="CCGG", insts="CCGG", mol="SF6")
	
	SF6programsFig()
	SF6_HATS_Latfigure()
//	GlobalWebPlot(prefix="HATS", insts="otto;cats", mol="SF6")
	SF6_GlobalMean_Fig()
	ContourLatbin("HATS", "SF6")
	NewPath /q/o Web_HATS, userpath + "CATS:web-GML:webdata:hats:combined"
	SavePICT/O/P=Web_HATS/E=-5/B=72 as "hats_sf6_contour.png"
	
	plt = oldplt

end

function SF6programsFig()

	string win = "SF6_programs"
	SetDataFolder root:global:
	DoWindow /K $win
	Display /K=1/W=(879,87,1524,507) 
	DoWindow /C $win
	AppendToGraph Otto_Global_SF6 vs Otto_SF6_date
	AppendToGraph CATS_Global_SF6 vs CATS_SF6_date
	AppendToGraph CCGG_Global_SF6 vs CCGG_SF6_date
	AppendToGraph HATS_Global_SF6 vs HATS_SF6_date
	ModifyGraph margin(left)=75,margin(bottom)=70,margin(top)=50,margin(right)=20,gFont="Helvetica"
	ModifyGraph gfSize=14,gmSize=2,width=600,height=300
	ModifyGraph lSize(Otto_Global_SF6)=5,lSize(CATS_Global_SF6)=5,lSize(CCGG_Global_SF6)=5
	ModifyGraph lSize(HATS_Global_SF6)=2
	ModifyGraph lStyle(CCGG_Global_SF6)=6
	ModifyGraph rgb(Otto_Global_SF6)=(32768,32770,65535),rgb(CCGG_Global_SF6)=(3,52428,1)
	ModifyGraph rgb(HATS_Global_SF6)=(0,0,0)
	ModifyGraph grid(left)=1,grid(bottom)=2
	ModifyGraph mirror=2
	ModifyGraph font="Geneva"
	ModifyGraph lblMargin(bottom)=6
	ModifyGraph axThick=2
	ModifyGraph lblPos(left)=78
	ModifyGraph manTick(bottom)={2966457600,2,0,0,yr},manMinor(bottom)={1,50}
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,3,1,2,"Year",-17}
	Label left "\\f01Global Mean SF\\B6\\M (ppt)"
	Label bottom "\\f01Time"
	SetAxis/A/N=1 left
	SetAxis/A/N=1 bottom
	TextBox/C/N=NOAA/F=0/B=1/A=MC/X=-38.18/Y=-67.33 "\\JL\\F'Helvetica'\\Z11NOAA/Global Monitoring Laboratory"
	TextBox/C/N=datebox/F=0/B=1/A=MC/X=-49/Y=-71 "\\JL\\F'Helvetica'\\Z10" + date()[5,50]
	Legend/C/N=text0/J/F=0/X=-0.55/Y=-14 "\\JR\\s(HATS_Global_SF6) Combined Global mean  \\s(otto_Global_SF6) Current flask ECD program"
	AppendText "\\s(CCGG_Global_SF6) CCGG_Global_SF6 \\s(cats_Global_SF6) CATS in situ program"
	SetDrawLayer UserFront
	DrawPICT -.117,1.08,0.4,0.4,noaa_logo_png
	
	SetAxis bottom *,date2secs(ReturnCurrentYear()+1,1,1)
	SetDataFolder root:
	
	NewPath /q/o Web_HATS, userpath + "CATS:web-GML:webdata:hats:combined"
	SavePICT/O/P=Web_HATS/E=-5/B=72 as "hats_sf6_progs.png"
End

Function SF6_HATS_Latfigure()

	String fldrSav0= GetDataFolder(1)
	String win = "HATS_SF6_latwebfig"
	SetDataFolder root:global:
	DoWindow /k $win
	Display /K=1/W=(905,603,1550,1009) HATS_LatBan_SF6[*][0] vs HATS_SF6_date
	DoWindow /c $win
	AppendToGraph HATS_LatBan_SF6[*][1] vs HATS_SF6_date
	AppendToGraph HATS_LatBan_SF6[*][2] vs HATS_SF6_date
	AppendToGraph HATS_LatBan_SF6[*][3] vs HATS_SF6_date
	AppendToGraph HATS_LatBan_SF6[*][4] vs HATS_SF6_date
	AppendToGraph HATS_LatBan_SF6[*][5] vs HATS_SF6_date
	AppendToGraph HATS_LatBan_SF6[*][6] vs HATS_SF6_date
	SetDataFolder fldrSav0
	ModifyGraph margin(left)=75,margin(bottom)=70,margin(top)=36,margin(right)=20,gFont="Helvetica"
	ModifyGraph gfSize=14,gmSize=2,width=600,height=300
	ModifyGraph lSize=2
	ModifyGraph lStyle(HATS_LatBan_SF6#4)=2,lStyle(HATS_LatBan_SF6#5)=2,lStyle(HATS_LatBan_SF6#6)=2
	ModifyGraph rgb(HATS_LatBan_SF6#1)=(24576,24576,65535),rgb(HATS_LatBan_SF6#2)=(3,52428,1)
	ModifyGraph rgb(HATS_LatBan_SF6#3)=(4369,4369,4369),rgb(HATS_LatBan_SF6#4)=(3,52428,1)
	ModifyGraph rgb(HATS_LatBan_SF6#5)=(0,0,65535),rgb(HATS_LatBan_SF6#6)=(52428,1,1)
	ModifyGraph grid(left)=1,grid(bottom)=2
	ModifyGraph mirror=2
	ModifyGraph font="Geneva"
	ModifyGraph lblMargin(bottom)=6
	ModifyGraph axThick=2
	ModifyGraph lblPos(left)=78
	ModifyGraph manTick(bottom)={2966457600,4,0,0,yr},manMinor(bottom)={1,50}
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,3,1,2,"Year",-17}
	Label left "\\f01SF\\B6\\M (ppt)"
	Label bottom "\\f01Time"
	SetAxis/A/N=1 left
	Legend/C/N=legd/J/X=3.27/Y=54.00 "\\Z16\\s(HATS_LatBAN_SF6)60-90 N \r\\s(HATS_LatBAN_SF6#1)45-60 N\r\\s(HATS_LatBAN_SF6#2)20-45 N\r\\s(HATS_LatBAN_SF6#3) 0-20 N"
	AppendText "\\s(HATS_LatBAN_SF6#4) 0-20 S\r\\s(HATS_LatBAN_SF6#5)20-45 S\r\\s(HATS_LatBAN_SF6#6)45-90 S"
	TextBox/C/N=NOAA/F=0/B=1/A=MC/X=-38/Y=-66.33 "\\JL\\F'Helvetica'\\Z11NOAA Global Monitoring Laboratory"
	TextBox/C/N=datebox/F=0/B=1/A=MC/X=-48.91/Y=-70.33 "\\JL\\F'Helvetica'\\Z10" + date()[5,50]
	TextBox/C/N=text0/F=0/X=0.55/Y=-9.00 "Zonal Means"
	SetDrawLayer UserFront
	DrawPICT -.117,1.08,0.4,0.4,noaa_logo_png
	
	SetAxis bottom 2840227200,date2secs(ReturnCurrentYear()+1,1,1)
	SetDataFolder root:

	NewPath /q/o Web_HATS, userpath + "CATS:web-GML:webdata:hats:combined"
	SavePICT/O/P=Web_HATS/E=-5/B=72 as "hats_sf6_zones.png"
EndMacro


Function N2Ofigs()

	NVAR plt = root:global:G_plot
	variable oldplt = plt
	plt = 1

	string instruments="oldgc;rits;cats;otto;ccgg"
	Global_Mean(prefix="HATS", insts=instruments, mol="N2O")
	Global_Mean(prefix="oldGC", insts="oldgc", mol="N2O")
	Global_Mean(prefix="RITS", insts="rits", mol="N2O")
	Global_Mean(prefix="Otto", insts="otto", mol="N2O")
	Global_Mean(prefix="CATS", insts="cats", mol="N2O")
	Global_Mean(prefix="CCGG", insts="CCGG", mol="N2O")

	N2OProgramsFig()	
	GlobalWebPlot(prefix="HATS", insts=instruments, mol="N2O")
	N2O_GlobalMean_Fig()
	N2O_HATS_Latfigure()
	ContourLatbin("HATS", "N2O")
	
	NewPath /q/o Web_HATS, userpath + "CATS:web-GML:webdata:hats:combined"
	SavePICT/O/P=Web_HATS/E=-5/B=72 as "hats_n2o_contour.png"

	plt = oldplt
	
end

function N2OProgramsFig()
	string win = "N2O_programs"
	SetDataFolder root:global:
	DoWindow /K $win
	Display /K=1/W=(879,87,1524,507) oldGC_Global_N2O vs oldGC_N2O_date
	DoWindow /C $win
	AppendToGraph RITS_Global_N2O vs RITS_N2O_date
	AppendToGraph Otto_Global_N2O vs Otto_N2O_date
	AppendToGraph CATS_Global_N2O vs CATS_N2O_date
	AppendToGraph CCGG_Global_N2O vs CCGG_N2O_date
	AppendToGraph HATS_Global_N2O vs HATS_N2O_date
	ModifyGraph margin(left)=75,margin(bottom)=70,margin(top)=58,margin(right)=20,gFont="Helvetica"
	ModifyGraph gfSize=14,gmSize=2,width=600,height=300
	ModifyGraph lSize(oldGC_Global_N2O)=5,lSize(RITS_Global_N2O)=5,lSize(Otto_Global_N2O)=5
	ModifyGraph lSize(CATS_Global_N2O)=5,lSize(CCGG_Global_N2O)=5,lSize(HATS_Global_N2O)=2
	ModifyGraph lStyle(oldGC_Global_N2O)=2,lStyle(RITS_Global_N2O)=2
	ModifyGraph rgb(oldGC_Global_N2O)=(3,52428,1),rgb(RITS_Global_N2O)=(65535,43690,0)
	ModifyGraph rgb(Otto_Global_N2O)=(32768,32770,65535),rgb(CCGG_Global_N2O)=(3,52428,1)
	ModifyGraph rgb(HATS_Global_N2O)=(0,0,0)
	ModifyGraph grid(left)=1,grid(bottom)=2
	ModifyGraph mirror=2
	ModifyGraph font="Geneva"
	ModifyGraph lblMargin(bottom)=6
	ModifyGraph axThick=2
	ModifyGraph lblPos(left)=78
	ModifyGraph manTick(bottom)={2240611200,5,0,0,yr},manMinor(bottom)={0,50}
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,3,1,2,"Year",-17}
	Label left "\\f01Global Mean N\\B2\\MO (ppb)"
	Label bottom "\\f01Time"
	SetAxis/A/N=1 left

	TextBox/C/N=NOAA/F=0/B=1/A=MC/X=-38/Y=-66.33 "\\JL\\F'Helvetica'\\Z11NOAA Global Monitoring Laboratory"
	Legend/C/N=text0/J/F=0/X=-0.55/Y=-18.33
	AppendText "\\JR\\s(HATS_Global_N2O) Combined Global mean \\s(oldgc_Global_N2O) Original flask ECD program  \\s(otto_Global_N2O) Current flask ECD program"
	AppendText "\\s(ccgg_global_n2o) Carbon Cycle Gas Group (CCGG) flask program\r\\s(rits_Global_N2O) RITS in situ program \\s(cats_Global_N2O) CATS in situ program"
	TextBox/C/N=datebox/F=0/B=1/A=MC/X=-48.91/Y=-70.33 "\\JL\\F'Helvetica'\\Z10" + date()[5,50]
	SetDrawLayer UserFront
	DrawPICT  -.117,1.08,0.4,0.4,noaa_logo_png
		
	SetAxis/A/N=1 bottom *,date2secs(ReturnCurrentYear()+1,1,1)
	SetDataFolder root:
	
	NewPath /q/o Web_HATS, userpath + "CATS:web-GML:webdata:hats:combined"
	SavePICT/O/P=Web_HATS/E=-5/B=72 as "hats_n2o_progs.png"
end

Function N2O_HATS_Latfigure()

	String fldrSav0= GetDataFolder(1)
	String win = "HATS_N2O_latwebfig"
	SetDataFolder root:global:
	DoWindow /k $win
	Display /K=1/W=(905,603,1550,1009) HATS_LatBan_N2O[*][0] vs HATS_N2O_date
	DoWindow /c $win
	AppendToGraph HATS_LatBan_N2O[*][1] vs HATS_N2O_date
	AppendToGraph HATS_LatBan_N2O[*][2] vs HATS_N2O_date
	AppendToGraph HATS_LatBan_N2O[*][3] vs HATS_N2O_date
	AppendToGraph HATS_LatBan_N2O[*][4] vs HATS_N2O_date
	AppendToGraph HATS_LatBan_N2O[*][5] vs HATS_N2O_date
	AppendToGraph HATS_LatBan_N2O[*][6] vs HATS_N2O_date
	SetDataFolder fldrSav0
	ModifyGraph margin(left)=75,margin(bottom)=70,margin(top)=36,margin(right)=20,gFont="Helvetica"
	ModifyGraph gfSize=16,gmSize=2,width=600,height=300
	ModifyGraph lSize=2
	ModifyGraph lStyle(HATS_LatBan_N2O#4)=2,lStyle(HATS_LatBan_N2O#5)=2,lStyle(HATS_LatBan_N2O#6)=2
	ModifyGraph rgb(HATS_LatBan_N2O#1)=(24576,24576,65535),rgb(HATS_LatBan_N2O#2)=(3,52428,1)
	ModifyGraph rgb(HATS_LatBan_N2O#3)=(4369,4369,4369),rgb(HATS_LatBan_N2O#4)=(3,52428,1)
	ModifyGraph rgb(HATS_LatBan_N2O#5)=(0,0,65535),rgb(HATS_LatBan_N2O#6)=(52428,1,1)
	ModifyGraph grid(left)=1,grid(bottom)=2
	ModifyGraph mirror=2
	ModifyGraph font="Geneva"
	ModifyGraph lblMargin(bottom)=6
	ModifyGraph axThick=2
	ModifyGraph lblPos(left)=78
	ModifyGraph manTick(bottom)={2240611200,5,0,0,yr},manMinor(bottom)={0,50}
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,3,1,2,"Year",-17}
	Label left "\\f01N\\B2\\MO (ppb)"
	Label bottom "\\f01Time"
	SetAxis/A/N=1 left
	Legend/C/N=legd/J/X=3.27/Y=54.00 "\\s(HATS_LatBAN_N2O)60-90 N \r\\s(HATS_LatBAN_N2O#1)45-60 N\r\\s(HATS_LatBAN_N2O#2)20-45 N\r\\s(HATS_LatBAN_N2O#3) 0-20 N"
	AppendText "\\s(HATS_LatBAN_N2O#4) 0-20 S\r\\s(HATS_LatBAN_N2O#5)20-45 S\r\\s(HATS_LatBAN_N2O#6)45-90 S"
	TextBox/C/N=NOAA/F=0/B=1/A=MC/X=-38/Y=-66.33 "\\JL\\F'Helvetica'\\Z11NOAA Global Monitoring Laboratory"
	TextBox/C/N=datebox/F=0/B=1/A=MC/X=-48.91/Y=-70.33 "\\JL\\F'Helvetica'\\Z10" + date()[5,50]
	TextBox/C/N=text0/F=0/X=0.55/Y=-9.00 "Zonal Means"
	SetDrawLayer UserFront
	DrawPICT -.117,1.08,0.4,0.4,noaa_logo_png
	
	SetAxis bottom *,date2secs(ReturnCurrentYear()+1,1,1)
	SetDataFolder root:

	NewPath /q/o Web_HATS, userpath + "CATS:web-GML:webdata:hats:combined"
	SavePICT/O/P=Web_HATS/E=-5/B=72 as "hats_n2o_zones.png"
EndMacro


function N2O_GlobalMean_Fig() 
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:global:

	String win = "n2o_globalmean", grate
	DoWindow /K $win
	Display /W=(279,82,923,507)/K=1  HATS_Global_N2O vs HATS_N2O_date
	DoWindow /C $win

	AppendToGraph HATS_Global_N2O vs HATS_N2O_date
	
	CurveFit/NTHR=0 line  HATS_Global_N2O /X=HATS_N2O_date /W=HATS_Global_N2O_sd /I=1 /D 
	Wave W_coef
	sprintf grate, "%0.2f", W_coef[1]*60*60*24*365

	SetDataFolder fldrSav0
	ModifyGraph margin(left)=75,margin(bottom)=70,margin(top)=43,margin(right)=20,gFont="Helvetica"
	ModifyGraph gfSize=14,gmSize=2
	ModifyGraph lSize(HATS_Global_N2O)=2,lSize(HATS_Global_N2O#1)=3,lSize(fit_HATS_Global_N2O)=2
	ModifyGraph rgb(HATS_Global_N2O)=(43690,43690,43690),rgb(HATS_Global_N2O#1)=(0,0,0)
	ModifyGraph grid(left)=1,grid(bottom)=2
	ModifyGraph mirror=2,width=600,height=300
	ModifyGraph font="Geneva"
	ModifyGraph lblMargin(bottom)=6
	ModifyGraph axThick=2
	ModifyGraph lblPos(left)=78
	ModifyGraph manTick(bottom)={2240611200,5,0,0,yr},manMinor(bottom)={0,50}
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,3,1,2,"Year",-17}
	Label left "\\f01Global Mean N\\B2\\MO (ppb)"
	Label bottom "\\f01Time"
	SetAxis/A/N=1 left
	ErrorBars/T=0.2/L=3 HATS_Global_N2O Y,wave=(:global:HATS_Global_N2O_sd,:global:HATS_Global_N2O_sd)
	TextBox/C/N=NOAA/F=0/B=1/A=MC/X=-38/Y=-66.33 "\\JL\\F'Helvetica'\\Z11NOAA Global Monitoring Laboratory"
	Legend/C/N=text0/J/F=0/X=-0.55/Y=-11.86 "\\s(HATS_Global_N2O#1) Global mean with 1-sigma uncertainty\r\\s(fit_HATS_Global_N2O) Linear fit:  " + grate + " ppb per year growth"
	
	SetAxis/N=1 bottom *, date2secs(ReturnCurrentYear()+1,1,1)
	TextBox/C/N=datebox/F=0/B=1/A=MC/X=-48.5/Y=-70.19 "\\JL\\F'Helvetica'\\Z10" + date()[5,50]
	
	SetDrawLayer UserFront
	DrawPICT -.117,1.08,0.4,0.4,noaa_logo_png
	
	NewPath /q/o Web_HATS, userpath + "CATS:web-GML:webdata:hats:combined"
	SavePICT/O/P=Web_HATS/E=-5/B=72 as "hats_n2o_globalmean.png"
	
	SetDataFolder root:
	
EndMacro

Window GlobalN2Ogrowthrate_web() : Graph
	PauseUpdate; Silent 1		// building window...
	DisplayGrowthRate("N2O","Global","CATS;OTTO;CCGG","GML",12,2)
	
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:global:
	Display /W=(352,66,1047,451)/K=1  GML_Global_N2O_gr vs GML_N2O_date
	DoWindow /K GlobalN2Ogrowthrate
	SetDataFolder fldrSav0
	ModifyGraph margin(left)=75,margin(bottom)=70,margin(top)=15,margin(right)=20,gFont="Helvetica"
	ModifyGraph gfSize=14,gmSize=2,width=600,height=300
	ModifyGraph marker=19
	ModifyGraph lSize=3
	ModifyGraph rgb=(1,39321,19939)
	ModifyGraph gaps=0
	ModifyGraph grid(left)=1,grid(bottom)=2
	ModifyGraph tick=3
	ModifyGraph mirror=2
	ModifyGraph font="Geneva"
	ModifyGraph lblMargin(bottom)=6
	ModifyGraph axThick=2
	ModifyGraph lblPos(left)=78
	ModifyGraph manTick(bottom)={2240611200,5,0,0,yr},manMinor(bottom)={0,50}
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,3,1,2,"Year",-17}
	Label left "\\f01N\\B2\\MO Growth Rate (ppb yr\\S-1\\M)"
	Label bottom "\\f01Time"
	SetAxis/A/N=1 left
	SetAxis/N=1 bottom 3029529600,date2secs(ReturnCurrentYear()+1, 1, 1)
	TextBox/C/N=NOAA/F=0/B=1/A=MC/X=-38.14/Y=-63.66 "\\JL\\F'Helvetica'\\Z11NOAA Global Monitoring Laboratory"
	TextBox/C/N=datebox/F=0/B=1/A=MC/X=-48.33/Y=-68.33 "\\JL\\F'Helvetica'\\Z10" + date()[5,50]
	SetDrawLayer UserFront
	DrawPICT -0.111295756593079,1.06142981592732,0.4,0.4,noaa_logo_png
	
	NewPath /q/o Web_HATS, userpath + "CATS:web-GML:webdata:hats:combined"
	SavePICT/O/P=Web_HATS/E=-5/B=72 as "GlobalN2Ogrowthrate.png"
	
	SetDataFolder root:
	SyncFigures()

EndMacro


function SF6_GlobalMean_Fig() 
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:global:

	String win = "SF6_globalmean", grate
	DoWindow /K $win
	Display /W=(279,82,923,507)/K=1  HATS_Global_SF6 vs HATS_SF6_date
	DoWindow /C $win

	AppendToGraph HATS_Global_SF6 vs HATS_SF6_date
	
	CurveFit/NTHR=0 line  HATS_Global_SF6 /X=HATS_SF6_date /W=HATS_Global_SF6_sd /I=1 /D 
	Wave W_coef
	sprintf grate, "%0.2f", W_coef[1]*60*60*24*365

	SetDataFolder fldrSav0
	ModifyGraph margin(left)=75,margin(bottom)=70,margin(top)=43,margin(right)=20,gFont="Helvetica"
	ModifyGraph gfSize=14,gmSize=2
	ModifyGraph lSize(HATS_Global_SF6)=2,lSize(HATS_Global_SF6#1)=3,lSize(fit_HATS_Global_SF6)=2
	ModifyGraph rgb(HATS_Global_SF6)=(43690,43690,43690),rgb(HATS_Global_SF6#1)=(0,0,0)
	ModifyGraph grid(left)=1,grid(bottom)=2
	ModifyGraph mirror=2
	ModifyGraph font="Geneva"
	ModifyGraph lblMargin(bottom)=6
	ModifyGraph axThick=2
	ModifyGraph lblPos(left)=78
	ModifyGraph manTick(bottom)={2272147200,2,0,0,yr},manMinor(bottom)={0,50}
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,3,1,2,"Year",-17}
	Label left "\\f01Global Mean " + FullMolName("SF6")
	Label bottom "\\f01Time"
	SetAxis/A/N=1 left
	ErrorBars/T=0.2/L=3 HATS_Global_SF6 Y,wave=(:global:HATS_Global_SF6_sd,:global:HATS_Global_SF6_sd)
	TextBox/C/N=NOAA/F=0/B=1/A=MC/X=-37/Y=-65.38 "\\JL\\F'Helvetica'\\Z11NOAA Global Monitoring Laboratory"
	Legend/C/N=text0/J/F=0/X=-0.55/Y=-11.86 "\\s(HATS_Global_SF6#1) Global mean with 1-sigma errors\r\\s(fit_HATS_Global_SF6) Linear fit: " + grate + " ppt per year growth"
	
	SetAxis/N=1 bottom 2840227200, date2secs(ReturnCurrentYear()+1,1,1)
	TextBox/C/N=datebox/F=0/B=1/A=MC/X=-48.5/Y=-70 "\\JL\\F'Helvetica'\\Z10" + date()[5,50]
	
	SetDrawLayer UserFront
	DrawPICT -.117,1.08,0.4,0.4,noaa_logo_png
	
	NewPath /q/o Web_HATS, userpath + "CATS:web-GML:webdata:hats:combined"
	SavePICT/O/P=Web_HATS/E=-5/B=72 as "hats_sf6_globalmean.png"
	
	SetDataFolder root:
	
EndMacro


Function CCl4figs()

	NVAR plt = root:global:G_plot
	variable oldplt = plt
	plt = 1
	Global_Mean(prefix="HATS", insts="rits;otto;cats", mol="CCl4")
	Global_Mean(prefix="Otto", insts="otto", mol="CCl4")
	Global_Mean(prefix="CATS", insts="cats", mol="CCl4")
	Global_Mean(prefix="rits", insts="rits", mol="CCl4")
	
	CCl4programsFig()
	CCl4_HATS_Latfigure()
	GlobalWebPlot(prefix="HATS", insts="rits;otto;cats", mol="CCl4", errors=1)
	ContourLatbin("HATS", "CCl4")
	NewPath /q/o Web_HATS, userpath + "CATS:web-GML:webdata:hats:combined"
	SavePICT/O/P=Web_HATS/E=-5/B=72 as "hats_ccl4_contour.png"
	
	plt = oldplt

end

function CCl4programsFig()

	string win = "ccl4_programs"
	SetDataFolder root:global:
	DoWindow /K $win
	Display /K=1/W=(879,87,1524,507) 
	DoWindow /C $win
	AppendToGraph rits_Global_CCl4 vs rits_CCl4_date
	AppendToGraph Otto_Global_CCl4 vs Otto_CCl4_date
	AppendToGraph CATS_Global_CCl4 vs CATS_CCl4_date
	AppendToGraph HATS_Global_CCl4 vs HATS_CCl4_date
	ModifyGraph margin(left)=75,margin(bottom)=70,margin(top)=50,margin(right)=20,gFont="Helvetica"
	ModifyGraph gfSize=14,gmSize=2,width=600,height=300
	ModifyGraph lSize(Otto_Global_CCl4)=8
	ModifyGraph lSize(CATS_Global_CCl4)=8,lSize(HATS_Global_CCl4)=2
	ModifyGraph lStyle(CATS_Global_CCl4)=3
	ModifyGraph rgb(Otto_Global_CCl4)=(32768,32770,65535),rgb(HATS_Global_CCl4)=(0,0,0)
	ModifyGraph lstyle=0,lsize(Otto_Global_CCl4)=5,lsize(CATS_Global_CCl4)=5
	ModifyGraph lstyle(RITS_Global_CCl4)=2,rgb(RITS_Global_CCl4)=(52428,34958,1),lsize(RITS_Global_CCl4)=5
	ModifyGraph grid(left)=1,grid(bottom)=2
	ModifyGraph mirror=2
	ModifyGraph font="Geneva"
	ModifyGraph lblMargin(bottom)=6
	ModifyGraph axThick=2
	ModifyGraph lblPos(left)=78
	ModifyGraph manTick(bottom)={2966457600,4,0,0,yr},manMinor(bottom)={3,50}
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,3,1,2,"Year",-17}
	Label left FullMolName("CCl4")
	Label bottom "\\f01Time"
	SetAxis/A/N=1 left
	SetAxis/A/N=1 bottom
	TextBox/C/N=NOAA/F=0/B=1/A=MC/X=-39.33/Y=-66 "\\JL\\F'Helvetica'\\Z11NOAA/GML halocarbons program"
	TextBox/C/N=datebox/F=0/B=1/A=MC/X=-49/Y=-70.67 "\\JL\\F'Helvetica'\\Z10" + date()[5,50]
	Legend/C/N=text0/J/F=0/X=-0.55/Y=-13.33
	AppendText "\\JR\\s(HATS_Global_CCl4) Combined Global mean  \\s(otto_Global_CCl4) Current flask ECD program"
	AppendText "\\s(rits_global_ccl4) RITS in situ program \\s(cats_Global_CCl4) CATS in situ program"
	SetDrawLayer UserFront
	DrawPICT  -.117,1.08,0.4,0.4,noaa_logo_png
	
	SetAxis bottom *,date2secs(ReturnCurrentYear()+1,1,1)
	SetDataFolder root:
	
	NewPath /q/o Web_HATS, userpath + "CATS:web-GML:webdata:hats:combined"
	SavePICT/O/P=Web_HATS/E=-5/B=72 as "hats_ccl4_progs.png"
End

Function CCl4_HATS_Latfigure()

	String fldrSav0= GetDataFolder(1)
	String win = "HATS_ccl4_latwebfig"
	SetDataFolder root:global:
	DoWindow /k $win
	Display /K=1/W=(905,603,1550,1009) HATS_LatBan_CCl4[*][0] vs HATS_CCl4_date
	DoWindow /c $win
	AppendToGraph HATS_LatBan_CCl4[*][1] vs HATS_CCl4_date
	AppendToGraph HATS_LatBan_CCl4[*][2] vs HATS_CCl4_date
	AppendToGraph HATS_LatBan_CCl4[*][3] vs HATS_CCl4_date
	AppendToGraph HATS_LatBan_CCl4[*][4] vs HATS_CCl4_date
	AppendToGraph HATS_LatBan_CCl4[*][5] vs HATS_CCl4_date
	AppendToGraph HATS_LatBan_CCl4[*][6] vs HATS_CCl4_date
	SetDataFolder fldrSav0
	ModifyGraph margin(left)=75,margin(bottom)=70,margin(top)=36,margin(right)=20,gFont="Helvetica"
	ModifyGraph gfSize=14,gmSize=2,width=600,height=300
	ModifyGraph lSize=2
	ModifyGraph lStyle(HATS_LatBan_CCl4#4)=2,lStyle(HATS_LatBan_CCl4#5)=2,lStyle(HATS_LatBan_CCl4#6)=2
	ModifyGraph rgb(HATS_LatBan_CCl4#1)=(24576,24576,65535),rgb(HATS_LatBan_CCl4#2)=(3,52428,1)
	ModifyGraph rgb(HATS_LatBan_CCl4#3)=(4369,4369,4369),rgb(HATS_LatBan_CCl4#4)=(3,52428,1)
	ModifyGraph rgb(HATS_LatBan_CCl4#5)=(0,0,65535),rgb(HATS_LatBan_CCl4#6)=(52428,1,1)
	ModifyGraph grid(left)=1,grid(bottom)=2
	ModifyGraph mirror=2
	ModifyGraph font="Geneva"
	ModifyGraph lblMargin(bottom)=6
	ModifyGraph axThick=2
	ModifyGraph lblPos(left)=78
	ModifyGraph manTick(bottom)={2966457600,4,0,0,yr},manMinor(bottom)={3,50}
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,3,1,2,"Year",-17}
	Label left FullMolName("CCl4")
	Label bottom "\\f01Time"
	SetAxis/A/N=1 left
	Legend/C/N=legd/J/X=2.33/Y=3.67 "\\Z16\\s(HATS_LatBAN_CCl4)60-90 N \r\\s(HATS_LatBAN_CCl4#1)45-60 N\r\\s(HATS_LatBAN_CCl4#2)20-45 N\r\\s(HATS_LatBAN_CCl4#3) 0-20 N"
	AppendText "\\s(HATS_LatBAN_CCl4#4) 0-20 S\r\\s(HATS_LatBAN_CCl4#5)20-45 S\r\\s(HATS_LatBAN_CCl4#6)45-90 S"
	TextBox/C/N=NOAA/F=0/B=1/A=MC/X=-38/Y=-66.33 "\\JL\\F'Helvetica'\\Z11NOAA Global Monitoring Laboratory"
	TextBox/C/N=datebox/F=0/B=1/A=MC/X=-48.91/Y=-70.33 "\\JL\\F'Helvetica'\\Z10" + date()[5,50]
	TextBox/C/N=text0/F=0/X=0.55/Y=-9.00 "Zonal Means"
	SetDrawLayer UserFront
	DrawPICT  -.117,1.08,0.4,0.4,noaa_logo_png
	
	SetAxis bottom 2587766400,date2secs(ReturnCurrentYear()+1,1,1)
	SetDataFolder root:

	NewPath /q/o Web_HATS, userpath + "CATS:web-GML:webdata:hats:combined"
	SavePICT/O/P=Web_HATS/E=-5/B=72 as "hats_ccl4_zones.png"
EndMacro



function UpdateAllWebFigs()

	//UpdateWebPlots_CATS()
	F11figs()
	F12figs()
	F113figs()
	SF6figs()
	N2Ofigs()
	CCl4figs()
	
	SyncFigures()

end


// runs upload.sh script which syncs figures to the website
function SyncFigures()

	string igorCmd, unixCmd
	
	//unixCmd = "\\\"/Users/gdutton/data/web GMD/upload.sh\\\""
	unixCmd = "\\\"/Users/gdutton/data/cats/web-GML/upload.sh\\\""
	
	sprintf igorCmd, "do shell script \"%s\"", unixCmd
	ExecuteScriptText igorCmd
	
	Print S_value
end

//NP == no prompt
Function WMAppendFillBetweenContours_NP()

	String graphName= WinName(0,1)	// top graph
	String contours= ContourNameList("",";")
	if( strlen(graphName) == 0 || strlen(contours) == 0 )
		DoAlert 0, "Need a contour plot in top graph to do this!"
		return 0
	endif

	String contourInstanceName= StringFromList(0,contours)
	if( ItemsInList(contours) > 1 )
		Prompt contourInstanceName,"contour plot to fill",popup,ContourNameList("",";")
		DoPrompt "Append Image or Fill between Contours", contourInstanceName
		if( V_Flag != 0 )
			return 0
		endif
	endif

	WAVE contourImage= ContourNameToWaveRef(graphName,contourInstanceName)	// matrix wave, triplet wave, or z wave of x,y,z contour
	String info=ContourInfo(graphName,contourInstanceName,0)
	String haxis= StringByKey("XAXIS",info)
	String vaxis= StringByKey("YAXIS",info)
	String xwavePath= StringByKey("XWAVE",info)
	String ywavePath= StringByKey("YWAVE",info)
	String zwavePath= StringByKey("ZWAVE",info)
	String flags= StringByKey("AXISFLAGS",info)
	String type=StringByKey("DATAFORMAT",info)

	// choose rows, cols (for xyz contours) based on plot area in pixels,
	GetWindow $graphName, psizeDC	// pixels V_left, V_right, V_top, and V_bottom
	Variable rows=V_right-V_left
	Variable cols=V_bottom-V_top
	String commands=WinRecreation(graphName,4)
	Variable swapXY = strsearch(commands, "swapXY=1",0) >= 0
	if( swapXY )
		Variable tmp= rows
		rows= cols
		cols=tmp	
	endif
	// limit default to something speedy
	if( rows > 1024 )
		rows= 1024
	endif
	if( cols > 1024 )
		cols= 1024
	endif
	
	// Propose an expansion (for matrix contours) that fills the plot area pixels
	Variable expansion=ceil(rows/DimSize(contourImage,0))
	expansion= max(expansion, ceil(cols/DimSize(contourImage,1)))
	Variable sliceYN=2// No
	Prompt sliceYN, "Flat color between contours?", popup, "Yes;No;"

//	if( CmpStr(type,"Matrix") == 0 )
	WAVE/Z wx=$xwavePath
	WAVE/Z wy=$ywavePath
	Variable isMatrixInterpolation= (CmpStr(type,"Matrix") == 0) && !WaveExists(wx) && !WaveExists(wy)
	if( isMatrixInterpolation )
		Prompt expansion,"interpolation factor"
		DoPrompt "Append Image or Fill between Matrix Contours",  sliceYN, expansion
		rows= expansion * DimSize(contourImage,0)
		cols=  expansion * DimSize(contourImage,1)
	else
		Prompt rows,"number of rows"
		Prompt cols,"number of cols"
		//DoPrompt "Append Image or Fill between XYZ Contours", sliceYN, rows, cols
	endif
	if( V_Flag != 0 )
		return 0
	endif
	Variable doSlice= sliceYN == 1	// 1 is Yes, 2 is No

	// pathToImage is the image we want to display. It COULD be just the matrix contour's image
	String pathToImage= WMCreateImageForContour(graphName,contourInstanceName,doSlice,rows,cols)
	Wave image= $pathToImage
	Variable imageAlreadyDisplayed= ImageIsDisplayed(graphName,image)
	if( imageAlreadyDisplayed )
		return 0
	endif 

	// Avoid having BOTH the matrix contour image and an interpolated/sliced image in the graph
	String pathToContourWave= GetWavesDataFolder(contourImage,2)
	Variable contourDisplayedAsImage=  ImageIsDisplayed(graphName,contourImage)
	
	String pathForPossiblyExtantImage= WMCreatedContourImagePath(contourImage)	// NOT the matrix wave; a (re-)created wave, may not even exist.
	WAVE/Z possiblyExtantCreatedImage= $pathForPossiblyExtantImage
	Variable possiblyExtantDisplayedAsImage=  WaveExists(possiblyExtantCreatedImage) && ImageIsDisplayed(graphName,possiblyExtantCreatedImage)

	// we're either going to replace an image or append an image
	String imageInstanceName
	if( contourDisplayedAsImage )
		imageInstanceName= ImageDisplayedName(graphName, contourImage)
		ReplaceWave/W=$graphName image=$imageInstanceName, image

	elseif( possiblyExtantDisplayedAsImage )
		imageInstanceName= ImageDisplayedName(graphName, possiblyExtantCreatedImage)
		ReplaceWave/W=$graphName image=$imageInstanceName, image
	else
		String cmd
		sprintf cmd,"AppendImage%s %s",flags,pathToImage
		Execute cmd
	endif
	return 1	// truth an image was appended or altered
End

// inverse of ImageNameToWaveRef()
static Function/S ImageDisplayedName(graphName, image)
	String graphName
	Wave image
	
	String pathToImage=  GetWavesDataFolder(image,2)
	String images=ImageNameList(graphName,";")
	Variable i=0
	do
		String imageName= StringFromList(i, images)
		if( strlen(imageName) == 0 )
			break
		endif
		Wave w= ImageNameToWaveRef(graphName,imageName)
		String pathToW=GetWavesDataFolder(w,2)
		if( CmpStr(pathToImage, pathToW) == 0 )
			return imageName
		endif
		i+=1
	while(1)

	return ""
End

static Function ImageIsDisplayed(graphName,image)
	String graphName
	Wave image
	
	String imageInstanceName= ImageDisplayedName(graphName, image)
	return strlen(imageInstanceName) > 0
End


// make sure the MSD data is loaded before running
function HATSdatafigures([mol])
	string mol		// for debugging use on MSD mols only

	string win, MSDgases, sites
	variable i
	if (ParamIsDefault(mol))
		// does N2O, F11, F12, F113, SF6, CH3CCl3, CCl4
		calcHATScombinedData()
		
		// other MSD (M3 and Perseus gases excluding combo gases.
		MSDgases = "HCFC22;HCFC141b;HCFC142b;HFC134A;HFC152A;HFC227ea;HFC365mfc;OCS;MC;CH2Cl2;C2Cl4;h1211;h2402;CH3Br;CH3Cl;"
		MSDgases += kPERSEUSmols
		
		// make sure global means are up to date
		for (i=0; i<ItemsInList(MSDgases); i+=1)
			Global_Mean(insts="MSD", prefix="HATS", mol=StringFromList(i, MSDgases), plot=2, offsets=1)
		endfor
		
		string mols = kMSDmols + kPERSEUSmols + "N2O;SF6;F11;F12;CCl4"			// kMSDmols is defined in "HATS FTP Data.ipf"
	else
		mols = mol
		MSDgases = mol
		Global_Mean(insts="MSD", prefix="HATS", mol=mol, plot=2, offsets=1)
	endif
	
	// make thumbnail figures for website
	for(i=0; i<ItemsInList(mols); i+=1)
		mol = StringFromList(i, mols)
		ZonalMeanFigure(mol=mol)
		win = WinName(0,1)
		win = win[5,inf]	// shorten figure name (remove HATS)
		DoWindow /K $win
		DoWindow /K $win + "_th"
		DoWindow /C $win
		
		// thumbnail
		DoWindow/C $win + "_th"
		Legend/K/N=legd
		Label bottom "\\Z13Time"
		Label left "\\Z13"+FullMolName(mol)
		ModifyGraph mirror=2
		ModifyGraph gfSize=0
		ModifyGraph width=200,height=100
//		if ((cmpstr(mol, "N2O") == 0) || (cmpstr(mol, "F11") == 0) || (cmpstr(mol, "F12") == 0))
//			ModifyGraph manTick=0
//		else
//			ModifyGraph manTick(bottom)={3029529600,5,0,0,yr},manMinor(bottom)={4,0}
//		endif
		ModifyGraph manTick=0
		ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,4,1,2,"Year",-29}
		DoUpdate
		NewPath /q/o webdata, userpath + "CATS:web-GML:webdata:hats:front"
		SavePICT/O/P=webdata/E=-6/B=72
		
		if (ParamIsDefault(mol))
			DoWindow /K $win + "_th"
		endif
	endfor
	
	// figures for webpages that are not combined data sets.
	for(i=0; i<ItemsInList(MSDgases); i+=1)
		mol = StringFromList(i, MSDgases)
		HATSzonalmeans(mol)
		MSDbackground(mol)
	endfor

	if (ParamIsDefault(mol))
		SyncFigures()
	endif
end

function HATSzonalmeans(mol)
	string mol

	String fldrSav0= GetDataFolder(1), leg
	SetDataFolder root:global:

	// zonal mean figure
	wave DD = $"HATS_" + mol + "_date"
	string lb ="HATS_LatBan_" + mol
	wave latbin = $lb
	string win = "ZonalMeanFigure_" + mol

	DoWindow /k $win
	Display /W=(59,58,876,429)/K=1  latbin[*][0] vs DD
	AppendToGraph latbin[*][1] vs DD
	AppendToGraph latbin[*][2] vs DD
	AppendToGraph latbin[*][3] vs DD
	AppendToGraph latbin[*][4] vs DD
	AppendToGraph latbin[*][5] vs DD
	AppendToGraph latbin[*][6] vs DD
	SetDataFolder fldrSav0
	ModifyGraph margin(right)=144,gfSize=14,width=600,height=300
	ModifyGraph lSize=2
	ModifyGraph lStyle($lb#4)=2,lStyle($lb#5)=2,lStyle($lb#6)=2
	ModifyGraph rgb($lb#1)=(24576,24576,65535),rgb($lb#2)=(3,52428,1)
	ModifyGraph rgb($lb#3)=(4369,4369,4369),rgb($lb#4)=(3,52428,1)
	ModifyGraph rgb($lb#5)=(0,0,65535),rgb($lb#6)=(52428,1,1)
	ModifyGraph mirror=2
	ModifyGraph mirror(bottom)=1
	//ModifyGraph manTick(bottom)={3029529600,5,0,0,yr},manMinor(bottom)={4,0}
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,4,1,2,"Year",-29}
	Label left FullMolName(mol)
	Label bottom "Time"
	SetAxis/A/N=1 left
	SetAxis/A/N=1 bottom
	//SetAxis bottom *, date2secs(ReturnCurrentYear()+1,3,1)
	SetAxis bottom delta_date(latbin, DD, -365/2*24*60*60), delta_date(latbin, DD, +365/2*24*60*60)
	
	sprintf leg, "\\s(%s)60-90 N \r\\s(%s#1)45-60 N\r\\s(%s#2)20-45 N\r\\s(%s#3) 0-20 N\r\\s(%s#4) 0-20 S\r\\s(%s#5)20-45 S\r\\s(%s#6)45-90 S", lb, lb, lb, lb, lb, lb, lb
	Legend/C/N=legd/J/X=-20.67/Y=29.00 leg
	TextBox/C/N=text1/F=0/A=LC/X=102.00/Y=36.00 "\\JCZonal means\rfrom background \rstations "
	TextBox/C/N=date/F=0/A=LB/X=-10.50/Y=-16.67 "\\Z09"+date()
	SetDrawLayer UserFront
	DrawPICT 1.06666666666667,0.803333333333333,0.581818,0.577982,noaa_logo_png
	
	DoWindow /C $win
	
	SavePICT/O/P=webdata/E=-6/B=72
	
end

Function /D delta_date(matrix, datewv, delta)
	wave matrix, datewv
	variable delta
	variable pt
	MatrixOp /free good = replace(maxRows(replaceNaNs(matrix,0)),0,Nan)
	if (delta < 0)
		pt = FirstGoodPt(good)
	else
		pt = LastGoodPt(good)
	endif
	return datewv[pt] + delta
end

// figures for background MSD sites
function MSDbackground(mol)
	string mol
	
	String fldrSav0= GetDataFolder(1)
	string site, win = "BK_" + mol
	variable i
	
	SetDataFolder root:MSD:
	DoWindow /K $win
	Display /K=1/W=(59,506,878,879)
	for(i=0; i<ItemsInList(AllBKsitesMSD); i+=1)
		site = StringFromList(i, AllBKsitesMSD)
		string mixstr = "MSD_" + site + "_" + mol
		if (WaveExists($mixstr))
			Wave mix = $mixstr
			Wave DD = $"MSD_" + site + "_" + mol + "_date"
			AppendToGraph mix vs DD
		endif
	endfor
	
	SetDataFolder fldrSav0

	ColorWavesBasedonLat()
	
	ModifyGraph margin(right)=144,gfSize=14,width=600,height=300
	ModifyGraph mode=4
	ModifyGraph marker=19
	ModifyGraph lSize=2
	ModifyGraph msize=3
	ModifyGraph mirror=2
	ModifyGraph mirror(bottom)=1
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,4,1,2,"Year",-29}
	//ModifyGraph manTick(bottom)={3029529600,5,0,0,yr},manMinor(bottom)={4,0}
	Label left FullMolName(mol)
	Label bottom "Time"
	SetAxis/A/N=1 left
	SetAxis/A/N=1 bottom
	SetAxis bottom *, date2secs(ReturnCurrentYear()+1,6,1)
	
	// duplicate the axis of the zonal mean figure
	string win0 = "ZonalMeanFigure_" + mol
	DoWindow $win0
	if (V_flag == 1)
		string cmd = StringByKey("SETAXISCMD", AxisInfo(win0, "bottom"))
		Execute /Q cmd
		cmd = StringByKey("SETAXISCMD", AxisInfo(win0, "left"))
	endif

	ColorScale/C/N=text0/X=104.17/Y=2.33  ctab={-90,90,EOSSpectral11,1}, nticks=10
	ColorScale/C/N=text0 lblMargin=0
	AppendText "Latitude"
	TextBox/C/N=text1/F=0/A=LC/X=105.67/Y=47.00 "\\JCBackground\rstations"
	TextBox/C/N=date/F=0/A=LB/X=-10.50/Y=-16.67 "\\Z09"+date()
	SetDrawLayer UserFront
	DrawPICT 1.07333333333333,0.89,0.581818,0.577982,noaa_logo_png

	DoWindow /C $win
	SavePICT/O/P=webdata/E=-6/B=72
end	

