import sharp from 'sharp';
import { readFileSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = join(__dirname, '..', '..');
const iconsDir = join(projectRoot, 'tauri', 'src-tauri', 'icons');
const svgPath = join(iconsDir, 'tray-icon.svg');

// 读取 SVG 文件
const svgBuffer = readFileSync(svgPath);

// macOS 菜单栏图标尺寸: 22x22 (@1x) 和 44x44 (@2x)
const sizes = [
  { name: 'tray-icon.png', size: 22 },
  { name: 'tray-icon@2x.png', size: 44 },
];

async function generateTrayIcons() {
  console.log('生成托盘图标...\n');
  
  for (const { name, size } of sizes) {
    const outputPath = join(iconsDir, name);
    await sharp(svgBuffer)
      .resize(size, size)
      .png()
      .toFile(outputPath);
    console.log(`✓ 已生成 ${name} (${size}x${size})`);
  }
  
  console.log('\n托盘图标生成完成！');
}

generateTrayIcons().catch(console.error);
