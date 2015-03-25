#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "tango"

static StrConstant amPanel = "analysisMaster"

Menu "Mies Panels"
		"Start Polling WSE queue", StartTestTask()
		"Stop Polling WSE queue", StopTestTask()
End

Function writeLog(logMessage)
	String logMessage
	
	//- function arg: the name of the device on which the commands will be executed 
	String dev_name = "logger_device/LoggerDevice/test"
	
	//- verbose
	print "\rStarting <Tango-API::tango_cmd_io> test...\r"
  
	//- let's declare our <argin> and <argout> structures. 
	//- be aware that <argout> will be overwritten (and reset) each time we execute a 
	//- command it means that you must use another <CmdArgOut> if case you want to 
	//- store more than one command result at a time. here we reuse both argin and 
	//- argout for each command.

	//- argin
	Struct CmdArgIO argin
	tango_init_cmd_argio (argin)
	
	//- argout 
	Struct CmdArgIO argout
	tango_init_cmd_argio (argout)
	
	//- populate argin: <CmdArgIn.cmd> struct member
	//- name of the command to be executed on <argin.dev> 
	String cmd = "log"

	//- verbose
	print "\rexecuting <" + cmd + ">...\r"
  
	//- since the command argin is a string scalar (i.e. single string), we stored its its value 
	//- into the <str> member of the <CmdArgIn> structure. 
	argin.str_val = logMessage
  
	Variable mst_ref = StartMSTimer
  
	Variable mst_dt  
	//- actual cmd execution
	//- if an error occurs during command execution, argout is undefined (null or empty members)
	//- ALWAYS CHECK THE CMD RESULT BEFORE TRYING TO ACCESS ARGOUT: 0 means NO_ERROR, -1 means ERROR
	if (tango_cmd_inout(dev_name, cmd, arg_in = argin, arg_out = argout) == -1)
		//- the cmd failed, display error...
		tango_display_error()
		//- ... then return error
		mst_dt = StopMSTimer(mst_ref)		
		return kERROR
	endif
  
	mst_dt = StopMSTimer(mst_ref)
	print "\t'-> took " + num2str(mst_dt / 1000) + " ms to complete"
	
	//- <argout> is populated (i.e. filled) by <tango_cmd_inout> uppon return of the command.
	//- since the command ouput argument is a string scalar (i.e. single string), it is stored 
	//- in the <str> member of the <CmdArgOut> structure.

	//- as previously explained, we are testing our TANGO binding on a TangoTest device. 
	//- consequently, we check that <argin.str == argout.str> in order to be sure that everything is ok
//	if (cmpstr(argin.str_val, argout.str_val) != 0)
//		//- the cmd failed, display error...
//		tango_display_error_str("ERROR:DevString:unexpected cmd result - aborting test")
//		//- ... then return error
//		return kERROR
//	endif
  
	//- verbose
	print "\t'-> cmd passed\r"
	
End

Function initLog(dev)
	//- function arg: the name of the device on which the commands will be executed 
	String dev
	
  
	//- verbose
	print "\rStarting <Tango-API::tango_cmd_io> test...\r"
  
	//- let's declare our <argin> and <argout> structures. 
	//- be aware that <argout> will be overwritten (and reset) each time we execute a 
	//- command it means that you must use another <CmdArgOut> if case you want to 
	//- store more than one command result at a time. here we reuse both argin and 
	//- argout for each command.

	//- argin
	Struct CmdArgIO argin
	tango_init_cmd_argio (argin)
	
	//- argout 
	Struct CmdArgIO argout
	tango_init_cmd_argio (argout)
	
	//- populate argin: <CmdArgIn.cmd> struct member
	//- name of the command to be executed on <argin.dev> 
	String cmd = "Init"

	//- verbose
	print "\rexecuting <" + cmd + ">...\r"
  
	//- since the command argin is a string scalar (i.e. single string), we stored its its value 
	//- into the <str> member of the <CmdArgIn> structure. 
	argin.str_val = "hello world"
  
	Variable mst_ref = StartMSTimer
  
  	Variable mst_dt
	//- actual cmd execution
	//- if an error occurs during command execution, argout is undefined (null or empty members)
	//- ALWAYS CHECK THE CMD RESULT BEFORE TRYING TO ACCESS ARGOUT: 0 means NO_ERROR, -1 means ERROR
	if (tango_cmd_inout(dev, cmd, arg_in = argin, arg_out = argout) == -1)
		//- the cmd failed, display error...
		tango_display_error()
		//- ... then return error
		mst_dt = StopMSTimer(mst_ref)
		return kERROR
	endif
  
	mst_dt = StopMSTimer(mst_ref)
	print "\t'-> took " + num2str(mst_dt / 1000) + " ms to complete"
	
	//- <argout> is populated (i.e. filled) by <tango_cmd_inout> uppon return of the command.
	//- since the command ouput argument is a string scalar (i.e. single string), it is stored 
	//- in the <str> member of the <CmdArgOut> structure.

	//- as previously explained, we are testing our TANGO binding on a TangoTest device. 
	//- consequently, we check that <argin.str == argout.str> in order to be sure that everything is ok
