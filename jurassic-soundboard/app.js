'use strict';

// ── Sound definitions ──────────────────────────────────────────────────────
// cat: "dino" | "quote" | "music" | "ambient"
// file: filename inside sounds/ folder (mp3)
// The myinstants slug is used in the download script to pull the original files.
const SOUNDS = [
  // Dinosaur roars & calls
  { id: 'trex-roar',       label: 'T-Rex Roar',            emoji: '🦖', cat: 'dino',    file: 'trex-roar.mp3',          slug: 'jurassic-park-t-rex-roar' },
  { id: 'trex-roar2',      label: 'T-Rex Scream',          emoji: '🦖', cat: 'dino',    file: 'trex-scream.mp3',         slug: 'jurassic-park-t-rex-roar-2' },
  { id: 'raptor-screech',  label: 'Raptor Screech',        emoji: '🦎', cat: 'dino',    file: 'raptor-screech.mp3',      slug: 'velociraptor-screech-3' },
  { id: 'raptor-bark',     label: 'Raptor Bark',           emoji: '🦎', cat: 'dino',    file: 'raptor-bark.mp3',         slug: 'raptor-sound-effect' },
  { id: 'raptor-call',     label: 'Raptor Call',           emoji: '🦎', cat: 'dino',    file: 'raptor-call.mp3',         slug: 'velociraptor' },
  { id: 'brachi-call',     label: 'Brachiosaurus',         emoji: '🦕', cat: 'dino',    file: 'brachiosaurus.mp3',       slug: 'brachiosaurus-call-jurassic-park' },
  { id: 'diloph-spit',     label: 'Dilophosaurus Spit',   emoji: '🐊', cat: 'dino',    file: 'dilophosaurus-spit.mp3',  slug: 'dilophosaurus-spit' },
  { id: 'diloph-call',     label: 'Dilophosaurus Call',   emoji: '🐊', cat: 'dino',    file: 'dilophosaurus-call.mp3',  slug: 'dilophosaurus' },
  { id: 'triceratops',     label: 'Triceratops',           emoji: '🦏', cat: 'dino',    file: 'triceratops.mp3',         slug: 'triceratops-sound' },
  { id: 'dino-footsteps',  label: 'T-Rex Footsteps',       emoji: '👣', cat: 'dino',    file: 'trex-footsteps.mp3',      slug: 'trex-footsteps' },

  // Famous movie quotes
  { id: 'welcome',         label: 'Welcome to\nJurassic Park', emoji: '🌿', cat: 'quote', file: 'welcome-to-jurassic-park.mp3', slug: 'welcome-to-jurassic-park' },
  { id: 'life-finds-way',  label: 'Life Finds a Way',      emoji: '🧬', cat: 'quote',   file: 'life-finds-a-way.mp3',    slug: 'life-finds-a-way' },
  { id: 'hold-butts',      label: 'Hold Onto Your Butts',  emoji: '🚬', cat: 'quote',   file: 'hold-onto-your-butts.mp3',slug: 'hold-onto-your-butts' },
  { id: 'spared-expense',  label: 'Spared No Expense',     emoji: '💰', cat: 'quote',   file: 'spared-no-expense.mp3',   slug: 'spared-no-expense' },
  { id: 'clever-girl',     label: 'Clever Girl',           emoji: '🎓', cat: 'quote',   file: 'clever-girl.mp3',         slug: 'clever-girl-jurassic-park' },
  { id: 'unix-system',     label: "It's a UNIX System!",   emoji: '💾', cat: 'quote',   file: 'unix-system.mp3',         slug: 'its-a-unix-system-i-know-this' },
  { id: 'must-go-faster',  label: 'Must Go Faster',        emoji: '🏎️', cat: 'quote',   file: 'must-go-faster.mp3',      slug: 'must-go-faster-jurassic-park' },

  // Music
  { id: 'jp-theme',        label: 'JP Theme',              emoji: '🎵', cat: 'music',   file: 'jurassic-park-theme.mp3', slug: 'jurassic-park-theme-song' },
  { id: 'danger-theme',    label: 'Danger Theme',          emoji: '🎼', cat: 'music',   file: 'danger-theme.mp3',        slug: 'jurassic-park-danger-theme' },

  // Ambient
  { id: 'jungle',          label: 'Jungle Ambience',       emoji: '🌴', cat: 'ambient', file: 'jungle-ambience.mp3',     slug: 'jungle-ambience' },
  { id: 'electric-fence',  label: 'Electric Fence',        emoji: '⚡', cat: 'ambient', file: 'electric-fence.mp3',      slug: 'electric-fence' },
  { id: 'flare',           label: 'T-Rex vs Raptors',      emoji: '🔥', cat: 'dino',    file: 'trex-vs-raptors.mp3',     slug: 'jurassic-park-t-rex-saves-the-day' },
  { id: 'godzilla',        label: 'Godzilla Roar',         emoji: '👾', cat: 'dino',    file: 'godzilla-roar.mp3',       slug: '' },
];

