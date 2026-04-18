.pragma library

// https://github.com/KDE/plasma-framework/blob/master/src/declarativeimports/calendar/eventpluginsmanager.h
// https://github.com/KDE/plasma-framework/blob/master/src/declarativeimports/calendar/eventpluginsmanager.cpp

var DEFAULT_PLUGIN_FILENAMES = [
	'holidaysevents.so',
	'pimevents.so',
]

function toArray(listLike) {
	if (!listLike) {
		return []
	}
	if (Array.isArray(listLike)) {
		return listLike
	}
	if (typeof listLike === 'string') {
		if (!listLike) {
			return []
		}
		return [listLike]
	}
	if (typeof listLike.length === 'number') {
		var array = []
		for (var i = 0; i < listLike.length; i++) {
			array.push(listLike[i])
		}
		return array
	}
	return []
}

function getPluginFilename(pluginPath) {
	if (!pluginPath || typeof pluginPath !== 'string') {
		return ''
	}
	var lastSlash = pluginPath.lastIndexOf('/')
	if (lastSlash === -1) {
		return pluginPath
	}
	return pluginPath.substr(lastSlash + 1)
}

function pluginPathToFilenameList(pluginPathList) {
	var pluginFilenameList = []
	pluginPathList = toArray(pluginPathList)
	for (var i = 0; i < pluginPathList.length; i++) {
		var pluginFilename = getPluginFilename(pluginPathList[i])
		if (!pluginFilename) {
			continue
		}
		if (pluginFilenameList.indexOf(pluginFilename) == -1) {
			pluginFilenameList.push(pluginFilename)
		}
	}
	return pluginFilenameList
}

function getPluginPath(eventPluginsManager, pluginFilenameA) {
	if (!eventPluginsManager || !eventPluginsManager.model || typeof eventPluginsManager.model.rowCount !== 'function') {
		return null
	}
	for (var i = 0; i < eventPluginsManager.model.rowCount(); i++) {
		var pluginPath = eventPluginsManager.model.get(i, 'pluginPath')
		if (!pluginPath) {
			continue
		}
		// console.log('\t\t', i, pluginPath)
		var pluginFilenameB = getPluginFilename(pluginPath)
		if (pluginFilenameA == pluginFilenameB) {
			return pluginPath
		}
	}

	// Plugin not installed
	return null
}

function pluginFilenameToPathList(eventPluginsManager, pluginFilenameList) {
	// console.log('eventPluginsManager', eventPluginsManager)
	// console.log('eventPluginsManager.model', eventPluginsManager.model)
	// console.log('eventPluginsManager.model.rowCount', eventPluginsManager.model.rowCount())
	var pluginPathList = []
	pluginFilenameList = toArray(pluginFilenameList)
	for (var i = 0; i < pluginFilenameList.length; i++) {
		var pluginFilename = pluginFilenameList[i]
		if (!pluginFilename) {
			continue
		}
		// console.log('\t\t', i, pluginFilename)
		var pluginPath = getPluginPath(eventPluginsManager, pluginFilename)
		if (!pluginPath) {
			console.log('[eventcalendar] Tried to load ', pluginFilename, ' however the plasma calendar plugin is not installed.')
			continue
		}
		if (pluginPathList.indexOf(pluginPath) == -1) {
			pluginPathList.push(pluginPath)
		}
	}
	// console.log('pluginFilenameList', pluginFilenameList)
	// console.log('pluginPathList', pluginPathList)
	return pluginPathList
}

function normalizePluginFilenameList(pluginFilenameList) {
	var normalizedList = []
	pluginFilenameList = toArray(pluginFilenameList)
	for (var i = 0; i < pluginFilenameList.length; i++) {
		var pluginFilename = pluginFilenameList[i]
		if (!pluginFilename || typeof pluginFilename !== 'string') {
			continue
		}
		if (normalizedList.indexOf(pluginFilename) === -1) {
			normalizedList.push(pluginFilename)
		}
	}
	return normalizedList
}

function getDefaultPluginFilenameList(eventPluginsManager) {
	var defaultPluginFilenameList = []
	for (var i = 0; i < DEFAULT_PLUGIN_FILENAMES.length; i++) {
		var pluginFilename = DEFAULT_PLUGIN_FILENAMES[i]
		if (eventPluginsManager && !getPluginPath(eventPluginsManager, pluginFilename)) {
			continue
		}
		defaultPluginFilenameList.push(pluginFilename)
	}
	return defaultPluginFilenameList
}

function getEffectivePluginFilenameList(eventPluginsManager, pluginFilenameList, allowEmpty) {
	var normalizedPluginFilenameList = normalizePluginFilenameList(pluginFilenameList)
	if (normalizedPluginFilenameList.length > 0 || allowEmpty) {
		return normalizedPluginFilenameList
	}
	return getDefaultPluginFilenameList(eventPluginsManager)
}

function populateEnabledPluginsByFilename(eventPluginsManager, pluginFilenameList, allowEmpty) {
	var pluginPathList = pluginFilenameToPathList(
		eventPluginsManager,
		getEffectivePluginFilenameList(eventPluginsManager, pluginFilenameList, allowEmpty)
	)
	eventPluginsManager.populateEnabledPluginsList(pluginPathList)
}

function setEnabledPluginsByFilename(eventPluginsManager, pluginFilenameList, allowEmpty) {
	var pluginPathList = pluginFilenameToPathList(
		eventPluginsManager,
		getEffectivePluginFilenameList(eventPluginsManager, pluginFilenameList, allowEmpty)
	)
	eventPluginsManager.enabledPlugins = pluginPathList
}
