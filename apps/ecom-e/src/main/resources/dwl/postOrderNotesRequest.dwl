%dw 2.0
output application/json
---
{
    "Notes": {
        "list": payload.orderNotes map ((orderNote, index) -> {
            "Topic": orderNote.topic,
            "Note": orderNote.note,
            "Mandatory": orderNote.mandatory,
            "OrderNo": payload.orderNo
        })
    },
    "OrderNo": payload.orderNo,
    "UserDefinedFields": {
        "OeHdrUdUid": payload.oeHdrUdUid
    }
}