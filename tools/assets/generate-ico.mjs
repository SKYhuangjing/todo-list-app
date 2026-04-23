import sharp from 'sharp';
import { readFileSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = join(__dirname, '..', '..');
const iconsDir = join(projectRoot, 'tauri', 'src-tauri', 'icons');

// ICO 文件格式生成器
async function generateIco() {
  const sizes = [16, 32, 48, 64, 128, 256];
  const images = [];
  
  // 读取源 PNG 并调整为各种尺寸
  const sourcePng = join(iconsDir, 'icon.png');
  
  for (const size of sizes) {
    const buffer = await sharp(sourcePng)
      .resize(size, size)
      .png()
      .toBuffer();
    images.push({ size, buffer });
  }
  
  // 构建 ICO 文件
  const iconDir = Buffer.alloc(6 + images.length * 16);
  iconDir.writeUInt16LE(0, 0); // Reserved
  iconDir.writeUInt16LE(1, 2); // Type: 1 = ICO
  iconDir.writeUInt16LE(images.length, 4); // Number of images
  
  let offset = 6 + images.length * 16;
  const imageBuffers = [];
  
  for (let i = 0; i < images.length; i++) {
    const { size, buffer } = images[i];
    const entryOffset = 6 + i * 16;
    
    iconDir.writeUInt8(size < 256 ? size : 0, entryOffset); // Width
    iconDir.writeUInt8(size < 256 ? size : 0, entryOffset + 1); // Height
    iconDir.writeUInt8(0, entryOffset + 2); // Color palette
    iconDir.writeUInt8(0, entryOffset + 3); // Reserved
    iconDir.writeUInt16LE(1, entryOffset + 4); // Color planes
    iconDir.writeUInt16LE(32, entryOffset + 6); // Bits per pixel
    iconDir.writeUInt32LE(buffer.length, entryOffset + 8); // Size
    iconDir.writeUInt32LE(offset, entryOffset + 12); // Offset
    
    offset += buffer.length;
    imageBuffers.push(buffer);
  }
  
  const icoBuffer = Buffer.concat([iconDir, ...imageBuffers]);
  const outputPath = join(iconsDir, 'icon.ico');
  writeFileSync(outputPath, icoBuffer);
  
  console.log('✓ 成功生成 icon.ico');
}

generateIco().catch(console.error);
