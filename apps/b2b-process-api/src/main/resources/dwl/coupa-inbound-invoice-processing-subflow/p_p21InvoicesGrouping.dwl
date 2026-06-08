%dw 2.0
output application/json
var grouped = vars.p21Response.value groupBy ((item) -> item.invoice_no)
---
grouped pluck ((lines, invNo) -> {
    invoice_no: invNo,
    invoice_date: lines[0].invoice_date,
    from_domain: lines[0].from_domain,
    from_identity: lines[0].from_identity,
    to_domain: lines[0].to_domain,
    to_identity: "ADMCoupaidentity",
    customer_id: lines[0].customer_id,
    buyer_name: lines[0].buyer_name,
	buyer_customer_id: lines[0].buyer_customer_id,
    buyer_addr: lines[0].buyer_addr,
    buyer_city: lines[0].buyer_city,
    buyer_state: lines[0].buyer_state,
    ship2_name: lines[0].ship2_name,
    ship2_address1: lines[0].ship2_address1,
    ship2_city: lines[0].ship2_city,
    ship2_state: lines[0].ship2_state,
    ship2_postal_code: lines[0].ship2_postal_code,
    order_no: lines[0].order_no,
    ship_date: lines[0].ship_date,
    total_amount: lines[0].total_amount,
    tax_amount: lines[0].tax_amount,
    freight: lines[0].freight,
	vendor_name: lines[0].vendor_name,
    vendor_supplier_id: lines[0].vendor_supplier_id,
    vendor_addr: lines[0].vendor_addr,
    vendor_city: lines[0].vendor_city,
    vendor_state: lines[0].vendor_state,
	ship_from_name: lines[0].ship_from_name,
    ship_from_addr: lines[0].ship_from_addr,
    ship_from_city: lines[0].ship_from_city,
    ship_from_state: lines[0].ship_from_state,
	remit_street: lines[0].Remit_Street,
    remit_name: lines[0].Remit_Name,
    remit_id: lines[0].Remit_ID,
    remit_city: lines[0].Remit_City,
    remit_state: lines[0].Remit_State,
    remit_postalcode: lines[0].Remit_Postalcode,
    company_id: lines[0].company_id,
    order_date: lines[0].order_date,
    order_price_code: lines[0].order_price_code,
    total_line_count: sizeOf(lines),
    //all line items for this invoice, distinct and ordered
    lines: 
        (lines distinctBy ((l) -> l.line_no))
        orderBy ((l) -> l.line_no)
        map (l,index) -> {
            line_no: l.line_no,
            item_id: l.item_id,
            item_desc: l.item_desc,
            qty_shipped: l.qty_shipped,
            unit_price: l.unit_price,
            unit_of_measure: l.unit_of_measure,
            po_no: l.po_no,
            location_id: l.location_id,
            inv_mast_uid: l.inv_mast_uid,
            vendor_part_no: l.vendor_part_no,
            buyer_customer_id: l.buyer_customer_id,
            ship_from_name: l.ship_from_name,
            ship_from_addr: l.ship_from_addr,
            ship_from_city: l.ship_from_city,
            ship_from_state: l.ship_from_state
        }
})