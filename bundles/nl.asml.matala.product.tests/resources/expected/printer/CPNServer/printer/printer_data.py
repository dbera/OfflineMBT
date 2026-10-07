import copy
import json
if __package__ is None or __package__ == '':
    from printer_reporting import get_reporting, Location
else:
    from .printer_reporting import get_reporting, Location

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
    	try:
    	    Event_0jcg6zx = Flow_1u2qmtt
    	except Exception as e:
    	    __location = Location(63,63,2082,29,"Event_0jcg6zx := Flow_1u2qmtt")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Event_0jcg6zx)
    
    @staticmethod
    def execute_PrintFactoryA3DPrinter_RunPrintJob_default_printResult(request,Flow_1u2qmtt,variants):
    	try:
    	    printResult = {"verdict": "Outcome::OK"}
    	except Exception as e:
    	    __location = Location(66,66,2178,47,"printResult := Result { verdict = Outcome::OK }")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(printResult)
    
    @staticmethod
    def execute_PrintFactoryA3DPrinter_RunPrintJob_default_printReport(request,Flow_1u2qmtt,variants):
    	try:
    	    printReport = {"id": request["id"]}
    	except Exception as e:
    	    __location = Location(69,71,2331,66,"printReport := Report { id = request.id }")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(printReport)
    
    @staticmethod
    def execute_PrintFactoryA3DPrinter_RunPrintJob_default_variants(request,Flow_1u2qmtt,variants):
    	try:
    	    variants = variants
    	except Exception as e:
    	    __location = Location(74,74,2475,20,"variants := variants")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(variants)
    
    @staticmethod
    def execute_PrintFactoryA3DPrinter_ComposePrintJob_default_request(corrections,printJob):
    	try:
    	    request = printJob
    	except Exception as e:
    	    __location = Location(84,84,2900,19,"request := printJob")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(request)
    
    @staticmethod
    def execute_PrintFactoryA3DPrinter_ComposePrepareJob_default_request(printJob):
    	try:
    	    request = printJob
    	except Exception as e:
    	    __location = Location(94,94,3280,19,"request := printJob")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(request)
    
    @staticmethod
    def execute_PrintFactoryA3DPrinter_RunPrepareJob_default_Event_0mxx05p(request,Flow_0iaelzn,variants):
    	try:
    	    Event_0mxx05p = Flow_0iaelzn
    	except Exception as e:
    	    __location = Location(105,105,3771,29,"Event_0mxx05p := Flow_0iaelzn")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Event_0mxx05p)
    
    @staticmethod
    def execute_PrintFactoryA3DPrinter_RunPrepareJob_default_printResult(request,Flow_0iaelzn,variants):
    	try:
    	    printResult = {"verdict": "Outcome::OK"}
    	except Exception as e:
    	    __location = Location(108,108,3867,47,"printResult := Result { verdict = Outcome::OK }")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(printResult)
    
    @staticmethod
    def execute_PrintFactoryA3DPrinter_RunPrepareJob_default_variants(request,Flow_0iaelzn,variants):
    	try:
    	    variants = variants
    	except Exception as e:
    	    __location = Location(111,111,3992,20,"variants := variants")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(variants)
    
    @staticmethod
    def execute_PrintFactoryAssertions_AssertVisualInspection_default_history(inspectionReport,history):
    	try:
    	    history = {"inspectionReports": history["inspectionReports"] + [inspectionReport["id"]]}
    	except Exception as e:
    	    __location = Location(147,149,5050,130,"history := AssertionsHistory { inspectionReports = add(history.inspectionReports, inspectionReport.id) }")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(history)
    
    @staticmethod
    def execute_PrintFactoryAssertions_AssertVisualInspection_default_inspectionReport(inspectionReport,history):
    	try:
    	    inspectionReport = inspectionReport
    	except Exception as e:
    	    __location = Location(152,152,5296,36,"inspectionReport := inspectionReport")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(inspectionReport)
    
    @staticmethod
    def execute_PrintFactoryInspection_RunVisualinspection_default_inspectionReport(measureRequest,Flow_07l0yyj):
    	try:
    	    inspectionReport = {"id": measureRequest["id"]}
    	except Exception as e:
    	    __location = Location(183,185,6122,78,"inspectionReport := Report { id = measureRequest.id }")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(inspectionReport)
    
    @staticmethod
    def execute_PrintFactoryInspection_RunVisualinspection_default_inspectionResult(measureRequest,Flow_07l0yyj):
    	try:
    	    inspectionResult = {"verdict": "Outcome::OK"}
    	except Exception as e:
    	    __location = Location(188,188,6272,52,"inspectionResult := Result { verdict = Outcome::OK }")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(inspectionResult)
    
    @staticmethod
    def execute_PrintFactoryInspection_ComposeVisualInspectionJob_default_measureRequest(printReport,inspectionJob):
    	try:
    	    measureRequest = inspectionJob
    	except Exception as e:
    	    __location = Location(201,201,6871,31,"measureRequest := inspectionJob")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(measureRequest)
    
    @staticmethod
    def execute_PrintFactoryInspection_ComposeVisualInspectionJob_default_printReport(printReport,inspectionJob):
    	try:
    	    printReport = printReport
    	except Exception as e:
    	    __location = Location(204,204,6992,26,"printReport := printReport")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(printReport)
    
    @staticmethod
    def execute_PrintFactoryOptimization_ComposeOptimizationJob_default_optimizeJob(optJob,inspectionReport):
    	try:
    	    optimizeJob = optJob
    	except Exception as e:
    	    __location = Location(238,238,7898,21,"optimizeJob := optJob")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(optimizeJob)
    
    @staticmethod
    def execute_PrintFactoryOptimization_ComposeOptimizationJob_default_inspectionReport(optJob,inspectionReport):
    	try:
    	    inspectionReport = inspectionReport
    	except Exception as e:
    	    __location = Location(241,241,8014,36,"inspectionReport := inspectionReport")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(inspectionReport)
    
    @staticmethod
    def execute_PrintFactoryOptimization_RunOptimizationJob_default_Event_1oozdnw(optimizeJob,Flow_0y8u5pd):
    	try:
    	    Event_1oozdnw = Flow_0y8u5pd
    	except Exception as e:
    	    __location = Location(249,249,8333,29,"Event_1oozdnw := Flow_0y8u5pd")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Event_1oozdnw)
    
    @staticmethod
    def execute_PrintFactoryOptimization_RunOptimizationJob_default_corrections(optimizeJob,Flow_0y8u5pd):
    	try:
    	    corrections = {"id": optimizeJob["id"] + 1}
    	except Exception as e:
    	    __location = Location(252,254,8443,85,"corrections := CorrectionsReport { id = optimizeJob.id + 1 }")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(corrections)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_SendPrintJob_default_Flow_16s4ey1(printRequests,Gateway_1wpvmtk):
    	try:
    	    Flow_16s4ey1 = Gateway_1wpvmtk
    	except Exception as e:
    	    __location = Location(328,328,10537,31,"Flow_16s4ey1 := Gateway_1wpvmtk")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	try:
    	    Flow_16s4ey1["color"] = printRequests["color"]
    	except Exception as e:
    	    __location = Location(329,329,10581,41,"Flow_16s4ey1.color := printRequests.color")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	try:
    	    Flow_16s4ey1["resolution"] = printRequests["resolution"]
    	except Exception as e:
    	    __location = Location(330,330,10635,51,"Flow_16s4ey1.resolution := printRequests.resolution")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	try:
    	    Flow_16s4ey1["scale"] = printRequests["scale"]
    	except Exception as e:
    	    __location = Location(331,331,10699,41,"Flow_16s4ey1.scale := printRequests.scale")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_16s4ey1)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_SendPrintJob_default_printJob(printRequests,Gateway_1wpvmtk):
    	try:
    	    printJob = {"id": printRequests["id"], "resolution": printRequests["resolution"], "scale": printRequests["scale"], "color": printRequests["color"], "opType": printRequests["opType"]}
    	except Exception as e:
    	    __location = Location(334,340,10804,255,"printJob := PrintRequest { id = printRequests.id, resolution = printRequests.resolution, scale = printRequests.scale, color = printRequests.color, opType = printRequests.opType }")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(printJob)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_NextJob_default_Gateway_1wpvmtk(Gateway_0p2uo9v):
    	try:
    	    Gateway_1wpvmtk = Gateway_0p2uo9v
    	except Exception as e:
    	    __location = Location(348,348,11257,34,"Gateway_1wpvmtk := Gateway_0p2uo9v")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	try:
    	    Gateway_1wpvmtk["id"] = Gateway_1wpvmtk["id"] + 1
    	except Exception as e:
    	    __location = Location(349,349,11304,44,"Gateway_1wpvmtk.id := Gateway_1wpvmtk.id + 1")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_1wpvmtk)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_WaitforOptimizationJob_default_Flow_09b0flo(Flow_01m2s0h,optResult):
    	try:
    	    Flow_09b0flo = Flow_01m2s0h
    	except Exception as e:
    	    __location = Location(357,357,11583,28,"Flow_09b0flo := Flow_01m2s0h")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_09b0flo)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_Gateway_1f8wap6_default_Gateway_0p2uo9v(Flow_09b0flo,Flow_1vq9t2p):
    	try:
    	    Gateway_0p2uo9v = Flow_09b0flo
    	except Exception as e:
    	    __location = Location(366,366,11884,31,"Gateway_0p2uo9v := Flow_09b0flo")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_0p2uo9v)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_Gateway_1j3rupx_default_Flow_1y4bjf4(Flow_1dcdx0e):
    	try:
    	    Flow_1y4bjf4 = Flow_1dcdx0e
    	except Exception as e:
    	    __location = Location(374,374,12122,28,"Flow_1y4bjf4 := Flow_1dcdx0e")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_1y4bjf4)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_Gateway_1j3rupx_default_Flow_1f74bn4(Flow_1dcdx0e):
    	try:
    	    Flow_1f74bn4 = Flow_1dcdx0e
    	except Exception as e:
    	    __location = Location(377,377,12218,28,"Flow_1f74bn4 := Flow_1dcdx0e")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_1f74bn4)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_WaitforVisualInspection_default_Flow_0kbycuh(inspectionResult,Flow_1dt29vl):
    	try:
    	    Flow_0kbycuh = Flow_1dt29vl
    	except Exception as e:
    	    __location = Location(385,385,12490,28,"Flow_0kbycuh := Flow_1dt29vl")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_0kbycuh)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_SendOptimizationJob_default_Flow_01m2s0h(Flow_0kbycuh):
    	try:
    	    Flow_01m2s0h = Flow_0kbycuh
    	except Exception as e:
    	    __location = Location(393,393,12735,28,"Flow_01m2s0h := Flow_0kbycuh")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_01m2s0h)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_SendOptimizationJob_default_optJob(Flow_0kbycuh):
    	try:
    	    optJob = {"id": Flow_0kbycuh["id"]}
    	except Exception as e:
    	    __location = Location(396,396,12825,50,"optJob := OptimizeRequest { id = Flow_0kbycuh.id }")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(optJob)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_CleanPrinter_default_Flow_1rkhqnd(Flow_1f74bn4):
    	try:
    	    Flow_1rkhqnd = Flow_1f74bn4
    	except Exception as e:
    	    __location = Location(404,404,13077,28,"Flow_1rkhqnd := Flow_1f74bn4")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_1rkhqnd)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_CleanPrinter_default_printJob(Flow_1f74bn4):
    	try:
    	    printJob = {"id": Flow_1f74bn4["id"], "resolution": Flow_1f74bn4["resolution"], "scale": None, "color": Flow_1f74bn4["color"], "opType": "OperationType::PREP"}
    	except Exception as e:
    	    __location = Location(407,413,13169,236,"printJob := PrintRequest { id = Flow_1f74bn4.id, resolution = Flow_1f74bn4.resolution, scale = null, color = Flow_1f74bn4.color, opType = OperationType::PREP }")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(printJob)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_SendVisualInspectionJob_default_Flow_1dt29vl(Flow_1y4bjf4):
    	try:
    	    Flow_1dt29vl = Flow_1y4bjf4
    	except Exception as e:
    	    __location = Location(421,421,13631,28,"Flow_1dt29vl := Flow_1y4bjf4")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_1dt29vl)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_SendVisualInspectionJob_default_inspectionJob(Flow_1y4bjf4):
    	try:
    	    inspectionJob = {"id": Flow_1y4bjf4["id"]}
    	except Exception as e:
    	    __location = Location(424,426,13770,81,"inspectionJob := MeasureRequest { id = Flow_1y4bjf4.id }")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(inspectionJob)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_WaitforClean_default_Flow_1vq9t2p(printResult,Flow_1rkhqnd):
    	try:
    	    Flow_1vq9t2p = Flow_1rkhqnd
    	except Exception as e:
    	    __location = Location(434,434,14067,28,"Flow_1vq9t2p := Flow_1rkhqnd")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_1vq9t2p)
    
    @staticmethod
    def execute_PrintFactoryFactoryAutomation_WaitforPrintJob_default_Flow_1dcdx0e(printResult,Flow_16s4ey1):
    	try:
    	    Flow_1dcdx0e = Flow_16s4ey1
    	except Exception as e:
    	    __location = Location(442,442,14318,28,"Flow_1dcdx0e := Flow_16s4ey1")
    	    __source_file = "printer.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_1dcdx0e)
    