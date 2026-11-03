// Render logo & avatar Whisker dengan style "whisker-lorelei-cat":
// kepala kucing calico + mata/alis/mulut dari DiceBear Lorelei (CC0 1.0, Lisa Wischofsky).
// Pakai: cd design/tools && npm install && npm run lorelei
// (bila style berubah: python3 build-lorelei-cat.py dulu)
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { Avatar, Style } from '@dicebear/core';

const root = new URL('../', import.meta.url);
const definition = JSON.parse(readFileSync(new URL('dicebear/whisker-lorelei-cat.json', root), 'utf8'));
const style = new Style(definition);
const outDir = new URL('logo/lorelei/', root);
mkdirSync(outDir, { recursive: true });

// Kandidat logo: seed tetap + varian & warna terkunci.
const logo = {
  seed: 'Whisker',
  earsVariant: 'pointy',
  patchesVariant: 'classic',
  eyesVariant: 'variant04',
  mouthVariant: 'happy06',
  eyebrowsProbability: 0,
  frecklesProbability: 0,
  patchAColor: '#F47806',
  patchBColor: '#221E1A',
  earLeftColor: '#F47806',
  earRightColor: '#221E1A',
  noseColor: '#FA6786',
};
const files = {
  'whisker-lorelei-logo.svg': { ...logo, backgroundColor: '#FEEFE7', borderRadius: 22 },
  'whisker-lorelei-logo-ginger.svg': { ...logo, backgroundColor: '#F47806', earLeftColor: '#FEA065', patchAColor: '#FEA065', borderRadius: 22 },
  'whisker-lorelei-mark.svg': { ...logo, backgroundColor: '#00000000' },
};
for (const [file, options] of Object.entries(files)) {
  writeFileSync(new URL(file, outDir), new Avatar(style, { ...options, title: 'Whisker' }).toString() + '\n');
  console.log('tulis', file);
}

// Contoh avatar pengguna: seed = id pengguna, varian & warna bebas.
const seeds = ['yusuf', 'angkasa', 'serverpod', 'forui', 'calico', 'flutter', 'mochi', 'luna'];
const row = seeds
  .map((seed, i) => `<image href="${new Avatar(style, { seed, borderRadius: 50 }).toDataUri()}" x="${i * 110}" y="0" width="100" height="100"/>`)
  .join('');
writeFileSync(new URL('avatar-samples.svg', outDir), `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${seeds.length * 110 - 10} 100">${row}</svg>\n`);
console.log('tulis avatar-samples.svg');
