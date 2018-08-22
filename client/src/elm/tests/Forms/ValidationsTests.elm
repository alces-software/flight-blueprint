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
        ]
