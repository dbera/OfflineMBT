import { JsonData } from '../types';
class MetaInfo {
    public createdAt: Date;

    constructor(jsonData: JsonData | null) {
        this.createdAt = jsonData != null ? new Date(jsonData.createdAt) : new Date();
    }
}

export default MetaInfo;