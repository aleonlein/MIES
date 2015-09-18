#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_DataManagementNew.ipf
/// @brief __DM__ Convert and scale acquired data

static Constant FLOAT_32BIT = 0x02
static Constant FLOAT_64BIT = 0x04

Function DM_SaveAndScaleITCData(panelTitle)
	string panelTitle

	variable sweepNo, rowsToCopy, saveSweepData
	string savedDataWaveName, savedSetUpWaveName

	sweepNo = GetSetVariable(panelTitle, "SetVar_Sweep")
	// the checkbox text reads "Do not save data"
	saveSweepData = !GetCheckBoxState(panelTitle, "Check_Settings_SaveData")

	WAVE ITCDataWave = GetITCDataWave(panelTitle)
	Redimension/Y=(GetRawDataFPType(panelTitle)) ITCDataWave
	DM_ADScaling(ITCDataWave, panelTitle)
	DM_DAScaling(ITCDataWave, panelTitle)

	if(saveSweepData)
		WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)

		savedDataWaveName = GetDeviceDataPathAsString(panelTitle)  + ":Sweep_" +  num2str(sweepNo)
		savedSetUpWaveName = GetDeviceDataPathAsString(panelTitle) + ":Config_Sweep_" + num2str(sweepNo)

		rowsToCopy = DC_GetStopCollectionPoint(panelTitle, DATA_ACQUISITION_MODE) - 1

		Duplicate/O/R=[0, rowsToCopy][] ITCDataWave $savedDataWaveName/Wave=dataWave
		Duplicate/O ITCChanConfigWave $savedSetUpWaveName
		note dataWave, Time()
		note dataWave, GetExperimentName()  + " - Igor Pro " + num2str(igorVersion())
		AppendMiesVersionToWaveNote(dataWave)

		SetVariable SetVar_Sweep, Value = _NUM:(sweepNo + 1), limits={0, sweepNo + 1, 1}, win = $panelTitle

		if (GetCheckboxState(panelTitle, "check_Settings_SaveAmpSettings"))
			AI_FillAndSendAmpliferSettings(panelTitle, sweepNo)
			// function for debugging
			// AI_createDummySettingsWave(panelTitle, SweepNo)
		endif

		// if option is checked, wave note containing single readings from (async) ADs is made
		if(GetCheckboxState(panelTitle, "Check_Settings_Append"))
			ITC_ADDataBasedWaveNotes(dataWave, panelTitle)
		endif

		//Add wave notes for the stim wave name and scale factor
		ED_createWaveNoteTags(panelTitle, sweepNo)

		//Add wave notes for the factors on the Asyn tab
		ED_createAsyncWaveNoteTags(panelTitle, sweepNo)

		// TP settings, especially useful if "global TP insertion" is active
		ED_TPSettingsDocumentation(panelTitle)

		AM_analysisMasterPostSweep(panelTitle, sweepNo)
	endif

	DM_CallAnalysisFunctions(panelTitle, POST_SWEEP_EVENT)

	if(saveSweepData)
		DM_AfterSweepDataSaveHook(panelTitle)
	endif
End

/// @brief Call the analysis function associated with the stimset from the wavebuilder
Function DM_CallAnalysisFunctions(panelTitle, eventType)
	string panelTitle
	variable eventType

	variable error, i
	string func, setName

	if(GetCheckBoxState(panelTitle, "Check_Settings_SkipAnalysFuncs"))
		return NaN
	endif

	NVAR count = $GetCount(panelTitle)
	WAVE/T sweepDataTxTLNB = GetSweepSettingsTextWave(panelTitle)
	WAVE guiState = GetDA_EphysGuiStateNum(panelTitle)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!guiState[i][%HSState])
			continue
		endif

		switch(eventType)
			case PRE_DAQ_EVENT:
				func = sweepDataTxTLNB[0][5][i]
				break
			case MID_SWEEP_EVENT:
				func = sweepDataTxTLNB[0][6][i]
				break
			case POST_SWEEP_EVENT:
				func = sweepDataTxTLNB[0][7][i]
				break
			case POST_SET_EVENT:
				func = sweepDataTxTLNB[0][8][i]
				// we have to check if we acquired a full set for the headstage
				setName = sweepDataTxTLNB[0][0][i]

				if(mod(count + 1, IDX_NumberOfTrialsInSet(panelTitle, setName)) != 0)
					continue
				endif
				break
			case POST_DAQ_EVENT:
				func = sweepDataTxTLNB[0][9][i]
				break
			default:
				ASSERT(0, "Invalid eventType")
				break
		endswitch

		DEBUGPRINT("function", str=func)

		if(isEmpty(func))
			continue
		endif

		FUNCREF AF_PROTO_ANALYSIS_FUNC_V1 f = $func

		if(!FuncRefIsAssigned(FuncRefInfo(f))) // not a valid analysis function
			continue
		endif

		WAVE ITCDataWave = GetITCDataWave(panelTitle)
		SetWaveLock 1, ITCDataWave

		try
			f(panelTitle, eventType, ITCDataWave, i); AbortOnRTE
		catch
			error = GetRTError(1)
			printf "The analysis function %s aborted, this is dangerous and must *not* happen!\r", func
		endtry

		SetWaveLock 0, ITCDataWave
	endfor
End

