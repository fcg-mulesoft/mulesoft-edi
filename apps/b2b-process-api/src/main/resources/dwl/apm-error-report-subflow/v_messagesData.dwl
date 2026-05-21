%dw 2.0
output application/json

---
vars.messageErrors map (item) -> {

    partnerFrom: item.partnerFrom.name,

    partnerTo: item.partnerTo.name,

    transaction: item.messageType,

    transmissionId: item.transmissionId,

    businessKey: item.businessDocumentKey,

    receivedDateTime: item.receivedTime,

    messageDirection: item.direction,

    documentVersion: item.messageVersion,

    businessFlow: item.documentFlowName,

    documentNumber: item.businessDocumentId,

    batchGroupNumber: item.businessDocumentGroupId,

    acknowledgementType: item.messageAckType,

    acknowledgementStatus: item.messageAckStatus
}