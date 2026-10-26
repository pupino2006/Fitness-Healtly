export interface WorkoutSessionPayload {
  id: string;
  gruppo: string;
  startedAt: string;
  exercises: Array<{
    exId: string;
    name: string;
    sets: Array<{ set: number; reps: number; peso: number; done?: boolean }>;
    currentSet?: number;
  }>;
  currentExerciseIndex: number;
}

export interface LiveMetrics {
  heartRate: number | null;
  activeCalories: number | null;
  elapsedSeconds: number;
  isActive: boolean;
}

export interface WorkoutBridgePlugin {
  /** Richiede permessi HealthKit (workout, FC, energia attiva). */
  requestPermissions(): Promise<{ granted: boolean }>;

  /** Avvia sessione HealthKit (si riflette sull'Apple Watch). */
  startNativeWorkout(options: {
    sessionId: string;
    gruppo: string;
    activityType?: string;
  }): Promise<{ ok: boolean }>;

  /** Termina sessione HealthKit e restituisce metriche finali. */
  endNativeWorkout(): Promise<{
    ok: boolean;
    activeCalories: number | null;
    averageHeartRate: number | null;
    durationSeconds: number;
  }>;

  /** Metriche live (FC / kcal) durante il workout. */
  getLiveMetrics(): Promise<LiveMetrics>;

  /** Invia lo stato sessione all'Apple Watch (esercizi, set, recupero). */
  syncSessionToWatch(options: { session: WorkoutSessionPayload }): Promise<{ ok: boolean }>;

  /** Avvia timer recupero sul Watch (+ haptic). */
  startWatchRecovery(options: { seconds: number; exerciseName?: string }): Promise<{ ok: boolean }>;

  /** Ferma timer recupero sul Watch. */
  stopWatchRecovery(): Promise<{ ok: boolean }>;

  /** True se siamo in Capacitor iOS nativo. */
  isNativeAvailable(): Promise<{ available: boolean; watchReachable: boolean }>;

  addListener(
    eventName: 'watchEvent',
    listenerFunc: (event: {
      type: 'setComplete' | 'setUndo' | 'nextExercise' | 'prevExercise' | 'finishSession' | 'recoveryDone';
      exId?: string;
      setNum?: number;
      seconds?: number;
    }) => void
  ): Promise<{ remove: () => void }>;
}
