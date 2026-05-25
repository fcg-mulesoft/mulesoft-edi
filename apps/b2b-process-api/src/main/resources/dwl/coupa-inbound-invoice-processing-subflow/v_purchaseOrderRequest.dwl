%dw 2.0
output application/xml
var itemIDSearch = vars.partsPriceResponse.ArrayOfItemPrice.*ItemPrice.ItemId default []
var hardCodedNotes = {
    Notes: {
        OrderLineNote: {
            Topic: "TEST EDI LINE",
            Note: "Item is not matching",
            NotepadClassId: "ITEMS"
        }
    }
}
---
{
	Order @("xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd": "http://www.w3.org/2001/XMLSchema"): {
		CustomerId: vars.poSearchResponse.value[0].customer_id,
		CompanyId: 	vars.poSearchResponse.value[0].company_id,
		LocationId: vars.poSearchResponse.value[0].preferred_location_id,
		ShipToId: vars.poSearchResponse.value[0].ship_to_id,
		PoNo: vars.initialPayload.Order.PoNo,
		ContactId: payload.value.edi_default_contact_id[0],
		Taker: vars.initialPayload.Order.Taker default "MULESOFTINT",
		Quote: "N",
        Approved: "false",
		Notes: {
			OrderNote: {
				Topic: vars.initialPayload.Order.Notes.OrderNote.Topic,
				Note: vars.initialPayload.Order.Notes.OrderNote.Note,
				NotepadClassId: vars.initialPayload.Order.Notes.OrderNote.NotepadClassId
			}
		},
		Lines: vars.initialPayload.Order.Lines update {
    			case line at .OrderLine ->
        			if (itemIDSearch contains (line.ItemId as Number))
            			line - "Notes"
        		else
            		line update {
                		case .Notes -> hardCodedNotes.Notes
            	}
		}
	}
}