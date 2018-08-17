module Model
    exposing
        ( CoreDomain
        , Model
        , convertToYamlCmd
        , coreName
        , init
        )

import ClusterDomain exposing (ClusterDomain)
import ComputeForm.Model exposing (ComputeForm, ComputeModal)
import EveryDict exposing (EveryDict)
import Json.Encode as E
import Maybe.Extra
import Msg exposing (..)
import Node exposing (Node)
import Ports
import PrimaryGroup exposing (..)
import Random.Pcg exposing (Seed)
import SecondaryGroupForm.Model exposing (SecondaryGroupForm)
import Set
import Uuid exposing (Uuid)


type alias Model =
    { core : CoreDomain
    , clusters : List ClusterDomain
    , clusterPrimaryGroups : EveryDict Uuid PrimaryGroup
    , exportedYaml : String
    , randomSeed : Seed
    , computeModal : ComputeModal
    , computeForm : ComputeForm
    , secondaryGroupForm : SecondaryGroupForm
    }


type alias CoreDomain =
    { gateway : Node
    , infra : Maybe Node
    }


init : Int -> ( Model, Cmd Msg )
init initialRandomSeed =
    let
        initialModel =
            { core =
                { gateway =
                    { name = "gateway" }
                , infra = Nothing
                }
            , clusters = []
            , clusterPrimaryGroups = EveryDict.empty
            , exportedYaml = ""
            , randomSeed = Random.Pcg.initialSeed initialRandomSeed

            -- XXX Collapse two parts of ComputeForm state together as with
            -- SecondaryGroupForm? Although current structure does allow filled
            -- in fields to be retained if close and reopen form elsewhere (or
            -- in same cluster), which is useful - consider if could retain
            -- this in different way?
            , computeModal = ComputeForm.Model.Hidden
            , computeForm = ComputeForm.Model.init
            , secondaryGroupForm = SecondaryGroupForm.Model.Hidden
            }
    in
    initialModel ! [ convertToYamlCmd initialModel ]


convertToYamlCmd : Model -> Cmd Msg
convertToYamlCmd =
    encode >> Ports.convertToYaml


encode : Model -> E.Value
encode model =
    let
        coreField =
            ( "core", encodeCore model.core )

        clusterFields =
            List.map
                (\c -> ( c.name, encodeCluster model c ))
                model.clusters
    in
    E.object (coreField :: clusterFields)


encodeCore : CoreDomain -> E.Value
encodeCore core =
    let
        coreFields =
            Maybe.Extra.values
                [ Just <| ( "gateway", encodeNode core.gateway )
                , Maybe.map
                    (\i -> ( "infra", encodeNode i ))
                    core.infra
                ]
    in
    E.object coreFields


encodeCluster : Model -> ClusterDomain -> E.Value
encodeCluster model cluster =
    let
        loginField =
            ( "login", encodeNode cluster.login )

        computeField =
            ( "compute", E.object computeGroupFields )

        computeGroupFields =
            List.map
                (\g -> ( g.name, encodePrimaryGroup g ))
                groups

        groups =
            cluster.computeGroupIds
                |> List.map (flip EveryDict.get model.clusterPrimaryGroups)
                |> Maybe.Extra.values
    in
    E.object
        [ loginField
        , computeField
        ]


encodePrimaryGroup : PrimaryGroup -> E.Value
encodePrimaryGroup group =
    E.object
        [ ( "secondaryGroups"
          , Set.toList group.secondaryGroups
                |> List.map E.string
                |> E.list
          )
        , ( "meta", encodeNodesSpecification group.nodes )
        , ( "nodes"
          , PrimaryGroup.nodes group
                |> List.map encodeNode
                |> E.list
          )
        ]


encodeNodesSpecification : PrimaryGroup.NodesSpecification -> E.Value
encodeNodesSpecification nodesSpec =
    E.object
        [ ( "base", E.string nodesSpec.base )
        , ( "size", E.int nodesSpec.size )
        , ( "startIndex", E.int nodesSpec.startIndex )
        , ( "indexPadding", E.int nodesSpec.indexPadding )

        -- XXX Not handling overrides yet.
        , ( "overrides", E.object [] )
        ]


encodeNode : Node -> E.Value
encodeNode node =
    E.string node.name


coreName : String
coreName =
    "core"
