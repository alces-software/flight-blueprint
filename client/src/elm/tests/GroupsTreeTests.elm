module GroupsTreeTests exposing (..)

import Canopy
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import GroupsTree exposing (NodeData(..))
import List.Nonempty as Nonempty
import Random.Pcg
import Test exposing (..)
import Uuid exposing (Uuid)


-- XXX Only handling groups for compute nodes atm - need to also handle for
-- login nodes eventually.
-- XXX add fuzz tests for more complex situations and invariants.


suite : Test
suite =
    describe "GroupsTree module"
        [ describe "init"
            [ test "creates new tree with `all` and `nodes` secondary groups" <|
                \_ ->
                    let
                        newTree =
                            GroupsTree.init

                        rootNodeData =
                            Canopy.value newTree
                    in
                    case rootNodeData of
                        PrimaryGroup _ ->
                            Expect.fail "root node should contain SecondaryGroups"

                        SecondaryGroups groups ->
                            Expect.equal
                                (Nonempty.toList groups)
                                [ "all", "nodes" ]
            ]
        , let
            groupUuid =
                mockPrimaryGroupUuid 1
          in
          describe "addPrimaryGroup and secondaryGroups"
            [ test "when no secondary groups passed, new group only has default secondary groups" <|
                \_ ->
                    let
                        newTree =
                            GroupsTree.init
                                -- XXX Add more things here to check works correctly?
                                -- XXX And/or: extract consistent tree to use for testing
                                |> GroupsTree.addPrimaryGroup groupUuid []

                        rootNodeChildren =
                            Canopy.children newTree
                                |> List.map Canopy.value
                    in
                    Expect.equal
                        (GroupsTree.secondaryGroups groupUuid newTree)
                        [ "all", "nodes" ]
            , test
                "when secondary groups passed, new group also has these secondary groups"
              <|
                \_ ->
                    let
                        newTree =
                            GroupsTree.init
                                |> GroupsTree.addPrimaryGroup
                                    groupUuid
                                    [ "newGroup1", "newGroup2" ]
                    in
                    -- XXX should secondaryGroups be returned in order? or
                    -- should sort and then match
                    Expect.equal
                        (GroupsTree.secondaryGroups groupUuid newTree)
                        [ "all", "newGroup1", "newGroup2", "nodes" ]

            -- , test "when new secondary group passed" <|
            --     \_ -> let
            --         newTree =
            --             GroupsTree.init
            --             |> GroupsTree.addPrimaryGroup groupUuid ["newGroup"]
            --             rootNodeChildren =
            --                 Canopy.children newTree
            --                 |> List.map Canopy.value
            --             -- newGroupChildren =
            --             --     Canopy.seek
            --         in
            --             Expect.equal
            , todo "XXX consider how to handle adding group with secondary groups in other situations"
            ]
        , describe "removePrimaryGroup"
            [ todo "removes the primary group from the tree"
            , todo "consider what to do with now orphaned secondary groups"
            ]
        , describe "XXX"
            [ todo "what querying methods do we need?"
            , todo "consider how to handle editing"
            ]
        ]


mockPrimaryGroupUuid : Int -> Uuid
mockPrimaryGroupUuid mockSeed =
    Random.Pcg.initialSeed mockSeed
        |> Random.Pcg.step Uuid.uuidGenerator
        |> Tuple.first
