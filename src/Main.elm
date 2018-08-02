module Main exposing (..)

import Css exposing (..)
import Css.Colors exposing (..)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onClick)


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
    = AddCluster


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AddCluster ->
            let
                newClusters =
                    List.concat [ model.clusters, [ newCluster ] ]

                newCluster =
                    -- XXX Have cluster names auto-increment
                    { name = "cluster1"
                    , login =
                        { name = "login1" }
                    , compute = []
                    }
            in
            { model | clusters = newClusters } ! []



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
        (List.concat
            [ [ viewCore model.core ]
            , List.map viewCluster model.clusters
            , [ addClusterButton ]
            ]
        )


viewCore : CoreDomain -> Html Msg
viewCore core =
    let
        coreColor =
            blue
    in
    div
        -- XXX DRY up drawing domains, nodes
        [ css <| domainStyles coreColor ]
        [ text coreName
        , div
            [ css <| nodeStyles coreColor ]
            [ text core.gateway.name ]
        ]


viewCluster : ClusterDomain -> Html Msg
viewCluster cluster =
    let
        clusterColor =
            -- XXX Select cluster colors rather than always using red.
            red
    in
    div
        [ css <| domainStyles clusterColor ]
        [ text cluster.name
        , div
            [ css <| nodeStyles clusterColor ]
            [ text cluster.login.name ]
        ]


addClusterButton : Html Msg
addClusterButton =
    let
        styles =
            List.concat
                [ [ fontSize (px 30) ]
                , domainStyles green
                ]
    in
    button
        [ css styles, onClick AddCluster ]
        [ text "+" ]



---- STYLES ----


domainStyles : Color -> List Style
domainStyles color =
    List.concat
        [ [ Css.width (px 200)
          , display inlineBlock
          ]
        , boxStyles 2 color
        ]


nodeStyles : Color -> List Style
nodeStyles domainColor =
    boxStyles 1 domainColor


boxStyles : Float -> Color -> List Style
boxStyles borderWidth boxColor =
    [ backgroundColor white
    , border (px borderWidth)
    , borderColor boxColor
    , borderStyle solid
    , color boxColor
    , margin (px 20)
    , minHeight (px 50)
    , verticalAlign top
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
