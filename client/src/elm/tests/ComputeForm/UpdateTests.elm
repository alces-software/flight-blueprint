module ComputeForm.UpdateTests exposing (..)

import ComputeForm.Model
import ComputeForm.Update
import Expect exposing (Expectation)
import Form
import Form.Field as Field
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)


suite : Test
suite =
    describe "ComputeForm.Update module"
        [ let
            testUpdateName { originalName, originalBase, newName, expectedNewBase } =
                let
                    initialComputeForm =
                        Form.initial
                            [ ( "name", Field.string originalName )
                            , ( "nodes"
                              , Field.group
                                    [ ( "base", Field.string originalBase ) ]
                              )
                            ]
                            ComputeForm.Model.validation

                    newComputeForm =
                        ComputeForm.Update.handleUpdatingComputeFormName newName initialComputeForm

                    newBase =
                        newValue "nodes.base"

                    newValue =
                        flip Form.getFieldAsString newComputeForm
                            >> .value
                            >> Maybe.withDefault ""
                in
                \_ ->
                    Expect.equal newBase expectedNewBase
          in
          -- XXX Maybe testing too many implementation details here/above, and
          -- should test at higher level - in `update`?
          describe "handleUpdatingComputeFormName"
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
