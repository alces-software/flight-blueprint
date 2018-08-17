module SecondaryGroupForm.View exposing (viewForm)

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Fieldset as Fieldset
import Form as ElmForm exposing (Form)
import Html exposing (..)
import ModalForm exposing (FieldType(..))
import Msg exposing (..)
import SecondaryGroupForm.Model exposing (..)


viewForm : NameForm -> Html Msg
viewForm form =
    let
        formInput =
            ModalForm.input form
                >> Html.map SecondaryGroupFormMsg
    in
    Form.form []
        [ formInput
            { label = "Secondary group name"
            , fieldIdentifier = "name"
            , fieldType = Text
            , help = "The name to use for this secondary group."
            }

        -- XXX Move this button to modal footer?
        , Button.button
            [ Button.success
            , Button.onClick <| SecondaryGroupFormMsg ElmForm.Submit
            ]
            [ text "Select compute group members" ]
        ]
