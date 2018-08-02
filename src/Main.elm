module Main exposing (..)

import Css exposing (..)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)


---- MODEL ----


type alias Model =
    { core : CoreDomain
    , clusters : List ClusterDomain
    }


type alias CoreDomain =
    { gateway : Gateway
    , infra : Maybe Infra
    }


type alias Gateway =
    { name : String
    }


type alias Infra =
    { name : String
    }


type alias ClusterDomain =
    { name : String
    , login : Login
    , compute : List Compute
    }


type alias Login =
    { name : String
    }


type alias Compute =
    { name : String
    }


init : ( Model, Cmd Msg )
init =
    { core =
        { gateway =
            { name = "gateway"
            }
        , infra = Nothing
        }
    , clusters = []
    }
        ! []



---- UPDATE ----


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div
        [ css
            [ fontFamilies
                [ "Source Sans Pro"
                , "Trebuchet MS"
                , "Lucida Grande"
                , "Bitstream Vera Sans"
                , "Helvetica Neue"
                , "sans-serif"
                ]
            ]
        ]
        [ h1 [] [ text "Your Elm App is working!" ]
        ]



---- PROGRAM ----


main : Program Never Model Msg
main =
    Html.program
        { view = view >> toUnstyled
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }
