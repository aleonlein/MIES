#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function ITC_DataAcq(DeviceType, DeviceNum, panelTitle)
	variable DeviceType, DeviceNum
	string panelTitle
	string cmd
	variable i = 0
	//variable StopCollectionPoint = (DC_CalculateITCDataWaveLength(panelTitle)/4 // + DC_ReturnTotalLengthIncrease(panelTitle)/4)
	variable ADChannelToMonitor = (DC_NoOfChannelsSelected("DA", "Check", panelTitle))
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	NVAR ITCDeviceIDGlobal = $WavePath + ":ITCDeviceIDGlobal"
	wave ITCDataWave = $WavePath + ":ITCDataWave", ITCFIFOAvailAllConfigWave = $WavePath + ":ITCFIFOAvailAllConfigWave"//, ChannelConfigWave, UpdateFIFOWave, RecordedWave
	variable stopCollectionPoint = ITC_CalcDataAcqStopCollPoint(panelTitle) // dimsize(ITCDataWave, 0) / 4
	string ITCDataWavePath = WavePath + ":ITCDataWave", ITCFIFOAvailAllConfigWavePath= WavePath + ":ITCFIFOAvailAllConfigWave"
	string ITCChanConfigWavePath = WavePath + ":ITCChanConfigWave"
	string ITCFIFOPositionAllConfigWavePth = WavePath + ":ITCFIFOPositionAllConfigWave"
	string oscilloscopeSubwindow = panelTitle + "#oscilloscope"
	string ResultsWavePath = WavePath + ":ResultsWave"
	make /O /I /N = 4 $ResultsWavePath 
	doupdate
	
	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	execute cmd
		
	sprintf cmd, "ITCconfigAllchannels, %s, %s" ITCChanConfigWavePath, ITCDataWavePath
	//print cmd
	execute cmd

	do

		sprintf cmd, "ITCUpdateFIFOPositionAll , %s" ITCFIFOPositionAllConfigWavePth // I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
		execute cmd// this also seems necessary to update the DA channel data to the board!!

		controlinfo /w =$panelTitle Check_DataAcq1_RepeatAcq
		variable RepeatedAcqOnOrOff = v_value
		if(RepeatedAcqOnOrOff == 1)
			ITC_StartITCDeviceTimer(panelTitle) // starts a timer for each ITC device. Timer is used to do real time ITI timing.
		endif

		sprintf cmd, "ITCStartAcq"// /f/r=0/z=0 -1,0,1,1"//   
		Execute cmd	
			do
				sprintf cmd, "ITCFIFOAvailableALL/z=0 , %s" ITCFIFOAvailAllConfigWavePath
				Execute cmd	
				ITCDataWave[0][0] += 0
				doupdate /w = $oscilloscopeSubwindow
				//doxopidle
			while (ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] < StopCollectionPoint)// 
		//Check Status
		sprintf cmd, "ITCGetState /R /O /C /E %s" ResultsWavePath
		Execute cmd
		sprintf cmd, "ITCStopAcq /z = 0"
		Execute cmd
		itcdatawave[0][0] += 0//runs arithmatic on data wave to force onscreen update 
		doupdate
		sprintf cmd, "ITCConfigChannelUpload /f /z = 0"//AS Long as this command is within the do-while loop the number of cycles can be repeated		
		Execute cmd
		i += 1
	while (i < 1)// 
	
	ControlInfo /w = $panelTitle Check_Settings_SaveData
	If(v_value == 0)
		DM_SaveITCData(panelTitle)
	endif
	
	 DM_ScaleITCDataWave(panelTitle)
End

