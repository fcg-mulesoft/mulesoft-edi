%dw 2.0
output application/json
---
{
    "status": if(payload.Summary.Succeeded==1)"Success"  else if((payload.Summary.Failed==1) and (payload.Messages[0] contains("This pick ticket has been cancelled")))"Success" else if(payload.Messages[0] contains ("Save is not enabled")) "Success" else payload.Results.Transactions.Status[0],
    "description": payload.Messages[0],
    "pickTicketNo": payload.Results.Transactions[0].DataElements[0].Rows[0].Edits[0].Value
    
}