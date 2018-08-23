module Forms
    exposing
        ( FieldConfig
        , FieldName(..)
        , FieldType(..)
        , computeFormValidation
        , configFor
        , initComputeForm
        , initSecondaryGroupNameForm
        , secondaryGroupNameFormValidation
        )

import ComputeForm.Model as ComputeForm exposing (ComputeForm)
import EveryDict exposing (EveryDict)
import Form
import Form.Field as Field exposing (Field)
import Form.Validate exposing (..)
import Forms.Validations as Validations
import List.Extra
import Maybe.Extra
import PrimaryGroup exposing (PrimaryGroup)
import SecondaryGroupForm.Model as SecondaryGroupForm exposing (NameForm)
import Set exposing (Set)
import Uuid exposing (Uuid)


type alias FieldConfig =
    { label : String
    , fieldIdentifier : String
    , fieldType : FieldType
    , help : String
    }


type FieldType
    = Identifier
    | Integer Validations.IntBounds


type FieldName
    = ComputeFormName
    | ComputeFormNodesBase
    | ComputeFormNodesStartIndex
    | ComputeFormNodesIndexPadding
    | ComputeFormNodesSize
    | SecondaryGroupFormName


initComputeForm : Uuid -> ComputeForm
initComputeForm newGroupId =
    computeFormValidation newGroupId
        |> Form.initial computeFormInitialValues


computeFormInitialValues : List ( String, Field )
computeFormInitialValues =
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


computeFormValidation : Uuid -> Validation Validations.CustomError PrimaryGroup
computeFormValidation newGroupId =
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


initSecondaryGroupNameForm : NameForm
initSecondaryGroupNameForm =
    Form.initial
        secondaryGroupNameFormInitialValues
        secondaryGroupNameFormValidation


secondaryGroupNameFormInitialValues : List ( String, Field )
secondaryGroupNameFormInitialValues =
    []


secondaryGroupNameFormValidation : Validation Validations.CustomError String
secondaryGroupNameFormValidation =
    validateText SecondaryGroupFormName



-- A limitation of the current design is that we need to specify the
-- `fieldType` within each FieldConfig, and then independently call the correct
-- `validate*` function from below in the overall form validation function.
-- This is required as these functions need to produce different types and so a
-- single function cannot handle all FieldTypes. Therefore if the incorrect
-- `validate*` function is called for a given FieldType we just need to handle
-- this in the minimal possible default way to get a value of the correct type;
-- hopefully it should be obvious if an incorrect `validate*` function is used
-- for a FieldType, as none of the validations will run.
--
-- XXX Consider if possible to improve this design, or if this abstraction is
-- more trouble than it's worth.


validateText : FieldName -> Validation Validations.CustomError String
validateText fieldName =
    let
        validateType fieldType =
            case fieldType of
                Identifier ->
                    Validations.validateIdentifier

                Integer _ ->
                    default

        default =
            string
    in
    createValidate validateType default fieldName


validateInt : FieldName -> Validation Validations.CustomError Int
validateInt fieldName =
    let
        validateType fieldType =
            case fieldType of
                Identifier ->
                    default

                Integer bounds ->
                    Validations.validateInteger bounds

        default =
            int
    in
    createValidate validateType default fieldName


createValidate :
    (FieldType -> Validation Validations.CustomError resultType)
    -> Validation Validations.CustomError resultType
    -> FieldName
    -> Validation Validations.CustomError resultType
createValidate validateType noConfigDefault fieldName =
    let
        validation =
            case configFor fieldName of
                Nothing ->
                    noConfigDefault

                Just config ->
                    validateType config.fieldType
    in
    field (shortIdentifier fieldName) validation


shortIdentifier : FieldName -> String
shortIdentifier field =
    configFor field
        |> Maybe.map (.fieldIdentifier >> String.split "." >> List.Extra.last)
        |> Maybe.Extra.join
        |> Maybe.withDefault ""


configFor : FieldName -> Maybe FieldConfig
configFor field =
    EveryDict.get field fieldConfigs


fieldConfigs : EveryDict FieldName FieldConfig
fieldConfigs =
    EveryDict.fromList
        [ ( ComputeFormName
          , { label = "New group name"
            , fieldIdentifier = "name"
            , fieldType = Identifier
            , help = "The name to use for this new group of compute nodes."
            }
          )
        , ( ComputeFormNodesBase
          , { label = "Base to use for generated node names"
            , fieldIdentifier = "nodes.base"
            , fieldType = Identifier
            , help = "E.g. 'node' to generate nodes like 'node01', 'node02' etc."
            }
          )
        , ( ComputeFormNodesStartIndex
          , { label = "Index to start from when generating node names"
            , fieldIdentifier = "nodes.startIndex"
            , fieldType = Integer { min = Just 1, max = Nothing }
            , help = "E.g. '4' for a node like 'node04' to be the first generated."
            }
          )
        , ( ComputeFormNodesIndexPadding
          , { label = "Padding to use for indices when generating nodes"
            , fieldIdentifier = "nodes.indexPadding"
            , fieldType = Integer { min = Just 0, max = Just 10 }
            , help = "E.g. '2' will pad each index like 'node01', or 3 will pad each like 'node001'."
            }
          )
        , ( ComputeFormNodesSize
          , { label = "Number of nodes to generate"
            , fieldIdentifier = "nodes.size"
            , fieldType = Integer { min = Just 1, max = Just 1000 }
            , help = "E.g. '10' to generate 10 nodes in this group."
            }
          )
        , ( SecondaryGroupFormName
          , { label = "Secondary group name"
            , fieldIdentifier = "name"
            , fieldType = Identifier
            , help = "The name to use for this secondary group."
            }
          )
        ]
