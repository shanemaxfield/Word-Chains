STOCKFISH CDN FALLBACK
======================

If the npm stockfish.js package fails to load, the worker will attempt to load
Stockfish from this directory.

To add Stockfish manually:

1. Download stockfish.js from:
   https://github.com/nmrugg/stockfish.js/releases

2. Place stockfish.js in this directory (public/stockfish/)

3. The file should export a global STOCKFISH function

Alternative sources:
- https://cdn.jsdelivr.net/npm/stockfish.js@10.0.2/stockfish.js
- Direct from official stockfish.js repository

The worker (app/engine/stockfish.worker.ts) will automatically detect and use
this file if npm import fails.
