import datetime
import json
import pprint
import argparse
import random
from pathlib import Path

from snakes.nets import *

if __package__ is None or __package__ == '':
    from imaging_TestSCN import TestSCN, Step, Tests, Constraint, CEntry
    from imaging_data import Data
    from imaging_Simulation import Simulation, simulate
else:
    from .imaging_TestSCN import TestSCN, Step, Tests, Constraint, CEntry
    from .imaging_data import Data
    from .imaging_Simulation import Simulation, simulate
import subprocess
import copy
import os

snakes.plugins.load('gv', 'snakes.nets', 'nets')
from nets import *
# from CPNServer.utils import AbstractCPNControl


class imagingModel:
    visitedList = set()
    visitedTList = [[]]
    visitedTProdList = [[]]
    rg_txt = ""

    # test generation data
    sutTypesList = []
    sutVarTransitionMap = {}
    numTestCases = 0
    listOfEnvBlocks = []
    listOfSUTActions = []
    mapOfSuppressTransitionVars = {}
    mapOfTransitionQnames = {}
    map_of_transition_modes = {}
    map_transition_modes_to_name = {}
    constraint_dict = {}
    tr_assert_ref_dict = {}
    map_transition_assert = {}

    # Simulation data
    stepsList = []
    markedIndex = 0
    # Replay scenario data
    map_transition_filter = {}

    def __init__(self):
        self.rg_txt = '@startuml\n'
        self.rg_txt += '[*] --> 0\n'
        self.listOfEnvBlocks = ["SupervisonModelPumpController","SupervisonModelAcquisitionController","SupervisonModelSupervisionTemperatureHandler"]
        self.listOfSUTActions = ["SupervisonModelSupervisionImagePreparation_Unprepare_default","SupervisonModelSupervisionImagePreparation_Prepare_default","SupervisonModelPumpController_startpump_default","SupervisonModelPumpController_stoppump_default","SupervisonModelSupervisionPressureHandler_StartPump_default","SupervisonModelSupervisionPressureHandler_TurnOffPump_default","SupervisonModelTemperatureController_CheckTemp_default","SupervisonModelAcquisitionController_Execacquisitioninitandteardown_default","SupervisonModelAcquisitionController_StartAcquisition_default","SupervisonModelAcquisitionController_StopAcquisition_default","SupervisonModelSupervisionImaging_CheckLowResImageQuality_default","SupervisonModelSupervisionImaging_StopAcquisition_default","SupervisonModelSupervisionImaging_StartAcquisition_default","SupervisonModelSupervisionImaging_CheckHighResImageQuality_default","SupervisonModelSupervisionTemperatureHandler_CreateResetTempMessage_default","SupervisonModelSupervisionTemperatureHandler_ExecuteSetTemp_default","SupervisonModelSupervisionTemperatureHandler_CreateSetTempMessage_default"]
        self.mapOfSuppressTransitionVars = {'SupervisonModelSupervisionImaging_CheckLowResImageQuality_default': ['Gateway_0qg69ul'],'SupervisonModelSupervisionImagePreparation_Prepare_default': ['Flow_0kkvgdv','EqStatus'],'SupervisonModelSupervisionImagePreparation_Unprepare_default': ['Flow_1kpcqqf'],'SupervisonModelSupervisionTemperatureHandler_CreateResetTempMessage_default': ['Gateway_1qk9wqe','EqStatus'],'SupervisonModelSupervisionImagePreparation_WaitforUnprepare_default': ['Gateway_102q82v'],'SupervisonModelSupervisionImaging_StopAcquisition_default': ['Flow_0678bm1'],'SupervisonModelSupervisionImaging_StartAcquisition_default': ['Flow_1bajtwc','EqStatus'],'SupervisonModelSupervisionPressureHandler_TurnOffPump_default': ['EqStatus'],'SupervisonModelSupervisionImaging_WaitforStartAcquisition_default': ['Gateway_0qg69ul'],'SupervisonModelSupervisionImagePreparation_Waitforprepare_default': ['Gateway_102q82v'],'SupervisonModelSupervisionTemperatureHandler_ExecuteSetTemp_default': ['Event_13ys7sy'],'SupervisonModelSupervisionImaging_CheckHighResImageQuality_default': ['Gateway_0qg69ul'],'SupervisonModelSupervisionTemperatureHandler_CreateSetTempMessage_default': ['Gateway_1qk9wqe'],'SupervisonModelSupervisionImaging_WaitforStopAcquisition_default': ['Gateway_16m9e4j'],'SupervisonModelSupervisionPressureHandler_StartPump_default': ['EqStatus']}
        self.mapOfTransitionQnames = {'SupervisonModelSupervisionImagePreparation_Unprepare_default': 'imaging.SupervisonModelSupervisionImagePreparation.Unprepare.default','SupervisonModelSupervisionImagePreparation_Prepare_default': 'imaging.SupervisonModelSupervisionImagePreparation.Prepare.default','SupervisonModelPumpController_startpump_default': 'imaging.SupervisonModelPumpController.startpump.default','SupervisonModelPumpController_stoppump_default': 'imaging.SupervisonModelPumpController.stoppump.default','SupervisonModelSupervisionPressureHandler_StartPump_default': 'imaging.SupervisonModelSupervisionPressureHandler.StartPump.default','SupervisonModelSupervisionPressureHandler_TurnOffPump_default': 'imaging.SupervisonModelSupervisionPressureHandler.TurnOffPump.default','SupervisonModelTemperatureController_CheckTemp_default': 'imaging.SupervisonModelTemperatureController.CheckTemp.default','SupervisonModelAcquisitionController_Execacquisitioninitandteardown_default': 'imaging.SupervisonModelAcquisitionController.Execacquisitioninitandteardown.default','SupervisonModelAcquisitionController_StartAcquisition_default': 'imaging.SupervisonModelAcquisitionController.StartAcquisition.default','SupervisonModelAcquisitionController_StopAcquisition_default': 'imaging.SupervisonModelAcquisitionController.StopAcquisition.default','SupervisonModelSupervisionImaging_CheckLowResImageQuality_default': 'imaging.SupervisonModelSupervisionImaging.CheckLowResImageQuality.default','SupervisonModelSupervisionImaging_StopAcquisition_default': 'imaging.SupervisonModelSupervisionImaging.StopAcquisition.default','SupervisonModelSupervisionImaging_StartAcquisition_default': 'imaging.SupervisonModelSupervisionImaging.StartAcquisition.default','SupervisonModelSupervisionImaging_CheckHighResImageQuality_default': 'imaging.SupervisonModelSupervisionImaging.CheckHighResImageQuality.default','SupervisonModelSupervisionTemperatureHandler_CreateResetTempMessage_default': 'imaging.SupervisonModelSupervisionTemperatureHandler.CreateResetTempMessage.default','SupervisonModelSupervisionTemperatureHandler_ExecuteSetTemp_default': 'imaging.SupervisonModelSupervisionTemperatureHandler.ExecuteSetTemp.default','SupervisonModelSupervisionTemperatureHandler_CreateSetTempMessage_default': 'imaging.SupervisonModelSupervisionTemperatureHandler.CreateSetTempMessage.default'}
        self.n = PetriNet('imaging')
        self.n.globals["Data"] = Data
        self.n.globals.declare("import json")
        self.n.add_place(Place('ImagingRequest'))
        self.n.add_place(Place('AcqUpdate'))
        self.n.add_place(Place('EqStatus'))
        self.n.add_place(Place('ImagingUpdate'))
        self.n.add_place(Place('AcquisitionReq'))
        self.n.add_place(Place('Gateway_102q82v'))
        self.n.add_place(Place('Flow_0kkvgdv'))
        self.n.add_place(Place('Flow_1kpcqqf'))
        self.n.add_place(Place('PumpRequest'))
        self.n.add_place(Place('PumpUpdate'))
        self.n.add_place(Place('Gateway_0td58pc'))
        self.n.add_place(Place('Flow_0x0gs9b'))
        self.n.add_place(Place('Flow_104f6k4'))
        self.n.add_place(Place('Gateway_0i3nw09'))
        self.n.add_place(Place('Gateway_0gu94f4'))
        self.n.add_place(Place('Gateway_0kvhy0o'))
        self.n.add_place(Place('Gateway_08l0os0'))
        self.n.add_place(Place('Gateway_0xpxevh'))
        self.n.add_place(Place('Flow_1k04xzh'))
        self.n.add_place(Place('Flow_029nrs5'))
        self.n.add_place(Place('Flow_0ncxpgd'))
        self.n.add_place(Place('Flow_05szwsj'))
        self.n.add_place(Place('VacuumRequest'))
        self.n.add_place(Place('VacuumUpdate'))
        self.n.add_place(Place('Gateway_1i0qy9g'))
        self.n.add_place(Place('Gateway_1j81da5'))
        self.n.add_place(Place('Flow_1wguswc'))
        self.n.add_place(Place('Flow_0balrow'))
        self.n.add_place(Place('Flow_0cjhiik'))
        self.n.add_place(Place('TempUpdate'))
        self.n.add_place(Place('temp_achieved'))
        self.n.add_place(Place('TempRequest'))
        self.n.add_place(Place('Gateway_1sv33t8'))
        self.n.add_place(Place('Gateway_12yhscn'))
        self.n.add_place(Place('Event_1r2zvr6'))
        self.n.add_place(Place('Flow_0estwso'))
        self.n.add_place(Place('Flow_0ay6jpo'))
        self.n.add_place(Place('Flow_01g3o4k'))
        self.n.add_place(Place('Gateway_0mqr7c2'))
        self.n.add_place(Place('Gateway_07w0e8f'))
        self.n.add_place(Place('Flow_1phqrfh'))
        self.n.add_place(Place('Flow_1erv6vq'))
        self.n.add_place(Place('Flow_1dvvja5'))
        self.n.add_place(Place('ImageData'))
        self.n.add_place(Place('Gateway_0h81kts'))
        self.n.add_place(Place('Flow_084nmm6'))
        self.n.add_place(Place('Flow_1rusz82'))
        self.n.add_place(Place('Flow_1w9tlf4'))
        self.n.add_place(Place('LastAcqReq'))
        self.n.add_place(Place('Gateway_16m9e4j'))
        self.n.add_place(Place('Gateway_0qg69ul'))
        self.n.add_place(Place('Flow_0678bm1'))
        self.n.add_place(Place('Flow_1bajtwc'))
        self.n.add_place(Place('TempCMD'))
        self.n.add_place(Place('Gateway_1qk9wqe'))
        self.n.add_place(Place('Event_13ys7sy'))
        self.n.place('Event_1r2zvr6').empty()
        self.n.place('Event_1r2zvr6').add(json.dumps({"id": 0}))
        self.n.place('Gateway_0mqr7c2').empty()
        self.n.place('Gateway_0mqr7c2').add(json.dumps({"id": 0}))
        self.n.place('Gateway_0xpxevh').empty()
        self.n.place('Gateway_0xpxevh').add(json.dumps({"id": 0}))
        self.n.place('EqStatus').empty()
        self.n.place('EqStatus').add(json.dumps({"temp_status": "Status::OFF", "pump_status": "Status::OFF", "acq_status": "Status::OFF"}))
        self.n.place('Gateway_1j81da5').empty()
        self.n.place('Gateway_1j81da5').add(json.dumps({"id": 0}))
        self.n.add_transition(PrioritizedTransition('SupervisonModelSupervisionImagePreparation_Unprepare_default@null@COMPOSE@', 0, Expression('json.loads(v_ImagingRequest, object_pairs_hook=Data().int_keys)["cmd_type"] == "ImageEnum::UNPREPARE"')))
        self.n.add_transition(PrioritizedTransition('SupervisonModelSupervisionImagePreparation_Prepare_default@null@COMPOSE@', 0, Expression('json.loads(v_ImagingRequest, object_pairs_hook=Data().int_keys)["cmd_type"] == "ImageEnum::PREPARE" and json.loads(v_EqStatus, object_pairs_hook=Data().int_keys)["temp_status"] == "Status::ON"')))
        self.n.add_transition(PrioritizedTransition('SupervisonModelSupervisionImagePreparation_Waitforprepare_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelSupervisionImagePreparation_WaitforUnprepare_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelPumpController_done_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelPumpController_startpump_default@ExecPumpCommand@RUN@', 0, Expression('json.loads(v_PumpRequest, object_pairs_hook=Data().int_keys)["cmd_type"] == "VacuumEnum::ON"')))
        self.n.add_transition(PrioritizedTransition('SupervisonModelPumpController_stoppump_default@ExecPumpCommand@RUN@', 0, Expression('json.loads(v_PumpRequest, object_pairs_hook=Data().int_keys)["cmd_type"] == "VacuumEnum::OFF"')))
        self.n.add_transition(PrioritizedTransition('SupervisonModelPumpController_pumpstopped_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelImagingController_WaitforUnprepareImaging_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelImagingController_returntoprep_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelImagingController_UnprepareImaging_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelImagingController_WaitforImagingStopped_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelImagingController_StartLowResImaging_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelImagingController_nextimage_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelImagingController_StartHighResImaging_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelImagingController_Stopimaging_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelImagingController_WaitforPrepared_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelImagingController_PrepareImaging_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelImagingController_ImagingFinished_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelSupervisionPressureHandler_StartPump_default@null@COMPOSE@', 0, Expression('json.loads(v_EqStatus, object_pairs_hook=Data().int_keys)["acq_status"] == "Status::PREPARING"')))
        self.n.add_transition(PrioritizedTransition('SupervisonModelSupervisionPressureHandler_WaitforPumpOff_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelSupervisionPressureHandler_Restart_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelSupervisionPressureHandler_TurnOffPump_default@null@COMPOSE@', 0, Expression('json.loads(v_EqStatus, object_pairs_hook=Data().int_keys)["acq_status"] == "Status::UNPREPARING"')))
        self.n.add_transition(PrioritizedTransition('SupervisonModelSupervisionPressureHandler_WaitforPumpStated_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelTemperatureController_return_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelTemperatureController_CheckTemp_default@TempCheck@ASSERT@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelTemperatureController_SetTemperature_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelTemperatureController_ResetTemperature_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelTemperatureController_WaitforReset_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelTemperatureController_WaitforTempSet_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelVacuumController_TurnOff_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelVacuumController_SetVacuum_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelVacuumController_return_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelVacuumController_WaitforOff_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelVacuumController_WaitforVacuumSet_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelAcquisitionController_AcquisitionStopped_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelAcquisitionController_Execacquisitioninitandteardown_default@ExecAcquisitionCommand@RUN@', 0, Expression('json.loads(v_AcquisitionReq, object_pairs_hook=Data().int_keys)["cmd_type"] == "ImageEnum::PREPARE" or json.loads(v_AcquisitionReq, object_pairs_hook=Data().int_keys)["cmd_type"] == "ImageEnum::UNPREPARE"')))
        self.n.add_transition(PrioritizedTransition('SupervisonModelAcquisitionController_StartAcquisition_default@ExecAcquisitionCommand@RUN@', 0, Expression('json.loads(v_AcquisitionReq, object_pairs_hook=Data().int_keys)["cmd_type"] == "ImageEnum::START"')))
        self.n.add_transition(PrioritizedTransition('SupervisonModelAcquisitionController_Acquisitionexecdone_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelAcquisitionController_StopAcquisition_default@ExecAcquisitionCommand@RUN@', 0, Expression('json.loads(v_AcquisitionReq, object_pairs_hook=Data().int_keys)["cmd_type"] == "ImageEnum::STOP"')))
        self.n.add_transition(PrioritizedTransition('SupervisonModelAcquisitionController_AcquisitionStarted_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelSupervisionImaging_WaitforStopAcquisition_default@null@INTERNAL@', 0, Expression('json.loads(v_AcqUpdate, object_pairs_hook=Data().int_keys)["result"] == "ResponseEnum::OK"')))
        self.n.add_transition(PrioritizedTransition('SupervisonModelSupervisionImaging_CheckLowResImageQuality_default@CheckAcquisitionResult@ASSERT@', 0, Expression('json.loads(v_LastAcqReq, object_pairs_hook=Data().int_keys)["image_quality"] == "ImageQuality::LOW"')))
        self.n.add_transition(PrioritizedTransition('SupervisonModelSupervisionImaging_WaitforStartAcquisition_default@null@INTERNAL@', 0, Expression('json.loads(v_AcqUpdate, object_pairs_hook=Data().int_keys)["result"] == "ResponseEnum::OK"')))
        self.n.add_transition(PrioritizedTransition('SupervisonModelSupervisionImaging_StopAcquisition_default@null@COMPOSE@', 0, Expression('json.loads(v_ImagingRequest, object_pairs_hook=Data().int_keys)["cmd_type"] == "ImageEnum::STOP"')))
        self.n.add_transition(PrioritizedTransition('SupervisonModelSupervisionImaging_StartAcquisition_default@null@COMPOSE@', 0, Expression('json.loads(v_ImagingRequest, object_pairs_hook=Data().int_keys)["cmd_type"] == "ImageEnum::START" and json.loads(v_EqStatus, object_pairs_hook=Data().int_keys)["temp_status"] == "Status::ON" and json.loads(v_EqStatus, object_pairs_hook=Data().int_keys)["pump_status"] == "Status::ON"')))
        self.n.add_transition(PrioritizedTransition('SupervisonModelSupervisionImaging_CheckHighResImageQuality_default@CheckAcquisitionResult@ASSERT@', 0, Expression('json.loads(v_LastAcqReq, object_pairs_hook=Data().int_keys)["image_quality"] == "ImageQuality::HIGH"')))
        self.n.add_transition(PrioritizedTransition('SupervisonModelSupervisionTemperatureHandler_CreateResetTempMessage_default@null@COMPOSE@', 0, Expression('json.loads(v_TempRequest, object_pairs_hook=Data().int_keys)["cmd_type"] == "TempEnum::RESET" and json.loads(v_EqStatus, object_pairs_hook=Data().int_keys)["acq_status"] == "Status::UNPREPARING"')))
        self.n.add_transition(PrioritizedTransition('SupervisonModelSupervisionTemperatureHandler_ExecuteSetTemp_default@SetTemperature@RUN@', 0))
        self.n.add_transition(PrioritizedTransition('SupervisonModelSupervisionTemperatureHandler_CreateSetTempMessage_default@null@COMPOSE@', 0, Expression('json.loads(v_TempRequest, object_pairs_hook=Data().int_keys)["cmd_type"] == "TempEnum::SET"')))
        self.n.add_input('Flow_0estwso','SupervisonModelTemperatureController_WaitforTempSet_default@null@INTERNAL@',Variable('v_Flow_0estwso'))
        self.n.add_input('TempUpdate','SupervisonModelTemperatureController_WaitforTempSet_default@null@INTERNAL@',Variable('v_TempUpdate'))
        self.n.add_input('Flow_0x0gs9b','SupervisonModelPumpController_done_default@null@INTERNAL@',Variable('v_Flow_0x0gs9b'))
        self.n.add_input('AcquisitionReq','SupervisonModelAcquisitionController_StopAcquisition_default@ExecAcquisitionCommand@RUN@',Variable('v_AcquisitionReq'))
        self.n.add_input('Gateway_16m9e4j','SupervisonModelSupervisionImaging_CheckLowResImageQuality_default@CheckAcquisitionResult@ASSERT@',Variable('v_Gateway_16m9e4j'))
        self.n.add_input('ImageData','SupervisonModelSupervisionImaging_CheckLowResImageQuality_default@CheckAcquisitionResult@ASSERT@',Variable('v_ImageData'))
        self.n.add_input('LastAcqReq','SupervisonModelSupervisionImaging_CheckLowResImageQuality_default@CheckAcquisitionResult@ASSERT@',Variable('v_LastAcqReq'))
        self.n.add_input('Flow_01g3o4k','SupervisonModelTemperatureController_ResetTemperature_default@null@INTERNAL@',Variable('v_Flow_01g3o4k'))
        self.n.add_input('Gateway_0i3nw09','SupervisonModelImagingController_nextimage_default@null@INTERNAL@',Variable('v_Gateway_0i3nw09'))
        self.n.add_input('Flow_1kpcqqf','SupervisonModelSupervisionImagePreparation_WaitforUnprepare_default@null@INTERNAL@',Variable('v_Flow_1kpcqqf'))
        self.n.add_input('AcqUpdate','SupervisonModelSupervisionImagePreparation_WaitforUnprepare_default@null@INTERNAL@',Variable('v_AcqUpdate'))
        self.n.add_input('EqStatus','SupervisonModelSupervisionImagePreparation_WaitforUnprepare_default@null@INTERNAL@',Variable('v_EqStatus'))
        self.n.add_input('Flow_029nrs5','SupervisonModelImagingController_WaitforPrepared_default@null@INTERNAL@',Variable('v_Flow_029nrs5'))
        self.n.add_input('ImagingUpdate','SupervisonModelImagingController_WaitforPrepared_default@null@INTERNAL@',Variable('v_ImagingUpdate'))
        self.n.add_input('Gateway_0i3nw09','SupervisonModelImagingController_UnprepareImaging_default@null@INTERNAL@',Variable('v_Gateway_0i3nw09'))
        self.n.add_input('Gateway_08l0os0','SupervisonModelImagingController_ImagingFinished_default@null@INTERNAL@',Variable('v_Gateway_08l0os0'))
        self.n.add_input('ImagingUpdate','SupervisonModelImagingController_ImagingFinished_default@null@INTERNAL@',Variable('v_ImagingUpdate'))
        self.n.add_input('Gateway_0mqr7c2','SupervisonModelVacuumController_SetVacuum_default@null@INTERNAL@',Variable('v_Gateway_0mqr7c2'))
        self.n.add_input('Flow_0678bm1','SupervisonModelSupervisionImaging_WaitforStopAcquisition_default@null@INTERNAL@',Variable('v_Flow_0678bm1'))
        self.n.add_input('AcqUpdate','SupervisonModelSupervisionImaging_WaitforStopAcquisition_default@null@INTERNAL@',Variable('v_AcqUpdate'))
        self.n.add_input('EqStatus','SupervisonModelSupervisionImaging_WaitforStopAcquisition_default@null@INTERNAL@',Variable('v_EqStatus'))
        self.n.add_input('Flow_05szwsj','SupervisonModelImagingController_WaitforUnprepareImaging_default@null@INTERNAL@',Variable('v_Flow_05szwsj'))
        self.n.add_input('ImagingUpdate','SupervisonModelImagingController_WaitforUnprepareImaging_default@null@INTERNAL@',Variable('v_ImagingUpdate'))
        self.n.add_input('Flow_1dvvja5','SupervisonModelVacuumController_WaitforOff_default@null@INTERNAL@',Variable('v_Flow_1dvvja5'))
        self.n.add_input('VacuumUpdate','SupervisonModelVacuumController_WaitforOff_default@null@INTERNAL@',Variable('v_VacuumUpdate'))
        self.n.add_input('Flow_1wguswc','SupervisonModelSupervisionPressureHandler_TurnOffPump_default@null@COMPOSE@',Variable('v_Flow_1wguswc'))
        self.n.add_input('VacuumRequest','SupervisonModelSupervisionPressureHandler_TurnOffPump_default@null@COMPOSE@',Variable('v_VacuumRequest'))
        self.n.add_input('EqStatus','SupervisonModelSupervisionPressureHandler_TurnOffPump_default@null@COMPOSE@',Variable('v_EqStatus'))
        self.n.add_input('PumpRequest','SupervisonModelPumpController_startpump_default@ExecPumpCommand@RUN@',Variable('v_PumpRequest'))
        self.n.add_input('TempRequest','SupervisonModelSupervisionTemperatureHandler_CreateResetTempMessage_default@null@COMPOSE@',Variable('v_TempRequest'))
        self.n.add_input('EqStatus','SupervisonModelSupervisionTemperatureHandler_CreateResetTempMessage_default@null@COMPOSE@',Variable('v_EqStatus'))
        self.n.add_input('Flow_1rusz82','SupervisonModelAcquisitionController_AcquisitionStarted_default@null@INTERNAL@',Variable('v_Flow_1rusz82'))
        self.n.add_input('ImagingRequest','SupervisonModelSupervisionImagePreparation_Unprepare_default@null@COMPOSE@',Variable('v_ImagingRequest'))
        self.n.add_input('Flow_1k04xzh','SupervisonModelImagingController_Stopimaging_default@null@INTERNAL@',Variable('v_Flow_1k04xzh'))
        self.n.add_input('Flow_1bajtwc','SupervisonModelSupervisionImaging_WaitforStartAcquisition_default@null@INTERNAL@',Variable('v_Flow_1bajtwc'))
        self.n.add_input('AcqUpdate','SupervisonModelSupervisionImaging_WaitforStartAcquisition_default@null@INTERNAL@',Variable('v_AcqUpdate'))
        self.n.add_input('EqStatus','SupervisonModelSupervisionImaging_WaitforStartAcquisition_default@null@INTERNAL@',Variable('v_EqStatus'))
        self.n.add_input('AcquisitionReq','SupervisonModelAcquisitionController_Execacquisitioninitandteardown_default@ExecAcquisitionCommand@RUN@',Variable('v_AcquisitionReq'))
        self.n.add_input('Gateway_1sv33t8','SupervisonModelTemperatureController_CheckTemp_default@TempCheck@ASSERT@',Variable('v_Gateway_1sv33t8'))
        self.n.add_input('temp_achieved','SupervisonModelTemperatureController_CheckTemp_default@TempCheck@ASSERT@',Variable('v_temp_achieved'))
        self.n.add_input('Flow_0kkvgdv','SupervisonModelSupervisionImagePreparation_Waitforprepare_default@null@INTERNAL@',Variable('v_Flow_0kkvgdv'))
        self.n.add_input('AcqUpdate','SupervisonModelSupervisionImagePreparation_Waitforprepare_default@null@INTERNAL@',Variable('v_AcqUpdate'))
        self.n.add_input('EqStatus','SupervisonModelSupervisionImagePreparation_Waitforprepare_default@null@INTERNAL@',Variable('v_EqStatus'))
        self.n.add_input('Gateway_0gu94f4','SupervisonModelImagingController_returntoprep_default@null@INTERNAL@',Variable('v_Gateway_0gu94f4'))
        self.n.add_input('Flow_0cjhiik','SupervisonModelSupervisionPressureHandler_WaitforPumpOff_default@null@INTERNAL@',Variable('v_Flow_0cjhiik'))
        self.n.add_input('PumpUpdate','SupervisonModelSupervisionPressureHandler_WaitforPumpOff_default@null@INTERNAL@',Variable('v_PumpUpdate'))
        self.n.add_input('EqStatus','SupervisonModelSupervisionPressureHandler_WaitforPumpOff_default@null@INTERNAL@',Variable('v_EqStatus'))
        self.n.add_input('Gateway_1j81da5','SupervisonModelSupervisionPressureHandler_StartPump_default@null@COMPOSE@',Variable('v_Gateway_1j81da5'))
        self.n.add_input('VacuumRequest','SupervisonModelSupervisionPressureHandler_StartPump_default@null@COMPOSE@',Variable('v_VacuumRequest'))
        self.n.add_input('EqStatus','SupervisonModelSupervisionPressureHandler_StartPump_default@null@COMPOSE@',Variable('v_EqStatus'))
        self.n.add_input('Gateway_0kvhy0o','SupervisonModelImagingController_StartLowResImaging_default@null@INTERNAL@',Variable('v_Gateway_0kvhy0o'))
        self.n.add_input('Flow_084nmm6','SupervisonModelAcquisitionController_Acquisitionexecdone_default@null@INTERNAL@',Variable('v_Flow_084nmm6'))
        self.n.add_input('Gateway_07w0e8f','SupervisonModelVacuumController_return_default@null@INTERNAL@',Variable('v_Gateway_07w0e8f'))
        self.n.add_input('PumpRequest','SupervisonModelPumpController_stoppump_default@ExecPumpCommand@RUN@',Variable('v_PumpRequest'))
        self.n.add_input('Gateway_0kvhy0o','SupervisonModelImagingController_StartHighResImaging_default@null@INTERNAL@',Variable('v_Gateway_0kvhy0o'))
        self.n.add_input('Gateway_0xpxevh','SupervisonModelImagingController_PrepareImaging_default@null@INTERNAL@',Variable('v_Gateway_0xpxevh'))
        self.n.add_input('ImagingRequest','SupervisonModelSupervisionImaging_StopAcquisition_default@null@COMPOSE@',Variable('v_ImagingRequest'))
        self.n.add_input('Flow_104f6k4','SupervisonModelPumpController_pumpstopped_default@null@INTERNAL@',Variable('v_Flow_104f6k4'))
        self.n.add_input('Flow_1phqrfh','SupervisonModelVacuumController_WaitforVacuumSet_default@null@INTERNAL@',Variable('v_Flow_1phqrfh'))
        self.n.add_input('VacuumUpdate','SupervisonModelVacuumController_WaitforVacuumSet_default@null@INTERNAL@',Variable('v_VacuumUpdate'))
        self.n.add_input('Gateway_12yhscn','SupervisonModelTemperatureController_return_default@null@INTERNAL@',Variable('v_Gateway_12yhscn'))
        self.n.add_input('Gateway_1i0qy9g','SupervisonModelSupervisionPressureHandler_Restart_default@null@INTERNAL@',Variable('v_Gateway_1i0qy9g'))
        self.n.add_input('Flow_0ncxpgd','SupervisonModelImagingController_WaitforImagingStopped_default@null@INTERNAL@',Variable('v_Flow_0ncxpgd'))
        self.n.add_input('ImagingUpdate','SupervisonModelImagingController_WaitforImagingStopped_default@null@INTERNAL@',Variable('v_ImagingUpdate'))
        self.n.add_input('Flow_1w9tlf4','SupervisonModelAcquisitionController_AcquisitionStopped_default@null@INTERNAL@',Variable('v_Flow_1w9tlf4'))
        self.n.add_input('Gateway_16m9e4j','SupervisonModelSupervisionImaging_CheckHighResImageQuality_default@CheckAcquisitionResult@ASSERT@',Variable('v_Gateway_16m9e4j'))
        self.n.add_input('ImageData','SupervisonModelSupervisionImaging_CheckHighResImageQuality_default@CheckAcquisitionResult@ASSERT@',Variable('v_ImageData'))
        self.n.add_input('LastAcqReq','SupervisonModelSupervisionImaging_CheckHighResImageQuality_default@CheckAcquisitionResult@ASSERT@',Variable('v_LastAcqReq'))
        self.n.add_input('TempRequest','SupervisonModelSupervisionTemperatureHandler_CreateSetTempMessage_default@null@COMPOSE@',Variable('v_TempRequest'))
        self.n.add_input('AcquisitionReq','SupervisonModelAcquisitionController_StartAcquisition_default@ExecAcquisitionCommand@RUN@',Variable('v_AcquisitionReq'))
        self.n.add_input('Gateway_1qk9wqe','SupervisonModelSupervisionTemperatureHandler_ExecuteSetTemp_default@SetTemperature@RUN@',Variable('v_Gateway_1qk9wqe'))
        self.n.add_input('TempCMD','SupervisonModelSupervisionTemperatureHandler_ExecuteSetTemp_default@SetTemperature@RUN@',Variable('v_TempCMD'))
        self.n.add_input('EqStatus','SupervisonModelSupervisionTemperatureHandler_ExecuteSetTemp_default@SetTemperature@RUN@',Variable('v_EqStatus'))
        self.n.add_input('Flow_1erv6vq','SupervisonModelVacuumController_TurnOff_default@null@INTERNAL@',Variable('v_Flow_1erv6vq'))
        self.n.add_input('Flow_0balrow','SupervisonModelSupervisionPressureHandler_WaitforPumpStated_default@null@INTERNAL@',Variable('v_Flow_0balrow'))
        self.n.add_input('PumpUpdate','SupervisonModelSupervisionPressureHandler_WaitforPumpStated_default@null@INTERNAL@',Variable('v_PumpUpdate'))
        self.n.add_input('EqStatus','SupervisonModelSupervisionPressureHandler_WaitforPumpStated_default@null@INTERNAL@',Variable('v_EqStatus'))
        self.n.add_input('Event_1r2zvr6','SupervisonModelTemperatureController_SetTemperature_default@null@INTERNAL@',Variable('v_Event_1r2zvr6'))
        self.n.add_input('ImagingRequest','SupervisonModelSupervisionImagePreparation_Prepare_default@null@COMPOSE@',Variable('v_ImagingRequest'))
        self.n.add_input('EqStatus','SupervisonModelSupervisionImagePreparation_Prepare_default@null@COMPOSE@',Variable('v_EqStatus'))
        self.n.add_input('Flow_0ay6jpo','SupervisonModelTemperatureController_WaitforReset_default@null@INTERNAL@',Variable('v_Flow_0ay6jpo'))
        self.n.add_input('TempUpdate','SupervisonModelTemperatureController_WaitforReset_default@null@INTERNAL@',Variable('v_TempUpdate'))
        self.n.add_input('ImagingRequest','SupervisonModelSupervisionImaging_StartAcquisition_default@null@COMPOSE@',Variable('v_ImagingRequest'))
        self.n.add_input('EqStatus','SupervisonModelSupervisionImaging_StartAcquisition_default@null@COMPOSE@',Variable('v_EqStatus'))
        self.n.add_output('Gateway_1sv33t8','SupervisonModelTemperatureController_WaitforTempSet_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelTemperatureController_WaitforTempSet_default_Gateway_1sv33t8(json.loads(v_TempUpdate, object_pairs_hook=Data().int_keys),json.loads(v_Flow_0estwso, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_0td58pc','SupervisonModelPumpController_done_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelPumpController_done_default_Gateway_0td58pc(json.loads(v_Flow_0x0gs9b, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('PumpUpdate','SupervisonModelPumpController_done_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelPumpController_done_default_PumpUpdate(json.loads(v_Flow_0x0gs9b, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_1w9tlf4','SupervisonModelAcquisitionController_StopAcquisition_default@ExecAcquisitionCommand@RUN@', Expression('Data().execute_SupervisonModelAcquisitionController_StopAcquisition_default_Flow_1w9tlf4(json.loads(v_AcquisitionReq, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('ImageData','SupervisonModelAcquisitionController_StopAcquisition_default@ExecAcquisitionCommand@RUN@', Expression('Data().execute_SupervisonModelAcquisitionController_StopAcquisition_default_ImageData(json.loads(v_AcquisitionReq, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_0qg69ul','SupervisonModelSupervisionImaging_CheckLowResImageQuality_default@CheckAcquisitionResult@ASSERT@', Expression('Data().execute_SupervisonModelSupervisionImaging_CheckLowResImageQuality_default_Gateway_0qg69ul(json.loads(v_ImageData, object_pairs_hook=Data().int_keys),json.loads(v_Gateway_16m9e4j, object_pairs_hook=Data().int_keys),json.loads(v_LastAcqReq, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_0ay6jpo','SupervisonModelTemperatureController_ResetTemperature_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelTemperatureController_ResetTemperature_default_Flow_0ay6jpo(json.loads(v_Flow_01g3o4k, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('TempRequest','SupervisonModelTemperatureController_ResetTemperature_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelTemperatureController_ResetTemperature_default_TempRequest(json.loads(v_Flow_01g3o4k, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_0kvhy0o','SupervisonModelImagingController_nextimage_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelImagingController_nextimage_default_Gateway_0kvhy0o(json.loads(v_Gateway_0i3nw09, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_102q82v','SupervisonModelSupervisionImagePreparation_WaitforUnprepare_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelSupervisionImagePreparation_WaitforUnprepare_default_Gateway_102q82v(json.loads(v_AcqUpdate, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys),json.loads(v_Flow_1kpcqqf, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('ImagingUpdate','SupervisonModelSupervisionImagePreparation_WaitforUnprepare_default@null@INTERNAL@', Expression('Data().get_ImgResp()'))
        self.n.add_output('EqStatus','SupervisonModelSupervisionImagePreparation_WaitforUnprepare_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelSupervisionImagePreparation_WaitforUnprepare_default_EqStatus(json.loads(v_AcqUpdate, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys),json.loads(v_Flow_1kpcqqf, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_0kvhy0o','SupervisonModelImagingController_WaitforPrepared_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelImagingController_WaitforPrepared_default_Gateway_0kvhy0o(json.loads(v_Flow_029nrs5, object_pairs_hook=Data().int_keys),json.loads(v_ImagingUpdate, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_05szwsj','SupervisonModelImagingController_UnprepareImaging_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelImagingController_UnprepareImaging_default_Flow_05szwsj(json.loads(v_Gateway_0i3nw09, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('ImagingRequest','SupervisonModelImagingController_UnprepareImaging_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelImagingController_UnprepareImaging_default_ImagingRequest(json.loads(v_Gateway_0i3nw09, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_1k04xzh','SupervisonModelImagingController_ImagingFinished_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelImagingController_ImagingFinished_default_Flow_1k04xzh(json.loads(v_Gateway_08l0os0, object_pairs_hook=Data().int_keys),json.loads(v_ImagingUpdate, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_1phqrfh','SupervisonModelVacuumController_SetVacuum_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelVacuumController_SetVacuum_default_Flow_1phqrfh(json.loads(v_Gateway_0mqr7c2, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('VacuumRequest','SupervisonModelVacuumController_SetVacuum_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelVacuumController_SetVacuum_default_VacuumRequest(json.loads(v_Gateway_0mqr7c2, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_16m9e4j','SupervisonModelSupervisionImaging_WaitforStopAcquisition_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelSupervisionImaging_WaitforStopAcquisition_default_Gateway_16m9e4j(json.loads(v_AcqUpdate, object_pairs_hook=Data().int_keys),json.loads(v_Flow_0678bm1, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('ImagingUpdate','SupervisonModelSupervisionImaging_WaitforStopAcquisition_default@null@INTERNAL@', Expression('Data().get_ImgResp()'))
        self.n.add_output('EqStatus','SupervisonModelSupervisionImaging_WaitforStopAcquisition_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelSupervisionImaging_WaitforStopAcquisition_default_EqStatus(json.loads(v_AcqUpdate, object_pairs_hook=Data().int_keys),json.loads(v_Flow_0678bm1, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_0gu94f4','SupervisonModelImagingController_WaitforUnprepareImaging_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelImagingController_WaitforUnprepareImaging_default_Gateway_0gu94f4(json.loads(v_Flow_05szwsj, object_pairs_hook=Data().int_keys),json.loads(v_ImagingUpdate, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_07w0e8f','SupervisonModelVacuumController_WaitforOff_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelVacuumController_WaitforOff_default_Gateway_07w0e8f(json.loads(v_VacuumUpdate, object_pairs_hook=Data().int_keys),json.loads(v_Flow_1dvvja5, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_0cjhiik','SupervisonModelSupervisionPressureHandler_TurnOffPump_default@null@COMPOSE@', Expression('Data().execute_SupervisonModelSupervisionPressureHandler_TurnOffPump_default_Flow_0cjhiik(json.loads(v_Flow_1wguswc, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys),json.loads(v_VacuumRequest, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('PumpRequest','SupervisonModelSupervisionPressureHandler_TurnOffPump_default@null@COMPOSE@', Expression('Data().execute_SupervisonModelSupervisionPressureHandler_TurnOffPump_default_PumpRequest(json.loads(v_Flow_1wguswc, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys),json.loads(v_VacuumRequest, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('EqStatus','SupervisonModelSupervisionPressureHandler_TurnOffPump_default@null@COMPOSE@', Expression('Data().execute_SupervisonModelSupervisionPressureHandler_TurnOffPump_default_EqStatus(json.loads(v_Flow_1wguswc, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys),json.loads(v_VacuumRequest, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_0x0gs9b','SupervisonModelPumpController_startpump_default@ExecPumpCommand@RUN@', Expression('Data().execute_SupervisonModelPumpController_startpump_default_Flow_0x0gs9b(json.loads(v_PumpRequest, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_1qk9wqe','SupervisonModelSupervisionTemperatureHandler_CreateResetTempMessage_default@null@COMPOSE@', Expression('Data().get_UNIT()'))
        self.n.add_output('TempCMD','SupervisonModelSupervisionTemperatureHandler_CreateResetTempMessage_default@null@COMPOSE@', Expression('Data().execute_SupervisonModelSupervisionTemperatureHandler_CreateResetTempMessage_default_TempCMD(json.loads(v_TempRequest, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('EqStatus','SupervisonModelSupervisionTemperatureHandler_CreateResetTempMessage_default@null@COMPOSE@', Expression('Data().execute_SupervisonModelSupervisionTemperatureHandler_CreateResetTempMessage_default_EqStatus(json.loads(v_TempRequest, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_0h81kts','SupervisonModelAcquisitionController_AcquisitionStarted_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelAcquisitionController_AcquisitionStarted_default_Gateway_0h81kts(json.loads(v_Flow_1rusz82, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('AcqUpdate','SupervisonModelAcquisitionController_AcquisitionStarted_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelAcquisitionController_AcquisitionStarted_default_AcqUpdate(json.loads(v_Flow_1rusz82, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_1kpcqqf','SupervisonModelSupervisionImagePreparation_Unprepare_default@null@COMPOSE@', Expression('Data().get_UNIT()'))
        self.n.add_output('AcquisitionReq','SupervisonModelSupervisionImagePreparation_Unprepare_default@null@COMPOSE@', Expression('Data().execute_SupervisonModelSupervisionImagePreparation_Unprepare_default_AcquisitionReq(json.loads(v_ImagingRequest, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_0ncxpgd','SupervisonModelImagingController_Stopimaging_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelImagingController_Stopimaging_default_Flow_0ncxpgd(json.loads(v_Flow_1k04xzh, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('ImagingRequest','SupervisonModelImagingController_Stopimaging_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelImagingController_Stopimaging_default_ImagingRequest(json.loads(v_Flow_1k04xzh, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_0qg69ul','SupervisonModelSupervisionImaging_WaitforStartAcquisition_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelSupervisionImaging_WaitforStartAcquisition_default_Gateway_0qg69ul(json.loads(v_AcqUpdate, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys),json.loads(v_Flow_1bajtwc, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('ImagingUpdate','SupervisonModelSupervisionImaging_WaitforStartAcquisition_default@null@INTERNAL@', Expression('Data().get_ImgResp()'))
        self.n.add_output('EqStatus','SupervisonModelSupervisionImaging_WaitforStartAcquisition_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelSupervisionImaging_WaitforStartAcquisition_default_EqStatus(json.loads(v_AcqUpdate, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys),json.loads(v_Flow_1bajtwc, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_084nmm6','SupervisonModelAcquisitionController_Execacquisitioninitandteardown_default@ExecAcquisitionCommand@RUN@', Expression('Data().execute_SupervisonModelAcquisitionController_Execacquisitioninitandteardown_default_Flow_084nmm6(json.loads(v_AcquisitionReq, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_01g3o4k','SupervisonModelTemperatureController_CheckTemp_default@TempCheck@ASSERT@', Expression('Data().execute_SupervisonModelTemperatureController_CheckTemp_default_Flow_01g3o4k(json.loads(v_Gateway_1sv33t8, object_pairs_hook=Data().int_keys),json.loads(v_temp_achieved, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_102q82v','SupervisonModelSupervisionImagePreparation_Waitforprepare_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelSupervisionImagePreparation_Waitforprepare_default_Gateway_102q82v(json.loads(v_Flow_0kkvgdv, object_pairs_hook=Data().int_keys),json.loads(v_AcqUpdate, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('ImagingUpdate','SupervisonModelSupervisionImagePreparation_Waitforprepare_default@null@INTERNAL@', Expression('Data().get_ImgResp()'))
        self.n.add_output('EqStatus','SupervisonModelSupervisionImagePreparation_Waitforprepare_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelSupervisionImagePreparation_Waitforprepare_default_EqStatus(json.loads(v_Flow_0kkvgdv, object_pairs_hook=Data().int_keys),json.loads(v_AcqUpdate, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_0xpxevh','SupervisonModelImagingController_returntoprep_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelImagingController_returntoprep_default_Gateway_0xpxevh(json.loads(v_Gateway_0gu94f4, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_1i0qy9g','SupervisonModelSupervisionPressureHandler_WaitforPumpOff_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelSupervisionPressureHandler_WaitforPumpOff_default_Gateway_1i0qy9g(json.loads(v_PumpUpdate, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys),json.loads(v_Flow_0cjhiik, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('VacuumUpdate','SupervisonModelSupervisionPressureHandler_WaitforPumpOff_default@null@INTERNAL@', Expression('Data().get_VacResp()'))
        self.n.add_output('EqStatus','SupervisonModelSupervisionPressureHandler_WaitforPumpOff_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelSupervisionPressureHandler_WaitforPumpOff_default_EqStatus(json.loads(v_PumpUpdate, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys),json.loads(v_Flow_0cjhiik, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_0balrow','SupervisonModelSupervisionPressureHandler_StartPump_default@null@COMPOSE@', Expression('Data().execute_SupervisonModelSupervisionPressureHandler_StartPump_default_Flow_0balrow(json.loads(v_EqStatus, object_pairs_hook=Data().int_keys),json.loads(v_VacuumRequest, object_pairs_hook=Data().int_keys),json.loads(v_Gateway_1j81da5, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('PumpRequest','SupervisonModelSupervisionPressureHandler_StartPump_default@null@COMPOSE@', Expression('Data().execute_SupervisonModelSupervisionPressureHandler_StartPump_default_PumpRequest(json.loads(v_EqStatus, object_pairs_hook=Data().int_keys),json.loads(v_VacuumRequest, object_pairs_hook=Data().int_keys),json.loads(v_Gateway_1j81da5, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('EqStatus','SupervisonModelSupervisionPressureHandler_StartPump_default@null@COMPOSE@', Expression('Data().execute_SupervisonModelSupervisionPressureHandler_StartPump_default_EqStatus(json.loads(v_EqStatus, object_pairs_hook=Data().int_keys),json.loads(v_VacuumRequest, object_pairs_hook=Data().int_keys),json.loads(v_Gateway_1j81da5, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_08l0os0','SupervisonModelImagingController_StartLowResImaging_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelImagingController_StartLowResImaging_default_Gateway_08l0os0(json.loads(v_Gateway_0kvhy0o, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('ImagingRequest','SupervisonModelImagingController_StartLowResImaging_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelImagingController_StartLowResImaging_default_ImagingRequest(json.loads(v_Gateway_0kvhy0o, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_0h81kts','SupervisonModelAcquisitionController_Acquisitionexecdone_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelAcquisitionController_Acquisitionexecdone_default_Gateway_0h81kts(json.loads(v_Flow_084nmm6, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('AcqUpdate','SupervisonModelAcquisitionController_Acquisitionexecdone_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelAcquisitionController_Acquisitionexecdone_default_AcqUpdate(json.loads(v_Flow_084nmm6, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_0mqr7c2','SupervisonModelVacuumController_return_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelVacuumController_return_default_Gateway_0mqr7c2(json.loads(v_Gateway_07w0e8f, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_104f6k4','SupervisonModelPumpController_stoppump_default@ExecPumpCommand@RUN@', Expression('Data().execute_SupervisonModelPumpController_stoppump_default_Flow_104f6k4(json.loads(v_PumpRequest, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_08l0os0','SupervisonModelImagingController_StartHighResImaging_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelImagingController_StartHighResImaging_default_Gateway_08l0os0(json.loads(v_Gateway_0kvhy0o, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('ImagingRequest','SupervisonModelImagingController_StartHighResImaging_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelImagingController_StartHighResImaging_default_ImagingRequest(json.loads(v_Gateway_0kvhy0o, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_029nrs5','SupervisonModelImagingController_PrepareImaging_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelImagingController_PrepareImaging_default_Flow_029nrs5(json.loads(v_Gateway_0xpxevh, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('ImagingRequest','SupervisonModelImagingController_PrepareImaging_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelImagingController_PrepareImaging_default_ImagingRequest(json.loads(v_Gateway_0xpxevh, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_0678bm1','SupervisonModelSupervisionImaging_StopAcquisition_default@null@COMPOSE@', Expression('Data().get_UNIT()'))
        self.n.add_output('AcquisitionReq','SupervisonModelSupervisionImaging_StopAcquisition_default@null@COMPOSE@', Expression('Data().execute_SupervisonModelSupervisionImaging_StopAcquisition_default_AcquisitionReq(json.loads(v_ImagingRequest, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_0td58pc','SupervisonModelPumpController_pumpstopped_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelPumpController_pumpstopped_default_Gateway_0td58pc(json.loads(v_Flow_104f6k4, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('PumpUpdate','SupervisonModelPumpController_pumpstopped_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelPumpController_pumpstopped_default_PumpUpdate(json.loads(v_Flow_104f6k4, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_1erv6vq','SupervisonModelVacuumController_WaitforVacuumSet_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelVacuumController_WaitforVacuumSet_default_Flow_1erv6vq(json.loads(v_VacuumUpdate, object_pairs_hook=Data().int_keys),json.loads(v_Flow_1phqrfh, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_1sv33t8','SupervisonModelTemperatureController_return_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelTemperatureController_return_default_Gateway_1sv33t8(json.loads(v_Gateway_12yhscn, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_1j81da5','SupervisonModelSupervisionPressureHandler_Restart_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelSupervisionPressureHandler_Restart_default_Gateway_1j81da5(json.loads(v_Gateway_1i0qy9g, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_0i3nw09','SupervisonModelImagingController_WaitforImagingStopped_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelImagingController_WaitforImagingStopped_default_Gateway_0i3nw09(json.loads(v_Flow_0ncxpgd, object_pairs_hook=Data().int_keys),json.loads(v_ImagingUpdate, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_0h81kts','SupervisonModelAcquisitionController_AcquisitionStopped_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelAcquisitionController_AcquisitionStopped_default_Gateway_0h81kts(json.loads(v_Flow_1w9tlf4, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('AcqUpdate','SupervisonModelAcquisitionController_AcquisitionStopped_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelAcquisitionController_AcquisitionStopped_default_AcqUpdate(json.loads(v_Flow_1w9tlf4, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_0qg69ul','SupervisonModelSupervisionImaging_CheckHighResImageQuality_default@CheckAcquisitionResult@ASSERT@', Expression('Data().execute_SupervisonModelSupervisionImaging_CheckHighResImageQuality_default_Gateway_0qg69ul(json.loads(v_ImageData, object_pairs_hook=Data().int_keys),json.loads(v_Gateway_16m9e4j, object_pairs_hook=Data().int_keys),json.loads(v_LastAcqReq, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_1qk9wqe','SupervisonModelSupervisionTemperatureHandler_CreateSetTempMessage_default@null@COMPOSE@', Expression('Data().get_UNIT()'))
        self.n.add_output('TempCMD','SupervisonModelSupervisionTemperatureHandler_CreateSetTempMessage_default@null@COMPOSE@', Expression('Data().execute_SupervisonModelSupervisionTemperatureHandler_CreateSetTempMessage_default_TempCMD(json.loads(v_TempRequest, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_1rusz82','SupervisonModelAcquisitionController_StartAcquisition_default@ExecAcquisitionCommand@RUN@', Expression('Data().execute_SupervisonModelAcquisitionController_StartAcquisition_default_Flow_1rusz82(json.loads(v_AcquisitionReq, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Event_13ys7sy','SupervisonModelSupervisionTemperatureHandler_ExecuteSetTemp_default@SetTemperature@RUN@', Expression('Data().execute_SupervisonModelSupervisionTemperatureHandler_ExecuteSetTemp_default_Event_13ys7sy(json.loads(v_Gateway_1qk9wqe, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys),json.loads(v_TempCMD, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('TempUpdate','SupervisonModelSupervisionTemperatureHandler_ExecuteSetTemp_default@SetTemperature@RUN@', Expression('Data().get_TempResp()'))
        self.n.add_output('temp_achieved','SupervisonModelSupervisionTemperatureHandler_ExecuteSetTemp_default@SetTemperature@RUN@', Expression('Data().execute_SupervisonModelSupervisionTemperatureHandler_ExecuteSetTemp_default_temp_achieved(json.loads(v_Gateway_1qk9wqe, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys),json.loads(v_TempCMD, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('EqStatus','SupervisonModelSupervisionTemperatureHandler_ExecuteSetTemp_default@SetTemperature@RUN@', Expression('Data().execute_SupervisonModelSupervisionTemperatureHandler_ExecuteSetTemp_default_EqStatus(json.loads(v_Gateway_1qk9wqe, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys),json.loads(v_TempCMD, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_1dvvja5','SupervisonModelVacuumController_TurnOff_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelVacuumController_TurnOff_default_Flow_1dvvja5(json.loads(v_Flow_1erv6vq, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('VacuumRequest','SupervisonModelVacuumController_TurnOff_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelVacuumController_TurnOff_default_VacuumRequest(json.loads(v_Flow_1erv6vq, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_1wguswc','SupervisonModelSupervisionPressureHandler_WaitforPumpStated_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelSupervisionPressureHandler_WaitforPumpStated_default_Flow_1wguswc(json.loads(v_PumpUpdate, object_pairs_hook=Data().int_keys),json.loads(v_Flow_0balrow, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('VacuumUpdate','SupervisonModelSupervisionPressureHandler_WaitforPumpStated_default@null@INTERNAL@', Expression('Data().get_VacResp()'))
        self.n.add_output('EqStatus','SupervisonModelSupervisionPressureHandler_WaitforPumpStated_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelSupervisionPressureHandler_WaitforPumpStated_default_EqStatus(json.loads(v_PumpUpdate, object_pairs_hook=Data().int_keys),json.loads(v_Flow_0balrow, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_0estwso','SupervisonModelTemperatureController_SetTemperature_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelTemperatureController_SetTemperature_default_Flow_0estwso(json.loads(v_Event_1r2zvr6, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('TempRequest','SupervisonModelTemperatureController_SetTemperature_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelTemperatureController_SetTemperature_default_TempRequest(json.loads(v_Event_1r2zvr6, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_0kkvgdv','SupervisonModelSupervisionImagePreparation_Prepare_default@null@COMPOSE@', Expression('Data().get_UNIT()'))
        self.n.add_output('AcquisitionReq','SupervisonModelSupervisionImagePreparation_Prepare_default@null@COMPOSE@', Expression('Data().execute_SupervisonModelSupervisionImagePreparation_Prepare_default_AcquisitionReq(json.loads(v_ImagingRequest, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('EqStatus','SupervisonModelSupervisionImagePreparation_Prepare_default@null@COMPOSE@', Expression('Data().execute_SupervisonModelSupervisionImagePreparation_Prepare_default_EqStatus(json.loads(v_ImagingRequest, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_12yhscn','SupervisonModelTemperatureController_WaitforReset_default@null@INTERNAL@', Expression('Data().execute_SupervisonModelTemperatureController_WaitforReset_default_Gateway_12yhscn(json.loads(v_Flow_0ay6jpo, object_pairs_hook=Data().int_keys),json.loads(v_TempUpdate, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_1bajtwc','SupervisonModelSupervisionImaging_StartAcquisition_default@null@COMPOSE@', Expression('Data().get_UNIT()'))
        self.n.add_output('AcquisitionReq','SupervisonModelSupervisionImaging_StartAcquisition_default@null@COMPOSE@', Expression('Data().execute_SupervisonModelSupervisionImaging_StartAcquisition_default_AcquisitionReq(json.loads(v_ImagingRequest, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('LastAcqReq','SupervisonModelSupervisionImaging_StartAcquisition_default@null@COMPOSE@', Expression('Data().execute_SupervisonModelSupervisionImaging_StartAcquisition_default_LastAcqReq(json.loads(v_ImagingRequest, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('EqStatus','SupervisonModelSupervisionImaging_StartAcquisition_default@null@COMPOSE@', Expression('Data().execute_SupervisonModelSupervisionImaging_StartAcquisition_default_EqStatus(json.loads(v_ImagingRequest, object_pairs_hook=Data().int_keys),json.loads(v_EqStatus, object_pairs_hook=Data().int_keys))'))
        self.stepsList.append(self.n.get_marking())
    
    def loadScenario(self, scenario):
        self.map_transition_filter = scenario
        print('[INFO] Loaded scenario with ' + str(len(self.map_transition_filter)) + ' steps.')
        self.gotoMarking(0)
    
    def getCurrentMarking(self):
        # print('[INFO] Current Marking: ', self.n.get_marking())
        return self.n.get_marking()
    
    # Deprecated, use gotoMarking
    def saveMarking(self):
        self.markedIndex = len(self.stepsList) - 1
        print('[INFO] Save petri net marking', self.markedIndex)
    
    # Deprecated, use gotoMarking
    def gotoSavedMarking(self):
        print('[INFO] Setting petri net to saved marking')
        self.gotoMarking(self.markedIndex)
    
    def gotoMarking(self, index):
        print('[INFO] Setting petri net to marking', index)
        self.n.set_marking(self.stepsList[index])
        self.stepsList = self.stepsList[:index + 1]
    
    def fireEnabledTransition(self, choices, cid):
        transition, mode = choices.get(int(cid))
        flow = transition.flow(mode)
        transition.fire(mode)
        # print('[INFO] Transition Fired with ID: ', cid)
        self.stepsList.append(self.n.get_marking())
        return flow
    
    def getEnabledTransitions(self):
        choices = {}
        stepIndex = len(self.stepsList)
        stepFilter = None
        if len(self.map_transition_filter) > 0:
            if str(stepIndex) in self.map_transition_filter:
                stepFilter = self.map_transition_filter[str(stepIndex)]
            else:
                print('[INFO] End of scenario reached at step:', stepIndex)
                return choices
        chidx = 0
        for transition in self.getPNPriorityEnabledTransitions():
            for mode in transition.modes():
                if stepFilter is None or (_key.name == stepFilter['transition'] and _elm.dict() == stepFilter['substitution']):
                    choices[chidx] = transition, mode
                    chidx = chidx + 1
        if stepFilter and (len(choices) == 0):
            print('[ERROR] Scenario step is not available: ', stepIndex)
            raise RuntimeError('Scenario step is not available: ' + str(stepIndex))
        # print('[INFO] Enabled Transition Choices: ', choices)
        return choices
    
    # Only return the enabled transitions with the highest priority
    def getPNPriorityEnabledTransitions(self):
        priority = None
        priorityTransitions = []
        for transition in self.n.transition():
            if transition.modes():
                if priority is None or transition.priority > priority:
                    priority = transition.priority
                    priorityTransitions = []
                if transition.priority == priority:
                    priorityTransitions.append(transition)
        return priorityTransitions
    
    def generateSCN(self, level = 0, visitedT = None, visitedTP = None):
        if self.numTestCases >= 1:
            # print(' [RG-INFO] Max test cases reached! Terminating path.')
            return
        if level > 300:
            self.visitedTList.append(list(visitedT))
            self.visitedTProdList.append(list(visitedTP))
            self.numTestCases = self.numTestCases + 1
            # print(' [RG-INFO] Depth limit reached! Terminating path.')
            return
        if not visitedT:
            visitedT = []
        if not visitedTP:
            visitedTP = []
    
        enabled_transitions = self.getPNPriorityEnabledTransitions()
        if enabled_transitions:
            currM = self.n.get_marking()
            for t in enabled_transitions:
                for m in t.modes():
                    visitedT.append((0,t,m))
                    visitedTP.append(t.flow(m)[1])
                    t.fire(m)
                    self.n.get_marking()
                    self.generateSCN(level + 1, visitedT.copy(), visitedTP.copy())
                    del visitedT[-1]
                    del visitedTP[-1]
                    self.n.set_marking(currM)
        else:
            # print('[RG-INFO] Dead marking found.')
            self.visitedTList.append(list(visitedT))
            self.visitedTProdList.append(list(visitedTP))
            self.numTestCases = self.numTestCases + 1
            return
    
    def generateReachabilityGraph(self, writer, state_space = None, currIndex = 0, level = 0):
        nrOfDependencies = 0
        initial = not state_space
        if initial:
            writer.write('@startuml\n')
            state_space = [self.n.get_marking()]
        elif level > 300:
            writer.write('(%s) #red\n' % (currIndex,))
            print(' [RG-INFO] Depth limit reached! Terminating path.')
            return nrOfDependencies
        elif len(state_space) > 1000:
            writer.write('(%s) #red\n' % (currIndex,))
            print(' [RG-INFO] State-space limit reached! Terminating path.')
            return nrOfDependencies
    
        enabledTransitions = self.getPNPriorityEnabledTransitions()
        if enabledTransitions:
            mark = len([t for t in self.n.transition() if t.modes()]) != len(enabledTransitions)
            currMarking = state_space[currIndex]
            for transition in enabledTransitions:
                transitionLabel = transition.name.split('_default@')[0]
                for mode in transition.modes():
                    transition.fire(mode)
                    nextMarking = self.n.get_marking()
                    if nextMarking in state_space:
                        nextIndex = state_space.index(nextMarking)
                        writer.write('(%s) -%s-> (%s): %s\n' % (currIndex, "[#darkorange]" if mark else "", nextIndex, transitionLabel))
                        nrOfDependencies += 1
                    else:
                        nextIndex = len(state_space)
                        state_space.append(nextMarking)
                        writer.write('(%s) -%s-> (%s): %s\n' % (currIndex, "[#darkorange]" if mark else "", nextIndex, transitionLabel))
                        nrOfDependencies += 1 + self.generateReachabilityGraph(writer, state_space, nextIndex, level + 1)
                    self.n.set_marking(currMarking)
    
        if initial:
            writer.write('title State space: %d nodes and %d edges\n' % (len(state_space), nrOfDependencies))
            writer.write('@enduml\n')
    
        return nrOfDependencies
    
    def initializeTestGeneration(self):
        self.sutVarTransitionMap = {}
        # map_of_transition_modes = {}
        for entry in self.visitedTList:
            if entry:
                for step in entry:
                    if step[1].name in self.map_of_transition_modes:
                        self.map_of_transition_modes.get(step[1].name).append(step[2])
                    else:
                        self.map_of_transition_modes[step[1].name] = [step[2]]
        # map_transition_modes_to_name = {}
        cnt = 0
        for k,v in self.map_of_transition_modes.items():
            # print(k)
            cnt = 0
            # modes = set(v)
            for elm in v: # modes
                # print(elm)
                if k + "_" +elm.__repr__() in self.map_transition_modes_to_name:
                    print("WARN: duplicate modes detected for same transition.")
                    print(k + "_" +elm.__repr__())
                    print("WARN: references to the above transitions are ambigous!")
                self.map_transition_modes_to_name[k + "_" +elm.__repr__()] = k + "_" + str(cnt)
                # self.map_transition_modes_to_name[k + "_" + pprint.pformat(elm.items(), width=60, compact=True,depth=5)] = k + "_" + str(cnt)
                cnt = cnt + 1
        _txt = []
        constraint_list = []
        # tr_assert_ref_dict = {}
        # map_transition_assert = {}
        self.tr_assert_ref_dict["SupervisonModelSupervisionImaging_CheckLowResImageQuality_default@CheckAcquisitionResult@ASSERT@"] = "imaging.SupervisonModelSupervisionImaging.CheckLowResImageQuality.default.default"
        self.tr_assert_ref_dict["SupervisonModelTemperatureController_CheckTemp_default@TempCheck@ASSERT@"] = "imaging.SupervisonModelTemperatureController.CheckTemp.default.default"
        self.tr_assert_ref_dict["SupervisonModelSupervisionImaging_CheckHighResImageQuality_default@CheckAcquisitionResult@ASSERT@"] = "imaging.SupervisonModelSupervisionImaging.CheckHighResImageQuality.default.default"
        self.map_transition_assert = {'SupervisonModelSupervisionTemperatureHandler_CreateResetTempMessage_default@null@COMPOSE@': ['TempCMD','EqStatus'],'SupervisonModelAcquisitionController_StopAcquisition_default@ExecAcquisitionCommand@RUN@': ['ImageData'],'SupervisonModelSupervisionImagePreparation_Unprepare_default@null@COMPOSE@': ['AcquisitionReq'],'SupervisonModelSupervisionTemperatureHandler_ExecuteSetTemp_default@SetTemperature@RUN@': ['temp_achieved','EqStatus'],'SupervisonModelSupervisionPressureHandler_TurnOffPump_default@null@COMPOSE@': ['PumpRequest','EqStatus'],'SupervisonModelSupervisionImaging_StopAcquisition_default@null@COMPOSE@': ['AcquisitionReq'],'SupervisonModelSupervisionTemperatureHandler_CreateSetTempMessage_default@null@COMPOSE@': ['TempCMD'],'SupervisonModelSupervisionImagePreparation_Prepare_default@null@COMPOSE@': ['AcquisitionReq','EqStatus'],'SupervisonModelSupervisionPressureHandler_StartPump_default@null@COMPOSE@': ['PumpRequest','EqStatus'],'SupervisonModelSupervisionImaging_StartAcquisition_default@null@COMPOSE@': ['AcquisitionReq','LastAcqReq','EqStatus']}
    
    def generateTestCases(self):
        i = 0
        j = 0
        idx = 0
        _tests = Tests()
        
        for entry in pn.visitedTList:
            # txt = ''
            if entry:
                _test_scn = TestSCN(self.map_transition_assert, self.constraint_dict, self.tr_assert_ref_dict)
                idx = idx + 1
                j = 0
                for step in entry:
                    stp = step[1].name + "_" + step[2].__repr__()
                    step_txt = self.map_transition_modes_to_name[stp] 
                    if step_txt.rsplit("_",1)[0].split("@",1)[0] in self.listOfSUTActions:
                        # if not step_txt.split("_")[0] in self.listOfEnvBlocks:
                            # _step = Step(step_txt.rsplit("_",1)[0].split("@",1)[0] in self.listOfSUTActions)
                        # else:
                            # _step = Step(False)
                        _step = Step(False)
                        _step.step_name = self.map_transition_modes_to_name[stp]
                        for x,y in step[2].dict().items():
                            _step.input_data[x.replace("v_", "", 1)] = json.dumps(json.loads(y), indent=4, sort_keys=True)
                        for x,y in self.visitedTProdList[i][j].items():
                            for z in y.items():
                                #if step_txt.split("@")[0] in self.mapOfSuppressTransitionVars:
                                #    if x not in self.mapOfSuppressTransitionVars[step_txt.split("@")[0]]:
                                #        _step.output_data[x] = json.dumps(json.loads(z), indent=4, sort_keys=True)
                                #else:
                                _step.output_data[x] = json.dumps(json.loads(z), indent=4, sort_keys=True)
                        if step_txt.split("@")[0] in self.mapOfSuppressTransitionVars:
                            _step.output_suppress = self.mapOfSuppressTransitionVars[step_txt.split("@")[0]]
                        _test_scn.step_list.append(_step)
                    j = j + 1
                _test_scn.compute_dependencies()
                _test_scn.generate_viz(i, output_dir=p.plantuml_dir)
                _test_scn.generateJSON(i, entry, output_dir=p.tspec_dir)
                _test_scn.generateTSpec(i, pn.sutTypesList, pn.sutVarTransitionMap, pn.mapOfTransitionQnames, output_dir=p.tspec_dir)
                _tests.list_of_test_scn.append(_test_scn)
            i = i + 1
    
    def chunkstring(self, string, length):
        return (string[0+i:length+i] for i in range(0, len(string), length))
        
    def determineInterfacePlaces(self):
        intfP = InterfacePlaces()
        for p in self.n.place():
            if not self.n.pre([str(p)]):
                # print(" - " + str(p) + " -> source")
                intfP.input.append(str(p))
            if not self.n.post([str(p)]):
                # print(" - " + str(p) + " -> dest")
                intfP.output.append(str(p))
        return intfP


class InterfacePlaces:
    def __init__(self):
        self.input = []
        self.output = []


class PrioritizedTransition(Transition):
    def __init__ (self, name, priority=0, guard=None):
        super().__init__(name, guard)
        self.priority = priority

    def priority(self):
        return self.priority
    
    def copy(self, name=None):
        if name is None:
            name = self.name
        return self.__class__(name, self.priority, self.guard.copy())


if __name__ == '__main__':
    # check if there is custom output directory
    parser = argparse.ArgumentParser(
                    prog='ProgramName',
                    description='What the program does',
                    epilog='Text at the bottom of help')
    parser.add_argument("-tsdir","--tspec_dir",
                        type=Path,
                        default="generated_scenarios",
                        help="The directory in which tspec files produced will be saved")
    
    parser.add_argument("-pudir","--plantuml_dir",
                        type=Path,
                        default=os.getcwd(),
                        help="The directory in which plantuml files produced will be saved")
    
    parser.add_argument("-no_sim",
                        type=bool,
                        default=False,
                        help="Disable simulation")
    
    p = parser.parse_args()
    p.tspec_dir.mkdir(exist_ok=True)
    p.plantuml_dir.mkdir(exist_ok=True)
    
    a = datetime.datetime.now()
    pn = imagingModel()
    print("[INFO] Loaded CPN model.")
    # pn.n.draw('net-gv-graph.png')
    s = StateGraph(pn.n)
    # s.build()
    # s.draw('test-gv-graph.png')
    # print(" Finished Generation, writing to file.. ")
    print("[INFO] Starting Reachability Graph Generation")
    # pn.generateScenarios(s,0,[],[],[],0,300)
    sys.setrecursionlimit(400)
    pn.generateSCN()
    print('Num Tests: ', pn.numTestCases)
    print("[INFO] Finished.")
    b = datetime.datetime.now()

    # s.goto(0)
    
    fname = p.plantuml_dir / "rg.plantuml"
    with open(fname, 'w') as f:
        pn.generateReachabilityGraph(f)
        print("[INFO] Created %s" % (fname,))
    c = datetime.datetime.now()

    print("[INFO] Starting Test Generation.")
    pn.initializeTestGeneration()
    pn.generateTestCases()
    
    # print('[INFO] Number-of-generated-scenario files: ',len(pn.visitedTList))
    print("[INFO] Test Generation Finished.")
    d = datetime.datetime.now()
    
    print("[INFO] Creating Structure and Behavior Views in PlantUML.")
    map_block_uml_txt = {}
    for t in pn.n.transition():
        map_block_uml_txt[t.name.split('_')[0]] = '@startuml\n'
        
    for t in pn.n.transition():
        gtxt = map_block_uml_txt.get(t.name.split('_')[0])
        if 'json.loads' in t.guard._str:
            # print(t.guard._str.replace('json.loads',''))
            # print('\n'.join(list(pn.chunkstring(t.guard._str.replace('json.loads','').replace(', object_pairs_hook=Data().int_keys', ''),55))))
            gtxt += 'component %s\n' % (t.name)
            if len(list(pn.chunkstring(t.guard._str.replace('json.loads','').replace(', object_pairs_hook=Data().int_keys', ''),68))) <= 2:
                gtxt += 'note left of [%s]\n %s\nendnote\n' % (t.name, '\n'.join(list(pn.chunkstring(t.guard._str.replace('json.loads','').replace(', object_pairs_hook=Data().int_keys', ''),55))))
            else:
                gtxt += 'note bottom of [%s]\n %s\nendnote\n' % (t.name, '\n'.join(list(pn.chunkstring(t.guard._str.replace('json.loads','').replace(', object_pairs_hook=Data().int_keys', ''),55))))
        else:
            gtxt += 'component %s\n' % (t.name)
            gtxt += 'note right of [%s]\n %s\nendnote\n' % (t.name, t.guard)
        map_block_uml_txt[t.name.split('_')[0]] = gtxt
        
    for t in pn.n.transition():
        for inp in pn.n.pre(t.name):
            txt = map_block_uml_txt.get(t.name.split('_')[0])
            if 'local' in inp:
                txt += '%s -[#lightgrey]-> [%s]\n' % (inp, t.name)
            else:
                txt += '%s --> [%s]\n' % (inp, t.name)
            map_block_uml_txt[t.name.split('_')[0]] = txt
        for out in pn.n.post(t.name):
            txt = map_block_uml_txt.get(t.name.split('_')[0])
            if 'local' in out:
                txt += '[%s] -[#lightgrey]-> %s\n' % (t.name, out)
            else:
                txt += '[%s] --> %s\n' % (t.name, out)
            map_block_uml_txt[t.name.split('_')[0]] = txt
    
    for key in map_block_uml_txt:
        txt = map_block_uml_txt.get(key)
        txt += '@enduml\n'
        map_block_uml_txt[key] = txt
        fname = p.plantuml_dir / (key + ".plantuml")
        with open(fname, 'w') as f:
            f.write(txt)
    
    print("[INFO] View Generation Finished.")
    e = datetime.datetime.now()
    print("[INFO] Time Statistics")
    print("[INFO]    * Reachability Computation: %s" % (b - a))
    print("[INFO]    * Reachability PUML Creation: %s" % (c - b))
    print("[INFO]    * Test Generation: %s" % (d - c))
    print("[INFO]    * PlantUML View Generation: %s" % (e - d))
    
    # print("[INFO] Starting Command-Line Simulation.")
    # simulate(pn.n)
    
    #if not p.no_sim:
    #    print('[SIM] Start Simulation? (Y/N) :')
    #    value = input(" Enter Choice: ")
    #    if value == "Y" or value == "y":
    #        os.system('cls')
    #        simulate(pn.n)
    
    print("[INFO] Exiting..")
