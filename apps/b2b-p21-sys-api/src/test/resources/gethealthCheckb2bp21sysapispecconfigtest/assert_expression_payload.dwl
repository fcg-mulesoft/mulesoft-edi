%dw 2.0
import * from dw::test::Asserts
---
payload must equalTo({
  "application": "fcg_api_name",
  "status": "success"
})