//	if (cmpstr(argin.str_val, argout.str_val) != 0)
//		//- the cmd failed, display error...
//		tango_display_error_str("ERROR:DevString:unexpected cmd result - aborting test")
//		//- ... then return error
//		return kERROR
//	endif
  
	//- verbose
	print "\t'-> cmd passed\r"
	
End

Function readImage(dev_name)
//- function arg: the name of the device on which the attributes will be read
	String dev_name
  
	//- verbose
	print "\rStarting <Tango-API::tango_read_attr> test...\r"
  
   	//- create a root:tmp datafolder and make it the current datafolder
  	//- this function is kind enough to create all the datafolders along
  	//- the speciifed path in case they don't exist. great, isn't it?
  	tools_df_make("root:tmp", 1)
  	
	//- let's declare our <AttributeValue> structure. 
	//- be aware that <av> will be overwritten (and reset) each time we read
	//- an attribute. it means that you must use another <AttributeValue> if case 
	//- you want to store more than one attribue value at a time. here we reuse 
	//- <av> for each attribute reading 
	Struct AttributeValue av
  
	//- for 'technical reasons', the AttributeValue must be initialized 
	//- this ensures that everything is properly setup 
	tango_init_attr_val(av)
  
	//- populate attr_val: <dev> struct member
	//- the name of the device on which the attribute will be read
	//- NB: since the attributes will be read on the same device (i.e. dev_name), 
	//- we set the <AttributeValue.dev> struct member only once (i.e. no need to 
	//- set it not each time we read a attribute)  
	av.dev = dev_name
	
	av.attr = "image"
	av.val_path=""
	Variable mst_ref = StartMSTimer 
	Variable mst_dt
	if (tango_read_attr (av) == -1)
		tango_display_error()
		mst_dt = StopMSTimer(mst_ref)
		return kERROR
	endif
 	mst_dt = StopMSTimer(mst_ref)
	tango_dump_attribute_value (av)
	print "\t-read took......." + num2str(mst_dt / 1000) + " ms to complete"
	
		//- no error - great!
	print "\r<Tango-API::tango_read_attr> : TEST PASSED\r"
	
	//- for test purpose will delete any datafolder created in this function
	//tools_df_delete("root:tmp")
	
	return kNO_ERROR
end

Function throwError(dev_name)
	String dev_name
	
	//- verbose
	print "\rStarting <Tango-API::tango_cmd_io> test...\r"
  
	//- let's declare our <argin> and <argout> structures. 
	//- be aware that <argout> will be overwritten (and reset) each time we execute a 
	//- command it means that you must use another <CmdArgOut> if case you want to 
	//- store more than one command result at a time. here we reuse both argin and 
	//- argout for each command.

	//- argin
	Struct CmdArgIO argin
	tango_init_cmd_argio (argin)
	
	//- argout 
	Struct CmdArgIO argout
	tango_init_cmd_argio (argout)
	
	//- populate argin: <CmdArgIn.cmd> struct member
	//- name of the command to be executed on <argin.dev> 
	String cmd = "throw"

	//- verbose
	print "\rexecuting <" + cmd + ">...\r"
  
	//- since the command argin is a string scalar (i.e. single string), we stored its its value 
	//- into the <str> member of the <CmdArgIn> structure. 
	argin.str_val = "Invalid Mies command"
  
	Variable mst_ref = StartMSTimer
  	Variable mst_dt
  	
	//- actual cmd execution
	//- if an error occurs during command execution, argout is undefined (null or empty members)
	//- ALWAYS CHECK THE CMD RESULT BEFORE TRYING TO ACCESS ARGOUT: 0 means NO_ERROR, -1 means ERROR
	if (tango_cmd_inout(dev_name, cmd, arg_in = argin, arg_out = argout) == -1)
		//- the cmd failed, display error...
		tango_display_error()
		//- ... then return error
		mst_dt = StopMSTimer(mst_ref)
		return kERROR
	endif
  
	mst_dt = StopMSTimer(mst_ref)
	print "\t'-> took " + num2str(mst_dt / 1000) + " ms to complete"
	
	//- <argout> is populated (i.e. filled) by <tango_cmd_inout> uppon return of the command.
	//- since the command ouput argument is a string scalar (i.e. single string), it is stored 
	//- in the <str> member of the <CmdArgOut> structure.

	//- as previously explained, we are testing our TANGO binding on a TangoTest device. 
	//- consequently, we check that <argin.str == argout.str> in order to be sure that everything is ok
//	if (cmpstr(argin.str_val, argout.str_val) != 0)
//		//- the cmd failed, display error...
//		tango_display_error_str("ERROR:DevString:unexpected cmd result - aborting test")
//		//- ... then return error
//		return kERROR
//	endif
  
	//- verbose
	print "\t'-> throw cmd passed\r"
	
End	

