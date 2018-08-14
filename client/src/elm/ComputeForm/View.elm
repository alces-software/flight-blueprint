module ComputeForm.View exposing (viewFormModal)

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Fieldset as Fieldset
import Bootstrap.Form.Input as Input
import Bootstrap.Modal as Modal
import ComputeForm.Model exposing (..)
import Form as ElmForm exposing (Form)
import Form.Error exposing (ErrorValue(..))
import Form.Field as Field exposing (Field)
import Form.Input
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import List.Extra
import Maybe.Extra
import Model exposing (Model)
import Msg exposing (..)
import PrimaryGroup exposing (PrimaryGroup)
import Utils


viewFormModal : Model -> Html Msg
viewFormModal model =
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
            ( Modal.hidden, "", Utils.nothing )
    in
    Modal.config CancelAddingComputeGroup
        |> Modal.hideOnBackdropClick True
        |> Modal.h3 [] [ text header ]
        |> Modal.body [] [ body ]
        |> Modal.footer []
            [ Button.button
                [ Button.outlineWarning
                , Button.attrs [ onClick CancelAddingComputeGroup ]
                ]
                [ text "Cancel" ]
            ]
        |> Modal.view visibility


viewComputeGroupForm : ComputeForm -> Int -> Html Msg
viewComputeGroupForm computeForm clusterIndex =
    let
        formInput_ =
            formInput computeForm
                >> Html.map (ComputeFormMsg clusterIndex)
    in
    Form.form []
        [ formInput_
            { label = "New group name"
            , fieldIdentifier = "name"
            , fieldType = Text
            , help = "The name to use for this new group of compute nodes."
            }
        , Fieldset.config
            |> Fieldset.asGroup
            |> Fieldset.legend [] [ text "Generate nodes in this group" ]
            |> Fieldset.children
                [ formInput_
                    { label = "Base to use for generated node names"
                    , fieldIdentifier = "nodes.base"
                    , fieldType = Text
                    , help = "E.g. 'node' to generate nodes like 'node01', 'node02' etc."
                    }
                , formInput_
                    { label = "Index to start from when generating node names"
                    , fieldIdentifier = "nodes.startIndex"
                    , fieldType = Integer { min = Just 1, max = Nothing }
                    , help = "E.g. '4' for a node like 'node04' to be the first generated."
                    }
                , formInput_
                    { label = "Padding to use for indices when generating nodes"
                    , fieldIdentifier = "nodes.indexPadding"
                    , fieldType = Integer { min = Just 0, max = Just 10 }
                    , help = "E.g. '2' will pad each index like 'node01', or 3 will pad each like 'node001'."
                    }
                , formInput_
                    { label = "Number of nodes to generate"
                    , fieldIdentifier = "nodes.size"
                    , fieldType = Integer { min = Just 1, max = Nothing }
                    , help = "E.g. '10' to generate 10 nodes in this group."
                    }
                ]
            |> Fieldset.view

        -- XXX Move this button to modal footer?
        -- XXX Add reset button too?
        , Button.button
            [ Button.success
            , Button.onClick <| ComputeFormMsg clusterIndex ElmForm.Submit
            ]
            [ text "Create" ]
        ]


type alias FieldConfig =
    { label : String
    , fieldIdentifier : String
    , fieldType : FieldType
    , help : String
    }


type FieldType
    = Text
    | Integer { min : Maybe Int, max : Maybe Int }


formInput : ComputeForm -> FieldConfig -> Html ElmForm.Msg
formInput computeForm config =
    let
        field =
            ElmForm.getFieldAsString config.fieldIdentifier computeForm

        ( errorAttr, errorElement ) =
            -- XXX Currently valdidate and display errors on submit - better
            -- than initially displaying fields as invalid. Consider if better
            -- way to do this.
            case field.liveError of
                Just error ->
                    ( Input.danger
                    , Form.invalidFeedback []
                        [ text <| errorMessage error ]
                    )

                Nothing ->
                    ( Input.success, Utils.nothing )

        attrs =
            List.concat
                [ elmFormAttrs_
                , additionalInputAttrs
                ]

        elmFormAttrs_ =
            elmFormAttrs Field.String ElmForm.Text field

        additionalInputAttrs =
            case config.fieldType of
                Text ->
                    [ type_ "text" ]

                Integer { min, max } ->
                    Maybe.Extra.values
                        [ Just <| type_ "number"
                        , Maybe.map (toString >> Html.Attributes.min) min
                        , Maybe.map (toString >> Html.Attributes.max) max
                        ]

        inputId =
            "computeForm" ++ config.fieldIdentifier
    in
    Form.group []
        [ Form.label [ for inputId ] [ text config.label ]
        , Input.text
            [ Input.id inputId
            , errorAttr
            , Input.attrs attrs
            ]
        , Form.help [] [ text config.help ]
        , errorElement
        ]


elmFormAttrs :
    (String -> Field.FieldValue)
    -> ElmForm.InputType
    -> ElmForm.FieldState e String
    -> List (Attribute ElmForm.Msg)
elmFormAttrs toFieldValue inputType state =
    -- This should correspond with the attributes set in
    -- `https://github.com/etaque/elm-form/blob/3.0.0/src/Form/Input.elm#L32,L41`
    -- but:
    --
    -- - without the `type_` (as independently setting this elsewhere);
    --
    -- - without the containing `input` (as will be used with an input created
    -- using `Bootstrap.Form.Input`).
    --
    -- This allows us to use elements created using `elm-bootstrap`, but wired
    -- up so they should Just Work with `elm-form`.
    [ defaultValue (state.value |> Maybe.withDefault "")
    , onInput (toFieldValue >> ElmForm.Input state.path inputType)
    , onFocus (ElmForm.Focus state.path)
    , onBlur (ElmForm.Blur state.path)
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
