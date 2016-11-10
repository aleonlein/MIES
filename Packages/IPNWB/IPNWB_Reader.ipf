#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion=6.3
#pragma IndependentModule=IPNWB
#pragma version=0.15

/// @file IPNWB_Reader.ipf
/// @brief Generic functions related to import from the NeuroDataWithoutBorders format

/// @brief List devices in given hdf5 file
///
/// @param  fileID identifier of open HDF5 file
/// @return        comma separated list of devices
Function/S ReadDevices(fileID)
	Variable fileID

	return RemovePrefixFromListItem("device_", H5_ListGroupMembers(fileID, "/general/devices"))
End

/// @brief List groups inside /general/labnotebook
///
/// @param  fileID identifier of open HDF5 file
/// @return        list with name of all groups inside /general/labnotebook/*
Function/S ReadLabNoteBooks(fileID)
	Variable fileID

	return H5_ListGroups(fileID, "/general/labnotebook")
End

/// @brief List all acquisition channels.
///
/// @param  fileID identifier of open HDF5 file
/// @return        comma separated list of channels
Function/S ReadAcquisition(fileID)
	variable fileID

	return H5_ListGroups(fileID, "/acquisition/timeseries")
End

/// @brief List all stimulus channels.
///
/// @param  fileID identifier of open HDF5 file
/// @return        comma separated list of channels
Function/S ReadStimulus(fileID)
	variable fileID

	return H5_ListGroups(fileID, "/stimulus/presentation")
End

/// @brief Check if the file can be handled by the IPNWB Read Procedures
///
/// @param   fileID  Open HDF5-File Identifier
/// @return  True:   All checks successful
///          False:  Error(s) occured.
///                  The result of the analysis is printed to history.
Function CheckIntegrity(fileID)
	variable fileID

	string deviceList, channelList
	variable groupID
	variable integrity = 1

	deviceList = ReadDevices(fileID)
	if (cmpstr(deviceList, ReadLabNoteBooks(fileID)))
		print "labnotebook corrupt"
		integrity = 0
	endif

	channelList = ReadAcquisition(fileID)
	groupID = OpenAcquisition(fileID)
	if(!CheckChannels(groupID, channelList))
		print "acquisition channel corrupt"
		integrity = 0
	endif
	HDF5CloseGroup/Z groupID

	channelList = ReadStimulus(fileID)
	groupID = OpenStimulus(fileID)
	if(!CheckChannels(groupID, channelList))
		print "stimulus channel corrupt"
		integrity = 0
	endif
	HDF5CloseGroup/Z groupID

	return integrity
End

/// @brief  Try loading a channel and perform some checks
///         this can be used to verify the source data
///
/// @param   groupID  HDF5 group specified channel is a member of
/// @param   channel  channel to load
/// @return  True:    All checks successful
///          False:   Error(s) occured.
///                   The result of the analysis is printed to history.
Function CheckChannel(groupID, channel)
	Variable groupID
	String channel

	Struct ReadChannelParams p
	Struct ReadChannelParams q

	Variable integrity = 1

	LoadSourceAttribute(groupID, channel, p)
	AnalyseChannelName(channel, q)
	if(p.channelType != q.channelType)
		printf "name of channel %s differs from channelType %d\r" channel, p.channelType
		integrity = 0
	endif
	if(p.channelNumber != q.channelNumber)
		printf "name of channel %s differs from channelNumber %d\r" channel, p.channelNumber
		integrity = 0
	endif

	return integrity
End

