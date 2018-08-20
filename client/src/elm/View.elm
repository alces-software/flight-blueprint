module View exposing (view)

import Bootstrap.Modal as Modal
import ClusterDomain exposing (ClusterDomain)
import ComputeForm.View
import Count
import Css exposing (..)
import Css.Colors exposing (..)
import EveryDict exposing (EveryDict)
import EverySet exposing (EverySet)
import FeatherIcons as Icons exposing (Icon)
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attributes exposing (..)
import Html.Styled.Events exposing (onClick, onInput)
import List.Extra
import ModalForm
import Model exposing (CoreDomain, Model)
import Msg exposing (..)
import Node exposing (Node)
import PrimaryGroup exposing (PrimaryGroup)
import SecondaryGroupForm.Model
import SecondaryGroupForm.View
import Utils
import Uuid exposing (Uuid)


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
                    |> List.concat
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
        , viewModal model
        ]


type alias Layers =
    { normal : Style
    , overlay : Style
    , focusedCluster : Style
    }


layers : Layers
layers =
    let
        shiftValue zIndexValue =
            -- Multiply values sufficiently so that they show in front of
            -- Flight product/brand bars, subtracting one from first value so
            -- the 'normal' layer is at `z-index: 0`.
            (zIndexValue - 1) * 1500
    in
    Count.mapTo3
        (\zIndexValue -> zIndex (int <| shiftValue zIndexValue))
        Layers


viewModal : Model -> Html Msg
viewModal model =
    let
        ( visibility, header, body ) =
            case model.displayedForm of
                Model.NoForm ->
                    hiddenModalTriplet

                Model.ComputeForm clusterIndex form ->
                    let
                        maybeCluster =
                            List.Extra.getAt clusterIndex model.clusters
                    in
                    case maybeCluster of
                        Just cluster ->
                            ( Modal.shown
                            , "Add compute to " ++ cluster.name
                            , ComputeForm.View.view form
                            )

                        Nothing ->
                            -- If we're trying to add compute to a cluster
                            -- which isn't in the model, something must have
                            -- gone wrong, so keep the modal hidden.
                            hiddenModalTriplet

                Model.SecondaryGroupForm clusterIndex form ->
                    case form of
                        SecondaryGroupForm.Model.ShowingNameForm form ->
                            -- XXX DRY up with ComputeForm branch.
                            let
                                maybeCluster =
                                    List.Extra.getAt clusterIndex model.clusters
                            in
                            case maybeCluster of
                                Just cluster ->
                                    ( Modal.shown
                                    , "Create secondary group for " ++ cluster.name
                                    , SecondaryGroupForm.View.viewForm form
                                    )

                                Nothing ->
                                    -- If we're trying to create secondary
                                    -- group for a cluster which isn't in the
                                    -- model, something must have gone wrong,
                                    -- so keep the modal hidden.
                                    hiddenModalTriplet

                        SecondaryGroupForm.Model.SelectingGroups _ _ ->
                            -- We're at the group selection stage, so do not
                            -- show the modal.
                            hiddenModalTriplet

        hiddenModalTriplet =
            ( Modal.hidden, "", Utils.nothing )
    in
    ModalForm.view visibility header body CancelAddingComputeGroup
        |> Html.Styled.fromUnstyled


viewCore : CoreDomain -> Html Msg
viewCore core =
    let
        coreColor =
            blue

        infraNodeOrButton =
            case core.infra of
                Just infra ->
                    viewNode False coreColor Infra (Just RemoveInfra) infra

                Nothing ->
                    addInfraButton
    in
    viewDomain coreColor
        []
        [ -- XXX If decide we want to allow changing `core` name then move this
          -- from `viewCluster` into `viewDomain`, and remove name as just text
          -- here.
          text Model.coreName
        , viewNode False coreColor Gateway Nothing core.gateway
        , infraNodeOrButton
        ]


viewCluster : Model -> Int -> ClusterDomain -> List (Html Msg)
viewCluster model clusterIndex cluster =
    let
        color =
            clusterColor model clusterIndex

        additionalStyles =
            if isFocusedCluster then
                [ layers.focusedCluster
                , position relative
                , opacity (int 1)
                ]
            else
                []

        isFocusedCluster =
            case overlayData of
                Just ( focusedCluster, _, _ ) ->
                    cluster == focusedCluster

                Nothing ->
                    False

        overlayData =
            secondaryGroupSelectionOverlayData model

        startGroupingButton_ =
            startGroupingButton isFocusedCluster color clusterIndex

        clusterNameInput =
            nameInput
                isFocusedCluster
                color
                cluster
                (SetClusterName clusterIndex)

        removeClusterButton =
            removeButton isFocusedCluster <| RemoveCluster clusterIndex

        loginNode =
            viewNode
                isFocusedCluster
                color
                (Login clusterIndex)
                Nothing
                cluster.login

        primaryGroups =
            List.map
                (viewPrimaryGroup model isFocusedCluster color)
                cluster.computeGroupIds

        addComputeButton_ =
            addComputeButton isFocusedCluster clusterIndex
    in
    [ viewDomain color
        additionalStyles
        (List.concat
            [ [ startGroupingButton_
              , clusterNameInput
              , removeClusterButton
              , loginNode
              ]
            , primaryGroups
            , [ addComputeButton_ ]
            ]
        )
    , if isFocusedCluster then
        maybeHtml overlayData secondaryGroupSelectionOverlay
      else
        nothing
    ]


