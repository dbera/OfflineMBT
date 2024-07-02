import { JsonData } from '../types';
import SimScore from './SimScore';
class Similarity {
    public existingTest: string;
    public simScores: SimScore[];

    constructor(jsonData: JsonData) {
        this.existingTest = jsonData.existingTest
        this.simScores = jsonData != null ? jsonData.simScores : [];
    }
}

export default Similarity;