/// @brief General hook function which gets always executed after sweep data saving
static Function DM_AfterSweepDataSaveHook(panelTitle)
	string panelTitle

	string panelList, dataPath, panel, panelType
	variable numPanels, i

	panelList = WinList("DB_*", ";", "WIN:64")

	numPanels = ItemsInList(panelList)
	for(i = 0; i < numPanels; i += 1)
		panel = StringFromList(i, panelList)

		panelType = GetUserData(panel, "", MIES_PANEL_TYPE_USER_DATA)
		if(!cmpstr(panelType, MIES_DATABROWSER_PANEL))
			dataPath   = GetUserData(panel, "", "DataFolderPath")
			if(!cmpstr(dataPath, GetDevicePathAsString(panelTitle)))
				DB_UpdateToLastSweep(panel)
			endif
		endif
	endfor
End

Function DM_CreateScaleTPHoldingWave(panelTitle, [chunk])
	string panelTitle
	variable chunk

	variable length, first, last

	WAVE ITCDataWave = GetITCDataWave(panelTitle)
	WAVE TestPulseITC = GetTestPulseITCWave(panelTitle)
	length = TP_GetTestPulseLengthInPoints(panelTitle)

	if(ParamIsDefault(chunk))
		chunk = 0
	endif

	first = chunk * length
	last  = first + length
	ASSERT(first >= 0 && last < DimSize(ITCDataWave, ROWS), "Invalid wave subrange")

	Duplicate/O/R=[first, last][] ITCDataWave, TestPulseITC
	Redimension/Y=(GetRawDataFPType(panelTitle)) TestPulseITC
	SetScale/P x, 0, DimDelta(TestPulseITC, ROWS), "ms", TestPulseITC
	DM_ADScaling(TestPulseITC, panelTitle)
End

static Function DM_ADScaling(WaveToScale, panelTitle)
	wave WaveToScale
	string panelTitle

	variable startOfADColumns
	variable gain, i, numEntries, adc
	string ctrl

	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)
	WAVE ADCs = GetADCListFromConfig(ITCChanConfigWave)
	Wave ChannelClampMode = GetChannelClampMode(panelTitle)
	startOfADColumns = DimSize(GetDACListFromConfig(ITCChanConfigWave), ROWS)

	numEntries = DimSize(ADCs, ROWS)
	for(i = 0; i < numEntries; i += 1)
		adc = ADCs[i]

		ctrl = GetPanelControl(panelTitle, adc, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)
		gain = GetSetVariable(panelTitle, ctrl)

		if(ChannelClampMode[adc][1] == V_CLAMP_MODE || ChannelClampMode[adc][1] == I_CLAMP_MODE)
			// w' = w  / (g * s)
			gain *= 3200
			MultiThread WaveToScale[][(startOfADColumns + i)] /= gain
		endif
	endfor
end

static Function DM_DAScaling(WaveToScale, panelTitle)
	wave WaveToScale
	string panelTitle

	string ctrl
	variable gain, i, dac, numEntries
	DFREF deviceDFR       = GetDevicePath(panelTitle)
	Wave ChannelClampMode = GetChannelClampMode(panelTitle)
	WAVE/SDFR=deviceDFR ITCDataWave, ITCChanConfigWave
	WAVE DACs = GetDACListFromConfig(ITCChanConfigWave)

	numEntries = DimSize(DACs, ROWS)
	for(i = 0; i < numEntries ; i += 1)
		dac  = DACs[i]
		ctrl = GetPanelControl(panelTitle, dac, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)
		gain = GetSetVariable(panelTitle, ctrl)

		if(ChannelClampMode[dac][0] == V_CLAMP_MODE || ChannelClampMode[dac][0] == I_CLAMP_MODE)
			// w' = w * g / s
			gain /= 3200
			MultiThread WaveToScale[][i] *= gain
		endif
	endfor
end

Function DM_ReturnLastSweepAcquired(panelTitle)
	string panelTitle
	
	string list

	list = GetListOfWaves(GetDeviceDataPath(panelTitle), DATA_SWEEP_REGEXP, waveProperty="MINCOLS:2")
	return ItemsInList(list) - 1
End

/// @brief Delete all sweep and config waves having a sweep number
/// of `sweepNo` and higher
Function DM_DeleteDataWaves(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo

	string list, path, name
	variable i, numItems, waveSweepNo

	path  = GetDeviceDataPathAsString(panelTitle)
	list  = GetListOfWaves(GetDeviceDataPath(panelTitle), DATA_SWEEP_REGEXP, waveProperty="MINCOLS:2")
	list += GetListOfWaves(GetDeviceDataPath(panelTitle), DATA_CONFIG_REGEXP, waveProperty="MINCOLS:2")

	numItems = ItemsInList(list)
	for(i = 0; i < numItems; i += 1)
		name = StringFromList(i, list)
		waveSweepNo = ExtractSweepNumber(name)

		if(waveSweepNo < sweepNo)
			continue
		endif
		KillOrMoveToTrash(path + ":" + name)
	endfor
End

/// @brief Return the floating point type for storing the raw data
///
/// The returned values are the same as for `WaveType`
static Function GetRawDataFPType(panelTitle)
	string panelTitle

	return GetCheckboxState(panelTitle, "Check_Settings_UseDoublePrec") ? FLOAT_64BIT : FLOAT_32BIT
End
