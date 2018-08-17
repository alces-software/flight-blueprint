module Msg exposing (..)

import Form
import Uuid exposing (Uuid)


type Msg
    = AddCluster
    | RemoveCluster Int
    | StartAddingComputeGroup Int
    | CancelAddingComputeGroup
      -- XXX Here and for SecondaryGroupFormMsg - do we need to pass the Int
      -- (clusterIndex)? As can just be determined from Model state.
    | ComputeFormMsg Int Form.Msg
    | RemoveComputeGroup Uuid
    | AddInfra
    | RemoveInfra
    | NewConvertedYaml String
    | SetNodeName NodeSpecifier String
    | SetClusterName Int String
      -- XXX Extract sub-msg type for secondary group messages?
    | StartCreatingSecondaryGroup Int
    | SecondaryGroupFormMsg Int Form.Msg
      -- XXX Can modal cancel methods be collapsed together?
    | CancelCreatingSecondaryGroup
    | AddGroupToSecondaryGroup Uuid
    | RemoveGroupFromSecondaryGroup Uuid
    | CreateSecondaryGroup


type NodeSpecifier
    = Gateway
    | Infra
    | Login Int
      -- XXX Handle compute better
    | Compute
