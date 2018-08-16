module ComputeForm.Model
    exposing
        ( ComputeForm
        , ComputeModal(..)
        , init
        , validation
        )

import Form exposing (Form)
import Form.Field as Field exposing (Field)
import Form.Validate exposing (..)
import PrimaryGroup exposing (PrimaryGroup)


type alias ComputeForm =
    Form () PrimaryGroup


type ComputeModal
    = Hidden
    | AddingCompute Int


init : ComputeForm
init =
    Form.initial initialValues validation


initialValues : List ( String, Field )
initialValues =
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


validation : Validation () PrimaryGroup
validation =
    -- XXX Do more thoroughly - validate integers within ranges defined in view
    -- etc.
    map2 PrimaryGroup
        (field "name" string)
        (field "nodes"
            (map4 PrimaryGroup.NodesSpecification
                (field "base" string)
                (field "startIndex" int)
                (field "size" int)
                (field "indexPadding" int)
            )
        )