//======================================================================================
Function ITC_BkrdDataAcq(DeviceType, DeviceNum, panelTitle)
	variable DeviceType, DeviceNum
	string panelTitle
	string cmd
	variable i = 0
	//variable /G StopCollectionPoint = (DC_CalculateITCDataWaveLength(panelTitle)/4) + DC_ReturnTotalLengthIncrease(panelTitle)
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	variable /G root:MIES:ITCDevices:ADChannelToMonitor = (DC_NoOfChannelsSelected("DA", "Check", panelTitle))
	string /G root:MIES:ITCDevices:panelTitleG = panelTitle
	doupdate
	
	wave ITCDataWave = $WavePath+ ":ITCDataWave"
	//variable /G root:MIES:ITCDevices:StopCollectionPoint = dimsize(ITCDataWave, 0) / 5 
	variable /G root:MIES:ITCDevices:StopCollectionPoint = ITC_CalcDataAcqStopCollPoint(panelTitle)
	wave ITCFIFOAvailAllConfigWave = $WavePath + ":ITCFIFOAvailAllConfigWave"//, ChannelConfigWave, UpdateFIFOWave, RecordedWave
	
	string ITCDataWavePath = WavePath + ":ITCDataWave", ITCFIFOAvailAllConfigWavePath = WavePath + ":ITCFIFOAvailAllConfigWave"
	string ITCChanConfigWavePath = WavePath + ":ITCChanConfigWave"
	string ITCFIFOPositionAllConfigWavePth = WavePath + ":ITCFIFOPositionAllConfigWave"
	// open ITC device
	
	//sprintf cmd, "ITCOpenDevice %d, %d", DeviceType, DeviceNum
		//Execute cmd	
	NVAR ITCDeviceIDGlobal = $WavePath + ":ITCDeviceIDGlobal"
	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	execute cmd	
		
	sprintf cmd, "ITCconfigAllchannels, %s, %s" ITCChanConfigWavePath, ITCDataWavePath
		execute cmd
	sprintf cmd, "ITCUpdateFIFOPositionAll , %s" ITCFIFOPositionAllConfigWavePth// I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
		execute cmd// this also seems necessary to update the DA channel data to the board!!
	
	
	controlinfo /w =$panelTitle Check_DataAcq1_RepeatAcq
	variable RepeatedAcqOnOrOff = v_value
	if(RepeatedAcqOnOrOff == 1)
		ITC_StartITCDeviceTimer(panelTitle) // starts a timer for each ITC device. Timer is used to do real time ITI timing.
	endif
	
	sprintf cmd, "ITCStartAcq" 
		Execute cmd	
	ITC_StartBckgrdFIFOMonitor()
	
	End
//======================================================================================
Function ITC_StopDataAcq()
	variable DeviceType, DeviceNum
	string cmd
	NVAR StopCollectionPoint = root:MIES:ITCDevices:StopCollectionPoint, ADChannelToMonitor = root:MIES:ITCDevices:StopCollectionPoint
	SVAR panelTitleG = root:MIES:ITCDevices:panelTitleG
	string WavePath = HSU_DataFullFolderPathString(PanelTitleG)
	wave ITCDataWave = $WavePath + ":ITCDataWave"
	string CountPath = WavePath + ":count"

	sprintf cmd, "ITCStopAcq /z = 0"
	Execute cmd

	itcdatawave[0][0] += 0//runs arithmatic on data wave to force onscreen update 
	doupdate
	
	sprintf cmd, "ITCConfigChannelUpload /f /z = 0"//AS Long as this command is within the do-while loop the number of cycles can be repeated		
	Execute cmd	
	
	//sprintf cmd, "ITCCloseAll" 
	//execute cmd
	
	ControlInfo /w = $panelTitleG Check_Settings_SaveData
	If(v_value == 0)
		DM_SaveITCData(panelTitleG)// saving always comes before scaling - there are two independent scaling steps
	endif
	
	 DM_ScaleITCDataWave(panelTitleG)
	if(exists(CountPath) == 0)//If the global variable count does not exist, it is the first trial of repeated acquisition
	controlinfo /w = $panelTitleG Check_DataAcq1_RepeatAcq
		if(v_value == 1)//repeated aquisition is selected
			RA_Start(PanelTitleG)
		else
			DAP_StopButtonToAcqDataButton(panelTitleG)
			NVAR /z DataAcqState = $wavepath + ":DataAcqState"
			DataAcqState = 0
		endif
	else
		//print "about to initiate RA_BckgTPwithCallToRACounter(panelTitleG)"
		RA_BckgTPwithCallToRACounter(panelTitleG)//FUNCTION THAT ACTIVATES BCKGRD TP AND THEN CALLS REPEATED ACQ XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
	endif
