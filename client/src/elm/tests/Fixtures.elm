module Fixtures
    exposing
        ( clusterFixture
        , fuzzGroup
        , fuzzModel
        , groupFixture
        , initialModelFixture
        , nodesFixture
        , uuidFixture
        )

import ClusterDomain exposing (ClusterDomain)
import EveryDict
import Fuzz exposing (Fuzzer)
import Model exposing (CoreDomain, Model)
import Node exposing (Node)
import PrimaryGroup exposing (PrimaryGroup)
import Random.Pcg
import Set
import Shrink
import Uuid exposing (Uuid)


initialModelFixture : Model
initialModelFixture =
    Model.init 5 |> Tuple.first


fuzzModel : Fuzzer Model
fuzzModel =
    let
        fuzzGroupsForClusters clusters =
            -- XXX Just fuzz empty list of groups for now, rather than fuzzing
            -- every group for every cluster - code below should work to do
            -- that but seems to cause run-time errors like "RangeError:
            -- Maximum call stack size exceeded" and "JavaScript heap out of
            -- memory".
            --
            -- List.concatMap .computeGroupIds clusters
            --     |> List.map
            --         (\groupId ->
            --             Fuzz.map
            --                 (\group -> { group | id = groupId })
            --                 fuzzGroup
            --         )
            --     |> Fuzz.Extra.sequence
            --
            Fuzz.constant []

        fuzzModelWithClustersAndGroups clusters groups =
            Fuzz.map Model
                fuzzCore
                |> Fuzz.andMap (Fuzz.constant clusters)
                |> Fuzz.andMap
                    (Fuzz.constant
                        ((List.map (\g -> ( g.id, g ))
                            >> EveryDict.fromList
                         )
                            groups
                        )
                    )
                |> Fuzz.andMap Fuzz.string
                |> Fuzz.andMap fuzzSeed
                -- XXX Hard-coding this to NoForm is not very random but is easy to do,
                -- and (for now at least) this shouldn't effect anything where this
                -- fuzzer is being used. For robustness would be good to make this
                -- actually random though.
                |> Fuzz.andMap (Fuzz.constant Model.NoForm)
    in
    Fuzz.list fuzzCluster
        |> Fuzz.andThen
            (\clusters ->
                fuzzGroupsForClusters clusters
                    |> Fuzz.andThen
                        (fuzzModelWithClustersAndGroups clusters)
            )


fuzzCore : Fuzzer CoreDomain
fuzzCore =
    Fuzz.map2 CoreDomain
        fuzzNode
        (Fuzz.maybe fuzzNode)


uuidFixture : Uuid
uuidFixture =
    let
        ( uuid, _ ) =
            Random.Pcg.step Uuid.uuidGenerator mockSeed

        mockSeed =
            Random.Pcg.initialSeed 5
    in
    uuid


fuzzSeed : Fuzzer Random.Pcg.Seed
fuzzSeed =
    Fuzz.map Random.Pcg.initialSeed Fuzz.int


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


fuzzCluster : Fuzzer ClusterDomain
fuzzCluster =
    Fuzz.map3 ClusterDomain
        Fuzz.string
        fuzzNode
        (Fuzz.list fuzzUuid)


fuzzNode : Fuzzer Node
fuzzNode =
    Fuzz.map Node Fuzz.string
