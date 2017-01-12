#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

static StrConstant EXT_PANEL_SUBWINDOW = "OverlaySweeps"

Menu "TracePopup"
	"Ignore Headstage in Overlay Sweeps", /Q, OVS_IgnoreHeadstageInOverlay()
End

/// @brief This user trace menu function allows the user to select a trace
///        in overlay sweeps mode which should be ignored.
Function OVS_IgnoreHeadstageInOverlay()
	string graph, trace, extPanel, str, folder
	variable headstage, sweepNo, index

	GetLastUserMenuInfo
	graph = S_graphName
	trace = S_traceName

	extPanel = OVS_GetExtPanel(graph)

	if(!WindowExists(graph))
		printf "Context menu option \"%s\" is only useable for overlay sweeps.\r", S_Value
		ControlWindowToFront()
		return NaN
	endif

	sweepNo = str2num(GetUserData(graph, trace, "sweepNumber"))

	if(!IsValidSweepNumber(sweepNo))
		printf "Could not extract sweep number information from trace \"%s\".\r", trace
		ControlWindowToFront()
		return NaN
	endif

	headstage = str2num(GetUserData(graph, trace, "headstage"))

	if(!IsFinite(headstage))
		printf "Ignoring trace \"%s\" as it is not associated with a headstage.\r", trace
		ControlWindowToFront()
		return NaN
	endif

	sprintf str, "sweepNo=%d, headstage=%d", sweepNo, headstage
	DEBUGPRINT(str)

	// only set for sweepbrowser graphs
	folder = GetUserData(graph, "", "folder")

	if(!IsEmpty(folder))
		WAVE traceWave     = TraceNameToWaveRef(graph, trace)
		DFREF sweepDataDFR = GetWavesDataFolderDFR(traceWave)
		index = OVS_GetIndexFromSweepDataPathW(graph, sweepDataDFR)
		OVS_AddToIgnoreList(extPanel, headstage, index=index)
	else
		OVS_AddToIgnoreList(extPanel, headstage, sweepNo=sweepNo)
	endif
End

Function OVS_GetIndexFromSweepDataPathP(graph, dataDFR)
	string graph
	DFREF dataDFR

	ASSERT(0, "Can't call prototype function")
End

Function OVS_GetIndexFromSweepDataPathW(graph, dataDFR)
	string graph
	DFREF dataDFR

	FUNCREF OVS_GetIndexFromSweepDataPathP f = $"SB_GetIndexFromSweepDataPath"

	return f(graph, dataDFR)
End

/// @brief Return the full subwindow specification of the overlay sweeps panel
Function/S OVS_GetExtPanel(win)
	string win

	return GetMainWindow(win) + "#" + EXT_PANEL_SUBWINDOW
End

/// @brief Return a list of choices for the sweep selection popup
///
/// Includes a unique list of the DA stimsets of all available sweeps
Function/S OVS_GetSweepSelectionChoices(win)
	string win

	variable i, numEntries

	DFREF dfr = OVS_GetFolder(win)
	WAVE/T stimsetListWave = GetOverlaySweepsStimsetListWave(dfr)

	FindDuplicates/RT=dupsRemovedWave stimsetListWave

	return NONE + ";All;\\M1(-;\\M1(DA Stimulus Sets;" + TextWaveToList(MakeWaveFree(dupsRemovedWave), ";")
End

/// @brief Return the datafolder reference to the folder storing the listbox and selection wave
///
/// Requires the user data `OVS_FOLDER` of the external overlay sweeps panel.
///
/// @return a valid DFREF or an invalid one in case the external panel could not be found
Function/DF OVS_GetFolder(win)
	string win

	string extPanel = OVS_GetExtPanel(win)

	if(!WindowExists(extPanel))
		return $""
	endif

	DFREF dfr = $GetUserData(extPanel, "", "OVS_FOLDER")
	ASSERT(DataFolderExistsDFR(dfr), "Missing extPanel OVS_FOLDER userdata")

	return dfr
End

