%dw 2.0
output application/json skipNullOn="everywhere"
---
{
    "status": if(payload.Messages[0] contains ("Save is not enabled")) "Success" else if (payload.Summary.Succeeded != 1)payload.Results.Transactions.Status[0] else "Success",
    "itemId": payload.Transactions[0].DataElements[1].Rows[0].Edits[0].Value,
    "assetId": vars.assetId,
    "errorDetails": payload.Messages[0]
    
}