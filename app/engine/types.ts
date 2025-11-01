export interface EngineEvaluation {
  cp?: number; // centipawns
  mate?: number; // mate in N moves
}

export interface AnalysisLine {
  line: number; // MultiPV line number (1-indexed)
  pv: string[]; // Principal variation (algebraic moves)
  eval: EngineEvaluation;
  depth: number;
  seldepth?: number;
  nodes: number;
  nps?: number; // nodes per second
  time?: number; // time in milliseconds
  hashfull?: number;
}

export interface EngineMessage {
  type: 'ready' | 'info' | 'bestmove' | 'error' | 'log';
  data?: any;
  raw?: string;
}

export interface AnalysisOptions {
  fen: string;
  multipv?: number;
  depth?: number;
  movetime?: number; // milliseconds
}

export interface StockfishCommand {
  cmd: string;
}
