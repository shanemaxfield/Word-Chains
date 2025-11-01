/// <reference lib="webworker" />

let stockfish: any = null;

// Message handler from main thread
self.onmessage = async (e: MessageEvent<{ cmd: string }>) => {
  const { cmd } = e.data;

  if (cmd === 'init') {
    try {
      // Try to load Stockfish from npm package first
      try {
        // Dynamic import for stockfish.js
        // @ts-ignore - stockfish.js may not have types
        const StockfishModule = await import('stockfish.js');
        stockfish = StockfishModule.default || StockfishModule;

        if (typeof stockfish === 'function') {
          stockfish = stockfish();
        }
      } catch (npmError) {
        console.warn('Failed to load stockfish from npm, trying CDN fallback...', npmError);

        // Fallback: try to load from public/stockfish/stockfish.js
        try {
          // @ts-ignore
          if (typeof self.STOCKFISH !== 'undefined') {
            // @ts-ignore
            stockfish = self.STOCKFISH();
          } else {
            // Import the script
            self.importScripts('/stockfish/stockfish.js');
            // @ts-ignore
            stockfish = self.STOCKFISH ? self.STOCKFISH() : null;
          }
        } catch (cdnError) {
          console.error('Failed to load Stockfish from CDN fallback:', cdnError);
          postMessage({
            type: 'error',
            data: 'Failed to initialize Stockfish engine. Please ensure stockfish.js is available.'
          });
          return;
        }
      }

      if (!stockfish) {
        throw new Error('Stockfish instance is null after initialization');
      }

      // Set up output handler
      stockfish.addMessageListener = stockfish.addMessageListener || stockfish.onmessage;

      if (stockfish.addMessageListener) {
        stockfish.addMessageListener((line: string) => {
          handleEngineOutput(line);
        });
      } else if (stockfish.onmessage) {
        stockfish.onmessage = (line: string) => {
          handleEngineOutput(line);
        };
      } else {
        // Fallback for different Stockfish builds
        stockfish.postMessage = stockfish.postMessage || stockfish.postRun;
        const originalPost = stockfish.print || console.log;
        stockfish.print = (line: string) => {
          handleEngineOutput(line);
          originalPost(line);
        };
      }

      // Send UCI initialization
      sendToEngine('uci');

      postMessage({ type: 'log', data: 'Stockfish worker initialized' });
    } catch (error) {
      console.error('Stockfish initialization error:', error);
      postMessage({
        type: 'error',
        data: `Initialization failed: ${error instanceof Error ? error.message : String(error)}`
      });
    }
  } else {
    // Forward command to engine
    if (stockfish) {
      sendToEngine(cmd);
    } else {
      postMessage({ type: 'error', data: 'Engine not initialized' });
    }
  }
};

function sendToEngine(cmd: string): void {
  if (!stockfish) return;

  try {
    if (stockfish.postMessage) {
      stockfish.postMessage(cmd);
    } else if (stockfish.postRun) {
      stockfish.postRun(cmd);
    } else {
      // Direct stdin write for some builds
      stockfish(cmd);
    }
  } catch (error) {
    console.error('Error sending command to engine:', cmd, error);
    postMessage({ type: 'error', data: `Failed to send command: ${cmd}` });
  }
}

function handleEngineOutput(line: string): void {
  if (!line || typeof line !== 'string') return;

  const trimmed = line.trim();

  // Post raw output for debugging
  postMessage({ type: 'log', raw: trimmed });

  // Parse specific UCI responses
  if (trimmed === 'uciok') {
    postMessage({ type: 'ready', data: 'uciok' });
  } else if (trimmed === 'readyok') {
    postMessage({ type: 'ready', data: 'readyok' });
  } else if (trimmed.startsWith('info')) {
    postMessage({ type: 'info', raw: trimmed });
  } else if (trimmed.startsWith('bestmove')) {
    const parts = trimmed.split(' ');
    const bestmove = parts[1];
    const ponder = parts[3]; // ponder move if available
    postMessage({ type: 'bestmove', data: { bestmove, ponder }, raw: trimmed });
  }
}

// Handle worker errors
self.onerror = (error) => {
  console.error('Worker error:', error);
  postMessage({ type: 'error', data: `Worker error: ${error.message}` });
};

export {};
