module Model
    exposing
        ( DisplayedForm(..)
        , Model
        , convertToYamlCmd
        , init
        , primaryGroupsForCluster
        , secondaryGroupsForCluster
        , selectedSecondaryGroupMembers
        )

import Blueprint exposing (Blueprint)
import ClusterDomain exposing (ClusterDomain)
import ComputeForm.Model exposing (ComputeForm)
import EveryDict exposing (EveryDict)
import EverySet exposing (EverySet)
import List.Extra
import Msg exposing (..)
import Node exposing (Node)
import Ports
import PrimaryGroup exposing (PrimaryGroup, PrimaryGroupsDict)
import Random.Pcg exposing (Seed)
import SecondaryGroupForm.Model exposing (SecondaryGroupForm)
import Set
import Uuid exposing (Uuid)


type alias Model =
    { currentBlueprint : Blueprint
    , exportedYaml : String
    , randomSeed : Seed
    , displayedForm : DisplayedForm
    }


type DisplayedForm
    = NoForm
    | ComputeForm Int ComputeForm
    | SecondaryGroupForm Int SecondaryGroupForm


init : Int -> ( Model, Cmd Msg )
init initialRandomSeed =
    let
        initialModel =
            { currentBlueprint =
                { core =
                    { gateway =
                        { name = "gateway" }
                    , infra = Nothing
                    }
                , clusters = []
                , clusterPrimaryGroups = EveryDict.empty
                }
            , exportedYaml = ""
            , randomSeed = Random.Pcg.initialSeed initialRandomSeed
            , displayedForm = NoForm
            }
    in
    initialModel ! [ convertToYamlCmd initialModel ]


convertToYamlCmd : Model -> Cmd Msg
convertToYamlCmd =
    .currentBlueprint
        >> Blueprint.encode
        >> Ports.convertToYaml


{-|

    Gives currently selected groups if in group selection stage of secondary
    groups form, otherwise nothing.

-}
selectedSecondaryGroupMembers : Model -> Maybe (EverySet Uuid)
selectedSecondaryGroupMembers model =
    case model.displayedForm of
        SecondaryGroupForm _ form ->
            case form of
                SecondaryGroupForm.Model.ShowingNameForm _ ->
                    Nothing

                SecondaryGroupForm.Model.SelectingGroups _ groupIds ->
                    Just groupIds

        _ ->
            Nothing


primaryGroupsForCluster : Model -> Int -> List PrimaryGroup
primaryGroupsForCluster model clusterIndex =
    case clusterAtIndex model clusterIndex of
        Just cluster ->
            Blueprint.groupsFor model.currentBlueprint cluster

        Nothing ->
            []


secondaryGroupsForCluster : Model -> Int -> List String
secondaryGroupsForCluster model clusterIndex =
    case clusterAtIndex model clusterIndex of
        Just cluster ->
            Blueprint.groupsFor model.currentBlueprint cluster
                |> List.map .secondaryGroups
                |> List.foldl Set.union Set.empty
                |> Set.toList

        Nothing ->
            []


clusterAtIndex : Model -> Int -> Maybe ClusterDomain
clusterAtIndex model index =
    List.Extra.getAt index model.currentBlueprint.clusters
