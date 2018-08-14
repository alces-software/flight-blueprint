module Msg exposing (..)

import Form
import Uuid exposing (Uuid)


type Msg
    = AddCluster
    | RemoveCluster Int
    | StartAddingComputeGroup Int
    | CancelAddingComputeGroup
    | ComputeFormMsg Int Form.Msg
    | RemoveComputeGroup Uuid
    | AddInfra
    | RemoveInfra
    | NewConvertedYaml String
    | SetNodeName NodeSpecifier String
    | SetClusterName Int String


type NodeSpecifier
    = Gateway
    | Infra
    | Login Int
      -- XXX Handle compute better
    | Compute
