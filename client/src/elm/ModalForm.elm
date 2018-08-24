module ModalForm exposing (input, view)

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Modal as Modal
import Form as ElmForm exposing (Form)
import Form.Error exposing (ErrorValue(..))
import Form.Field as Field exposing (Field)
import Forms exposing (FieldConfig, FieldName, FieldType(..))
import Forms.Validations as Validations exposing (CustomError(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Maybe.Extra
import Utils


view : Modal.Visibility -> String -> Html msg -> msg -> Html msg
view visibility header body cancelMsg =
    Modal.config cancelMsg
        |> Modal.hideOnBackdropClick True
        |> Modal.h3 [] [ text header ]
        |> Modal.body [] [ body ]
        |> Modal.footer []
            [ Button.button
                [ Button.outlineWarning
                , Button.attrs [ onClick cancelMsg ]
                ]
                [ text "Cancel" ]
            ]
        |> Modal.view visibility


input : Form Validations.CustomError result -> FieldName -> Html ElmForm.Msg
input form fieldName =
    -- Render input for config, if config is not Nothing.
    Utils.maybeHtml
        (Forms.configFor fieldName)
        (inputWithConfig form)


inputWithConfig : Form Validations.CustomError result -> FieldConfig -> Html ElmForm.Msg
inputWithConfig form config =
    let
        field =
            ElmForm.getFieldAsString config.fieldIdentifier form

        ( errorAttr, errorElement ) =
            -- XXX Currently validate and display errors on submit - better
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
            let
                textAttrs =
                    [ type_ "text" ]
            in
            case config.fieldType of
                Identifier ->
                    textAttrs

                GroupName ->
                    textAttrs

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


errorMessage : ErrorValue Validations.CustomError -> String
errorMessage errorValue =
    let
        overMaximum i =
            "Maximum " ++ i ++ "."

        underMinimum i =
            "Minimum " ++ i ++ "."
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
            underMinimum <| toString i

        GreaterIntThan i ->
            overMaximum <| toString i

        SmallerFloatThan i ->
            underMinimum <| toString i

        GreaterFloatThan i ->
            overMaximum <| toString i

        ShorterStringThan i ->
            underMinimum <| toString i ++ " characters"

        LongerStringThan i ->
            overMaximum <| toString i ++ " characters"

        NotIncludedIn ->
            ""

        CustomError e ->
            customErrorMessage e


customErrorMessage : Validations.CustomError -> String
customErrorMessage error =
    let
        groupExists groupType =
            String.join " "
                [ "A"
                , groupType
                , "group with this name already exists for this cluster."
                ]
    in
    case error of
        InvalidIdentifierCharacters ->
            "Can only contain the letters a-z, and numbers 0-9."

        InvalidIdentifierFirstCharacter ->
            "First character must be a letter."

        ExistingPrimaryGroup ->
            groupExists "primary"

        ExistingSecondaryGroup ->
            groupExists "secondary"
