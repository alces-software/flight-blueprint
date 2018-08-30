module Fixtures
    exposing
        ( clusterFixture
        , groupFixture
        , groupFuzzer
        , initialModelFixture
        , modelFuzzer
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


modelFuzzer : Fuzzer Model
modelFuzzer =
    let
        groupsForClustersFuzzer clusters =
            List.concatMap .computeGroupIds clusters
                |> List.map
                    (\groupId ->
                        Fuzz.map
                            (\group -> { group | id = groupId })
                            groupFuzzer
                    )
                |> Fuzz.Extra.sequence

        modelWithClustersAndGroupsFuzzer clusters groups =
            Fuzz.map Model
                coreFuzzer
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
                |> Fuzz.andMap seedFuzzer
                -- XXX Hard-coding this to NoForm is not very random but is easy to do,
                -- and (for now at least) this shouldn't effect anything where this
                -- fuzzer is being used. For robustness would be good to make this
                -- actually random though.
                |> Fuzz.andMap (Fuzz.constant Model.NoForm)
    in
    shortListFuzzer clusterFuzzer
        |> Fuzz.andThen
            (\clusters ->
                groupsForClustersFuzzer clusters
                    |> Fuzz.andThen
                        (modelWithClustersAndGroupsFuzzer clusters)
            )


coreFuzzer : Fuzzer CoreDomain
coreFuzzer =
    Fuzz.map2 CoreDomain
        nodeFuzzer
        (Fuzz.maybe nodeFuzzer)


uuidFixture : Uuid
uuidFixture =
    let
        ( uuid, _ ) =
            Random.Pcg.step Uuid.uuidGenerator mockSeed

        mockSeed =
            Random.Pcg.initialSeed 5
    in
    uuid


seedFuzzer : Fuzzer Random.Pcg.Seed
seedFuzzer =
    Fuzz.map Random.Pcg.initialSeed Fuzz.int


uuidFuzzer : Fuzzer Uuid
uuidFuzzer =
    Fuzz.custom Uuid.uuidGenerator Shrink.noShrink


groupFixture : PrimaryGroup
groupFixture =
    { id = uuidFixture
    , name = "nodes"
    , nodes = nodesFixture
    , secondaryGroups = Set.empty
    }


groupFuzzer : Fuzzer PrimaryGroup
groupFuzzer =
    Fuzz.map4
        PrimaryGroup
        uuidFuzzer
        Fuzz.string
        nodesSpecificationFuzzer
        (shortListFuzzer Fuzz.string |> Fuzz.map Set.fromList)


nodesFixture : PrimaryGroup.NodesSpecification
nodesFixture =
    { base = "node"
    , startIndex = 1
    , size = 2
    , indexPadding = 3
    }


nodesSpecificationFuzzer : Fuzzer PrimaryGroup.NodesSpecification
nodesSpecificationFuzzer =
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


clusterFuzzer : Fuzzer ClusterDomain
clusterFuzzer =
    Fuzz.map3 ClusterDomain
        Fuzz.string
        nodeFuzzer
        (shortListFuzzer uuidFuzzer)


nodeFuzzer : Fuzzer Node
nodeFuzzer =
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
