module Update exposing (update)

import ClusterDomain
import ComputeForm.Update
import EveryDict exposing (EveryDict)
import EverySet exposing (EverySet)
import Form exposing (Form)
import Form.Field as Field exposing (Field)
import Forms
import List.Extra
import Model exposing (CoreDomain, Model)
import Msg exposing (..)
import Node exposing (Node)
import Random.Pcg
import SecondaryGroupForm.Model
import SecondaryGroupForm.Update
import Uuid exposing (Uuid)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        newModel =
            updateInterfaceState msg model

        convertYamlCmd =
            case msg of
                NewConvertedYaml _ ->
                    -- Do not convert model to YAML when we've just handled
                    -- receiving new converted YAML, to avoid infinite loop.
                    Cmd.none

                _ ->
                    Model.convertToYamlCmd newModel
    in
    newModel ! [ convertYamlCmd ]


updateInterfaceState : Msg -> Model -> Model
updateInterfaceState msg model =
    case msg of
        AddCluster ->
            let
                newClusters =
                    List.concat
                        [ model.clusters
                        , [ ClusterDomain.nextCluster model.clusters ]
                        ]
            in
            { model | clusters = newClusters }

        RemoveCluster clusterIndex ->
            { model
                | clusters = List.Extra.removeAt clusterIndex model.clusters
            }

        AddInfra ->
            changeInfra model <| Just { name = "infra" }

        RemoveInfra ->
            changeInfra model Nothing

        NewConvertedYaml yaml ->
            { model | exportedYaml = yaml }

        SetNodeName nodeSpecifier name ->
            -- XXX This branch is a bit messy and could be tidied up - possibly
            -- the best way to do this is to store all nodes in the same way in
            -- model.
            let
                { core, clusters } =
                    model

                newNode =
                    Node name
            in
            case nodeSpecifier of
                Gateway ->
                    let
                        newCore =
                            { core | gateway = newNode }
                    in
                    { model | core = newCore }

                Infra ->
                    let
                        newCore =
                            case core.infra of
                                Just infra ->
                                    { core | infra = Just newNode }

                                Nothing ->
                                    core
                    in
                    { model | core = newCore }

                Login clusterIndex ->
                    let
                        newClusters =
                            List.Extra.updateAt
                                clusterIndex
                                changeClusterLogin
                                clusters

                        changeClusterLogin cluster =
                            { cluster | login = newNode }
                    in
                    { model | clusters = newClusters }

                Compute ->
                    -- XXX Handle compute better
                    model

        SetClusterName clusterIndex name ->
            let
                newClusters =
                    List.Extra.updateAt
                        clusterIndex
                        (\c -> { c | name = name })
                        model.clusters
            in
            { model | clusters = newClusters }

        StartAddingComputeGroup clusterIndex ->
            let
                ( newGroupId, newSeed ) =
                    Random.Pcg.step Uuid.uuidGenerator model.randomSeed
            in
            { model
                | displayedForm =
                    Model.ComputeForm
                        clusterIndex
                        (Forms.initComputeForm model clusterIndex newGroupId)
                , randomSeed = newSeed
            }

        CancelAddingComputeGroup ->
            { model | displayedForm = Model.NoForm }

        ComputeFormMsg formMsg ->
            -- XXX Make this less nested.
            case model.displayedForm of
                Model.ComputeForm clusterIndex form ->
                    case ( formMsg, Form.getOutput form ) of
                        ( Form.Submit, Just newGroup ) ->
                            ComputeForm.Update.handleSuccessfulComputeFormSubmit
                                model
                                clusterIndex
                                newGroup

                        ( formMsg, _ ) ->
                            let
                                preUpdatedForm =
                                    case formMsg of
                                        Form.Input "name" _ (Field.String newName) ->
                                            ComputeForm.Update.handleUpdatingComputeFormName
                                                model
                                                clusterIndex
                                                newGroupId
                                                newName
                                                form

                                        _ ->
                                            form

                                ( newGroupId, newSeed ) =
                                    Random.Pcg.step Uuid.uuidGenerator model.randomSeed

                                newForm =
                                    Form.update
                                        (Forms.computeFormValidation
                                            model
                                            clusterIndex
                                            newGroupId
                                        )
                                        formMsg
                                        preUpdatedForm
                            in
                            { model
                                | displayedForm = Model.ComputeForm clusterIndex newForm
                                , randomSeed = newSeed
                            }

                _ ->
                    -- Do nothing if any other form displayed.
                    model

        RemoveComputeGroup groupId ->
            let
                -- Only delete the group itself, and not any possible
                -- references to this elsewhere. This makes things simple and
                -- should be fine so long as we always handle 'the group being
                -- referenced but not existing' case the same as the 'group not
                -- being referenced at all' case. XXX See if this causes
                -- problems and if I still think the same in future.
                newGroups =
                    EveryDict.remove groupId model.clusterPrimaryGroups
            in
            { model | clusterPrimaryGroups = newGroups }

        StartCreatingSecondaryGroup clusterIndex ->
            { model
                | displayedForm =
                    Model.SecondaryGroupForm
                        clusterIndex
                        (SecondaryGroupForm.Model.ShowingNameForm
                            (Forms.initSecondaryGroupNameForm
                                model
                                clusterIndex
                            )
                        )
            }

        SecondaryGroupFormMsg formMsg ->
            -- XXX Make this less nested.
            case model.displayedForm of
                Model.SecondaryGroupForm clusterIndex form ->
                    case form of
                        SecondaryGroupForm.Model.ShowingNameForm nameForm ->
                            case ( formMsg, Form.getOutput nameForm ) of
                                ( Form.Submit, Just groupName ) ->
                                    { model
                                        | displayedForm =
                                            Model.SecondaryGroupForm
                                                clusterIndex
                                                (SecondaryGroupForm.Model.SelectingGroups
                                                    groupName
                                                    EverySet.empty
                                                )
                                    }

                                ( formMsg, _ ) ->
                                    let
                                        newNameForm =
                                            Form.update
                                                (Forms.secondaryGroupNameFormValidation
                                                    model
                                                    clusterIndex
                                                )
                                                formMsg
                                                nameForm
                                    in
                                    { model
                                        | displayedForm =
                                            Model.SecondaryGroupForm
                                                clusterIndex
                                                (SecondaryGroupForm.Model.ShowingNameForm newNameForm)
                                    }

                        SecondaryGroupForm.Model.SelectingGroups _ _ ->
                            -- Do nothing if we're in the group selection
                            -- stage.
                            model

                _ ->
                    -- Do nothing if any other form displayed.
                    model

        CancelCreatingSecondaryGroup ->
            { model | displayedForm = Model.NoForm }

        AddGroupToSecondaryGroup groupId ->
            changeSecondaryGroupMembers model (EverySet.insert groupId)

        RemoveGroupFromSecondaryGroup groupId ->
            changeSecondaryGroupMembers model (EverySet.remove groupId)

        CreateSecondaryGroup ->
            case model.displayedForm of
                Model.SecondaryGroupForm clusterIndex form ->
                    case form of
                        SecondaryGroupForm.Model.ShowingNameForm _ ->
                            -- Do nothing if we're in the name form stage.
                            model

                        SecondaryGroupForm.Model.SelectingGroups secondaryGroupName memberGroupIds ->
                            SecondaryGroupForm.Update.handleSecondaryGroupCreate
                                model
                                clusterIndex
                                secondaryGroupName
                                memberGroupIds

                _ ->
                    -- Do nothing if any other form displayed.
                    model


changeInfra : Model -> Maybe Node -> Model
changeInfra model infra =
    let
        newCore =
            { currentCore | infra = infra }

        currentCore =
            model.core
    in
    { model | core = newCore }


changeSecondaryGroupMembers : Model -> (EverySet Uuid -> EverySet Uuid) -> Model
changeSecondaryGroupMembers model changeMembers =
    case model.displayedForm of
        Model.SecondaryGroupForm clusterId form ->
            let
                newForm =
                    case form of
                        SecondaryGroupForm.Model.ShowingNameForm _ ->
                            form

                        SecondaryGroupForm.Model.SelectingGroups groupName groupIds ->
                            SecondaryGroupForm.Model.SelectingGroups
                                groupName
                                (changeMembers groupIds)
            in
            { model
                | displayedForm = Model.SecondaryGroupForm clusterId newForm
            }

        _ ->
            -- Do nothing if any other form displayed.
            model
