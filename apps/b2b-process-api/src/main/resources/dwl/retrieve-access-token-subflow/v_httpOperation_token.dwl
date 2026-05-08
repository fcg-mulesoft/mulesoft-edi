
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
		"client_id": Mule::p('secure::apm.api.accessToken.clientId'),
		"client_secret": Mule::p('secure::apm.api.accessToken.clientSecret')
	},
	"untilsuccessful": {
		"maxRetries": Mule::p('anypoint.platform.untilsuccessful.maxRetries'),
		"interval":  Mule::p('anypoint.platform.untilsuccessful.interval'),
	}
}



