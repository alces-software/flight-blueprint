module Forms.ValidationsTests exposing (..)

import Expect exposing (Expectation)
import Form.Error exposing (..)
import Form.Test exposing (..)
import Form.Test.ValidationExpectation exposing (ValidationExpectation(..))
import Form.Validate exposing (..)
import Forms.Validations as Validations
import Test exposing (..)


suite : Test
suite =
    describe "Validations module"
        [ Form.Test.describeValidation "validateIdentifier"
            Validations.validateIdentifier
            [ ( "myGroup3", Valid )
            , ( "group#$^%"
              , Invalid <| CustomError Validations.InvalidIdentifierCharacters
              )
            , ( "foo bar"
              , Invalid <| CustomError Validations.InvalidIdentifierCharacters
              )
            , ( "4group"
              , Invalid <| CustomError Validations.InvalidIdentifierFirstCharacter
              )
            , ( "4group&*"
              , Invalid <| CustomError Validations.InvalidIdentifierCharacters
              )
            ]

        -- XXX It would be nice to fuzz test these, but this seems
        -- non-trivial/non-obvious with the current elm-test and elm-form
        -- testing APIs
        , Form.Test.describeValidation "validateInteger with no bounds"
            (Validations.validateInteger { min = Nothing, max = Nothing })
            [ ( "10", Valid )
            , ( "0", Valid )
            , ( "-10", Valid )
            ]
        , Form.Test.describeValidation "validateInteger with just upper bound"
            (Validations.validateInteger { min = Nothing, max = Just 5 })
            [ ( "6", Invalid <| GreaterIntThan 5 )
            , ( "5", Valid )
            , ( "4", Valid )
            ]
        , Form.Test.describeValidation "validateInteger with just lower bound"
            (Validations.validateInteger { min = Just 5, max = Nothing })
            [ ( "6", Valid )
            , ( "5", Valid )
            , ( "4", Invalid <| SmallerIntThan 5 )
            ]
        , Form.Test.describeValidation "validateInteger with both bounds"
            (Validations.validateInteger { min = Just 5, max = Just 6 })
            [ ( "7", Invalid <| GreaterIntThan 6 )
            , ( "6", Valid )
            , ( "5", Valid )
            , ( "4", Invalid <| SmallerIntThan 5 )
            ]
        ]