Function readSequenceQueue(dev_name)
	String dev_name
	
	//-verbose
	print "\rStarting Tango based interface to Sequencing Queue...\r"

	//- argin
	Struct CmdArgIO argin
	tango_init_cmd_argio (argin)
	
	//- argout 
	Struct CmdArgIO argout
	tango_init_cmd_argio (argout)	
	
	//- populate argin: <CmdArgIn.cmd> struct member
	//- name of the command to be executed on <argin.dev> 
	String cmd = "get"

	//- verbose
	print "\rexecuting <" + cmd + ">...\r"
  
	//- since the command argin is a string scalar (i.e. single string), we stored its its value 
	//- into the <str> member of the <CmdArgIn> structure. 
	argin.str_val = "hello world"
  
	Variable mst_ref = StartMSTimer
	Variable mst_dt
	
	//- actual cmd execution
	//- if an error occurs during command execution, argout is undefined (null or empty members)
	//- ALWAYS CHECK THE CMD RESULT BEFORE TRYING TO ACCESS ARGOUT: 0 means NO_ERROR, -1 means ERROR
	if (tango_cmd_inout(dev_name, cmd, arg_in = argin, arg_out = argout) == -1)
		//- the cmd failed, display error...
		print "cmd failed..."
		tango_display_error()
		//- ... then return error
		mst_dt = StopMSTimer(mst_ref)
		return kERROR
	endif
  
	mst_dt = StopMSTimer(mst_ref)
	print "\t'-> took " + num2str(mst_dt / 1000) + " ms to complete"
	
	//- <argout> is populated (i.e. filled) by <tango_cmd_inout> uppon return of the command.
	//- since the command ouput argument is a string scalar (i.e. single string), it is stored 
	//- in the <str> member of the <CmdArgOut> structure.

	//- as previously explained, we are testing our TANGO binding on a TangoTest device. 
	//- consequently, we check that <argin.str == argout.str> in order to be sure that everything is ok
	
	print "Command found: " + argout.str_val
	string cmdToRun = argout.str_val

	if (cmpStr(cmdToRun, "NONE") == 1)
		print "No Mies command found on Messaging queue..."
	else
		Execute/Z cmdToRun
		if (V_Flag != 0)
			print "Unable to run command....check command syntax..."
			throwError("mies_device/MiesDevice/test")
			writeLog("improper Mies Command requested...")
		else
			print "Command ran successfully..."
			writeLog("Mies command ran successfully....")
		endif
	endif
	
//	if (cmpstr(argin.str_val, argout.str_val) != 0)
//		//- the cmd failed, display error...
//		print "cmd failed...display error"
//		tango_display_error_str("ERROR:DevString:unexpected cmd result - aborting test")
//		//- ... then return error
//		return kERROR
//	endif
  
	//- verbose
	print "\t'-> cmd passed\r"
	
End

/// @brief function for recieving the command strings from the WSE
/// the format is "cmd_id:<id>;<cmd_string>"
Function TangoCommandInput(cmdString)
	string cmdString
	
	// parse out the cmd_id from the input cmdString
	variable cmdNumber
	variable cmdID
	string cmdPortion
	string igorCmd
	cmdNumber = ItemsInList(cmdString)
	
	// the first portion of the cmdString should be the "cmd_id:<id>"
	cmdPortion = StringFromList(0, cmdString)
	// now parse out the cmd_id
	sscanf cmdPortion, "cmd_id:%d", cmdID
	
	print "cmdID: ", cmdID
	
	// the second portion of the cmdString should be the "cmd_string"
	igorCmd = StringFromList(1, cmdString)
	print "igorCmd: ", igorCmd
	// now strip the trailing ")" off the end of the igorCmd
	string igorCmdPortion = StringFromList(0, igorCmd, ")")
	print "igorCmdPortion: ", igorCmdPortion
	// and append the cmdNumber and the trailing ")"
	string completeIgorCommand
	sprintf completeIgorCommand, "%s, cmdID=%d)", igorCmdPortion, cmdID
	
	print "completeIgorCommand: ", completeIgorCommand
	// now call the command 
	Execute/Z completeIgorCommand
	if (V_Flag != 0)
		print "Unable to run command....check command syntax..."
		writeAck(cmdID, -1)
	else
		print "Command ran successfully..."
//		writeLog("Mies command ran successfully....")
	endif
End	
	
Function sequenceTask(s)											// This is the function that will be called periodically
	STRUCT WMBackgroundStruct &s
	
	Printf "Task %s called, ticks=%d\r", s.name, s.curRunTicks
	readSequenceQueue("mies_device/MiesDevice/test")
	return 0	// Continue background task
End

Function StartTestTask()
	Variable numTicks = 10 * 60		// Run every ten seconds (600 ticks)
	CtrlNamedBackground Test, period=numTicks, proc=sequenceTask
	CtrlNamedBackground Test, start
End

Function StopTestTask()
	print "Ending polling task..."
	CtrlNamedBackground Test, stop
End

/// @brief Save Mies Experiment as a packed experiment
Function TangoSave(saveFileName, [cmdID])
	string saveFileName
	variable cmdID
	
	//save as packed experiment
	SaveExperiment/C/F={1,"",2}/P=home as saveFileName + ".pxp"
	print "Packed Experiment Save Success!"
	
	// determine if the cmdID was provided
	if (ParamIsDefault(cmdID) == 0)
		writeAck(cmdID, 1)
	endif
