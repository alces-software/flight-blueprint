module GroupsTree
    exposing
        ( GroupsTree
        , NodeData(..)
        , addPrimaryGroup
        , init
        , secondaryGroups
        )

import Canopy exposing (..)
import List.Nonempty as Nonempty exposing ((:::), Nonempty)
import PrimaryGroup exposing (PrimaryGroup)
import Uuid exposing (Uuid)


type alias GroupsTree =
    Node NodeData


type
    -- XXX Can this be privatised?
    NodeData
    -- XXX Handle login nodes here?
    = PrimaryGroup Uuid
      -- XXX Is Nonempty list best choice - order doesn't actually matter
      -- (Nonempty Set possible? Can't see existing package after quick look.
      -- Or could just use Set); also "all" should always be root, how to
      -- handle?
    | SecondaryGroups (Nonempty String)


init : GroupsTree
init =
    let
        initialGroups =
            "all" ::: Nonempty.fromElement "nodes"
    in
    leaf <| SecondaryGroups initialGroups


addPrimaryGroup : Uuid -> List String -> GroupsTree -> GroupsTree
addPrimaryGroup groupId secondaryGroups tree =
    let
        maybeNodesGroupNode =
            seek
                (\node ->
                    case node of
                        PrimaryGroup _ ->
                            False

                        SecondaryGroups groups ->
                            Nonempty.member "nodes" groups
                )
                tree
                -- Should be the only node found, but `seek` returns list of
                -- matching nodes (and should always be found, but can't
                -- guarantee that).
                |> List.head

        -- parentNode = case Nonempty.fromList secondaryGroups of
        --     Just groups ->
    in
    case maybeNodesGroupNode of
        Just nodesGroupNode ->
            -- Append new group to the 'nodes' group node.
            append
                (value nodesGroupNode)
                (PrimaryGroup groupId)
                tree

        Nothing ->
            -- Couldn't find 'nodes' group node for some reason; just return
            -- the tree unchanged.
            tree


secondaryGroups : Uuid -> GroupsTree -> List String
secondaryGroups groupId tree =
    let
        unpackSecondaryGroups nodeData =
            case nodeData of
                SecondaryGroups groups ->
                    Nonempty.toList groups

                PrimaryGroup _ ->
                    []
    in
    path (PrimaryGroup groupId) tree
        |> List.map (value >> unpackSecondaryGroups)
        |> List.concat



-- case groupParentData of
--     Just (SecondaryGroups groups) ->
--         Nonempty.toList groups
--     _ ->
--         -- PrimaryGroup should have a parent, which should be
--         -- SecondaryGroups, but if doesn't for some reason just return
--         -- empty list.
--         []
-- allParents : a -> Node a -> List a
-- allParents nodeData tree =
--     case
--     parent
--     case nodeData of
--         PrimaryGroup _ ->
--             parent
--         SecondaryGroups groups ->
--             groups
