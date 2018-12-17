module Msg exposing (..)

import Form
import Uuid exposing (Uuid)


type Msg
    = AddCluster
    | RemoveCluster Int
    | StartAddingComputeGroup Int
    | CancelAddingComputeGroup
    | ComputeFormMsg Form.Msg
    | RemoveComputeGroup Uuid
    | AddInfra
    | RemoveInfra
    | NewConvertedYaml String
    | SetNodeName NodeSpecifier String
    | SetClusterName Int String
      -- XXX Extract sub-msg type for secondary group messages?
    | StartCreatingSecondaryGroup Int
    | SecondaryGroupFormMsg Form.Msg
      -- XXX Can modal cancel methods be collapsed together?
    | CancelCreatingSecondaryGroup
    | AddGroupToSecondaryGroup Uuid
    | RemoveGroupFromSecondaryGroup Uuid
    | CreateSecondaryGroup
    | SetPrimaryGroupName Uuid Int String


type NodeSpecifier
    = Gateway
    | Infra
    | Login Int
      -- XXX Handle compute better
    | Compute
