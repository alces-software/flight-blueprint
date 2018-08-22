module ComputeForm.Model exposing (ComputeForm, init, validation)

import Form exposing (Form)
import Form.Field as Field exposing (Field)
import Form.Validate exposing (..)
import Forms exposing (..)
import Forms.Validations as Validations
import PrimaryGroup exposing (PrimaryGroup)
import Set exposing (Set)
import Uuid exposing (Uuid)


type alias ComputeForm =
    Form Validations.CustomError PrimaryGroup


init : Uuid -> ComputeForm
init newGroupId =
    validation newGroupId
        |> Form.initial initialValues


initialValues : List ( String, Field )
initialValues =
    -- XXX Extract things in some way so don't need to duplicate field names in
    -- different places (each field is in at least 3 currently).
    [ ( shortIdentifier ComputeFormName, Field.string "mynodes" )
    , ( "nodes"
      , Field.group
            [ ( shortIdentifier ComputeFormNodesBase, Field.string "mynode" )
            , ( shortIdentifier ComputeFormNodesStartIndex, Field.string "1" )
            , ( shortIdentifier ComputeFormNodesSize, Field.string "" )
            , ( shortIdentifier ComputeFormNodesIndexPadding, Field.string "2" )
            ]
      )
    ]


validation : Uuid -> Validation Validations.CustomError PrimaryGroup
validation newGroupId =
    map4 PrimaryGroup
        (succeed newGroupId)
        (validateText ComputeFormName)
        (field "nodes"
            (map4 PrimaryGroup.NodesSpecification
                (validateText ComputeFormNodesBase)
                (validateInt ComputeFormNodesStartIndex)
                (validateInt ComputeFormNodesSize)
                (validateInt ComputeFormNodesIndexPadding)
            )
        )
        (succeed defaultSecondaryGroups)


defaultSecondaryGroups : Set String
defaultSecondaryGroups =
    Set.fromList [ "all", "nodes" ]
