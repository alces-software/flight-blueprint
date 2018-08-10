port module Main exposing (..)

import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import Css exposing (..)
import Css.Colors exposing (..)
import FeatherIcons as Icons
import Form exposing (Form)
import Form.Value as Value exposing (Value)
import Form.View
import Html
import Html.Events
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onClick, onInput)
import Json.Encode as E
import List.Extra
import Maybe.Extra
import Node exposing (Node)
import PrimaryGroup exposing (PrimaryGroup)
import Svg
import Svg.Attributes exposing (points, x1, x2, y1, y2)


---- MODEL ----


type alias Model =
    { core : CoreDomain
    , clusters : List ClusterDomain
    , exportedYaml : String
    , computeModal : ComputeModal
    , computeForm : ComputeForm
    }


type ComputeModal
    = Hidden
    | AddingCompute Int


type alias ComputeForm =
    Form.View.Model ComputeFormValues


type alias ComputeFormValues =
    { name : Value.Value String
    , base : Value.Value String
    , startIndex : Value.Value Float
    , size : Value.Value Float
    , indexPadding : Value.Value Float
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
    , computeGroups : List PrimaryGroup
    }


type alias Login =
    Node


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
            , computeModal = Hidden
            , computeForm = initComputeForm
            }
    in
    initialModel ! [ convertToYamlCmd initialModel ]


initComputeForm : ComputeForm
initComputeForm =
    Form.View.idle
        { name = Value.filled "nodes"
        , base = Value.filled "node"
        , startIndex = Value.filled 1
        , size = Value.blank
        , indexPadding = Value.filled 2
        }



---- UPDATE ----


type Msg
    = AddCluster
    | RemoveCluster Int
    | StartAddingComputeGroup Int
    | CancelAddingComputeGroup
    | ComputeGroupFormChanged ComputeForm
    | CreateComputeGroup Int String String Int Int Int
    | AddInfra
    | RemoveInfra
    | NewConvertedYaml String
    | SetNodeName NodeSpecifier String
    | SetClusterName Int String


type NodeSpecifier
    = Gateway
    | Infra
    | Login Int
      -- XXX Handle compute better
    | Compute


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
                    , computeGroups = []
                    }
            in
            { model | clusters = newClusters }

        RemoveCluster clusterIndex ->
            { model
                | clusters = List.Extra.removeAt clusterIndex model.clusters
            }

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

                Compute ->
                    -- XXX Handle compute better
                    model

        SetClusterName clusterIndex name ->
            let
                newClusters =
                    List.Extra.updateAt
                        clusterIndex
                        (\c -> { c | name = name })
                        model.clusters
            in
            { model | clusters = newClusters }

        StartAddingComputeGroup clusterIndex ->
            { model | computeModal = AddingCompute clusterIndex }

        CancelAddingComputeGroup ->
            { model | computeModal = Hidden }

        ComputeGroupFormChanged newFormModel ->
            { model | computeForm = newFormModel }

        CreateComputeGroup clusterIndex name base startIndex size indexPadding ->
            let
                newClusters =
                    List.Extra.updateAt
                        clusterIndex
                        addGroup
                        model.clusters

                addGroup cluster =
                    { cluster
                        | computeGroups =
                            List.concat
                                [ cluster.computeGroups
                                , [ newGroup ]
                                ]
                    }

                newGroup =
                    { name = name
                    , nodes =
                        { base = base
                        , startIndex = startIndex
                        , size = size
                        , indexPadding = indexPadding
                        }
                    }
            in
            { model
                | clusters = newClusters
                , computeModal = Hidden
                , computeForm = initComputeForm
            }


convertToYamlCmd : Model -> Cmd Msg
convertToYamlCmd =
    encodeModel >> convertToYaml


