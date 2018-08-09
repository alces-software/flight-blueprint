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
