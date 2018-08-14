module Model exposing (..)

import ComputeForm.Model exposing (ComputeForm, ComputeModal)
import EveryDict exposing (EveryDict)
import Node exposing (Node)
import PrimaryGroup exposing (PrimaryGroup)
import Random.Pcg exposing (Seed)
import Uuid exposing (Uuid)


type alias Model =
    { core : CoreDomain
    , clusters : List ClusterDomain
    , clusterPrimaryGroups : EveryDict Uuid PrimaryGroup
    , exportedYaml : String
    , randomSeed : Seed
    , computeModal : ComputeModal
    , computeForm : ComputeForm
    }


type alias CoreDomain =
    { gateway : Node
    , infra : Maybe Node
    }


type alias ClusterDomain =
    { name : String
    , login : Node
    , computeGroupIds : List Uuid
    }
