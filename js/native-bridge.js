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
      const el = document.getElementById('native-metrics-bar');
      if (!el) return;
      if (!m?.isActive) {
        el.classList.add('hidden');
        return;
      }
      el.classList.remove('hidden');
      const hr = m.heartRate != null ? Math.round(m.heartRate) + ' bpm' : '--';
      const kcal = m.activeCalories != null ? Math.round(m.activeCalories) + ' kcal' : '--';
      const min = Math.floor((m.elapsedSeconds || 0) / 60);
      const sec = (m.elapsedSeconds || 0) % 60;
      el.innerHTML = `
        <span><i class="fas fa-heart text-red-400"></i> ${hr}</span>
        <span><i class="fas fa-fire text-orange-400"></i> ${kcal}</span>
        <span><i class="fas fa-clock text-slate-400"></i> ${min}:${String(sec).padStart(2, '0')}</span>
      `;
    },

    _onWatchEvent(ev) {
      if (!ev || !ev.type) return;
      console.log('Watch event', ev);

      if (ev.type === 'metrics') {
        this._renderMetrics({
          heartRate: ev.heartRate,
          activeCalories: ev.activeCalories,
          elapsedSeconds: 0,
          isActive: true,
        });
        return;
      }

      if (ev.type === 'setComplete' && ev.exId != null && ev.setNum != null) {
        // Simula tap sul set se non già completato
        const state = typeof getSessionState === 'function' ? getSessionState() : {};
        const done = state[ev.exId] || [];
        if (!done.includes(ev.setNum) && typeof handleSetClickNew === 'function') {
          handleSetClickNew(String(ev.exId), parseInt(ev.setNum, 10));
        }
        return;
      }

      if (ev.type === 'setUndo' && ev.exId != null && ev.setNum != null) {
        const state = typeof getSessionState === 'function' ? getSessionState() : {};
        const done = state[ev.exId] || [];
        if (done.includes(ev.setNum) && typeof handleSetClickNew === 'function') {
          handleSetClickNew(String(ev.exId), parseInt(ev.setNum, 10));
        }
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
