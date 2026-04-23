import os

file_path = 'src/App.css'
with open(file_path, 'r') as f:
    content = f.read()

replacements = {
    '--bg-card': '--card-bg',
    '--bg-hover': '--card-bg-hover',
    '--bg-input': '--input-bg',
    '--bg-secondary': '--btn-secondary-bg',
    '--border-color': '--divider',
    '--shadow-color': '--card-shadow'
}

for old, new in replacements.items():
    content = content.replace(old, new)

with open(file_path, 'w') as f:
    f.write(content)

print("Vars replaced.")
