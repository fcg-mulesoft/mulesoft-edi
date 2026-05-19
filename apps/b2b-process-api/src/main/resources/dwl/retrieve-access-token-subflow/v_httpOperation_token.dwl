
%dw 2.0
output application/json
---
{
	method: Mule::p('anypoint.platform.method'),
	host: Mule::p('anypoint.platform.host'),
	port: Mule::p('anypoint.platform.port'),
	basePath: Mule::p('anypoint.platform.basePath'),
	path: Mule::p('anypoint.platform.path'),
	headers: {
	},
	queryParams: {
		"dateReceivedTo": vars.interval.toTime,
		"expandCustomAttributes": true,
		"dateReceivedFrom": vars.interval.fromTime
	},
	body: {
		"grant_type": Mule::p('secure::apm.api.accessToken.grantType'),
		"client_id": "e74eeb31b0bf43339daacd81e123d41a",
		"client_secret": "687f40434106404984Aff58d8549D0B1"
	},
	"untilsuccessful": {
		"maxRetries": Mule::p('anypoint.platform.untilsuccessful.maxRetries'),
		"interval":  Mule::p('anypoint.platform.untilsuccessful.interval'),
	}
}



