'use client';

import { useState, useCallback, useMemo } from 'react';
import { Chessboard } from 'react-chessboard';
import { Chess } from 'chess.js';
import { useStockfishAnalysis } from './hooks/useStockfishAnalysis';
import { AnalysisLine } from './engine/types';

const INITIAL_FEN = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

export default function Home() {
  const [game, setGame] = useState(new Chess());
  const [currentFen, setCurrentFen] = useState(INITIAL_FEN);
  const [moveHistory, setMoveHistory] = useState<string[]>([]);
  const [liveAnalysis, setLiveAnalysis] = useState(false);
  const [multipv, setMultipv] = useState(3);
  const [depth, setDepth] = useState(16);
  const [fenInput, setFenInput] = useState('');

  const {
    analyzing,
    lines,
    error,
    bestMove,
    isReady,
    start,
    stop,
    setOptions,
  } = useStockfishAnalysis(currentFen, {
    multipv,
    depth,
    autoStart: liveAnalysis,
    debounceMs: 300,
  });

  // Update options when multipv or depth changes
  useMemo(() => {
    setOptions({ multipv, depth });
  }, [multipv, depth, setOptions]);

  // Handle piece drop
  const onDrop = useCallback(
    (sourceSquare: string, targetSquare: string) => {
      const gameCopy = new Chess(game.fen());

      try {
        const move = gameCopy.move({
          from: sourceSquare,
          to: targetSquare,
          promotion: 'q', // always promote to queen for simplicity
        });

        if (move === null) return false;

        setGame(gameCopy);
        setCurrentFen(gameCopy.fen());
        setMoveHistory([...moveHistory, move.san]);
        return true;
      } catch {
        return false;
      }
    },
    [game, moveHistory]
  );

  // Reset board
  const handleReset = useCallback(() => {
    const newGame = new Chess();
    setGame(newGame);
    setCurrentFen(INITIAL_FEN);
    setMoveHistory([]);
    stop();
  }, [stop]);

  // Load FEN
  const handleLoadFen = useCallback(() => {
    try {
      const newGame = new Chess(fenInput.trim());
      setGame(newGame);
      setCurrentFen(newGame.fen());
      setMoveHistory([]);
      setFenInput('');
    } catch {
      alert('Invalid FEN string');
    }
  }, [fenInput]);

  // Start analysis manually
  const handleStartAnalysis = useCallback(() => {
    start(currentFen);
  }, [start, currentFen]);

  // Pretty-print PV moves
  const formatPv = useCallback((pv: string[], rootFen: string): string => {
    if (!pv || pv.length === 0) return '';

    try {
      const tempGame = new Chess(rootFen);
      const sanMoves: string[] = [];

      for (const algebraic of pv.slice(0, 10)) { // limit to first 10 moves
        try {
          const move = tempGame.move(algebraic);
          if (!move) break;
          sanMoves.push(move.san);
        } catch {
          break;
        }
      }

      return sanMoves.join(' ');
    } catch {
      return pv.slice(0, 10).join(' ');
    }
  }, []);

  // Format evaluation
  const formatEval = useCallback((line: AnalysisLine): string => {
    if (line.eval.mate !== undefined) {
      return `#${line.eval.mate > 0 ? '+' : ''}${line.eval.mate}`;
    }
    if (line.eval.cp !== undefined) {
      const pawns = line.eval.cp / 100;
      return pawns >= 0 ? `+${pawns.toFixed(2)}` : pawns.toFixed(2);
    }
    return '0.00';
  }, []);

  return (
    <div className="min-h-screen bg-gray-900 text-gray-100">
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-3xl font-bold mb-8 text-center">
          Stockfish Analysis Board
        </h1>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Left: Board */}
          <div className="flex flex-col">
            <div className="mb-4">
              <Chessboard
                position={currentFen}
                onPieceDrop={onDrop}
                boardWidth={560}
                customBoardStyle={{
                  borderRadius: '4px',
                  boxShadow: '0 5px 15px rgba(0, 0, 0, 0.5)',
                }}
              />
            </div>

            {/* Move History */}
            <div className="bg-gray-800 rounded-lg p-4 mb-4">
              <h3 className="text-sm font-semibold mb-2 text-gray-400">
                Move History
              </h3>
              <div className="flex flex-wrap gap-1 min-h-[2rem]">
                {moveHistory.length > 0 ? (
                  moveHistory.map((move, idx) => (
                    <span
                      key={idx}
                      className="text-sm bg-gray-700 px-2 py-1 rounded"
                    >
                      {Math.floor(idx / 2) + 1}
                      {idx % 2 === 0 ? '.' : '...'} {move}
                    </span>
                  ))
                ) : (
                  <span className="text-sm text-gray-500">No moves yet</span>
                )}
              </div>
            </div>

            {/* FEN Input */}
            <div className="bg-gray-800 rounded-lg p-4">
              <h3 className="text-sm font-semibold mb-2 text-gray-400">
                Load Position
              </h3>
              <div className="flex gap-2">
                <input
                  type="text"
                  placeholder="Paste FEN string..."
                  value={fenInput}
                  onChange={(e) => setFenInput(e.target.value)}
                  className="flex-1 bg-gray-700 border border-gray-600 rounded px-3 py-2 text-sm focus:outline-none focus:border-blue-500"
                />
                <button
                  onClick={handleLoadFen}
                  disabled={!fenInput.trim()}
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-700 disabled:text-gray-500 rounded text-sm font-medium transition-colors"
                >
                  Load FEN
                </button>
              </div>
              <div className="mt-2 text-xs text-gray-500 font-mono break-all">
                Current: {currentFen}
              </div>
            </div>
          </div>

          {/* Right: Analysis Panel */}
          <div className="flex flex-col">
            {/* Controls */}
            <div className="bg-gray-800 rounded-lg p-4 mb-4">
              <h3 className="text-sm font-semibold mb-3 text-gray-400">
                Analysis Controls
              </h3>

              <div className="grid grid-cols-2 gap-3 mb-3">
                <div>
                  <label className="block text-xs text-gray-400 mb-1">
                    MultiPV Lines
                  </label>
                  <input
                    type="number"
                    min="1"
                    max="10"
                    value={multipv}
                    onChange={(e) => setMultipv(parseInt(e.target.value, 10))}
                    className="w-full bg-gray-700 border border-gray-600 rounded px-3 py-2 text-sm focus:outline-none focus:border-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-xs text-gray-400 mb-1">
                    Depth
                  </label>
                  <input
                    type="number"
                    min="1"
                    max="30"
                    value={depth}
                    onChange={(e) => setDepth(parseInt(e.target.value, 10))}
                    className="w-full bg-gray-700 border border-gray-600 rounded px-3 py-2 text-sm focus:outline-none focus:border-blue-500"
                  />
                </div>
              </div>

              <div className="flex gap-2 mb-3">
                <button
                  onClick={handleStartAnalysis}
                  disabled={!isReady || analyzing}
                  className="flex-1 px-4 py-2 bg-green-600 hover:bg-green-700 disabled:bg-gray-700 disabled:text-gray-500 rounded text-sm font-medium transition-colors"
                >
                  {analyzing ? 'Analyzing...' : 'Start Analysis'}
                </button>
                <button
                  onClick={stop}
                  disabled={!analyzing}
                  className="flex-1 px-4 py-2 bg-red-600 hover:bg-red-700 disabled:bg-gray-700 disabled:text-gray-500 rounded text-sm font-medium transition-colors"
                >
                  Stop
                </button>
              </div>

              <div className="flex gap-2">
                <button
                  onClick={handleReset}
                  className="flex-1 px-4 py-2 bg-gray-700 hover:bg-gray-600 rounded text-sm font-medium transition-colors"
                >
                  Reset Board
                </button>
                <button
                  onClick={() => setLiveAnalysis(!liveAnalysis)}
                  className={`flex-1 px-4 py-2 rounded text-sm font-medium transition-colors ${
                    liveAnalysis
                      ? 'bg-blue-600 hover:bg-blue-700'
                      : 'bg-gray-700 hover:bg-gray-600'
                  }`}
                >
                  {liveAnalysis ? '🔴 Live ON' : 'Live Analysis'}
                </button>
              </div>

              {/* Status */}
              <div className="mt-3 text-xs">
                <div className="flex items-center gap-2">
                  <span
                    className={`w-2 h-2 rounded-full ${
                      isReady ? 'bg-green-500' : 'bg-red-500'
                    }`}
                  />
                  <span className="text-gray-400">
                    {isReady ? 'Engine Ready' : 'Initializing...'}
                  </span>
                </div>
              </div>
            </div>

            {/* Error Display */}
            {error && (
              <div className="bg-red-900/50 border border-red-700 rounded-lg p-3 mb-4 text-sm">
                <strong>Error:</strong> {error}
              </div>
            )}

            {/* Analysis Lines */}
            <div className="bg-gray-800 rounded-lg p-4 flex-1">
              <h3 className="text-sm font-semibold mb-3 text-gray-400">
                Analysis Lines
                {bestMove && (
                  <span className="ml-2 text-blue-400">
                    Best: {bestMove}
                  </span>
                )}
              </h3>

              {lines.length > 0 ? (
                <div className="space-y-2">
                  {lines.map((line) => (
                    <div
                      key={line.line}
                      className={`p-3 rounded ${
                        line.line === 1
                          ? 'bg-blue-900/30 border border-blue-700'
                          : 'bg-gray-700'
                      }`}
                    >
                      <div className="flex items-start justify-between mb-1">
                        <span className="text-xs text-gray-400">
                          Line {line.line} (d{line.depth})
                        </span>
                        <span
                          className={`text-sm font-bold ${
                            line.eval.mate !== undefined
                              ? line.eval.mate > 0
                                ? 'text-green-400'
                                : 'text-red-400'
                              : (line.eval.cp || 0) > 0
                              ? 'text-green-400'
                              : (line.eval.cp || 0) < 0
                              ? 'text-red-400'
                              : 'text-gray-400'
                          }`}
                        >
                          {formatEval(line)}
                        </span>
                      </div>
                      <div className="text-sm text-gray-200 font-mono">
                        {formatPv(line.pv, currentFen)}
                      </div>
                      <div className="flex gap-3 mt-1 text-xs text-gray-500">
                        <span>Nodes: {line.nodes.toLocaleString()}</span>
                        {line.nps && (
                          <span>
                            NPS: {(line.nps / 1000).toFixed(0)}k
                          </span>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="text-center text-gray-500 py-8">
                  {analyzing
                    ? 'Analysis in progress...'
                    : 'Start analysis to see engine lines'}
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
