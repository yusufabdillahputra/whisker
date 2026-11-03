// Render logo Whisker dari style DiceBear kustom (design/dicebear/whisker-calico.json).
// Pakai: cd design/tools && npm install && npm run logo
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { Avatar, Style } from '@dicebear/core';

const root = new URL('../', import.meta.url);
const definition = JSON.parse(readFileSync(new URL('dicebear/whisker-calico.json', root), 'utf8'));
const style = new Style(definition);
const outDir = new URL('logo/', root);
mkdirSync(outDir, { recursive: true });

// Logo resmi = seed tetap + varian & warna terkunci, supaya hasilnya identik di semua mesin.
const logo = {
  seed: 'Whisker',
  earsVariant: 'pointy',
  patchesVariant: 'classic',
  eyesVariant: 'open',
  furColor: '#FEF9F4',
  patchAColor: '#F47806',
  patchBColor: '#221E1A',
  earLeftColor: '#F47806',
  earRightColor: '#221E1A',
  eyeColor: '#56B870',
  noseColor: '#FA6786',
  lineColor: '#221E1A',
};

const variants = {
  'whisker-logo.svg': { ...logo, backgroundColor: '#FEEFE7', borderRadius: 22 },
  'whisker-logo-ginger.svg': { ...logo, backgroundColor: '#F47806', borderRadius: 22 },
  'whisker-mark.svg': { ...logo, backgroundColor: '#00000000' },
};

for (const [file, options] of Object.entries(variants)) {
  const svg = new Avatar(style, { ...options, title: 'Whisker' }).toString();
  writeFileSync(new URL(file, outDir), svg + '\n');
  console.log('tulis', file);
}

// Contoh avatar pengguna: seed = id/username, semua varian & warna bebas.
const samples = ['yusuf', 'angkasa', 'serverpod', 'forui', 'calico', 'whisker-bot'];
const row = samples
  .map((seed, i) => {
    const uri = new Avatar(style, { seed, borderRadius: 50 }).toDataUri();
    return `<image href="${uri}" x="${i * 110}" y="0" width="100" height="100"/>`;
  })
  .join('');
writeFileSync(
  new URL('avatar-samples.svg', outDir),
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${samples.length * 110 - 10} 100">${row}</svg>\n`,
);
console.log('tulis avatar-samples.svg');
