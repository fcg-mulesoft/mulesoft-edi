%dw 2.0
output application/json
import * from dw::core::Strings
---
{
	"source": vars.integration.source,
	"target": vars.integration.target,
	"env": capitalize(p('mule.env')),	
	"integration-type": vars.integration."integration-type"
	
}