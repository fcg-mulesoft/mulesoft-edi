%dw 2.0
output application/json
---
{
	"method": p('anypoint.apm.method'),
	"host": "anypoint.mulesoft.com",
	"port": "443",
	"basePath": "/partnermanager",
	"path": "/tracking/api/v1/organizations/" ++ p('anypoint.apm.orgid') ++"/environments/" ++ p('anypoint.apm.envid') ++"/activity/messages",
	headers: {
		"Content-Type": "application/x-www-form-urlencoded",
		"Authorization": "Bearer " ++ vars.accessToken
	},
	queryParams: {
		"dateReceivedTo": vars.interval.toTime,
		"expandCustomAttributes": true,
		"status": "ERRORED",
		"dateReceivedFrom": vars.interval.fromTime
	},
	"untilsuccessful": {
		"maxRetries": Mule::p('anypoint.platform.untilsuccessful.maxRetries'),
		"interval": Mule::p('anypoint.platform.untilsuccessful.interval'),
	}
}



