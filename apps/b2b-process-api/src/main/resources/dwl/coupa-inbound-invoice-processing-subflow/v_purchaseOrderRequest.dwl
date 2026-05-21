%dw 2.0
output application/xml
---
{
	Order @("xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd": "http://www.w3.org/2001/XMLSchema"): {
		CustomerId: payload.value[0].customer_id,
		CompanyId: 	payload.value[0].company_id,
		LocationId: payload.value.preferred_location_id[0],
		ShipToId:payload.value.ship_to_id[0],
		PoNo: vars.initialPayload.Order.PoNo,
		ContactId: payload.value.edi_default_contact_id[0],
		Taker: vars.initialPayload.Order.Taker default "MULESOFTINT",
		Notes: {
			OrderNote: {
				Topic: vars.initialPayload.Order.Notes.OrderNote.Topic,
				Note: vars.initialPayload.Order.Notes.OrderNote.Note,
				NotepadClassId: vars.initialPayload.Order.Notes.OrderNote.NotepadClassId
			}
		},
		Lines: vars.initialPayload.Order.Lines
	}
}