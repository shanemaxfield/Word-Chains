'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { getStockfishService } from '../engine/stockfishService';
import { AnalysisLine, EngineMessage, AnalysisOptions } from '../engine/types';

interface UseStockfishAnalysisOptions {
  multipv?: number;
  depth?: number;
  movetime?: number;
  autoStart?: boolean;
  debounceMs?: number;
}

interface UseStockfishAnalysisReturn {
  analyzing: boolean;
  lines: AnalysisLine[];
  error: string | null;
  bestMove: string | null;
  isReady: boolean;
  start: (fen: string) => Promise<void>;
  stop: () => void;
  setOptions: (options: Partial<UseStockfishAnalysisOptions>) => void;
}

export function useStockfishAnalysis(
  fen: string,
  options: UseStockfishAnalysisOptions = {}
): UseStockfishAnalysisReturn {
  const [analyzing, setAnalyzing] = useState(false);
  const [lines, setLines] = useState<AnalysisLine[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [bestMove, setBestMove] = useState<string | null>(null);
  const [isReady, setIsReady] = useState(false);
  const [internalOptions, setInternalOptions] = useState<UseStockfishAnalysisOptions>({
    multipv: 3,
    depth: 16,
    debounceMs: 300,
    ...options,
  });

  const serviceRef = useRef(getStockfishService());
  const debounceTimerRef = useRef<NodeJS.Timeout | null>(null);
  const isMountedRef = useRef(true);

  // Initialize engine
  useEffect(() => {
    isMountedRef.current = true;
    let mounted = true;

    const initEngine = async () => {
      try {
        await serviceRef.current.init();
        if (mounted) {
          setIsReady(true);
          setError(null);
        }
      } catch (err) {
        if (mounted) {
          setError(err instanceof Error ? err.message : 'Failed to initialize engine');
          setIsReady(false);
        }
      }
    };

    initEngine();

    return () => {
      mounted = false;
      isMountedRef.current = false;
    };
  }, []);

  // Message handler for engine updates
  useEffect(() => {
    const service = serviceRef.current;

    const handleMessage = (message: EngineMessage) => {
      if (!isMountedRef.current) return;

      switch (message.type) {
        case 'info':
          if (message.raw) {
            const parsedLine = service.parseInfoLine(message.raw);
            if (parsedLine) {
              service.updateLine(parsedLine);
              setLines([...service.getCurrentLines()]);
            }
          }
          break;

        case 'bestmove':
          if (message.data?.bestmove) {
            setBestMove(message.data.bestmove);
          }
          setAnalyzing(false);
          break;

        case 'error':
          setError(message.data || 'Unknown engine error');
          setAnalyzing(false);
          break;
      }
    };

    service.addMessageHandler(handleMessage);

    return () => {
      service.removeMessageHandler(handleMessage);
    };
  }, []);

  // Start analysis
  const start = useCallback(
    async (fenToAnalyze: string) => {
      if (!isReady) {
        setError('Engine not ready');
        return;
      }

      try {
        setError(null);
        setAnalyzing(true);
        serviceRef.current.clearLines();
        setLines([]);
        setBestMove(null);

        const analysisOptions: AnalysisOptions = {
          fen: fenToAnalyze,
          multipv: internalOptions.multipv || 1,
        };

        if (internalOptions.movetime) {
          analysisOptions.movetime = internalOptions.movetime;
        } else {
          analysisOptions.depth = internalOptions.depth || 16;
        }

        await serviceRef.current.analyze(analysisOptions);
      } catch (err) {
        if (isMountedRef.current) {
          setError(err instanceof Error ? err.message : 'Analysis failed');
          setAnalyzing(false);
        }
      }
    },
    [isReady, internalOptions]
  );

  // Stop analysis
  const stop = useCallback(() => {
    serviceRef.current.stop();
    setAnalyzing(false);
  }, []);

  // Update options
  const setOptions = useCallback((newOptions: Partial<UseStockfishAnalysisOptions>) => {
    setInternalOptions((prev) => ({ ...prev, ...newOptions }));
  }, []);

  // Auto-start analysis when FEN changes (with debounce)
  useEffect(() => {
    if (!internalOptions.autoStart || !isReady || !fen) return;

    // Clear existing timer
    if (debounceTimerRef.current) {
      clearTimeout(debounceTimerRef.current);
    }

    // Set new timer
    debounceTimerRef.current = setTimeout(() => {
      start(fen);
    }, internalOptions.debounceMs || 300);

    return () => {
      if (debounceTimerRef.current) {
        clearTimeout(debounceTimerRef.current);
      }
    };
  }, [fen, internalOptions.autoStart, isReady, internalOptions.debounceMs, start]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (debounceTimerRef.current) {
        clearTimeout(debounceTimerRef.current);
      }
      // Don't destroy the service as it's a singleton
      // serviceRef.current.destroy();
    };
  }, []);

  return {
    analyzing,
    lines,
    error,
    bestMove,
    isReady,
    start,
    stop,
    setOptions,
  };
}
