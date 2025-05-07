/**
 * Copyright (c) 2024, 2025 TNO-ESI
 *
 * See the NOTICE file(s) distributed with this work for additional
 * information regarding copyright ownership.
 *
 * This program and the accompanying materials are made available
 * under the terms of the MIT License which is available at
 * https://opensource.org/licenses/MIT
 *
 * SPDX-License-Identifier: MIT
 */
package nl.esi.comma.testspecification.generator

import nl.esi.comma.inputspecification.inputSpecification.SUTDefinition
import nl.esi.comma.inputspecification.inputSpecification.TWINSCANKT
import nl.esi.comma.inputspecification.inputSpecification.LISVCP
import java.util.HashMap
import java.util.List
import java.util.ArrayList

class ConcreteSUTHandler 
{
	public var vartosutMap = new HashMap<String,String>
	public var suttosuttypeMap = new HashMap<String,String>
	public var concreteSUTMap = new HashMap<String, List<String>>
		
	def addToConcreteSUTMap(String sut_type, String txt) {
		if(concreteSUTMap.keySet.contains(sut_type)) {
			concreteSUTMap.get(sut_type).add(txt)
		} else {
			var tmp = new ArrayList<String>
			tmp.add(txt)
			concreteSUTMap.put(sut_type, tmp)
		}
	}
	
	// Only works for twinscan and lis, so far.. 
	// TODO Yieldstar grammar is not yet defined!
	def generateConcreteSoSUTMap(SUTDefinition sDef) 
	{	
		// var sutsname = sDef.sut.name
		// var sutsdesc = sDef.sut.desc
		
		for(vartosut : sDef.varToSut) {
			vartosutMap.put(vartosut.varref.name, vartosut.sutref.name)
		}
		
		for(sut : sDef.sutDef) {
			if(sut instanceof TWINSCANKT) {
				addToConcreteSUTMap(sut.name, generateTwinScanDocTxt(sut))
				suttosuttypeMap.put(sut.name, "TWINSCAN-KT")
			} else if(sut instanceof LISVCP) {
				addToConcreteSUTMap(sut.name, generateLISDocTxt(sut))
				suttosuttypeMap.put(sut.name, "LIS_VCP")
			}
		}
	}
	
	def display() {
		for(elm : vartosutMap.keySet) {
			System.out.println(" Var To SUT Map")
			System.out.println("	> " + elm + " -> " + vartosutMap.get(elm))
		}
		for(elm : suttosuttypeMap.keySet) {
			System.out.println(" SUT To SUT-Type Map")
			System.out.println("	> " + elm + " -> " + suttosuttypeMap.get(elm))
		}
		for(elm : concreteSUTMap.keySet) {
			System.out.println(" Concrete SUT Map")
			System.out.println("	> " + elm + " -> " + concreteSUTMap.get(elm))
		}
	}
	
	def generateVFDFile(SUTDefinition sDef) 
	{
		var def = sDef.generic.virtualFabDefinition
		var xsi = sDef.generic.XSI
		var loc = sDef.generic.schemaLocation
		var title = sDef.generic.title
		var sutsname = sDef.sut.name
		var sutsdesc = sDef.sut.desc
		'''
		<?xml version="1.0" encoding="UTF-8"?>
		<VirtualFabDefinition:VirtualFabDefinition xmlns:VirtualFabDefinition="«def»" xmlns:xsi="«xsi»" xsi:schemaLocation="«loc»">
		  <Header>
		    <Title>«title»</Title>
		    <CreateTime>2022-03-03T09:12:12</CreateTime>
		  </Header>
		  <Definition>
		    <Name>«sutsname»</Name>
		    <Description>«sutsdesc»</Description>
		    <SUTList>
		    «FOR sut : sDef.sut.sutDefRef»
		    	«IF sut instanceof TWINSCANKT»
		    		«generateTwinScanTxt(sut)»
		    	«ELSEIF sut instanceof LISVCP»
		    		«generateLisTxt(sut)»
		    	«ENDIF»
		    «ENDFOR»
		    </SUTList>
		  </Definition>
		</VirtualFabDefinition:VirtualFabDefinition>
		'''
	}
	