END
//======================================================================================

//======================================================================================
Function ITC_StartBckgrdFIFOMonitor()
	CtrlNamedBackground ITC_FIFOMonitor, period = 2, proc = ITC_FIFOMonitor
	CtrlNamedBackground ITC_FIFOMonitor, start
End

Function ITC_FIFOMonitor(s)
	STRUCT WMBackgroundStruct &s
	NVAR StopCollectionPoint = root:MIES:ITCDevices:StopCollectionPoint, ADChannelToMonitor = root:MIES:ITCDevices:ADChannelToMonitor
	SVAR panelTitleG = root:MIES:ITCDevices:panelTitleG
	String cmd
	string WavePath = HSU_DataFullFolderPathString(PanelTitleG)
	Wave ITCDataWave = $WavePath + ":ITCDataWave", ITCFIFOAvailAllConfigWave= $WavePath + ":ITCFIFOAvailAllConfigWave"
	string ITCFIFOAvailAllConfigWavePath = WavePath + ":ITCFIFOAvailAllConfigWave"
	sprintf cmd, "ITCFIFOAvailableALL /z = 0 , %s" ITCFIFOAvailAllConfigWavePath
	Execute cmd	
	ITCDataWave[0][0] += 0//forces on screen update
	string OscilloscopeSubWindow = panelTitleG + "#oscilloscope"
	doupdate /w = $OscilloscopeSubWindow
	if(ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] >= StopCollectionPoint)	
		print "stopped data acq"
		ITC_StopDataAcq()
		ITC_STOPFifoMonitor()
	endif
				
	return 0
End

Function ITC_STOPFifoMonitor()
CtrlNamedBackground ITC_FIFOMonitor, stop
End
//======================================================================================

Function ITC_StartBackgroundTimer(RunTimePassed,FunctionNameAPassedIn, FunctionNameBPassedIn,  FunctionNameCPassedIn, panelTitle)//Function name is the name of the function you want to run after run time has elapsed
	Variable RunTimePassed//how long you want the background timer to run in seconds
	String FunctionNameAPassedIn, FunctionNameBPassedIn, FunctionNameCPassedIn, panelTitle
	String /G root:MIES:ITCDevices:FunctionNameA = FunctionNameAPassedIn
	String /G root:MIES:ITCDevices:FunctionNameB = FunctionNameBPassedIn
	String /G root:MIES:ITCDevices:FunctionNameC = FunctionNameCPassedIn
	String /G root:MIES:ITCDevices:PanelTitleG = panelTitle
	Variable numTicks = 15		// Run every quarter second (15 ticks)
	Variable /G root:MIES:ITCDevices:Start = ticks
	Variable /G root:MIES:ITCDevices:RunTime = (RunTimePassed*60)
	CtrlNamedBackground ITC_Timer, period = 5, proc = ITC_Timer
	CtrlNamedBackground ITC_Timer, start
	
	If(RunTimePassed < 0)
		print "The time to configure the ITC device and the sweep time are greater than the user specified ITI"
		print "Data acquisition has not been interrupted but the actual ITI is longer than what was specified by:" + num2str(abs(RunTimePassed)) + "seconds"
	endif
End

Function ITC_Timer(s)
	STRUCT WMBackgroundStruct &s
	SVAR panelTitleG =  root:MIES:ITCDevices:panelTitleG
	NVAR Start = root:MIES:ITCDevices:Start, RunTime = root:MIES:ITCDevices:RunTime
	variable TimeLeft
	
	variable ElapsedTime = (ticks - Start)
	
	TimeLeft = abs(((RunTime - (ElapsedTime)) / 60))
	if(TimeLeft < 0)
		timeleft = 0
	endif
	ValDisplay valdisp_DataAcq_ITICountdown win = $panelTitleG, value = _NUM:TimeLeft
	
	if(ElapsedTime >= RunTime)
		ITC_StopBackgroundTimerTask()
	endif
	//printf "NextRunTicks %d", s.nextRunTicks
	return 0
End

