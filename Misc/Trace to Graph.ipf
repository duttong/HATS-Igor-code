#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6

Menu "TracePopup"
	"-"
	"Trace to New Graph"
	"Append Trace to Graph"
end

function TracetoNewGraph()
	GetLastUserMenuInfo
	string info = TraceInfo(S_graphName, S_traceName,0)
	string cmd, attribs = "rgb;mode;marker;lSize;lStyle;lSmooth;mrkThick;gaps"
	variable i
	Wave Ywv = TraceNameToWaveRef(S_graphName, S_traceName)
	
	if (WaveExists(XWaveRefFromTrace(S_graphName, S_traceName)))
		Wave Xwv = XWaveRefFromTrace(S_graphName, S_traceName)
		Display /K=1 Ywv vs Xwv
	else
		Display /K=1 Ywv
	endif
	
	for(i=0; i<ItemsInList(attribs); i+=1)
		cmd = RetModifyGraph(info, S_traceName, StringFromList(i, attribs))
		execute(cmd)
	endfor
	
end

function AppendTracetoGraph()
	GetLastUserMenuInfo
	string info = TraceInfo(S_graphName, S_traceName,0)
	string grp, cmd, attribs = "rgb;mode;marker;lSize;lStyle;lSmooth;mrkThick;gaps"
	variable i
	Wave Ywv = TraceNameToWaveRef(S_graphName, S_traceName)
	
	String Graphs = WinList("*", ";", "WIN:1")
	Graphs = RemoveFromList(WinName(0,1), Graphs)
	Prompt grp, "Append to which graph", popup, Graphs
	DoPrompt "Appending Trace", grp
	if (V_flag)
		return -1
	endif
	
	DoWindow /F $grp
	
	if (WaveExists(XWaveRefFromTrace(S_graphName, S_traceName)))
		Wave Xwv = XWaveRefFromTrace(S_graphName, S_traceName)
		AppendtoGraph Ywv vs Xwv
	else
		AppendtoGraph Ywv
	endif
	
	for(i=0; i<ItemsInList(attribs); i+=1)
		cmd = RetModifyGraph(info, S_traceName, StringFromList(i, attribs))
		execute(cmd)
	endfor
		
end

// takes input from TraceInfo function and finds attrib in string info
function/S ReturnRECattrib(info, attrib)
	string info, attrib
	
	string fnd = attrib + "(x)="
	variable v1, v2
	v1 = strsearch(info, fnd, 0)
	if (v1 == -1)
		return ""
	endif
	v2 = strsearch(info, ";", v1+strlen(fnd))
		
	return info[v1+strlen(fnd), v2-1]
end

// returns a ModifyGraph command with TraceInfo settings for attrib
// use return in excute command
function /S RetModifyGraph(info, trace, attrib)
	string info, trace, attrib
	
	string out = ReturnRECattrib(info, attrib), mdf
	if (strlen(out) == 0)
		return ""
	endif
	
	sprintf mdf, "ModifyGraph %s(%s)=%s", attrib, trace, out
	return mdf
	
end
