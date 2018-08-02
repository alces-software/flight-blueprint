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



-- XXX Consider using same type for all nodes, since effectively the same


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
    | AddCompute Int


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

        AddCompute clusterIndex ->
            let
                newClusters =
                    List.indexedMap
                        (\i c ->
                            if i == clusterIndex then
                                addComputeToCluster c
                            else
                                c
                        )
                        model.clusters

                addComputeToCluster cluster =
                    let
                        newComputeNode =
                            -- XXX Have compute node names auto-increment
                            { name = "node01"
                            }
                    in
                    { cluster
                        | compute =
                            List.concat
                                [ cluster.compute
                                , [ newComputeNode ]
                                ]
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
            , List.indexedMap viewCluster model.clusters
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


viewCluster : Int -> ClusterDomain -> Html Msg
viewCluster index cluster =
    let
        clusterColor =
            -- XXX Select cluster colors rather than always using red.
            red

        loginNode =
            div
                [ css <| nodeStyles clusterColor ]
                [ text cluster.login.name ]
    in
    div
        [ css <| domainStyles clusterColor ]
        (List.concat
            [ [ text cluster.name, loginNode ]
            , List.map (viewComputeNode clusterColor) cluster.compute
            , [ addComputeButton index ]
            ]
        )


viewComputeNode : Color -> Compute -> Html Msg
viewComputeNode domainColor compute =
    div
        [ css <| nodeStyles domainColor ]
        [ text compute.name ]


addComputeButton : Int -> Html Msg
addComputeButton clusterIndex =
    addButton nodeStyles (AddCompute clusterIndex)


addClusterButton : Html Msg
addClusterButton =
    addButton domainStyles AddCluster


addButton : (Color -> List Style) -> Msg -> Html Msg
addButton colorToStyles addMsg =
    let
        styles =
            List.concat
                [ [ fontSize (px 30), Css.width (pct 100) ]
                , colorToStyles green
                ]
    in
    button
        [ css styles, onClick addMsg ]
        [ text "+" ]



---- STYLES ----


domainStyles : Color -> List Style
domainStyles color =
    List.concat
        [ [ Css.width (px 200)
          , display inlineBlock
          , margin standardMargin
          ]
        , boxStyles 2 color
        ]


nodeStyles : Color -> List Style
nodeStyles domainColor =
    List.concat
        [ [ marginTop standardMargin ]
        , boxStyles 1 domainColor
        ]


boxStyles : Float -> Color -> List Style
boxStyles borderWidth boxColor =
    [ backgroundColor white
    , border (px borderWidth)
    , borderColor boxColor
    , borderStyle solid
    , color boxColor
    , minHeight (px 50)
    , padding (px 10)
    , verticalAlign top
    ]


standardMargin : Px
standardMargin =
    px 20



---- PROGRAM ----


main : Program Never Model Msg
main =
    Html.program
        { view = view >> toUnstyled
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }
