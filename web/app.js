const hud = document.getElementById('hud');
const statusRows = new Map([...document.querySelectorAll('[data-status]')].map((row) => [row.dataset.status, row]));
const bars = [...document.querySelectorAll('.voice-levels i')];
let manuallyHidden = false;

function setMeter(name, rawValue) {
  const row = statusRows.get(name);
  if (!row) return;
  const value = Math.max(0, Math.min(100, Number(rawValue) || 0));
  row.querySelector('.meter-fill').style.width = `${value}%`;
  row.querySelector('.status-value').textContent = String(Math.round(value));
  row.hidden = name === 'armor' && value <= 0;
}

function updateVoice(status = {}) {
  const level = Math.max(1, Math.min(3, Number(status.voice) || 1));
  bars.forEach((bar, index) => bar.classList.toggle('active', index < level));
  document.querySelector('.talk-indicator').classList.toggle('active', status.talking === true);
}

function updateLocation(data = {}, options = {}) {
  document.getElementById('location').hidden = options.showStreet === false && options.showCompass === false;
  document.getElementById('direction').hidden = options.showCompass === false;
  document.getElementById('direction').textContent = data.direction || 'N';
  document.getElementById('street').textContent = data.street || 'Unknown road';
  document.getElementById('crossing').textContent = data.crossing || '';
  document.getElementById('street').hidden = options.showStreet === false;
  document.getElementById('crossing').hidden = options.showStreet === false;
}

function updateVehicle(data, enabled = true) {
  const panel = document.getElementById('vehicle');
  panel.hidden = enabled !== true || !data;
  if (!data || !enabled) return;
  document.getElementById('speed').textContent = String(Math.max(0, Number(data.speed) || 0));
  document.getElementById('unit').textContent = data.unit || 'MPH';
  document.getElementById('gear').textContent = data.gear || 'P';
  const fuel = Math.max(0, Math.min(100, Number(data.fuel) || 0));
  document.getElementById('fuel').textContent = `${fuel}%`;
  document.getElementById('fuel-bar').style.width = `${fuel}%`;
  document.querySelector('.engine-indicator').classList.toggle('on', data.engine === true);
  const belt = document.getElementById('belt');
  belt.classList.toggle('on', data.seatbelt === true);
  belt.classList.toggle('off', data.seatbelt !== true);
}

window.addEventListener('message', ({ data }) => {
  if (!data || typeof data !== 'object') return;
  if (data.action === 'toggle') {
    manuallyHidden = !manuallyHidden;
    hud.classList.toggle('is-hidden', manuallyHidden);
    return;
  }
  if (data.action === 'visibility') {
    hud.classList.toggle('is-hidden', data.visible !== true);
    return;
  }
  if (data.action !== 'update') return;

  hud.classList.toggle('is-hidden', data.visible === false || manuallyHidden);
  hud.classList.toggle('position-left', data.position === 'left');
  const status = data.status || {};
  for (const key of statusRows.keys()) setMeter(key, status[key]);
  updateVoice(status);
  updateLocation(data.location, data);
  updateVehicle(data.vehicle, data.showVehicle);
});
