module Utils exposing (..)

import Html exposing (..)


nothing : Html msg
nothing =
    text ""


maybeHtml : Maybe a -> (a -> Html msg) -> Html msg
maybeHtml maybeItem itemToHtml =
    case maybeItem of
        Just item ->
            itemToHtml item

        Nothing ->
            nothing
