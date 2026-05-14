%dw 2.0
output application/json

---
vars.transmissionError map (item) -> {

    partnerFrom: item.partnerFrom.name,

    partnerTo: item.partnerTo.name,

    direction: item.direction,

    transaction: 
        item.sourceDocType.baseType 
        default "N/A",

    transmissionId: item.id,

    businessKey: item.businessDocumentKey,

    errorDetails:
        (
            (
                item.transmissionSteps 
                    filter ($.status == "ERRORED")
            )[0].errorMessage
        ) default "No Error Found"
}