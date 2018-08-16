port module Ports exposing (..)

import Json.Encode as E


port convertToYaml : E.Value -> Cmd msg


port convertedYaml : (String -> msg) -> Sub msg