nextClusterName : List ClusterDomain -> String
nextClusterName clusters =
    "cluster" ++ nextIndex clusters


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
    in
    E.object
        [ loginField

        -- XXX handle encoding compute nodes in new format
        -- , computeField
        ]


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
            , minHeight (vh 75)
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
                [ css <| boxStyles containerBoxBorderWidth solid black ]
                [ Html.Styled.pre []
                    [ text model.exportedYaml ]
                ]
            ]

        -- Must appear last so doesn't interfere with grid layout.
        , computeModal model
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
        [ -- XXX If decide we want to allow changing `core` name then move this
          -- from `viewCluster` into `viewDomain`, and remove name as just text
          -- here.
          text coreName
        , viewNode coreColor Gateway Nothing core.gateway
        , infraNodeOrButton
        ]


viewCluster : Model -> Int -> ClusterDomain -> Html Msg
viewCluster model clusterIndex cluster =
    let
        color =
            clusterColor model clusterIndex
    in
    viewDomain color
        (List.concat
            [ [ nameInput color cluster (SetClusterName clusterIndex)
              , removeButton <| RemoveCluster clusterIndex
              , viewNode color (Login clusterIndex) Nothing cluster.login
              ]
            , List.map (viewPrimaryGroup color) cluster.computeGroups
            , [ addComputeButton clusterIndex ]
            ]
        )