End

///@brief routine to be called from the WSE to select a stimWaveName, a PSA routine, a PAA routine, the scale factor, the ap threshold level, and which
/// headstage will be used
Function/S TI_runAdaptiveStim(stimWaveName, initScaleFactor, scaleFactor, threshold, headstage, [cmdID])
	string stimWaveName
	variable initScaleFactor
	variable scaleFactor
	variable headstage
	variable threshold
	string cmdID
	
	// save the present data folder
	string savedDataFolder = GetDataFolder(1)
	
	// get the da_ephys panel names
	string lockedDevList = DAP_ListOfLockedDevs()
	variable noLockedDevs = ItemsInList(lockedDevList)
	
	variable n
	for (n = 0; n<noLockedDevs; n+= 1)
		string currentPanel = StringFromList(n, lockedDevList)
	
		// structure needed for communicating with the start acquisition button on the DA_Ephys panel
		STRUCT WMButtonAction ba
		
		// pop the itc panel window to the front
		DoWindow /F $currentPanel
		
		Wave actionScaleSettingsWave = GetActionScaleSettingsWaveRef(currentPanel)
		Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(currentPanel)
		
		// put the scaleDelta in the  actionscalesettings wave
		actionScaleSettingsWave[headStage][%scaleValue] = scaleFactor
		// reset the result value before starting the cycle
		actionScaleSettingsWave[headStage][%result] = 0
		
		// push the waveSet to the ephys panel
		// first, build up the control name by using the headstage value
		string waveSelect 
		string psaMenu
		string paaMenu
		string psaCheck
		string paaCheck
		string scaleWidgetName
		
		sprintf waveSelect, "Wave_DA_%02d", headstage
		sprintf psaMenu, "PSA_headStage%d", headstage
		sprintf paaMenu, "PAA_headStage%d", headstage
		sprintf psaCheck, "headStage%d_postSweepAnalysisOn", headstage
		sprintf paaCheck, "headStage%d_postAnalysisActionOn", headstage
		sprintf scaleWidgetName, "Scale_DA_%02d", headStage
		
		string FolderPath
		string folder
		string ListOfWavesInFolder
		
		// build up the list of available wave sets
		FolderPath = GetWBSvdStimSetDAPathAsString()
		folder = "*DA*"
		setdatafolder FolderPath // sets the wavelist for the DA popup menu to show all waves in DAC folder
		ListOfWavesInFolder = Wavelist(Folder,";","") 
		
		// make sure that the incoming StimWaveName is a valid wave name
		if (FindListItem(StimWaveName, ListOfWavesInFolder) == -1)
			print "Not a valid wave selection...please try again..."
			return "RETURN: -1"
		endif
		
		// now find the index of the selected incoming wave in that list
		variable incomingWaveIndex = WhichListItem(StimWaveName, ListOfWavesInFolder, ";")
		
		// and now set the wave popup menu to that index
		// have to add 2 since the pulldown always has -none- and TestPulse as options
		SetPopupMenuIndex(currentPanel, waveSelect, incomingWaveIndex + 2)  
	
		// push the PSA_waveName into the right place
		// find the index for for the psa routine 
		// do this if the window actually exists
		ASSERT(WindowExists(amPanel), "Analysis master panel must exist")

		string psaFuncList = AM_PS_sortFunctions()
		variable psaFuncIndex	 = WhichListItem("returnActionPotential", psaFuncList)
		SetPopupMenuIndex("analysisMaster", psaMenu, psaFuncIndex)
		
		// push the PAA_waveName into the right place
		// find the index for for the psa routine
		string paaFuncList = AM_PA_sortFunctions()
		variable paaFuncIndex = WhichListItem("adjustScaleFactor", paaFuncList, ";")
		SetPopupMenuIndex("analysisMaster", paaMenu, paaFuncIndex)
	
		// do the on/off check boxes for consistency
		SetCheckBoxState("analysisMaster", psaCheck, 1)
		SetCheckBoxState("analysisMaster", paaCheck, 1)

		
		// insure that the on/off parts of analysisSettingsWave are on...
		analysisSettingsWave[headstage][%PSAOnOff] = "1"
		analysisSettingsWave[headstage][%PAAOnOff] = "1"
		
		// and put the full psa function into the analysisSettingsWave...putting it as the correct item into the popmenu widget doesn't push it into wave
		analysisSettingsWave[headstage][%PSAType] = "returnActionPotential"
		analysisSettingsWave[headstage][%PAAType] = "adjustScaleFactor"
		
		// turn on the repeated acquisition
		SetCheckBoxState(currentPanel, "Check_DataAcq1_RepeatAcq", 1)
		
		// put the delta in the right place 
		actionScaleSettingsWave[headstage][%scaleValue] = scaleFactor
		
		// put the threshold value in the right place
		actionScaleSettingsWave[headstage][%apThreshold] = threshold
		
		// make sure the analysisResult is set to 0
		analysisSettingsWave[headstage][%PSAResult] = num2str(0)
		
		// put the init Scale factor where it needs to go
		SetSetVariable(currentPanel, scaleWidgetName, initScaleFactor)
		
		// now start the sweep process
		print "pushing the start button..."
		// now start the sweep process
		// setting the ba structure
		ba.eventCode = 2
		ba.ctrlName = "DataAcquireButton"
		ba.win = currentPanel
		
		DAP_ButtonProc_AcquireData(ba)
		
		// and then return the scale value
		print "returning the actionPotential factor..." 
		variable firedActionPotentialScale = str2num(analysisSettingsWave[headstage][%PSAResult])
		print "firedActionPotentialScale: ", firedActionPotentialScale
	endfor
	
	 // restore the data folder
	SetDataFolder savedDataFolder
	
	return "RETURN:1"
