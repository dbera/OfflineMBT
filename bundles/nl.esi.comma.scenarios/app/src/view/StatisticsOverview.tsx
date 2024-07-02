
import React, { useState } from 'react';
import TableContainer from '@mui/material/TableContainer';
import Paper from '@mui/material/Paper';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableHead from '@mui/material/TableHead';
import TestConfigOverview from '../model/TestConfigOverview';
import ProgressionTest from '../model/ProgressionTest';
import RegressionTest from '../model/RegressionTest';
import ConfigInfo from '../model/ConfigInfo';
import * as Constant from '../model/Constants';
import { downloadFile } from '../utils';
import TestScenario from '../model/TestScenario';
import styled from "styled-components";
interface IStatisticsProps {
    definedTests: number;
    definedConfigurations: number;
    definedTestConfigPairs: number;
    estBuildTimeDefined: string;
    selectedTests: number;
    selectedConfigurations: number;
    selectedTestConfigPairs: number;
    estBuildTimeSelected: string;
    testConfigsOverview: TestConfigOverview[];
    progressionTests: ProgressionTest[];
    regressionTests: RegressionTest[];
    configInfo: ConfigInfo;
}

function StatisticsOverview(props:IStatisticsProps):JSX.Element{
    const [configChecked, setConfigChecked] = useState<string[]>([]);
    const [scnChecked, setScnChecked] = useState<TestScenario[]>([]);
    const [counter, setCounter] = useState(0);
    const Button = styled.button`
      background-color: #4CAF50; /* Green */
      border: none;
      color: white;
      padding: 15px 32px;
      text-align: center;
      text-decoration: none;
      display: inline-block;
      font-size: 16px;
    `;
    function handleConfigCheck (e:React.ChangeEvent<HTMLInputElement>, scns:string[]){
        let updatedList = [...configChecked];
        const scnUpdatedList = [...scnChecked];
        let tests : TestScenario[] = [];
        let index = counter;//debug counter, can be removed
        if (e.target.checked) {
            scns.forEach(scn => {
                if (scnUpdatedList.findIndex(t => t.scnID === scn && t.config === e.target.value) === -1){
                    const t = new TestScenario(scn, e.target.value);
                    tests = tests.concat(t);
                    index++;
                }
            });
            setCounter(index);
            updatedList = [...configChecked, e.target.value];
            setScnChecked(scnUpdatedList.concat(tests));
        } else {
            updatedList.splice(updatedList.indexOf(e.target.value), 1);
            scns.forEach(scn => index-- && scnUpdatedList.splice(
                scnUpdatedList.findIndex(t=>t.scnID === scn && t.config === e.target.value), 1)
            );
            setScnChecked(scnUpdatedList)
            setCounter(index);
        }
        setConfigChecked(updatedList);
    }
    function handleSCNCheck (e:React.ChangeEvent<HTMLInputElement>){
        const configUpdatedList = [...configChecked];
        let scnUpdatedList = [...scnChecked];
        let index = counter;
        if (e.target.checked) {
            const test = new TestScenario(e.target.id, e.target.value);
            scnUpdatedList = [...scnChecked, test];
            index++;
            setCounter(index);
        } else {
            scnUpdatedList.splice(scnUpdatedList.findIndex(t=>t.scnID === e.target.id && t.config === e.target.value), 1);
            index--;
            setCounter(index);
            if (isConfigChecked(e.target.value)){
                configUpdatedList.splice(configUpdatedList.indexOf(e.target.value), 1);
            }
        }
        setScnChecked(scnUpdatedList);
        setConfigChecked(configUpdatedList);
    }
    const isConfigChecked = (item:string) => configChecked.includes(item) ? true : false;
    const isSCNChecked = (item:string, config:string) => scnChecked.find(scn => scn.scnID === item && scn.config === config) ? true : false;

    function onDownloadClick() {
        const selectedConfig = props.testConfigsOverview.filter(config => 
            scnChecked.some(test => config.config.match(test.config)));
        const jsonObj = {Configurations: selectedConfig.map((config) => {
            if (config.config == "ALL CONFIGURATIONS"){
                return {ConfigurationFilePath : props.configInfo.configFilePath != null ?
                    props.configInfo.configFilePath+props.configInfo.defaultConfigName+".ini": props.configInfo.defaultConfigName+".ini",
                        TestData : [
                            {
                                AssemblyFilePath:props.configInfo.assemblyFilePath,
                                TestList:getTestList(config.config)
                            }
                        ]
                }
            } else {
                return {ConfigurationFilePath : props.configInfo.configFilePath != null ?
                    props.configInfo.configFilePath+config.config+".ini":config.config+".ini",
                        TestData : [
                            {
                                AssemblyFilePath:props.configInfo.assemblyFilePath,
                                TestList:getTestList(config.config)
                            }
                        ]
                }
            }
        })};
        downloadFile("features.json", JSON.stringify(jsonObj, null, 2));
    }

    function getTestList(config:string){
        const testList = scnChecked.filter(test => test.config == config);
        const obj = testList.map((test) => {
            let selected = props.progressionTests.filter(progression=>progression.scnID == test.scnID)[0];
            const testIdList= test.scnID.replaceAll('.','').replace(":",".").split(" ");
            let testId = "";
            for(let i =0; i < testIdList.length; i++){
                testId += testIdList[i].charAt(0).toUpperCase()+ testIdList[i].slice(1);
            }
            if (selected !== null && selected !== undefined) {
                return props.configInfo.testFilePathPrefix!=null? 
                props.configInfo.testFilePathPrefix + "." + testId:testId;
            } else {
                selected = props.regressionTests.filter(regression=>regression.scnID == test.scnID)[0];
                if (selected !== null && selected !== undefined) {
                    return props.configInfo.testFilePathPrefix!=null? 
                    props.configInfo.testFilePathPrefix + "." + testId:testId;
                }
            }
        });
        return obj
    }

    return (
        <div style={{ display: "block", padding: 80, width: '100%' }}>
            <label>Number of Defined Tests: {props.definedTests}</label><br/>
            <label>Number of Defined Configurations: {props.definedConfigurations}</label><br/>
            <label>Number of Test-Configuration Pairs: {props.definedTestConfigPairs}</label><br/>
            <br/>
            <label>Number of Selected Tests: {props.selectedTests}</label><br/>
            <label>Number of Selected Configurations: {props.selectedConfigurations}</label><br/>
            <label>Number of Selected Test-Configuration Pairs: {props.selectedTestConfigPairs}</label><br/>
            <br/>
            {/*<label>Debug:{counter}</label>*/}
            <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
                <Button onClick={onDownloadClick}>Push to VTP</Button>
            </div><br/>
            <TableContainer component={Paper}>
            <Table style={{width: '100%'}} size="small">
                <TableHead>
                    <Constant.StyledTableRow>
                        <Constant.StyledTableCell width="25%">Configuration</Constant.StyledTableCell>
                        <Constant.StyledTableCell width="40%">Selected Tests</Constant.StyledTableCell>
                        <Constant.StyledTableCell width="10%">Category</Constant.StyledTableCell>
                    </Constant.StyledTableRow>
                </TableHead>
                <TableBody>
                {
                    props.testConfigsOverview.map((config, index) => (
                        <Constant.StyledTableRow key={index} sx={{ '&:last-child td, &:last-child th': { border: 0 } }} style={{verticalAlign: 'top'}}>
                            <Constant.StyledTableCell align="left">
                                <input type="checkbox" value={config.config} checked={isConfigChecked(config.config)} onChange={(e) => handleConfigCheck(e, config.tests)} />{config.config}
                            </Constant.StyledTableCell>
                            <Constant.StyledTableCell align="left">{config.tests.map((item, index) => (
                                <li key={index} style={{ listStyleType: "none" }}>
                                <input type="checkbox" id={item} value={config.config} checked={isSCNChecked(item, config.config)} onChange={handleSCNCheck} />{item}</li>))}
                            </Constant.StyledTableCell>
                            <Constant.StyledTableCell align="left">{config.category}</Constant.StyledTableCell>
                        </Constant.StyledTableRow>
                    ))
                }
                </TableBody>
            </Table>
            </TableContainer>
        </div>
    );
}

export default StatisticsOverview;