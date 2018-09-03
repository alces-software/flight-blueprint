module Blueprint
    exposing
        ( Blueprint
        , CoreDomain
        , coreName
        , decoder
        , encode
        , groupWithId
        , groupsFor
        )

import ClusterDomain exposing (ClusterDomain)
import EveryDict exposing (EveryDict)
import Json.Decode as D
import Json.Encode as E
import Maybe.Extra
import Node exposing (Node)
import PrimaryGroup exposing (PrimaryGroup, PrimaryGroupsDict)
import Set
import Uuid exposing (Uuid)


type alias Blueprint =
    { core : CoreDomain
    , clusters : List ClusterDomain
    , clusterPrimaryGroups : PrimaryGroupsDict
    }


type alias CoreDomain =
    { gateway : Node
    , infra : Maybe Node
    }


encode : Blueprint -> E.Value
encode blueprint =
    let
        clusterItems =
            List.map (encodeCluster blueprint) blueprint.clusters
    in
    E.object
        [ ( "core", encodeCore blueprint.core )
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


encodeCluster : Blueprint -> ClusterDomain -> E.Value
encodeCluster blueprint cluster =
    let
        computeGroupItems =
            groupsFor blueprint cluster
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


decoder : Int -> D.Decoder Blueprint
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
    D.map3 Blueprint
        (D.field "core" coreDecoder)
        -- Decode `clusters` field in two ways, once for the clusters
        -- themselves and once for the cluster primary groups. Might be
        -- marginally more efficient to decode the primary groups once and
        -- reuse these in both places, but that doesn't really matter and this
        -- way should be more flexible to future changes.
        (D.field "clusters" (D.list clusterDecoder))
        (D.field "clusters" clusterPrimaryGroupsDecoder)


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


groupsFor : Blueprint -> ClusterDomain -> List PrimaryGroup
groupsFor blueprint cluster =
    List.map (groupWithId blueprint) cluster.computeGroupIds
        |> Maybe.Extra.values


groupWithId : Blueprint -> Uuid -> Maybe PrimaryGroup
groupWithId blueprint groupId =
    EveryDict.get groupId blueprint.clusterPrimaryGroups