	def generateTwinScanDocTxt(TWINSCANKT ts) 
	{
		var txt = new String
		txt += "```json \n { \n"
		txt += "\"twinscan-name\" : \"" + ts.name + "\",\n"
		txt += "\"type\": \"" + ts.type + "\",\n"
		txt += "\"scenario-parameter-name\": \"" + ts.scenarioParameterName + "\",\n"
		txt += "\"machine-id\": \"" + ts.machineID + "\",\n"
		txt += "\"CPU\": \"" + ts.CPU + "\",\n"
		txt += "\"memory\": \"" + ts.memory + "\",\n"
		txt += "\"machine-type\": \"" + ts.machineType + "\",\n"
		txt += "\"use-existing\": \"" + ts.useExisting + "\",\n"
		txt += "\"baseline\": \"" + ts.baseline + "\",\n"
		
		if(!ts.options.empty) {
			txt += "\"options\" : [" + "\n"
			for(elm : ts.options) 
			{
				txt += "{\n"
				txt += "	\"option-name\": \"" + elm.optionname + "\",\n"
				txt += "	\"value\": \"" + elm.value + "\",\n"
				txt += "	\"is-svp\": \"" + elm.isIsSVP + "\",\n"
				txt += "}\n" 
			}
			txt += "]\n"
		}
		
		if(!ts.commands.empty) {
			txt += "\"commands\" : [" + "\n"
			for(elm : ts.commands) {
				txt += "{\n"
				txt += "	" + elm + ",\n"
				txt += "}\n"
			}
			txt += "]\n"
		}
		txt += "```"
		return txt
	}
	
	def generateTwinScanTxt(TWINSCANKT ts) {
		var name = ts.name
		var type = ts.type
		var scn_param_name = ts.scenarioParameterName
		var machine_id = ts.machineID
		var cpu = ts.CPU
		var memory = ts.memory
		var machine_type = ts.machineType
		var useExisting = ts.useExisting
		var swbaseline = ts.baseline
		
		'''
		<SUT>
			<SutType>«type»</SutType>
			<Name>«name»</Name>
		    <ScenarioParameterName>«scn_param_name»</ScenarioParameterName>
		    <TWINSCAN-KT>
		    	<MachineID>«machine_id»</MachineID>
		        <CPU>«cpu»</CPU>
		        <Memory>«memory»</Memory>
		        <MachineType>«machine_type»</MachineType>
		        <UseExisting>«useExisting»</UseExisting>
		        <Baseline>«swbaseline»</Baseline>
		        «IF !ts.options.empty»
		        <OptionList>
		        «FOR elm : ts.options»
		        	<Option>
		        		<OptionName>«elm.optionname»</OptionName>
		        		<OptionValue>«elm.value»</OptionValue>
		        		<IsSVP>«elm.isIsSVP»</IsSVP>
		        	</Option>
		        «ENDFOR»
		        </OptionList>
		        «ENDIF»
		        «IF !ts.commands.empty»
		        <RunCommands>
		        	<PostConfiguration>
		            	<CommandList>
		                	«FOR elm : ts.commands»
		                	<Command>«elm»</Command>
		                	«ENDFOR»
		              	</CommandList>
		            </PostConfiguration>
		         </RunCommands>
		         «ENDIF»
			</TWINSCAN-KT>
		</SUT>
		'''
	}
	
	def generateLISDocTxt(LISVCP lis) 
	{
		var txt = new String
		txt += "```json \n { \n"
		txt += "\"name\" : \"" + lis.name + "\",\n"
		txt += "\"type\" : \"" + lis.type + "\",\n"
		txt += "\"scenario-parameter-name\" : \"" + lis.scenarioParameterName + "\",\n"
		txt += "\"address\" : \"" + lis.address + "\",\n"
		
		txt += "\"job-config-list\" : [" + "\n"
		for(elm : lis.jobConfigList) 
		{
			txt += "{\n"
			txt += "	\"app-id\" : \"" + elm.appID + "\",\n"
			txt += "	\"function-id\" : \"" + elm.fnId + "\",\n"
			txt += "	\"is-active-document-collection\" : \"" + elm.isActDocColl + "\",\n"
			txt += "}\n"
		}
		txt += "]\n"
		txt += "```"
		return txt
	}
	
	def generateLisTxt(LISVCP lis) 
	{
		var name = lis.name
		var type = lis.type
		var scn_param_name = lis.scenarioParameterName
		var address = lis.address
		
		'''
		      <SUT>
		        <SutType>«type»</SutType>
		        <Name>«name»</Name>
		        <ScenarioParameterName>«scn_param_name»</ScenarioParameterName>
		        <LIS-VCP>
		          <Address>«address»</Address>
		          <JobConfigList>
		          «FOR elm : lis.jobConfigList»
		            <JobConfig>
		              <ApplicationId>«elm.appID»</ApplicationId>
		              <FunctionId>«elm.fnId»</FunctionId>
		              <ActiveDocumentCollection>«elm.isActDocColl»</ActiveDocumentCollection>
		            </JobConfig>
		          «ENDFOR»
		          </JobConfigList>
		        </LIS-VCP>
		      </SUT>
		'''
	}
}