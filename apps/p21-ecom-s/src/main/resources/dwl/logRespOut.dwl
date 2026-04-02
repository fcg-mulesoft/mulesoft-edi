%dw 2.0
output application/json
---
{
    CorrelationId: vars.correlationId  default correlationId,
    Message: "your message",
    Payload: payload
}
