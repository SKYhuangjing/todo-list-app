import re

with open('src/App.css', 'r') as f:
    content = f.read()

light_theme = '''/* 浅色主题（默认） */
:root,
[data-theme="light"] {
  --container-bg: transparent;
  --container-border: transparent;
  
  --sidebar-bg: rgba(245, 245, 247, 0.6);
  --list-bg: rgba(255, 255, 255, 0.7);
  --details-bg: rgba(255, 255, 255, 0.6);
  
  --item-selected-bg: rgba(0, 0, 0, 0.05);
  --item-hover-bg: rgba(0, 0, 0, 0.03);
  --divider: rgba(0, 0, 0, 0.06);
  
  --card-bg: rgba(255, 255, 255, 0.7);
  --card-bg-hover: rgba(255, 255, 255, 0.8);
  --card-border: rgba(0, 0, 0, 0.04);
  --card-shadow: 0 8px 32px rgba(0, 0, 0, 0.04);
  
  --input-bg: rgba(0, 0, 0, 0.04);
  --input-bg-focus: rgba(255, 255, 255, 0.9);
  --input-border: transparent;
  --input-border-focus: var(--accent);
  
  --text-primary: #1D1D1F;
  --text-secondary: #515154;
  --text-tertiary: #86868B;
  
  --accent: #0A84FF;
  --accent-light: rgba(10, 132, 255, 0.1);
  --accent-hover: #0070E0;
  --success: #34C759;
  --success-light: #E8F5E9;
  --warning: #FF9500;
  --danger: #FF3B30;
  
  --btn-secondary-bg: var(--input-bg);
  --btn-secondary-hover: rgba(0, 0, 0, 0.08);
  
  --accent-rgb: 10, 132, 255;
}'''

dark_theme = '''/* 深色主题 */
[data-theme="dark"] {
  --sidebar-bg: rgba(30, 30, 30, 0.6);
  --list-bg: rgba(40, 40, 40, 0.7);
  --details-bg: rgba(30, 30, 30, 0.6);
  
  --item-selected-bg: rgba(255, 255, 255, 0.1);
  --item-hover-bg: rgba(255, 255, 255, 0.05);
  
  --container-bg: transparent;
  --container-border: rgba(255, 255, 255, 0.08);
  --container-shadow: 
    0 24px 80px -20px rgba(0, 0, 0, 0.5),
    0 0 1px rgba(0, 0, 0, 0.3);
  
  --card-bg: rgba(255, 255, 255, 0.05);
  --card-bg-hover: rgba(255, 255, 255, 0.1);
  --card-border: rgba(255, 255, 255, 0.08);
  --card-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
  
  --input-bg: rgba(255, 255, 255, 0.08);
  --input-bg-focus: rgba(255, 255, 255, 0.15);
  --input-border: transparent;
  --input-border-focus: var(--accent);
  
  --text-primary: #F5F5F7;
  --text-secondary: #A1A1A6;
  --text-tertiary: #86868B;
  
  --accent: #0A84FF;
  --accent-light: rgba(10, 132, 255, 0.2);
  --accent-hover: #47A1FF;
  --success: #32D74B;
  --success-light: rgba(50, 215, 75, 0.15);
  --warning: #FF9F0A;
  --danger: #FF453A;
  
  --divider: rgba(255, 255, 255, 0.1);
  
  --btn-secondary-bg: rgba(255, 255, 255, 0.1);
  --btn-secondary-hover: rgba(255, 255, 255, 0.15);
}'''

content = re.sub(r'/\* 浅色主题（默认） \*/.*?(?=/\* 深色主题 \*/)', light_theme + '\n\n', content, flags=re.DOTALL)
content = re.sub(r'/\* 深色主题 \*/.*?(?=/\* 通用设计 Token \*/)', dark_theme + '\n\n', content, flags=re.DOTALL)

with open('src/App.css', 'w') as f:
    f.write(content)

print("Done replacing themes.")
