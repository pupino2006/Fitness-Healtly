import { WebPlugin } from '@capacitor/core';
import type { LiveMetrics, WorkoutBridgePlugin, WorkoutSessionPayload } from './definitions';

export class WorkoutBridgeWeb extends WebPlugin implements WorkoutBridgePlugin {
  async requestPermissions(): Promise<{ granted: boolean }> {
    return { granted: false };
  }

  async startNativeWorkout(): Promise<{ ok: boolean }> {
    console.warn('[WorkoutBridge] HealthKit disponibile solo su iOS nativo');
    return { ok: false };
  }

  async endNativeWorkout() {
    return { ok: false, activeCalories: null, averageHeartRate: null, durationSeconds: 0 };
  }

  async getLiveMetrics(): Promise<LiveMetrics> {
    return { heartRate: null, activeCalories: null, elapsedSeconds: 0, isActive: false };
  }

  async syncSessionToWatch(_options: { session: WorkoutSessionPayload }) {
    return { ok: false };
  }

  async syncGroupsToWatch(_options: { groups: string[] }) {
    return { ok: false, count: 0 };
  }

  async startWatchRecovery() {
    return { ok: false };
  }

  async stopWatchRecovery() {
    return { ok: false };
  }

  async isNativeAvailable() {
    return { available: false, watchReachable: false };
  }
}