/// @brief Update the overlay sweep waves
///
/// Must be called after the sweeps changed.
Function OVS_UpdatePanel(win, listBoxWave, listBoxSelWave, stimSetListWave, sweepWaveList, [allTextualValues, textualValues])
	string win
	WAVE/T listBoxWave
	WAVE listBoxSelWave
	WAVE/T stimSetListWave
	WAVE/T textualValues
	WAVE/WAVE allTextualValues
	string sweepWaveList

	variable i, numEntries, sweepNo
	string ttlStimSets, extPanel

	extPanel = OVS_GetExtPanel(win)

	numEntries = ItemsInList(sweepWaveList)

	if(!ParamIsDefault(textualValues))
		Make/WAVE/FREE/N=(numEntries) allTextualValues = textualValues
	elseif(!ParamIsDefault(allTextualValues))
		ASSERT(numEntries == DimSize(allTextualValues, ROWS), "allTextualValues number of rows is not matching")
	else
		ASSERT(0, "Expected exactly one of textualValues or allTextualValues")
	endif

	Redimension/N=(numEntries, -1) listBoxWave, listBoxSelWave, stimSetListWave

	Make/FREE/U/I/N=(numEntries) sweeps = ExtractSweepNumber(StringFromList(p, sweepWaveList))
	MultiThread listBoxWave[][%Sweep] = num2str(sweeps[p])

	listBoxSelWave[][%Sweep] = listBoxSelWave[p] & LISTBOX_CHECKBOX_SELECTED ? LISTBOX_CHECKBOX | LISTBOX_CHECKBOX_SELECTED : LISTBOX_CHECKBOX

	if(WindowExists(extPanel) && GetCheckBoxState(extPanel, "check_overlaySweeps_disableHS"))
		listBoxSelWave[][%Headstages] = SetBit(listBoxSelWave[p][%Headstages], LISTBOX_CELL_EDITABLE)
	else
		listBoxSelWave[][%Headstages] = ClearBit(listBoxSelWave[p][%Headstages], LISTBOX_CELL_EDITABLE)
	endif

	for(i = 0; i < numEntries; i += 1)
		WAVE/T stimsets = GetLastSettingText(allTextualValues[i], sweeps[i], STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
		stimSetListWave[i][] = stimsets[q]
	endfor
End

/// @return free wave with the indizes into the listbox waves, invalid wave reference in case nothing is selected
Function/WAVE OVS_GetSelectedSweeps(win)
	string win

	DFREF dfr = OVS_GetFolder(win)

	if(!DataFolderExistsDFR(dfr))
		return $""
	endif

	WAVE/T listboxWave  = GetOverlaySweepsListWave(dfr)
	WAVE listboxSelWave = GetOverlaySweepsListSelWave(dfr)

	Extract/INDX/FREE listboxSelWave, selectedSweeps, listboxSelWave & LISTBOX_CHECKBOX_SELECTED

	if(DimSize(selectedSweeps, ROWS) == 0)
		return $""
	endif

	return selectedSweeps
End

/// @brief Invert the selection of the given sweep in the listbox wave
Function OVS_InvertSweepSelection(win, [sweepNo, index])
	string win
	variable sweepNo, index

	variable selectionState

	DFREF dfr = OVS_GetFolder(win)

	if(!DataFolderExistsDFR(dfr))
		return NaN
	endif

	WAVE/T listboxWave  = GetOverlaySweepsListWave(dfr)
	WAVE listboxSelWave = GetOverlaySweepsListSelWave(dfr)

	if(!ParamIsDefault(sweepNo))
		FindValue/TEXT=num2str(sweepNo)/TXOP=4 listboxWave
		index = V_Value
	elseif(!ParamIsDefault(index))
		// do nothing
	else
		ASSERT(0, "Requires one of index or sweepNo")
	endif

	if(index < 0 || index >= DimSize(listBoxWave, ROWS) || !IsFinite(index))
		return NaN
	endif

	selectionState = listboxSelWave[index]
	if(selectionState & LISTBOX_CHECKBOX_SELECTED)
		listboxSelWave[index] = ClearBit(selectionState, LISTBOX_CHECKBOX_SELECTED)
	else
		listboxSelWave[index] = SetBit(selectionState, LISTBOX_CHECKBOX_SELECTED)
	endif
End

/// @brief Select the given sweep in the listbox wave
Function OVS_SelectSweep(win, [sweepNo, index])
	string win
	variable sweepNo, index

	variable selectionState

	DFREF dfr = OVS_GetFolder(win)

	if(!DataFolderExistsDFR(dfr))
		return NaN
	endif

	WAVE/T listboxWave  = GetOverlaySweepsListWave(dfr)
	WAVE listboxSelWave = GetOverlaySweepsListSelWave(dfr)

	if(!ParamIsDefault(sweepNo))
		FindValue/TEXT=num2str(sweepNo)/TXOP=4 listboxWave
		index = V_Value
	elseif(!ParamIsDefault(index))
		// do nothing
	else
		ASSERT(0, "Requires one of index or sweepNo")
	endif

	if(index < 0 || index >= DimSize(listBoxWave, ROWS) || !IsFinite(index))
		return NaN
	endif

	listboxSelWave[index] = SetBit(listboxSelWave[index], LISTBOX_CHECKBOX_SELECTED)
End

/// @brief Add `headstage` to the ignore list of the given `sweepNo/index`
static Function OVS_AddToIgnoreList(win, headstage, [sweepNo, index])
	string win
	variable headstage, sweepNo, index

	variable row

	DFREF dfr = OVS_GetFolder(win)

	if(!DataFolderExistsDFR(dfr))
		return NaN
	endif

	WAVE/T listboxWave = GetOverlaySweepsListWave(dfr)

	if(!ParamIsDefault(sweepNo))
		FindValue/TEXT=num2str(sweepNo)/TXOP=4 listboxWave
		index = V_Value
	elseif(!ParamIsDefault(index))
		// do nothing
	else
		ASSERT(0, "Requires one of index or sweepNo")
	endif

	if(index < 0 || index >= DimSize(listBoxWave, ROWS) || !IsFinite(index))
		ASSERT(0, "Invalid sweepNo/index")
	endif

	listboxWave[index][%headstages] = AddListItem(num2str(headstage), listboxWave[index][%headstages], ";", inf)
	UpdateSweepPlot(win)
End

/// @brief Parse the ignore list of the given sweep.
///
///
/// The expected format of the ignore list entries is a semicolon (";") separated
/// list of subranges (without the possibility denoting the step size).
///
/// Examples:
/// - 0 (ignore HS 0)
/// - 1,3;0 (ignore HS 0 to 3)
/// - * (ignore all headstages)
///
/// @return free wave of size `NUM_HEADSTAGES` denoting with 0/1 the active state
///         of the headstage
Function/WAVE OVS_ParseIgnoreList(win, highlightSweep, [sweepNo, index])
	string win
	variable sweepNo, index, &highlightSweep

	variable numEntries, i, start, stop, step
	string ignoreList, subRangeStr, extPanel

	extPanel =  OVS_GetExtPanel(win)

	DFREF dfr = OVS_GetFolder(win)

	// save default
	highlightSweep = NaN

	if(!DataFolderExistsDFR(dfr) || !GetCheckBoxState(extPanel, "check_overlaySweeps_disableHS"))
		return $""
	endif

	WAVE/T listboxWave = GetOverlaySweepsListWave(dfr)

	if(!ParamIsDefault(sweepNo))
		FindValue/TEXT=num2str(sweepNo)/TXOP=4 listboxWave
		index = V_Value
	elseif(!ParamIsDefault(index))
		// do nothing
	else
		ASSERT(0, "Requires one of index or sweepNo")
	endif

	if(index < 0 || index >= DimSize(listBoxWave, ROWS) || !IsFinite(index))
		ASSERT(index != -1, "Invalid sweepNo/index")
	endif

	highlightSweep = OVS_IsSweepHighlighted(listboxWave, index)

	ignoreList = listboxWave[index][%headstages]
	numEntries = ItemsInList(ignoreList)

	Make/FREE/N=(NUM_HEADSTAGES) activeHS = 1

	for(i = 0; i < numEntries; i += 1)
		subRangeStr = "[" + StringFromList(i, ignoreList) + "]"
		WAVE/Z subrange = ExtractFromSubrange(subRangeStr, 0)

		if(!WaveExists(subrange) || DimSize(subrange, ROWS) != 1)
			printf "Could not parse subrange \"%s\" number %d from sweep %d\r", subRangeStr, i, sweepNo
			ControlWindowToFront()
			continue
		endif

		start = subrange[0][0]
		stop  = subrange[0][1]

		if(start == -1 && stop == -1) // ignore all
			activeHS = 0
			return activeHS
		elseif(stop == -1)
			activeHS[start, inf]  = 0
		else
			activeHS[start, stop] = 0
		endif
	endfor

	return activeHS
End

/// @brief Toggle the overlay sweeps external panel
///
/// @return 0 if opened, 1 if closed
Function OVS_TogglePanel(win, listboxWave, listboxSelWave)
	string win
	WAVE/T listboxWave
	WAVE listboxSelWave

	string extPanel = OVS_GetExtPanel(win)

	if(WindowExists(extPanel))
		KillWindow $extPanel
		return 1
	endif

	win = GetMainWindow(win)
	SetActiveSubWindow $win
	NewPanel/HOST=#/EXT=1/W=(200,0,0,407)
	SetWindow kwTopWin, hook(main)=OVS_MainWindowHook
	ListBox list_of_ranges,pos={7.00,70.00},size={186.00,330},proc=OVS_MainListBoxProc
	ListBox list_of_ranges,mode=0,widths={50,50},listWave=listboxWave,selWave=listboxSelWave
	ListBox list_of_ranges,help={"Select sweeps for overlay; The second column (\"Headstages\") allows to ignore some headstages for the graphing. Syntax is a semicolon \";\" separated list of subranges, e.g. \"0\", \"0,2\", \"1;4;2\""}
	PopupMenu popup_overlaySweeps_select,pos={19.00,24.00},size={156.00,19.00},proc=OVS_PopMenuProc_Select,title="Select"
	PopupMenu popup_overlaySweeps_select,mode=1,popvalue="- none -",value=#("OVS_GetSweepSelectionChoices(\"" + extPanel + "\")")
	PopupMenu popup_overlaySweeps_select,help={"Select sweeps according to various properties"}
	CheckBox check_overlaySweeps_disableHS,pos={22.00,50.00},size={122.00,15.00},proc=OVS_CheckBoxProc_HS_Select,title="Headstage Removal"
	CheckBox check_overlaySweeps_disableHS,help={"Toggle headstage removal"}
	CheckBox check_overlaySweeps_disableHS,value= 0
	RenameWindow #,OverlaySweeps
	SetActiveSubwindow ##

	SetWindow $extPanel, userData(OVS_FOLDER)=GetWavesDataFolder(listboxWave, 1)

	return 0
End

Function OVS_CheckBoxProc_HS_Select(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	string win

	switch(cba.eventCode)
		case 2: // mouse up
			win = cba.win

			DFREF dfr = OVS_GetFolder(win)
			WAVE listboxSelWave = GetOverlaySweepsListSelWave(dfr)

			if(cba.checked)
				listBoxSelWave[][%Headstages] = SetBit(listBoxSelWave[p][%Headstages], LISTBOX_CELL_EDITABLE)
			else
				listBoxSelWave[][%Headstages] = ClearBit(listBoxSelWave[p][%Headstages], LISTBOX_CELL_EDITABLE)
			endif

			UpdateSweepPlot(win)
		break
	endswitch

	return 0
End

static Function OVS_HighlightSweep(win, index)
	string win
	variable index

	DFREF dfr = OVS_GetFolder(win)
	WAVE/T listboxWave = GetOverlaySweepsListWave(dfr)

	SetDimLabel ROWS, -1, $num2str(index), listboxWave
End

/// @brief Return the state of the sweep highlightning
///
/// @return NaN no sweep highlighted, or 1/0 if index needs highlightning or not
static Function OVS_IsSweepHighlighted(listBoxWave, index)
	WAVE/T listBoxWave
	variable index

	variable state = str2num(GetDimLabel(listBoxWave, ROWS, -1))

	if(!IsFinite(state))
		return NaN
	endif

	return state == index
End

Function OVS_MainListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	string win

	switch(lba.eventCode)
		case 6: //begin edit
			win = lba.win
			OVS_HighlightSweep(win, lba.row)
			UpdateSweepPlot(win)
			break
		case 7:  // end edit
			win = lba.win
			OVS_HighlightSweep(win, NaN)
			UpdateSweepPlot(win)
			break
		case 13: // checkbox clicked
			win = lba.win
			UpdateSweepPlot(win)
			break
	endswitch

	return 0
End

Function OVS_PopMenuProc_Select(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string popStr, win
	variable i, numEntries, j

	switch(pa.eventCode)
		case 2: // mouse up
			win = pa.win
			popStr     = pa.popStr

			DFREF dfr = OVS_GetFolder(win)
			WAVE listboxSelWave    = GetOverlaySweepsListSelWave(dfr)
			WAVE/T stimsetListWave = GetOverlaySweepsStimsetListWave(dfr)

			if(!cmpstr(popStr, NONE))
				listboxSelWave[][%Sweep] = listboxSelWave[p][q] & ~LISTBOX_CHECKBOX_SELECTED
			elseif(!cmpstr(popStr, "All"))
				listboxSelWave[][%Sweep] = listboxSelWave[p][q] | LISTBOX_CHECKBOX_SELECTED
			else
				listboxSelWave[][%Sweep] = listboxSelWave[p][q] & ~LISTBOX_CHECKBOX_SELECTED

				for(i = 0; i < NUM_HEADSTAGES; i += 1)
					WAVE/Z indizes = FindIndizes(wvText=stimsetListWave, col=i, str=popStr)
					if(!WaveExists(indizes))
						continue
					endif

					numEntries = DimSize(indizes, ROWS)
					for(j = 0; j < numEntries; j += 1)
						listboxSelWave[indizes[j]][%Sweep] = listboxSelWave[p][q] | LISTBOX_CHECKBOX_SELECTED
					endfor
				endfor
			endif

			UpdateSweepPlot(win)
			break
	endswitch

	return 0
End

Function OVS_MainWindowHook(s)
	STRUCT WMWinHookStruct &s

	string win, mainWindow, ctrl

	switch(s.eventCode)
		case 2: // kill
			mainWindow = GetMainWindow(s.winName)

			if(IsDataBrowser(mainWindow))
				ctrl = "check_DataBrowser_SweepOverlay"
				win  = mainWindow
			else
				ctrl = "check_SweepBrowser_SweepOverlay"
				win  = mainWindow + "#P0"
			endif

			PGC_SetAndActivateControl(win, ctrl, val=CHECKBOX_UNSELECTED)
			break
	endswitch

	return 0
End
