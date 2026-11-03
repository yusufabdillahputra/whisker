// Render avatar & kandidat logo Whisker dengan style DiceBear "Lorelei" (CC0 1.0, Lisa Wischofsky)
// memakai palet calico dari design/tokens/whisker.tokens.json.
// Pakai: cd design/tools && npm install && npm run lorelei
import { writeFileSync, mkdirSync } from 'node:fs';
import { Avatar, Style } from '@dicebear/core';
import definition from '@dicebear/styles/lorelei.json' with { type: 'json' };

const style = new Style(definition);
const outDir = new URL('../logo/lorelei/', import.meta.url);
mkdirSync(outDir, { recursive: true });

// Palet calico: rambut oranye/hitam, garis hitam hangat, kulit krem, latar lembut.
const calico = {
  hairColor: ['#F47806', '#CD6505', '#221E1A', '#3C3731'],
  outlineColor: ['#221E1A'],
  eyesColor: ['#221E1A'],
  eyebrowsColor: ['#221E1A'],
  mouthColor: ['#221E1A'],
  noseColor: ['#221E1A'],
  frecklesColor: ['#CD6505'],
  glassesColor: ['#221E1A'],
  earringsColor: ['#F47806'],
  hairAccessoriesColor: ['#FA6786'],
  skinColor: ['#FEF9F4'],
  backgroundColor: ['#FEEFE7', '#ECE4DA', '#E0FBE5', '#FEDBDF', '#FEDECB'],
};

// Kandidat logo: seed tetap, warna terkunci (rambut oranye, latar krem ginger.100).
const logo = { ...calico, seed: 'Whisker', mouthVariant: 'happy01', beardProbability: 0, glassesProbability: 0, frecklesProbability: 100, hairColor: ['#F47806'], backgroundColor: ['#FEEFE7'] };
const files = {
  'whisker-lorelei-logo.svg': { ...logo, borderRadius: 22 },
  'whisker-lorelei-logo-ginger.svg': { ...logo, hairColor: ['#221E1A'], backgroundColor: ['#F47806'], borderRadius: 22 },
  'whisker-lorelei-mark.svg': { ...logo, backgroundColor: ['#00000000'] },
};
for (const [file, options] of Object.entries(files)) {
  writeFileSync(new URL(file, outDir), new Avatar(style, { ...options, title: 'Whisker' }).toString() + '\n');
  console.log('tulis', file);
}

const seeds = ['yusuf', 'angkasa', 'serverpod', 'forui', 'calico', 'whisker-bot', 'flutter', 'hub'];
const row = seeds
  .map((seed, i) => `<image href="${new Avatar(style, { ...calico, seed, borderRadius: 50 }).toDataUri()}" x="${i * 110}" y="0" width="100" height="100"/>`)
  .join('');
writeFileSync(new URL('avatar-samples.svg', outDir), `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${seeds.length * 110 - 10} 100">${row}</svg>\n`);
console.log('tulis avatar-samples.svg');