End

///@brief routine to be called from the WSE to select a stimWaveName, a PSA routine(returnActionPotential), a PAA routine(bracketScaleFactor), the coarse scale adjustment factor, 
/// the fine scale adjustment factor, the ap threshold level, and which headstage will be used
Function/S TI_runBracketingFunction(stimWaveName, coarseScaleFactor, fineScaleFactor, threshold, headstage, [cmdID])
	string stimWaveName
	variable coarseScaleFactor
	variable fineScaleFactor
	variable threshold
	variable headstage
	string cmdID
	
	// save the present data folder
	string savedDataFolder = GetDataFolder(1)
	
	// get the da_ephys panel names
	string lockedDevList = DAP_ListOfLockedDevs()
	variable noLockedDevs = ItemsInList(lockedDevList)
	
	variable n
	for (n = 0; n<noLockedDevs; n+= 1)
		string currentPanel = StringFromList(n, lockedDevList)
	
		// structure needed for communicating with the start acquisition button on the DA_Ephys panel
		STRUCT WMButtonAction ba
		
		// pop the itc panel window to the front
		DoWindow /F $currentPanel
		
		Wave actionScaleSettingsWave = GetActionScaleSettingsWaveRef(currentPanel)
		Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(currentPanel)
		
		// put the coarse scale factor in the  actionscalesettings wave
		actionScaleSettingsWave[headStage][%coarseScaleValue] = coarseScaleFactor
		// put the fine scale factor in the  actionscalesettings wave
		actionScaleSettingsWave[headStage][%fineScaleValue] = coarseScaleFactor
		// put the threshold in the  actionscalesettings wave
		actionScaleSettingsWave[headStage][%apThreshold] = threshold
		// reset the result value before starting the cycle
		actionScaleSettingsWave[headStage][%result] = 0
		
		// push the waveSet to the ephys panel
		// first, build up the control name by using the headstage value
		string waveSelect 
		string psaMenu
		string paaMenu
		string psaCheck
		string paaCheck
		string scaleWidgetName
		
		sprintf waveSelect, "Wave_DA_%02d", headstage
		sprintf psaMenu, "PSA_headStage%d", headstage
		sprintf paaMenu, "PAA_headStage%d", headstage
		sprintf psaCheck, "headStage%d_postSweepAnalysisOn", headstage
		sprintf paaCheck, "headStage%d_postAnalysisActionOn", headstage
		sprintf scaleWidgetName, "Scale_DA_%02d", headStage
		
		string FolderPath
		string folder
		string ListOfWavesInFolder
		
		// build up the list of available wave sets
		FolderPath = GetWBSvdStimSetDAPathAsString()
		folder = "*DA*"
		setdatafolder FolderPath // sets the wavelist for the DA popup menu to show all waves in DAC folder
		ListOfWavesInFolder = Wavelist(Folder,";","") 
		
		// make sure that the incoming StimWaveName is a valid wave name
		if (FindListItem(StimWaveName, ListOfWavesInFolder) == -1)
			print "Not a valid wave selection...please try again..."
			return "RETURN: -1"
		endif
		
		// now find the index of the selected incoming wave in that list
		variable incomingWaveIndex = WhichListItem(StimWaveName, ListOfWavesInFolder, ";")
		
		// and now set the wave popup menu to that index
		// have to add 2 since the pulldown always has -none- and TestPulse as options
		SetPopupMenuIndex(currentPanel, waveSelect, incomingWaveIndex + 2)  
	
		// push the PSA_waveName into the right place
		// find the index for for the psa routine 
		// do this if the window actually exists
		ASSERT(WindowExists(amPanel), "Analysis master panel must exist")

		string psaFuncList = AM_PS_sortFunctions()
		variable psaFuncIndex	 = WhichListItem("returnActionPotential", psaFuncList)
		SetPopupMenuIndex("analysisMaster", psaMenu, psaFuncIndex)
		
		// push the PAA_waveName into the right place
		// find the index for for the psa routine
		string paaFuncList = AM_PA_sortFunctions()
		variable paaFuncIndex = WhichListItem("bracketScaleFactor", paaFuncList, ";")
		SetPopupMenuIndex("analysisMaster", paaMenu, paaFuncIndex)
	
		// do the on/off check boxes for consistency
		SetCheckBoxState("analysisMaster", psaCheck, 1)
		SetCheckBoxState("analysisMaster", paaCheck, 1)
		
		// insure that the on/off parts of analysisSettingsWave are on...
		analysisSettingsWave[headstage][%PSAOnOff] = "1"
		analysisSettingsWave[headstage][%PAAOnOff] = "1"
		
		// and put the full psa function into the analysisSettingsWave...putting it as the correct item into the popmenu widget doesn't push it into wave
		analysisSettingsWave[headstage][%PSAType] = "returnActionPotential"
		analysisSettingsWave[headstage][%PAAType] = "bracketScaleFactor"
		
		// turn on the repeated acquisition
		SetCheckBoxState(currentPanel, "Check_DataAcq1_RepeatAcq", 1)
		
		// make sure the analysisResult is set to 0
		analysisSettingsWave[headstage][%PSAResult] = num2str(0)
		
		// now start the sweep process
		print "pushing the start button..."
		// now start the sweep process
		// setting the ba structure
		ba.eventCode = 2
		ba.ctrlName = "DataAcquireButton"
		ba.win = currentPanel
		
		DAP_ButtonProc_AcquireData(ba)
		
		// and then return the scale value
