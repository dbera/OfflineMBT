import { JsonData } from '../types';
class MetaInfo {
    public createdAt: Date;
    public taskName: string;

    constructor(jsonData: JsonData | null) {
        this.createdAt = jsonData != null ? new Date(jsonData.createdAt) : new Date();
        this.taskName = jsonData != null ? jsonData.taskName : "dummy";
    }
}

export default MetaInfo;