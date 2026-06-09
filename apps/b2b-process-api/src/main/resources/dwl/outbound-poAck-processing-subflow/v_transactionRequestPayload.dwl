%dw 2.0
output application/json

---
{
  Name: "Order",
  Transactions: payload map (item) -> {
    Status: "New",
    DataElements: [
      {
        Name: "TABPAGE_1.order",
        Type: "Form",
        Keys: [
          "order_no"
        ],
        Rows: [
          {
            Edits: [
              {
                Name: "order_no",
                Value: item.payload.poNumber
              },
              {
                Name: "ufc_oe_hdr_ud_edi_so_status",
                Value: 
                  if ((item.payload.status default "") == "SUCCESS")
                    "Acknowledge"
                  else
                    "Acknowledged Faile"
              }
            ]
          }
        ]
      }
    ]
  }
}
