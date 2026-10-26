import { registerPlugin } from '@capacitor/core';
import type { WorkoutBridgePlugin } from './definitions';

const WorkoutBridge = registerPlugin<WorkoutBridgePlugin>('WorkoutBridge', {
  web: () => import('./web').then((m) => new m.WorkoutBridgeWeb()),
});

export * from './definitions';
export { WorkoutBridge };
