module Update exposing (update)

import ClusterDomain
import ComputeForm.Model exposing (ComputeForm, ComputeModal(..))
import ComputeForm.Update
import EveryDict exposing (EveryDict)
import Form exposing (Form)
import Form.Field as Field exposing (Field)
import List.Extra
import Model exposing (CoreDomain, Model)
import Msg exposing (..)
import Node exposing (Node)


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
            { model | computeModal = AddingCompute clusterIndex }

        CancelAddingComputeGroup ->
            { model | computeModal = Hidden }

        ComputeFormMsg clusterIndex formMsg ->
            case ( formMsg, Form.getOutput model.computeForm ) of
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
                                        newName
                                        model.computeForm

                                _ ->
                                    model.computeForm
                    in
                    { model
                        | computeForm =
                            Form.update
                                ComputeForm.Model.validation
                                formMsg
                                preUpdatedForm
                    }

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


changeInfra : Model -> Maybe Node -> Model
changeInfra model infra =
    let
        newCore =
            { currentCore | infra = infra }

        currentCore =
            model.core
    in
    { model | core = newCore }
