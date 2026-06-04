%dw 2.0
output application/json
---
{
    "method": Mule::p('b2b-inbound-partner-mgmt-api.coupa-invoice.method'),
    "host": Mule::p('b2b-inbound-partner-mgmt-api.host'),
    "port": Mule::p('b2b-inbound-partner-mgmt-api.port'),
    "basePath": Mule::p('b2b-inbound-partner-mgmt-api.basePath'),
    "path": Mule::p('b2b-inbound-partner-mgmt-api.coupa-invoice.path'),
    "headers": {
        "x-correlation-id": correlationId
    },
    "queryParams": {
    },
    "uriParams": {
    },
    "body": {
      value: [{
        from_domain: payload.from_domain,
        from_identity: payload.from_identity,
        to_domain: payload.to_domain,
        to_identity: "ADMCoupaidentity",
        invoice_no: payload.invoice_no,
        invoice_date: payload.invoice_date,
        total_amount: payload.total_amount,
        tax_amount: payload.tax_amount,
        freight: payload.freight,
        ship2_name: payload.ship2_name,
        ship2_address1: payload.ship2_address1,
        ship2_city: payload.ship2_city,
        ship2_state: payload.ship2_state,
        ship2_postal_code: payload.ship2_postal_code,
        customer_id: payload.customer_id,
        order_no: payload.order_no,
        ship_date: payload.ship_date,
        inv_mast_uid: payload.inv_mast_uid,
        company_id: payload.company_id,
        line_no: payload.line_no,
        qty_shipped: payload.qty_shipped,
        unit_price: payload.unit_price,
        unit_of_measure: payload.unit_of_measure,
        po_no: payload.po_no,
        order_date: payload.order_date,
        location_id: payload.location_id,
        address_id: payload.address_id,
        item_id: payload.item_id,
        item_desc: payload.item_desc default payload.inv_item_desc,
        customer_part_number: payload.customer_part_number,
        buyer_name: payload.buyer_name,
        buyer_customer_id: payload.buyer_customer_id,
        buyer_addr: payload.buyer_addr,
        buyer_city: payload.buyer_city,
        buyer_state: payload.buyer_state,
        vendor_name: payload.vendor_name,
        vendor_supplier_id: payload.vendor_supplier_id,
        vendor_addr: payload.vendor_addr,
        vendor_city: payload.vendor_city,
        vendor_state: payload.vendor_state,
        ship_from_name: payload.ship_from_name,
        ship_from_location_id: payload.ship_from_location_id,
        ship_from_addr: payload.ship_from_addr,
        ship_from_city: payload.ship_from_city,
        ship_from_state: payload.ship_from_state,
        order_price_code: payload.order_price_code,
        total_line_count: vars.totalLineCount default 1,
        remit_street: payload.Remit_Street,
        remit_name: payload.Remit_Name,
        remit_id: payload.Remit_ID,
        remit_city: payload.Remit_City,
        remit_state: payload.Remit_State,
        remit_postalcode: payload.Remit_Postalcode
      }]
    },
    "untilsuccessful": {
        "maxRetries": Mule::p('b2b-inbound-partner-mgmt-api.coupa-invoice.untilsuccessful.maxRetries'),
        "interval": Mule::p('b2b-inbound-partner-mgmt-api.coupa-invoice.untilsuccessful.interval')
    }
}