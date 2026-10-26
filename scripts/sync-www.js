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
const bridge = path.join(root, 'js', 'native-bridge.js');
if (fs.existsSync(bridge)) {
  fs.copyFileSync(bridge, path.join(jsDir, 'native-bridge.js'));
  console.log('synced js/native-bridge.js');
}

console.log('www ready');
