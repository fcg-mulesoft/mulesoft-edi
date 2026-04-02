%dw 2.0
output application/json
---
{
	"status": if(payload.Messages[0] contains ("Save is not enabled")) "Success" else if (payload.Summary.Succeeded != 1)payload.Results.Transactions.Status[0] else "Success",
    "description": payload.Messages[0],
	"correlationId": vars.correlationId,
	"id": vars.id
	
}