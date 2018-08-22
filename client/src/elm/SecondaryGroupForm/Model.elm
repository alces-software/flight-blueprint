module SecondaryGroupForm.Model
    exposing
        ( NameForm
        , SecondaryGroupForm(..)
        , init
        , validation
        )

import EverySet exposing (EverySet)
import Form exposing (Form)
import Form.Field as Field exposing (Field)
import Form.Validate exposing (..)
import Uuid exposing (Uuid)
import Validations


type SecondaryGroupForm
    = ShowingNameForm NameForm
    | SelectingGroups String (EverySet Uuid)


type alias NameForm =
    Form Validations.CustomError String


init : NameForm
init =
    Form.initial initialValues validation


initialValues : List ( String, Field )
initialValues =
    []


validation : Validation Validations.CustomError String
validation =
    -- XXX Extract things in some way so don't need to duplicate field names in
    -- different places.
    field "name" Validations.validateIdentifier
