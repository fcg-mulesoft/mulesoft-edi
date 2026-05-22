%dw 2.0
output application/xml
---
{
	ArrayOfItemPriceInfo @("xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd": "http://www.w3.org/2001/XMLSchema"): {
		ItemPriceInfo: vars.initialPayload.Order.Lines.*OrderLine map ((item, index) -> 
        {
            ItemId: item.ItemId,
            SourceLocId: item.SourceLocId,
            CustomerPartNo: "", //To be Mapped
            UnitQuantity: item.UnitQuantity,
            UnitSize: "", //To be Mapped
            UOM: item.UnitOfMeasure
        })
    }
}