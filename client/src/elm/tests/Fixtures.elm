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
import Fuzz.Extra
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
            List.concatMap .computeGroupIds clusters
                |> List.map
                    (\groupId ->
                        Fuzz.map
                            (\group -> { group | id = groupId })
                            fuzzGroup
                    )
                |> Fuzz.Extra.sequence

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
    shortListFuzzer fuzzCluster
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
        (shortListFuzzer Fuzz.string |> Fuzz.map Set.fromList)


nodesFixture : PrimaryGroup.NodesSpecification
nodesFixture =
    { base = "node"
    , startIndex = 1
    , size = 2
    , indexPadding = 3
    }


fuzzNodes : Fuzzer PrimaryGroup.NodesSpecification
fuzzNodes =
    let
        -- Fuzz small ints to be used for each int in the fuzzed
        -- `NodesSpecification`, this prevents lists of Nodes which are too
        -- large being generated when `PrimaryGroup.nodes` is called for a
        -- fuzzed `NodesSpecification` - previously these could be so large
        -- that JavaScript would run out of memory when running tests.
        smallIntFuzzer =
            Fuzz.intRange 0 10
    in
    Fuzz.map4
        PrimaryGroup.NodesSpecification
        Fuzz.string
        smallIntFuzzer
        smallIntFuzzer
        smallIntFuzzer


clusterFixture : ClusterDomain
clusterFixture =
    ClusterDomain.nextCluster []


fuzzCluster : Fuzzer ClusterDomain
fuzzCluster =
    Fuzz.map3 ClusterDomain
        Fuzz.string
        fuzzNode
        (shortListFuzzer fuzzUuid)


fuzzNode : Fuzzer Node
fuzzNode =
    Fuzz.map Node Fuzz.string


{-| Fuzz a list of `a`s of length 4 or less.

This is useful when the fuzzed list may be used for something somewhat
computationally expensive, and having a short list is unlikely to effect
whether tests will pass; using this in these situations should at least
significantly speed up running tests, and can prevent JavaScript running out of
memory when running tests (which previously could happen in some cases
where we used `Fuzz.list` instead).

-}
shortListFuzzer : Fuzzer a -> Fuzzer (List a)
shortListFuzzer itemFuzzer =
    Fuzz.map5
        (\a b c d length ->
            [ a, b, c, d ]
                |> List.take length
        )
        itemFuzzer
        itemFuzzer
        itemFuzzer
        itemFuzzer
        (Fuzz.intRange 0 4)
