module Fixtures exposing (..)

import PrimaryGroup exposing (PrimaryGroup)
import Random.Pcg
import Set
import Uuid exposing (Uuid)


uuidFixture : Uuid
uuidFixture =
    let
        ( uuid, _ ) =
            Random.Pcg.step Uuid.uuidGenerator mockSeed

        mockSeed =
            Random.Pcg.initialSeed 5
    in
    uuid


groupFixture : PrimaryGroup
groupFixture =
    { id = uuidFixture
    , name = "nodes"
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
