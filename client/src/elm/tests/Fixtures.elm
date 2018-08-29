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
import Lazy.List exposing ((:::))
import Model exposing (CoreDomain, Model)
import Node exposing (Node)
import PrimaryGroup exposing (PrimaryGroup)
import Random.Pcg
import Set
import Shrink exposing (Shrinker)
import Uuid exposing (Uuid)


initialModelFixture : Model
initialModelFixture =
    Model.init 5 |> Tuple.first


fuzzModel : Fuzzer Model
fuzzModel =
    let
        fuzzModelFromGroupIds groupIds =
            Fuzz.map Model
                fuzzCore
                |> Fuzz.andMap
                    (Fuzz.list fuzzCluster
                        |> Fuzz.map
                            (List.map
                                (\c ->
                                    -- c
                                    { c | computeGroupIds = groupIds }
                                )
                            )
                    )
                |> Fuzz.andMap
                    (Fuzz.constant EveryDict.empty)
                -- (List.map
                --     (\groupId ->
                --         Fuzz.map (\g -> { g | id = groupId })
                --             fuzzGroup
                --     )
                --     groupIds
                --     |> Fuzz.Extra.sequence
                --     |> Fuzz.map (List.map (\g -> ( g.id, g )))
                --     |> Fuzz.map EveryDict.fromList
                -- )
                |> Fuzz.andMap Fuzz.string
                |> Fuzz.andMap fuzzSeed
                -- XXX Hard-coding this to NoForm is not very random but is easy to do,
                -- and (for now at least) this shouldn't effect anything where this
                -- fuzzer is being used. For robustness would be good to make this
                -- actually random though.
                |> Fuzz.andMap (Fuzz.constant Model.NoForm)
    in
    Fuzz.list fuzzUuid
        |> Fuzz.andThen fuzzModelFromGroupIds


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
    let
        shrink uuid =
            if uuid == baseUuid then
                Lazy.List.empty
            else
                baseUuid ::: Lazy.List.empty

        baseUuid =
            uuidFromSeed 1
    in
    Fuzz.custom Uuid.uuidGenerator shrink


uuidFromSeed : Int -> Uuid
uuidFromSeed seed =
    let
        ( uuid, _ ) =
            Random.Pcg.initialSeed seed
                |> Random.Pcg.step Uuid.uuidGenerator
    in
    uuid


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
