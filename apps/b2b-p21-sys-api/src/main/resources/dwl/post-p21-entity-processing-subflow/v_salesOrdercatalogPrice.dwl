%dw 2.0
output application/xml
var order = payload.Transactions[0].DataElements[0].Order
---
{
	ArrayOfItemPriceInfo @("xmlns:xsd": "http://www.w3.org/2001/XMLSchema",
        "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance"): {
		ItemPriceInfo: payload.Transactions[0].DataElements[0].ArrayOfItemPriceInfo.ItemPriceInfo map (item) -> {
			ItemId: item.ItemId,
			SourceLocId: item.SourceLocId,
			CustomerPartNo: item.CustomerPartNo,
			UnitQuantity: item.UnitQuantity,
			UnitSize: item.UnitSize,
			UOM: item.UOM
		}
	}
}