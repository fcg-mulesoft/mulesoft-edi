%dw 2.0
output application/json
---
{
	envId: attributes.uriParams.envId,
	contentrecordid:attributes.uriParams.contentRecordId ,
	orgId: attributes.uriParams.orgId
}