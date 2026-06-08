%dw 2.0

output application/xml encoding="UTF-8", indent=true

ns xsd http://www.w3.org/2001/XMLSchema
ns xsi http://www.w3.org/2001/XMLSchema-instance

var p21 = {
    companyId       : "",
    locationId      : "",
    sourceLocationId: "",
    taker           : "",
    salesrepId      : "",
    carrierId       : "",
    invoiceBatchNo  : "",
    customerId      : "",
    contactId       : "",
    shipToId        : "",
    upsCode         : ""
}

var orderHeader = payload.cXML.Request.OrderRequest.OrderRequestHeader
var items       = payload.cXML.Request.OrderRequest.*ItemOut default []
var shipTo      = orderHeader.ShipTo.Address
var shipPostal  = shipTo.PostalAddress
var streets     = shipPostal.*Street default []
var edixRefId   = orderHeader.ShipTo.Address.@addressID default ""

fun toP21DateTime(dtStr: String): String =
    if (isEmpty(dtStr)) ""
    else (dtStr as DateTime {format: "yyyy-MM-dd'T'HH:mm:ssxxx"}) as String {format: "yyyy-MM-dd'T'HH:mm:ss.SSS"}

fun toP21Date(dateStr: String): String =
    if (isEmpty(dateStr)) ""
    else ((dateStr as Date {format: "yyyy-MM-dd"}) as String {format: "yyyy-MM-dd"}) ++ "T00:00:00"

fun buildHeaderNote(lineItems: Array): String =
    (lineItems map ((item, idx) ->
        "Line" ++ ((item.@lineNumber default (idx + 1)) as String) ++
        " | " ++ ((item.ItemDetail.Description default "") as String) ++
        " | Qty: " ++ ((item.@quantity default "0") as String) ++
        " | Price: USD " ++ ((item.ItemDetail.UnitPrice.Money default "0") as String)
    )) joinBy "\n"

fun getSegment(item: Object, segDesc: String): String =
    ((item.Distribution.Accounting.*Segment filter ($.@description == segDesc))[0].@id) default ""

