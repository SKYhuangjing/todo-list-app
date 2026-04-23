import sharp from 'sharp';
import { readFileSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = join(__dirname, '..', '..');
const iconsDir = join(projectRoot, 'tauri', 'src-tauri', 'icons');
const sourcePath = join(iconsDir, 'design', 'user_icon.png');
const outputPath = join(iconsDir, 'design', 'user_icon_fullbleed.png');

async function createFullBleedIcon() {
  console.log('正在创建 Full Bleed 图标...\n');
  
  // 读取原图
  const image = sharp(sourcePath);
  const metadata = await image.metadata();
  
  console.log(`原图尺寸: ${metadata.width}x${metadata.height}`);
  
  // 步骤 1: 裁剪透明边距
  const trimmed = await image
    .trim({ threshold: 10 }) // 裁剪几乎透明的边缘
    .toBuffer();
  
  const trimmedImage = sharp(trimmed);
  const trimmedMeta = await trimmedImage.metadata();
  console.log(`裁剪后尺寸: ${trimmedMeta.width}x${trimmedMeta.height}`);
  
  // 步骤 2: 放大到 1024x1024 并填满（使用 cover 模式）
  // 这会裁掉圆角部分，让内容填满整个正方形
  await trimmedImage
    .resize(1024, 1024, {
      fit: 'cover',  // 填满模式，会裁剪圆角
      position: 'center'
    })
    .png({ quality: 100, compressionLevel: 9, palette: false })
    .toFile(outputPath);
  
  console.log(`✓ Full Bleed 图标已生成: ${outputPath}`);
  console.log('  - 尺寸: 1024x1024');
  console.log('  - 已去除圆角和透明边距');
  console.log('  - 内容填满整个画布\n');
}

createFullBleedIcon().catch(console.error);
