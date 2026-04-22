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
    def get_AcqData():
    	return json.dumps({"id":0})
    	
    @staticmethod
    def get_AcqReq():
    	return json.dumps({"cmd_type":"ImageEnum::PREPARE","id":0})
    	
    @staticmethod
    def get_AcqResp():
    	return json.dumps({"result":"ResponseEnum::OK","id":0})
    	
    @staticmethod
    def get_CTX():
    	return json.dumps({"id":0})
    	
    @staticmethod
    def get_EquipmentStatus():
    	return json.dumps({"temp_status":"Status::ON","pump_status":"Status::ON","acq_status":"Status::ON"})
    	
    @staticmethod
    def get_ImageEnum():
    	return "ImageEnum::PREPARE"
    	
    @staticmethod
    def get_ImageQuality():
    	return "ImageQuality::HIGH"
    	
    @staticmethod
    def get_ImgReq():
    	return json.dumps({"cmd_type":"ImageEnum::PREPARE","id":0,"image_quality":"ImageQuality::HIGH"})
    	
    @staticmethod
    def get_ImgResp():
    	return json.dumps({"result":"ResponseEnum::OK"})
    	
    @staticmethod
    def get_PumpReq():
    	return json.dumps({"cmd_type":"VacuumEnum::ON","id":0})
    	
    @staticmethod
    def get_PumpResp():
    	return json.dumps({"result":"ResponseEnum::OK"})
    	
    @staticmethod
    def get_ResponseEnum():
    	return "ResponseEnum::OK"
    	
    @staticmethod
    def get_Status():
    	return "Status::ON"
    	
    @staticmethod
    def get_TempEnum():
    	return "TempEnum::SET"
    	
    @staticmethod
    def get_TempReq():
    	return json.dumps({"cmd_type":"TempEnum::SET","id":0})
    	
    @staticmethod
    def get_TempResp():
    	return json.dumps({"result":"ResponseEnum::OK","reqid":0})
    	
    @staticmethod
    def get_VacReq():
    	return json.dumps({"cmd_type":"VacuumEnum::ON","id":0})
    	
    @staticmethod
    def get_VacResp():
    	return json.dumps({"result":"ResponseEnum::OK"})
    	
    @staticmethod
    def get_VacuumEnum():
    	return "VacuumEnum::ON"
    	
    @staticmethod
    def execute_SupervisonModelSupervisionImagePreparation_Unprepare_default_AcquisitionReq(ImagingRequest):
    	AcquisitionReq = {"cmd_type": ImagingRequest["cmd_type"], "id": ImagingRequest["id"]}
    	return json.dumps(AcquisitionReq)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImagePreparation_Prepare_default_AcquisitionReq(ImagingRequest,EqStatus):
    	AcquisitionReq = {"cmd_type": ImagingRequest["cmd_type"], "id": ImagingRequest["id"]}
    	return json.dumps(AcquisitionReq)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImagePreparation_Prepare_default_EqStatus(ImagingRequest,EqStatus):
    	EqStatus = EqStatus
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImagePreparation_Waitforprepare_default_Gateway_102q82v(Flow_0kkvgdv,AcqUpdate,EqStatus):
    	Gateway_102q82v = Flow_0kkvgdv
    	return json.dumps(Gateway_102q82v)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImagePreparation_Waitforprepare_default_EqStatus(Flow_0kkvgdv,AcqUpdate,EqStatus):
    	EqStatus = {"temp_status": EqStatus["temp_status"], "pump_status": EqStatus["pump_status"], "acq_status": "Status::PREPARING"}
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImagePreparation_WaitforUnprepare_default_Gateway_102q82v(AcqUpdate,EqStatus,Flow_1kpcqqf):
    	Gateway_102q82v = Flow_1kpcqqf
    	return json.dumps(Gateway_102q82v)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImagePreparation_WaitforUnprepare_default_EqStatus(AcqUpdate,EqStatus,Flow_1kpcqqf):
    	EqStatus = {"temp_status": EqStatus["temp_status"], "pump_status": EqStatus["pump_status"], "acq_status": "Status::UNPREPARING"}
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelPumpController_done_default_Gateway_0td58pc(Flow_0x0gs9b):
    	Gateway_0td58pc = Flow_0x0gs9b
    	return json.dumps(Gateway_0td58pc)
    
    @staticmethod
    def execute_SupervisonModelPumpController_done_default_PumpUpdate(Flow_0x0gs9b):
    	PumpUpdate = {"result": "ResponseEnum::OK"}
    	return json.dumps(PumpUpdate)
    
    @staticmethod
    def execute_SupervisonModelPumpController_startpump_default_Flow_0x0gs9b(PumpRequest):
    	Flow_0x0gs9b = {"id": PumpRequest["id"]}
    	return json.dumps(Flow_0x0gs9b)
    
    @staticmethod
    def execute_SupervisonModelPumpController_stoppump_default_Flow_104f6k4(PumpRequest):
    	Flow_104f6k4 = {"id": PumpRequest["id"]}
    	return json.dumps(Flow_104f6k4)
    
    @staticmethod
    def execute_SupervisonModelPumpController_pumpstopped_default_Gateway_0td58pc(Flow_104f6k4):
    	Gateway_0td58pc = Flow_104f6k4
    	return json.dumps(Gateway_0td58pc)
    
    @staticmethod
    def execute_SupervisonModelPumpController_pumpstopped_default_PumpUpdate(Flow_104f6k4):
    	PumpUpdate = {"result": "ResponseEnum::OK"}
    	return json.dumps(PumpUpdate)
    
    @staticmethod
    def execute_SupervisonModelImagingController_WaitforUnprepareImaging_default_Gateway_0gu94f4(Flow_05szwsj,ImagingUpdate):
    	Gateway_0gu94f4 = Flow_05szwsj
    	return json.dumps(Gateway_0gu94f4)
    
    @staticmethod
    def execute_SupervisonModelImagingController_returntoprep_default_Gateway_0xpxevh(Gateway_0gu94f4):
    	Gateway_0xpxevh = Gateway_0gu94f4
    	return json.dumps(Gateway_0xpxevh)
    
    @staticmethod
    def execute_SupervisonModelImagingController_UnprepareImaging_default_Flow_05szwsj(Gateway_0i3nw09):
    	Flow_05szwsj = Gateway_0i3nw09
    	Flow_05szwsj["id"] = Flow_05szwsj["id"] + 1
    	return json.dumps(Flow_05szwsj)
    
    @staticmethod
    def execute_SupervisonModelImagingController_UnprepareImaging_default_ImagingRequest(Gateway_0i3nw09):
    	ImagingRequest = {"cmd_type": "ImageEnum::UNPREPARE", "id": Gateway_0i3nw09["id"], "image_quality": "ImageQuality::NA"}
    	return json.dumps(ImagingRequest)
    
    @staticmethod
    def execute_SupervisonModelImagingController_WaitforImagingStopped_default_Gateway_0i3nw09(Flow_0ncxpgd,ImagingUpdate):
    	Gateway_0i3nw09 = Flow_0ncxpgd
    	return json.dumps(Gateway_0i3nw09)
    
    @staticmethod
    def execute_SupervisonModelImagingController_StartLowResImaging_default_Gateway_08l0os0(Gateway_0kvhy0o):
    	Gateway_08l0os0 = Gateway_0kvhy0o
    	Gateway_08l0os0["id"] = Gateway_08l0os0["id"] + 1
    	return json.dumps(Gateway_08l0os0)
    
    @staticmethod
    def execute_SupervisonModelImagingController_StartLowResImaging_default_ImagingRequest(Gateway_0kvhy0o):
    	ImagingRequest = {"cmd_type": "ImageEnum::START", "id": Gateway_0kvhy0o["id"], "image_quality": "ImageQuality::LOW"}
    	return json.dumps(ImagingRequest)
    
    @staticmethod
    def execute_SupervisonModelImagingController_nextimage_default_Gateway_0kvhy0o(Gateway_0i3nw09):
    	Gateway_0kvhy0o = Gateway_0i3nw09
    	return json.dumps(Gateway_0kvhy0o)
    
    @staticmethod
    def execute_SupervisonModelImagingController_StartHighResImaging_default_Gateway_08l0os0(Gateway_0kvhy0o):
    	Gateway_08l0os0 = Gateway_0kvhy0o
    	Gateway_08l0os0["id"] = Gateway_08l0os0["id"] + 1
    	return json.dumps(Gateway_08l0os0)
    
    @staticmethod
    def execute_SupervisonModelImagingController_StartHighResImaging_default_ImagingRequest(Gateway_0kvhy0o):
    	ImagingRequest = {"cmd_type": "ImageEnum::START", "id": Gateway_0kvhy0o["id"], "image_quality": "ImageQuality::HIGH"}
    	return json.dumps(ImagingRequest)
    
    @staticmethod
    def execute_SupervisonModelImagingController_Stopimaging_default_Flow_0ncxpgd(Flow_1k04xzh):
    	Flow_0ncxpgd = Flow_1k04xzh
    	Flow_0ncxpgd["id"] = Flow_0ncxpgd["id"] + 1
    	return json.dumps(Flow_0ncxpgd)
    
    @staticmethod
    def execute_SupervisonModelImagingController_Stopimaging_default_ImagingRequest(Flow_1k04xzh):
    	ImagingRequest = {"cmd_type": "ImageEnum::STOP", "id": Flow_1k04xzh["id"], "image_quality": "ImageQuality::NA"}
    	return json.dumps(ImagingRequest)
    
    @staticmethod
    def execute_SupervisonModelImagingController_WaitforPrepared_default_Gateway_0kvhy0o(Flow_029nrs5,ImagingUpdate):
    	Gateway_0kvhy0o = Flow_029nrs5
    	return json.dumps(Gateway_0kvhy0o)
    
    @staticmethod
    def execute_SupervisonModelImagingController_PrepareImaging_default_Flow_029nrs5(Gateway_0xpxevh):
    	Flow_029nrs5 = Gateway_0xpxevh
    	Flow_029nrs5["id"] = Flow_029nrs5["id"] + 1
    	return json.dumps(Flow_029nrs5)
    
    @staticmethod
    def execute_SupervisonModelImagingController_PrepareImaging_default_ImagingRequest(Gateway_0xpxevh):
    	ImagingRequest = {"cmd_type": "ImageEnum::PREPARE", "id": Gateway_0xpxevh["id"], "image_quality": "ImageQuality::NA"}
    	return json.dumps(ImagingRequest)
    
    @staticmethod
    def execute_SupervisonModelImagingController_ImagingFinished_default_Flow_1k04xzh(Gateway_08l0os0,ImagingUpdate):
    	Flow_1k04xzh = Gateway_08l0os0
    	return json.dumps(Flow_1k04xzh)
    
    @staticmethod
    def execute_SupervisonModelSupervisionPressureHandler_StartPump_default_Flow_0balrow(EqStatus,VacuumRequest,Gateway_1j81da5):
    	Flow_0balrow = Gateway_1j81da5
    	return json.dumps(Flow_0balrow)
    
    @staticmethod
    def execute_SupervisonModelSupervisionPressureHandler_StartPump_default_PumpRequest(EqStatus,VacuumRequest,Gateway_1j81da5):
    	PumpRequest = {"cmd_type": "VacuumEnum::ON", "id": VacuumRequest["id"]}
    	return json.dumps(PumpRequest)
    
    @staticmethod
    def execute_SupervisonModelSupervisionPressureHandler_StartPump_default_EqStatus(EqStatus,VacuumRequest,Gateway_1j81da5):
    	EqStatus = EqStatus
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelSupervisionPressureHandler_WaitforPumpOff_default_Gateway_1i0qy9g(PumpUpdate,EqStatus,Flow_0cjhiik):
    	Gateway_1i0qy9g = Flow_0cjhiik
    	return json.dumps(Gateway_1i0qy9g)
    
    @staticmethod
    def execute_SupervisonModelSupervisionPressureHandler_WaitforPumpOff_default_EqStatus(PumpUpdate,EqStatus,Flow_0cjhiik):
    	EqStatus = {"temp_status": EqStatus["temp_status"], "pump_status": "Status::OFF", "acq_status": EqStatus["acq_status"]}
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelSupervisionPressureHandler_Restart_default_Gateway_1j81da5(Gateway_1i0qy9g):
    	Gateway_1j81da5 = Gateway_1i0qy9g
    	return json.dumps(Gateway_1j81da5)
    
    @staticmethod
    def execute_SupervisonModelSupervisionPressureHandler_TurnOffPump_default_Flow_0cjhiik(Flow_1wguswc,EqStatus,VacuumRequest):
    	Flow_0cjhiik = Flow_1wguswc
    	return json.dumps(Flow_0cjhiik)
    
    @staticmethod
    def execute_SupervisonModelSupervisionPressureHandler_TurnOffPump_default_PumpRequest(Flow_1wguswc,EqStatus,VacuumRequest):
    	PumpRequest = {"cmd_type": "VacuumEnum::OFF", "id": VacuumRequest["id"]}
    	return json.dumps(PumpRequest)
    
    @staticmethod
    def execute_SupervisonModelSupervisionPressureHandler_TurnOffPump_default_EqStatus(Flow_1wguswc,EqStatus,VacuumRequest):
    	EqStatus = EqStatus
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelSupervisionPressureHandler_WaitforPumpStated_default_Flow_1wguswc(PumpUpdate,Flow_0balrow,EqStatus):
    	Flow_1wguswc = Flow_0balrow
    	return json.dumps(Flow_1wguswc)
    
    @staticmethod
    def execute_SupervisonModelSupervisionPressureHandler_WaitforPumpStated_default_EqStatus(PumpUpdate,Flow_0balrow,EqStatus):
    	EqStatus = {"temp_status": EqStatus["temp_status"], "pump_status": "Status::ON", "acq_status": EqStatus["acq_status"]}
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelTemperatureController_return_default_Gateway_1sv33t8(Gateway_12yhscn):
    	Gateway_1sv33t8 = Gateway_12yhscn
    	Gateway_1sv33t8["id"] = Gateway_1sv33t8["id"]
    	return json.dumps(Gateway_1sv33t8)
    
    @staticmethod
    def execute_SupervisonModelTemperatureController_CheckTemp_default_Flow_01g3o4k(Gateway_1sv33t8,temp_achieved):
    	Flow_01g3o4k = Gateway_1sv33t8
    	return json.dumps(Flow_01g3o4k)
    
    @staticmethod
    def execute_SupervisonModelTemperatureController_SetTemperature_default_Flow_0estwso(Event_1r2zvr6):
    	Flow_0estwso = Event_1r2zvr6
    	Flow_0estwso["id"] = Flow_0estwso["id"] + 1
    	return json.dumps(Flow_0estwso)
    
    @staticmethod
    def execute_SupervisonModelTemperatureController_SetTemperature_default_TempRequest(Event_1r2zvr6):
    	TempRequest = {"cmd_type": "TempEnum::SET", "id": Event_1r2zvr6["id"]}
    	return json.dumps(TempRequest)
    
    @staticmethod
    def execute_SupervisonModelTemperatureController_ResetTemperature_default_Flow_0ay6jpo(Flow_01g3o4k):
    	Flow_0ay6jpo = Flow_01g3o4k
    	Flow_0ay6jpo["id"] = Flow_0ay6jpo["id"] + 1
    	return json.dumps(Flow_0ay6jpo)
    
    @staticmethod
    def execute_SupervisonModelTemperatureController_ResetTemperature_default_TempRequest(Flow_01g3o4k):
    	TempRequest = {"cmd_type": "TempEnum::RESET", "id": Flow_01g3o4k["id"]}
    	return json.dumps(TempRequest)
    
    @staticmethod
    def execute_SupervisonModelTemperatureController_WaitforReset_default_Gateway_12yhscn(Flow_0ay6jpo,TempUpdate):
    	Gateway_12yhscn = Flow_0ay6jpo
    	return json.dumps(Gateway_12yhscn)
    
    @staticmethod
    def execute_SupervisonModelTemperatureController_WaitforTempSet_default_Gateway_1sv33t8(TempUpdate,Flow_0estwso):
    	Gateway_1sv33t8 = Flow_0estwso
    	return json.dumps(Gateway_1sv33t8)
    
    @staticmethod
    def execute_SupervisonModelVacuumController_TurnOff_default_Flow_1dvvja5(Flow_1erv6vq):
    	Flow_1dvvja5 = Flow_1erv6vq
    	Flow_1dvvja5["id"] = Flow_1dvvja5["id"] + 1
    	return json.dumps(Flow_1dvvja5)
    
    @staticmethod
    def execute_SupervisonModelVacuumController_TurnOff_default_VacuumRequest(Flow_1erv6vq):
    	VacuumRequest = {"cmd_type": "VacuumEnum::OFF", "id": Flow_1erv6vq["id"]}
    	return json.dumps(VacuumRequest)
    
    @staticmethod
    def execute_SupervisonModelVacuumController_SetVacuum_default_Flow_1phqrfh(Gateway_0mqr7c2):
    	Flow_1phqrfh = Gateway_0mqr7c2
    	Flow_1phqrfh["id"] = Flow_1phqrfh["id"] + 1
    	return json.dumps(Flow_1phqrfh)
    
    @staticmethod
    def execute_SupervisonModelVacuumController_SetVacuum_default_VacuumRequest(Gateway_0mqr7c2):
    	VacuumRequest = {"cmd_type": "VacuumEnum::ON", "id": Gateway_0mqr7c2["id"]}
    	return json.dumps(VacuumRequest)
    
    @staticmethod
    def execute_SupervisonModelVacuumController_return_default_Gateway_0mqr7c2(Gateway_07w0e8f):
    	Gateway_0mqr7c2 = Gateway_07w0e8f
    	return json.dumps(Gateway_0mqr7c2)
    
    @staticmethod
    def execute_SupervisonModelVacuumController_WaitforOff_default_Gateway_07w0e8f(VacuumUpdate,Flow_1dvvja5):
    	Gateway_07w0e8f = Flow_1dvvja5
    	return json.dumps(Gateway_07w0e8f)
    
    @staticmethod
    def execute_SupervisonModelVacuumController_WaitforVacuumSet_default_Flow_1erv6vq(VacuumUpdate,Flow_1phqrfh):
    	Flow_1erv6vq = Flow_1phqrfh
    	return json.dumps(Flow_1erv6vq)
    
    @staticmethod
    def execute_SupervisonModelAcquisitionController_AcquisitionStopped_default_Gateway_0h81kts(Flow_1w9tlf4):
    	Gateway_0h81kts = Flow_1w9tlf4
    	return json.dumps(Gateway_0h81kts)
    
    @staticmethod
    def execute_SupervisonModelAcquisitionController_AcquisitionStopped_default_AcqUpdate(Flow_1w9tlf4):
    	AcqUpdate = {"result": "ResponseEnum::OK", "id": Flow_1w9tlf4["id"]}
    	return json.dumps(AcqUpdate)
    
    @staticmethod
    def execute_SupervisonModelAcquisitionController_Execacquisitioninitandteardown_default_Flow_084nmm6(AcquisitionReq):
    	Flow_084nmm6 = {"id": AcquisitionReq["id"]}
    	return json.dumps(Flow_084nmm6)
    
    @staticmethod
    def execute_SupervisonModelAcquisitionController_StartAcquisition_default_Flow_1rusz82(AcquisitionReq):
    	Flow_1rusz82 = {"id": AcquisitionReq["id"]}
    	return json.dumps(Flow_1rusz82)
    
    @staticmethod
    def execute_SupervisonModelAcquisitionController_Acquisitionexecdone_default_Gateway_0h81kts(Flow_084nmm6):
    	Gateway_0h81kts = Flow_084nmm6
    	return json.dumps(Gateway_0h81kts)
    
    @staticmethod
    def execute_SupervisonModelAcquisitionController_Acquisitionexecdone_default_AcqUpdate(Flow_084nmm6):
    	AcqUpdate = {"result": "ResponseEnum::OK", "id": Flow_084nmm6["id"]}
    	return json.dumps(AcqUpdate)
    
    @staticmethod
    def execute_SupervisonModelAcquisitionController_StopAcquisition_default_Flow_1w9tlf4(AcquisitionReq):
    	Flow_1w9tlf4 = {"id": AcquisitionReq["id"]}
    	return json.dumps(Flow_1w9tlf4)
    
    @staticmethod
    def execute_SupervisonModelAcquisitionController_StopAcquisition_default_ImageData(AcquisitionReq):
    	ImageData = {"id": AcquisitionReq["id"]}
    	return json.dumps(ImageData)
    
    @staticmethod
    def execute_SupervisonModelAcquisitionController_AcquisitionStarted_default_Gateway_0h81kts(Flow_1rusz82):
    	Gateway_0h81kts = Flow_1rusz82
    	return json.dumps(Gateway_0h81kts)
    
    @staticmethod
    def execute_SupervisonModelAcquisitionController_AcquisitionStarted_default_AcqUpdate(Flow_1rusz82):
    	AcqUpdate = {"result": "ResponseEnum::OK", "id": Flow_1rusz82["id"]}
    	return json.dumps(AcqUpdate)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImaging_WaitforStopAcquisition_default_Gateway_16m9e4j(AcqUpdate,Flow_0678bm1,EqStatus):
    	Gateway_16m9e4j = Flow_0678bm1
    	return json.dumps(Gateway_16m9e4j)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImaging_WaitforStopAcquisition_default_EqStatus(AcqUpdate,Flow_0678bm1,EqStatus):
    	EqStatus = {"temp_status": EqStatus["temp_status"], "pump_status": EqStatus["pump_status"], "acq_status": "Status::OFF"}
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImaging_CheckLowResImageQuality_default_Gateway_0qg69ul(ImageData,Gateway_16m9e4j,LastAcqReq):
    	Gateway_0qg69ul = Gateway_16m9e4j
    	return json.dumps(Gateway_0qg69ul)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImaging_WaitforStartAcquisition_default_Gateway_0qg69ul(AcqUpdate,EqStatus,Flow_1bajtwc):
    	Gateway_0qg69ul = Flow_1bajtwc
    	return json.dumps(Gateway_0qg69ul)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImaging_WaitforStartAcquisition_default_EqStatus(AcqUpdate,EqStatus,Flow_1bajtwc):
    	EqStatus = {"temp_status": EqStatus["temp_status"], "pump_status": EqStatus["pump_status"], "acq_status": "Status::ON"}
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImaging_StopAcquisition_default_AcquisitionReq(ImagingRequest):
    	AcquisitionReq = {"cmd_type": ImagingRequest["cmd_type"], "id": ImagingRequest["id"]}
    	return json.dumps(AcquisitionReq)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImaging_StartAcquisition_default_AcquisitionReq(ImagingRequest,EqStatus):
    	AcquisitionReq = {"cmd_type": ImagingRequest["cmd_type"], "id": ImagingRequest["id"]}
    	return json.dumps(AcquisitionReq)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImaging_StartAcquisition_default_LastAcqReq(ImagingRequest,EqStatus):
    	LastAcqReq = ImagingRequest
    	return json.dumps(LastAcqReq)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImaging_StartAcquisition_default_EqStatus(ImagingRequest,EqStatus):
    	EqStatus = EqStatus
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImaging_CheckHighResImageQuality_default_Gateway_0qg69ul(ImageData,Gateway_16m9e4j,LastAcqReq):
    	Gateway_0qg69ul = Gateway_16m9e4j
    	return json.dumps(Gateway_0qg69ul)
    
    @staticmethod
    def execute_SupervisonModelSupervisionTemperatureHandler_CreateResetTempMessage_default_TempCMD(TempRequest,EqStatus):
    	TempCMD = TempRequest
    	return json.dumps(TempCMD)
    
    @staticmethod
    def execute_SupervisonModelSupervisionTemperatureHandler_CreateResetTempMessage_default_EqStatus(TempRequest,EqStatus):
    	EqStatus = EqStatus
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelSupervisionTemperatureHandler_ExecuteSetTemp_default_Event_13ys7sy(Gateway_1qk9wqe,EqStatus,TempCMD):
    	Event_13ys7sy = Gateway_1qk9wqe
    	return json.dumps(Event_13ys7sy)
    
    @staticmethod
    def execute_SupervisonModelSupervisionTemperatureHandler_ExecuteSetTemp_default_temp_achieved(Gateway_1qk9wqe,EqStatus,TempCMD):
    	temp_achieved = {"result": "ResponseEnum::OK", "reqid": TempCMD["id"]}
    	return json.dumps(temp_achieved)
    
    @staticmethod
    def execute_SupervisonModelSupervisionTemperatureHandler_ExecuteSetTemp_default_EqStatus(Gateway_1qk9wqe,EqStatus,TempCMD):
    	EqStatus = {"temp_status": "Status::ON", "pump_status": EqStatus["pump_status"], "acq_status": EqStatus["acq_status"]}
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelSupervisionTemperatureHandler_CreateSetTempMessage_default_TempCMD(TempRequest):
    	TempCMD = TempRequest
    	return json.dumps(TempCMD)
    
