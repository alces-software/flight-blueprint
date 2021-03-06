module ComputeForm.Update
    exposing
        ( handleSuccessfulComputeFormSubmit
        , handleUpdatingComputeFormName
        )

import ComputeForm.Model exposing (ComputeForm)
import EveryDict exposing (EveryDict)
import Form exposing (Form)
import Form.Field as Field exposing (Field)
import Forms
import List.Extra
import Model exposing (Model)
import PrimaryGroup exposing (PrimaryGroup)
import Uuid exposing (Uuid)


-- XXX Should this just contain top-level `update` function for handling
-- `ComputeFormMsg`s?


handleSuccessfulComputeFormSubmit : Model -> Int -> PrimaryGroup -> Model
handleSuccessfulComputeFormSubmit model clusterIndex newGroup =
    let
        currentCluster =
            List.Extra.getAt clusterIndex currentBlueprint.clusters

        newClusters =
            List.Extra.updateAt
                clusterIndex
                addGroupId
                currentBlueprint.clusters

        addGroupId cluster =
            { cluster
                | computeGroupIds =
                    newGroup.id :: cluster.computeGroupIds
            }

        newGroups =
            EveryDict.insert
                newGroup.id
                newGroup
                currentBlueprint.clusterPrimaryGroups

        { currentBlueprint } =
            model
    in
    { model
        | currentBlueprint =
            { currentBlueprint
                | clusters = newClusters
                , clusterPrimaryGroups = newGroups
            }
        , displayedForm = Model.NoForm
    }


handleUpdatingComputeFormName :
    Model
    -> Int
    -> Uuid
    -> String
    -> ComputeForm
    -> ComputeForm
handleUpdatingComputeFormName model clusterIndex newGroupId newName computeForm =
    let
        ( currentName, currentBase ) =
            ( value "name"
            , value "nodes.base"
            )

        value =
            flip Form.getFieldAsString computeForm
                >> .value
                >> Maybe.withDefault ""

        newBase =
            if shouldKeepCurrentBase then
                currentBase
            else
                singularized newName

        shouldKeepCurrentBase =
            not <| currentBase == singularized currentName

        singularized word =
            if isPlural word then
                String.dropRight 1 word
            else
                word

        isPlural =
            String.endsWith "s"

        validation =
            Forms.computeFormValidation model clusterIndex newGroupId
    in
    Form.update validation
        (Form.Input "nodes.base" Form.Text (Field.String newBase))
        computeForm
