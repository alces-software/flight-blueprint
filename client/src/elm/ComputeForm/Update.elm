module ComputeForm.Update
    exposing
        ( handleSuccessfulComputeFormSubmit
        , handleUpdatingComputeFormName
        )

import ComputeForm.Model exposing (ComputeForm)
import EveryDict exposing (EveryDict)
import Form exposing (Form)
import Form.Field as Field exposing (Field)
import List.Extra
import Model exposing (Model)
import PrimaryGroup exposing (PrimaryGroup)
import Random.Pcg exposing (Seed)
import Uuid exposing (Uuid)


-- XXX Should this just contain top-level `update` function for handling
-- `ComputeFormMsg`s?


handleSuccessfulComputeFormSubmit : Model -> Int -> PrimaryGroup -> Model
handleSuccessfulComputeFormSubmit model clusterIndex newGroup =
    let
        currentCluster =
            List.Extra.getAt clusterIndex model.clusters

        newClusters =
            List.Extra.updateAt
                clusterIndex
                addGroupId
                model.clusters

        addGroupId cluster =
            { cluster
                | computeGroupIds =
                    newGroupId :: cluster.computeGroupIds
            }

        ( newGroupId, newSeed ) =
            Random.Pcg.step Uuid.uuidGenerator model.randomSeed

        newGroups =
            EveryDict.insert
                newGroupId
                newGroup
                model.clusterPrimaryGroups
    in
    { model
        | clusters = newClusters
        , clusterPrimaryGroups = newGroups
        , randomSeed = newSeed
        , displayedForm = Model.NoForm
    }


handleUpdatingComputeFormName : String -> ComputeForm -> ComputeForm
handleUpdatingComputeFormName newName computeForm =
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
    in
    Form.update ComputeForm.Model.validation
        (Form.Input "nodes.base" Form.Text (Field.String newBase))
        computeForm
