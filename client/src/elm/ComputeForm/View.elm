module ComputeForm.View exposing (view)

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Fieldset as Fieldset
import ComputeForm.Model exposing (..)
import Form as ElmForm exposing (Form)
import Html exposing (..)
import ModalForm exposing (FieldType(..))
import Msg exposing (..)


view : ComputeForm -> Int -> Html Msg
view computeForm clusterIndex =
    let
        formInput =
            ModalForm.input computeForm
                >> Html.map (ComputeFormMsg clusterIndex)
    in
    Form.form []
        [ formInput
            { label = "New group name"
            , fieldIdentifier = "name"
            , fieldType = Text
            , help = "The name to use for this new group of compute nodes."
            }
        , Fieldset.config
            |> Fieldset.asGroup
            |> Fieldset.legend [] [ text "Generate nodes in this group" ]
            |> Fieldset.children
                [ formInput
                    { label = "Base to use for generated node names"
                    , fieldIdentifier = "nodes.base"
                    , fieldType = Text
                    , help = "E.g. 'node' to generate nodes like 'node01', 'node02' etc."
                    }
                , formInput
                    { label = "Index to start from when generating node names"
                    , fieldIdentifier = "nodes.startIndex"
                    , fieldType = Integer { min = Just 1, max = Nothing }
                    , help = "E.g. '4' for a node like 'node04' to be the first generated."
                    }
                , formInput
                    { label = "Padding to use for indices when generating nodes"
                    , fieldIdentifier = "nodes.indexPadding"
                    , fieldType = Integer { min = Just 0, max = Just 10 }
                    , help = "E.g. '2' will pad each index like 'node01', or 3 will pad each like 'node001'."
                    }
                , formInput
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
