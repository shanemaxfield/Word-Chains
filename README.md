# Stockfish Analysis Board

A modern chess analysis board powered by **Stockfish WASM** running locally in your browser. Built with Next.js 14, React, TypeScript, and chess.js.

## Features

✅ **Local Stockfish Engine** - No server required, runs entirely in a Web Worker
✅ **Multi-PV Analysis** - View top N engine lines simultaneously
✅ **Live Analysis Mode** - Auto-analyze positions as you play
✅ **Interactive Board** - Make moves via drag-and-drop
✅ **FEN Support** - Load any position via FEN string
✅ **Pretty-Printed Moves** - PV moves displayed in Standard Algebraic Notation
✅ **Eval Display** - Shows centipawn scores and mate announcements
✅ **Dark Theme** - Clean, minimal UI with Tailwind CSS

---

## Quick Start

### Installation

Using **pnpm** (recommended):

```bash
pnpm install
pnpm dev
```

Using **npm**:

```bash
npm install
npm run dev
```

Using **yarn**:

```bash
yarn install
yarn dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

---

## Project Structure

```
├── app/
│   ├── engine/
│   │   ├── types.ts              # TypeScript interfaces
│   │   ├── stockfish.worker.ts   # Web Worker (loads Stockfish)
│   │   └── stockfishService.ts   # Engine service wrapper
│   ├── hooks/
│   │   └── useStockfishAnalysis.ts  # React hook for analysis
│   ├── layout.tsx                # Root layout
│   ├── page.tsx                  # Main UI (board + analysis)
│   └── globals.css               # Tailwind styles
├── public/
│   └── stockfish/
│       └── README.txt            # CDN fallback instructions
├── package.json
├── tsconfig.json
├── next.config.mjs
└── tailwind.config.ts
```

---

## Usage

### Making Moves

- **Drag and drop** pieces on the board
- Move history appears below the board
- Current FEN is displayed at the bottom

### Starting Analysis

1. Set **MultiPV** (number of lines, 1-10)
2. Set **Depth** (search depth, 1-30)
3. Click **"Start Analysis"**
4. Engine lines appear on the right panel

### Live Analysis

- Toggle **"Live Analysis"** button
- Analysis auto-restarts on every move (300ms debounce)
- Disable to manually control analysis

### Loading Positions

1. Paste FEN string into input field
2. Click **"Load FEN"**
3. Board updates to the new position

### Reset

- Click **"Reset Board"** to return to starting position
- Clears analysis lines and move history

---

## Stockfish Setup

### Primary: NPM Package

The project uses the `stockfish.js` npm package by default. It should work out of the box after `npm install`.

### Fallback: CDN / Manual

If the npm package fails to load, the worker attempts to load from `public/stockfish/stockfish.js`.

**To add the fallback:**

1. Download `stockfish.js` from:
   - [Official Releases](https://github.com/nmrugg/stockfish.js/releases)
   - [CDN](https://cdn.jsdelivr.net/npm/stockfish.js@10.0.2/stockfish.js)

2. Place the file at:
   ```
   public/stockfish/stockfish.js
   ```

3. The worker auto-detects and uses it if npm import fails

**Test the fallback:**
- Open DevTools Console
- Look for "Failed to load stockfish from npm, trying CDN fallback..."
- If successful: "Stockfish worker initialized"

---

## Configuration

### Engine Options

Edit defaults in `app/page.tsx`:

```typescript
const [multipv, setMultipv] = useState(3);   // Number of lines
const [depth, setDepth] = useState(16);      // Search depth
```

### Hook Options

Modify in `app/hooks/useStockfishAnalysis.ts`:

```typescript
{
  multipv: 3,          // Default lines
  depth: 16,           // Default depth
  debounceMs: 300,     // Live analysis delay
  autoStart: false,    // Auto-start on mount
}
```

### Worker Options

Adjust UCI commands in `app/engine/stockfishService.ts`:

```typescript
// Example: Set hash size
this.send('setoption name Hash value 128');
```

---

## TypeScript Types

### `AnalysisLine`

```typescript
interface AnalysisLine {
  line: number;           // MultiPV line number (1-indexed)
  pv: string[];           // Principal variation (algebraic)
  eval: {
    cp?: number;          // Centipawns
    mate?: number;        // Mate in N
  };
  depth: number;          // Search depth
  nodes: number;          // Nodes searched
  nps?: number;           // Nodes per second
  time?: number;          // Time in ms
}
```

### `AnalysisOptions`

```typescript
interface AnalysisOptions {
  fen: string;
  multipv?: number;
  depth?: number;
  movetime?: number;  // Alternative to depth
}
```

---

## Troubleshooting

### Engine Not Loading

**Symptoms:**
- "Initializing..." status persists
- No analysis lines appear

**Fixes:**
1. Check browser console for errors
2. Verify `stockfish.js` package installed: `npm list stockfish.js`
3. Try CDN fallback (see Stockfish Setup above)
4. Ensure Web Workers enabled in browser

### Worker Path Issues

**Symptoms:**
- "Failed to construct 'Worker'"

**Fixes:**
1. Ensure Next.js 14+ is installed
2. Check `next.config.mjs` has webpack worker config
3. Verify worker file at `app/engine/stockfish.worker.ts`

### CSP Errors

**Symptoms:**
- "Refused to create a worker from 'blob:'"

**Fixes:**
1. Add to `next.config.mjs`:
   ```javascript
   async headers() {
     return [{
       source: '/:path*',
       headers: [
         { key: 'Cross-Origin-Embedder-Policy', value: 'require-corp' },
         { key: 'Cross-Origin-Opener-Policy', value: 'same-origin' },
       ],
     }];
   }
   ```

### Analysis Freezes

**Symptoms:**
- Lines stop updating mid-analysis

**Fixes:**
1. Click "Stop" then restart
2. Reduce depth (try 12-14)
3. Reduce MultiPV (try 1-2 lines)
4. Check browser performance (close other tabs)

### Invalid FEN

**Symptoms:**
- Alert "Invalid FEN string"

**Fixes:**
1. Verify FEN format: `rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1`
2. Use online FEN validator
3. Copy FEN from chess.com or lichess

---

## Build & Deploy

### Development

```bash
pnpm dev     # Start dev server (http://localhost:3000)
pnpm build   # Build for production
pnpm start   # Start production server
pnpm lint    # Run ESLint
```

### Production Build

```bash
pnpm build
pnpm start
```

Or deploy to **Vercel**:

```bash
vercel deploy
```

### Environment Variables

None required! Engine runs 100% client-side.

---

## Browser Compatibility

| Browser | Version | Status |
|---------|---------|--------|
| Chrome  | 90+     | ✅ Full support |
| Firefox | 88+     | ✅ Full support |
| Safari  | 15+     | ✅ Full support |
| Edge    | 90+     | ✅ Full support |

**Requirements:**
- Web Workers
- WebAssembly (WASM)
- ES2020+ support

---

## Performance Tips

1. **Reduce MultiPV** - Fewer lines = faster analysis
2. **Limit Depth** - Depth 16-18 is usually sufficient
3. **Use movetime** - Instead of depth for time-limited analysis:
   ```typescript
   setOptions({ movetime: 3000 }); // 3 seconds
   ```
4. **Disable Live Analysis** - When playing rapidly
5. **Close other tabs** - Free up CPU for Stockfish

---

## UCI Protocol

The engine service implements core UCI commands:

- `uci` - Initialize engine
- `isready` / `readyok` - Synchronization
- `ucinewgame` - Reset for new position
- `position fen <fen>` - Set position
- `setoption name <name> value <value>` - Configure engine
- `go depth <n>` - Start analysis
- `stop` - Stop analysis
- `quit` - Shutdown

**Parsed info fields:**
- `depth`, `seldepth`
- `multipv` (line number)
- `score cp` / `score mate`
- `nodes`, `nps`, `time`
- `pv` (principal variation)

---

## Development Notes

### Adding UCI Options

Edit `app/engine/stockfishService.ts`:

```typescript
async analyze(options: AnalysisOptions) {
  // Add custom options
  this.send('setoption name Threads value 4');
  this.send('setoption name Hash value 256');
  // ...
}
```

### Custom Analysis Modes

Modify the `go` command in `stockfishService.ts`:

```typescript
// Infinite analysis
this.send('go infinite');

// Move time
this.send('go movetime 5000');

// Nodes
this.send('go nodes 1000000');
```

### Worker Debugging

Enable verbose logging in `stockfish.worker.ts`:

```typescript
function handleEngineOutput(line: string): void {
  console.log('[Engine]', line); // Add this
  // ...
}
```

---

## License

This project is open source. Stockfish is licensed under GPLv3.

---

## Credits

- **Stockfish** - The world's strongest chess engine
- **chess.js** - Chess logic and move validation
- **react-chessboard** - Beautiful React chess board component
- **Next.js** - React framework
- **Tailwind CSS** - Utility-first CSS framework

---

## Support

**Issues:**
- Check browser console for errors
- Review troubleshooting section above
- Ensure latest Next.js 14 and dependencies

**Questions:**
- Review UCI protocol documentation
- Check Stockfish.js GitHub issues
- Verify Web Worker compatibility

---

## Roadmap

- [ ] Move takeback/forward navigation
- [ ] Save/load PGN files
- [ ] Opening book integration
- [ ] Position evaluation graph
- [ ] Multiple engine support
- [ ] Tablebase integration
- [ ] Game analysis mode (annotate full games)

---

**Enjoy analyzing!** ♟️
