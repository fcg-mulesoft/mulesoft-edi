
%dw 2.0
output application/json
---
{
	method: "POST",
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
		"maxRetries": "5",
		"interval": "5000"
	}
}



