const assert = require('assert')
const fs = require('fs')
const path = require('path')

const logic = fs.readFileSync(
	path.join(__dirname, '../package/contents/ui/Logic.qml'),
	'utf8'
)

assert.ok(
	!logic.includes("logger.debugJSON('updateDailyWeather.response', data)"),
	'Logic.qml must not log full daily weather responses'
)
assert.ok(
	!logic.includes("logger.debugJSON('updateHourlyWeather.response', data)"),
	'Logic.qml must not log full hourly weather responses'
)

console.log('PASS no_large_weather_debug_logs')