Function ITC_StopBackgroundTimerTask()
	SVAR FunctionNameA = root:MIES:ITCDevices:FunctionNameA
	SVAR FunctionNameB = root:MIES:ITCDevices:FunctionNameB
	SVAR FunctionNameC = root:MIES:ITCDevices:FunctionNameC
	CtrlNamedBackground ITC_Timer, stop // had incorrect background procedure name
	Execute FunctionNameA
 	Execute FunctionNameB
	//Execute FunctionNameC
	//killvariables/z Start, RunTime
	//Killstrings/z FunctionNameA, FunctionNameB, FunctionNameC
End
//======================================================================================

Function ITC_StartBackgroundTestPulse(panelTitle)
	string panelTitle

	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	string /G root:MIES:ITCDevices:panelTitleG
	SVAR panelTitleG = root:MIES:ITCDevices:panelTitleG
	panelTitleG = panelTitle
	string cmd

	TP_ResetTPStorage(panelTitle)
	variable /G root:MIES:ITCDevices:StopCollectionPoint = DC_CalculateLongestSweep(panelTitle)
	variable /G root:MIES:ITCDevices:ADChannelToMonitor  = DC_NoOfChannelsSelected("DA", "Check", panelTitle)
	variable /G root:MIES:ITCDevices:BackgroundTPCount   = 0

	DoUpdate
	string  ITCDataWavePath = WavePath + ":ITCDataWave"
	string  ITCChanConfigWavePath = WavePath + ":ITCChanConfigWave"

	NVAR ITCDeviceIDGlobal = $WavePath + ":ITCDeviceIDGlobal"
	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	execute cmd
	
	sprintf cmd, "ITCconfigAllchannels, %s, %s" ITCChanConfigWavePath, ITCDataWavePath
	execute cmd

	CtrlNamedBackground TestPulse, period = 1, proc = ITC_TestPulseFunc
	CtrlNamedBackground TestPulse, start
End
//======================================================================================

///@brief Background execution function for the test pulse data acquisition
Function ITC_TestPulseFunc(s)
	STRUCT WMBackgroundStruct &s

	NVAR StopCollectionPoint = root:MIES:ITCDevices:StopCollectionPoint
	NVAR ADChannelToMonitor  = root:MIES:ITCDevices:ADChannelToMonitor
	NVAR BackgroundTPCount   = root:MIES:ITCDevices:BackgroundTPCount
	SVAR panelTitleG         = root:MIES:ITCDevices:PanelTitleG
	// create a copy as panelTitleG is killed in ITC_STOPTestPulse
	// but we still need it afterwards
	string panelTitle        = panelTitleG

	String cmd, Keyboard
	string WavePath = HSU_DataFullFolderPathString(panelTitle)

	string ITCFIFOPositionAllConfigWavePth = WavePath + ":ITCFIFOPositionAllConfigWave"
	string ITCFIFOAvailAllConfigWavePath = WavePath + ":ITCFIFOAvailAllConfigWave"
	Wave ITCFIFOAvailAllConfigWave = $ITCFIFOAvailAllConfigWavePath
	string ResultsWavePath = WavePath + ":ResultsWave"
	string CountPath = WavePath + ":count"

	sprintf cmd, "ITCUpdateFIFOPositionAll , %s" ITCFIFOPositionAllConfigWavePth // I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
	execute cmd // this also seems necessary to update the DA channel data to the board!!
	sprintf cmd, "ITCStartAcq"
	Execute cmd

	do
		sprintf cmd, "ITCFIFOAvailableALL /z = 0 , %s" ITCFIFOAvailAllConfigWavePath
		Execute cmd
	while (ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] < StopCollectionPoint)// 5000 IS CHOSEN AS A POINT THAT IS A BIT LARGER THAN THE OUTPUT DATA

	sprintf cmd, "ITCGetState /R /O /C /E %s" ResultsWavePath
	Execute cmd
	sprintf cmd, "ITCStopAcq /z = 0"
	Execute cmd
	sprintf cmd, "ITCConfigChannelUpload /f /z = 0"//AS Long as this command is within the do-while loop the number of cycles can be repeated
	Execute cmd
	DM_CreateScaleTPHoldingWave(panelTitle)
	TP_ClampModeString(panelTitle)
	TP_Delta(panelTitle, WavePath + ":TestPulse")

	BackgroundTPCount += 1

	if(mod(BackgroundTPCount,30) == 0 || BackgroundTPCount == 1)
		// debug output at every nth step
	endif

	if(!exists(countPath)) // uses the presence of a global variable that is created by the activation of repeated aquisition to determine if the space bar can turn off the TP
		Keyboard = KeyboardState("")
		if (cmpstr(Keyboard[9], " ") == 0)	// Is space bar pressed (note the space between the quotations)?
			beep
			ITC_STOPTestPulse(panelTitle)
			ITC_TPDocumentation(panelTitle) // documents the TP Vrest, peak and steady state resistance values. for manually terminated TPs
		endif
	endif

	return 0
