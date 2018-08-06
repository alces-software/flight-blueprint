port module Main exposing (..)

import Css exposing (..)
import Css.Colors exposing (..)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onClick, onInput)
import Json.Encode as E
import List.Extra
import Maybe.Extra


---- MODEL ----


type alias Model =
    { core : CoreDomain
    , clusters : List ClusterDomain
    , exportedYaml : String
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
    let
        initialModel =
            { core =
                { gateway =
                    { name = "gateway" }
                , infra = Nothing
                }
            , clusters = []
            , exportedYaml = ""
            }
    in
    initialModel ! [ convertToYamlCmd initialModel ]



---- UPDATE ----


type Msg
    = AddCluster
    | RemoveCluster Int
    | AddCompute Int
    | RemoveCompute Int
    | AddInfra
    | RemoveInfra
    | NewConvertedYaml String
    | SetNodeName NodeSpecifier String


type NodeSpecifier
    = Gateway
    | Infra
    | Login Int
    | Compute Int Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        newModel =
            updateInterfaceState msg model

        convertYamlCmd =
            case msg of
                NewConvertedYaml _ ->
                    -- Do not convert model to YAML when we've just handled
                    -- receiving new converted YAML, to avoid infinite loop.
                    Cmd.none

                _ ->
                    convertToYamlCmd newModel
    in
    newModel ! [ convertYamlCmd ]


updateInterfaceState : Msg -> Model -> Model
updateInterfaceState msg model =
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
            { model | clusters = newClusters }

        RemoveCluster clusterIndex ->
            { model
                | clusters = List.Extra.removeAt clusterIndex model.clusters
            }

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

        RemoveCompute clusterIndex ->
            let
                removeLastComputeNode currentCompute =
                    exceptLast currentCompute
            in
            changeComputeForCluster model clusterIndex removeLastComputeNode

        AddInfra ->
            changeInfra model <| Just { name = "infra" }

        RemoveInfra ->
            changeInfra model Nothing

        NewConvertedYaml yaml ->
            { model | exportedYaml = yaml }

        SetNodeName nodeSpecifier name ->
            -- XXX This branch is a bit messy and could be tidied up - possibly
            -- the best way to do this is to store all nodes in the same way in
            -- model.
            let
                { core, clusters } =
                    model

                newNode =
                    Node name
            in
            case nodeSpecifier of
                Gateway ->
                    let
                        newCore =
                            { core | gateway = newNode }
                    in
                    { model | core = newCore }

                Infra ->
                    let
                        newCore =
                            case core.infra of
                                Just infra ->
                                    { core | infra = Just newNode }

                                Nothing ->
                                    core
                    in
                    { model | core = newCore }

                Login clusterIndex ->
                    let
                        newClusters =
                            List.Extra.updateAt
                                clusterIndex
                                changeClusterLogin
                                clusters

                        changeClusterLogin cluster =
                            { cluster | login = newNode }
                    in
                    { model | clusters = newClusters }

                Compute clusterIndex computeIndex ->
                    let
                        changeClusterCompute =
                            List.Extra.updateAt computeIndex
                                (always newNode)
                    in
                    changeComputeForCluster model
                        clusterIndex
                        changeClusterCompute


convertToYamlCmd : Model -> Cmd Msg
convertToYamlCmd =
    encodeModel >> convertToYaml


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


changeInfra : Model -> Maybe Infra -> Model
changeInfra model infra =
    let
        newCore =
            { currentCore | infra = infra }

        currentCore =
            model.core
    in
    { model | core = newCore }


changeComputeForCluster :
    Model
    -> Int
    -> (List Compute -> List Compute)
    -> Model
changeComputeForCluster model clusterIndex changeCompute =
    let
        newClusters =
            List.Extra.updateAt
                clusterIndex
                (\c -> { c | compute = changeCompute c.compute })
                model.clusters
    in
    { model | clusters = newClusters }


encodeModel : Model -> E.Value
encodeModel model =
    let
        coreField =
            ( "core", encodeCore model.core )

        clusterFields =
            List.map
                (\c -> ( c.name, encodeCluster c ))
                model.clusters
    in
    E.object (coreField :: clusterFields)


encodeCore : CoreDomain -> E.Value
encodeCore core =
    let
        coreFields =
            Maybe.Extra.values
                [ Just <| ( "gateway", encodeNode core.gateway )
                , Maybe.map
                    (\i -> ( "infra", encodeNode i ))
                    core.infra
                ]
    in
    E.object coreFields


encodeCluster : ClusterDomain -> E.Value
encodeCluster cluster =
    let
        loginField =
            ( "login", encodeNode cluster.login )

        computeField =
            ( "compute"
            , E.list <| List.map encodeNode cluster.compute
            )
    in
    E.object [ loginField, computeField ]


encodeNode : Node -> E.Value
encodeNode node =
    E.string node.name



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
            , Css.property "display" "grid"
            , Css.property "grid-template-columns" "66% 33%"
            ]
        ]
        [ div
            [ css [ Css.property "grid-column-start" "1" ] ]
            (List.concat
                [ [ viewCore model.core ]
                , List.indexedMap (viewCluster model) model.clusters
                , [ addClusterButton ]
                ]
            )
        , div
            [ css [ Css.property "grid-column-start" "2" ] ]
            [ div
                [ css <| boxStyles containerBoxBorderWidth black ]
                [ Html.Styled.pre []
                    [ text model.exportedYaml ]
                ]
            ]
        ]


