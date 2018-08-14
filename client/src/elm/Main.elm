port module Main exposing (..)

import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import Css exposing (..)
import Css.Colors exposing (..)
import EveryDict exposing (EveryDict)
import FeatherIcons as Icons
import Form exposing (Form)
import Form.Error exposing (ErrorValue(..))
import Form.Field as Field exposing (Field)
import Form.Input as Input
import Form.Validate as V exposing (Validation)
import Html
import Html.Attributes as Attrs
import Html.Events
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onClick, onInput)
import Json.Encode as E
import List.Extra
import Maybe.Extra
import Node exposing (Node)
import PrimaryGroup exposing (PrimaryGroup)
import Random.Pcg exposing (Seed)
import Uuid exposing (Uuid)


---- MODEL ----


type alias Model =
    { core : CoreDomain
    , clusters : List ClusterDomain
    , clusterPrimaryGroups : EveryDict Uuid PrimaryGroup
    , exportedYaml : String
    , randomSeed : Seed
    , computeModal : ComputeModal
    , computeForm : ComputeForm
    }


type ComputeModal
    = Hidden
    | AddingCompute Int


type alias ComputeForm =
    Form () PrimaryGroup


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
    , computeGroupIds : List Uuid
    }


type alias Login =
    Node


init : Int -> ( Model, Cmd Msg )
init initialRandomSeed =
    let
        initialModel =
            { core =
                { gateway =
                    { name = "gateway" }
                , infra = Nothing
                }
            , clusters = []
            , clusterPrimaryGroups = EveryDict.empty
            , exportedYaml = ""
            , randomSeed = Random.Pcg.initialSeed initialRandomSeed
            , computeModal = Hidden
            , computeForm = initComputeForm
            }
    in
    initialModel ! [ convertToYamlCmd initialModel ]


initComputeForm : ComputeForm
initComputeForm =
    Form.initial initialComputeFormValues computeFormValidation


initialComputeFormValues : List ( String, Field )
initialComputeFormValues =
    -- XXX Extract things in some way so don't need to duplicate field names in
    -- different places (each field is in at least 3 currently).
    [ ( "name", Field.string "nodes" )
    , ( "nodes"
      , Field.group
            [ ( "base", Field.string "node" )
            , ( "startIndex", Field.string "1" )
            , ( "size", Field.string "" )
            , ( "indexPadding", Field.string "2" )
            ]
      )
    ]


computeFormValidation : Validation () PrimaryGroup
computeFormValidation =
    -- XXX Do more thoroughly - validate integers within ranges defined in view
    -- etc.
    V.map2 PrimaryGroup
        (V.field "name" V.string)
        (V.field "nodes"
            (V.map4 PrimaryGroup.NodesSpecification
                (V.field "base" V.string)
                (V.field "startIndex" V.int)
                (V.field "size" V.int)
                (V.field "indexPadding" V.int)
            )
        )



---- UPDATE ----


type Msg
    = AddCluster
    | RemoveCluster Int
    | StartAddingComputeGroup Int
    | CancelAddingComputeGroup
    | ComputeFormMsg Int Form.Msg
    | RemoveComputeGroup Uuid
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
                    , computeGroupIds = []
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

        ComputeFormMsg clusterIndex formMsg ->
            case ( formMsg, Form.getOutput model.computeForm ) of
                ( Form.Submit, Just newGroup ) ->
                    handleSuccessfulComputeFormSubmit model clusterIndex newGroup

                ( formMsg, _ ) ->
                    let
                        preUpdatedForm =
                            case formMsg of
                                Form.Input "name" _ (Field.String newName) ->
                                    handleUpdatingComputeFormName newName model.computeForm

                                _ ->
                                    model.computeForm
                    in
                    { model
                        | computeForm =
                            Form.update computeFormValidation formMsg preUpdatedForm
                    }

        RemoveComputeGroup groupId ->
            let
                -- Only delete the group itself, and not any possible
                -- references to this elsewhere. This makes things simple and
                -- should be fine so long as we always handle 'the group being
                -- referenced but not existing' case the same as the 'group not
                -- being referenced at all' case. XXX See if this causes
                -- problems and if I still think the same in future.
                newGroups =
                    EveryDict.remove groupId model.clusterPrimaryGroups
            in
            { model | clusterPrimaryGroups = newGroups }


handleSuccessfulComputeFormSubmit : Model -> Int -> PrimaryGroup -> Model
handleSuccessfulComputeFormSubmit model clusterIndex newGroup =
    let
        currentCluster =
            List.Extra.getAt clusterIndex model.clusters

        newClusters =
            List.Extra.updateAt
                clusterIndex
                addGroupId
                model.clusters

        addGroupId cluster =
            { cluster
                | computeGroupIds =
                    newGroupId :: cluster.computeGroupIds
            }

        ( newGroupId, newSeed ) =
            Random.Pcg.step Uuid.uuidGenerator model.randomSeed

        newGroups =
            EveryDict.insert
                newGroupId
                newGroup
                model.clusterPrimaryGroups
    in
    { model
        | clusters = newClusters
        , clusterPrimaryGroups = newGroups
        , randomSeed = newSeed
        , computeModal = Hidden
        , computeForm = initComputeForm
    }


