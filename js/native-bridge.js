/**
 * Bridge Capacitor ↔ HealthKit ↔ Apple Watch
 * Su browser web resta no-op; su iOS nativo attiva metriche e sync Watch.
 */
(function (global) {
  const NativeWorkout = {
    available: false,
    watchReachable: false,
    _listener: null,
    _metricsTimer: null,

    async init() {
      try {
        if (!global.Capacitor?.isNativePlatform?.()) {
          this.available = false;
          return false;
        }
        const plugin = global.Capacitor.Plugins?.WorkoutBridge;
        if (!plugin) {
          console.warn('WorkoutBridge plugin non registrato');
          return false;
        }
        const status = await plugin.isNativeAvailable();
        this.available = !!status.available;
        this.watchReachable = !!status.watchReachable;
        if (this.available) {
          await plugin.requestPermissions();
          this._listener = await plugin.addListener('watchEvent', (ev) => {
            this._onWatchEvent(ev);
          });
        }
        return this.available;
      } catch (e) {
        console.warn('NativeWorkout.init', e);
        return false;
      }
    },

    plugin() {
      return global.Capacitor?.Plugins?.WorkoutBridge;
    },

    async start(sessionId, gruppo) {
      const p = this.plugin();
      if (!p || !this.available) return null;
      try {
        await p.startNativeWorkout({ sessionId, gruppo, activityType: 'strength' });
        this._startMetricsPolling();
        return true;
      } catch (e) {
        console.warn('NativeWorkout.start', e);
        return false;
      }
    },

    async end() {
      const p = this.plugin();
      this._stopMetricsPolling();
      if (!p || !this.available) return null;
      try {
        return await p.endNativeWorkout();
      } catch (e) {
        console.warn('NativeWorkout.end', e);
        return null;
      }
    },

    async syncSession(sessionPayload) {
      const p = this.plugin();
      if (!p || !this.available) return;
      try {
        await p.syncSessionToWatch({ session: sessionPayload });
      } catch (e) {
        console.warn('NativeWorkout.syncSession', e);
      }
    },

    async startRecovery(seconds, exerciseName) {
      const p = this.plugin();
      if (!p || !this.available) return;
      try {
        await p.startWatchRecovery({ seconds, exerciseName: exerciseName || '' });
      } catch (e) {
        console.warn('NativeWorkout.startRecovery', e);
      }
    },

    async stopRecovery() {
      const p = this.plugin();
      if (!p || !this.available) return;
      try {
        await p.stopWatchRecovery();
      } catch (_) {}
    },

    async syncGroupsToWatch(groups) {
      const p = this.plugin();
      if (!p || !this.available) return;
      try {
        if (typeof p.syncGroupsToWatch === 'function') {
          await p.syncGroupsToWatch({ groups: groups || [] });
        } else if (typeof p.syncSessionToWatch === 'function') {
          // fallback: reuse generic send via session sync shape not ideal — plugin method preferred
        }
      } catch (e) {
        console.warn('NativeWorkout.syncGroupsToWatch', e);
      }
    },

    buildWatchPayload(gruppo, sessionId, startedAt) {
      const cards = [...document.querySelectorAll('#workout-exercises .glass-card')];
      const exercises = [];
      let currentExerciseIndex = 0;

      cards.forEach((card, idx) => {
        const title = card.querySelector('h3')?.textContent?.trim() || 'Esercizio';
        const serieInput = card.querySelector('input[id^="serie-"]');
        if (!serieInput) return;
        const exId = serieInput.id.replace('serie-', '');
        const serieVal = parseInt(serieInput.value) || 3;
        const state = (typeof getSessionState === 'function' ? getSessionState() : {})[exId] || [];
        const sets = [];
        for (let i = 1; i <= serieVal; i++) {
          sets.push({
            set: i,
            reps: parseInt(document.getElementById('reps-' + exId + '-' + i)?.value) || 10,
            peso: parseFloat(document.getElementById('peso-' + exId + '-' + i)?.value) || 0,
            done: state.includes(i),
          });
        }
        if (state.length < serieVal && currentExerciseIndex === 0 && idx > 0) {
          // keep first incomplete as current — refined below
        }
        exercises.push({ exId: String(exId), name: title, sets, currentSet: (state[state.length - 1] || 0) + 1 });
      });

      // primo esercizio con set incompleti
      const incomplete = exercises.findIndex((ex) => ex.sets.some((s) => !s.done));
      currentExerciseIndex = incomplete >= 0 ? incomplete : 0;

      return {
        id: sessionId,
        gruppo,
        startedAt: startedAt || new Date().toISOString(),
        exercises,
        currentExerciseIndex,
      };
    },

    _startMetricsPolling() {
      this._stopMetricsPolling();
      this._metricsTimer = setInterval(async () => {
        const p = this.plugin();
        if (!p) return;
        try {
          const m = await p.getLiveMetrics();
          this._renderMetrics(m);
        } catch (_) {}
      }, 5000);
    },

    _stopMetricsPolling() {
      if (this._metricsTimer) clearInterval(this._metricsTimer);
      this._metricsTimer = null;
    },

    _renderMetrics(m) {
      // Aggiorna il live workout stile Fitness se attivo
      if (global.liveWorkout && m) {
        if (m.heartRate != null) global.liveWorkout.heartRate = m.heartRate;
        if (m.activeCalories != null) {
          global.liveWorkout.nativeActiveKcal = Math.round(m.activeCalories);
          global.liveWorkout.activeCalories = global.liveWorkout.nativeActiveKcal;
        }
        if (typeof global.refreshLiveMetricsUI === 'function') global.refreshLiveMetricsUI();
      }
      const el = document.getElementById('live-hr');
      if (el && m?.heartRate != null) el.textContent = Math.round(m.heartRate);
      const ka = document.getElementById('live-kcal-active');
      if (ka && m?.activeCalories != null) ka.textContent = Math.round(m.activeCalories);
    },

    _onWatchEvent(ev) {
      if (!ev || !ev.type) return;
      console.log('Watch event', ev);

      if (ev.type === 'startWorkoutFromWatch') {
        const gruppo = ev.gruppo || ev.group || '';
        if (typeof startWorkoutFromWatch === 'function') {
          startWorkoutFromWatch(gruppo);
        }
        return;
      }

      if (ev.type === 'metrics') {
        this._renderMetrics({
          heartRate: ev.heartRate,
          activeCalories: ev.activeCalories,
          elapsedSeconds: 0,
          isActive: true,
        });
        return;
      }

      if (ev.type === 'setComplete') {
        if (typeof completeLiveSet === 'function' && global.liveWorkout) {
          completeLiveSet();
        }
        return;
      }

      if (ev.type === 'setUndo' && global.liveWorkout) {
        const ex = global.liveWorkout.exercises[global.liveWorkout.exIndex];
        const last = [...(ex?.sets || [])].reverse().find((s) => s.done);
        if (last) {
          last.done = false;
          if (typeof persistLiveSetToStorage === 'function') persistLiveSetToStorage();
          if (typeof renderLiveStep === 'function') renderLiveStep();
        }
        return;
      }

      if (ev.type === 'nextExercise' && typeof nextLiveExercise === 'function') {
        nextLiveExercise(false);
        return;
      }
      if (ev.type === 'prevExercise' && global.liveWorkout) {
        global.liveWorkout.exIndex = Math.max(0, global.liveWorkout.exIndex - 1);
        if (typeof renderLiveStep === 'function') renderLiveStep();
        return;
      }

      if (ev.type === 'finishSession' && typeof finishWorkoutSession === 'function') {
        // Forza salvataggio senza secondo confirm se già chiesto dal Watch
        if (confirm('Il Watch ha chiesto di terminare. Salvare la sessione?')) {
          finishWorkoutSession(true);
        }
        return;
      }

      if (ev.type === 'recoveryDone') {
        const overlay = document.getElementById('timer-overlay');
        if (overlay && !overlay.classList.contains('hidden') && typeof stopTimer === 'function') {
          stopTimer();
        }
      }
    },
  };

  global.NativeWorkout = NativeWorkout;
})(window);
