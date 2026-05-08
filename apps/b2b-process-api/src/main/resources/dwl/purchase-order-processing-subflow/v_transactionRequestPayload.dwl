%dw 2.0
output application/json
---
{
  UseCodeValues: true,
  IgnoreDisabled: true,
  Transactions: payload map (item) -> {
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
                Value: item.payload.poNumber default ""
              },
              {
                Name: "vendor_id",
                Value: item.payload.partnerId default ""
              },
              {
                Name: "ufc_po_hdr_ud_edi_po_status",
                Value: 
                  if ((item.payload.status default "") == "SUCCESS") 
                    "Transmitted"
                  else 
                    "Failed"
              }
            ]
          }
        ]
      }
    ]
  }
}