.pragma library

// https://github.com/KDE/plasma-framework/blob/master/src/declarativeimports/calendar/eventpluginsmanager.h
// https://github.com/KDE/plasma-framework/blob/master/src/declarativeimports/calendar/eventpluginsmanager.cpp

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
	if (!Array.isArray(pluginPathList)) {
		return pluginFilenameList
	}
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
	if (!Array.isArray(pluginFilenameList)) {
		return pluginPathList
	}
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

function populateEnabledPluginsByFilename(eventPluginsManager, pluginFilenameList) {
	var pluginPathList = pluginFilenameToPathList(eventPluginsManager, pluginFilenameList)
	eventPluginsManager.populateEnabledPluginsList(pluginPathList)
}

function setEnabledPluginsByFilename(eventPluginsManager, pluginFilenameList) {
	var pluginPathList = pluginFilenameToPathList(eventPluginsManager, pluginFilenameList)
	eventPluginsManager.enabledPlugins = pluginPathList
}
