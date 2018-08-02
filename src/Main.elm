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
    Node


type alias Infra =
    Node


type alias ClusterDomain =
    { name : String
    , login : Login
    , compute : List Compute
    }


type alias Login =
    Node


type alias Compute =
    Node


type alias Node =
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
                    { name = nextClusterName model.clusters
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
                            { name = nextComputeNodeName cluster.compute
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


nextClusterName : List ClusterDomain -> String
nextClusterName clusters =
    "cluster" ++ nextIndex clusters


nextComputeNodeName : List Compute -> String
nextComputeNodeName nodes =
    let
        suffix =
            String.padLeft 3 '0' <| nextIndex nodes
    in
    "node" ++ suffix


nextIndex : List a -> String
nextIndex items =
    List.length items
        + 1
        |> toString



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
    viewDomain coreColor
        coreName
        [ viewNode coreColor core.gateway ]


viewCluster : Int -> ClusterDomain -> Html Msg
viewCluster index cluster =
    let
        clusterColor =
            -- XXX Select cluster colors rather than always using red.
            red
    in
    viewDomain clusterColor
        cluster.name
        (List.concat
            [ [ viewNode clusterColor cluster.login ]
            , List.map (viewNode clusterColor) cluster.compute
            , [ addComputeButton index ]
            ]
        )


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


viewNode : Color -> Node -> Html Msg
viewNode color node =
    div
        [ css <| nodeStyles color ]
        [ text node.name ]


viewDomain : Color -> String -> List (Html Msg) -> Html Msg
viewDomain color name children =
    div
        [ css <| domainStyles color ]
        (text name :: children)



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