viewPrimaryGroup : Color -> PrimaryGroup -> Html Msg
viewPrimaryGroup color group =
    let
        nodes =
            PrimaryGroup.nodes group
    in
    div
        [ css <| groupStyles color ]
        (text group.name
            :: List.map (viewNode color Compute Nothing) nodes
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
    addButton "compute" nodeStyles (StartAddingComputeGroup clusterIndex)


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
        [ nodeIcon nodeSpecifier
        , nameInput color node (SetNodeName nodeSpecifier)
        , maybeHtml removeMsg removeButton
        ]


nodeIcon : NodeSpecifier -> Html msg
nodeIcon nodeSpecifier =
    let
        ( icon, titleText ) =
            case nodeSpecifier of
                Gateway ->
                    ( Icons.cloud, "Gateway node" )

                Infra ->
                    ( Icons.users, "Infra node" )

                Login _ ->
                    -- XXX Icon grabbed from
                    -- https://1602.github.io/elm-feather-icons/ but not yet
                    -- made it into https://github.com/1602/elm-feather-icons -
                    -- can simplify this to `Icons.terminal` and possibly
                    -- remove our `elm-lang/svg` dependency when it does.
                    ( Icons.customIcon
                        [ Svg.polyline [ points "4 17 10 11 4 5" ] []
                        , Svg.line [ x1 "12", y1 "19", x2 "20", y2 "19" ] []
                        ]
                    , "Login node"
                    )

                Compute ->
                    ( Icons.settings, "Compute node" )

        iconHtml =
            Icons.withSize 15 icon
                |> Icons.toHtml []
                |> Html.Styled.fromUnstyled
    in
    div
        [ css
            [ display inlineBlock
            , marginRight (px 5)
            ]
        , title titleText
        ]
        [ iconHtml ]


nameInput : Color -> { a | name : String } -> (String -> Msg) -> Html Msg
nameInput color { name } inputMsg =
    input
        [ value name
        , onInput inputMsg
        , css
            -- Reset input styles to look like regular text (adapted from
            -- https://stackoverflow.com/a/38830702/2620402).
            [ border unset
            , display inline
            , fontFamily inherit
            , fontSize inherit
            , padding (px 0)

            -- Do not set width to 100% to allow space for remove buttons.
            , Css.width (pct 80)
            , Css.color color
            ]
        ]
        []


viewDomain : Color -> List (Html Msg) -> Html Msg
viewDomain color children =
    div
        [ css <| domainStyles color ]
        children


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


computeModal : Model -> Html Msg
computeModal model =
    let
        ( visibility, header, body ) =
            case model.computeModal of
                Hidden ->
                    hiddenModalTriplet

                AddingCompute clusterIndex ->
                    let
                        maybeCluster =
                            List.Extra.getAt clusterIndex model.clusters
                    in
                    case maybeCluster of
                        Just cluster ->
                            ( Modal.shown
                            , "Add compute to " ++ cluster.name
                            , viewComputeGroupForm model.computeForm clusterIndex
                            )

                        Nothing ->
                            -- If we're trying to add compute to a cluster
                            -- which isn't in the model, something must have
                            -- gone wrong, so keep the modal hidden.
                            hiddenModalTriplet

        hiddenModalTriplet =
            ( Modal.hidden, "", toUnstyled nothing )
    in
    Modal.config CancelAddingComputeGroup
        |> Modal.hideOnBackdropClick True
        |> Modal.h3 [] [ Html.text header ]
        |> Modal.body [] [ body ]
        |> Modal.footer []
            [ Button.button
                [ Button.outlineWarning
                , Button.attrs [ Html.Events.onClick CancelAddingComputeGroup ]
                ]
                [ Html.text "Cancel" ]
            ]
        |> Modal.view visibility
        |> Html.Styled.fromUnstyled


viewComputeGroupForm : ComputeForm -> Int -> Html.Html Msg
viewComputeGroupForm computeFormModel clusterIndex =
    Form.View.asHtml
        { onChange = ComputeGroupFormChanged
        , action = "Create"
        , loading = "Creating..."
        , validation = Form.View.ValidateOnBlur
        }
        (computeGroupForm clusterIndex)
        computeFormModel


computeGroupForm : Int -> Form ComputeFormValues Msg
computeGroupForm clusterIndex =
    let
        nameField =
            Form.textField
                { parser = Ok
                , value = .name
                , update = \value values -> { values | name = value }
                , attributes =
                    { label = "New group name"
                    , placeholder = ""
                    }
                }

        baseField =
            Form.textField
                { parser = Ok
                , value = .base
                , update = \value values -> { values | base = value }
                , attributes =
                    { label = "Base to use for generated node names"
                    , placeholder = ""
                    }
                }

        startIndexField =
            Form.numberField
                { parser = intParser
                , value = .startIndex
                , update = \value values -> { values | startIndex = value }
                , attributes =
                    { label = "Index to start from when generating node names"
                    , placeholder = ""
                    , max = Nothing
                    , min = Just 1
                    , step = 1
                    }
                }

        sizeField =
            Form.numberField
                { parser = intParser
                , value = .size
                , update = \value values -> { values | size = value }
                , attributes =
                    { label = "Number of nodes to generate"
                    , placeholder = ""
                    , max = Nothing
                    , min = Just 1
                    , step = 1
                    }
                }

        indexPaddingField =
            Form.numberField
                { parser = intParser
                , value = .indexPadding
                , update = \value values -> { values | indexPadding = value }
                , attributes =
                    { label = "Padding to use for indices when generating nodes"
                    , placeholder = ""
                    , max = Just 10
                    , min = Just 0
                    , step = 1
                    }
                }

        intParser float =
            toString float
                |> String.toInt
                |> Result.mapError (always "Must be an integer.")
    in
    Form.succeed (CreateComputeGroup clusterIndex)
        |> Form.append nameField
        |> Form.append baseField
        |> Form.append startIndexField
        |> Form.append sizeField
        |> Form.append indexPaddingField



---- STYLES ----


domainStyles : Color -> List Style
domainStyles color =
    List.concat
        [ [ Css.width (px 300)
          , display inlineBlock
          , margin standardMargin
          ]
        , boxStyles containerBoxBorderWidth solid color
        ]


nodeStyles : Color -> List Style
nodeStyles color =
    innerBoxStyles solid color


groupStyles : Color -> List Style
groupStyles color =
    innerBoxStyles dashed color


innerBoxStyles : BorderStyle compatible -> Color -> List Style
innerBoxStyles borderStyle boxColor =
    List.concat
        [ [ marginTop standardMargin ]
        , boxStyles innerBoxBorderWidth borderStyle boxColor
        ]


boxStyles : Float -> BorderStyle compatible -> Color -> List Style
boxStyles borderWidth borderStyle boxColor =
    [ backgroundColor white
    , border (px borderWidth)
    , borderColor boxColor
    , Css.borderStyle borderStyle
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
