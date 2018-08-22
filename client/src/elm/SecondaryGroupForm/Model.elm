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
import Forms exposing (FieldName(..))
import Forms.Validations as Validations
import Uuid exposing (Uuid)


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
    Forms.validateText SecondaryGroupFormName
