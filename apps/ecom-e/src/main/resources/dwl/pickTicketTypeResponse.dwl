%dw 2.0
output application/json
---
(payload.pickTicketIds map 
 {
      id:$,
      pickTicketId: vars.txNo
}) distinctBy $.id