// ── State ──────────────────────────────────────────────────────────────────
const audioCache = {};
let currentAudio = null;
let currentBtn   = null;

// ── DOM ────────────────────────────────────────────────────────────────────
const grid   = document.getElementById('sound-grid');
const ripCon = document.getElementById('ripple-container');

// ── Build grid ─────────────────────────────────────────────────────────────
SOUNDS.forEach(sound => {
  const btn = document.createElement('button');
  btn.className   = 'sound-btn';
  btn.dataset.id  = sound.id;
  btn.dataset.cat = sound.cat;
  btn.innerHTML   = `
    <span class="btn-emoji">${sound.emoji}</span>
    <span class="btn-label">${sound.label.replace(/\n/g, '<br>')}</span>
  `;

  // Check if the sound file exists (for deployed app)
  checkSoundExists(sound.file).then(exists => {
    if (!exists) btn.classList.add('missing');
  });

  btn.addEventListener('click', e => handlePlay(e, btn, sound));
  grid.appendChild(btn);
});

// ── Existence check ────────────────────────────────────────────────────────
async function checkSoundExists(file) {
  try {
    const r = await fetch(`sounds/${file}`, { method: 'HEAD' });
    return r.ok;
  } catch { return false; }
}

// ── Playback ───────────────────────────────────────────────────────────────
function handlePlay(e, btn, sound) {
  if (btn.classList.contains('missing')) {
    showToast('⚠️ Sound file not found — see README for setup');
    return;
  }

  spawnRipple(e);

  // Stop currently playing sound
  if (currentAudio && !currentAudio.paused) {
    currentAudio.pause();
    currentAudio.currentTime = 0;
    if (currentBtn) clearPlaying(currentBtn);
    if (currentBtn === btn) { currentBtn = null; currentAudio = null; return; }
  }

  const audio = getAudio(sound.file);
  audio.currentTime = 0;
  audio.play().then(() => {
    currentAudio = audio;
    currentBtn   = btn;
    btn.classList.add('playing');
    btn.style.setProperty('--dur', `${audio.duration || 3}s`);
    audio.onended = () => clearPlaying(btn);
  }).catch(() => showToast('Tap to allow audio'));
}

function clearPlaying(btn) {
  btn.classList.remove('playing');
  btn.style.removeProperty('--dur');
}

function getAudio(file) {
  if (!audioCache[file]) {
    const a = new Audio(`sounds/${file}`);
    a.preload = 'auto';
    audioCache[file] = a;
  }
  return audioCache[file];
}

// ── Ripple effect ──────────────────────────────────────────────────────────
function spawnRipple(e) {
  const el   = document.createElement('div');
  const rect = e.currentTarget.getBoundingClientRect();
  const size = Math.max(rect.width, rect.height) * 2;
  el.className = 'ripple';
  el.style.cssText = `
    width:${size}px;height:${size}px;
    left:${e.clientX - size/2}px;
    top:${e.clientY - size/2}px;
  `;
  ripCon.appendChild(el);
  el.addEventListener('animationend', () => el.remove());
}

// ── Toast ──────────────────────────────────────────────────────────────────
let toastTimer;
function showToast(msg) {
  let toast = document.getElementById('toast');
  if (!toast) {
    toast = document.createElement('div');
    toast.id = 'toast';
    document.body.appendChild(toast);
  }
  toast.textContent = msg;
  toast.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.remove('show'), 3000);
}

// ── Preload on first interaction (iOS requires user gesture) ───────────────
document.addEventListener('touchstart', () => {
  SOUNDS.forEach(s => {
    const a = getAudio(s.file);
    a.load();
  });
}, { once: true });
