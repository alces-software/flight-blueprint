module ComputeForm.Model exposing (..)

import Form exposing (Form)
import PrimaryGroup exposing (PrimaryGroup)


type alias ComputeForm =
    Form () PrimaryGroup


type ComputeModal
    = Hidden
    | AddingCompute Int
