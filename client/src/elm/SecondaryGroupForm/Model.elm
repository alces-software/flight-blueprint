module SecondaryGroupForm.Model
    exposing
        ( NameForm
        , SecondaryGroupForm(..)
        , init
        )

import EverySet exposing (EverySet)
import Form exposing (Form)
import Form.Field as Field exposing (Field)
import Form.Validate exposing (..)
import Uuid exposing (Uuid)


type SecondaryGroupForm
    = ShowingNameForm NameForm
    | SelectingGroups String (EverySet Uuid)


type alias NameForm =
    Form () String


init : NameForm
init =
    Form.initial initialValues validation


initialValues : List ( String, Field )
initialValues =
    []


validation : Validation () String
validation =
    -- XXX Extract things in some way so don't need to duplicate field names in
    -- different places.
    -- XXX Validate this more thoroughly? What characters are invalid in group
    -- names?
    field "name" string
