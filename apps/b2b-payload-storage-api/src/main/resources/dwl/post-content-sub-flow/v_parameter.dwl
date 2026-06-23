%dw 2.0
output application/json
---
{
	envId: attributes.uriParams.envId  ,
	contentrecordid:uuid(),
	orgId: attributes.uriParams.orgId
}