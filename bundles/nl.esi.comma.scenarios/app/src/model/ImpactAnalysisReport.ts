import MetaInfo from './MetaInfo';
import ImpactedTest from './ImpactedTest';
import ProgressionTest from './ProgressionTest';
import RegressionTest from './RegressionTest';
import StatisticsInfo from './StatisticsInfo';
import TestConfigOverview from './TestConfigOverview';
import { JsonData } from '../types';
import ConfigInfo from './ConfigInfo';

class ImpactAnalysisReport {
    public meta : MetaInfo;
    public config : ConfigInfo;
    public impactedTestSet : ImpactedTest[];
    public progressionTestSet : ProgressionTest[];
    public regressionTestSet :  RegressionTest[];
    public statisticsInfo: StatisticsInfo;
    public testSelectionOverview : TestConfigOverview[];

    constructor(data: JsonData | null) {
        this.meta = new MetaInfo(data != null ? data.meta : null);
        this.config = new ConfigInfo(data != null ? data.config: null);
        this.impactedTestSet = data != null ? data.impactedTestSet.map((d: JsonData) => new ImpactedTest(d)) : [];
        this.progressionTestSet = data != null ? data.progressionTestSet.map((d: JsonData) => new ProgressionTest(d)) : [];
        this.regressionTestSet = data != null ? data.regressionTestSet.map((d: JsonData) => new RegressionTest(d)) : [];
        this.statisticsInfo = new StatisticsInfo(data != null ? data.statistics : null);
        this.testSelectionOverview = data != null ? data.testSelectionOverview.map((d: JsonData) => new TestConfigOverview(d)) : [];
    }
}

export default ImpactAnalysisReport;