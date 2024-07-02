import { JsonData } from '../types';
class SimScore {
    public newTestId: string;
    public jaccardIndex: number;
    public normalizedEditDistance: number;

    constructor(jsonData: JsonData) {
        this.newTestId = jsonData.newTestId
        this.jaccardIndex = jsonData.jaccardIndex
        this.normalizedEditDistance = jsonData.normalizedEditDistance
    }

}

export default SimScore;