End
//======================================================================================

Function ITC_STOPTestPulse(panelTitle)
	string panelTitle
	string cmd
	CtrlNamedBackground TestPulse, stop
	//sprintf cmd, "ITCCloseAll" 
	//execute cmd
//	ITC_TPDocumentation(panelTitle) // documents the TP Vrest, peak and steady state resistance values.
	controlinfo /w = $panelTitle check_Settings_ShowScopeWindow
	if(v_value == 0)
		DAP_SmoothResizePanel(-340, panelTitle)
		setwindow $panelTitle + "#oscilloscope", hide = 1
	endif

	DAP_RestoreTTLState(panelTitle)
	//killwaves /z root:MIES:WaveBuilder:SavedStimulusSets:DA:TestPulse// this line generates an error. hence the /z. not sure why.
	ControlInfo /w = $panelTitle StartTestPulseButton
	if(V_disable == 2) // 0 = normal, 1 = hidden, 2 = disabled, visible
		Button StartTestPulseButton, win = $panelTitle, disable = 0
	endif
	if(V_disable == 3) // 0 = normal, 1 = hidden, 2 = disabled, visible
		V_disable = V_disable & ~0x2
		Button StartTestPulseButton, win = $panelTitle, disable =  V_disable
	endif
	killvariables /z  StopCollectionPoint, ADChannelToMonitor, BackgroundTaskActive
	killstrings /z root:MIES:ITCDevices:PanelTitleG
End

static Constant DEFAULT_MAXAUTOBIASCURRENT = 500e-12 /// Unit: Amps
static Constant AUTOBIAS_INTERVALL_SECONDS = 2

