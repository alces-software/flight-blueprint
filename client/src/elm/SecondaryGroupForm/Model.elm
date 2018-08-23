module SecondaryGroupForm.Model exposing (NameForm, SecondaryGroupForm(..))

import EverySet exposing (EverySet)
import Form exposing (Form)
import Forms.Validations as Validations
import Uuid exposing (Uuid)


type SecondaryGroupForm
    = ShowingNameForm NameForm
    | SelectingGroups String (EverySet Uuid)


type alias NameForm =
    Form Validations.CustomError String
