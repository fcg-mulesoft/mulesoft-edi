%dw 2.0
output application/json
var DEBUG = false
fun norm(v) =
  if ( v is String ) (upper(trim(v)) replace /[^A-Z0-9]/ with "")
  else if ( v is Number ) (v as String)
  else ""
fun isMatch(a, b) = norm(a) == norm(b)
fun isMismatch(v) = !(v default false)
fun first(v) =
  if ( v is Array and sizeOf(v) > 0 ) v[0]
  else v
fun toNumber(v) =
  if ( v is Array ) (v[0] default 0)
  else (v default 0)
fun cleanPO(v) =
  if ( v is Array ) cleanPO(v[0])
  else if ( v is String ) (v replace "/" with "")
  else if ( v is Number ) (v as String)
  else ""
fun isPriceMatch(a, b) =
  abs(toNumber(a) - toNumber(b)) <= 0.01
var root = payload[0]
var header = root.b2bMessage.header default {
}
var ediLines = root.b2bMessage.detail.itemDetails default []
var odataLines = vars.purchaseOrderData.value default []
var shipToRaw =
  ((header.partyInformation default []) filter ($.qualifier == "ST"))[0] default {
}
var shipTo = {
	name: shipToRaw.name,
	address1: shipToRaw.address1,
	city: shipToRaw.city,
	state: shipToRaw.state,
	countryCode: shipToRaw.countryCode,
	postalCode: shipToRaw.postalCode
}
var comparison =
  ediLines map (line) -> do {
	var lineNo = first(line.lineNo)
	var buyerPart = first(line.buyerPartNo)
	var vendorPart = first(line.vendorPartNo)
	var matchedByItem =
      (odataLines filter (norm($.item_id) == norm(buyerPart)))[0]
	var matched =
      if ( matchedByItem != null ) matchedByItem
      else
        (odataLines filter (norm($.supplier_part_no) == norm(vendorPart)))[0] default {
	}
	var orderedQty = toNumber(line.quantityOrdered)
	var receivedQty = matched.qty_received default 0
	var allowedQty = matched.qty_ordered default 0
	---
	{
		lineNo: lineNo,
		buyerPart: buyerPart,
		vendorPart: vendorPart,
		// ✅ NEW VALIDATION FLAG
		buyer_match: matchedByItem != null,
		supplier_part_no: {
			original: vendorPart,
			odata: matched.supplier_part_no,
			match: isMatch(vendorPart, matched.supplier_part_no)
		},
		qty_ordered: {
			original: orderedQty,
			odata: allowedQty,
			match: (orderedQty + receivedQty) <= allowedQty
		},
		unit_price: {
			original: toNumber(line.unitPrice),
			odata: matched.unit_price,
			match: isPriceMatch(line.unitPrice, matched.unit_price)
		},
		shipTo: {
			original: shipTo,
			odata: {
				name: matched.ship2_name,
				address1: matched.ship2_add1,
				city: matched.ship2_city,
				state: matched.ship2_state,
				countryCode: matched.ship2_country,
				postalCode: matched.ship2_zip
			},
			match: {
				name: isMatch(shipTo.name, matched.ship2_name),
				address1: isMatch(shipTo.address1, matched.ship2_add1),
				city: isMatch(shipTo.city, matched.ship2_city),
				state: isMatch(shipTo.state, matched.ship2_state),
				countryCode: isMatch(shipTo.countryCode, matched.ship2_country),
				postalCode: isMatch(shipTo.postalCode, matched.ship2_zip)
			}
		}
	}
}
var itemErrors =
  (comparison map (line) -> {
	(line.buyerPart): flatten([if ( isMismatch(line.buyer_match) ) ["Item ID mismatch"] else [],
      if ( isMismatch(line.supplier_part_no.match) ) ["Supplier part number mismatch"] else [],
      if ( isMismatch(line.qty_ordered.match) ) ["Quantity exceeds ordered amount"] else [],
      if ( isMismatch(line.unit_price.match) ) ["Unit quantity exceeded"] else []])
}) reduce ((item, acc = {
}) -> acc ++ item) filterObject (sizeOf($) > 0)
var firstMatched = (odataLines[0]) default {
}
var shipToErrors =
  flatten([if ( isMismatch(isMatch(shipTo.name, firstMatched.ship2_name)) ) ["ShipTo Name mismatch"] else [],
    if ( isMismatch(isMatch(shipTo.address1, firstMatched.ship2_add1)) ) ["ShipTo Address1 mismatch"] else [],
    if ( isMismatch(isMatch(shipTo.city, firstMatched.ship2_city)) ) ["ShipTo City mismatch"] else [],
    if ( isMismatch(isMatch(shipTo.state, firstMatched.ship2_state)) ) ["ShipTo State mismatch"] else [],
    if ( isMismatch(isMatch(shipTo.countryCode, firstMatched.ship2_country)) ) ["ShipTo Country mismatch"] else [],
    if ( isMismatch(isMatch(shipTo.postalCode, firstMatched.ship2_zip)) ) ["ShipTo Zip mismatch"] else []])
var itemErrorList = flatten(valuesOf(itemErrors))
var shipErrorList = shipToErrors default []
var errorCount =
  sizeOf(itemErrorList) + sizeOf(shipErrorList)
---
{
	debug: if ( DEBUG ) {
		comparison: comparison,
		errorCount: errorCount
	} else null,
	isValid: errorCount == 0,
	validationErrors: {
		itemErrors: itemErrors,
		shipToErrors: shipToErrors,
		carrierErrors: [],
		externalPoErrors: [],
		customerPartErrors: []
	},
	warnings: []
}