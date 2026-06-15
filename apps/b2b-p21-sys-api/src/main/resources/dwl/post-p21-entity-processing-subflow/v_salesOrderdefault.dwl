%dw 2.0
output application/xml

var order = payload.Transactions[0].DataElements[0].Order

---
Order: {
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
        (order.Notes.OrderNote map (n) ->
            OrderNote: {
                Topic: n.Topic,
                Note: n.Note,
                NotepadClassId: n.NotepadClassId,
                Mandatory: n.Mandatory
            }
        )
    },

    Lines: {
        (order.Lines.OrderLine map (line) ->
            OrderLine: {
                Notes: {
                    (line.Notes.OrderLineNote map (note) ->
                        OrderLineNote: {
                            Topic: note.Topic,
                            Note: note.Note,
                            NotepadClassId: note.NotepadClassId,
                            Mandatory: note.Mandatory
                        }
                    )
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