const assert = require('assert')
const fs = require('fs')
const path = require('path')
const vm = require('vm')

const source = fs.readFileSync(
	path.join(__dirname, '../package/contents/ui/lib/Requests.js'),
	'utf8'
).replace(/^\.pragma library\s*/, '')

class MockXMLHttpRequest {
	constructor() {
		this.readyState = 0
		this.status = 0
		this.responseText = ''
		this.headers = {}
	}

	open(method, url) {
		this.method = method
		this.url = url
	}

	setRequestHeader(key, value) {
		this.headers[key] = value
	}

	getAllResponseHeaders() {
		return ''
	}

	send(data) {
		this.data = data
		this.status = 400
		this.readyState = 3
		this.onerror()
		this.responseText = JSON.stringify({
			error: 'invalid_grant',
			error_description: 'Token has been expired or revoked.',
		})
		this.readyState = MockXMLHttpRequest.DONE
		this.onerror()
		this.onreadystatechange()
	}
}
MockXMLHttpRequest.DONE = 4

const context = {
	XMLHttpRequest: MockXMLHttpRequest,
	console: { log() {} },
	encodeURIComponent: encodeURIComponent,
	JSON: JSON,
}
vm.runInNewContext(source, context)

const calls = []
context.request({ url: 'https://oauth2.googleapis.com/token' }, function(err, data, xhr) {
	calls.push({ err, data, status: xhr.status })
})

assert.strictEqual(calls.length, 1, 'request must complete only once when error events overlap')
assert.strictEqual(calls[0].err, 'HTTP Error 400')
assert.strictEqual(calls[0].status, 400)
assert.deepStrictEqual(JSON.parse(calls[0].data), {
	error: 'invalid_grant',
	error_description: 'Token has been expired or revoked.',
})

console.log('PASS requests_completion')
