const fs = require('fs')
let index = fs.readFileSync('build/index.html', 'utf8');

index = index.replace(/<script defer=\"defer\" src=\"(.+)\"><\/script>/g, function(match, token) {
    return `<script>${fs.readFileSync(`build/${token}`)}</script>`;
});

index = index.replace(/<link.*href="(.+)" rel="stylesheet">/g, function(match, token) {
    return `<style>${fs.readFileSync(`build/${token}`)}</style>`;
});

const output = '../resource/constraints_dashboard.html';
fs.writeFileSync(output, index);
console.log(`Saved to ${output}`);
