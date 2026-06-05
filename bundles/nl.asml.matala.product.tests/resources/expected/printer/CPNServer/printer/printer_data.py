import copy
import json


class Data:
    
    @staticmethod
    def int_keys(ordered_pairs):
        result = {}
        for key, value in ordered_pairs:
            try:
                key = int(key)
            except ValueError:
                pass
            result[key] = value
        return result
    
    @staticmethod
    def get_UNIT():
    	return json.dumps({"unit":0})
    	
    @staticmethod
    def get_AssertionsHistory():
    	return json.dumps({"inspectionReports":[]})
    	
    @staticmethod
    def get_ColorType():
    	return "ColorType::MONOCHROME"
    	
    @staticmethod
    def get_CorrectionItem():
    	return json.dumps({"data":""})
    	
    @staticmethod
    def get_CorrectionsReport():
    	return json.dumps({"correctionsMap":{},"id":0})
    	
    @staticmethod
    def get_FactoryCtx():
    	return json.dumps({"id":0,"resolution":"PrintResolution::LOW","scale":0.0,"color":"ColorType::MONOCHROME"})
    	
    @staticmethod
    def get_MeasureRequest():
    	return json.dumps({"id":0,"printJobReport":{"id":0}})
    	
    @staticmethod
    def get_OperationType():
    	return "OperationType::PREP"
    	
    @staticmethod
    def get_OptimizeRequest():
    	return json.dumps({"id":0})
    	
    @staticmethod
    def get_Outcome():
    	return "Outcome::OK"
    	
    @staticmethod
    def get_PrintRequest():
    	return json.dumps({"id":0,"resolution":"PrintResolution::LOW","scale":0.0,"color":"ColorType::MONOCHROME","opType":"OperationType::PREP"})
    	
    @staticmethod
    def get_PrintResolution():
    	return "PrintResolution::LOW"
    	
    @staticmethod
    def get_PrinterVariants():
    	return json.dumps({"version":"","release":""})
    	
    @staticmethod
    def get_Report():
    	return json.dumps({"id":0})
    	
    @staticmethod
    def get_Result():
    	return json.dumps({"verdict":"Outcome::OK"})
    	
    @staticmethod
    def execute_PrintFactoryA3DPrinter_RunPrintJob_default_Event_0jcg6zx(request,Flow_1u2qmtt,variants):
    	Event_0jcg6zx = Flow_1u2qmtt
    	return json.dumps(Event_0jcg6zx)
    
    @staticmethod
    def execute_PrintFactoryA3DPrinter_RunPrintJob_default_printResult(request,Flow_1u2qmtt,variants):
    	printResult = {"verdict": "Outcome::OK"}
    	return json.dumps(printResult)
    
    @staticmethod
    def execute_PrintFactoryA3DPrinter_RunPrintJob_default_printReport(request,Flow_1u2qmtt,variants):
    	printReport = {"id": request["id"]}
    	return json.dumps(printReport)
    
    @staticmethod
    def execute_PrintFactoryA3DPrinter_RunPrintJob_default_variants(request,Flow_1u2qmtt,variants):
    	variants = variants
    	return json.dumps(variants)
    
    @staticmethod
    def execute_PrintFactoryA3DPrinter_ComposePrintJob_default_request(corrections,printJob):
    	request = printJob
    	return json.dumps(request)
    
    @staticmethod
    def execute_PrintFactoryA3DPrinter_ComposePrepareJob_default_request(printJob):
    	request = printJob
    	return json.dumps(request)
    
    @staticmethod
    def execute_PrintFactoryA3DPrinter_RunPrepareJob_default_Event_0mxx05p(request,Flow_0iaelzn,variants):
    	Event_0mxx05p = Flow_0iaelzn
    	return json.dumps(Event_0mxx05p)
    
    @staticmethod
    def execute_PrintFactoryA3DPrinter_RunPrepareJob_default_printResult(request,Flow_0iaelzn,variants):
    	printResult = {"verdict": "Outcome::OK"}
    	return json.dumps(printResult)
    
    @staticmethod
    def execute_PrintFactoryA3DPrinter_RunPrepareJob_default_variants(request,Flow_0iaelzn,variants):
    	variants = variants
    	return json.dumps(variants)
    
    @staticmethod
    def execute_PrintFactoryAssertions_AssertVisualInspection_default_history(inspectionReport,history):
    	history = {"inspectionReports": history["inspectionReports"] + [inspectionReport["id"]]}
    	return json.dumps(history)
    
    @staticmethod
    def execute_PrintFactoryAssertions_AssertVisualInspection_default_inspectionReport(inspectionReport,history):
    	inspectionReport = inspectionReport
    	return json.dumps(inspectionReport)
    
    @staticmethod
    def execute_PrintFactoryInspection_RunVisualinspection_default_inspectionReport(measureRequest,Flow_07l0yyj):
    	inspectionReport = {"id": measureRequest["id"]}
    	return json.dumps(inspectionReport)
    
    @staticmethod
    def execute_PrintFactoryInspection_RunVisualinspection_default_inspectionResult(measureRequest,Flow_07l0yyj):
    	inspectionResult = {"verdict": "Outcome::OK"}
    	return json.dumps(inspectionResult)
    
    @staticmethod
    def execute_PrintFactoryInspection_ComposeVisualInspectionJob_default_measureRequest(printReport,inspectionJob):
    	measureRequest = inspectionJob
    	return json.dumps(measureRequest)
    
    @staticmethod
    def execute_PrintFactoryInspection_ComposeVisualInspectionJob_default_printReport(printReport,inspectionJob):
    	printReport = printReport
    	return json.dumps(printReport)
    
    @staticmethod
    def execute_PrintFactoryOptimization_ComposeOptimizationJob_default_optimizeJob(optJob,inspectionReport):
    	optimizeJob = optJob
    	return json.dumps(optimizeJob)
    
    @staticmethod
    def execute_PrintFactoryOptimization_ComposeOptimizationJob_default_inspectionReport(optJob,inspectionReport):
    	inspectionReport = inspectionReport
    	return json.dumps(inspectionReport)
    
    @staticmethod
    def execute_PrintFactoryOptimization_RunOptimizationJob_default_Event_1oozdnw(optimizeJob,Flow_0y8u5pd):
    	Event_1oozdnw = Flow_0y8u5pd
    	return json.dumps(Event_1oozdnw)
    
    @staticmethod
    def execute_PrintFactoryOptimization_RunOptimizationJob_default_corrections(optimizeJob,Flow_0y8u5pd):
    	corrections = {"id": optimizeJob["id"] + 1}
    	return json.dumps(corrections)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_SendPrintJob_default_Flow_16s4ey1(printRequests,Gateway_1wpvmtk):
    	Flow_16s4ey1 = Gateway_1wpvmtk
    	Flow_16s4ey1["color"] = printRequests["color"]
    	Flow_16s4ey1["resolution"] = printRequests["resolution"]
    	Flow_16s4ey1["scale"] = printRequests["scale"]
    	return json.dumps(Flow_16s4ey1)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_SendPrintJob_default_printJob(printRequests,Gateway_1wpvmtk):
    	printJob = {"id": printRequests["id"], "resolution": printRequests["resolution"], "scale": printRequests["scale"], "color": printRequests["color"], "opType": printRequests["opType"]}
    	return json.dumps(printJob)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_NextJob_default_Gateway_1wpvmtk(Gateway_0p2uo9v):
    	Gateway_1wpvmtk = Gateway_0p2uo9v
    	Gateway_1wpvmtk["id"] = Gateway_1wpvmtk["id"] + 1
    	return json.dumps(Gateway_1wpvmtk)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_WaitforOptimizationJob_default_Flow_09b0flo(Flow_01m2s0h,optResult):
    	Flow_09b0flo = Flow_01m2s0h
    	return json.dumps(Flow_09b0flo)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_Gateway_1f8wap6_default_Gateway_0p2uo9v(Flow_09b0flo,Flow_1vq9t2p):
    	Gateway_0p2uo9v = Flow_09b0flo
    	return json.dumps(Gateway_0p2uo9v)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_Gateway_1j3rupx_default_Flow_1y4bjf4(Flow_1dcdx0e):
    	Flow_1y4bjf4 = Flow_1dcdx0e
    	return json.dumps(Flow_1y4bjf4)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_Gateway_1j3rupx_default_Flow_1f74bn4(Flow_1dcdx0e):
    	Flow_1f74bn4 = Flow_1dcdx0e
    	return json.dumps(Flow_1f74bn4)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_WaitforVisualInspection_default_Flow_0kbycuh(inspectionResult,Flow_1dt29vl):
    	Flow_0kbycuh = Flow_1dt29vl
    	return json.dumps(Flow_0kbycuh)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_SendOptimizationJob_default_Flow_01m2s0h(Flow_0kbycuh):
    	Flow_01m2s0h = Flow_0kbycuh
    	return json.dumps(Flow_01m2s0h)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_SendOptimizationJob_default_optJob(Flow_0kbycuh):
    	optJob = {"id": Flow_0kbycuh["id"]}
    	return json.dumps(optJob)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_CleanPrinter_default_Flow_1rkhqnd(Flow_1f74bn4):
    	Flow_1rkhqnd = Flow_1f74bn4
    	return json.dumps(Flow_1rkhqnd)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_CleanPrinter_default_printJob(Flow_1f74bn4):
    	printJob = {"id": Flow_1f74bn4["id"], "resolution": Flow_1f74bn4["resolution"], "scale": None, "color": Flow_1f74bn4["color"], "opType": "OperationType::PREP"}
    	return json.dumps(printJob)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_SendVisualInspectionJob_default_Flow_1dt29vl(Flow_1y4bjf4):
    	Flow_1dt29vl = Flow_1y4bjf4
    	return json.dumps(Flow_1dt29vl)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_SendVisualInspectionJob_default_inspectionJob(Flow_1y4bjf4):
    	inspectionJob = {"id": Flow_1y4bjf4["id"]}
    	return json.dumps(inspectionJob)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_WaitforClean_default_Flow_1vq9t2p(printResult,Flow_1rkhqnd):
    	Flow_1vq9t2p = Flow_1rkhqnd
    	return json.dumps(Flow_1vq9t2p)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_WaitforPrintJob_default_Flow_1dcdx0e(printResult,Flow_16s4ey1):
    	Flow_1dcdx0e = Flow_16s4ey1
    	return json.dumps(Flow_1dcdx0e)
    
