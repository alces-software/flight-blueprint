module Model exposing (..)

import Canopy
import ComputeForm.Model exposing (ComputeForm, ComputeModal)
import EveryDict exposing (EveryDict)
import List.Nonempty exposing (Nonempty)
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
    , groupsTree : GroupsTree
    }


type alias GroupsTree =
    -- XXX Make this encapsulated type and enforce how it is updated?
    -- (PrimaryGroups cannot have children)
    -- XXX Use extracted type
    Canopy.Node NodeData


type
    NodeData
    -- XXX Handle login nodes here?
    = PrimaryGroup Uuid
    | SecondaryGroups (Nonempty String)
