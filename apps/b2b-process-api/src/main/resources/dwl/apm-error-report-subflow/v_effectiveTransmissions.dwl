%dw 2.0
output application/json
---
vars.transmissionError filter ((t) -> not (vars.messageErrors.transmissionId contains t.id))
