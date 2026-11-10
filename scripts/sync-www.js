#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const www = path.join(root, 'www');

fs.mkdirSync(www, { recursive: true });

const files = ['index.html', 'manifest.json', 'workout_template.csv'];
for (const file of files) {
  const src = path.join(root, file);
  if (fs.existsSync(src)) {
    fs.copyFileSync(src, path.join(www, file));
    console.log('synced', file);
  }
}

const jsDir = path.join(www, 'js');
fs.mkdirSync(jsDir, { recursive: true });
for (const name of ['native-bridge.js', 'workout-library.js']) {
  const src = path.join(root, 'js', name);
  if (fs.existsSync(src)) {
    fs.copyFileSync(src, path.join(jsDir, name));
    console.log('synced js/' + name);
  }
}

console.log('www ready');
