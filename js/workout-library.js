/**
 * Demo stick-figure, split superserie, schede 50 min e alternative
 * pronte da mettere al posto di un singolo esercizio.
 */
(function (global) {
  const HEAVY = [220, 240, 280, 320, 360, 400];

  function exerciseSides(name) {
    const raw = String(name || '').replace(/\s*\(SS[^)]*\)/gi, '').trim();
    if (/frontali\s*\+\s*laterali\s*\+\s*posteriori/i.test(raw)) {
      return ['Alzate frontali', 'Alzate laterali', 'Alzate posteriori'];
    }
    if (raw.includes(' / ')) {
      return raw.split(' / ').map((part) => part.trim()).filter(Boolean).slice(0, 3);
    }
    return [raw || 'Esercizio'];
  }

  function escapeHtml(value) {
    return String(value ?? '').replace(/[&<>"']/g, (c) => ({
      '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
    }[c]));
  }

  /* ---------- Stick-figure demos (due pose astratte) ---------- */

  function stickKind(name) {
    const t = String(name || '');
    if (/pullover/i.test(t)) return 'pullover';
    if (/hip\s*thrust|thrust/i.test(t)) return 'hipthrust';
    if (/hyperextension|iperestension/i.test(t)) return 'backext';
    if (/rumen|stacco/i.test(t)) return 'rdl';
    if (/wall\s*sit/i.test(t)) return 'wallsit';
    if (/affond|lunge|piston|step-?up/i.test(t)) return 'lunge';
    if (/leg\s*curl|femoral|lug\s*curl/i.test(t)) return 'legcurl';
    if (/leg\s*extension|extension/i.test(t) && /leg|gamba|quad/i.test(t)) return 'legext';
    if (/leg\s*press|pressa/i.test(t)) return 'legpress';
    if (/polpacc|calf/i.test(t)) return 'calf';
    if (/squat|accosciat|goblet/i.test(t)) return 'squat';
    if (/chest\s*press/i.test(t)) return 'chestpress';
    if (/croci|fly|peck/i.test(t)) return 'fly';
    if (/inclinat/i.test(t)) return 'incline';
    if (/panca\s*stretta|close.?grip/i.test(t)) return 'closebench';
    if (/panca|bench/i.test(t)) return 'bench';
    if (/flession|push-?up/i.test(t)) return 'pushup';
    if (/push\s*down|pushdown|french/i.test(t)) return 'pushdown';
    if (/hammer/i.test(t)) return 'hammer';
    if (/curl|bicip/i.test(t)) return 'curl';
    if (/scrollat|shrug/i.test(t)) return 'shrug';
    if (/posteriori|rear|face\s*pull|tirate posteriori/i.test(t)) return 'rear';
    if (/frontali/i.test(t)) return 'front';
    if (/laterali/i.test(t)) return 'lateral';
    if (/lento|overhead|military|verticale/i.test(t)) return 'ohp';
    if (/lat|pulldown|pull\s*down/i.test(t)) return 'lat';
    if (/rematore|pulley|row|australian/i.test(t)) return 'row';
    if (/addominal|crunch|abs/i.test(t)) return 'crunch';
    return 'generic';
  }

  function stickPair(kind) {
    const stroke = '#fb923c';
    const soft = '#64748b';
    const head = (cx, cy) => `<circle cx="${cx}" cy="${cy}" r="5" fill="none" stroke="${stroke}" stroke-width="2"/>`;
    const line = (a, b, c, d, col) => `<line x1="${a}" y1="${b}" x2="${c}" y2="${d}" stroke="${col || stroke}" stroke-width="2.4" stroke-linecap="round"/>`;
    const bar = (x1, y1, x2, y2) => line(x1, y1, x2, y2, soft);

    const poses = {
      squat: [
        head(40, 18) + line(40, 23, 40, 48) + line(40, 32, 26, 42) + line(40, 32, 54, 42) + line(40, 48, 28, 72) + line(40, 48, 52, 72) + line(28, 72, 24, 88) + line(52, 72, 56, 88) + bar(22, 90, 58, 90),
        head(40, 28) + line(40, 33, 40, 52) + line(40, 40, 24, 48) + line(40, 40, 56, 48) + line(40, 52, 26, 68) + line(40, 52, 54, 68) + line(26, 68, 22, 86) + line(54, 68, 58, 86) + bar(20, 90, 60, 90)
      ],
      lunge: [
        head(36, 16) + line(36, 21, 36, 46) + line(36, 30, 24, 40) + line(36, 30, 50, 38) + line(36, 46, 24, 78) + line(36, 46, 56, 70) + line(24, 78, 20, 90) + line(56, 70, 62, 90),
        head(38, 18) + line(38, 23, 38, 48) + line(38, 32, 26, 42) + line(38, 32, 52, 40) + line(38, 48, 28, 80) + line(38, 48, 58, 68) + line(28, 80, 22, 90) + line(58, 68, 66, 88)
      ],
      legpress: [
        head(22, 30) + line(22, 35, 34, 48) + line(34, 48, 58, 42) + line(34, 48, 58, 58) + bar(62, 34, 62, 66) + bar(58, 38, 66, 38) + bar(58, 62, 66, 62),
        head(22, 30) + line(22, 35, 36, 50) + line(36, 50, 70, 40) + line(36, 50, 70, 60) + bar(74, 32, 74, 68) + bar(70, 36, 78, 36) + bar(70, 64, 78, 64)
      ],
      legext: [
        head(30, 20) + line(30, 25, 30, 48) + line(30, 48, 48, 48) + line(48, 48, 62, 70) + line(30, 35, 18, 48) + line(30, 35, 42, 42) + bar(14, 72, 70, 72),
        head(30, 20) + line(30, 25, 30, 48) + line(30, 48, 48, 48) + line(48, 48, 68, 42) + line(30, 35, 18, 48) + line(30, 35, 42, 42) + bar(14, 72, 70, 72)
      ],
      legcurl: [
        head(24, 28) + line(24, 33, 40, 40) + line(40, 40, 58, 40) + line(58, 40, 68, 58) + bar(18, 70, 72, 70),
        head(24, 28) + line(24, 33, 40, 40) + line(40, 40, 58, 40) + line(58, 40, 62, 22) + bar(18, 70, 72, 70)
      ],
      calf: [
        head(40, 14) + line(40, 19, 40, 50) + line(40, 28, 28, 40) + line(40, 28, 52, 40) + line(40, 50, 34, 78) + line(40, 50, 46, 78) + line(34, 78, 32, 90) + line(46, 78, 48, 90) + bar(26, 92, 54, 92),
        head(40, 12) + line(40, 17, 40, 48) + line(40, 26, 28, 38) + line(40, 26, 52, 38) + line(40, 48, 34, 72) + line(40, 48, 46, 72) + line(34, 72, 34, 84) + line(46, 72, 46, 84) + bar(26, 92, 54, 92)
      ],
      rdl: [
        head(40, 16) + line(40, 21, 40, 48) + line(40, 32, 24, 32) + line(40, 32, 56, 32) + bar(20, 32, 60, 32) + line(40, 48, 32, 88) + line(40, 48, 48, 88),
        head(52, 28) + line(52, 33, 40, 52) + line(40, 42, 26, 48) + line(40, 42, 54, 50) + bar(22, 50, 58, 54) + line(40, 52, 32, 88) + line(40, 52, 48, 88)
      ],
      hipthrust: [
        head(22, 42) + line(22, 47, 40, 50) + line(40, 50, 58, 50) + line(58, 50, 68, 70) + line(40, 50, 40, 70) + bar(18, 72, 72, 72),
        head(22, 28) + line(22, 33, 40, 36) + line(40, 36, 58, 36) + line(58, 36, 68, 70) + line(40, 36, 40, 70) + bar(18, 72, 72, 72)
      ],
      wallsit: [
        head(34, 18) + line(34, 23, 34, 48) + line(34, 48, 52, 48) + line(52, 48, 52, 78) + line(34, 32, 24, 42) + line(34, 32, 48, 38) + bar(56, 14, 56, 90),
        head(34, 18) + line(34, 23, 34, 48) + line(34, 48, 52, 48) + line(52, 48, 52, 78) + line(34, 32, 22, 40) + line(34, 32, 46, 36) + bar(56, 14, 56, 90)
      ],
      bench: [
        head(22, 28) + line(22, 33, 40, 36) + line(40, 36, 58, 36) + line(40, 28, 28, 20) + line(40, 28, 52, 20) + bar(16, 48, 64, 48) + line(40, 36, 40, 48),
        head(22, 28) + line(22, 33, 40, 36) + line(40, 36, 58, 36) + line(40, 28, 24, 12) + line(40, 28, 56, 12) + bar(16, 48, 64, 48) + line(40, 36, 40, 48) + bar(22, 12, 58, 12)
      ],
      incline: [
        head(26, 22) + line(26, 27, 42, 36) + line(42, 36, 58, 42) + line(42, 30, 30, 18) + line(42, 30, 54, 22) + bar(20, 56, 66, 42) + line(42, 36, 48, 50),
        head(26, 22) + line(26, 27, 42, 36) + line(42, 36, 58, 42) + line(42, 30, 26, 10) + line(42, 30, 58, 16) + bar(20, 56, 66, 42) + bar(24, 10, 60, 16)
      ],
      fly: [
        head(40, 22) + line(40, 27, 40, 48) + line(40, 36, 22, 28) + line(40, 36, 58, 28) + bar(18, 56, 62, 56),
        head(40, 22) + line(40, 27, 40, 48) + line(40, 36, 18, 42) + line(40, 36, 62, 42) + bar(18, 56, 62, 56)
      ],
      chestpress: [
        head(28, 24) + line(28, 29, 42, 36) + line(42, 36, 56, 36) + line(42, 30, 30, 22) + line(42, 30, 54, 22) + bar(22, 48, 64, 48),
        head(28, 24) + line(28, 29, 42, 36) + line(42, 36, 56, 36) + line(42, 30, 26, 14) + line(42, 30, 58, 14) + bar(22, 48, 64, 48)
      ],
      pushup: [
        head(18, 36) + line(18, 40, 40, 40) + line(40, 40, 62, 40) + line(28, 40, 24, 56) + line(50, 40, 54, 56) + line(40, 40, 36, 58) + line(40, 40, 48, 58) + bar(12, 62, 68, 62),
        head(18, 28) + line(18, 32, 40, 30) + line(40, 30, 62, 32) + line(28, 30, 22, 52) + line(50, 30, 58, 52) + line(40, 30, 34, 54) + line(40, 30, 50, 54) + bar(12, 62, 68, 62)
      ],
      closebench: [
        head(22, 28) + line(22, 33, 40, 36) + line(40, 36, 58, 36) + line(40, 28, 34, 18) + line(40, 28, 46, 18) + bar(16, 48, 64, 48) + bar(32, 18, 48, 18),
        head(22, 28) + line(22, 33, 40, 36) + line(40, 36, 58, 36) + line(40, 28, 36, 12) + line(40, 28, 44, 12) + bar(16, 48, 64, 48) + bar(34, 12, 46, 12)
      ],
      lat: [
        head(40, 18) + line(40, 23, 40, 50) + line(40, 32, 22, 20) + line(40, 32, 58, 20) + bar(18, 18, 62, 18) + line(40, 50, 32, 88) + line(40, 50, 48, 88),
        head(40, 18) + line(40, 23, 40, 50) + line(40, 32, 26, 36) + line(40, 32, 54, 36) + bar(24, 34, 56, 34) + line(40, 50, 32, 88) + line(40, 50, 48, 88)
      ],
      row: [
        head(54, 22) + line(54, 27, 40, 46) + line(40, 40, 28, 34) + line(40, 40, 28, 46) + bar(18, 36, 30, 40) + line(40, 46, 34, 86) + line(40, 46, 48, 86),
        head(54, 22) + line(54, 27, 40, 46) + line(40, 40, 22, 28) + line(40, 40, 22, 42) + bar(12, 30, 24, 36) + line(40, 46, 34, 86) + line(40, 46, 48, 86)
      ],
      pullover: [
        head(28, 30) + line(28, 35, 44, 40) + line(44, 40, 58, 40) + line(44, 34, 36, 18) + line(44, 34, 52, 18) + bar(34, 14, 54, 14) + bar(20, 52, 66, 52),
        head(28, 30) + line(28, 35, 44, 40) + line(44, 40, 58, 40) + line(44, 34, 58, 28) + line(44, 34, 62, 36) + bar(56, 26, 68, 34) + bar(20, 52, 66, 52)
      ],
      shrug: [
        head(40, 22) + line(40, 27, 40, 55) + line(40, 36, 24, 48) + line(40, 36, 56, 48) + line(40, 55, 32, 88) + line(40, 55, 48, 88),
        head(40, 18) + line(40, 23, 40, 52) + line(40, 32, 24, 36) + line(40, 32, 56, 36) + line(40, 52, 32, 88) + line(40, 52, 48, 88)
      ],
      ohp: [
        head(40, 28) + line(40, 33, 40, 55) + line(40, 40, 28, 48) + line(40, 40, 52, 48) + bar(24, 50, 56, 50) + line(40, 55, 32, 88) + line(40, 55, 48, 88),
        head(40, 22) + line(40, 27, 40, 52) + line(40, 34, 30, 18) + line(40, 34, 50, 18) + bar(26, 16, 54, 16) + line(40, 52, 32, 88) + line(40, 52, 48, 88)
      ],
      lateral: [
        head(40, 18) + line(40, 23, 40, 52) + line(40, 34, 24, 48) + line(40, 34, 56, 48) + line(40, 52, 32, 88) + line(40, 52, 48, 88),
        head(40, 18) + line(40, 23, 40, 52) + line(40, 34, 16, 34) + line(40, 34, 64, 34) + line(40, 52, 32, 88) + line(40, 52, 48, 88)
      ],
      front: [
        head(40, 18) + line(40, 23, 40, 52) + line(40, 34, 28, 48) + line(40, 34, 52, 48) + line(40, 52, 32, 88) + line(40, 52, 48, 88),
        head(40, 18) + line(40, 23, 40, 52) + line(40, 34, 28, 22) + line(40, 34, 52, 22) + bar(24, 20, 56, 20) + line(40, 52, 32, 88) + line(40, 52, 48, 88)
      ],
      rear: [
        head(48, 20) + line(48, 25, 40, 50) + line(40, 36, 26, 28) + line(40, 36, 26, 42) + line(40, 50, 34, 88) + line(40, 50, 48, 88),
        head(48, 20) + line(48, 25, 40, 50) + line(40, 36, 18, 30) + line(40, 36, 18, 44) + line(40, 50, 34, 88) + line(40, 50, 48, 88)
      ],
      curl: [
        head(40, 16) + line(40, 21, 40, 50) + line(40, 34, 28, 52) + line(40, 34, 52, 52) + bar(24, 54, 56, 54) + line(40, 50, 32, 88) + line(40, 50, 48, 88),
        head(40, 16) + line(40, 21, 40, 50) + line(40, 34, 30, 28) + line(40, 34, 50, 28) + bar(26, 26, 54, 26) + line(40, 50, 32, 88) + line(40, 50, 48, 88)
      ],
      hammer: [
        head(40, 16) + line(40, 21, 40, 50) + line(40, 34, 30, 54) + line(40, 34, 50, 54) + line(40, 50, 32, 88) + line(40, 50, 48, 88),
        head(40, 16) + line(40, 21, 40, 50) + line(40, 34, 30, 26) + line(40, 34, 50, 26) + line(40, 50, 32, 88) + line(40, 50, 48, 88)
      ],
      pushdown: [
        head(40, 18) + line(40, 23, 40, 50) + line(40, 32, 30, 24) + line(40, 32, 50, 24) + bar(28, 20, 52, 20) + line(40, 50, 32, 88) + line(40, 50, 48, 88),
        head(40, 18) + line(40, 23, 40, 50) + line(40, 32, 30, 44) + line(40, 32, 50, 44) + bar(28, 20, 52, 20) + line(40, 50, 32, 88) + line(40, 50, 48, 88)
      ],
      crunch: [
        head(22, 48) + line(22, 52, 40, 58) + line(40, 58, 62, 58) + line(40, 58, 36, 74) + line(40, 58, 48, 74) + bar(16, 78, 68, 78),
        head(28, 36) + line(28, 40, 44, 52) + line(44, 52, 62, 58) + line(44, 52, 38, 74) + line(44, 52, 52, 74) + bar(16, 78, 68, 78)
      ],
      backext: [
        head(22, 42) + line(22, 46, 40, 50) + line(40, 50, 60, 52) + line(40, 50, 36, 70) + line(40, 50, 48, 70) + bar(16, 74, 68, 74),
        head(28, 28) + line(28, 32, 42, 44) + line(42, 44, 60, 52) + line(42, 44, 36, 70) + line(42, 44, 50, 70) + bar(16, 74, 68, 74)
      ],
      generic: [
        head(40, 16) + line(40, 21, 40, 52) + line(40, 34, 26, 44) + line(40, 34, 54, 44) + line(40, 52, 32, 88) + line(40, 52, 48, 88),
        head(40, 16) + line(40, 21, 40, 52) + line(40, 34, 24, 34) + line(40, 34, 56, 34) + line(40, 52, 32, 88) + line(40, 52, 48, 88)
      ]
    };
    return poses[kind] || poses.generic;
  }

  function demoFrame(name) {
    const kind = stickKind(name);
    const [a, b] = stickPair(kind);
    return `<div class="ex-frame stick-anim relative w-full h-28 rounded-xl bg-slate-900 overflow-hidden border border-slate-800" data-on="a">
      <svg viewBox="0 0 80 100" class="stick-a absolute inset-0 w-full h-full p-1" fill="none">${a}</svg>
      <svg viewBox="0 0 80 100" class="stick-b absolute inset-0 w-full h-full p-1 opacity-0" fill="none">${b}</svg>
    </div>`;
  }

  function demoRow(name) {
    const sides = exerciseSides(name);
    const cards = sides.map((side) => `
      <div class="ex-demo min-w-0">
        ${demoFrame(side)}
        <p class="text-[8px] text-center text-slate-500 mt-1 uppercase truncate">${escapeHtml(side)}</p>
      </div>`).join('');
    const cols = sides.length > 2 ? 'grid-cols-3' : sides.length > 1 ? 'grid-cols-2' : 'grid-cols-1';
    return `<div class="grid ${cols} gap-2">${cards}</div>`;
  }

  function pesoChoices(current) {
    const base = [0, 2.5, 5, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 35, 40, 45, 50, 55, 60, 70, 80, 90, 100, 120, 140, 160, 180, 200].concat(HEAVY);
    const n = Number(current);
    if (Number.isFinite(n) && !base.some((v) => v == n)) base.push(n);
    return base.sort((a, b) => a - b);
  }

  function selectHtml(values, current, onchange, tone) {
    const opts = values.map((n) => `<option value="${n}" ${n == current ? 'selected' : ''}>${n || '—'}</option>`).join('');
    const color = tone === 'orange' ? 'text-orange-400' : 'text-white';
    return `<select onchange="${onchange}" class="w-full bg-slate-900/80 rounded-xl py-2 text-center text-sm font-black ${color} outline-none border border-slate-700">${opts}</select>`;
  }

  function loadControlsHtml(ex, set) {
    if (!ex || !set) return '';
    const sides = ex.partNames && ex.partNames.length > 1 ? ex.partNames : exerciseSides(ex.name);
    const multi = sides.length > 1;
    const fields = [
      { reps: 'reps', peso: 'peso', repsVal: set.reps, pesoVal: set.peso },
      { reps: 'reps2', peso: 'peso2', repsVal: set.reps2, pesoVal: set.peso2 },
      { reps: 'reps3', peso: 'peso3', repsVal: set.reps3, pesoVal: set.peso3 }
    ];
    return sides.map((side, index) => {
      const field = fields[index];
      if (!field) return '';
      const repsVal = field.repsVal || set.reps || 10;
      const pesoVal = Number.isFinite(Number(field.pesoVal)) ? Number(field.pesoVal) : 0;
      return `
        <div class="space-y-1">
          ${multi ? `<p class="text-[9px] font-black uppercase text-slate-400 truncate">${escapeHtml(side)}</p>` : ''}
          <div class="grid grid-cols-2 gap-2">
            <div class="bg-slate-900/70 rounded-2xl p-2 text-center">
              <p class="text-[8px] text-slate-500 font-black uppercase">Reps</p>
              ${selectHtml(Array.from({ length: 30 }, (_, i) => i + 1), repsVal, `updateLiveSetField('${field.reps}', this.value)`, 'white')}
            </div>
            <div class="bg-slate-900/70 rounded-2xl p-2 text-center">
              <p class="text-[8px] text-slate-500 font-black uppercase">Kg</p>
              ${selectHtml(pesoChoices(pesoVal), pesoVal, `updateLiveSetField('${field.peso}', this.value)`, 'orange')}
            </div>
          </div>
        </div>`;
    }).join('');
  }

  function schedaSeriesBlock(ex, saved, numSerie, defaultReps, dbPeso) {
    const exId = String(ex.id);
    const sides = exerciseSides(ex.esercizi);
    let html = demoRow(ex.esercizi);
    sides.forEach((side, index) => {
      const repsKey = index === 0 ? 'reps' : `reps${index + 1}`;
      const pesoKey = index === 0 ? 'peso' : `peso${index + 1}`;
      if (sides.length > 1) {
        html += `<p class="text-[9px] font-black uppercase text-amber-300 pt-1">${escapeHtml(side)}</p>`;
      }
      for (let i = 1; i <= numSerie; i++) {
        const sd = saved[i] || {};
        const repsVal = parseInt(sd[repsKey]) || defaultReps;
        const rawPeso = sd[pesoKey];
        const parsedPeso = rawPeso === undefined || rawPeso === '' ? NaN : parseFloat(rawPeso);
        const peso = Number.isFinite(parsedPeso) ? parsedPeso : (index === 0 ? dbPeso : 0);
        html += `
          <div class="grid grid-cols-[28px_1fr_1fr] gap-2 items-center">
            <span class="text-[10px] font-black text-slate-500 text-center">${i}</span>
            ${selectHtml(Array.from({ length: 20 }, (_, n) => n + 1), repsVal, `saveSchedaEditField('${exId}', ${i}, '${repsKey}', this.value, ${numSerie})`, 'white')}
            ${selectHtml(pesoChoices(peso), peso, `saveSchedaEditField('${exId}', ${i}, '${pesoKey}', this.value, ${numSerie})`, 'orange')}
          </div>`;
      }
    });
    return html;
  }

  function setLiftedKg(set) {
    let total = (Number(set.reps) || 0) * (Number(set.peso) || 0);
    // Match Watch liftedKg: when secondary kg is set, fall back to primary reps.
    if (set.peso2 != null && set.peso2 !== '') {
      const reps2 = set.reps2 != null && set.reps2 !== '' ? Number(set.reps2) : Number(set.reps);
      total += (Number(reps2) || 0) * (Number(set.peso2) || 0);
    }
    if (set.peso3 != null && set.peso3 !== '') {
      const reps3 = set.reps3 != null && set.reps3 !== '' ? Number(set.reps3) : Number(set.reps);
      total += (Number(reps3) || 0) * (Number(set.peso3) || 0);
    }
    return total;
  }

  function exRow(id, name, sets, reps, peso, rec, note) {
    return {
      id,
      esercizi: name,
      serie: String(sets),
      note_rep: String(reps),
      recupero: String(rec),
      note: note || 'Scheda 50 minuti',
      avanzamento_pesi: String(peso),
      gruppi_muscolari: ''
    };
  }

  /* ---------- Alternative pronte (singolo esercizio) ---------- */

  function alt(id, name, reps, peso, from, note) {
    return { id, name, reps, peso, from, note: note || '' };
  }

  const ALT_RULES = [
    {
      match: /panca inclinata|distensioni.*inclinat/i,
      alts: [
        alt('a_inc_db', 'Distensioni manubri su inclinata', 8, 28, 'Spinte 2', 'Stesso angolo, manubri.'),
        alt('a_chest', 'Chest press', 8, 32, 'Spinte 1', 'Macchina, più stabile.'),
        alt('a_pushups', 'Flessioni mani larghe', 12, 0, 'Corpo libero', 'Se manca il carico.')
      ]
    },
    {
      match: /chest press|panca(?!\s*stretta)/i,
      alts: [
        alt('a_bench_mp', 'Panca Multipower', 8, 40, 'Spinta', 'Bilanciere guidato.'),
        alt('a_inc_db2', 'Distensioni manubri su inclinata', 8, 28, 'Spinte 2', ''),
        alt('a_fly_m', 'Croci alla macchina', 10, 15, 'Spinte 2', '')
      ]
    },
    {
      match: /croci/i,
      alts: [
        alt('a_fly_cab', 'Croci ai cavi alti', 12, 15, 'Spinte 1', ''),
        alt('a_fly_mach', 'Croci alla macchina', 10, 15, 'Spinte 2', ''),
        alt('a_pec', 'Pec deck', 12, 20, 'Alternativa', 'Se c’è la macchina.')
      ]
    },
    {
      match: /laterali/i,
      alts: [
        alt('a_lat_cavo', 'Alzate laterali al cavo', 12, 8, 'Spalle', 'Tensione continua.'),
        alt('a_lat_sed', 'Alzate laterali seduto', 12, 10, 'Spalle', 'Meno cheating.'),
        alt('a_upright', 'Alzate a 90° / upright', 10, 12, 'Spalle', '')
      ]
    },
    {
      match: /frontali/i,
      alts: [
        alt('a_front_disk', 'Alzate frontali disco', 10, 10, 'Spalle', ''),
        alt('a_front_cavo', 'Alzate frontali al cavo', 12, 8, 'Spalle', ''),
        alt('a_ohp_alt', 'Lento avanti manubri', 8, 12, 'Spinte 2', '')
      ]
    },
    {
      match: /posteriori|rear|face/i,
      alts: [
        alt('a_rear_mach', 'Reverse fly macchina', 12, 20, 'Schiena', ''),
        alt('a_face', 'Face pull', 12, 20, 'Schiena', ''),
        alt('a_rear_db', 'Alzate posteriori manubri', 12, 8, 'Spalle', '')
      ]
    },
    {
      match: /lento|overhead|military/i,
      alts: [
        alt('a_ohp_mp', 'Military Multipower', 8, 30, 'Spalle', ''),
        alt('a_ohp_db', 'Lento avanti manubri', 8, 12, 'Spinte 2', ''),
        alt('a_arnold', 'Arnold press', 8, 12, 'Spalle', '')
      ]
    },
    {
      match: /push\s*down|pushdown|panca stretta|tricip/i,
      alts: [
        alt('a_pd_bar', 'Push down barra', 10, 30, 'Spinte 1', ''),
        alt('a_pd_rope', 'Push down fune', 12, 20, 'Spinte 2', ''),
        alt('a_close', 'Panca stretta Multipower', 10, 30, 'Spinte 2', '')
      ]
    },
    {
      match: /leg press|pressa/i,
      alts: [
        alt('a_lp45', 'Leg press 45', 8, 360, 'Gambe 1', ''),
        alt('a_lp_or', 'Leg press orizzontale', 10, 160, 'Gambe 2', ''),
        alt('a_squat_alt', 'Squat Multipower', 8, 70, 'Gambe 1', '')
      ]
    },
    {
      match: /squat|accosciat/i,
      alts: [
        alt('a_squat_mp', 'Squat Multipower', 8, 70, 'Gambe 1', ''),
        alt('a_hack', 'Hack squat / macchina accosciate', 8, 60, 'Gambe', ''),
        alt('a_goblet', 'Goblet squat', 10, 20, 'Corpo libero', 'Manubrio al petto.')
      ]
    },
    {
      match: /leg extension|extension/i,
      alts: [
        alt('a_le', 'Leg extension', 10, 60, 'Gambe 1', ''),
        alt('a_sissy', 'Sissy squat assistito', 10, 0, 'Quadricipiti', ''),
        alt('a_step', 'Step-up panca', 10, 14, 'Gambe', 'Manubri.')
      ]
    },
    {
      match: /leg curl|femoral|lug curl/i,
      alts: [
        alt('a_lc_sit', 'Leg curl seduto', 10, 55, 'Gambe 1', ''),
        alt('a_lc_lie', 'Leg curl sdraiato', 10, 55, 'Gambe 2', ''),
        alt('a_nordic', 'Nordic curl assistito', 6, 0, 'Femorali', '')
      ]
    },
    {
      match: /affond|lunge/i,
      alts: [
        alt('a_walk', 'Affondi in camminata', 12, 16, 'Gambe 1', ''),
        alt('a_rev', 'Affondi indietro', 10, 14, 'Gambe', ''),
        alt('a_bulg', 'Bulgarian split squat', 8, 12, 'Gambe', '')
      ]
    },
    {
      match: /polpacc|calf/i,
      alts: [
        alt('a_calf_m', 'Polpacci alla macchina', 15, 160, 'Gambe 1', ''),
        alt('a_calf_leg', 'Polpacci in leg press', 15, 100, 'Gambe', ''),
        alt('a_calf_stand', 'Polpacci in piedi manubrio', 15, 20, 'Gambe', '')
      ]
    },
    {
      match: /rumen|stacco/i,
      alts: [
        alt('a_rdl', 'Stacchi rumeni bilanciere', 8, 100, 'Gambe 2', ''),
        alt('a_rdl_db', 'Stacchi rumeni manubri', 10, 24, 'Gambe', ''),
        alt('a_good', 'Good morning Multipower', 10, 40, 'Femorali', '')
      ]
    },
    {
      match: /hip thrust|thrust/i,
      alts: [
        alt('a_ht', 'Hip thrust', 10, 60, 'Glutei', ''),
        alt('a_bridge', 'Glute bridge bilanciere', 12, 40, 'Glutei', ''),
        alt('a_kick', 'Kickback cavo', 12, 15, 'Glutei', '')
      ]
    },
    {
      match: /lat|pulldown|pull down/i,
      alts: [
        alt('a_lat_pron', 'Lat machine presa prona', 8, 70, 'Tirata 1', ''),
        alt('a_lat_tri', 'Lat machine presa triangolo', 10, 60, 'Tirata 1', ''),
        alt('a_pullup', 'Trazioni assistite', 8, 0, 'Dorso', '')
      ]
    },
    {
      match: /rematore|pulley|row/i,
      alts: [
        alt('a_pulley', 'Pulley', 10, 80, 'Tirata 1', ''),
        alt('a_row_db', 'Rematore manubri', 10, 24, 'Schiena 2', ''),
        alt('a_row_bb', 'Rematore bilanciere', 8, 50, 'Schiena 2', 'Parti leggero.')
      ]
    },
    {
      match: /scrollat|shrug/i,
      alts: [
        alt('a_shrug_db', 'Scrollate manubri', 10, 24, 'Tirata 1', ''),
        alt('a_shrug_bb', 'Scrollate bilanciere', 10, 40, 'Trapezi', ''),
        alt('a_face2', 'Face pull alti', 12, 20, 'Trapezi', '')
      ]
    },
    {
      match: /hammer/i,
      alts: [
        alt('a_ham', 'Hammer curl manubri', 10, 12, 'Tirata 2', ''),
        alt('a_rope', 'Curl fune al cavo', 12, 20, 'Bicipiti', ''),
        alt('a_conc', 'Curl concentrato', 10, 10, 'Bicipiti', '')
      ]
    },
    {
      match: /curl|bicip/i,
      alts: [
        alt('a_ez', 'Curl bilanciere EZ', 10, 10, 'Tirata 2', ''),
        alt('a_cable', 'Curl cavo basso barra', 10, 20, 'Tirata 1', ''),
        alt('a_db_curl', 'Curl manubri in piedi', 10, 12, 'Bicipiti', '')
      ]
    }
  ];

  function alternativesFor(name) {
    const text = String(name || '');
    for (const rule of ALT_RULES) {
      if (rule.match.test(text)) return rule.alts;
    }
    return [
      alt('a_gen_1', 'Variante macchina dello stesso gruppo', 10, 20, 'Generica', 'Stesso schema serie/reps.'),
      alt('a_gen_2', 'Variante manubri dello stesso gruppo', 10, 12, 'Generica', ''),
      alt('a_gen_3', 'Variante cavi dello stesso gruppo', 12, 15, 'Generica', '')
    ];
  }

  function getExOverrides() {
    try { return JSON.parse(localStorage.getItem('workout_ex_overrides_v1') || '{}'); }
    catch (_) { return {}; }
  }

  function saveExOverrides(map) {
    localStorage.setItem('workout_ex_overrides_v1', JSON.stringify(map));
  }

  function applyExerciseOverride(ex) {
    if (!ex) return ex;
    const over = getExOverrides()[String(ex.id)];
    if (!over) return ex;
    return Object.assign({}, ex, {
      esercizi: over.name || over.esercizi || ex.esercizi,
      note_rep: over.reps != null ? String(over.reps) : (over.note_rep || ex.note_rep),
      avanzamento_pesi: over.peso != null ? String(over.peso) : (over.avanzamento_pesi || ex.avanzamento_pesi),
      note: over.note || ex.note,
      _altFrom: over.from || '',
      _altId: over.id || ''
    });
  }

  function applyExerciseOverrides(rows) {
    return (rows || []).map(applyExerciseOverride);
  }

  function replaceExerciseWithAlt(exId, altId, originalName) {
    const list = alternativesFor(originalName);
    const chosen = list.find((a) => a.id === altId);
    if (!chosen) return;
    const map = getExOverrides();
    map[String(exId)] = {
      id: chosen.id,
      name: chosen.name,
      reps: chosen.reps,
      peso: chosen.peso,
      from: chosen.from,
      note: chosen.note ? `Alt. da ${chosen.from}: ${chosen.note}` : `Alternativa da ${chosen.from}`,
      originalName: originalName
    };
    saveExOverrides(map);
    let data = {};
    try { data = JSON.parse(localStorage.getItem('ex_data_v1') || '{}'); } catch (_) { data = {}; }
    if (!data[exId]) data[exId] = {};
    data[exId].serie = data[exId].serie || 3;
    const serie = parseInt(data[exId].serie, 10) || 3;
    for (let i = 1; i <= serie; i++) {
      data[exId][i] = Object.assign({}, data[exId][i] || {}, {
        reps: String(chosen.reps),
        peso: String(chosen.peso)
      });
    }
    localStorage.setItem('ex_data_v1', JSON.stringify(data));
    if (typeof global.schedulePlansSync === 'function') global.schedulePlansSync(true);
    const title = document.getElementById('scheda-edit-title');
    const gruppo = title?.dataset?.gruppo || title?.textContent;
    if (gruppo && typeof global.openSchedaEditor === 'function') {
      global.openSchedaEditor(gruppo === 'Tutta la scheda' ? 'all' : gruppo);
    }
  }

  function clearExerciseOverride(exId) {
    const map = getExOverrides();
    const prev = map[String(exId)];
    delete map[String(exId)];
    saveExOverrides(map);
    if (typeof global.schedulePlansSync === 'function') global.schedulePlansSync(true);
    const title = document.getElementById('scheda-edit-title');
    const gruppo = title?.dataset?.gruppo || title?.textContent;
    if (gruppo && typeof global.openSchedaEditor === 'function') {
      global.openSchedaEditor(gruppo === 'Tutta la scheda' ? 'all' : gruppo);
    }
    return prev;
  }

  function alternativesBlockHtml(ex) {
    const over = getExOverrides()[String(ex.id)];
    const original = over?.originalName || ex.esercizi;
    const alts = alternativesFor(original);
    const overridden = !!over;
    const safeName = String(original).replace(/\\/g, '\\\\').replace(/'/g, "\\'");
    return `
      <div class="space-y-1.5 pt-1">
        <p class="text-[9px] font-black uppercase text-slate-500">Alternative pronte</p>
        ${overridden ? `<button onclick="clearExerciseOverride('${ex.id}')" class="w-full py-2 rounded-xl text-[9px] font-black uppercase border border-slate-700 text-slate-300">Ripristina esercizio originale</button>` : ''}
        ${alts.map((a) => `
          <button onclick="replaceExerciseWithAlt('${ex.id}', '${a.id}', '${safeName}')" class="w-full text-left p-2.5 rounded-xl bg-slate-900/80 border border-slate-700 active:scale-[0.98]">
            <div class="flex justify-between gap-2">
              <p class="text-[10px] font-black uppercase text-amber-200 truncate">${escapeHtml(a.name)}</p>
              <p class="text-[9px] text-orange-300 shrink-0">${a.reps} · ${a.peso || 0} kg</p>
            </div>
            <p class="text-[8px] text-slate-500 mt-0.5">Da ${escapeHtml(a.from)}${a.note ? ' · ' + escapeHtml(a.note) : ''}</p>
          </button>`).join('')}
      </div>`;
  }

  const CUSTOM_PLANS = [
    {
      id: 'push50',
      name: 'Spinta densa',
      focus: 'Petto, spalle, tricipiti',
      exercises: [
        exRow('p50_push_1', 'Panca inclinata Multipower', 4, 8, 30, 120, 'Carico della tua scheda, serie un po’ più corte.'),
        exRow('p50_push_2', 'Chest press', 3, 10, 32, 90, ''),
        exRow('p50_push_3', 'Croci ai cavi alti', 3, 12, 15, 75, ''),
        exRow('p50_push_4', 'Lento avanti manubri', 3, 8, 12, 90, ''),
        exRow('p50_push_5', 'Alzate laterali manubri', 3, 12, 12, 75, ''),
        exRow('p50_push_6', 'Push down barra', 3, 10, 30, 75, ''),
        exRow('p50_push_7', 'Flessioni mani larghe', 2, 12, 0, 60, 'A corpo libero, regola le ripetizioni.')
      ]
    },
    {
      id: 'legs50',
      name: 'Gambe quadricipiti',
      focus: 'Quadricipiti, glutei, polpacci',
      exercises: [
        exRow('p50_leg_1', 'Leg press 45', 4, 8, 360, 120, 'Parti da 360 kg e sali se le ultime reps sono pulite.'),
        exRow('p50_leg_2', 'Squat Multipower', 3, 8, 70, 120, ''),
        exRow('p50_leg_3', 'Leg extension', 3, 10, 60, 90, ''),
        exRow('p50_leg_4', 'Affondi in camminata', 3, 12, 16, 90, 'Manubri per mano.'),
        exRow('p50_leg_5', 'Leg curl seduto', 3, 10, 55, 75, ''),
        exRow('p50_leg_6', 'Polpacci alla macchina', 4, 12, 160, 60, '')
      ]
    },
    {
      id: 'pull50',
      name: 'Tirata densa',
      focus: 'Dorso, trapezi, bicipiti',
      exercises: [
        exRow('p50_pull_1', 'Lat machine presa prona', 4, 8, 70, 120, ''),
        exRow('p50_pull_2', 'Pulley', 3, 10, 80, 90, ''),
        exRow('p50_pull_3', 'Rematore manubri', 3, 10, 24, 90, ''),
        exRow('p50_pull_4', 'Lat machine presa triangolo', 3, 10, 60, 90, ''),
        exRow('p50_pull_5', 'Tirate posteriori al cavo', 3, 12, 25, 75, ''),
        exRow('p50_pull_6', 'Curl bilanciere EZ', 3, 10, 10, 75, ''),
        exRow('p50_pull_7', 'Hammer curl manubri', 3, 10, 12, 75, '')
      ]
    },
    {
      id: 'post50',
      name: 'Catena posteriore',
      focus: 'Femorali, glutei, lombari',
      exercises: [
        exRow('p50_post_1', 'Stacchi rumeni bilanciere', 4, 8, 100, 120, 'Sotto il tuo 120–130, così resti preciso per tutta la seduta.'),
        exRow('p50_post_2', 'Hip thrust', 3, 10, 60, 90, ''),
        exRow('p50_post_3', 'Leg curl sdraiato', 3, 10, 55, 90, ''),
        exRow('p50_post_4', 'Affondi in camminata', 3, 10, 14, 90, ''),
        exRow('p50_post_5', 'Leg press orizzontale', 3, 10, 160, 90, 'Regola il carico della macchina.'),
        exRow('p50_post_6', 'Polpacci alla macchina', 3, 15, 140, 60, '')
      ]
    },
    {
      id: 'shoulder50',
      name: 'Spalle e braccia',
      focus: 'Deltoidi, tricipiti, bicipiti',
      exercises: [
        exRow('p50_sh_1', 'Lento avanti manubri', 4, 8, 12, 90, ''),
        exRow('p50_sh_2', 'Alzate laterali manubri', 4, 12, 12, 75, ''),
        exRow('p50_sh_3', 'Alzate frontali manubri', 3, 10, 8, 75, ''),
        exRow('p50_sh_4', 'Deltoidi posteriori', 3, 12, 8, 75, ''),
        exRow('p50_sh_5', 'Push down fune', 3, 12, 20, 75, ''),
        exRow('p50_sh_6', 'Curl bilanciere EZ', 3, 10, 10, 75, ''),
        exRow('p50_sh_7', 'Hammer curl manubri', 3, 10, 12, 60, '')
      ]
    }
  ];

  function planMinutes(plan) {
    const sec = (plan.exercises || []).reduce((sum, ex) => {
      const sets = parseInt(ex.serie, 10) || 3;
      const rest = parseInt(ex.recupero, 10) || 90;
      return sum + sets * (40 + rest);
    }, 0);
    return Math.max(40, Math.round(sec / 60));
  }

  function getSwaps() {
    try { return JSON.parse(localStorage.getItem('workout_plan_swaps_v1') || '{}'); }
    catch (_) { return {}; }
  }

  function saveSwaps(swaps) {
    localStorage.setItem('workout_plan_swaps_v1', JSON.stringify(swaps));
  }

  function planById(id) {
    return CUSTOM_PLANS.find((plan) => plan.id === id) || null;
  }

  function activePlanForGroup(gruppo) {
    return planById(getSwaps()[gruppo]);
  }

  function planExercisesForGroup(gruppo) {
    const plan = activePlanForGroup(gruppo);
    return plan ? applyExerciseOverrides(plan.exercises) : null;
  }

  function swapPlanOntoGroup(planId, gruppo) {
    const swaps = getSwaps();
    swaps[gruppo] = planId;
    saveSwaps(swaps);
    if (typeof global.schedulePlansSync === 'function') global.schedulePlansSync(true);
    renderCustomPlanDetail(planId);
    if (typeof global.refreshGroupSwapLabels === 'function') global.refreshGroupSwapLabels();
  }

  function clearSwap(gruppo) {
    const swaps = getSwaps();
    delete swaps[gruppo];
    saveSwaps(swaps);
    if (typeof global.schedulePlansSync === 'function') global.schedulePlansSync(true);
    showCustomPlans();
  }

  function hideWorkoutPanels() {
    ['workout-hub', 'select-group', 'workout-list', 'scheda-edit', 'custom-plans', 'custom-plan-detail'].forEach((id) => {
      document.getElementById(id)?.classList.add('hidden');
    });
  }

  function showCustomPlans() {
    hideWorkoutPanels();
    const root = document.getElementById('custom-plans');
    const list = document.getElementById('custom-plans-list');
    if (!root || !list) return;
    const swaps = getSwaps();
    const used = Object.entries(swaps);
    list.innerHTML = CUSTOM_PLANS.map((plan) => {
      const where = used.filter(([, id]) => id === plan.id).map(([gruppo]) => gruppo);
      const badge = where.length ? `<p class="text-[8px] text-amber-300 mt-1">Al posto di ${escapeHtml(where.join(', '))}</p>` : '';
      return `
        <button onclick="openCustomPlan('${plan.id}')" class="w-full text-left p-4 rounded-2xl glass-card border border-slate-800 active:scale-[0.98]">
          <div class="flex justify-between gap-2 items-start">
            <div class="min-w-0">
              <p class="text-sm font-black uppercase text-amber-300">${escapeHtml(plan.name)}</p>
              <p class="text-[9px] text-slate-500">${escapeHtml(plan.focus)}</p>
              ${badge}
            </div>
            <p class="text-[10px] font-black text-slate-300 shrink-0">~${planMinutes(plan)} min</p>
          </div>
          <p class="text-[8px] text-slate-600 mt-2">${plan.exercises.length} esercizi · pesi già impostati · usabili anche uno a uno</p>
        </button>`;
    }).join('');
    root.classList.remove('hidden');
  }

  function renderCustomPlanDetail(planId) {
    const plan = planById(planId);
    if (!plan) return;
    hideWorkoutPanels();
    const root = document.getElementById('custom-plan-detail');
    if (!root) return;
    const groups = global.WATCH_GROUPS || [];
    const swaps = getSwaps();
    const groupButtons = groups.map((gruppo) => {
      const current = swaps[gruppo];
      const active = current === plan.id;
      const label = active ? `${gruppo} · in uso` : (current ? `${gruppo} · sostituisci` : gruppo);
      return `<button onclick="swapPlanOntoGroup('${plan.id}', '${gruppo.replace(/'/g, "\\'")}')" class="p-3 rounded-xl text-left text-[10px] font-black uppercase border ${active ? 'bg-amber-500/20 border-amber-400 text-amber-200' : 'bg-slate-900 border-slate-700 text-slate-200'}">${escapeHtml(label)}</button>`;
    }).join('');
    const usedHere = Object.entries(swaps).filter(([, id]) => id === plan.id);
    root.innerHTML = `
      <div class="flex gap-2 items-center mb-2">
        <button onclick="showCustomPlans()" class="bg-slate-800 px-4 py-2 rounded-xl border border-slate-700 text-slate-300 active:scale-90"><i class="fas fa-arrow-left text-sm"></i></button>
        <div class="min-w-0">
          <h2 class="text-sm font-black uppercase text-amber-300 truncate">${escapeHtml(plan.name)}</h2>
          <p class="text-[9px] text-slate-500">~${planMinutes(plan)} min · ${escapeHtml(plan.focus)}</p>
        </div>
      </div>
      <div class="space-y-3">
        ${plan.exercises.map((ex) => `
          <div class="glass-card rounded-2xl p-3 border border-slate-800 space-y-2">
            ${demoRow(ex.esercizi)}
            <p class="text-xs font-black uppercase text-slate-100">${escapeHtml(ex.esercizi)}</p>
            <p class="text-[10px] text-orange-300">${ex.serie} × ${ex.note_rep} · ${ex.avanzamento_pesi} kg · rec ${ex.recupero}s</p>
            <p class="text-[9px] text-slate-500">${escapeHtml(ex.note || '')}</p>
            <p class="text-[8px] text-slate-600">In Allenamenti apri una scheda e usa le alternative pronte sotto ogni esercizio per metterne uno al posto di un altro.</p>
          </div>`).join('')}
      </div>
      <div class="mt-4 space-y-2 pb-28">
        <p class="text-[10px] font-black uppercase text-slate-400">Scambia tutta la scheda</p>
        <p class="text-[9px] text-slate-500">Oppure, da Allenamenti, sostituisci un singolo esercizio con un’alternativa pronta.</p>
        <div class="grid grid-cols-2 gap-2">${groupButtons}</div>
        ${usedHere.map(([gruppo]) => `<button onclick="clearSwap('${gruppo.replace(/'/g, "\\'")}')" class="w-full py-3 rounded-xl text-[10px] font-black uppercase text-slate-300 border border-slate-700">Ripristina ${escapeHtml(gruppo)}</button>`).join('')}
      </div>`;
    root.classList.remove('hidden');
  }

  function openCustomPlan(planId) {
    renderCustomPlanDetail(planId);
  }

  function refreshGroupSwapLabels() {
    document.querySelectorAll('#select-group h3').forEach((title) => {
      const gruppo = title.textContent.trim();
      const note = title.parentElement?.querySelector('p');
      if (!note) return;
      if (!note.dataset.base) note.dataset.base = note.textContent;
      const plan = activePlanForGroup(gruppo);
      if (plan) {
        note.textContent = `50 min · ${plan.name}`;
        note.classList.add('text-amber-300');
        note.classList.remove('text-slate-500');
      } else {
        note.textContent = note.dataset.base;
        note.classList.remove('text-amber-300');
        note.classList.add('text-slate-500');
      }
    });
  }

  setInterval(() => {
    document.querySelectorAll('.stick-anim').forEach((box) => {
      const a = box.querySelector('.stick-a');
      const b = box.querySelector('.stick-b');
      if (!a || !b) return;
      const useB = box.dataset.on !== 'b';
      box.dataset.on = useB ? 'b' : 'a';
      a.classList.toggle('opacity-0', useB);
      b.classList.toggle('opacity-0', !useB);
    });
  }, 900);

  global.exerciseSides = exerciseSides;
  global.demoRow = demoRow;
  global.loadControlsHtml = loadControlsHtml;
  global.schedaSeriesBlock = schedaSeriesBlock;
  global.setLiftedKg = setLiftedKg;
  global.CUSTOM_PLANS = CUSTOM_PLANS;
  global.planExercisesForGroup = planExercisesForGroup;
  global.activePlanForGroup = activePlanForGroup;
  global.showCustomPlans = showCustomPlans;
  global.openCustomPlan = openCustomPlan;
  global.swapPlanOntoGroup = swapPlanOntoGroup;
  global.clearSwap = clearSwap;
  global.refreshGroupSwapLabels = refreshGroupSwapLabels;
  global.pesoChoices = pesoChoices;
  global.alternativesFor = alternativesFor;
  global.alternativesBlockHtml = alternativesBlockHtml;
  global.applyExerciseOverride = applyExerciseOverride;
  global.applyExerciseOverrides = applyExerciseOverrides;
  global.replaceExerciseWithAlt = replaceExerciseWithAlt;
  global.clearExerciseOverride = clearExerciseOverride;
})(window);
