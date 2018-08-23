module SecondaryGroupForm.Update exposing (handleSecondaryGroupCreate)

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
            EverySet.map (Model.groupWithId model) memberGroupIds
                |> EverySet.toList
                |> Maybe.Extra.values

        newGroups : PrimaryGroupsDict
        newGroups =
            List.foldl
                updateGroupWithSecondaryGroup
                model.clusterPrimaryGroups
                memberGroups

        updateGroupWithSecondaryGroup : PrimaryGroup -> PrimaryGroupsDict -> PrimaryGroupsDict
        updateGroupWithSecondaryGroup group groups =
            EveryDict.insert
                group.id
                (PrimaryGroup.addSecondaryGroup secondaryGroupName group)
                groups
    in
    { model
        | clusterPrimaryGroups = newGroups
        , displayedForm = Model.NoForm
    }
