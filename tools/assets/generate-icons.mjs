import { createRequire } from 'module';
import { mkdirSync, rmSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { execFileSync } from 'child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = join(__dirname, '..', '..');
const require = createRequire(join(projectRoot, 'tauri', 'package.json'));
const sharp = require('sharp');
const iconsDir = join(projectRoot, 'tauri', 'src-tauri', 'icons');
const svgPath = join(iconsDir, 'design', 'icon_fullbleed.svg');
const iconsetDir = join(iconsDir, 'icon.iconset');

const pngTargets = [
  { name: '32x32.png', size: 32 },
  { name: '128x128.png', size: 128 },
  { name: '128x128@2x.png', size: 256 },
  { name: 'icon_512x512@2x.png', size: 1024 },
  { name: 'icon.png', size: 512 },
  { name: 'Square30x30Logo.png', size: 30 },
  { name: 'Square44x44Logo.png', size: 44 },
  { name: 'Square71x71Logo.png', size: 71 },
  { name: 'Square89x89Logo.png', size: 89 },
  { name: 'Square107x107Logo.png', size: 107 },
  { name: 'Square142x142Logo.png', size: 142 },
  { name: 'Square150x150Logo.png', size: 150 },
  { name: 'Square284x284Logo.png', size: 284 },
  { name: 'Square310x310Logo.png', size: 310 },
  { name: 'StoreLogo.png', size: 50 },
];

const icnsTargets = [
  { name: 'icon_16x16.png', size: 16 },
  { name: 'icon_16x16@2x.png', size: 32 },
  { name: 'icon_32x32.png', size: 32 },
  { name: 'icon_32x32@2x.png', size: 64 },
  { name: 'icon_128x128.png', size: 128 },
  { name: 'icon_128x128@2x.png', size: 256 },
  { name: 'icon_256x256.png', size: 256 },
  { name: 'icon_256x256@2x.png', size: 512 },
  { name: 'icon_512x512.png', size: 512 },
  { name: 'icon_512x512@2x.png', size: 1024 },
];

async function renderPng(outputPath, size) {
  await sharp(svgPath)
    .resize(size, size, {
      fit: 'contain',
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png({ quality: 100, compressionLevel: 9, palette: false })
    .toFile(outputPath);
}

async function generatePngAssets() {
  for (const { name, size } of pngTargets) {
    const outputPath = join(iconsDir, name);
    await renderPng(outputPath, size);
    console.log(`✓ PNG ${name} (${size}x${size})`);
  }
}

async function generateIcns() {
  rmSync(iconsetDir, { recursive: true, force: true });
  mkdirSync(iconsetDir, { recursive: true });

  for (const { name, size } of icnsTargets) {
    await renderPng(join(iconsetDir, name), size);
  }

  execFileSync('iconutil', ['-c', 'icns', iconsetDir, '-o', join(iconsDir, 'icon.icns')]);
  rmSync(iconsetDir, { recursive: true, force: true });
  console.log('✓ ICNS icon.icns');
}

async function generateIco() {
  const sizes = [16, 32, 48, 64, 128, 256];
  const images = [];

  for (const size of sizes) {
    const buffer = await sharp(svgPath)
      .resize(size, size, {
        fit: 'contain',
        background: { r: 0, g: 0, b: 0, alpha: 0 },
      })
      .png()
      .toBuffer();
    images.push({ size, buffer });
  }

  const iconDir = Buffer.alloc(6 + images.length * 16);
  iconDir.writeUInt16LE(0, 0);
  iconDir.writeUInt16LE(1, 2);
  iconDir.writeUInt16LE(images.length, 4);

  let offset = 6 + images.length * 16;
  const imageBuffers = [];

  for (let index = 0; index < images.length; index += 1) {
    const { size, buffer } = images[index];
    const entryOffset = 6 + index * 16;

    iconDir.writeUInt8(size < 256 ? size : 0, entryOffset);
    iconDir.writeUInt8(size < 256 ? size : 0, entryOffset + 1);
    iconDir.writeUInt8(0, entryOffset + 2);
    iconDir.writeUInt8(0, entryOffset + 3);
    iconDir.writeUInt16LE(1, entryOffset + 4);
    iconDir.writeUInt16LE(32, entryOffset + 6);
    iconDir.writeUInt32LE(buffer.length, entryOffset + 8);
    iconDir.writeUInt32LE(offset, entryOffset + 12);

    offset += buffer.length;
    imageBuffers.push(buffer);
  }

  writeFileSync(join(iconsDir, 'icon.ico'), Buffer.concat([iconDir, ...imageBuffers]));
  console.log('✓ ICO icon.ico');
}

async function main() {
  console.log('Generating app icons...\n');
  await generatePngAssets();
  await generateIcns();
  await generateIco();
  console.log('\nDone.');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
