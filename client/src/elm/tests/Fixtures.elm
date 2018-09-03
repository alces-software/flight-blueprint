module Fixtures
    exposing
        ( clusterFixture
        , groupFixture
        , initialModelFixture
        , nodesFixture
        , uuidFixture
        )

import Blueprint exposing (CoreDomain)
import ClusterDomain exposing (ClusterDomain)
import EveryDict
import Model exposing (Model)
import Node exposing (Node)
import PrimaryGroup exposing (PrimaryGroup)
import Random.Pcg
import Set
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


clusterFixture : ClusterDomain
clusterFixture =
    ClusterDomain.nextCluster []
