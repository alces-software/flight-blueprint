module Model
    exposing
        ( CoreDomain
        , DisplayedForm(..)
        , Model
        , convertToYamlCmd
        , coreName
        , decoder
        , encode
        , groupWithId
        , init
        , primaryGroupsForCluster
        , secondaryGroupsForCluster
        , selectedSecondaryGroupMembers
        )

import ClusterDomain exposing (ClusterDomain)
import ComputeForm.Model exposing (ComputeForm)
import EveryDict exposing (EveryDict)
import EverySet exposing (EverySet)
import Json.Decode as D
import Json.Encode as E
import List.Extra
import Maybe.Extra
import Msg exposing (..)
import Node exposing (Node)
import Ports
import PrimaryGroup exposing (PrimaryGroup, PrimaryGroupsDict)
import Random.Pcg exposing (Seed)
import SecondaryGroupForm.Model exposing (SecondaryGroupForm)
import Set
import Uuid exposing (Uuid)


type alias Model =
    { core : CoreDomain
    , clusters : List ClusterDomain
    , clusterPrimaryGroups : PrimaryGroupsDict
    , exportedYaml : String
    , randomSeed : Seed
    , displayedForm : DisplayedForm
    }


type alias CoreDomain =
    { gateway : Node
    , infra : Maybe Node
    }


type DisplayedForm
    = NoForm
    | ComputeForm Int ComputeForm
    | SecondaryGroupForm Int SecondaryGroupForm


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
            , displayedForm = NoForm
            }
    in
    initialModel ! [ convertToYamlCmd initialModel ]


convertToYamlCmd : Model -> Cmd Msg
convertToYamlCmd =
    encode >> Ports.convertToYaml


encode : Model -> E.Value
encode model =
    let
        clusterItems =
            List.map (encodeCluster model) model.clusters
    in
    E.object
        [ ( "core", encodeCore model.core )
        , ( "clusters", E.list clusterItems )
        ]


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
        computeGroupItems =
            groupsFor model cluster
                |> List.map encodePrimaryGroup
    in
    E.object
        [ ( "name", E.string cluster.name )
        , ( "login", encodeNode cluster.login )
        , ( "compute", E.list computeGroupItems )
        ]


encodePrimaryGroup : PrimaryGroup -> E.Value
encodePrimaryGroup group =
    E.object
        [ ( "name", E.string group.name )
        , ( "secondaryGroups"
          , Set.toList group.secondaryGroups
                |> List.map E.string
                |> E.list
          )
        , ( "meta", encodePrimaryGroupMetaField group )
        , ( "nodes"
          , PrimaryGroup.nodes group
                |> List.map encodeNode
                |> E.list
          )
        ]


encodePrimaryGroupMetaField : PrimaryGroup -> E.Value
encodePrimaryGroupMetaField group =
    E.object
        [ ( "id", E.string <| Uuid.toString group.id )
        , ( "nodes", encodeNodesSpecification group.nodes )
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


decoder : Int -> D.Decoder Model
decoder randomSeed =
    let
        clusterPrimaryGroupsDecoder =
            D.list (D.field "compute" (D.list primaryGroupDecoder))
                |> D.map
                    (List.concat
                        >> List.map (\pg -> ( pg.id, pg ))
                        >> EveryDict.fromList
                    )
    in
    D.map5
        (\initModel core clusters primaryGroups seed ->
            { initModel
                | core = core
                , clusters = clusters
                , clusterPrimaryGroups = primaryGroups
                , randomSeed = seed
            }
        )
        -- XXX Remove use of `init` once decoding full model.
        (init 5 |> Tuple.first |> D.succeed)
        (D.field "core" coreDecoder)
        -- Decode `clusters` field in two ways, once for the clusters
        -- themselves and once for the cluster primary groups. Might be
        -- marginally more efficient to decode the primary groups once and
        -- reuse these in both places, but that doesn't really matter and this
        -- way should be more flexible to future changes.
        (D.field "clusters" (D.list clusterDecoder))
        (D.field "clusters" clusterPrimaryGroupsDecoder)
        (D.succeed <| Random.Pcg.initialSeed randomSeed)


coreDecoder : D.Decoder CoreDomain
coreDecoder =
    D.map2 CoreDomain
        (D.field "gateway" nodeDecoder)
        (D.maybe <| D.field "infra" nodeDecoder)


clusterDecoder : D.Decoder ClusterDomain
clusterDecoder =
    D.map3 ClusterDomain
        (D.field "name" D.string)
        (D.field "login" nodeDecoder)
        (D.field "compute"
            (D.list <| D.map .id primaryGroupDecoder)
        )


primaryGroupDecoder : D.Decoder PrimaryGroup
primaryGroupDecoder =
    D.map4 PrimaryGroup
        (D.at [ "meta", "id" ] uuidDecoder)
        (D.field "name" D.string)
        (D.at [ "meta", "nodes" ] nodesSpecificationDecoder)
        (D.field "secondaryGroups"
            (D.list D.string |> D.map Set.fromList)
        )


uuidDecoder : D.Decoder Uuid
uuidDecoder =
    D.string
        |> D.andThen
            (\uuidString ->
                case Uuid.fromString uuidString of
                    Just uuid ->
                        D.succeed uuid

                    Nothing ->
                        D.fail "Doesn't look like a valid UUID"
            )


nodesSpecificationDecoder : D.Decoder PrimaryGroup.NodesSpecification
nodesSpecificationDecoder =
    D.map4 PrimaryGroup.NodesSpecification
        (D.field "base" D.string)
        (D.field "startIndex" D.int)
        (D.field "size" D.int)
        (D.field "indexPadding" D.int)


nodeDecoder : D.Decoder Node
nodeDecoder =
    D.map Node D.string


coreName : String
coreName =
    "core"


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
            groupsFor model cluster

        Nothing ->
            []


secondaryGroupsForCluster : Model -> Int -> List String
secondaryGroupsForCluster model clusterIndex =
    case clusterAtIndex model clusterIndex of
        Just cluster ->
            groupsFor model cluster
                |> List.map .secondaryGroups
                |> List.foldl Set.union Set.empty
                |> Set.toList

        Nothing ->
            []


clusterAtIndex : Model -> Int -> Maybe ClusterDomain
clusterAtIndex model index =
    List.Extra.getAt index model.clusters


groupsFor : Model -> ClusterDomain -> List PrimaryGroup
groupsFor model cluster =
    List.map (groupWithId model) cluster.computeGroupIds
        |> Maybe.Extra.values


groupWithId : Model -> Uuid -> Maybe PrimaryGroup
groupWithId model groupId =
    EveryDict.get groupId model.clusterPrimaryGroups
