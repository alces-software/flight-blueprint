module Fixtures exposing (..)

import PrimaryGroup exposing (PrimaryGroup)
import Set


groupFixture : PrimaryGroup
groupFixture =
    { name = "nodes"
    , nodes = nodesFixture
    , secondaryGroups = Set.empty
    }


nodesFixture : PrimaryGroup.NodesSpecification
nodesFixture =
    { base = "node"
    , startIndex = 1
    , size = 2
    , indexPadding = 3
    }
