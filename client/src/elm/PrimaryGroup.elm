module PrimaryGroup exposing (..)

import EveryDict exposing (EveryDict)
import Node exposing (Node)
import Set exposing (Set)
import Uuid exposing (Uuid)


type alias PrimaryGroup =
    { id : Uuid
    , name : String
    , nodes : NodesSpecification
    , secondaryGroups : Set String
    }


type alias NodesSpecification =
    { base : String
    , startIndex : Int
    , size : Int
    , indexPadding : Int

    -- XXX Maybe needed?
    -- , overrides : List something
    }


type alias PrimaryGroupsDict =
    EveryDict Uuid PrimaryGroup


nodes : PrimaryGroup -> List Node
nodes group =
    let
        { base, startIndex, size, indexPadding } =
            group.nodes

        endIndex =
            startIndex + size - 1

        padIndex =
            String.padLeft indexPadding '0'
    in
    List.range startIndex endIndex
        |> List.map (toString >> padIndex >> (++) base >> Node)


addSecondaryGroup : String -> PrimaryGroup -> PrimaryGroup
addSecondaryGroup secondaryGroup group =
    { group
        | secondaryGroups =
            Set.insert secondaryGroup group.secondaryGroups
    }