var quoteExtrinsic = ((orderHeader.*Extrinsic filter ($.@name == "quote"))[0]) default ""
var quoteFlag      = if (!isEmpty(quoteExtrinsic as String)) "Y" else "N"
var firstLineDate  = (items[0].@requestedDeliveryDate) default ""
var orderDateStr   = (orderHeader.@orderDate default "") as String
var endUserContact = ((orderHeader.*Contact filter ($.@role == "endUser"))[0]) default {}
---
Order @("xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd": "http://www.w3.org/2001/XMLSchema"): {
    Lines: {
        (items map ((item) ->
            OrderLine: {
                Serials   : {},
                Lots      : {},
                Bins      : {},
                LotBins   : {},
                Notes: {
                    OrderLineNote: {
                        Topic         : "EDI_LINE" ++ ((item.@lineNumber default "1") as String),
                        Note          : (item.ItemDetail.Description default "") as String,
                        NotepadClassId: "ITEMS",
                        Mandatory     : "Y"
                    }
                },
                LineRooms            : {},
                LineNo               : item.@lineNumber default "1",
                ItemId               : (item.ItemID.SupplierPartID default "") as String,
                UnitQuantity         : item.@quantity default "1",
                UnitOfMeasure        : item.ItemDetail.UnitOfMeasure default "EA",
                UnitPrice            : item.ItemDetail.UnitPrice.Money default "0",
                SourceLocId          : p21.locationId,
                ShipLocId            : p21.locationId,
                ProductGroupId       : "DEFAULT",
                RequiredDate         : toP21Date((item.@requestedDeliveryDate default "") as String),
                ExpediteDate         : toP21Date((item.@requestedDeliveryDate default "") as String),
                WillCall             : "N",
                TaxItem              : "Y",
                PricingUnit          : item.ItemDetail.UnitOfMeasure default "EA",
                CommissionCost       : (item.Distribution.Charge.Money default "0") as Number,
                OtherCost            : (item.Distribution.Charge.Money default "0") as Number,
                PoCost               : 0,
                Disposition          : "B",
                ManualPriceOveride   : "Y",
                CaptureUsage         : "Y",
                ContractBinId        : {},
                JobNo                : {},
                PromiseDate          : toP21Date((item.@requestedDeliveryDate default "") as String),
                ExtendedPrice        : ((item.ItemDetail.UnitPrice.Money default "0") as Number)
                                       * ((item.@quantity default "1") as Number),
                CompanyId            : p21.companyId,
                QtyOrdered           : item.@quantity default "1",
                Delete               : "N",
                Buy                  : "Y",
                SecondaryUnitPrice   : 0,
                SecondaryExtendedPrice: 0,
                OtherCostEdited      : "P",
                CommissionCostEdited : "P",
                UserDefinedFields    : {}
            }
        ))
    },
    Notes: {
        OrderNote: {
            Topic         : "EDI_HEADER",
            Note          : buildHeaderNote(items),
            NotepadClassId: "ITEMS",
            Mandatory     : "true"
        }
    },
    Salesreps: {
        OrderSalesrep: {
            SalesrepId                : p21.salesrepId,
            CommissionSplit           : 100,
            Delete                    : "N",
            PrimarySalesrep           : true,
            ExcludeSplitValidationFlag: false,
            UserDefinedFields         : {}
        }
    },
    BuilderSelectionSheets   : {},
    Samples                  : {},
    CustomerId               : p21.customerId,
    CompanyId                : p21.companyId,
    LocationId               : p21.locationId,
    PoNo                     : (orderHeader.@orderID default "") as String,
    ContactId                : p21.contactId,
    Taker                    : p21.taker,
    JobName                  : {},
    OrderDate                : toP21DateTime(orderDateStr),
    RequestedDate            : toP21Date(orderDateStr[0 to 9]),
    Approved                 : true,
    ShipToId                 : p21.shipToId,
	edixRefId				 : edixRefId,
    ShipToName               : (shipTo.Name default "") as String,
    ShipToAddress1           : (streets[0] default "") as String,
    ShipToAddress2           : (streets[1] default "") as String,
    ShipToAddress3           : {},
    ShipToCity               : (shipPostal.City default "") as String,
    OeHdrShip2State          : (shipPostal.State default "") as String,
    ZipCode                  : (shipPostal.PostalCode default "") as String,
    ShipToCountry            : (shipTo.@isoCountryCode default "US") as String,
    ShipToMailAddress        : (endUserContact.Email default (shipTo.Email default "")) as String,
    ShipToPhone              : {},
    SourceLocationId         : p21.sourceLocationId,
    CarrierId                : p21.carrierId,
    Route                    : {},
    PackingBasis             : "Partial",
    DeliveryInstructions     : {},
    Terms                    : (orderHeader.PaymentTerm.@payInNumberOfDays default "") as String,
    WillCall                 : "N",
    Class1id                 : if (!isEmpty(items)) getSegment(items[0], "Site ID")  else "",
    Class2id                 : if (!isEmpty(items)) getSegment(items[0], "Loc_Resp") else "",
    Class3id                 : if (!isEmpty(items)) getSegment(items[0], "Dept_Sub") else "",
    Class4id                 : if (!isEmpty(items)) getSegment(items[0], "GL")       else "",
    Class5id                 : {},
    RMA                      : "N",
    FreightCd                : "FFA",
    BillingDescription       : "Bill Recipient",
    CaptureUsage             : true,
    JobNo                    : {},
    InvoiceBatchNumber       : p21.invoiceBatchNo,
    InvoiceExchangeRateSource: "Invoice",
    ApplyBuilderAllowanceFlag: "N",
    QuoteExpirationDate @("xsi:nil": "true"): "",
    PromiseDate              : toP21Date(firstLineDate),
    CreateInvoice            : false,
    CStrategicPriceLibraryId : {},
    MerchandiseCreditFlag    : "N",
    OrderPriorityId          : {},
    UpsCode                  : p21.upsCode,
    PlacedByName             : (endUserContact.Name default "") as String,
    RequiredPaymentUponRelease: "N",
    FreightOut               : (orderHeader.Shipping.Money default "0") as Number,
    PickTicketType           : "UT",
    ThirdPartyBilling        : "B",
    UserDefinedFields        : {},
    CurrencyID               : 1,
    Completed                : "N",
    Quote                    : quoteFlag,
    DeletedFlag              : "N",
    CancelledFlag            : "N",
    InvoiceNo                : {},
    QuoteType @("xsi:nil": "true"): "",
    WebReferenceNo           : {}
}