viewCore : CoreDomain -> Html Msg
viewCore core =
    let
        coreColor =
            blue

        infraNodeOrButton =
            case core.infra of
                Just infra ->
                    viewNode coreColor Infra (Just RemoveInfra) infra

                Nothing ->
                    addInfraButton
    in
    viewDomain coreColor
        coreName
        [ viewNode coreColor Gateway Nothing core.gateway
        , infraNodeOrButton
        ]


viewCluster : Model -> Int -> ClusterDomain -> Html Msg
viewCluster model clusterIndex cluster =
    let
        color =
            clusterColor model clusterIndex

        ( otherNodes, maybeLastNode ) =
            ( exceptLast cluster.compute
            , List.Extra.last cluster.compute
            )

        viewClusterNode =
            viewNode color

        viewLastNode =
            let
                lastNodeIndex =
                    List.length cluster.compute - 1
            in
            maybeHtml maybeLastNode
                (viewClusterNode
                    (Compute clusterIndex lastNodeIndex)
                    (Just <| RemoveCompute clusterIndex)
                )
    in
    viewDomain color
        cluster.name
        (List.concat
            [ [ removeButton <| RemoveCluster clusterIndex
              , viewClusterNode (Login clusterIndex) Nothing cluster.login
              ]
            , List.indexedMap
                (\i -> viewClusterNode (Compute clusterIndex i) Nothing)
                otherNodes
            , [ viewLastNode
              , addComputeButton clusterIndex
              ]
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


viewNode : Color -> NodeSpecifier -> Maybe Msg -> Node -> Html Msg
viewNode color nodeSpecifier removeMsg node =
    div
        [ css <| nodeStyles color ]
        [ input
            [ value node.name
            , onInput (SetNodeName nodeSpecifier)
            , css
                -- Reset input styles to look like regular text (adapted from
                -- https://stackoverflow.com/a/38830702/2620402).
                [ border unset
                , display inline
                , fontFamily inherit
                , fontSize inherit
                , padding (px 0)
                , Css.width (pct 100)
                , Css.color color
                ]
            ]
            []
        , maybeHtml removeMsg removeButton
        ]


viewDomain : Color -> String -> List (Html Msg) -> Html Msg
viewDomain color name children =
    div
        [ css <| domainStyles color ]
        (text name :: children)


maybeHtml : Maybe a -> (a -> Html Msg) -> Html Msg
maybeHtml maybeItem itemToHtml =
    case maybeItem of
        Just item ->
            itemToHtml item

        Nothing ->
            nothing


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
        , boxStyles containerBoxBorderWidth color
        ]


nodeStyles : Color -> List Style
nodeStyles domainColor =
    List.concat
        [ [ marginTop standardMargin ]
        , boxStyles innerBoxBorderWidth domainColor
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


buttonFontSize : Style
buttonFontSize =
    fontSize (px 20)


containerBoxBorderWidth : Float
containerBoxBorderWidth =
    innerBoxBorderWidth * 2


innerBoxBorderWidth : Float
innerBoxBorderWidth =
    1



---- UTILS ----


exceptLast : List a -> List a
exceptLast list =
    List.reverse list
        |> List.tail
        |> Maybe.withDefault []
        |> List.reverse



---- PORTS ----


port convertToYaml : E.Value -> Cmd msg


port convertedYaml : (String -> msg) -> Sub msg



---- SUBSCRIPTIONS ----


subscriptions : Model -> Sub Msg
subscriptions model =
    convertedYaml NewConvertedYaml



---- PROGRAM ----


main : Program Never Model Msg
main =
    Html.program
        { view = view >> toUnstyled
        , init = init
        , update = update
        , subscriptions = subscriptions
        }
