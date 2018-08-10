module MainTests exposing (..)

import Expect exposing (Expectation)
import Form.Value as Value
import Fuzz exposing (Fuzzer, int, list, string)
import Main
import Node exposing (Node)
import Test exposing (..)


suite : Test
suite =
    describe "Main module"
        [ let
            testUpdateName { originalName, originalBase, newName, expectedNewBase } =
                let
                    newNameValue =
                        Value.filled newName

                    values =
                        { initialValues
                            | name = Value.filled originalName
                            , base = Value.filled originalBase
                        }

                    updatedValues =
                        Main.updateName newNameValue values
                in
                \_ ->
                    Expect.equal
                        ( updatedValues.name, updatedValues.base )
                        ( newNameValue, Value.filled expectedNewBase )
          in
          -- XXX Extract `Main.updateName` somewhere better.
          describe "updateName"
            [ test "it sets name and base to new name when current name and base the same" <|
                testUpdateName
                    { originalName = "gpu"
                    , originalBase = "gpu"
                    , newName = "newGpu"
                    , expectedNewBase = "newGpu"
                    }
            , test "it sets base to singular of new name when current name is base with additional `s`" <|
                testUpdateName
                    { originalName = "nodes"
                    , originalBase = "node"
                    , newName = "newNodes"
                    , expectedNewBase = "newNode"
                    }
            , test "it does not change base when is not singular or plural of current name" <|
                testUpdateName
                    { originalName = "nodes"
                    , originalBase = "somethingElse"
                    , newName = "newNodes"
                    , expectedNewBase = "somethingElse"
                    }
            ]
        ]


initialValues =
    Main.initialComputeFormValues
