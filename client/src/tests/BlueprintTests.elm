module BlueprintTests exposing (..)

import Blueprint
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Model exposing (Model)
import Test exposing (..)


suite : Test
suite =
    describe "Blueprint module"
        [ let
            decodeTest description expectation =
                fuzz Fuzzers.blueprint description <|
                    \model ->
                        case encodeAndDecode model of
                            Ok decodedBlueprint ->
                                expectation model decodedBlueprint

                            Err message ->
                                Expect.fail <| "Decoding model failed: " ++ message

            encodeAndDecode =
                Blueprint.encode
                    >> D.decodeValue (Blueprint.decoder passedInSeed)

            passedInSeed =
                42
          in
          describe "encoding and decoding"
            [ decodeTest "gives same `core`"
                (\model decodedBlueprint ->
                    Expect.equal model.core decodedBlueprint.core
                )
            , decodeTest "gives same `clusters`"
                (\model decodedBlueprint ->
                    Expect.equal model.clusters decodedBlueprint.clusters
                )
            , decodeTest "gives same `clusterPrimaryGroups`"
                (\model decodedBlueprint ->
                    Expect.equal
                        model.clusterPrimaryGroups
                        decodedBlueprint.clusterPrimaryGroups
                )
            ]
        ]