// this will be enabled once we add async reporting capability to the WSE
//		print "returning the actionPotential factor..." 
//		variable firedActionPotentialScale = str2num(analysisSettingsWave[headstage][%PSAResult])
//		print "firedActionPotentialScale: ", firedActionPotentialScale
	endfor
	
	 // restore the data folder
	SetDataFolder savedDataFolder
	
	return "RETURN:1"
End

///@brief routine to be called from the WSE to select a stimWaveName, a PSA routine, a PAA routine, the scale factor, and which
/// headstage will be used
Function/T TI_runStimWave(stimWaveName, scaleFactor, headstage, [cmdID])
	string stimWaveName
	variable scaleFactor
	variable headstage
	string cmdID
	
	// save the present data folder
	string savedDataFolder = GetDataFolder(1)
	
	// get the da_ephys panel names
	string lockedDevList = DAP_ListOfLockedDevs()
	variable noLockedDevs = ItemsInList(lockedDevList)
	
	variable n
	for (n = 0; n<noLockedDevs; n+= 1)
		string currentPanel = StringFromList(n, lockedDevList)
	
		// structure needed for communicating with the start acquisition button on the DA_Ephys panel
		STRUCT WMButtonAction ba
		
		// pop the itc panel window to the front
		DoWindow /F $currentPanel
		
		Wave actionScaleSettingsWave = GetActionScaleSettingsWaveRef(currentPanel)
		Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(currentPanel)
		
		// push the waveSet to the ephys panel
		// first, build up the control name by using the headstage value
		string waveSelect 
		string psaCheck
		string paaCheck
		string scaleWidgetName
		string daCheck
		string hsCheck
		string adCheck
		
		sprintf waveSelect, "Wave_DA_%02d", headstage
		sprintf psaCheck, "headStage%d_postSweepAnalysisOn", headstage
		sprintf paaCheck, "headStage%d_postAnalysisActionOn", headstage
		sprintf scaleWidgetName, "Scale_DA_%02d", headStage
		sprintf daCheck, "Check_DA_%02d", headStage
		sprintf hsCheck, "Check_DataAcq_HS_%02d", headStage
		sprintf adCheck, "Check_AD_%02d", headStage
		
		string FolderPath
		string folder
		string ListOfWavesInFolder
			
		// turn off all DA's
		DAP_ButtonProc_DAOff("Button_DAC_TurnOFFDACs")
		
		// turn off all headstages
		// setting the ba structure
		ba.eventCode = 2
		ba.ctrlName = "button_DataAcq_TurnOffAllChan"
		ba.win = currentPanel
		
		 DAP_ButtonProc_AllChanOff(ba)
		 
		 // now turn on the requested headstage
		 SetCheckBoxState(currentPanel, hsCheck, 1)
		
		// build up the list of available wave sets
		FolderPath = GetWBSvdStimSetDAPathAsString()
		folder = "*DA*"
		setdatafolder FolderPath // sets the wavelist for the DA popup menu to show all waves in DAC folder
		ListOfWavesInFolder = Wavelist(Folder,";","") 
		
		// make sure that the incoming StimWaveName is a valid wave name
		if (FindListItem(StimWaveName, ListOfWavesInFolder) == -1)
			print "Not a valid wave selection...please try again..."
			return "RETURN: -1"
		endif
		
		// now find the index of the selected incoming wave in that list
		variable incomingWaveIndex = WhichListItem(StimWaveName, ListOfWavesInFolder, ";")
		
		// and now set the wave popup menu to that index
		SetPopupMenuIndex(currentPanel, waveSelect, incomingWaveIndex + 2)  // have to add 2 since the pulldown always has -none- and TestPulse as options
			
		// Turn off the PSA and PAA
		ASSERT(WindowExists(amPanel), "Analysis master panel must exist")
		
		// do the on/off check boxes for consistancy
		SetCheckBoxState("analysisMaster", psaCheck, 0)
		SetCheckBoxState("analysisMaster", paaCheck, 0)
		
		// insure that the on/off parts of analysisSettingsWave is off
		analysisSettingsWave[headstage][%PSAOnOff] = "0"
		analysisSettingsWave[headstage][%PAAOnOff] = "0"
		
		// set the DA check box
		SetCheckBoxState(currentPanel, daCheck, 1)
		
		// set the AD check box
		SetCheckBoxState(currentPanel, adCheck, 1)
					
		// turn off the repeated acquisition
		SetCheckBoxState(currentPanel, "Check_DataAcq1_RepeatAcq", 0)
		
		// put the delta in the right place 
		actionScaleSettingsWave[headstage][%scaleValue] = scaleFactor
		SetSetVariable(currentPanel, scaleWidgetName, scaleFactor)
		
		// now start the sweep process
		// setting the ba structure
		ba.eventCode = 2
		ba.ctrlName = "DataAcquireButton"
		ba.win = currentPanel
		
		DAP_ButtonProc_AcquireData(ba)
	endfor
	
	// restore the data folder
	SetDataFolder savedDataFolder
	
	// and finish
	return "RETURN: 1"
