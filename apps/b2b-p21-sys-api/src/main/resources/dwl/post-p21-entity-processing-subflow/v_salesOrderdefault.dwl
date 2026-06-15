%dw 2.0
output application/xml

var order = payload.Transactions[0].DataElements[0].Order

---
Order @(
    "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
    "xmlns:xsd": "http://www.w3.org/2001/XMLSchema"
): {
    CustomerId: order.CustomerId,
    CompanyId: order.CompanyId,
    LocationId: order.LocationId,
    ShipToId: order.ShipToId,
    PoNo: order.PoNo,
    ContactId: order.ContactId,
    Taker: order.Taker,
    Quote: order.Quote,
    Approved: order.Approved,

    Notes: {
        OrderNote: {
            Topic: order.Notes.OrderNote.Topic,
            Note: order.Notes.OrderNote.Note,
            NotepadClassId: order.Notes.OrderNote.NotepadClassId,
            Mandatory: order.Notes.OrderNote.Mandatory
        }
    },

    Lines: {
        (order.Lines.OrderLine map (line) ->
            OrderLine: {
                Notes: {
                    OrderLineNote: {
                        Topic: line.Notes.OrderLineNote.Topic,
                        Note: line.Notes.OrderLineNote.Note,
                        NotepadClassId: line.Notes.OrderLineNote.NotepadClassId,
                        Mandatory: line.Notes.OrderLineNote.Mandatory
                    }
                },

                LineNo: line.LineNo,
                ItemId: line.ItemId,
                ItemDesc: line.ItemDesc,
                ExtendedDesc: line.ExtendedDesc,
                UnitQuantity: line.UnitQuantity,
                UnitOfMeasure: line.UnitOfMeasure,
                UnitPrice: line.UnitPrice,
                QtyOrdered: line.QtyOrdered,
                ExtendedPrice: line.ExtendedPrice,
                SourceLocId: line.SourceLocId
            }
        )
    }
}