/// @brief Check every channel from channelList inside a specified group
///
/// @param   groupID     HDF5 group containing the channels to check
/// @param   channelList List of all channels that have to be checked
/// @return  True:       All checks successful
///          False:      Error(s) occured.
///                      The result of the analysis is printed to history.
Function CheckChannels(groupID, channelList)
	Variable groupID
	String channelList

	String channel
	Variable numChannels, i

	numChannels = ItemsInList(channelList)
	for(i = 0; i < numChannels; i += 1)
		channel = StringFromList(i, channelList)
		if(!CheckChannel(groupID, channel))
			return 0
		endif
		wave loaded = LoadDataWave(groupID, channel)
		if(!WaveExists(loaded))
			printf "could not load DataSet for channel %s" channel
			return 0
		endif
		WaveClear loaded
	endfor

	return 1
End

/// @brief Loader structure analog to #IPNWB::WriteChannelParams
Structure ReadChannelParams
	string   device           ///< name of the measure device, e.g. "ITC18USB_Dev_0"
	string   channelSuffix    ///< custom channel suffix, in case the channel number is ambiguous
	variable sweep            ///< running number for each measurement
	variable channelType      ///< channel type, one of @ref IPNWB_ChannelTypes
	variable channelNumber    ///< running number of the channel
	variable electrodeNumber  ///< electrode identifier the channel was acquired with
	variable groupIndex       ///< constant for all channels in this measurement.
	variable ttlBit           ///< unambigous ttl-channel-number
EndStructure

/// @brief Try to extract information from channel name string
///
/// @param[in]  channel  Input channel name in form data_00000_TTL1_3
/// @param[out] p        ReadChannelParams structure to get filled
Function AnalyseChannelName(channel, p)
	String channel
	STRUCT ReadChannelParams &p
	String groupIndex, channelTypeStr, channelNumber, channelSuffix, channelID

	SplitString/E="^(?i)data_([A-Z0-9]+)_([A-Z]+)([0-9]+)(?:_([A-Z0-9]+)){0,1}" channel, groupIndex, channelID, channelNumber, p.channelSuffix
	p.groupIndex = str2num(groupIndex)
	p.ttlBit = str2num(p.channelSuffix)
	strswitch(channelID)
		case "AD":
			p.channelType = CHANNEL_TYPE_ADC
			break
		case "DA":
			p.channelType = CHANNEL_TYPE_DAC
			break
		case "TTL":
			p.channelType = CHANNEL_TYPE_TTL
			break
		default:
			p.channelType = CHANNEL_TYPE_OTHER
	endswitch
	p.channelNumber = str2num(channelNumber)
End

/// @brief Read parameters from source attribute
///
/// @param[in]  locationID   HDF5 group specified channel is a member of
/// @param[in]  channel      channel to load
/// @param[out] p            ReadChannelParams structure to get filled
Function LoadSourceAttribute(locationID, channel, p)
	variable locationID
	string channel
	STRUCT ReadChannelParams &p

	string attribute, property, value
	variable numStrings, i, error

	attribute = "source"
	ASSERT(!H5_DatasetExists(locationID, channel + "/" + attribute), "Could not find source attribute!")

	HDF5LoadData/O/A=(attribute)/N=tempAttributeWave/TYPE=1/Q/Z locationID, channel
	error = V_flag
	if(error)
		HDf5DumpErrors/CLR=1
		HDF5DumpState
		HDF5CloseGroup/Z locationID
		KillWaves/Z tempAttributeWave
		ASSERT(0, "\rCould not load the HDF5 attribute '" + attribute + "' in channel '" + channel + "'\rError No: " + num2str(error))
	endif

	ASSERT(ItemsInList(S_WaveNames) == 1, "Expected only one wave")
	WAVE/T wv = tempAttributeWave
	ASSERT(WaveType(wv, 1) == 2, "Expected a dataset of type text")

	numStrings = DimSize(wv, ROWS)

	// new format since eaa5e724 (H5_WriteTextAttribute: Force dataspace to SIMPLE
	// for lists, 2016-08-28)
	// source has now always one element
	if(numStrings == 1)
		WAVE/T list = ListToTextWave(wv[0], ";")
		numStrings = DimSize(list, ROWS)
	else
		WAVE/T list = wv
	endif

	for(i = 0; i < numStrings; i += 1)
		SplitString/E="(.*)=(.*)" list[i], property, value
		strswitch(property)
			case "Device":
				p.device = value
				break
			case "Sweep":
				p.sweep = str2num(value)
				break
			case "ElectrodeNumber":
				p.electrodeNumber = str2num(value)
				break
			case "AD":
				p.channelType = CHANNEL_TYPE_ADC
				p.channelNumber = str2num(value)
				break
			case "DA":
				p.channelType = CHANNEL_TYPE_DAC
				p.channelNumber = str2num(value)
				break
			case "TTL":
				p.channelType = CHANNEL_TYPE_TTL
				p.channelNumber = str2num(value)
				break
			case "TTLBit":
				p.ttlBit = str2num(value)
				break
			default:
		endswitch
	endfor

	KillWaves/Z wv
