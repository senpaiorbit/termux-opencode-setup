#!/data/data/com.termux/files/usr/bin/bash
# One-shot bootstrap for termux-opencode-setup.
# Usage: curl -sL https://raw.githubusercontent.com/senpaiorbit/termux-opencode-setup/main/templates/quickstart.sh | bash
set -u
REPO="https://raw.githubusercontent.com/senpaiorbit/termux-opencode-setup/main"
CFG="$HOME/.config/opencode"
TS="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$CFG/backups"
for f in opencode.json oh-my-opencode-slim.json; do
  [ -f "$CFG/$f" ] && cp "$CFG/$f" "$CFG/backups/$f.$TS" && echo "backup: backups/$f.$TS"
done
echo "downloading starter opencode.json..."
curl -sL -o "$CFG/opencode.json" "$REPO/templates/opencode.starter.json"
echo "downloading 3-preset slim config..."
curl -sL -o "$CFG/oh-my-opencode-slim.json" "$REPO/configs/oh-my-opencode-slim.json"
if [ -d "$HOME/omo-slim-test/package" ]; then
  node -e "
const fs=require('fs');
const p=process.env.HOME+'/.config/opencode/opencode.json';
const c=JSON.parse(fs.readFileSync(p,'utf8'));
c.plugin=[process.env.HOME+'/omo-slim-test/package'];
fs.writeFileSync(p,JSON.stringify(c,null,2)+'\n');
console.log('plugin -> ~/omo-slim-test/package');
"
fi
node -e "
const fs=require('fs');
for (const f of ['opencode.json','oh-my-opencode-slim.json']) {
  JSON.parse(fs.readFileSync(process.env.HOME+'/.config/opencode/'+f,'utf8'));
  console.log('valid: '+f);
}
"
echo 'done. restart OpenCode. switch presets with /preset (free, opencode-free, kilo-free).'