/// @brief Handle automatic bias current injection
///
/// @param panelTitle	locked panel with test pulse running occasionally
/// @param BaselineSSAvg
/// @param SSResistance
Function ITC_ApplyAutoBias(panelTitle, BaselineSSAvg, SSResistance)
	string panelTitle
	Wave BaselineSSAvg, SSResistance

	variable headStage, entries, actualcurrent, current, targetVoltage, targetVoltageTol, setVoltage
	variable activeHeadStages
	variable resistance, maximumAutoBiasCurrent

	Wave TPStorage = GetTPStorage(panelTitle)
	variable lastInvocation = GetNumberFromWaveNote(TPStorage, AUTOBIAS_LAST_INVOCATION_KEY)
	variable curTime = ticks * TICKS_TO_SECONDS

	if( (curTime - lastInvocation) < AUTOBIAS_INTERVALL_SECONDS )
		return NaN
	endif

	DEBUGPRINT("ITC_ApplyAutoBias's turn, curTime=", var=curTime)
	SetNumberInWaveNote(TPStorage, AUTOBIAS_LAST_INVOCATION_KEY, curTime)

	if(isEmpty(panelTitle))
		DEBUGPRINT("Can't work with an empty panelTitle")
		return NaN
	endif

	Wave channelClampMode = GetChannelClampMode(panelTitle)
	Wave ampSettings      = GetAmplifierParamStorageWave(panelTitle)

	entries = DimSize(ampSettings, LAYERS)
	activeHeadStages = 0
	for(headStage=0; headStage < entries; headStage+=1)

		// From DAP_RemoveClampModeSettings and DAP_ApplyClmpModeSavdSettngs we know that
		// both wave entries are NaN iff the headstage is unset
		if(!IsFinite(channelClampMode[headStage][%DAC]) || !IsFinite(channelClampMode[headStage][%ADC]))
			continue
		endif

		activeHeadStages +=1

		// headStage channels not in current clamp mode
		if(channelClampMode[headStage][%DAC] != I_CLAMP_MODE && channelClampMode[headStage][%ADC] != I_CLAMP_MODE)
			continue
		endif

		// autobias not enabled
		if(!ampSettings[%AutoBiasEnable][0][headStage])
			continue
		endif

		DEBUGPRINT("current clamp mode set in headstage", var=headStage)

		maximumAutoBiasCurrent = abs(ampSettings[%AutoBiasIbiasmax][0][headStage] * 1e-12)
		if(maximumAutoBiasCurrent == 0 || maximumAutoBiasCurrent > DEFAULT_MAXAUTOBIASCURRENT)
			printf "Warning for headStage %d: replacing invalid maximum auto bias currrent of %g with %g\r", headStage, maximumAutoBiasCurrent, DEFAULT_MAXAUTOBIASCURRENT
			maximumAutoBiasCurrent = DEFAULT_MAXAUTOBIASCURRENT
		endif

		/// all variables holding physical units use plain values without prefixes
		/// e.g Amps instead of pA

		targetVoltage    = ampSettings[%AutoBiasVcom][0][headStage] * 1e-3
		targetVoltageTol = ampSettings[%AutoBiasVcomVariance][0][headStage] * 1e-3

		resistance = SSResistance[0][activeHeadStages - 1] * 1e6
		setVoltage = BaselineSSAvg[0][activeHeadStages - 1] * 1e-3

		DEBUGPRINT("resistance=", var=resistance)
		DEBUGPRINT("setVoltage=", var=setVoltage)
		DEBUGPRINT("targetVoltage=", var=targetVoltage)

		// if we are in the desired voltage region, check the next headstage
		if(abs(targetVoltage - setVoltage) < targetVoltageTol)
			continue
		endif

		// neuron needs a current shot
		// I = U / R
		current = ( targetVoltage - setVoltage ) / resistance
		DEBUGPRINT("current=", var=current)
		// only use part of the calculated current, as BaselineSSAvg holds
		// an overestimate for small buffer sizes
		current *= 0.20

		actualCurrent = AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_GETHOLDING_FUNC, NaN)
		DEBUGPRINT("actualCurrent=", var=actualCurrent)

		if(!IsFinite(actualCurrent))
			print "Queried amplifier current is non-finite"
			continue
		endif

		current += actualCurrent

		if( abs(current) > maximumAutoBiasCurrent)
			printf "Not applying autobias current shot of %gA as that would exceed the maximum allowed current of %gA\r", current, maximumAutoBiasCurrent
			continue
		endif

		DEBUGPRINT("current to send=", var=current)
		AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_SETHOLDINGENABLE_FUNC, 1)
		AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_SETHOLDING_FUNC, current)
	endfor
End

//ITC_StartBackgroundTestPulse();ITC_StartBackgroundTimer(20, "ITC_STOPTestPulse()")  This line of code starts the tests pulse and runs it for 20 seconds