secondaryGroupSelectionOverlayData : Model -> Maybe ( ClusterDomain, String, EverySet Uuid )
secondaryGroupSelectionOverlayData model =
    case model.displayedForm of
        Model.SecondaryGroupForm clusterIndex form ->
            case ( List.Extra.getAt clusterIndex model.clusters, form ) of
                ( Just cluster, SecondaryGroupForm.Model.SelectingGroups secondaryGroupName members ) ->
                    Just ( cluster, secondaryGroupName, members )

                _ ->
                    Nothing

        _ ->
            Nothing


secondaryGroupSelectionOverlay : ( ClusterDomain, String, EverySet Uuid ) -> Html Msg
secondaryGroupSelectionOverlay ( cluster, secondaryGroupName, members ) =
    div
        [ css
            [ -- Similar styling to Bootstrap modals, so transition from
              -- naming secondary group to selecting members is fairly
              -- seamless.
              position fixed
            , top zero
            , bottom zero
            , left zero
            , right zero
            , layers.overlay
            , backgroundColor (hex "000")
            , opacity (num 0.5)
            ]
        ]
        [-- XXX Add cancel button here
        ]


startGroupingButton : Bool -> Color -> Int -> Html Msg
startGroupingButton disabled color clusterIndex =
    let
        titleText =
            "Create secondary group to organize compute in this cluster"
    in
    iconButton
        disabled
        color
        Icons.grid
        titleText
        [ marginRight (px 8) ]
        (StartCreatingSecondaryGroup clusterIndex)


viewPrimaryGroup : Model -> Bool -> Color -> Uuid -> Html Msg
viewPrimaryGroup model clusterIsFocused color groupId =
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
                          , removeButton clusterIsFocused <| RemoveComputeGroup groupId
                          ]
                        , List.map (viewNode clusterIsFocused color Compute Nothing) nodes
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
    addButton False "infra" nodeStyles AddInfra


addComputeButton : Bool -> Int -> Html Msg
addComputeButton disabled clusterIndex =
    addButton disabled "compute" nodeStyles (StartAddingComputeGroup clusterIndex)


addClusterButton : Html Msg
addClusterButton =
    addButton False "cluster" domainStyles AddCluster


addButton : Bool -> String -> (Color -> List Style) -> Msg -> Html Msg
addButton disabled itemToAdd colorToStyles addMsg =
    let
        attrs =
            css styles :: conditionalAttrs

        styles =
            List.concat
                [ [ buttonFontSize
                  , Css.width (pct 100)
                  ]
                , colorToStyles green
                , conditionalStyles
                ]

        ( conditionalAttrs, conditionalStyles ) =
            if disabled then
                ( [ Attributes.disabled True ], [ cursor Css.default ] )
            else
                ( [ onClick addMsg ], [] )
    in
    button attrs [ text <| "+" ++ itemToAdd ]


removeButton : Bool -> Msg -> Html Msg
removeButton disabled removeMsg =
    iconButton disabled red Icons.x "" [ float right ] removeMsg


iconButton :
    Bool
    -> Color
    -> Icon
    -> String
    -> List Style
    -> Msg
    -> Html Msg
iconButton disabled iconColor icon titleText additionalStyles msg =
    let
        styles =
            List.concat
                [ [ backgroundColor white
                  , border unset
                  , buttonFontSize
                  , color iconColor
                  , padding unset
                  , verticalAlign top
                  ]
                , conditionalStyles
                , additionalStyles
                ]

        attrs =
            List.concat
                [ [ css styles ]
                , conditionalAttrs
                ]

        ( conditionalStyles, conditionalAttrs ) =
            if disabled then
                ( [ cursor Css.default
                  , important <| outline none
                  ]
                , []
                )
            else
                ( [], [ onClick msg, title titleText ] )
    in
    button attrs [ viewIcon icon ]


viewNode : Bool -> Color -> NodeSpecifier -> Maybe Msg -> Node -> Html Msg
viewNode actionsDisabled color nodeSpecifier removeMsg node =
    div
        [ css <| nodeStyles color ]
        [ nodeIcon nodeSpecifier
        , nameInput actionsDisabled color node (SetNodeName nodeSpecifier)
        , maybeHtml removeMsg (removeButton actionsDisabled)
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
    in
    div
        [ css
            [ display inlineBlock
            , marginRight (px 5)
            ]
        , title titleText
        ]
        [ viewIcon icon ]


nameInput : Bool -> Color -> { a | name : String } -> (String -> Msg) -> Html Msg
nameInput disabled color { name } inputMsg =
    input
        [ value name
        , onInput inputMsg
        , Attributes.disabled disabled
        , css
            -- Reset input styles to look like regular text (adapted from
            -- https://stackoverflow.com/a/38830702/2620402).
            [ border unset
            , display inline
            , fontFamily inherit
            , fontSize inherit
            , padding zero

            -- Do not set width to 100% to allow space for remove buttons.
            , Css.width (pct 80)
            , Css.color color
            , backgroundColor white
            , cursor Css.text_
            ]
        ]
        []


viewDomain : Color -> List Style -> List (Html Msg) -> Html Msg
viewDomain color additionalStyles children =
    let
        styles =
            List.concat
                [ domainStyles color
                , additionalStyles
                ]
    in
    div [ css styles ] children


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


viewIcon : Icon -> Html msg
viewIcon =
    Icons.withSize 15
        >> Icons.toHtml []
        >> Html.Styled.fromUnstyled



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
