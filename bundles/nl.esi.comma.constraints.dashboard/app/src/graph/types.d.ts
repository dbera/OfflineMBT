export type EdgeType = 'cont' | 'curved' | 'bezier';

export interface GraphOptions {
    edgeType: EdgeType,
    view: 'interactive' | 'svg',
    spacing: number,
    minTestSet: number,
}