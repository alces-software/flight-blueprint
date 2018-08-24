module Forms.Validations
    exposing
        ( CustomError(..)
        , IntBounds
        , validateGroupName
        , validateIdentifier
        , validateInteger
        )

import Form.Validate exposing (..)
import PrimaryGroup exposing (PrimaryGroup)
import Regex


type CustomError
    = InvalidIdentifierCharacters
    | InvalidIdentifierFirstCharacter
    | ExistingPrimaryGroup
    | ExistingSecondaryGroup


validateGroupName : List PrimaryGroup -> List String -> Validation CustomError String
validateGroupName existingPrimaryGroups existingSecondaryGroupNames =
    let
        existingPrimaryGroupNames =
            List.map .name existingPrimaryGroups
    in
    customValidation validateIdentifier
        (\s ->
            if List.member s existingPrimaryGroupNames then
                Err <| customError ExistingPrimaryGroup
            else if List.member s existingSecondaryGroupNames then
                Err <| customError ExistingSecondaryGroup
            else
                Ok s
        )


validateIdentifier : Validation CustomError String
validateIdentifier =
    string
        |> andThen
            (format (Regex.regex "^[a-zA-Z0-9]+$")
                >> withCustomError InvalidIdentifierCharacters
            )
        |> andThen
            (format (Regex.regex "^[a-zA-Z]")
                >> withCustomError InvalidIdentifierFirstCharacter
            )


{-| Bounds for an integer field (inclusive).
-}
type alias IntBounds =
    { min : Maybe Int
    , max : Maybe Int
    }


validateInteger : IntBounds -> Validation e Int
validateInteger bounds =
    int
        |> andThen
            (case bounds.max of
                Just max ->
                    maxInt max

                Nothing ->
                    succeed
            )
        |> andThen
            (case bounds.min of
                Just min ->
                    minInt min

                Nothing ->
                    succeed
            )