End

/// @brief Load data wave from specified path
///
/// @param locationID   id of an open hdf5 group containing channel
///                     id can also be of an open nwb file. In this case specify (optional) path.
/// @param channel      name of channel for which data attribute is loaded
/// @param path         use path to specify group inside hdf5 file where ./channel/data is located.
/// @return             reference to free wave containing loaded data
Function/Wave LoadDataWave(locationID, channel, [path])
	variable locationID
	string channel, path

	if(ParamIsDefault(path))
		path = "./"
	endif

	Assert(IPNWB#H5_GroupExists(locationID, path), "Path is not in nwb file")

	path += channel + "/data"
	HDF5LoadData/Q/IGOR=(-1) locationID, path

	Assert(!V_flag, "could not load data wave from specified path")
	Assert(ItemsInList(S_waveNames) == 1, "unspecified data format")

	wave data = $StringFromList(0, S_waveNames)
	MoveWave data $channel

	return MakeWaveFree(data)
End

/// @brief Load single channel data as a wave from /acquisition/timeseries
///
/// @param locationID   id of an open hdf5 group or file
/// @param channel      name of channel for which data attribute is loaded
/// @param dfr          dataFolder where data is saved
/// @return             reference to wave containing loaded data
Function/Wave LoadTimeseries(locationID, channel, [dfr])
	Variable locationID
	String channel
	DFREF dfr

	WAVE data = LoadDataWave(locationID, channel, path = "/acquisition/timeseries/")
	if(!ParamIsDefault(dfr))
		MoveAndRename(data, "AD" + NameOfWave(data), dfr = dfr)
	endif

	return data
End

/// @brief Load single channel data as a wave from /stimulus/presentation/
///
/// @param locationID    id of an open hdf5 group or file
/// @param channel       name of channel for which data attribute is loaded
/// @param dfr           dataFolder where data is saved
/// @param channelPrefix Add custom Prefix to WaveName
/// @return             reference to wave containing loaded data
Function/Wave LoadStimulus(locationID, channel, [dfr, channelPrefix])
	Variable locationID
	String channel, channelPrefix
	DFREF dfr
	if(ParamIsDefault(channelPrefix))
		channelPrefix = "DA"
	endif

	WAVE data = LoadDataWave(locationID, channel, path = "/stimulus/presentation/")
	if(!ParamIsDefault(dfr))
		MoveAndRename(data, channelPrefix + NameOfWave(data), dfr = dfr)
	endif

	return data
End

/// @brief Open hdf5 group containing acquisition channels
///
/// @param fileID id of an open hdf5 group or file
///
/// @return id of hdf5 group
Function OpenAcquisition(fileID)
	variable fileID

	return H5_OpenGroup(fileID, "/acquisition/timeseries")
End

/// @brief Open hdf5 group containing stimulus channels
///
/// @param fileID id of an open hdf5 group or file
///
/// @return id of hdf5 group
Function OpenStimulus(fileID)
	variable fileID

	return H5_OpenGroup(fileID, "/stimulus/presentation")
End