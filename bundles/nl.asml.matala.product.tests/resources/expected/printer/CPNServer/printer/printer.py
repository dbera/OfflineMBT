import datetime
import json
import pprint
import argparse
import random
from pathlib import Path

from snakes.nets import *

if __package__ is None or __package__ == '':
    from printer_TestSCN import TestSCN, Step, Tests, Constraint, CEntry
    from printer_data import Data
    from printer_Simulation import Simulation, simulate
else:
    from .printer_TestSCN import TestSCN, Step, Tests, Constraint, CEntry
    from .printer_data import Data
    from .printer_Simulation import Simulation, simulate
import subprocess
import copy
import os

snakes.plugins.load('gv', 'snakes.nets', 'nets')
from nets import *
# from CPNServer.utils import AbstractCPNControl


class printerModel:
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
        self.listOfEnvBlocks = ["PrintFactoryA3DPrinter","PrintFactoryInspection","PrintFactoryOptimization"]
        self.listOfSUTActions = ["PrintFactoryA3DPrinter_RunPrintJob_default","PrintFactoryA3DPrinter_ComposePrintJob_default","PrintFactoryA3DPrinter_ComposePrepareJob_default","PrintFactoryA3DPrinter_RunPrepareJob_default","PrintFactoryInspection_RunVisualinspection_default","PrintFactoryInspection_ComposeVisualInspectionJob_default","PrintFactoryOptimization_ComposeOptimizationJob_default","PrintFactoryOptimization_RunOptimizationJob_default","PrintFactoryFactoryAutomation_AssertVisualInspection_default"]
        self.mapOfSuppressTransitionVars = {'PrintFactoryOptimization_RunOptimizationJob_default': ['Event_1oozdnw'],'PrintFactoryInspection_ComposeVisualInspectionJob_default': ['Flow_07l0yyj','printReport'],'PrintFactoryA3DPrinter_ComposePrepareJob_default': ['Flow_0iaelzn'],'PrintFactoryOptimization_ComposeOptimizationJob_default': ['Flow_0y8u5pd','inspectionReport'],'PrintFactoryA3DPrinter_RunPrepareJob_default': ['Event_0mxx05p'],'PrintFactoryA3DPrinter_ComposePrintJob_default': ['Flow_1u2qmtt'],'PrintFactoryA3DPrinter_RunPrintJob_default': ['Event_0jcg6zx']}
        self.mapOfTransitionQnames = {'PrintFactoryA3DPrinter_RunPrintJob_default': 'printer.PrintFactoryA3DPrinter.RunPrintJob.default','PrintFactoryA3DPrinter_ComposePrintJob_default': 'printer.PrintFactoryA3DPrinter.ComposePrintJob.default','PrintFactoryA3DPrinter_ComposePrepareJob_default': 'printer.PrintFactoryA3DPrinter.ComposePrepareJob.default','PrintFactoryA3DPrinter_RunPrepareJob_default': 'printer.PrintFactoryA3DPrinter.RunPrepareJob.default','PrintFactoryInspection_RunVisualinspection_default': 'printer.PrintFactoryInspection.RunVisualinspection.default','PrintFactoryInspection_ComposeVisualInspectionJob_default': 'printer.PrintFactoryInspection.ComposeVisualInspectionJob.default','PrintFactoryOptimization_ComposeOptimizationJob_default': 'printer.PrintFactoryOptimization.ComposeOptimizationJob.default','PrintFactoryOptimization_RunOptimizationJob_default': 'printer.PrintFactoryOptimization.RunOptimizationJob.default','PrintFactoryFactoryAutomation_AssertVisualInspection_default': 'printer.PrintFactoryFactoryAutomation.AssertVisualInspection.default'}
        self.n = PetriNet('printer')
        self.n.globals["Data"] = Data
        self.n.globals.declare("import json")
        self.n.add_place(Place('printJob'))
        self.n.add_place(Place('corrections'))
        self.n.add_place(Place('printResult'))
        self.n.add_place(Place('printReport'))
        self.n.add_place(Place('request'))
        self.n.add_place(Place('Event_0mxx05p'))
        self.n.add_place(Place('Event_0jcg6zx'))
        self.n.add_place(Place('Flow_1u2qmtt'))
        self.n.add_place(Place('Flow_0iaelzn'))
        self.n.add_place(Place('inspectionJob'))
        self.n.add_place(Place('inspectionReport'))
        self.n.add_place(Place('inspectionResult'))
        self.n.add_place(Place('measureRequest'))
        self.n.add_place(Place('Flow_07l0yyj'))
        self.n.add_place(Place('optJob'))
        self.n.add_place(Place('optResult'))
        self.n.add_place(Place('optimizeJob'))
        self.n.add_place(Place('Event_1oozdnw'))
        self.n.add_place(Place('Flow_0y8u5pd'))
        self.n.add_place(Place('printRequests'))
        self.n.add_place(Place('Gateway_0p2uo9v'))
        self.n.add_place(Place('Gateway_1wpvmtk'))
        self.n.add_place(Place('Flow_16s4ey1'))
        self.n.add_place(Place('Flow_1dcdx0e'))
        self.n.add_place(Place('Flow_1dt29vl'))
        self.n.add_place(Place('Flow_0kbycuh'))
        self.n.add_place(Place('Flow_01m2s0h'))
        self.n.add_place(Place('Flow_09b0flo'))
        self.n.add_place(Place('Flow_1rkhqnd'))
        self.n.add_place(Place('Flow_1vq9t2p'))
        self.n.add_place(Place('Flow_0fe8hce'))
        self.n.add_place(Place('Flow_1y4bjf4'))
        self.n.add_place(Place('Flow_1f74bn4'))
        self.n.place('Gateway_1wpvmtk').empty()
        self.n.place('Gateway_1wpvmtk').add(json.dumps({"id": 1, "resolution": "PrintResolution::LOW", "scale": 0.0, "color": "ColorType::MONOCHROME"}))
        self.n.place('printRequests').empty()
        self.n.place('printRequests').add(json.dumps({"id": 1, "resolution": "PrintResolution::LOW", "scale": 50.0, "color": "ColorType::MONOCHROME", "opType": "OperationType::PRINT"}))
        self.n.place('printRequests').add(json.dumps({"id": 2, "resolution": "PrintResolution::MED", "scale": 75.0, "color": "ColorType::COLOR", "opType": "OperationType::PRINT"}))
        self.n.place('printRequests').add(json.dumps({"id": 3, "resolution": "PrintResolution::HIGH", "scale": 75.0, "color": "ColorType::COLOR", "opType": "OperationType::PRINT"}))
        self.n.place('corrections').empty()
        self.n.place('corrections').add(json.dumps({"id": 1, "correctionsMap": {0: [{"data": "X"}, {"data": "Y"}], 1: [{"data": "A"}, {"data": "B"}]}}))
        self.n.add_transition(PrioritizedTransition('PrintFactoryA3DPrinter_RunPrintJob_default@ExecutePrinter@RUN@', 0))
        self.n.add_transition(PrioritizedTransition('PrintFactoryA3DPrinter_ComposePrintJob_default@null@COMPOSE@', 0, Expression('json.loads(v_corrections, object_pairs_hook=Data().int_keys)["id"] == json.loads(v_printJob, object_pairs_hook=Data().int_keys)["id"] and json.loads(v_printJob, object_pairs_hook=Data().int_keys)["opType"] == "OperationType::PRINT"')))
        self.n.add_transition(PrioritizedTransition('PrintFactoryA3DPrinter_ComposePrepareJob_default@null@COMPOSE@', 0, Expression('json.loads(v_printJob, object_pairs_hook=Data().int_keys)["opType"] == "OperationType::PREP"')))
        self.n.add_transition(PrioritizedTransition('PrintFactoryA3DPrinter_RunPrepareJob_default@ExecutePrinter@RUN@', 0))
        self.n.add_transition(PrioritizedTransition('PrintFactoryInspection_RunVisualinspection_default@ExecuteInspection@RUN@', 0))
        self.n.add_transition(PrioritizedTransition('PrintFactoryInspection_ComposeVisualInspectionJob_default@null@COMPOSE@', 0, Expression('json.loads(v_printReport, object_pairs_hook=Data().int_keys)["id"] == json.loads(v_inspectionJob, object_pairs_hook=Data().int_keys)["id"]')))
        self.n.add_transition(PrioritizedTransition('PrintFactoryOptimization_ComposeOptimizationJob_default@null@COMPOSE@', 0, Expression('json.loads(v_inspectionReport, object_pairs_hook=Data().int_keys)["id"] == json.loads(v_optJob, object_pairs_hook=Data().int_keys)["id"]')))
        self.n.add_transition(PrioritizedTransition('PrintFactoryOptimization_RunOptimizationJob_default@ExecuteOptimizer@RUN@', 0))
        self.n.add_transition(PrioritizedTransition('PrintFactoryFactoryAutomation_SendPrintJob_default@null@INTERNAL@', 0, Expression('json.loads(v_printRequests, object_pairs_hook=Data().int_keys)["id"] == json.loads(v_Gateway_1wpvmtk, object_pairs_hook=Data().int_keys)["id"]')))
        self.n.add_transition(PrioritizedTransition('PrintFactoryFactoryAutomation_NextJob_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('PrintFactoryFactoryAutomation_WaitforOptimizationJob_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('PrintFactoryFactoryAutomation_Gateway_1f8wap6_default@null@INTERNAL@', 0, Expression('json.loads(v_Flow_1vq9t2p, object_pairs_hook=Data().int_keys) == json.loads(v_Flow_09b0flo, object_pairs_hook=Data().int_keys)')))
        self.n.add_transition(PrioritizedTransition('PrintFactoryFactoryAutomation_Gateway_1j3rupx_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('PrintFactoryFactoryAutomation_WaitforVisualInspection_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('PrintFactoryFactoryAutomation_SendOptimizationJob_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('PrintFactoryFactoryAutomation_PreparePrinter_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('PrintFactoryFactoryAutomation_AssertVisualInspection_default@Assert_Visual_Inspection@ASSERT@', 0))
        self.n.add_transition(PrioritizedTransition('PrintFactoryFactoryAutomation_SendVisualInspectionJob_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('PrintFactoryFactoryAutomation_WaitforPrepare_default@null@INTERNAL@', 0))
        self.n.add_transition(PrioritizedTransition('PrintFactoryFactoryAutomation_WaitforPrintJob_default@null@INTERNAL@', 0))
        self.n.add_input('Flow_0fe8hce','PrintFactoryFactoryAutomation_SendOptimizationJob_default@null@INTERNAL@',Variable('v_Flow_0fe8hce'))
        self.n.add_input('Flow_1f74bn4','PrintFactoryFactoryAutomation_PreparePrinter_default@null@INTERNAL@',Variable('v_Flow_1f74bn4'))
        self.n.add_input('Flow_1y4bjf4','PrintFactoryFactoryAutomation_SendVisualInspectionJob_default@null@INTERNAL@',Variable('v_Flow_1y4bjf4'))
        self.n.add_input('optJob','PrintFactoryOptimization_ComposeOptimizationJob_default@null@COMPOSE@',Variable('v_optJob'))
        self.n.add_input('inspectionReport','PrintFactoryOptimization_ComposeOptimizationJob_default@null@COMPOSE@',Variable('v_inspectionReport'))
        self.n.add_input('Gateway_0p2uo9v','PrintFactoryFactoryAutomation_NextJob_default@null@INTERNAL@',Variable('v_Gateway_0p2uo9v'))
        self.n.add_input('Flow_1rkhqnd','PrintFactoryFactoryAutomation_WaitforPrepare_default@null@INTERNAL@',Variable('v_Flow_1rkhqnd'))
        self.n.add_input('printResult','PrintFactoryFactoryAutomation_WaitforPrepare_default@null@INTERNAL@',Variable('v_printResult'))
        self.n.add_input('Flow_16s4ey1','PrintFactoryFactoryAutomation_WaitforPrintJob_default@null@INTERNAL@',Variable('v_Flow_16s4ey1'))
        self.n.add_input('printResult','PrintFactoryFactoryAutomation_WaitforPrintJob_default@null@INTERNAL@',Variable('v_printResult'))
        self.n.add_input('Flow_1dcdx0e','PrintFactoryFactoryAutomation_Gateway_1j3rupx_default@null@INTERNAL@',Variable('v_Flow_1dcdx0e'))
        self.n.add_input('Gateway_1wpvmtk','PrintFactoryFactoryAutomation_SendPrintJob_default@null@INTERNAL@',Variable('v_Gateway_1wpvmtk'))
        self.n.add_input('printRequests','PrintFactoryFactoryAutomation_SendPrintJob_default@null@INTERNAL@',Variable('v_printRequests'))
        self.n.add_input('Flow_07l0yyj','PrintFactoryInspection_RunVisualinspection_default@ExecuteInspection@RUN@',Variable('v_Flow_07l0yyj'))
        self.n.add_input('measureRequest','PrintFactoryInspection_RunVisualinspection_default@ExecuteInspection@RUN@',Variable('v_measureRequest'))
        self.n.add_input('Flow_0y8u5pd','PrintFactoryOptimization_RunOptimizationJob_default@ExecuteOptimizer@RUN@',Variable('v_Flow_0y8u5pd'))
        self.n.add_input('optimizeJob','PrintFactoryOptimization_RunOptimizationJob_default@ExecuteOptimizer@RUN@',Variable('v_optimizeJob'))
        self.n.add_input('Flow_0iaelzn','PrintFactoryA3DPrinter_RunPrepareJob_default@ExecutePrinter@RUN@',Variable('v_Flow_0iaelzn'))
        self.n.add_input('request','PrintFactoryA3DPrinter_RunPrepareJob_default@ExecutePrinter@RUN@',Variable('v_request'))
        self.n.add_input('Flow_1dt29vl','PrintFactoryFactoryAutomation_WaitforVisualInspection_default@null@INTERNAL@',Variable('v_Flow_1dt29vl'))
        self.n.add_input('inspectionResult','PrintFactoryFactoryAutomation_WaitforVisualInspection_default@null@INTERNAL@',Variable('v_inspectionResult'))
        self.n.add_input('inspectionJob','PrintFactoryInspection_ComposeVisualInspectionJob_default@null@COMPOSE@',Variable('v_inspectionJob'))
        self.n.add_input('printReport','PrintFactoryInspection_ComposeVisualInspectionJob_default@null@COMPOSE@',Variable('v_printReport'))
        self.n.add_input('Flow_01m2s0h','PrintFactoryFactoryAutomation_WaitforOptimizationJob_default@null@INTERNAL@',Variable('v_Flow_01m2s0h'))
        self.n.add_input('optResult','PrintFactoryFactoryAutomation_WaitforOptimizationJob_default@null@INTERNAL@',Variable('v_optResult'))
        self.n.add_input('printJob','PrintFactoryA3DPrinter_ComposePrintJob_default@null@COMPOSE@',Variable('v_printJob'))
        self.n.add_input('corrections','PrintFactoryA3DPrinter_ComposePrintJob_default@null@COMPOSE@',Variable('v_corrections'))
        self.n.add_input('printJob','PrintFactoryA3DPrinter_ComposePrepareJob_default@null@COMPOSE@',Variable('v_printJob'))
        self.n.add_input('Flow_09b0flo','PrintFactoryFactoryAutomation_Gateway_1f8wap6_default@null@INTERNAL@',Variable('v_Flow_09b0flo'))
        self.n.add_input('Flow_1vq9t2p','PrintFactoryFactoryAutomation_Gateway_1f8wap6_default@null@INTERNAL@',Variable('v_Flow_1vq9t2p'))
        self.n.add_input('Flow_1u2qmtt','PrintFactoryA3DPrinter_RunPrintJob_default@ExecutePrinter@RUN@',Variable('v_Flow_1u2qmtt'))
        self.n.add_input('request','PrintFactoryA3DPrinter_RunPrintJob_default@ExecutePrinter@RUN@',Variable('v_request'))
        self.n.add_input('Flow_0kbycuh','PrintFactoryFactoryAutomation_AssertVisualInspection_default@Assert_Visual_Inspection@ASSERT@',Variable('v_Flow_0kbycuh'))
        self.n.add_input('inspectionReport','PrintFactoryFactoryAutomation_AssertVisualInspection_default@Assert_Visual_Inspection@ASSERT@',Variable('v_inspectionReport'))
        self.n.add_output('Flow_01m2s0h','PrintFactoryFactoryAutomation_SendOptimizationJob_default@null@INTERNAL@', Expression('Data().execute_PrintFactoryFactoryAutomation_SendOptimizationJob_default_Flow_01m2s0h(json.loads(v_Flow_0fe8hce, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('optJob','PrintFactoryFactoryAutomation_SendOptimizationJob_default@null@INTERNAL@', Expression('Data().execute_PrintFactoryFactoryAutomation_SendOptimizationJob_default_optJob(json.loads(v_Flow_0fe8hce, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_1rkhqnd','PrintFactoryFactoryAutomation_PreparePrinter_default@null@INTERNAL@', Expression('Data().execute_PrintFactoryFactoryAutomation_PreparePrinter_default_Flow_1rkhqnd(json.loads(v_Flow_1f74bn4, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('printJob','PrintFactoryFactoryAutomation_PreparePrinter_default@null@INTERNAL@', Expression('Data().execute_PrintFactoryFactoryAutomation_PreparePrinter_default_printJob(json.loads(v_Flow_1f74bn4, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_1dt29vl','PrintFactoryFactoryAutomation_SendVisualInspectionJob_default@null@INTERNAL@', Expression('Data().execute_PrintFactoryFactoryAutomation_SendVisualInspectionJob_default_Flow_1dt29vl(json.loads(v_Flow_1y4bjf4, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('inspectionJob','PrintFactoryFactoryAutomation_SendVisualInspectionJob_default@null@INTERNAL@', Expression('Data().execute_PrintFactoryFactoryAutomation_SendVisualInspectionJob_default_inspectionJob(json.loads(v_Flow_1y4bjf4, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_0y8u5pd','PrintFactoryOptimization_ComposeOptimizationJob_default@null@COMPOSE@', Expression('Data().get_UNIT()'))
        self.n.add_output('optimizeJob','PrintFactoryOptimization_ComposeOptimizationJob_default@null@COMPOSE@', Expression('Data().execute_PrintFactoryOptimization_ComposeOptimizationJob_default_optimizeJob(json.loads(v_optJob, object_pairs_hook=Data().int_keys),json.loads(v_inspectionReport, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('inspectionReport','PrintFactoryOptimization_ComposeOptimizationJob_default@null@COMPOSE@', Expression('Data().execute_PrintFactoryOptimization_ComposeOptimizationJob_default_inspectionReport(json.loads(v_optJob, object_pairs_hook=Data().int_keys),json.loads(v_inspectionReport, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_1wpvmtk','PrintFactoryFactoryAutomation_NextJob_default@null@INTERNAL@', Expression('Data().execute_PrintFactoryFactoryAutomation_NextJob_default_Gateway_1wpvmtk(json.loads(v_Gateway_0p2uo9v, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_1vq9t2p','PrintFactoryFactoryAutomation_WaitforPrepare_default@null@INTERNAL@', Expression('Data().execute_PrintFactoryFactoryAutomation_WaitforPrepare_default_Flow_1vq9t2p(json.loads(v_printResult, object_pairs_hook=Data().int_keys),json.loads(v_Flow_1rkhqnd, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_1dcdx0e','PrintFactoryFactoryAutomation_WaitforPrintJob_default@null@INTERNAL@', Expression('Data().execute_PrintFactoryFactoryAutomation_WaitforPrintJob_default_Flow_1dcdx0e(json.loads(v_printResult, object_pairs_hook=Data().int_keys),json.loads(v_Flow_16s4ey1, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_1y4bjf4','PrintFactoryFactoryAutomation_Gateway_1j3rupx_default@null@INTERNAL@', Expression('Data().execute_PrintFactoryFactoryAutomation_Gateway_1j3rupx_default_Flow_1y4bjf4(json.loads(v_Flow_1dcdx0e, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_1f74bn4','PrintFactoryFactoryAutomation_Gateway_1j3rupx_default@null@INTERNAL@', Expression('Data().execute_PrintFactoryFactoryAutomation_Gateway_1j3rupx_default_Flow_1f74bn4(json.loads(v_Flow_1dcdx0e, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_16s4ey1','PrintFactoryFactoryAutomation_SendPrintJob_default@null@INTERNAL@', Expression('Data().execute_PrintFactoryFactoryAutomation_SendPrintJob_default_Flow_16s4ey1(json.loads(v_printRequests, object_pairs_hook=Data().int_keys),json.loads(v_Gateway_1wpvmtk, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('printJob','PrintFactoryFactoryAutomation_SendPrintJob_default@null@INTERNAL@', Expression('Data().execute_PrintFactoryFactoryAutomation_SendPrintJob_default_printJob(json.loads(v_printRequests, object_pairs_hook=Data().int_keys),json.loads(v_Gateway_1wpvmtk, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('inspectionReport','PrintFactoryInspection_RunVisualinspection_default@ExecuteInspection@RUN@', Expression('Data().execute_PrintFactoryInspection_RunVisualinspection_default_inspectionReport(json.loads(v_measureRequest, object_pairs_hook=Data().int_keys),json.loads(v_Flow_07l0yyj, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('inspectionResult','PrintFactoryInspection_RunVisualinspection_default@ExecuteInspection@RUN@', Expression('Data().execute_PrintFactoryInspection_RunVisualinspection_default_inspectionResult(json.loads(v_measureRequest, object_pairs_hook=Data().int_keys),json.loads(v_Flow_07l0yyj, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Event_1oozdnw','PrintFactoryOptimization_RunOptimizationJob_default@ExecuteOptimizer@RUN@', Expression('Data().execute_PrintFactoryOptimization_RunOptimizationJob_default_Event_1oozdnw(json.loads(v_optimizeJob, object_pairs_hook=Data().int_keys),json.loads(v_Flow_0y8u5pd, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('corrections','PrintFactoryOptimization_RunOptimizationJob_default@ExecuteOptimizer@RUN@', Expression('Data().execute_PrintFactoryOptimization_RunOptimizationJob_default_corrections(json.loads(v_optimizeJob, object_pairs_hook=Data().int_keys),json.loads(v_Flow_0y8u5pd, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('optResult','PrintFactoryOptimization_RunOptimizationJob_default@ExecuteOptimizer@RUN@', Expression('Data().get_Result()'))
        self.n.add_output('Event_0mxx05p','PrintFactoryA3DPrinter_RunPrepareJob_default@ExecutePrinter@RUN@', Expression('Data().execute_PrintFactoryA3DPrinter_RunPrepareJob_default_Event_0mxx05p(json.loads(v_request, object_pairs_hook=Data().int_keys),json.loads(v_Flow_0iaelzn, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('printResult','PrintFactoryA3DPrinter_RunPrepareJob_default@ExecutePrinter@RUN@', Expression('Data().execute_PrintFactoryA3DPrinter_RunPrepareJob_default_printResult(json.loads(v_request, object_pairs_hook=Data().int_keys),json.loads(v_Flow_0iaelzn, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_0kbycuh','PrintFactoryFactoryAutomation_WaitforVisualInspection_default@null@INTERNAL@', Expression('Data().execute_PrintFactoryFactoryAutomation_WaitforVisualInspection_default_Flow_0kbycuh(json.loads(v_inspectionResult, object_pairs_hook=Data().int_keys),json.loads(v_Flow_1dt29vl, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_07l0yyj','PrintFactoryInspection_ComposeVisualInspectionJob_default@null@COMPOSE@', Expression('Data().get_UNIT()'))
        self.n.add_output('measureRequest','PrintFactoryInspection_ComposeVisualInspectionJob_default@null@COMPOSE@', Expression('Data().execute_PrintFactoryInspection_ComposeVisualInspectionJob_default_measureRequest(json.loads(v_printReport, object_pairs_hook=Data().int_keys),json.loads(v_inspectionJob, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('printReport','PrintFactoryInspection_ComposeVisualInspectionJob_default@null@COMPOSE@', Expression('Data().execute_PrintFactoryInspection_ComposeVisualInspectionJob_default_printReport(json.loads(v_printReport, object_pairs_hook=Data().int_keys),json.loads(v_inspectionJob, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_09b0flo','PrintFactoryFactoryAutomation_WaitforOptimizationJob_default@null@INTERNAL@', Expression('Data().execute_PrintFactoryFactoryAutomation_WaitforOptimizationJob_default_Flow_09b0flo(json.loads(v_Flow_01m2s0h, object_pairs_hook=Data().int_keys),json.loads(v_optResult, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_1u2qmtt','PrintFactoryA3DPrinter_ComposePrintJob_default@null@COMPOSE@', Expression('Data().get_UNIT()'))
        self.n.add_output('request','PrintFactoryA3DPrinter_ComposePrintJob_default@null@COMPOSE@', Expression('Data().execute_PrintFactoryA3DPrinter_ComposePrintJob_default_request(json.loads(v_corrections, object_pairs_hook=Data().int_keys),json.loads(v_printJob, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_0iaelzn','PrintFactoryA3DPrinter_ComposePrepareJob_default@null@COMPOSE@', Expression('Data().get_UNIT()'))
        self.n.add_output('request','PrintFactoryA3DPrinter_ComposePrepareJob_default@null@COMPOSE@', Expression('Data().execute_PrintFactoryA3DPrinter_ComposePrepareJob_default_request(json.loads(v_printJob, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Gateway_0p2uo9v','PrintFactoryFactoryAutomation_Gateway_1f8wap6_default@null@INTERNAL@', Expression('Data().execute_PrintFactoryFactoryAutomation_Gateway_1f8wap6_default_Gateway_0p2uo9v(json.loads(v_Flow_09b0flo, object_pairs_hook=Data().int_keys),json.loads(v_Flow_1vq9t2p, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Event_0jcg6zx','PrintFactoryA3DPrinter_RunPrintJob_default@ExecutePrinter@RUN@', Expression('Data().execute_PrintFactoryA3DPrinter_RunPrintJob_default_Event_0jcg6zx(json.loads(v_request, object_pairs_hook=Data().int_keys),json.loads(v_Flow_1u2qmtt, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('printResult','PrintFactoryA3DPrinter_RunPrintJob_default@ExecutePrinter@RUN@', Expression('Data().execute_PrintFactoryA3DPrinter_RunPrintJob_default_printResult(json.loads(v_request, object_pairs_hook=Data().int_keys),json.loads(v_Flow_1u2qmtt, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('printReport','PrintFactoryA3DPrinter_RunPrintJob_default@ExecutePrinter@RUN@', Expression('Data().execute_PrintFactoryA3DPrinter_RunPrintJob_default_printReport(json.loads(v_request, object_pairs_hook=Data().int_keys),json.loads(v_Flow_1u2qmtt, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('Flow_0fe8hce','PrintFactoryFactoryAutomation_AssertVisualInspection_default@Assert_Visual_Inspection@ASSERT@', Expression('Data().execute_PrintFactoryFactoryAutomation_AssertVisualInspection_default_Flow_0fe8hce(json.loads(v_Flow_0kbycuh, object_pairs_hook=Data().int_keys),json.loads(v_inspectionReport, object_pairs_hook=Data().int_keys))'))
        self.n.add_output('inspectionReport','PrintFactoryFactoryAutomation_AssertVisualInspection_default@Assert_Visual_Inspection@ASSERT@', Expression('Data().execute_PrintFactoryFactoryAutomation_AssertVisualInspection_default_inspectionReport(json.loads(v_Flow_0kbycuh, object_pairs_hook=Data().int_keys),json.loads(v_inspectionReport, object_pairs_hook=Data().int_keys))'))
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
        _txt.append(CEntry("printer.PrintFactoryInspection.ComposeVisualInspectionJob.default.reportLinking",""))
        constraint_list.append(Constraint("measureRequest","OUT", _txt))
        # _txt = []
        if "PrintFactoryInspection_ComposeVisualInspectionJob_default@null@COMPOSE@" not in self.constraint_dict:
            self.constraint_dict["PrintFactoryInspection_ComposeVisualInspectionJob_default@null@COMPOSE@"] = constraint_list
        else:
            self.constraint_dict["PrintFactoryInspection_ComposeVisualInspectionJob_default@null@COMPOSE@"].extend(constraint_list)
        _txt = []
        constraint_list = []
        # tr_assert_ref_dict = {}
        # map_transition_assert = {}
        self.tr_assert_ref_dict["PrintFactoryFactoryAutomation_AssertVisualInspection_default@Assert_Visual_Inspection@ASSERT@"] = "printer.PrintFactoryFactoryAutomation.AssertVisualInspection.default.default"
        self.map_transition_assert = {'PrintFactoryInspection_ComposeVisualInspectionJob_default@null@COMPOSE@': ['measureRequest','printReport'],'PrintFactoryA3DPrinter_ComposePrintJob_default@null@COMPOSE@': ['request'],'PrintFactoryA3DPrinter_ComposePrepareJob_default@null@COMPOSE@': ['request'],'PrintFactoryOptimization_ComposeOptimizationJob_default@null@COMPOSE@': ['optimizeJob','inspectionReport'],'PrintFactoryA3DPrinter_RunPrintJob_default@ExecutePrinter@RUN@': ['printReport'],'PrintFactoryFactoryAutomation_AssertVisualInspection_default@Assert_Visual_Inspection@ASSERT@': ['inspectionReport'],'PrintFactoryInspection_RunVisualinspection_default@ExecuteInspection@RUN@': ['inspectionReport'],'PrintFactoryOptimization_RunOptimizationJob_default@ExecuteOptimizer@RUN@': ['corrections']}
    
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
    pn = printerModel()
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
