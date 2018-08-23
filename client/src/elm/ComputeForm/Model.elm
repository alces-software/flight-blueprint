module ComputeForm.Model exposing (ComputeForm)

import Form exposing (Form)
import Forms.Validations as Validations
import PrimaryGroup exposing (PrimaryGroup)


type alias ComputeForm =
    Form Validations.CustomError PrimaryGroup
