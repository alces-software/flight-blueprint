module ModelTests exposing (..)

import EveryDict
import EverySet
import Expect exposing (Expectation)
import Fixtures exposing (clusterFixture, groupFixture, initialModelFixture)
import Fuzz exposing (Fuzzer, int, list, string)
import Json.Decode as D
import Model
import Set
import Test exposing (..)


suite : Test
suite =
    describe "Model module"
        [ let
            model =
                { initialModelFixture
                    | clusters = [ cluster ]
                    , clusterPrimaryGroups =
                        EveryDict.fromList
                            [ ( primaryGroup.id, primaryGroup ) ]
                }

            cluster =
                { clusterFixture | computeGroupIds = [ primaryGroup.id ] }

            primaryGroup =
                groupFixture
          in
          describe "primaryGroupsForCluster"
            [ test "returns the primary groups for the cluster" <|
                \_ ->
                    Expect.equal
                        (Model.primaryGroupsForCluster model 0)
                        [ primaryGroup ]
            , fuzz Fixtures.fuzzGroup "never includes group not associated with cluster" <|
                \group ->
                    let
                        modelWithGroup =
                            { model
                                | clusterPrimaryGroups =
                                    EveryDict.insert
                                        group.id
                                        group
                                        model.clusterPrimaryGroups
                            }
                    in
                    Expect.equal
                        (Model.primaryGroupsForCluster modelWithGroup 0)
                        [ primaryGroup ]
            ]
        , describe "secondaryGroupsForCluster"
            [ fuzz2
                Fixtures.fuzzGroup
                Fixtures.fuzzGroup
                "returns all secondary groups for the cluster primary groups"
              <|
                \group1 group2 ->
                    let
                        model =
                            { initialModelFixture
                                | clusters = [ cluster ]
                                , clusterPrimaryGroups =
                                    EveryDict.fromList
                                        [ ( group1.id, group1 )
                                        , ( group2.id, group2 )
                                        ]
                            }

                        cluster =
                            { clusterFixture
                                | computeGroupIds = [ group1.id, group2.id ]
                            }
                    in
                    Expect.equal
                        (List.sort <| Model.secondaryGroupsForCluster model 0)
                        (List.sort <|
                            Set.toList <|
                                Set.union
                                    group1.secondaryGroups
                                    group2.secondaryGroups
                        )
            ]
        , let
            modelDecodeTest description expectation =
                fuzz Fixtures.fuzzModel description <|
                    \model ->
                        case encodeAndDecode model of
                            Ok decodedModel ->
                                expectation model decodedModel

                            Err message ->
                                Expect.fail <| "Decoding model failed: " ++ message

            encodeAndDecode =
                Model.encode >> D.decodeValue Model.decoder
          in
          describe "encoding and decoding"
            [ modelDecodeTest "gives same `core`"
                (\model decodedModel ->
                    Expect.equal model.core decodedModel.core
                )
            ]
        ]
