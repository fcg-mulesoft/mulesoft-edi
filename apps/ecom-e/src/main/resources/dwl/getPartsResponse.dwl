%dw 2.0
output application/json
---
{
   "itemId": payload.Part.ItemId,
  "itemDesc": payload.Part.ItemDesc,
  "invMastUid": payload.Part.InvMastUid
}