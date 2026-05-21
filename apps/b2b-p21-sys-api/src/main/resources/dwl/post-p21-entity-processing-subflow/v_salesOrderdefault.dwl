%dw 2.0
output application/xml

var orderPayload = payload.Transactions[0].DataElements[0].Order

---
{
    Order @(
        "xmlns:xsd": "http://www.w3.org/2001/XMLSchema",
        "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance"
    ): orderPayload
}