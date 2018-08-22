module Validations exposing (CustomError(..), validateIdentifier)

import Form.Validate exposing (..)
import Regex


type CustomError
    = InvalidIdentifierCharacters
    | InvalidIdentifierFirstCharacter


validateIdentifier : Validation CustomError String
validateIdentifier =
    string
        |> andThen
            (format (Regex.regex "^[a-zA-Z0-9]+$")
                >> withCustomError InvalidIdentifierCharacters
            )
        |> andThen
            (format (Regex.regex "^[a-zA-Z]")
                >> withCustomError InvalidIdentifierFirstCharacter
            )
