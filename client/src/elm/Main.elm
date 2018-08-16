module Main exposing (..)

import Html
import Html.Styled
import Model exposing (Model)
import Msg exposing (..)
import Ports
import Update
import View


---- SUBSCRIPTIONS ----


subscriptions : Model -> Sub Msg
subscriptions model =
    Ports.convertedYaml NewConvertedYaml



---- PROGRAM ----


main : Program Int Model Msg
main =
    Html.programWithFlags
        { view = View.view >> Html.Styled.toUnstyled
        , init = Model.init
        , update = Update.update
        , subscriptions = subscriptions
        }
