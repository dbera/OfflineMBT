import copy
import json
if __package__ is None or __package__ == '':
    from imaging_reporting import get_reporting, Location
else:
    from .imaging_reporting import get_reporting, Location

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
    	try:
    	    AcquisitionReq = {"cmd_type": ImagingRequest["cmd_type"], "id": ImagingRequest["id"]}
    	except Exception as e:
    	    __location = Location(39,42,1040,125,"AcquisitionReq := AcqReq { cmd_type = ImagingRequest.cmd_type, id = ImagingRequest.id }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(AcquisitionReq)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImagePreparation_Prepare_default_AcquisitionReq(ImagingRequest,EqStatus):
    	try:
    	    AcquisitionReq = {"cmd_type": ImagingRequest["cmd_type"], "id": ImagingRequest["id"]}
    	except Exception as e:
    	    __location = Location(52,55,1573,125,"AcquisitionReq := AcqReq { cmd_type = ImagingRequest.cmd_type, id = ImagingRequest.id }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(AcquisitionReq)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImagePreparation_Prepare_default_EqStatus(ImagingRequest,EqStatus):
    	try:
    	    EqStatus = EqStatus
    	except Exception as e:
    	    __location = Location(58,58,1785,20,"EqStatus := EqStatus")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImagePreparation_Waitforprepare_default_Gateway_102q82v(Flow_0kkvgdv,AcqUpdate,EqStatus):
    	try:
    	    Gateway_102q82v = Flow_0kkvgdv
    	except Exception as e:
    	    __location = Location(66,66,2045,31,"Gateway_102q82v := Flow_0kkvgdv")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_102q82v)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImagePreparation_Waitforprepare_default_EqStatus(Flow_0kkvgdv,AcqUpdate,EqStatus):
    	try:
    	    EqStatus = {"temp_status": EqStatus["temp_status"], "pump_status": EqStatus["pump_status"], "acq_status": "Status::PREPARING"}
    	except Exception as e:
    	    __location = Location(70,74,2179,183,"EqStatus:=EquipmentStatus { temp_status = EqStatus.temp_status, pump_status = EqStatus.pump_status, acq_status = Status::PREPARING }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImagePreparation_WaitforUnprepare_default_Gateway_102q82v(AcqUpdate,EqStatus,Flow_1kpcqqf):
    	try:
    	    Gateway_102q82v = Flow_1kpcqqf
    	except Exception as e:
    	    __location = Location(82,82,2606,31,"Gateway_102q82v := Flow_1kpcqqf")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_102q82v)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImagePreparation_WaitforUnprepare_default_EqStatus(AcqUpdate,EqStatus,Flow_1kpcqqf):
    	try:
    	    EqStatus = {"temp_status": EqStatus["temp_status"], "pump_status": EqStatus["pump_status"], "acq_status": "Status::UNPREPARING"}
    	except Exception as e:
    	    __location = Location(86,90,2740,185,"EqStatus:=EquipmentStatus { temp_status = EqStatus.temp_status, pump_status = EqStatus.pump_status, acq_status = Status::UNPREPARING }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelPumpController_done_default_Gateway_0td58pc(Flow_0x0gs9b):
    	try:
    	    Gateway_0td58pc = Flow_0x0gs9b
    	except Exception as e:
    	    __location = Location(119,119,3531,31,"Gateway_0td58pc := Flow_0x0gs9b")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_0td58pc)
    
    @staticmethod
    def execute_SupervisonModelPumpController_done_default_PumpUpdate(Flow_0x0gs9b):
    	try:
    	    PumpUpdate = {"result": "ResponseEnum::OK"}
    	except Exception as e:
    	    __location = Location(122,122,3628,52,"PumpUpdate := PumpResp { result = ResponseEnum::OK }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(PumpUpdate)
    
    @staticmethod
    def execute_SupervisonModelPumpController_startpump_default_Flow_0x0gs9b(PumpRequest):
    	try:
    	    Flow_0x0gs9b = {"id": PumpRequest["id"]}
    	except Exception as e:
    	    __location = Location(131,131,3978,43,"Flow_0x0gs9b := CTX { id = PumpRequest.id }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_0x0gs9b)
    
    @staticmethod
    def execute_SupervisonModelPumpController_stoppump_default_Flow_104f6k4(PumpRequest):
    	try:
    	    Flow_104f6k4 = {"id": PumpRequest["id"]}
    	except Exception as e:
    	    __location = Location(140,140,4318,43,"Flow_104f6k4 := CTX { id = PumpRequest.id }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_104f6k4)
    
    @staticmethod
    def execute_SupervisonModelPumpController_pumpstopped_default_Gateway_0td58pc(Flow_104f6k4):
    	try:
    	    Gateway_0td58pc = Flow_104f6k4
    	except Exception as e:
    	    __location = Location(148,148,4564,31,"Gateway_0td58pc := Flow_104f6k4")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_0td58pc)
    
    @staticmethod
    def execute_SupervisonModelPumpController_pumpstopped_default_PumpUpdate(Flow_104f6k4):
    	try:
    	    PumpUpdate = {"result": "ResponseEnum::OK"}
    	except Exception as e:
    	    __location = Location(151,151,4661,52,"PumpUpdate := PumpResp { result = ResponseEnum::OK }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(PumpUpdate)
    
    @staticmethod
    def execute_SupervisonModelImagingController_WaitforUnprepareImaging_default_Gateway_0gu94f4(Flow_05szwsj,ImagingUpdate):
    	try:
    	    Gateway_0gu94f4 = Flow_05szwsj
    	except Exception as e:
    	    __location = Location(187,187,5569,31,"Gateway_0gu94f4 := Flow_05szwsj")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_0gu94f4)
    
    @staticmethod
    def execute_SupervisonModelImagingController_returntoprep_default_Gateway_0xpxevh(Gateway_0gu94f4):
    	try:
    	    Gateway_0xpxevh = Gateway_0gu94f4
    	except Exception as e:
    	    __location = Location(195,195,5809,34,"Gateway_0xpxevh := Gateway_0gu94f4")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_0xpxevh)
    
    @staticmethod
    def execute_SupervisonModelImagingController_UnprepareImaging_default_Flow_05szwsj(Gateway_0i3nw09):
    	try:
    	    Flow_05szwsj = Gateway_0i3nw09
    	except Exception as e:
    	    __location = Location(203,203,6056,31,"Flow_05szwsj := Gateway_0i3nw09")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	try:
    	    Flow_05szwsj["id"] = Flow_05szwsj["id"] + 1
    	except Exception as e:
    	    __location = Location(204,204,6100,36,"Flow_05szwsj.id := Flow_05szwsj.id+1")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_05szwsj)
    
    @staticmethod
    def execute_SupervisonModelImagingController_UnprepareImaging_default_ImagingRequest(Gateway_0i3nw09):
    	try:
    	    ImagingRequest = {"cmd_type": "ImageEnum::UNPREPARE", "id": Gateway_0i3nw09["id"], "image_quality": "ImageQuality::NA"}
    	except Exception as e:
    	    __location = Location(207,207,6206,118,"ImagingRequest:= ImgReq { cmd_type = ImageEnum::UNPREPARE, id = Gateway_0i3nw09.id, image_quality = ImageQuality::NA }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(ImagingRequest)
    
    @staticmethod
    def execute_SupervisonModelImagingController_WaitforImagingStopped_default_Gateway_0i3nw09(Flow_0ncxpgd,ImagingUpdate):
    	try:
    	    Gateway_0i3nw09 = Flow_0ncxpgd
    	except Exception as e:
    	    __location = Location(215,215,6564,31,"Gateway_0i3nw09 := Flow_0ncxpgd")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_0i3nw09)
    
    @staticmethod
    def execute_SupervisonModelImagingController_StartLowResImaging_default_Gateway_08l0os0(Gateway_0kvhy0o):
    	try:
    	    Gateway_08l0os0 = Gateway_0kvhy0o
    	except Exception as e:
    	    __location = Location(223,223,6817,34,"Gateway_08l0os0 := Gateway_0kvhy0o")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	try:
    	    Gateway_08l0os0["id"] = Gateway_08l0os0["id"] + 1
    	except Exception as e:
    	    __location = Location(224,224,6864,42,"Gateway_08l0os0.id := Gateway_08l0os0.id+1")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_08l0os0)
    
    @staticmethod
    def execute_SupervisonModelImagingController_StartLowResImaging_default_ImagingRequest(Gateway_0kvhy0o):
    	try:
    	    ImagingRequest = {"cmd_type": "ImageEnum::START", "id": Gateway_0kvhy0o["id"], "image_quality": "ImageQuality::LOW"}
    	except Exception as e:
    	    __location = Location(227,227,6976,116,"ImagingRequest := ImgReq { cmd_type = ImageEnum::START, id = Gateway_0kvhy0o.id, image_quality = ImageQuality::LOW }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(ImagingRequest)
    
    @staticmethod
    def execute_SupervisonModelImagingController_nextimage_default_Gateway_0kvhy0o(Gateway_0i3nw09):
    	try:
    	    Gateway_0kvhy0o = Gateway_0i3nw09
    	except Exception as e:
    	    __location = Location(235,235,7294,34,"Gateway_0kvhy0o := Gateway_0i3nw09")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_0kvhy0o)
    
    @staticmethod
    def execute_SupervisonModelImagingController_StartHighResImaging_default_Gateway_08l0os0(Gateway_0kvhy0o):
    	try:
    	    Gateway_08l0os0 = Gateway_0kvhy0o
    	except Exception as e:
    	    __location = Location(243,243,7552,34,"Gateway_08l0os0 := Gateway_0kvhy0o")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	try:
    	    Gateway_08l0os0["id"] = Gateway_08l0os0["id"] + 1
    	except Exception as e:
    	    __location = Location(244,244,7599,42,"Gateway_08l0os0.id := Gateway_08l0os0.id+1")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_08l0os0)
    
    @staticmethod
    def execute_SupervisonModelImagingController_StartHighResImaging_default_ImagingRequest(Gateway_0kvhy0o):
    	try:
    	    ImagingRequest = {"cmd_type": "ImageEnum::START", "id": Gateway_0kvhy0o["id"], "image_quality": "ImageQuality::HIGH"}
    	except Exception as e:
    	    __location = Location(247,247,7711,117,"ImagingRequest := ImgReq { cmd_type = ImageEnum::START, id = Gateway_0kvhy0o.id, image_quality = ImageQuality::HIGH }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(ImagingRequest)
    
    @staticmethod
    def execute_SupervisonModelImagingController_Stopimaging_default_Flow_0ncxpgd(Flow_1k04xzh):
    	try:
    	    Flow_0ncxpgd = Flow_1k04xzh
    	except Exception as e:
    	    __location = Location(255,255,8028,28,"Flow_0ncxpgd := Flow_1k04xzh")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	try:
    	    Flow_0ncxpgd["id"] = Flow_0ncxpgd["id"] + 1
    	except Exception as e:
    	    __location = Location(256,256,8069,36,"Flow_0ncxpgd.id := Flow_0ncxpgd.id+1")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_0ncxpgd)
    
    @staticmethod
    def execute_SupervisonModelImagingController_Stopimaging_default_ImagingRequest(Flow_1k04xzh):
    	try:
    	    ImagingRequest = {"cmd_type": "ImageEnum::STOP", "id": Flow_1k04xzh["id"], "image_quality": "ImageQuality::NA"}
    	except Exception as e:
    	    __location = Location(259,259,8175,111,"ImagingRequest := ImgReq { cmd_type = ImageEnum::STOP, id = Flow_1k04xzh.id, image_quality = ImageQuality::NA }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(ImagingRequest)
    
    @staticmethod
    def execute_SupervisonModelImagingController_WaitforPrepared_default_Gateway_0kvhy0o(Flow_029nrs5,ImagingUpdate):
    	try:
    	    Gateway_0kvhy0o = Flow_029nrs5
    	except Exception as e:
    	    __location = Location(267,267,8513,31,"Gateway_0kvhy0o := Flow_029nrs5")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_0kvhy0o)
    
    @staticmethod
    def execute_SupervisonModelImagingController_PrepareImaging_default_Flow_029nrs5(Gateway_0xpxevh):
    	try:
    	    Flow_029nrs5 = Gateway_0xpxevh
    	except Exception as e:
    	    __location = Location(275,275,8753,31,"Flow_029nrs5 := Gateway_0xpxevh")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	try:
    	    Flow_029nrs5["id"] = Flow_029nrs5["id"] + 1
    	except Exception as e:
    	    __location = Location(276,276,8797,36,"Flow_029nrs5.id := Flow_029nrs5.id+1")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_029nrs5)
    
    @staticmethod
    def execute_SupervisonModelImagingController_PrepareImaging_default_ImagingRequest(Gateway_0xpxevh):
    	try:
    	    ImagingRequest = {"cmd_type": "ImageEnum::PREPARE", "id": Gateway_0xpxevh["id"], "image_quality": "ImageQuality::NA"}
    	except Exception as e:
    	    __location = Location(279,279,8903,117,"ImagingRequest := ImgReq { cmd_type = ImageEnum::PREPARE, id = Gateway_0xpxevh.id, image_quality = ImageQuality::NA }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(ImagingRequest)
    
    @staticmethod
    def execute_SupervisonModelImagingController_ImagingFinished_default_Flow_1k04xzh(Gateway_08l0os0,ImagingUpdate):
    	try:
    	    Flow_1k04xzh = Gateway_08l0os0
    	except Exception as e:
    	    __location = Location(287,287,9246,31,"Flow_1k04xzh := Gateway_08l0os0")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_1k04xzh)
    
    @staticmethod
    def execute_SupervisonModelSupervisionPressureHandler_StartPump_default_Flow_0balrow(EqStatus,VacuumRequest,Gateway_1j81da5):
    	try:
    	    Flow_0balrow = Gateway_1j81da5
    	except Exception as e:
    	    __location = Location(324,324,10243,31,"Flow_0balrow := Gateway_1j81da5")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_0balrow)
    
    @staticmethod
    def execute_SupervisonModelSupervisionPressureHandler_StartPump_default_PumpRequest(EqStatus,VacuumRequest,Gateway_1j81da5):
    	try:
    	    PumpRequest = {"cmd_type": "VacuumEnum::ON", "id": VacuumRequest["id"]}
    	except Exception as e:
    	    __location = Location(327,330,10355,113,"PumpRequest := PumpReq { cmd_type = VacuumEnum::ON, id = VacuumRequest.id }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(PumpRequest)
    
    @staticmethod
    def execute_SupervisonModelSupervisionPressureHandler_StartPump_default_EqStatus(EqStatus,VacuumRequest,Gateway_1j81da5):
    	try:
    	    EqStatus = EqStatus
    	except Exception as e:
    	    __location = Location(333,333,10555,20,"EqStatus := EqStatus")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelSupervisionPressureHandler_WaitforPumpOff_default_Gateway_1i0qy9g(PumpUpdate,EqStatus,Flow_0cjhiik):
    	try:
    	    Gateway_1i0qy9g = Flow_0cjhiik
    	except Exception as e:
    	    __location = Location(341,341,10808,31,"Gateway_1i0qy9g := Flow_0cjhiik")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_1i0qy9g)
    
    @staticmethod
    def execute_SupervisonModelSupervisionPressureHandler_WaitforPumpOff_default_EqStatus(PumpUpdate,EqStatus,Flow_0cjhiik):
    	try:
    	    EqStatus = {"temp_status": EqStatus["temp_status"], "pump_status": "Status::OFF", "acq_status": EqStatus["acq_status"]}
    	except Exception as e:
    	    __location = Location(345,349,10941,178,"EqStatus := EquipmentStatus { temp_status = EqStatus.temp_status, pump_status = Status::OFF, acq_status = EqStatus.acq_status }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelSupervisionPressureHandler_Restart_default_Gateway_1j81da5(Gateway_1i0qy9g):
    	try:
    	    Gateway_1j81da5 = Gateway_1i0qy9g
    	except Exception as e:
    	    __location = Location(357,357,11316,34,"Gateway_1j81da5 := Gateway_1i0qy9g")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_1j81da5)
    
    @staticmethod
    def execute_SupervisonModelSupervisionPressureHandler_TurnOffPump_default_Flow_0cjhiik(Flow_1wguswc,EqStatus,VacuumRequest):
    	try:
    	    Flow_0cjhiik = Flow_1wguswc
    	except Exception as e:
    	    __location = Location(366,366,11676,28,"Flow_0cjhiik := Flow_1wguswc")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_0cjhiik)
    
    @staticmethod
    def execute_SupervisonModelSupervisionPressureHandler_TurnOffPump_default_PumpRequest(Flow_1wguswc,EqStatus,VacuumRequest):
    	try:
    	    PumpRequest = {"cmd_type": "VacuumEnum::OFF", "id": VacuumRequest["id"]}
    	except Exception as e:
    	    __location = Location(369,372,11785,114,"PumpRequest := PumpReq { cmd_type = VacuumEnum::OFF, id = VacuumRequest.id }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(PumpRequest)
    
    @staticmethod
    def execute_SupervisonModelSupervisionPressureHandler_TurnOffPump_default_EqStatus(Flow_1wguswc,EqStatus,VacuumRequest):
    	try:
    	    EqStatus = EqStatus
    	except Exception as e:
    	    __location = Location(375,375,11986,20,"EqStatus := EqStatus")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelSupervisionPressureHandler_WaitforPumpStated_default_Flow_1wguswc(PumpUpdate,Flow_0balrow,EqStatus):
    	try:
    	    Flow_1wguswc = Flow_0balrow
    	except Exception as e:
    	    __location = Location(383,383,12242,28,"Flow_1wguswc := Flow_0balrow")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_1wguswc)
    
    @staticmethod
    def execute_SupervisonModelSupervisionPressureHandler_WaitforPumpStated_default_EqStatus(PumpUpdate,Flow_0balrow,EqStatus):
    	try:
    	    EqStatus = {"temp_status": EqStatus["temp_status"], "pump_status": "Status::ON", "acq_status": EqStatus["acq_status"]}
    	except Exception as e:
    	    __location = Location(387,391,12372,177,"EqStatus := EquipmentStatus { temp_status = EqStatus.temp_status, pump_status = Status::ON, acq_status = EqStatus.acq_status }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelTemperatureController_return_default_Gateway_1sv33t8(Gateway_12yhscn):
    	try:
    	    Gateway_1sv33t8 = Gateway_12yhscn
    	except Exception as e:
    	    __location = Location(425,425,13322,34,"Gateway_1sv33t8 := Gateway_12yhscn")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	try:
    	    Gateway_1sv33t8["id"] = Gateway_1sv33t8["id"]
    	except Exception as e:
    	    __location = Location(426,426,13369,40,"Gateway_1sv33t8.id := Gateway_1sv33t8.id")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_1sv33t8)
    
    @staticmethod
    def execute_SupervisonModelTemperatureController_CheckTemp_default_Flow_01g3o4k(Gateway_1sv33t8,temp_achieved):
    	try:
    	    Flow_01g3o4k = Gateway_1sv33t8
    	except Exception as e:
    	    __location = Location(437,437,13765,31,"Flow_01g3o4k := Gateway_1sv33t8")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_01g3o4k)
    
    @staticmethod
    def execute_SupervisonModelTemperatureController_SetTemperature_default_Flow_0estwso(Event_1r2zvr6):
    	try:
    	    Flow_0estwso = Event_1r2zvr6
    	except Exception as e:
    	    __location = Location(445,445,14003,29,"Flow_0estwso := Event_1r2zvr6")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	try:
    	    Flow_0estwso["id"] = Flow_0estwso["id"] + 1
    	except Exception as e:
    	    __location = Location(446,446,14045,38,"Flow_0estwso.id := Flow_0estwso.id + 1")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_0estwso)
    
    @staticmethod
    def execute_SupervisonModelTemperatureController_SetTemperature_default_TempRequest(Event_1r2zvr6):
    	try:
    	    TempRequest = {"cmd_type": "TempEnum::SET", "id": Event_1r2zvr6["id"]}
    	except Exception as e:
    	    __location = Location(449,452,14150,112,"TempRequest := TempReq { cmd_type = TempEnum::SET, id = Event_1r2zvr6.id }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(TempRequest)
    
    @staticmethod
    def execute_SupervisonModelTemperatureController_ResetTemperature_default_Flow_0ay6jpo(Flow_01g3o4k):
    	try:
    	    Flow_0ay6jpo = Flow_01g3o4k
    	except Exception as e:
    	    __location = Location(460,460,14472,28,"Flow_0ay6jpo := Flow_01g3o4k")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	try:
    	    Flow_0ay6jpo["id"] = Flow_0ay6jpo["id"] + 1
    	except Exception as e:
    	    __location = Location(461,461,14513,38,"Flow_0ay6jpo.id := Flow_0ay6jpo.id + 1")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_0ay6jpo)
    
    @staticmethod
    def execute_SupervisonModelTemperatureController_ResetTemperature_default_TempRequest(Flow_01g3o4k):
    	try:
    	    TempRequest = {"cmd_type": "TempEnum::RESET", "id": Flow_01g3o4k["id"]}
    	except Exception as e:
    	    __location = Location(464,467,14618,113,"TempRequest := TempReq { cmd_type = TempEnum::RESET, id = Flow_01g3o4k.id }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(TempRequest)
    
    @staticmethod
    def execute_SupervisonModelTemperatureController_WaitforReset_default_Gateway_12yhscn(Flow_0ay6jpo,TempUpdate):
    	try:
    	    Gateway_12yhscn = Flow_0ay6jpo
    	except Exception as e:
    	    __location = Location(475,475,14949,31,"Gateway_12yhscn := Flow_0ay6jpo")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_12yhscn)
    
    @staticmethod
    def execute_SupervisonModelTemperatureController_WaitforTempSet_default_Gateway_1sv33t8(TempUpdate,Flow_0estwso):
    	try:
    	    Gateway_1sv33t8 = Flow_0estwso
    	except Exception as e:
    	    __location = Location(483,483,15203,31,"Gateway_1sv33t8 := Flow_0estwso")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_1sv33t8)
    
    @staticmethod
    def execute_SupervisonModelVacuumController_TurnOff_default_Flow_1dvvja5(Flow_1erv6vq):
    	try:
    	    Flow_1dvvja5 = Flow_1erv6vq
    	except Exception as e:
    	    __location = Location(515,515,15932,28,"Flow_1dvvja5 := Flow_1erv6vq")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	try:
    	    Flow_1dvvja5["id"] = Flow_1dvvja5["id"] + 1
    	except Exception as e:
    	    __location = Location(516,516,15973,38,"Flow_1dvvja5.id := Flow_1dvvja5.id + 1")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_1dvvja5)
    
    @staticmethod
    def execute_SupervisonModelVacuumController_TurnOff_default_VacuumRequest(Flow_1erv6vq):
    	try:
    	    VacuumRequest = {"cmd_type": "VacuumEnum::OFF", "id": Flow_1erv6vq["id"]}
    	except Exception as e:
    	    __location = Location(519,519,16080,76,"VacuumRequest := VacReq { cmd_type = VacuumEnum::OFF, id = Flow_1erv6vq.id }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(VacuumRequest)
    
    @staticmethod
    def execute_SupervisonModelVacuumController_SetVacuum_default_Flow_1phqrfh(Gateway_0mqr7c2):
    	try:
    	    Flow_1phqrfh = Gateway_0mqr7c2
    	except Exception as e:
    	    __location = Location(527,527,16355,31,"Flow_1phqrfh := Gateway_0mqr7c2")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	try:
    	    Flow_1phqrfh["id"] = Flow_1phqrfh["id"] + 1
    	except Exception as e:
    	    __location = Location(528,528,16399,38,"Flow_1phqrfh.id := Flow_1phqrfh.id + 1")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_1phqrfh)
    
    @staticmethod
    def execute_SupervisonModelVacuumController_SetVacuum_default_VacuumRequest(Gateway_0mqr7c2):
    	try:
    	    VacuumRequest = {"cmd_type": "VacuumEnum::ON", "id": Gateway_0mqr7c2["id"]}
    	except Exception as e:
    	    __location = Location(531,531,16506,78,"VacuumRequest := VacReq { cmd_type = VacuumEnum::ON, id = Gateway_0mqr7c2.id }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(VacuumRequest)
    
    @staticmethod
    def execute_SupervisonModelVacuumController_return_default_Gateway_0mqr7c2(Gateway_07w0e8f):
    	try:
    	    Gateway_0mqr7c2 = Gateway_07w0e8f
    	except Exception as e:
    	    __location = Location(539,539,16779,34,"Gateway_0mqr7c2 := Gateway_07w0e8f")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_0mqr7c2)
    
    @staticmethod
    def execute_SupervisonModelVacuumController_WaitforOff_default_Gateway_07w0e8f(VacuumUpdate,Flow_1dvvja5):
    	try:
    	    Gateway_07w0e8f = Flow_1dvvja5
    	except Exception as e:
    	    __location = Location(547,547,17029,31,"Gateway_07w0e8f := Flow_1dvvja5")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_07w0e8f)
    
    @staticmethod
    def execute_SupervisonModelVacuumController_WaitforVacuumSet_default_Flow_1erv6vq(VacuumUpdate,Flow_1phqrfh):
    	try:
    	    Flow_1erv6vq = Flow_1phqrfh
    	except Exception as e:
    	    __location = Location(555,555,17286,28,"Flow_1erv6vq := Flow_1phqrfh")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_1erv6vq)
    
    @staticmethod
    def execute_SupervisonModelAcquisitionController_AcquisitionStopped_default_Gateway_0h81kts(Flow_1w9tlf4):
    	try:
    	    Gateway_0h81kts = Flow_1w9tlf4
    	except Exception as e:
    	    __location = Location(586,586,17999,31,"Gateway_0h81kts := Flow_1w9tlf4")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_0h81kts)
    
    @staticmethod
    def execute_SupervisonModelAcquisitionController_AcquisitionStopped_default_AcqUpdate(Flow_1w9tlf4):
    	try:
    	    AcqUpdate = {"result": "ResponseEnum::OK", "id": Flow_1w9tlf4["id"]}
    	except Exception as e:
    	    __location = Location(589,589,18095,72,"AcqUpdate := AcqResp { result = ResponseEnum::OK, id = Flow_1w9tlf4.id }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(AcqUpdate)
    
    @staticmethod
    def execute_SupervisonModelAcquisitionController_Execacquisitioninitandteardown_default_Flow_084nmm6(AcquisitionReq):
    	try:
    	    Flow_084nmm6 = {"id": AcquisitionReq["id"]}
    	except Exception as e:
    	    __location = Location(598,598,18579,46,"Flow_084nmm6 := CTX { id = AcquisitionReq.id }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_084nmm6)
    
    @staticmethod
    def execute_SupervisonModelAcquisitionController_StartAcquisition_default_Flow_1rusz82(AcquisitionReq):
    	try:
    	    Flow_1rusz82 = {"id": AcquisitionReq["id"]}
    	except Exception as e:
    	    __location = Location(607,607,18952,46,"Flow_1rusz82 := CTX { id = AcquisitionReq.id }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_1rusz82)
    
    @staticmethod
    def execute_SupervisonModelAcquisitionController_Acquisitionexecdone_default_Gateway_0h81kts(Flow_084nmm6):
    	try:
    	    Gateway_0h81kts = Flow_084nmm6
    	except Exception as e:
    	    __location = Location(615,615,19218,31,"Gateway_0h81kts := Flow_084nmm6")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_0h81kts)
    
    @staticmethod
    def execute_SupervisonModelAcquisitionController_Acquisitionexecdone_default_AcqUpdate(Flow_084nmm6):
    	try:
    	    AcqUpdate = {"result": "ResponseEnum::OK", "id": Flow_084nmm6["id"]}
    	except Exception as e:
    	    __location = Location(618,618,19314,72,"AcqUpdate := AcqResp { result = ResponseEnum::OK, id = Flow_084nmm6.id }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(AcqUpdate)
    
    @staticmethod
    def execute_SupervisonModelAcquisitionController_StopAcquisition_default_Flow_1w9tlf4(AcquisitionReq):
    	try:
    	    Flow_1w9tlf4 = {"id": AcquisitionReq["id"]}
    	except Exception as e:
    	    __location = Location(627,627,19710,46,"Flow_1w9tlf4 := CTX { id = AcquisitionReq.id }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_1w9tlf4)
    
    @staticmethod
    def execute_SupervisonModelAcquisitionController_StopAcquisition_default_ImageData(AcquisitionReq):
    	try:
    	    ImageData = {"id": AcquisitionReq["id"]}
    	except Exception as e:
    	    __location = Location(630,630,19835,47,"ImageData := AcqData { id = AcquisitionReq.id }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(ImageData)
    
    @staticmethod
    def execute_SupervisonModelAcquisitionController_AcquisitionStarted_default_Gateway_0h81kts(Flow_1rusz82):
    	try:
    	    Gateway_0h81kts = Flow_1rusz82
    	except Exception as e:
    	    __location = Location(638,638,20099,31,"Gateway_0h81kts := Flow_1rusz82")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_0h81kts)
    
    @staticmethod
    def execute_SupervisonModelAcquisitionController_AcquisitionStarted_default_AcqUpdate(Flow_1rusz82):
    	try:
    	    AcqUpdate = {"result": "ResponseEnum::OK", "id": Flow_1rusz82["id"]}
    	except Exception as e:
    	    __location = Location(641,641,20195,72,"AcqUpdate := AcqResp { result = ResponseEnum::OK, id = Flow_1rusz82.id }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(AcqUpdate)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImaging_WaitforStopAcquisition_default_Gateway_16m9e4j(AcqUpdate,Flow_0678bm1,EqStatus):
    	try:
    	    Gateway_16m9e4j = Flow_0678bm1
    	except Exception as e:
    	    __location = Location(678,678,21206,31,"Gateway_16m9e4j := Flow_0678bm1")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_16m9e4j)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImaging_WaitforStopAcquisition_default_EqStatus(AcqUpdate,Flow_0678bm1,EqStatus):
    	try:
    	    EqStatus = {"temp_status": EqStatus["temp_status"], "pump_status": EqStatus["pump_status"], "acq_status": "Status::OFF"}
    	except Exception as e:
    	    __location = Location(682,686,21340,179,"EqStatus := EquipmentStatus { temp_status = EqStatus.temp_status, pump_status = EqStatus.pump_status, acq_status = Status::OFF }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImaging_CheckLowResImageQuality_default_Gateway_0qg69ul(ImageData,Gateway_16m9e4j,LastAcqReq):
    	try:
    	    Gateway_0qg69ul = Gateway_16m9e4j
    	except Exception as e:
    	    __location = Location(706,706,22235,34,"Gateway_0qg69ul := Gateway_16m9e4j")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_0qg69ul)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImaging_WaitforStartAcquisition_default_Gateway_0qg69ul(AcqUpdate,EqStatus,Flow_1bajtwc):
    	try:
    	    Gateway_0qg69ul = Flow_1bajtwc
    	except Exception as e:
    	    __location = Location(715,715,22585,31,"Gateway_0qg69ul := Flow_1bajtwc")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_0qg69ul)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImaging_WaitforStartAcquisition_default_EqStatus(AcqUpdate,EqStatus,Flow_1bajtwc):
    	try:
    	    EqStatus = {"temp_status": EqStatus["temp_status"], "pump_status": EqStatus["pump_status"], "acq_status": "Status::ON"}
    	except Exception as e:
    	    __location = Location(719,723,22719,178,"EqStatus := EquipmentStatus { temp_status = EqStatus.temp_status, pump_status = EqStatus.pump_status, acq_status = Status::ON }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImaging_StopAcquisition_default_AcquisitionReq(ImagingRequest):
    	try:
    	    AcquisitionReq = {"cmd_type": ImagingRequest["cmd_type"], "id": ImagingRequest["id"]}
    	except Exception as e:
    	    __location = Location(733,736,23268,125,"AcquisitionReq := AcqReq { cmd_type = ImagingRequest.cmd_type, id = ImagingRequest.id }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(AcquisitionReq)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImaging_StartAcquisition_default_AcquisitionReq(ImagingRequest,EqStatus):
    	try:
    	    AcquisitionReq = {"cmd_type": ImagingRequest["cmd_type"], "id": ImagingRequest["id"]}
    	except Exception as e:
    	    __location = Location(746,749,23857,125,"AcquisitionReq := AcqReq { cmd_type = ImagingRequest.cmd_type, id = ImagingRequest.id }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(AcquisitionReq)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImaging_StartAcquisition_default_LastAcqReq(ImagingRequest,EqStatus):
    	try:
    	    LastAcqReq = ImagingRequest
    	except Exception as e:
    	    __location = Location(752,752,24062,26,"LastAcqReq:=ImagingRequest")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(LastAcqReq)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImaging_StartAcquisition_default_EqStatus(ImagingRequest,EqStatus):
    	try:
    	    EqStatus = EqStatus
    	except Exception as e:
    	    __location = Location(755,755,24175,20,"EqStatus := EqStatus")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelSupervisionImaging_CheckHighResImageQuality_default_Gateway_0qg69ul(ImageData,Gateway_16m9e4j,LastAcqReq):
    	try:
    	    Gateway_0qg69ul = Gateway_16m9e4j
    	except Exception as e:
    	    __location = Location(775,775,24915,34,"Gateway_0qg69ul := Gateway_16m9e4j")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Gateway_0qg69ul)
    
    @staticmethod
    def execute_SupervisonModelSupervisionTemperatureHandler_CreateResetTempMessage_default_TempCMD(TempRequest,EqStatus):
    	try:
    	    TempCMD = TempRequest
    	except Exception as e:
    	    __location = Location(809,809,25922,22,"TempCMD := TempRequest")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(TempCMD)
    
    @staticmethod
    def execute_SupervisonModelSupervisionTemperatureHandler_CreateResetTempMessage_default_EqStatus(TempRequest,EqStatus):
    	try:
    	    EqStatus = EqStatus
    	except Exception as e:
    	    __location = Location(812,812,26031,20,"EqStatus := EqStatus")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelSupervisionTemperatureHandler_ExecuteSetTemp_default_Event_13ys7sy(Gateway_1qk9wqe,EqStatus,TempCMD):
    	try:
    	    Event_13ys7sy = Gateway_1qk9wqe
    	except Exception as e:
    	    __location = Location(820,820,26333,32,"Event_13ys7sy := Gateway_1qk9wqe")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Event_13ys7sy)
    
    @staticmethod
    def execute_SupervisonModelSupervisionTemperatureHandler_ExecuteSetTemp_default_temp_achieved(Gateway_1qk9wqe,EqStatus,TempCMD):
    	try:
    	    temp_achieved = {"result": "ResponseEnum::OK", "reqid": TempCMD["id"]}
    	except Exception as e:
    	    __location = Location(824,827,26484,113,"temp_achieved := TempResp { result = ResponseEnum::OK, reqid = TempCMD.id }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(temp_achieved)
    
    @staticmethod
    def execute_SupervisonModelSupervisionTemperatureHandler_ExecuteSetTemp_default_EqStatus(Gateway_1qk9wqe,EqStatus,TempCMD):
    	try:
    	    EqStatus = {"temp_status": "Status::ON", "pump_status": EqStatus["pump_status"], "acq_status": EqStatus["acq_status"]}
    	except Exception as e:
    	    __location = Location(830,834,26675,177,"EqStatus := EquipmentStatus { temp_status = Status::ON, pump_status = EqStatus.pump_status, acq_status = EqStatus.acq_status }")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(EqStatus)
    
    @staticmethod
    def execute_SupervisonModelSupervisionTemperatureHandler_CreateSetTempMessage_default_TempCMD(TempRequest):
    	try:
    	    TempCMD = TempRequest
    	except Exception as e:
    	    __location = Location(844,844,27225,22,"TempCMD := TempRequest")
    	    __source_file = "imaging.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(TempCMD)
    