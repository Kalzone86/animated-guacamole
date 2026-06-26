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
  { id: 'hammond-biz',     label: "Hammond:\nBack in Biz", emoji: '🧓', cat: 'quote',   file: 'hammond-back-in-business.mp3', slug: '' },
  { id: 'nedry-ahahah',    label: 'Ah Ah Ah!',             emoji: '🖥️', cat: 'quote',   file: 'nedry-ah-ah-ah.mp3',      slug: '' },
  { id: 'unix-system',     label: "It's a UNIX System!",   emoji: '💾', cat: 'quote',   file: 'unix-system.mp3',         slug: 'its-a-unix-system-i-know-this' },
  { id: 'must-go-faster',  label: 'Must Go Faster',        emoji: '🏎️', cat: 'quote',   file: 'must-go-faster.mp3',      slug: 'must-go-faster-jurassic-park' },

  // Music
  { id: 'jp-theme',        label: 'JP Theme',              emoji: '🎵', cat: 'music',   file: 'jurassic-park-theme.mp3', slug: 'jurassic-park-theme-song' },
  { id: 'jp-theme-short',  label: 'JP Theme (Fast)',       emoji: '⚡🎵', cat: 'music',  file: 'jp-theme-short.mp3',      slug: '' },
  { id: 'jp-celebration',  label: 'JP Celebration',        emoji: '🎉', cat: 'music',   file: 'jp-celebration.mp3',      slug: '' },
  { id: 'jp-theme-alt',    label: 'JP Theme (Alt)',        emoji: '🎶', cat: 'music',   file: 'jp-theme-alt.mp3',        slug: '' },
  { id: 'flare',           label: 'T-Rex vs Raptors',      emoji: '🔥', cat: 'dino',    file: 'trex-vs-raptors.mp3',     slug: 'jurassic-park-t-rex-saves-the-day' },
  { id: 'raptor-attack',   label: 'Raptor Attack',         emoji: '🦎', cat: 'dino',    file: 'raptor-attack.mp3',          slug: '' },
  { id: 'baryonyx',        label: 'Baryonyx Roar',         emoji: '🐉', cat: 'dino',    file: 'baryonyx-roar.mp3',       slug: 'baryonyx-walkeri-roar' },
  { id: 'dino-roar',       label: 'Dino Roar',             emoji: '🦕', cat: 'dino',    file: 'dino-roar.mp3',           slug: '' },
  { id: 'trex-roar-alt',   label: 'T-Rex Alt Roar',        emoji: '🦖', cat: 'dino',    file: 'trex-roar-alt.mp3',       slug: '' },
  { id: 'trex-roar-3',     label: 'T-Rex Roar 3',          emoji: '🦖', cat: 'dino',    file: 'trex-roar-3.mp3',         slug: '' },
  { id: 'godzilla',        label: 'Godzilla Roar',         emoji: '👾', cat: 'dino',    file: 'godzilla-roar.mp3',       slug: '' },

  // Rex roars — each one a different moment
  { id: 'rex-here-she-comes',   label: 'Rex: HERE SHE COMES!',  emoji: '🦖', cat: 'dino', file: 'trex-here-she-comes.mp3' },
  { id: 'rex-gate-crasher',     label: 'Rex: Gate Crasher',      emoji: '🦖', cat: 'dino', file: 'trex-gate-crasher.mp3' },
  { id: 'rex-the-breakout',     label: 'Rex: The Breakout',      emoji: '🦖', cat: 'dino', file: 'trex-the-breakout.mp3' },
  { id: 'rex-warning-shot',     label: 'Rex: Warning Shot',      emoji: '🦖', cat: 'dino', file: 'trex-warning-shot.mp3' },
  { id: 'rex-paddock-escape',   label: 'Rex: Paddock Escape',    emoji: '🦖', cat: 'dino', file: 'trex-paddock-escape.mp3' },
  { id: 'rex-short-and-loud',   label: 'Rex: Short & LOUD',      emoji: '🦖', cat: 'dino', file: 'trex-short-and-loud.mp3' },
  { id: 'rex-quick-snap',       label: 'Rex: Quick Snap',        emoji: '🦖', cat: 'dino', file: 'trex-quick-snap.mp3' },
  { id: 'rex-dont-move',        label: "Rex: Don't Move",        emoji: '🦖', cat: 'dino', file: 'trex-dont-move.mp3' },
  { id: 'rex-she-found-you',    label: 'Rex: She Found You',     emoji: '🦖', cat: 'dino', file: 'trex-she-found-you.mp3' },
  { id: 'rex-sniff-and-roar',   label: 'Rex: Sniff & Roar',      emoji: '🦖', cat: 'dino', file: 'trex-sniff-and-roar.mp3' },
  { id: 'rex-jungle-thunder',   label: 'Rex: Jungle Thunder',    emoji: '🦖', cat: 'dino', file: 'trex-jungle-thunder.mp3' },
  { id: 'rex-big-entrance',     label: 'Rex: Big Entrance',      emoji: '🦖', cat: 'dino', file: 'trex-big-entrance.mp3' },
  { id: 'rex-feeding-frenzy',   label: 'Rex: Feeding Frenzy',    emoji: '🦖', cat: 'dino', file: 'trex-feeding-frenzy.mp3' },
  { id: 'rex-night-patrol',     label: 'Rex: Night Patrol',      emoji: '🦖', cat: 'dino', file: 'trex-night-patrol.mp3' },
  { id: 'rex-i-smell-you',      label: 'Rex: I Smell You',       emoji: '🦖', cat: 'dino', file: 'trex-i-smell-you.mp3' },
  { id: 'rex-roooaaarrr',       label: 'Rex: ROOOAAARRR!',       emoji: '🦖', cat: 'dino', file: 'trex-roooaaarrr.mp3' },
  { id: 'rex-stomp-walk',       label: 'Rex: Stomp Walk',        emoji: '🦖', cat: 'dino', file: 'trex-stomp-walk.mp3' },
  { id: 'rex-headlight-stare',  label: 'Rex: Headlight Stare',   emoji: '🦖', cat: 'dino', file: 'trex-headlight-stare.mp3' },
  { id: 'rex-river-chase',      label: 'Rex: River Chase',       emoji: '🦖', cat: 'dino', file: 'trex-river-chase.mp3' },
  { id: 'rex-victory-lap',      label: 'Rex: Victory Lap',       emoji: '🦖', cat: 'dino', file: 'trex-victory-lap.mp3' },
  { id: 'rex-king-of-the-park', label: 'Rex: King of the Park',  emoji: '🦖', cat: 'dino', file: 'trex-king-of-the-park.mp3' },
  { id: 'rex-tour-bus-terror',  label: 'Rex: Tour Bus Terror',   emoji: '🦖', cat: 'dino', file: 'trex-tour-bus-terror.mp3' },
  { id: 'rex-sunrise-roar',     label: 'Rex: Sunrise Roar',      emoji: '🦖', cat: 'dino', file: 'trex-sunrise-roar.mp3' },
  { id: 'rex-last-roar',        label: 'Rex: Last Roar',         emoji: '🦖', cat: 'dino', file: 'trex-last-roar.mp3' },
  { id: 'rex-saves-the-day',    label: 'Rex: Saves the Day',     emoji: '🦖', cat: 'dino', file: 'trex-saves-the-day.mp3' },

  // Rex growls — sneaky & stalking
  { id: 'rex-low-rumble',       label: 'Rex: Low Rumble',        emoji: '😤', cat: 'dino', file: 'trex-low-rumble.mp3' },
  { id: 'rex-deep-snarl',       label: 'Rex: Deep Snarl',        emoji: '😤', cat: 'dino', file: 'trex-deep-snarl.mp3' },
  { id: 'rex-getting-closer',   label: 'Rex: Getting Closer',    emoji: '😤', cat: 'dino', file: 'trex-getting-closer.mp3' },
  { id: 'rex-behind-the-trees', label: 'Rex: Behind the Trees',  emoji: '😤', cat: 'dino', file: 'trex-behind-the-trees.mp3' },
  { id: 'rex-sniffing-around',  label: 'Rex: Sniffing Around',   emoji: '😤', cat: 'dino', file: 'trex-sniffing-around.mp3' },
  { id: 'rex-the-stalk',        label: 'Rex: The Stalk',         emoji: '😤', cat: 'dino', file: 'trex-the-stalk.mp3' },

  // Rex takes damage
  { id: 'rex-takes-a-hit',      label: 'Rex: Takes a Hit',       emoji: '💥', cat: 'dino', file: 'trex-takes-a-hit.mp3' },
  { id: 'rex-feels-the-sting',  label: 'Rex: Feels the Sting',   emoji: '💥', cat: 'dino', file: 'trex-feels-the-sting.mp3' },

  // Bonus big sounds
  { id: 'rex-full-rampage',     label: 'Rex: Full Rampage',      emoji: '🔥', cat: 'dino', file: 'trex-full-rampage.mp3' },
  { id: 'rex-loudest-roar',     label: 'Rex: LOUDEST ROAR',      emoji: '📢', cat: 'dino', file: 'trex-loudest-roar.mp3' },
  { id: 'rex-cgi-classic',      label: 'Rex: CGI Classic',       emoji: '🎬', cat: 'dino', file: 'trex-cgi-classic.mp3' },
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
