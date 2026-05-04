%dw 2.0
output application/json
---
vars.messageErrors default [] map (msg) -> {

    messageType: msg.messageType,
    direction: msg.direction,
    partnerFrom: msg.partnerFrom.name,
    partnerTo: msg.partnerTo.name,
    businessKey: if (sizeOf(msg.customAttributes) > 0) 
                  (msg.customAttributes[0].alias default "") 
                  ++ "-" 
                  ++ (msg.customAttributes[0].values[0] default "")
              else 
                   (msg.businessDocumentKey default "")
}

