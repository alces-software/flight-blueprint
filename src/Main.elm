module Main exposing (..)

import Css exposing (..)
import Css.Colors exposing (..)
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


coreName : String
coreName =
    "core"


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
        (viewCore model.core
            :: List.map viewCluster model.clusters
        )


viewCore : CoreDomain -> Html Msg
viewCore core =
    let
        coreColor =
            blue
    in
    div
        [ css <| domainStyles coreColor ]
        [ text coreName
        , div
            [ css <| nodeStyles coreColor ]
            [ text core.gateway.name ]
        ]


viewCluster : ClusterDomain -> Html Msg
viewCluster clusters =
    -- XXX Actually implement this
    div [ css <| domainStyles red ] []



---- STYLES ----


domainStyles : Color -> List Style
domainStyles color =
    List.concat
        [ [ Css.width (px 200) ]
        , boxStyles 2 color
        ]


nodeStyles : Color -> List Style
nodeStyles domainColor =
    boxStyles 1 domainColor


boxStyles : Float -> Color -> List Style
boxStyles borderWidth boxColor =
    [ border (px borderWidth)
    , borderColor boxColor
    , borderStyle solid
    , color boxColor
    , margin (px 20)
    , minHeight (px 50)
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
