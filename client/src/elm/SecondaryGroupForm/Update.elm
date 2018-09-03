module SecondaryGroupForm.Update exposing (handleSecondaryGroupCreate)

import Blueprint
import EveryDict exposing (EveryDict)
import EverySet exposing (EverySet)
import Maybe.Extra
import Model exposing (Model)
import PrimaryGroup exposing (PrimaryGroup, PrimaryGroupsDict)
import Uuid exposing (Uuid)


handleSecondaryGroupCreate : Model -> Int -> String -> EverySet Uuid -> Model
handleSecondaryGroupCreate model clusterIndex secondaryGroupName memberGroupIds =
    let
        memberGroups : List PrimaryGroup
        memberGroups =
            EverySet.map (Blueprint.groupWithId currentBlueprint) memberGroupIds
                |> EverySet.toList
                |> Maybe.Extra.values

        newGroups : PrimaryGroupsDict
        newGroups =
            List.foldl
                updateGroupWithSecondaryGroup
                currentBlueprint.clusterPrimaryGroups
                memberGroups

        updateGroupWithSecondaryGroup : PrimaryGroup -> PrimaryGroupsDict -> PrimaryGroupsDict
        updateGroupWithSecondaryGroup group groups =
            EveryDict.insert
                group.id
                (PrimaryGroup.addSecondaryGroup secondaryGroupName group)
                groups

        { currentBlueprint } =
            model
    in
    { model
        | currentBlueprint =
            { currentBlueprint
                | clusterPrimaryGroups = newGroups
            }
        , displayedForm = Model.NoForm
    }
