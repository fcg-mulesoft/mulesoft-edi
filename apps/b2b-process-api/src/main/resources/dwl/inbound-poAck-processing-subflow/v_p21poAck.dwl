%dw 2.0
output application/json

fun formatDate(d) = 
    if (d is String) 
        ((d as DateTime) as String {format: "MM/dd/yyyy"}) 
    else ""

---
{

  UseCodeValues: true,
  IgnoreDisabled: true,
  Transactions: payload map (wrapper) -> do {
    
    var txn = wrapper.b2bMessage
    var items = txn.detail.itemDetails default []
    var poNum = txn.header.poNumber default ""
    
    ---
    {
      Status: "New",
      DataElements: [
        {
          Name: "TABPAGE_1.tp_1_dw_1",
          Type: "Form",
          Keys: ["po_no"],
          Rows: [
            {
              Edits: [
                {
                  Name: "po_no",
                  Value: poNum
                },
                {
                  Name: "external_po_no",
                  Value: "/" ++ poNum
                },
                {
                  Name: "ufc_po_hdr_ud_supplier_acknowledgement",
                  Value: poNum
                }
              ]
            }
          ]
        },
        {
          Name: "TABPAGE_17.tp_17_dw_17",
          Type: "List",
          Keys: ["line_no", "item_id"],
          Rows: items map (item, index) -> {
            Edits: [
              {
                Name: "line_no",
                Value: (index + 1) as String
              },
              {
                Name: "item_id",
                Value: item.buyerPartNo default ""
              },
              {
                Name: "acknowledged",
                Value: "Y"
              },
              {
                Name: "acknowledged_date",
                Value: formatDate(item.acknowledgments[0].scheduledDate)
              }
            ]
          }
        },
        {
          Name: "TABPAGE_18.extended_info",
          Type: "List",
          Keys: ["item_id"],
          Rows: items map (item) -> {
            Edits: [
              {
                Name: "item_id",
                Value: item.buyerPartNo default ""
              },
              {
                Name: "acknowledged",
                Value: "Y"
              },
              {
                Name: "acknowledged_date",
                Value: formatDate(item.acknowledgments[0].scheduledDate)
              }
            ]
          }
        }
      ]
    }
  }
}