Function ITC_StartTestPulse(DeviceType, DeviceNum, panelTitle)
	variable DeviceType, DeviceNum
	string panelTitle

	string cmd
	variable i = 0
	variable StopCollectionPoint = DC_CalculateLongestSweep(panelTitle)
	variable ADChannelToMonitor = (DC_NoOfChannelsSelected("DA", "Check", panelTitle))

	string oscilloscopeSubWindow = panelTitle + "#oscilloscope"

	TP_ResetTPStorage(panelTitle)
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	string ITCChanConfigWavePath = WavePath + ":ITCChanConfigWave"
	string ITCDataWavePath = WavePath + ":ITCDataWave"
	wave ITCFIFOAvailAllConfigWave = $WavePath+ ":ITCFIFOAvailAllConfigWave"//, ChannelConfigWave, UpdateFIFOWave, RecordedWave
	string ITCFIFOAvailAllConfigWavePath = WavePath+ ":ITCFIFOAvailAllConfigWave"
	
	string ITCFIFOPositionAllConfigWavePth = WavePath + ":ITCFIFOPositionAllConfigWave"
	
	string ResultsWavePath = WavePath + ":ResultsWave"
	
	string Keyboard

	make /O /I /N = 4 $ResultsWavePath 
	doupdate
	
	NVAR ITCDeviceIDGlobal = $WavePath + ":ITCDeviceIDGlobal"
	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	execute cmd
	
	sprintf cmd, "ITCconfigAllchannels, %s, %s" ITCChanConfigWavePath, ITCDataWavePath
	execute cmd
	do
		// I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
		// this also seems necessary to update the DA channel data to the board!!
		sprintf cmd, "ITCUpdateFIFOPositionAll , %s" ITCFIFOPositionAllConfigWavePth
		execute cmd
		sprintf cmd, "ITCStartAcq"
		Execute cmd

		do
			sprintf cmd, "ITCFIFOAvailableALL /z = 0 , %s" ITCFIFOAvailAllConfigWavePath
			Execute cmd
		while (ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] < StopCollectionPoint)

		sprintf cmd, "ITCGetState /R /O /C /E %s" ResultsWavePath
		Execute cmd
		sprintf cmd, "ITCStopAcq /z = 0"
		Execute cmd
		DM_CreateScaleTPHoldingWave(panelTitle)
		TP_ClampModeString(panelTitle)
		TP_Delta(panelTitle, WavePath + ":TestPulse") 
		doupdate
		sprintf cmd, "ITCConfigChannelUpload /f /z = 0"//AS Long as this command is within the do-while loop the number of cycles can be repeated		
		Execute cmd
		if(mod(i, 50) == 0)
			ModifyGraph /w = $oscilloscopeSubWindow Live = 0
			ModifyGraph /w = $oscilloscopeSubWindow Live = 1
		endif
		i += 1	
		Keyboard = KeyboardState("")
	while (cmpstr(Keyboard[9], " ") != 0)
	
	DAP_RestoreTTLState(panelTitle)
	ITC_TPDocumentation(panelTitle)
	EnableControl(panelTitle,"StartTestPulseButton")
END
//======================================================================================

Function ITC_SingleADReading(Channel, panelTitle)//channels 16-23 are asynch channels on ITC1600
	variable Channel
	string panelTitle
	variable ChannelValue
	string cmd
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	make /o /n = 1 $WavePath + ":AsyncChannelData"
	string AsyncChannelDataPath = WavePath+":AsyncChannelData"
	wave AsyncChannelData = $AsyncChannelDataPath
	sprintf cmd, "ITCReadADC /V = 1 %d, %s" Channel, AsyncChannelDataPath
	execute cmd
	ChannelValue = AsyncChannelData[0]
	//print channelValue
	killwaves /f AsyncChannelData
	return ChannelValue
End 

//======================================================================================

Function ITC_ADDataBasedWaveNotes(DataWave, DeviceType, DeviceNum,panelTitle)
	Wave DataWave
	variable DeviceType, DeviceNum
	string panelTitle
	// This function takes about 0.9 seconds to run
	// this is the wave that the note gets appended to. The note contains the async ad channel value and info
	//variable starttime=ticks
	string AsyncChannelState = DC_ControlStatusListString("AsyncAD", "check", panelTitle)
	variable i
	variable TotAsyncChannels = itemsinlist(AsyncChannelState,";")
	variable RawChannelValue
	string cmd
	string SetVar_Title, Title
	string SetVar_gain, Measurement
	string SetVar_Unit, Unit
	string WaveNote = ""
	
	controlinfo /w = $panelTitle popup_MoreSettings_DeviceType // "ITC16" (0), "ITC18" (1), "ITC1600" (2), "ITC00" (3), "ITC16USB" (4), "ITC18USB" (5) 
	DeviceType = v_value - 1
	variable DeviceChannelOffset // used to select asych ad channels on itc 1600 and standard ad channels on other itc devices.
	If(DeviceType == 2)
		DeviceChannelOffset = 15
	else
		DeviceChannelOffset = 0
	endif
	
	// sprintf cmd, "ITCOpenDevice %d, %d", DeviceType, DeviceNum
	// Execute cmd	
	
	do
		if(str2num(stringfromlist(i, AsyncChannelState,";")) == 1)
		RawChannelValue=ITC_SingleADReading(i +DeviceChannelOffset, panelTitle)//Async channels start at channel 16 on ITC 1600, needs to be a diff value constant for ITC18
		
			if(i < 10)
				 SetVar_title = "SetVar_Async_Title_0" + num2str(i)
				 SetVar_gain = "SetVar_AsyncAD_Gain_0" + num2str(i)
				 SetVar_Unit = "SetVar_Async_Unit_0" + num2str(i)
			else
				 SetVar_title = "SetVar_Async_Title_" + num2str(i)
				 SetVar_gain = "SetVar_AsyncAD_Gain_" + num2str(i)
				 SetVar_Unit = "SetVar_Async_Unit_" + num2str(i)
			endif 
			
			controlInfo /w = $panelTitle $SetVar_title
			title = s_value
			controlInfo /w = $panelTitle $SetVar_gain
			Measurement = num2str(RawChannelValue / v_value)//(v_value * RawChannelValue)
			ITC_SupportSystemAlarm(i, v_value * RawChannelValue, title, panelTitle)
			controlInfo /w = $panelTitle $SetVar_Unit
			Unit = s_value
			WaveNote = title + " " + Measurement + " " + Unit
			note DataWave, WaveNote
		endif
		i += 1 
	while(i < TotAsyncChannels)
	
	// sprintf cmd, "ITCCloseAll" 
	// execute cmd
	//print (ticks - starttime) / 60

