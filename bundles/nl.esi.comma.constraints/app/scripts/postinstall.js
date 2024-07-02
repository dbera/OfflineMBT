const path = require('path');
const fs = require('fs');

const root = path.join(__dirname, '..')
const source = path.join(root, 'node_modules', '@hpcc-js', 'wasm', 'dist', 'graphvizlib.wasm');
const target = path.join(root, 'public', 'static', 'js', 'graphvizlib.wasm');

fs.mkdirSync(path.dirname(target), {recursive: true});
fs.copyFileSync(source, target);
console.log(`Copied '${source}' to '${target}'`)