import {Node} from '../types';

export type Mode = 'sometimes' | 'always' | 'never' | 'does_not_exist';

export interface MatrixEntryBase {
    ID: string; x: number; y: number; nx: Node; ny: Node;
}

export interface MatrixDiffEntry extends MatrixEntryBase {
    modeBefore: Mode; modeAfter: Mode;
}

export interface MatrixEntry extends MatrixEntryBase {
    occurence: number; followsCount: number; mode: Mode;
}

export type ViewType = 'before' | 'after' | 'diff';