End
//======================================================================================
Function ITC_SupportSystemAlarm(Channel, Measurement, MeasurementTitle, panelTitle)
variable Channel, Measurement
string MeasurementTitle, panelTitle
String CheckAlarm, SetVarTitle, SetVarMin, SetVarMax, Title
variable ParamMin, ParamMax

if(channel < 10)
	CheckAlarm = "check_Async_Alarm_0" + num2str(channel)
	SetVarMin = "setvar_Async_min_0" + num2str(channel)	
	SetVarMax = "setvar_Async_max_0" + num2str(channel)	
else
	CheckAlarm = "check_Async_Alarm_" + num2str(channel)
	SetVarMin = "setvar_Async_min_" + num2str(channel)				
	SetVarMax = "setvar_Async_max_" + num2str(channel)
endif

ControlInfo /W = $panelTitle $CheckAlarm
if(v_value == 1)
	ControlInfo /W = $panelTitle $SetVarMin
	ParamMin = v_value
	ControlInfo /W = $panelTitle $SetVarMax
	ParamMax = v_value
	print measurement
	if(Measurement >= ParamMax || Measurement <= ParamMin)
		beep
		print time() + " !!!!!!!!!!!!! " + MeasurementTitle + " has exceeded max/min settings" + " !!!!!!!!!!!!!"
		beep
	endif
endif

End
//======================================================================================

Function ITC_CalcDataAcqStopCollPoint(panelTitle) // calculates the stop colleciton point, includes global adjustments to set on and off set.
	string panelTitle
	variable stopCollectionPoint
	Variable LongestSweep = DC_CalculateLongestSweep(panelTitle) // returns longest sweep in points - accounts for sampling interval
	Variable GobalOnsetOffsetSum = DC_ReturnTotalLengthIncrease(panelTitle)
	stopCollectionPoint = LongestSweep + GobalOnsetOffsetSum
	return stopCollectionPoint
End

//======================================================================================

Function ITC_ZeroITCOnActiveChan(panelTitle) // sets active DA channels to Zero - used after TP MD
	string panelTitle // function operates on active device - does not check to see if a device is open.
	string WavePath
	sprintf WavePath, "%s" HSU_DataFullFolderPathString(panelTitle)
	string DAChannelStatusList  =""
	sprintf  DAChannelStatusList, "%s" DC_ControlStatusListString("DA", "check", panelTitle)
	string cmd
	variable NoOfDAChannels = itemsinList(DAChannelStatusList, ";")
	variable i
	
	for(i = 0; i < NoOfDAChannels; i += 1)
		if(str2num(stringfromlist(i, DAChannelStatusList)) == 1)
			sprintf cmd, "ITCSetDAC /z = 0 %d, 0" i 
			Execute cmd
		endif
	endfor

END
