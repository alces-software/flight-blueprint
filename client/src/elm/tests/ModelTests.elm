module ModelTests exposing (..)

import EveryDict
import Expect exposing (Expectation)
import Fixtures exposing (clusterFixture, groupFixture)
import Fuzz exposing (Fuzzer, int, list, string)
import Model
import Test exposing (..)


suite : Test
suite =
    describe "Model module"
        [ let
            model =
                { initialModel
                    | clusters = [ cluster ]
                    , clusterPrimaryGroups =
                        EveryDict.fromList
                            [ ( primaryGroup.id, primaryGroup ) ]
                }

            initialModel =
                Model.init 5 |> Tuple.first

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
        ]
