%dw 2.0
output application/xml skipNullOn="everywhere"

var orderPayload = payload.Transactions[0].DataElements[0].Order

---
Order @(
    "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
    "xmlns:xsd": "http://www.w3.org/2001/XMLSchema"
): {
    CustomerId: orderPayload.CustomerId,
    CompanyId: orderPayload.CompanyId,
    LocationId: orderPayload.LocationId,
    ShipToId: orderPayload.ShipToId,
    PoNo: orderPayload.PoNo,
    ContactId: orderPayload.ContactId,
    Taker: orderPayload.Taker,
    Quote: orderPayload.Quote,
    Approved: orderPayload.Approved,

    Notes: {
        OrderNote: {
            Topic: orderPayload.Notes.OrderNote.Topic,
            Note: orderPayload.Notes.OrderNote.Note,
            NotepadClassId: orderPayload.Notes.OrderNote.NotepadClassId,
            Mandatory: orderPayload.Notes.OrderNote.Mandatory
        }
    },

    Lines: {
        OrderLine: {
            Notes: {
                OrderLineNote: {
                    Topic: orderPayload.Lines.OrderLine.Notes.OrderLineNote.Topic,
                    Note: orderPayload.Lines.OrderLine.Notes.OrderLineNote.Note,
                    NotepadClassId: orderPayload.Lines.OrderLine.Notes.OrderLineNote.NotepadClassId,
                    Mandatory: orderPayload.Lines.OrderLine.Notes.OrderLineNote.Mandatory
                }
            },

            LineNo: orderPayload.Lines.OrderLine.LineNo,
            ItemId: orderPayload.Lines.OrderLine.ItemId,
            ItemDesc: orderPayload.Lines.OrderLine.ItemDesc,
            ExtendedDesc: orderPayload.Lines.OrderLine.ExtendedDesc,
            UnitQuantity: orderPayload.Lines.OrderLine.UnitQuantity,
            UnitOfMeasure: orderPayload.Lines.OrderLine.UnitOfMeasure,
            UnitPrice: orderPayload.Lines.OrderLine.UnitPrice,
            QtyOrdered: orderPayload.Lines.OrderLine.QtyOrdered,
            ExtendedPrice: orderPayload.Lines.OrderLine.ExtendedPrice,
            SourceLocId: orderPayload.Lines.OrderLine.SourceLocId
        }
    }
}