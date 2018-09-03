module ModelTests exposing (..)

import EveryDict
import Expect exposing (Expectation)
import Fixtures exposing (clusterFixture, groupFixture, initialModelFixture)
import Fuzzers
import Json.Decode as D
import Model
import Random.Pcg
import Set
import Test exposing (..)


suite : Test
suite =
    describe "Model module"
        [ let
            model =
                { initialModelFixture
                    | currentBlueprint =
                        { currentBlueprint
                            | clusters = [ cluster ]
                            , clusterPrimaryGroups =
                                EveryDict.fromList
                                    [ ( primaryGroup.id, primaryGroup ) ]
                        }
                }

            { currentBlueprint } =
                initialModelFixture

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
            , fuzz Fuzzers.group "never includes group not associated with cluster" <|
                \group ->
                    let
                        modelWithGroup =
                            { model
                                | currentBlueprint =
                                    { currentBlueprint
                                        | clusterPrimaryGroups =
                                            EveryDict.insert
                                                group.id
                                                group
                                                currentBlueprint.clusterPrimaryGroups
                                    }
                            }

                        { currentBlueprint } =
                            model
                    in
                    Expect.equal
                        (Model.primaryGroupsForCluster modelWithGroup 0)
                        [ primaryGroup ]
            ]
        , describe "secondaryGroupsForCluster"
            [ fuzz2
                Fuzzers.group
                Fuzzers.group
                "returns all secondary groups for the cluster primary groups"
              <|
                \group1 group2 ->
                    let
                        model =
                            { initialModelFixture
                                | currentBlueprint =
                                    { currentBlueprint
                                        | clusters = [ cluster ]
                                        , clusterPrimaryGroups =
                                            EveryDict.fromList
                                                [ ( group1.id, group1 )
                                                , ( group2.id, group2 )
                                                ]
                                    }
                            }

                        { currentBlueprint } =
                            initialModelFixture

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
        ]
