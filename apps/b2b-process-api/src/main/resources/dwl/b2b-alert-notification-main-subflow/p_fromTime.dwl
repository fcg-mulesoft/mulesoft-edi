%dw 2.0
output application/json
---
if(isEmpty(payload)) (now() - |PT168H|)
else read(payload.lastRun,"application/json") as DateTime