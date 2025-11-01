import { EngineMessage, AnalysisLine, AnalysisOptions, EngineEvaluation } from './types';

type MessageHandler = (message: EngineMessage) => void;

export class StockfishService {
  private worker: Worker | null = null;
  private messageHandlers: Set<MessageHandler> = new Set();
  private readyPromise: Promise<void> | null = null;
  private isInitialized = false;
  private isAnalyzing = false;
  private currentLines: Map<number, AnalysisLine> = new Map();

  constructor() {}

  async init(): Promise<void> {
    if (this.isInitialized && this.worker) {
      return;
    }

    return new Promise((resolve, reject) => {
      try {
        // Create worker using Next.js compatible approach
        this.worker = new Worker(
          new URL('./stockfish.worker.ts', import.meta.url),
          { type: 'module' }
        );

        let uciOkReceived = false;

        this.worker.onmessage = (e: MessageEvent<EngineMessage>) => {
          const message = e.data;

          // Broadcast to all handlers
          this.messageHandlers.forEach(handler => handler(message));

          // Handle initialization
          if (message.type === 'ready' && message.data === 'uciok' && !uciOkReceived) {
            uciOkReceived = true;
            this.isInitialized = true;
            resolve();
          }

          if (message.type === 'error') {
            reject(new Error(message.data));
          }
        };

        this.worker.onerror = (error) => {
          console.error('Worker error:', error);
          reject(error);
        };

        // Initialize the engine
        this.worker.postMessage({ cmd: 'init' });

        // Timeout after 10 seconds
        setTimeout(() => {
          if (!uciOkReceived) {
            reject(new Error('Engine initialization timeout'));
          }
        }, 10000);
      } catch (error) {
        reject(error);
      }
    });
  }

  send(cmd: string): void {
    if (!this.worker) {
      console.error('Worker not initialized');
      return;
    }
    this.worker.postMessage({ cmd });
  }

  async waitForReady(): Promise<void> {
    return new Promise((resolve) => {
      const handler = (message: EngineMessage) => {
        if (message.type === 'ready' && message.data === 'readyok') {
          this.removeMessageHandler(handler);
          resolve();
        }
      };
      this.addMessageHandler(handler);
      this.send('isready');
    });
  }

  async analyze(options: AnalysisOptions): Promise<void> {
    if (!this.isInitialized || !this.worker) {
      throw new Error('Engine not initialized');
    }

    // Stop any ongoing analysis
    if (this.isAnalyzing) {
      this.stop();
    }

    this.currentLines.clear();
    this.isAnalyzing = true;

    // Set MultiPV if specified
    if (options.multipv && options.multipv > 1) {
      this.send(`setoption name MultiPV value ${options.multipv}`);
    } else {
      this.send('setoption name MultiPV value 1');
    }

    await this.waitForReady();

    // Send new game
    this.send('ucinewgame');
    await this.waitForReady();

    // Set position
    this.send(`position fen ${options.fen}`);

    // Start analysis
    if (options.movetime) {
      this.send(`go movetime ${options.movetime}`);
    } else if (options.depth) {
      this.send(`go depth ${options.depth}`);
    } else {
      this.send('go depth 16'); // default
    }
  }

  stop(): void {
    if (this.worker && this.isAnalyzing) {
      this.send('stop');
      this.isAnalyzing = false;
    }
  }

  parseInfoLine(line: string): AnalysisLine | null {
    if (!line.startsWith('info')) return null;

    const tokens = line.split(' ');
    const info: Partial<AnalysisLine> = {
      eval: {},
      pv: [],
      depth: 0,
      nodes: 0,
    };

    let i = 1; // skip 'info'
    while (i < tokens.length) {
      const token = tokens[i];

      switch (token) {
        case 'depth':
          info.depth = parseInt(tokens[++i], 10);
          break;
        case 'seldepth':
          info.seldepth = parseInt(tokens[++i], 10);
          break;
        case 'multipv':
          info.line = parseInt(tokens[++i], 10);
          break;
        case 'score':
          i++;
          const scoreType = tokens[i];
          if (scoreType === 'cp') {
            info.eval!.cp = parseInt(tokens[++i], 10);
          } else if (scoreType === 'mate') {
            info.eval!.mate = parseInt(tokens[++i], 10);
          }
          break;
        case 'nodes':
          info.nodes = parseInt(tokens[++i], 10);
          break;
        case 'nps':
          info.nps = parseInt(tokens[++i], 10);
          break;
        case 'time':
          info.time = parseInt(tokens[++i], 10);
          break;
        case 'hashfull':
          info.hashfull = parseInt(tokens[++i], 10);
          break;
        case 'pv':
          // Everything after 'pv' is the principal variation
          info.pv = tokens.slice(i + 1);
          i = tokens.length; // exit loop
          break;
        default:
          i++;
      }
    }

    // Only return if we have essential data
    if (info.depth && info.pv && info.pv.length > 0) {
      return info as AnalysisLine;
    }

    return null;
  }

  addMessageHandler(handler: MessageHandler): void {
    this.messageHandlers.add(handler);
  }

  removeMessageHandler(handler: MessageHandler): void {
    this.messageHandlers.delete(handler);
  }

  getCurrentLines(): AnalysisLine[] {
    return Array.from(this.currentLines.values()).sort((a, b) => a.line - b.line);
  }

  updateLine(line: AnalysisLine): void {
    const lineNumber = line.line || 1;
    this.currentLines.set(lineNumber, line);
  }

  clearLines(): void {
    this.currentLines.clear();
  }

  isEngineAnalyzing(): boolean {
    return this.isAnalyzing;
  }

  destroy(): void {
    if (this.worker) {
      this.send('quit');
      this.worker.terminate();
      this.worker = null;
    }
    this.isInitialized = false;
    this.isAnalyzing = false;
    this.messageHandlers.clear();
    this.currentLines.clear();
  }
}

// Singleton instance
let serviceInstance: StockfishService | null = null;

export function getStockfishService(): StockfishService {
  if (!serviceInstance) {
    serviceInstance = new StockfishService();
  }
  return serviceInstance;
}
