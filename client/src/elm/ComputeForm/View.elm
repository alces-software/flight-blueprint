module ComputeForm.View exposing (view)

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Fieldset as Fieldset
import ComputeForm.Model exposing (..)
import Form as ElmForm exposing (Form)
import Forms exposing (FieldName(..))
import Html exposing (..)
import ModalForm
import Msg exposing (..)


view : ComputeForm -> Html Msg
view computeForm =
    let
        formInput =
            ModalForm.input computeForm
                >> Html.map ComputeFormMsg
    in
    Form.form []
        [ formInput <| Forms.configFor ComputeFormName
        , Fieldset.config
            |> Fieldset.asGroup
            |> Fieldset.legend [] [ text "Generate nodes in this group" ]
            |> Fieldset.children
                [ formInput <| Forms.configFor ComputeFormNodesBase
                , formInput <| Forms.configFor ComputeFormNodesStartIndex
                , formInput <| Forms.configFor ComputeFormNodesIndexPadding
                , formInput <| Forms.configFor ComputeFormNodesSize
                ]
            |> Fieldset.view

        -- XXX Move this button to modal footer?
        -- XXX Add reset button too?
        , Button.button
            [ Button.success
            , Button.onClick <| ComputeFormMsg ElmForm.Submit
            ]
            [ text "Create" ]
        ]
