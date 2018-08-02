module Main exposing (..)

import Css exposing (..)
import Css.Colors exposing (..)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onClick)
import List.Extra


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
    | AddInfra
    | RemoveInfra


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
                addCompute currentCompute =
                    List.concat
                        [ currentCompute
                        , [ { name =
                                nextComputeNodeName currentCompute
                            }
                          ]
                        ]
            in
            changeComputeForCluster model clusterIndex addCompute

        AddInfra ->
            changeInfra model <| Just { name = "infra" }

        RemoveInfra ->
            changeInfra model Nothing


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


changeInfra : Model -> Maybe Infra -> ( Model, Cmd Msg )
changeInfra model infra =
    let
        newCore =
            { currentCore | infra = infra }

        currentCore =
            model.core
    in
    { model | core = newCore } ! []


changeComputeForCluster :
    Model
    -> Int
    -> (List Compute -> List Compute)
    -> ( Model, Cmd Msg )
changeComputeForCluster model clusterIndex changeCompute =
    let
        newClusters =
            List.indexedMap
                (\i c ->
                    if i == clusterIndex then
                        { c | compute = changeCompute c.compute }
                    else
                        c
                )
                model.clusters
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
            , List.indexedMap (viewCluster model) model.clusters
            , [ addClusterButton ]
            ]
        )


viewCore : CoreDomain -> Html Msg
viewCore core =
    let
        coreColor =
            blue

        infraNodeOrButton =
            case core.infra of
                Just infra ->
                    viewNode coreColor (Just RemoveInfra) infra

                Nothing ->
                    addInfraButton
    in
    viewDomain coreColor
        coreName
        [ viewNode coreColor Nothing core.gateway
        , infraNodeOrButton
        ]


viewCluster : Model -> Int -> ClusterDomain -> Html Msg
viewCluster model index cluster =
    let
        color =
            clusterColor model index
    in
    viewDomain color
        cluster.name
        (List.concat
            [ [ viewNode color Nothing cluster.login ]
            , List.map (viewNode color Nothing) cluster.compute
            , [ addComputeButton index ]
            ]
        )


clusterColor : Model -> Int -> Color
clusterColor model clusterIndex =
    let
        colors =
            -- Available colors = all default colors provided by elm-css, in
            -- rainbow order, minus:
            -- - colors already used for other things (blue, green)
            -- - colors which are too pale and so hard/impossible to read
            -- (lime, aqua, white)
            -- - colors which are too dark and so look the same as black (navy)
            [ red
            , orange
            , yellow
            , olive
            , teal
            , purple
            , fuchsia
            , maroon
            , black
            , fallbackColor
            ]

        fallbackColor =
            gray
    in
    List.Extra.getAt clusterIndex colors
        |> Maybe.withDefault fallbackColor


addInfraButton : Html Msg
addInfraButton =
    addButton "infra" nodeStyles AddInfra


addComputeButton : Int -> Html Msg
addComputeButton clusterIndex =
    addButton "compute" nodeStyles (AddCompute clusterIndex)


addClusterButton : Html Msg
addClusterButton =
    addButton "cluster" domainStyles AddCluster


addButton : String -> (Color -> List Style) -> Msg -> Html Msg
addButton itemToAdd colorToStyles addMsg =
    let
        styles =
            List.concat
                [ [ buttonFontSize
                  , Css.width (pct 100)
                  ]
                , colorToStyles green
                ]
    in
    button
        [ css styles, onClick addMsg ]
        [ text <| "+" ++ itemToAdd ]


removeButton : Msg -> Html Msg
removeButton removeMsg =
    let
        styles =
            [ backgroundColor white
            , border unset
            , buttonFontSize
            , color red
            , float right
            , padding unset
            , verticalAlign top
            ]
    in
    button
        [ css styles, onClick removeMsg ]
        [ text "x" ]


buttonFontSize : Style
buttonFontSize =
    fontSize (px 20)


viewNode : Color -> Maybe Msg -> Node -> Html Msg
viewNode color removeMsg node =
    div
        [ css <| nodeStyles color ]
        [ text node.name
        , case removeMsg of
            Just msg ->
                removeButton msg

            Nothing ->
                nothing
        ]


viewDomain : Color -> String -> List (Html Msg) -> Html Msg
viewDomain color name children =
    div
        [ css <| domainStyles color ]
        (text name :: children)


nothing : Html Msg
nothing =
    text ""



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
