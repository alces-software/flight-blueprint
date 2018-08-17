module SecondaryGroupForm.Model exposing (SecondaryGroupForm(..), init)

import EverySet exposing (EverySet)
import Form exposing (Form)
import Form.Field as Field exposing (Field)
import Form.Validate exposing (..)
import Uuid exposing (Uuid)


type
    SecondaryGroupForm
    -- XXX Give `Form () String` alias and use in different places?
    = ShowingNameForm (Form () String)
    | SelectingGroups String (EverySet Uuid)


init : Form () String
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
