%dw 2.0


fun handleSpecialCharForP21(name: String | Null): String | Null =
    if (isEmpty(name))
        null
    else
        name 
                  // Truncate string at first semicolon -               remove ; and everything after it
      replace /[;'`].*$/ with ""
        // Normalize multiple spaces to single space
        replace /\s+/ with " "
        // Trim leading/trailing spaces
        replace /^\s+|\s+$/ with ""
