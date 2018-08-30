module Fuzzers exposing (group, model)

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


model : Fuzzer Model
model =
    let
        groupsForClustersFuzzer clusters =
            List.concatMap .computeGroupIds clusters
                |> List.map
                    (\groupId ->
                        Fuzz.map
                            (\group -> { group | id = groupId })
                            group
                    )
                |> Fuzz.Extra.sequence

        modelWithClustersAndGroupsFuzzer clusters groups =
            Fuzz.map Model
                core
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
                |> Fuzz.andMap seed
                -- XXX Hard-coding this to NoForm is not very random but is easy to do,
                -- and (for now at least) this shouldn't effect anything where this
                -- fuzzer is being used. For robustness would be good to make this
                -- actually random though.
                |> Fuzz.andMap (Fuzz.constant Model.NoForm)
    in
    shortList cluster
        |> Fuzz.andThen
            (\clusters ->
                groupsForClustersFuzzer clusters
                    |> Fuzz.andThen
                        (modelWithClustersAndGroupsFuzzer clusters)
            )


core : Fuzzer CoreDomain
core =
    Fuzz.map2 CoreDomain node (Fuzz.maybe node)


seed : Fuzzer Random.Pcg.Seed
seed =
    Fuzz.map Random.Pcg.initialSeed Fuzz.int


uuid : Fuzzer Uuid
uuid =
    Fuzz.custom Uuid.uuidGenerator Shrink.noShrink


group : Fuzzer PrimaryGroup
group =
    Fuzz.map4
        PrimaryGroup
        uuid
        Fuzz.string
        nodesSpecification
        (shortList Fuzz.string |> Fuzz.map Set.fromList)


nodesSpecification : Fuzzer PrimaryGroup.NodesSpecification
nodesSpecification =
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


cluster : Fuzzer ClusterDomain
cluster =
    Fuzz.map3 ClusterDomain
        Fuzz.string
        node
        (shortList uuid)


node : Fuzzer Node
node =
    Fuzz.map Node Fuzz.string


{-| Fuzz a list of `a`s of length 4 or less.

This is useful when the fuzzed list may be used for something somewhat
computationally expensive, and having a short list is unlikely to effect
whether tests will pass; using this in these situations should at least
significantly speed up running tests, and can prevent JavaScript running out of
memory when running tests (which previously could happen in some cases
where we used `Fuzz.list` instead).

-}
shortList : Fuzzer a -> Fuzzer (List a)
shortList itemFuzzer =
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