End

///@brief routine to be called from the WSE to see if the Action Potential has fired
Function/S TI_runAPResult(headstage, [cmdID])
	variable headstage
	string cmdID
	
	// get the da_ephys panel names
	string lockedDevList = DAP_ListOfLockedDevs()
	variable noLockedDevs = ItemsInList(lockedDevList)
	
	variable n
	for(n = 0; n < noLockedDevs; n += 1)
		string currentPanel = StringFromList(n, lockedDevList)
	
		Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(currentPanel)		
		variable apResult = AM_PSA_returnActionPotential(currentPanel, headstage)
		
		// return the ActionPotential Result
		string returnResult
		sprintf returnResult, "RETURN: %s" analysisSettingsWave[headstage][%PSAResult]
	endfor
	
	//return the result
	return returnResult
End

///@brief routine to be called from the WSE to start and stop the test pulse
Function TI_runTestPulse(tpCmd, [cmdID])
	variable tpCmd
	variable cmdID
	
	print "cmdID: ", cmdID
	
	// get the da_ephys panel names
	string lockedDevList = DAP_ListOfLockedDevs()
	variable noLockedDevs = ItemsInList(lockedDevList)
	
	variable n
	string currentPanel
	variable returnValue
	for (n = 0; n<noLockedDevs; n+= 1)
		currentPanel = StringFromList(n, lockedDevList)

		// structure needed for communicating with the start acquisition button on the DA_Ephys panel
		STRUCT WMButtonAction ba
		
		if(tpCmd == 1)	// Turn on the test pulse
		
			// setting the ba structure
			ba.eventCode = 2
			ba.ctrlName = "StartTestPulseButton"
			ba.win = currentPanel
			
			TP_ButtonProc_DataAcq_TestPulse(ba)
			
			returnValue = 1
		elseif(tpCmd == 0) // Turn off the test pulse
			ITC_STOPTestPulse(currentPanel)
			ITC_TPDocumentation(currentPanel) // documents the TP Vrest, peak and steady state resistance values. for manually terminated TPs
			returnValue = 0
		else
			returnValue = -1
		endif
	endfor
	
	writeAck(cmdID, returnValue)
END


///@brief Routine to test starting and stopping acquisition by remotely hitting the start/stop button on the DA_Ephys panel
Function TI_runStopStart([cmdID])
	variable cmdID
	
	// get the da_ephys panel names
	string lockedDevList = DAP_ListOfLockedDevs()
	variable noLockedDevs = ItemsInList(lockedDevList)
	
	variable n
	for (n = 0; n<noLockedDevs; n+= 1)
		string currentPanel = StringFromList(n, lockedDevList)

		// structure needed for communicating with the start acquisition button on the DA_Ephys panel
		STRUCT WMButtonAction ba
		
		// pop the itc panel window to the front
		DoWindow /F $currentPanel
		
		// setting the ba structure
		ba.eventCode = 2
		ba.ctrlName = "DataAcquireButton"
		ba.win = currentPanel
		
		DAP_ButtonProc_AcquireData(ba)
	endfor
	
	// determine if the cmdID was provided
	if (ParamIsDefault(cmdID) == 0)
		writeAck(cmdID, 1)
	endif
End

