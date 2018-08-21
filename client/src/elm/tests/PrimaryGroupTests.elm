module PrimaryGroupTests exposing (..)

import Expect exposing (Expectation)
import Fixtures exposing (groupFixture, nodesFixture)
import Fuzz exposing (Fuzzer, int, list, string)
import Node exposing (Node)
import PrimaryGroup exposing (PrimaryGroup)
import Set
import Test exposing (..)


suite : Test
suite =
    describe "PrimaryGroup module"
        [ describe "nodes"
            [ test "generates list of Nodes from PrimaryGroup.nodes" <|
                let
                    group =
                        { groupFixture
                            | nodes =
                                { nodesFixture
                                    | startIndex = 4
                                    , size = 3
                                    , indexPadding = 2
                                }
                        }
                in
                \_ ->
                    Expect.equal (PrimaryGroup.nodes group)
                        [ Node "node04"
                        , Node "node05"
                        , Node "node06"
                        ]
            ]
        ]
