%dw 2.0
import trim from dw::core::Strings
output application/xml skipNullOn="everywhere"

var theirItemIds =
    (vars.partsPriceResponse.value.their_item_id default [])
        map (v) -> lower(trim((v default "") as String))
        filter ($ != "")

var ourItemIds =
    (vars.partsPriceResponse.value.our_item_id default [])
        map (v) -> lower(trim((v default "") as String))
        filter ($ != "")

var itemIDSearch = (theirItemIds ++ ourItemIds) distinctBy $

var defaultItemId = Mule::p('edi.default.item.id')

fun money(v) = "\u0024" ++ (((v default 0) as Number) as String { format: "0.00" })

fun lineItemId(line) = trim((line.ItemId default "") as String)
fun lineNo(line) = (line.LineNo default "") as String
fun lineQty(line) = (line.QtyOrdered default line.UnitQuantity default 0) as Number
fun linePrice(line) = (line.UnitPrice default 0) as Number
fun lineCost(line) = (line.CommissionCost default line.OtherCost default linePrice(line)) as Number

fun lineDesc(line) =
    trim(
        ((line.ItemId default "") as String) ++ " " ++
        ((line.ItemDesc default "") as String) ++ " " ++
        ((line.ExtendedDesc default "") as String)
    )

fun lineNoteText(line) =
    lineDesc(line) ++
    " | Cost: " ++ money(lineCost(line)) ++
    " | Qty: " ++ ((lineQty(line)) as String) ++
    " | Price: " ++ money(linePrice(line))

fun headerLineText(line) =
    "Line" ++ lineNo(line) ++ " | " ++ lineNoteText(line)

fun isMatched(line) =
    do {
        var id = lower(lineItemId(line))
        ---
        (id != "") and (itemIDSearch contains id)
    }

fun getOurItemIdFromLine(line) =
    do {
        var id = lower(lineItemId(line))
        var matchedRecord = (vars.partsPriceResponse.value filter (
            lower(trim(($.their_item_id default "") as String)) == id or 
            lower(trim(($.our_item_id default "") as String)) == id
        ))[0]
        ---
        matchedRecord.our_item_id default lineItemId(line)
    }

fun isValidLine(line) = 
    line != null and !isEmpty(line)

fun formatCostDate(costDate) =
    if (isEmpty(costDate)) 
        ""
    else if ((costDate as String) contains "T")
        ((costDate as String) splitBy /[-+]\d{2}:\d{2}$/)[0] default (costDate as String)
    else
        costDate as String

fun getCostDate(line) =
    do {
        var id = lower(lineItemId(line))
        var matchedRecord = (vars.partsPriceResponse.value filter (
            lower(trim(($.their_item_id default "") as String)) == id or
            lower(trim(($.our_item_id default "") as String)) == id
        ))[0]
        var costDate = matchedRecord.cost_date default ""
        ---
        formatCostDate(costDate)
    }

fun lookupOurItemId(theirItemId) =
    do {
        var id = lower(trim((theirItemId default "") as String))
        var matchedRecord = (vars.partsPriceResponse.value filter (
            lower(trim(($.their_item_id default "") as String)) == id or
            lower(trim(($.our_item_id default "") as String)) == id
        ))[0]
        ---
        matchedRecord.our_item_id default theirItemId
    }

var rawLines = vars.initialPayload.Order.Lines.*OrderLine default []
var linesArr = if (rawLines is Array) rawLines else [rawLines]
var validLinesArr = linesArr filter (line) -> isValidLine(line)

var unmatchedLines = validLinesArr filter (line) -> not isMatched(line)

var headerNoteText =
    ((unmatchedLines map (line) -> headerLineText(line)) joinBy " | ") ++
    (if (sizeOf(unmatchedLines) > 0) " |" else "")

---
{
  Order @("xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd": "http://www.w3.org/2001/XMLSchema"): {
    CustomerId: vars.poSearchResponse.value[0].customer_id,
    CompanyId: vars.poSearchResponse.value[0].company_id,
    LocationId: vars.poSearchResponse.value[0].preferred_location_id,
    ShipToId: vars.poSearchResponse.value[0].ship_to_id,
    PoNo: vars.initialPayload.Order.PoNo,
    ContactId: vars.poSearchResponse.value[0].edi_default_contact_id default null,
    Taker: vars.poSearchResponse.value[0].edi_default_taker default "MULESOFTINT",
    Quote: "N",
    Approved: "false",

    Notes:
      if (sizeOf(unmatchedLines) > 0)
        {
          OrderNote: {
            Topic: "EDI_HEADER",
            Note: headerNoteText,
            NotepadClassId: "ITEMS"
          }
        }
      else
        vars.initialPayload.Order.Notes,

    Lines: 
      if (sizeOf(validLinesArr) > 0)
        {
          OrderLine:
            validLinesArr map (line) ->
              (
                if (isMatched(line))
                  ((line - "UserDefinedFields") mapObject ((value, key) -> 
                    if (isEmpty(value)) {} 
                    else if (key as String == "ItemId") {(key): lookupOurItemId(value)} 
                    else {(key): value}
                  ))
                else
                  (((line - "ItemId" - "Notes" - "UserDefinedFields") mapObject ((value, key) -> 
                    if (isEmpty(value)) {} 
                    else {(key): value}
                  )) ++ {
                    ItemId: defaultItemId,
                    Notes: {
                      OrderLineNote: {
                        Topic: "EDI_LINE1",
                        Note: lineNoteText(line),
                        NotepadClassId: "ITEMS"
                      }
                    }
                  })
              )
              ++
              (
                if (!isEmpty(getCostDate(line)))
                  {
                    UserDefinedFields: {
                      LocCostDate: getCostDate(line)
                    }
                  }
                else
                  {}
              )
        }
      else
        null
  }
}