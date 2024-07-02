/**
 * This script inlines the bundle.js in index.html and saves it as the dashboard.html.
 */

const fs = require('fs')
const index = fs.readFileSync('public/index.html', 'utf8');
const bundle = fs.readFileSync('public/bundle.js', 'utf8');

let content = index.split("<script src=\"bundle.js\"></script>");
content = content[0] + `<script>${bundle}</script>` + content[1]
fs.writeFileSync('../resource/impactAnalysis.html', content);
console.log('Saved to ../resource/impactAnalysis.html');
