module SecondaryGroupForm.View exposing (viewForm)

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Form as ElmForm exposing (Form)
import Forms exposing (FieldName(..))
import Html exposing (..)
import ModalForm
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
        [ formInput <| Forms.configFor SecondaryGroupFormName

        -- XXX Move this button to modal footer?
        , Button.button
            [ Button.success
            , Button.onClick <| SecondaryGroupFormMsg ElmForm.Submit
            ]
            [ text "Select compute group members" ]
        ]
