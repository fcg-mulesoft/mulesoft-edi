%dw 2.0
import try from dw::Runtime

/**
 * Converts input String of potential Date or DateTime to an output String in Date format
 * 
 * Takes an input timeZone to convert a DateTime to before returning a Date String.
 */
fun cvtDateTimeStringToDateStringTz(inString: Date | DateTime | String | Null, targetTimeZone: String): String | Null = do {
    var inDateTime: Object = (
    				try(() -> (((inString default "" ) as DateTime) >> targetTimeZone)
    		))
    var inDate: Object = 
        if (inDateTime.success)
                (inDateTime) update {
                    case dateTimeResult at .result -> (dateTimeResult as Date)
                }
            else
                (try(() -> (inString as Date)))
    ---
    if (inDate.success)
        inDate.result as String
    else
        null
}

/**
 * Formats a quote expiration date by appending end-of-day time
 * 
 * This function takes a date string and converts it to a datetime string
 * representing the end of that day (23:59:59). This is commonly used in
 * business logic where quotes should expire at the end of the specified date
 * rather than at midnight (beginning of day).
 * 
 * @param expirationDate - Input date as String or Null
 * @return String representing the formatted datetime with end-of-day time, or Null
 */
fun formatQuoteExpirationDate(expirationDate: String | Null): String | Null = do {
	var tz = "America/New_York"
    var cvtDate = cvtDateTimeStringToDateStringTz(expirationDate, tz)
    ---
    // Check if expirationDate is not null AND can be successfully converted to Date type
    if (cvtDate != null)
        cvtDate as String ++ "T23:59:59"
    else 
        // Return null if input is null or cannot be converted to a valid Date
        null
}

/**
 * Function to extract quotedByEmail values from input array
 * Returns comma-separated string of emails or null if no emails found
 * 
 * This function handles both single quote objects and arrays of quote objects,
 * making it flexible for different payload structures. It filters out null
 * email values and concatenates valid emails into a single string.
 * 
 * @param pload - Input payload (can be Array of quote objects or single quote object)
 * @return String of comma-separated emails, single email string, or null
 */
fun extractQuotedByEmails(pload): String | Null = do {
    var emails =
    	if (pload == null)
    		null
    	else if (pload is Array)
			pload 
				filter ($.quote.pdfInfo.quotedByEmail != null) 
				map $.quote.pdfInfo.quotedByEmail
		else
			pload.quote.pdfInfo.quotedByEmail
    ---
    if (emails is Array and sizeOf(emails) > 0) 
        emails joinBy ","
    else 
        emails
}

/*
 * The payload structure is different for ServiceQuotes
 */
fun extractQuotedByEmailsServiceQuote(pload): String | Null = do {
    var emails =
    	if (pload == null)
    		null
    	else if (pload is Array)
			pload 
				filter ($.pdfInfo.quotedByEmail != null) 
				map $.pdfInfo.quotedByEmail
		else
			pload.pdfInfo.quotedByEmail
    ---
    if (emails is Array and sizeOf(emails) > 0) 
        emails joinBy ","
    else 
        emails
}

/**
 * Recursively removes null values from objects and arrays
 * @param value - The input value to process (can be Object, Array, or primitive)
 * @returns The processed value with null values removed
 */
fun removeNulls(value) =
  // Check if the input value is an Object type
  if (value is Object)
    value
      // First, filter out any key-value pairs where the value is null
      filterObject ((val, key) -> val != null)
      // Then, recursively process each remaining value to remove nested nulls
      mapObject ((val, key) -> (key): removeNulls(val))
  
  // Check if the input value is an Array type
  else if (value is Array)
    // First, filter out any null values from the array, then recursively process remaining items
    (value filter (item) -> item != null) map (item) -> removeNulls(item)
  
  // For primitive values (strings, numbers, booleans, etc.)
  else
    // Return the value as-is since primitives cannot contain nested nulls
    value

/**
 * Formats monetary values to display with 2 decimal places
 * 
 * @param value - The numeric value to format
 * @return String representing the formatted monetary value
 */
fun formatMoney(value: Number | Null): String =
    (value default 0) as String {format: "0.00"}
    
/**
 * Builds the enhanced note format for I2P Default Items
 * Format: <Product Name> | <Product Number> | <Vendor> | Cost: $<Unit Cost> | Qty: <Quantity> | Price: $<Unit Price>
 * 
 * @param product - The product object containing all product details
 * @return String representing the formatted note
 */
fun buildEnhancedNote(product): String = 
    (product.name default "Unknown Name") ++ " | " ++ 
    (product.itemNo default "Unknown ItemNo") ++ " | " ++ 
    (product.vendorName default "") ++ " | " ++ 
    "Cost: \$" ++ formatMoney(product.lastCostPaid) ++ " | " ++ 
    "Qty: " ++ (product.quantity default 0) ++ " | " ++ 
    "Price: \$" ++ formatMoney(product.revisedPrice)
    
var encodingMap = {
       // " ": "%20",  // or "+" for query strings, but using %20 for general purpose
        "!": "%21",
        "\"": "%22",
        "#": "%23",
        "\$": "%24",
        "%": "%25",
        "&": "%26",
        "'": "%27",
        "(": "%28",
        ")": "%29",
        "*": "%2A",
        "+": "%2B",
        ",": "%2C",
        "/": "%2F",
        ":": "%3A",
        ";": "%3B",
        "<": "%3C",
        "=": "%3D",
        ">": "%3E",
        "?": "%3F",
        "@": "%40",
        "[": "%5B",
        "\\": "%5C",
        "]": "%5D",
        "^": "%5E",
        "{": "%7B",
        "|": "%7C",
        "}": "%7D",
        "~": "%7E" 
    }
fun customUrlEncode(ip: String): String = do {
    (ip splitBy "") map ((char) -> (encodingMap[char] default char)) joinBy ""
}