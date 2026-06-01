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
	  value: vars.p21Response.value map (item) -> {
	    from_domain: item.from_domain,
	    from_identity: item.from_identity,
	    to_domain: item.to_domain,
	    to_identity: "ADMCoupaidentity",
	    invoice_no: item.invoice_no,
	    invoice_date: item.invoice_date,
	    total_amount: item.total_amount,
	    tax_amount: item.tax_amount,
	    freight: item.freight,
	    ship2_name: item.ship2_name,
	    ship2_address1: item.ship2_address1,
	    ship2_city: item.ship2_city,
	    ship2_state: item.ship2_state,
	    ship2_postal_code: item.ship2_postal_code,
	    customer_id: item.customer_id,
	    order_no: item.order_no,
	    ship_date: item.ship_date,
	    inv_mast_uid: item.inv_mast_uid,
	    company_id: item.company_id,
	    line_no: item.line_no,
	    qty_shipped: item.qty_shipped,
	    unit_price: item.unit_price,
	    unit_of_measure: item.unit_of_measure,
	    po_no: item.po_no,
	    order_date: item.order_date,
	    location_id: item.location_id,
	    address_id: item.address_id,
	    item_id: item.item_id,
	    item_desc: item.item_desc default item.inv_item_desc,
	    customer_part_number: item.customer_part_number,
	    buyer_name: item.buyer_name,
	    buyer_customer_id: item.buyer_customer_id,
	    buyer_addr: item.buyer_addr,
	    buyer_city: item.buyer_city,
	    buyer_state: item.buyer_state,
	    vendor_name: item.vendor_name,
	    vendor_supplier_id: item.vendor_supplier_id,
	    vendor_addr: item.vendor_addr,
	    vendor_city: item.vendor_city,
	    vendor_state: item.vendor_state,
	    ship_from_name: item.ship_from_name,
	    ship_from_location_id: item.ship_from_location_id,
	    ship_from_addr: item.ship_from_addr,
	    ship_from_city: item.ship_from_city,
	    ship_from_state: item.ship_from_state,
	    order_price_code: item.order_price_code,
	    total_line_count: sizeOf(payload.value),  // or groupBy if needed
	    remit_street: item.Remit_Street,
	    remit_name: item.Remit_Name,
	    remit_id: item.Remit_ID,
	    remit_city: item.Remit_City,
	    remit_state: item.Remit_State,
	    remit_postalcode: item.Remit_Postalcode
	  }
	},
	"untilsuccessful": {
		"maxRetries": Mule::p('b2b-inbound-partner-mgmt-api.coupa-invoice.untilsuccessful.maxRetries'),
		"interval": Mule::p('b2b-inbound-partner-mgmt-api.coupa-invoice.untilsuccessful.interval')
	}
}