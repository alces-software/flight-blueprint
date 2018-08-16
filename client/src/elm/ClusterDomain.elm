module ClusterDomain exposing (ClusterDomain, nextCluster)

import Node exposing (Node)
import Uuid exposing (Uuid)


type alias ClusterDomain =
    { name : String
    , login : Node
    , computeGroupIds : List Uuid
    }


nextCluster : List ClusterDomain -> ClusterDomain
nextCluster currentClusters =
    { name = nextName currentClusters
    , login =
        { name = "login1" }
    , computeGroupIds = []
    }


nextName : List ClusterDomain -> String
nextName clusters =
    "cluster" ++ nextIndex clusters


nextIndex : List a -> String
nextIndex items =
    List.length items
        + 1
        |> toString
