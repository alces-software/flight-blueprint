module Fixtures
    exposing
        ( clusterFixture
        , fuzzGroup
        , groupFixture
        , initialModelFixture
        , nodesFixture
        , uuidFixture
        )

import ClusterDomain exposing (ClusterDomain)
import Fuzz exposing (Fuzzer)
import Model exposing (Model)
import PrimaryGroup exposing (PrimaryGroup)
import Random.Pcg
import Set
import Shrink
import Uuid exposing (Uuid)


initialModelFixture : Model
initialModelFixture =
    Model.init 5 |> Tuple.first


uuidFixture : Uuid
uuidFixture =
    let
        ( uuid, _ ) =
            Random.Pcg.step Uuid.uuidGenerator mockSeed

        mockSeed =
            Random.Pcg.initialSeed 5
    in
    uuid


fuzzUuid : Fuzzer Uuid
fuzzUuid =
    Fuzz.custom Uuid.uuidGenerator Shrink.noShrink


groupFixture : PrimaryGroup
groupFixture =
    { id = uuidFixture
    , name = "nodes"
    , nodes = nodesFixture
    , secondaryGroups = Set.empty
    }


fuzzGroup : Fuzzer PrimaryGroup
fuzzGroup =
    Fuzz.map4
        PrimaryGroup
        fuzzUuid
        Fuzz.string
        fuzzNodes
        (Fuzz.list Fuzz.string |> Fuzz.map Set.fromList)


nodesFixture : PrimaryGroup.NodesSpecification
nodesFixture =
    { base = "node"
    , startIndex = 1
    , size = 2
    , indexPadding = 3
    }


fuzzNodes : Fuzzer PrimaryGroup.NodesSpecification
fuzzNodes =
    Fuzz.map4
        PrimaryGroup.NodesSpecification
        Fuzz.string
        Fuzz.int
        Fuzz.int
        Fuzz.int


clusterFixture : ClusterDomain
clusterFixture =
    ClusterDomain.nextCluster []