handleUpdatingComputeFormName : String -> ComputeForm -> ComputeForm
handleUpdatingComputeFormName newName computeForm =
    let
        ( currentName, currentBase ) =
            ( value "name"
            , value "nodes.base"
            )

        value =
            flip Form.getFieldAsString computeForm
                >> .value
                >> Maybe.withDefault ""

        newBase =
            if shouldKeepCurrentBase then
                currentBase
            else
                singularized newName

        shouldKeepCurrentBase =
            not <| currentBase == singularized currentName

        singularized word =
            if isPlural word then
                String.dropRight 1 word
            else
                word

        isPlural =
            String.endsWith "s"
    in
    Form.update computeFormValidation
        (Form.Input "nodes.base" Form.Text (Field.String newBase))
        computeForm


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
            , List.map (viewPrimaryGroup model color) cluster.computeGroupIds
            , [ addComputeButton clusterIndex ]
            ]
        )


viewPrimaryGroup : Model -> Color -> Uuid -> Html Msg
viewPrimaryGroup model color groupId =
    let
        maybeGroup =
            EveryDict.get groupId model.clusterPrimaryGroups
    in
    case maybeGroup of
        Just group ->
            let
                nodes =
                    PrimaryGroup.nodes group

                children =
                    List.concat
                        [ [ text group.name
                          , removeButton <| RemoveComputeGroup groupId
                          ]
                        , List.map (viewNode color Compute Nothing) nodes
                        ]
            in
            div [ css <| groupStyles color ] children

        Nothing ->
            nothing


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
                    ( Icons.terminal, "Login node" )

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


nothing : Html msg
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
                                |> toUnstyled
                                |> Html.map (ComputeFormMsg clusterIndex)
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


viewComputeGroupForm : ComputeForm -> Int -> Html Form.Msg
viewComputeGroupForm computeForm clusterIndex =
    let
        formInput_ =
            formInput computeForm
    in
    div []
        [ formInput_
            { label = "New group name"
            , fieldIdentifier = "name"
            , fieldType = Text
            }
        , formInput_
            { label = "Base to use for generated node names"
            , fieldIdentifier = "nodes.base"
            , fieldType = Text
            }
        , formInput_
            { label = "Index to start from when generating node names"
            , fieldIdentifier = "nodes.startIndex"
            , fieldType = Integer { min = Just 1, max = Nothing }
            }
        , formInput_
            { label = "Number of nodes to generate"
            , fieldIdentifier = "nodes.size"
            , fieldType = Integer { min = Just 1, max = Nothing }
            }
        , formInput_
            { label = "Padding to use for indices when generating nodes"
            , fieldIdentifier = "nodes.indexPadding"
            , fieldType = Integer { min = Just 0, max = Just 10 }
            }
        , button [ onClick Form.Submit ] [ text "Create" ]
        , Html.Styled.fromUnstyled <| Input.dumpErrors computeForm
        ]


type alias FieldConfig =
    { label : String
    , fieldIdentifier : String
    , fieldType : FieldType
    }


type FieldType
    = Text
    | Integer { min : Maybe Int, max : Maybe Int }


formInput : ComputeForm -> FieldConfig -> Html Form.Msg
formInput computeForm config =
    let
        field =
            Form.getFieldAsString config.fieldIdentifier computeForm

        errorElement =
            case field.liveError of
                Just error ->
                    div
                        [ class "error" ]
                        [ text <| errorMessage error ]

                Nothing ->
                    nothing

        additionalInputAttrs =
            case config.fieldType of
                Text ->
                    [ Attrs.type_ "text" ]

                Integer { min, max } ->
                    Maybe.Extra.values
                        [ Just <| Attrs.type_ "number"
                        , Maybe.map (toString >> Attrs.min) min
                        , Maybe.map (toString >> Attrs.max) max
                        ]
    in
    div []
        [ label [] [ text config.label ]
        , Input.textInput field additionalInputAttrs
            |> Html.Styled.fromUnstyled
        , errorElement
        ]


errorMessage : ErrorValue e -> String
errorMessage errorValue =
    let
        mustBeLessThan i =
            "Must be less than " ++ toString i ++ "."

        mustBeGreaterThan i =
            "Must be greater than " ++ toString i ++ "."
    in
    -- XXX Consider how to make error messages better when no value entered;
    -- not helpful to tell user that the value they haven't entered should be
    -- an integer.
    case errorValue of
        Empty ->
            ""

        InvalidString ->
            "Must be a string."

        InvalidEmail ->
            "Not a valid email."

        InvalidFormat ->
            "Invalid format."

        InvalidInt ->
            "Must be an integer."

        InvalidFloat ->
            "Must be a number."

        InvalidBool ->
            "Must be a boolean value."

        InvalidDate ->
            "Must be a date."

        SmallerIntThan i ->
            mustBeLessThan i

        GreaterIntThan i ->
            mustBeGreaterThan i

        SmallerFloatThan i ->
            mustBeLessThan i

        GreaterFloatThan i ->
            mustBeGreaterThan i

        ShorterStringThan i ->
            "Must be shorter than " ++ toString i ++ " characters."

        LongerStringThan i ->
            "Must be longer than " ++ toString i ++ " characters."

        NotIncludedIn ->
            ""

        CustomError e ->
            toString e



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


main : Program Int Model Msg
main =
    Html.programWithFlags
        { view = view >> toUnstyled
        , init = init
        , update = update
        , subscriptions = subscriptions
        }
