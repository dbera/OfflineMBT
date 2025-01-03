package nl.esi.comma.testspecification.generator.fast

import nl.esi.comma.inputspecification.inputSpecification.SUTDefinition
import nl.esi.comma.inputspecification.inputSpecification.TWINSCANKT
import nl.esi.comma.inputspecification.inputSpecification.LISVCP

class FastUtils {

    def static generateVFDFile(SUTDefinition sDef) {
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

    def static generateTwinScanTxt(TWINSCANKT ts) {
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

    def static generateLisTxt(LISVCP lis) {
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
