module PrimaryGroup exposing (..)

import Node exposing (Node)


type alias PrimaryGroup =
    { name : String
    , nodes : NodesSpecification
    }


type alias NodesSpecification =
    { base : String
    , startIndex : Int
    , size : Int
    , indexPadding : Int

    -- XXX Maybe needed?
    -- , overrides : List something
    }


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