/// @brief function to write the acknowledgement string back to the WSE
Function writeAck(cmdID, returnValue)
	Variable cmdID
	Variable returnValue
	
	String logMessage
		
	// put the response string together...
	sprintf logMessage, "cmd_id:%d;response:%d", cmdID, returnValue 
	print "logMessage: ", logMessage
	
	//- function arg: the name of the device on which the commands will be executed 
	String dev_name = "mies_device/MiesDevice/test"
  
	//- let's declare our <argin> and <argout> structures. 
	//- be aware that <argout> will be overwritten (and reset) each time we execute a 
	//- command it means that you must use another <CmdArgOut> if case you want to 
	//- store more than one command result at a time. here we reuse both argin and 
	//- argout for each command.

	//- argin
	Struct CmdArgIO argin
	tango_init_cmd_argio (argin)
	
	//- argout 
	Struct CmdArgIO argout
	tango_init_cmd_argio (argout)
	
	//- populate argin: <CmdArgIn.cmd> struct member
	//- name of the command to be executed on <argin.dev> 
	String cmd = "post_ack"

	//- verbose
	print "\rexecuting <" + cmd + ">...\r"
  
	//- since the command argin is a string scalar (i.e. single string), we stored its its value 
	//- into the <str> member of the <CmdArgIn> structure. 
	argin.str_val = logMessage
  
	Variable mst_ref = StartMSTimer
  
	Variable mst_dt  
	//- actual cmd execution
	//- if an error occurs during command execution, argout is undefined (null or empty members)
	//- ALWAYS CHECK THE CMD RESULT BEFORE TRYING TO ACCESS ARGOUT: 0 means NO_ERROR, -1 means ERROR
	if (tango_cmd_inout(dev_name, cmd, arg_in = argin, arg_out = argout) == -1)
		//- the cmd failed, display error...
		tango_display_error()
		//- ... then return error
		mst_dt = StopMSTimer(mst_ref)		
		return kERROR
	endif
  
	mst_dt = StopMSTimer(mst_ref)
	print "\t'-> took " + num2str(mst_dt / 1000) + " ms to complete"
	
	//- <argout> is populated (i.e. filled) by <tango_cmd_inout> uppon return of the command.
	//- since the command ouput argument is a string scalar (i.e. single string), it is stored 
	//- in the <str> member of the <CmdArgOut> structure.

	//- as previously explained, we are testing our TANGO binding on a TangoTest device. 
	//- consequently, we check that <argin.str == argout.str> in order to be sure that everything is ok
//	if (cmpstr(argin.str_val, argout.str_val) != 0)
//		//- the cmd failed, display error...
//		tango_display_error_str("ERROR:DevString:unexpected cmd result - aborting test")
//		//- ... then return error
//		return kERROR
//	endif
  
	//- verbose
	print "\t'-> ack sent\r"
	
End


/// @brief function to allow for writing async responses back to the WSE
Function writeAsyncResponse(cmdID, returnString)
	variable cmdID
	String returnString
	
	String responseMessage	
	variable numberOfReturnItems = ItemsInList(returnString)
	
	// put the response string together...
	sprintf logMessage, "cmd_id:%d;%d;%s", cmdID, numberOfReturnItems, returnString
	
	//- function arg: the name of the device on which the commands will be executed 
	String dev_name = "mies_device/MiesDevice/test"
  
	//- let's declare our <argin> and <argout> structures. 
	//- be aware that <argout> will be overwritten (and reset) each time we execute a 
	//- command it means that you must use another <CmdArgOut> if case you want to 
	//- store more than one command result at a time. here we reuse both argin and 
	//- argout for each command.

	//- argin
	Struct CmdArgIO argin
	tango_init_cmd_argio (argin)
	
	//- argout 
	Struct CmdArgIO argout
	tango_init_cmd_argio (argout)
	
	//- populate argin: <CmdArgIn.cmd> struct member
	//- name of the command to be executed on <argin.dev> 
	String cmd = "post_asynch_response"

	//- verbose
	print "\rexecuting <" + cmd + ">...\r"
  
	//- since the command argin is a string scalar (i.e. single string), we stored its its value 
	//- into the <str> member of the <CmdArgIn> structure. 
	argin.str_val = responseMessage
  
	Variable mst_ref = StartMSTimer
  
	Variable mst_dt  
	//- actual cmd execution
	//- if an error occurs during command execution, argout is undefined (null or empty members)
	//- ALWAYS CHECK THE CMD RESULT BEFORE TRYING TO ACCESS ARGOUT: 0 means NO_ERROR, -1 means ERROR
	if (tango_cmd_inout(dev_name, cmd, arg_in = argin, arg_out = argout) == -1)
		//- the cmd failed, display error...
		tango_display_error()
		//- ... then return error
		mst_dt = StopMSTimer(mst_ref)		
		return kERROR
	endif
  
	mst_dt = StopMSTimer(mst_ref)
	print "\t'-> took " + num2str(mst_dt / 1000) + " ms to complete"
	
	//- <argout> is populated (i.e. filled) by <tango_cmd_inout> uppon return of the command.
	//- since the command ouput argument is a string scalar (i.e. single string), it is stored 
	//- in the <str> member of the <CmdArgOut> structure.

	//- as previously explained, we are testing our TANGO binding on a TangoTest device. 
	//- consequently, we check that <argin.str == argout.str> in order to be sure that everything is ok
//	if (cmpstr(argin.str_val, argout.str_val) != 0)
//		//- the cmd failed, display error...
//		tango_display_error_str("ERROR:DevString:unexpected cmd result - aborting test")
//		//- ... then return error
//		return kERROR
//	endif
  
	//- verbose
	print "\t'-> async response sent\r"
	
End