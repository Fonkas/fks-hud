'use strict';

/* =====================================================================
   fks-hud inside the fks-core NUI (extension, client/hud.lua). The HUD itself plus the /hudsettings
   editor; the editor panel is built with fks-core components (api.render), so it looks like every
   other FKS screen. Tokens, fonts and the panel art come from fks-core.
   ===================================================================== */
FKS.extension(document.currentScript.dataset.owner, (() => {
    const CORES = ['health', 'stamina', 'hunger', 'thirst', 'temperature', 'stress', 'horseHealth', 'horseStamina'];
    const INFO = ['clock', 'job', 'money', 'playerId']; // text info
    const INFO_ICONS = {
        clock:    '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="8.6" fill="none" stroke="currentColor" stroke-width="2"/><path d="M12 7.4V12l3.2 2.1" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>',
        job:      '<svg viewBox="0 0 24 24"><path fill="currentColor" fill-rule="evenodd" d="M9 3.5h6a1.5 1.5 0 0 1 1.5 1.5v2H20a1.5 1.5 0 0 1 1.5 1.5v10A1.5 1.5 0 0 1 20 20H4a1.5 1.5 0 0 1-1.5-1.5v-10A1.5 1.5 0 0 1 4 7h3.5V5A1.5 1.5 0 0 1 9 3.5zm.5 3.5h5V5.5h-5z"/></svg>',
        money:    '<svg viewBox="0 0 24 24"><path d="M16.2 7.6c-.6-1.4-2.1-2.3-4.2-2.3-2.4 0-4 1.2-4 3 0 4.1 8.1 2.4 8.1 6.3 0 1.8-1.7 3.1-4.2 3.1-2.2 0-3.8-.9-4.4-2.5M12 2.8v18.4" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round"/></svg>',
        playerId: '<svg viewBox="0 0 24 24"><path fill="currentColor" fill-rule="evenodd" d="M3.5 5h17A1.5 1.5 0 0 1 22 6.5v11a1.5 1.5 0 0 1-1.5 1.5h-17A1.5 1.5 0 0 1 2 17.5v-11A1.5 1.5 0 0 1 3.5 5zM8 8.3a2.1 2.1 0 1 0 0 4.2 2.1 2.1 0 0 0 0-4.2zM4.8 16.2c.4-1.8 1.7-2.7 3.2-2.7s2.8.9 3.2 2.7zM13.5 9.2h6v1.6h-6zm0 3.2h4.6V14h-4.6z"/></svg>',
    };
    const ICONS = {
        health:  '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M12 20.6l-1.2-1.1C5.9 15.1 3 12.4 3 8.9 3 6.1 5.2 4 7.9 4c1.6 0 3.1.7 4.1 1.9C13 4.7 14.5 4 16.1 4 18.8 4 21 6.1 21 8.9c0 3.5-2.9 6.2-7.8 10.6L12 20.6z"/></svg>',
        stamina: '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M13.4 2.2 5.2 13.4h5.6l-1.4 8.4 9.4-12h-5.9l.5-7.6z"/></svg>',
        hunger:  '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M14.5 3a6.5 6.5 0 0 0-6 9l-3.6 3.6a2 2 0 1 0-1.3 2.8 2 2 0 1 0 2.8-1.3L10 13.5A6.5 6.5 0 1 0 14.5 3z"/></svg>',
        thirst:  '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M12 2.8s-6.5 7.3-6.5 11.9a6.5 6.5 0 0 0 13 0C18.5 10.1 12 2.8 12 2.8z"/></svg>',
        temperature: '<svg viewBox="0 0 24 24"><path d="M10 4.6a2 2 0 0 1 4 0v9.6a4 4 0 1 1-4 0z" fill="none" stroke="currentColor" stroke-width="1.8"/><circle cx="12" cy="17.2" r="2.1" fill="currentColor"/><path d="M12 15.3V8.5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>',
        horseHealth:  '<svg viewBox="0 0 24 24"><path fill="currentColor" fill-rule="evenodd" d="M12 20.6l-1.2-1.1C5.9 15.1 3 12.4 3 8.9 3 6.1 5.2 4 7.9 4c1.6 0 3.1.7 4.1 1.9C13 4.7 14.5 4 16.1 4 18.8 4 21 6.1 21 8.9c0 3.5-2.9 6.2-7.8 10.6L12 20.6zM7.03 7.84L9.34 7.840L9.34 8.56L8.98 8.56L9.19 10.14C10.49 11.44 13.08 11.44 14.52 9.86C14.95 9.28 15.38 8.42 15.67 7.55C16.25 7.70 16.82 8.13 16.68 8.85C16.54 10.14 16.25 11.01 15.82 11.58L16.39 11.58C16.90 11.58 16.97 12.02 16.97 12.45L16.97 13.02C16.97 13.46 16.68 13.74 16.25 13.74L13.94 13.74L13.80 14.90L14.23 14.90L14.23 16.05L11.64 16.05L11.64 14.90L12.07 14.90L11.93 13.74L8.18 13.74C7.75 13.74 7.46 13.46 7.46 13.02L7.46 12.30C7.46 11.87 7.75 11.58 8.18 11.58L8.47 11.58L8.62 10.00L8.04 8.56L7.03 8.56Z"/></svg>',
        horseStamina: '<svg viewBox="0 0 24 24"><path fill="currentColor" fill-rule="evenodd" d="M16 1 3.5 14h6.7L8 23 20.5 9.2h-6.9L16 1zM8.59 9.71L10.12 9.71L10.12 10.19L9.88 10.19L10.03 11.25C10.89 12.11 12.62 12.11 13.58 11.05C13.87 10.67 14.16 10.09 14.35 9.52C14.73 9.61 15.12 9.90 15.02 10.38C14.92 11.25 14.73 11.82 14.44 12.21L14.83 12.21C15.16 12.21 15.21 12.49 15.21 12.78L15.21 13.17C15.21 13.45 15.02 13.65 14.73 13.65L13.20 13.65L13.10 14.41L13.39 14.41L13.39 15.18L11.66 15.18L11.66 14.41L11.95 14.41L11.85 13.65L9.36 13.65C9.07 13.65 8.88 13.45 8.88 13.17L8.88 12.69C8.88 12.40 9.07 12.21 9.36 12.21L9.55 12.21L9.64 11.15L9.26 10.19L8.59 10.19Z"/></svg>',
        stress:  '<svg viewBox="0 0 24 24"><path d="M2 12.5h4.2l2.1-5 3.4 11 3-14 2.3 8H22" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    };

    const OUTER = 46;          // outer ring radius (fixed, the thickness grows inwards)
    const DEFAULT_THICKNESS = 6;
    const SHAPES = ['circle', 'square', 'hexagon'];
    const RED = '#d63a2a';
    const HEART_WEAK = '#ff2a1a';

    let api = null;
    let cfg = null;          // init data (defaults, locale, logo...)
    let layout = null;       // layout being edited
    let savedLayout = null;  // last saved layout
    let values = {};         // last received values
    let editing = false;
    let selected = 'general';
    const els = {};
    const D = {};

    const $ = (s, p) => p.querySelector(s);
    const clone = (o) => JSON.parse(JSON.stringify(o));
    const clamp = (v, a, b) => Math.min(b, Math.max(a, v));
    const L = (k) => (cfg && cfg.locale && cfg.locale[k]) || k;

    function geometry(thickness) {
        const t = clamp(parseFloat(thickness) || DEFAULT_THICKNESS, 2, 16);
        const r = OUTER - t / 2;
        return { t, r, coreR: Math.max(12, OUTER - t - 2.5) };
    }

    // every path starts at the top center and goes clockwise (the ring fills from the top in any shape)
    function shapePath(shape, r) {
        const c = 50;
        if (shape === 'square') {
            const h = r * 0.9;
            const k = h * 0.22;
            const x0 = c - h, x1 = c + h, y0 = c - h, y1 = c + h;
            return `M${c} ${y0}H${x1 - k}A${k} ${k} 0 0 1 ${x1} ${y0 + k}V${y1 - k}A${k} ${k} 0 0 1 ${x1 - k} ${y1}` +
                   `H${x0 + k}A${k} ${k} 0 0 1 ${x0} ${y1 - k}V${y0 + k}A${k} ${k} 0 0 1 ${x0 + k} ${y0}Z`;
        }
        if (shape === 'hexagon') {
            const pts = [-90, -30, 30, 90, 150, 210].map((a) => {
                const rad = (a * Math.PI) / 180;
                return `${(c + r * Math.cos(rad)).toFixed(2)} ${(c + r * Math.sin(rad)).toFixed(2)}`;
            });
            return `M${pts.join('L')}Z`;
        }
        return `M${c} ${c - r}A${r} ${r} 0 1 1 ${c} ${c + r}A${r} ${r} 0 1 1 ${c} ${c - r}Z`;
    }

    function mergeLayout(defaults, saved) {
        const out = clone(defaults);
        if (!saved) return out;
        for (const k of ['scale', 'opacity', 'grid', 'shape']) if (saved[k] !== undefined) out[k] = saved[k];
        for (const id in out.elements) {
            if (saved.elements && saved.elements[id]) Object.assign(out.elements[id], saved.elements[id]);
        }
        return out;
    }

    /* ============================================================ elements */
    function buildCore(id) {
        const el = document.createElement('div');
        el.className = 'fh-el core';
        el.dataset.id = id;
        el.style.position = 'absolute';
        el.innerHTML = `
            <svg class="frame" viewBox="0 0 100 100">
                <defs>
                    <mask id="fh-seg-${id}" maskUnits="userSpaceOnUse" x="-10" y="-10" width="120" height="120">
                        <path class="seg-mask" fill="none" stroke="#fff" pathLength="100"/>
                    </mask>
                    <radialGradient id="fh-shine-${id}" cx="50%" cy="30%" r="60%">
                        <stop offset="0%" stop-color="#fff" stop-opacity=".18"/>
                        <stop offset="100%" stop-color="#fff" stop-opacity="0"/>
                    </radialGradient>
                </defs>
                <path class="disc"/>
                <g mask="url(#fh-seg-${id})">
                    <path class="track" pathLength="100"/>
                    <path class="ring" pathLength="100"/>
                </g>
                <path class="shine-c" fill="url(#fh-shine-${id})"/>
            </svg>
            <div class="icon">
                <div class="icon-bg">${ICONS[id]}</div>
                <div class="icon-fg">${ICONS[id]}</div>
            </div>
            <div class="value"></div>
            <div class="timer"></div>`;
        return el;
    }

    function buildLogo() {
        const el = document.createElement('div');
        el.className = 'fh-el logo';
        el.dataset.id = 'logo';
        const img = document.createElement('img');
        img.draggable = false;
        img.alt = '';
        img.style.cssText = 'width:100%;height:auto;display:block';
        img.src = cfg.logo.image;
        // logo not found -> default logo (and a warning in the F8 console if that fails too)
        img.onerror = () => {
            const fb = cfg.logo.fallback;
            if (fb && !img.dataset.fallback) {
                img.dataset.fallback = '1';
                img.src = fb;
            } else {
                console.log(`[fks-hud] logo image not found: ${cfg.logo.image} (check Config.Logo.image)`);
            }
        };
        el.appendChild(img);
        return el;
    }

    function buildInfo(id) {
        const el = document.createElement('div');
        el.className = 'fh-el info';
        el.dataset.id = id;
        el.innerHTML = `<span class="info-icon">${INFO_ICONS[id]}</span><span class="info-text"></span>`;
        return el;
    }

    function build() {
        D.hud.innerHTML = '';
        for (const k in els) delete els[k];
        for (const id of CORES) {
            els[id] = buildCore(id);
            D.hud.appendChild(els[id]);
        }
        if (cfg.infoEnabled) {
            for (const id of INFO) {
                els[id] = buildInfo(id);
                D.hud.appendChild(els[id]);
            }
        }
        if (cfg.logo && cfg.logo.enabled) {
            els.logo = buildLogo();
            D.hud.appendChild(els.logo);
        }
        for (const id in els) {
            els[id].style.position = 'absolute';
            els[id].addEventListener('pointerdown', (e) => startDrag(e, id));
        }
    }

    /* ============================================================ layout (position / size / colours) */
    function applyLayout() {
        D.hud.style.setProperty('--hs', layout.scale);
        D.hud.style.opacity = layout.opacity;
        D.root.classList.toggle('no-grid', !layout.grid);

        for (const id in els) {
            const s = layout.elements[id];
            const el = els[id];
            if (!s) continue;

            const disabled = (id === 'temperature' && !cfg.tempEnabled) || (id === 'stress' && !cfg.stressEnabled)
                || (id.startsWith('horse') && !cfg.horseEnabled);
            el.classList.toggle('hide', !s.visible || disabled);
            el.style.display = disabled ? 'none' : '';
            el.style.left = `${s.x}%`;
            el.style.top = `${s.y}%`;
            el.style.setProperty('--size', s.size);
            // size also inline: even without hud.css an element can never grow to the whole screen
            if (!INFO.includes(id)) {
                const side = `calc(${Number(s.size) || 56} * 100vh / 1080 * ${Number(layout.scale) || 1})`;
                el.style.width = side;
                el.style.height = id === 'logo' ? 'auto' : side;
            }
            el.classList.toggle('selected', editing && selected === id);

            if (id === 'logo') {
                el.style.opacity = s.opacity;
                continue;
            }
            if (INFO.includes(id)) {
                el.style.color = s.color || '#ffffff';
                $('.info-icon', el).style.color = s.icon || '#ffffff';
                continue;
            }

            $('.ring', el).style.stroke = s.ring;
            $('.track', el).style.stroke = s.ring;
            $('.icon', el).style.color = s.icon;
            el.classList.toggle('show-value', !!s.showValue);

            const shape = SHAPES.includes(layout.shape) ? layout.shape : 'circle';
            const g = geometry(s.thickness);
            el._geo = g;
            el.dataset.shape = shape;
            const ringPath = shapePath(shape, g.r);
            for (const c of el.querySelectorAll('.track, .ring, .seg-mask')) c.setAttribute('d', ringPath);
            for (const c of el.querySelectorAll('.track, .ring')) c.style.strokeWidth = g.t;
            $('.disc', el).setAttribute('d', shapePath(shape, 49));
            $('.shine-c', el).setAttribute('d', shapePath(shape, g.coreR));
            $('.ring', el).setAttribute('stroke-dasharray', '100 100');
            const mask = $('.seg-mask', el);
            mask.setAttribute('stroke-width', g.t + 4);

            $('.icon', el).style.width = $('.icon', el).style.height = `${g.coreR * 2 * 0.64}%`;
            setTrack(el, el._cap === undefined ? 1 : el._cap);
            if (el._ring !== undefined) setRing(el, el._ring);
            if (el._fill !== undefined) setFill(el, el._fill);

            const n = parseInt(s.segments, 10) || 0;
            if (n > 1) mask.setAttribute('stroke-dasharray', `${100 / n - 0.9} 0.9`);
            else mask.removeAttribute('stroke-dasharray');
        }
    }

    /* ============================================================ values */
    function setRing(el, pct) {
        pct = clamp(pct, 0, 100);
        el._ring = pct;
        $('.ring', el).setAttribute('stroke-dashoffset', 100 - pct);
    }
    // maximum ring length (0-1): the horse uses its attribute level, everything else is 1
    function setTrack(el, cap) {
        el._cap = cap;
        $('.track', el).setAttribute('stroke-dasharray', `${100 * clamp(cap, 0, 1)} 100`);
    }
    // inner core: the icon fills from the bottom up (like the native RDR2 HUD)
    function setFill(el, pct) {
        pct = clamp(pct, 0, 100);
        el._fill = pct;
        $('.icon-fg', el).style.clipPath = `inset(${100 - pct}% 0 0 0)`;
    }
    function mixColor(a, b, t) {
        const p = (h) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16));
        const [ca, cb] = [p(a), p(b)];
        return `#${ca.map((v, i) => Math.round(v + (cb[i] - v) * t).toString(16).padStart(2, '0')).join('')}`;
    }
    function setTimer(el, seconds) {
        const t = $('.timer', el);
        el.classList.toggle('has-timer', seconds > 0);
        if (seconds <= 0) { t.textContent = ''; return; }
        const m = Math.floor(seconds / 60), s = seconds % 60;
        t.textContent = m > 0 ? `${m}:${String(s).padStart(2, '0')}` : `${s}s`;
    }
    const setValue = (el, text) => { $('.value', el).textContent = text; };

    function update(v) {
        values = v || {};
        const low = cfg.low;
        D.hud.classList.toggle('off', !values.visible && !editing);

        const horse = values.horse || {};
        const cores = [['health', values.health], ['stamina', values.stamina], ['horseHealth', horse.health], ['horseStamina', horse.stamina]];
        els.horseHealth.classList.toggle('away', !horse.visible);
        els.horseStamina.classList.toggle('away', !horse.visible);

        for (const [id, d] of cores) {
            const el = els[id];
            if (!d) continue;
            setTrack(el, d.cap === undefined ? 1 : d.cap);
            setRing(el, d.outer);
            setFill(el, d.core);
            setValue(el, d.outer);
            el.classList.toggle('gold', !!d.gold);
            setTimer(el, d.goldLeft || 0);

            const rel = d.rel !== undefined ? d.rel : (d.cap ? d.outer / d.cap : d.outer);
            const isStamina = id.endsWith('tamina');
            el.classList.toggle('low', !d.gold && (isStamina ? rel <= (cfg.emptyAt || 3) : (rel <= low || d.core <= low)));

            const es = layout.elements[id] || {};
            let iconColor = es.icon || '#ffffff';
            const weakAt = cfg.heartWeakAt || 0;
            if (id === 'health' && weakAt > 0 && !d.gold && d.core < weakAt) {
                iconColor = mixColor(HEART_WEAK, iconColor, clamp(d.core, 0, weakAt) / weakAt);
            }
            const exhausted = isStamina && d.exhausted && !d.gold;
            el.classList.toggle('exhausted', !!exhausted);
            $('.icon', el).style.color = exhausted ? mixColor(RED, iconColor, d.recovery || 0) : iconColor;
        }

        for (const id of ['hunger', 'thirst']) {
            const el = els[id];
            setRing(el, values[id]);
            setFill(el, 100);
            setValue(el, values[id]);
            el.classList.toggle('low', values[id] <= (cfg.lowNeeds ?? low));
        }

        const st = els.stress;
        setRing(st, values.stress);
        setFill(st, 100);
        setValue(st, values.stress);
        st.classList.toggle('low', values.stress >= 100 - low);

        const t = els.temperature, temp = values.temp || {};
        const range = cfg.temp.max - cfg.temp.min;
        const pct = range > 0 ? ((temp.raw - cfg.temp.min) / range) * 100 : 50;
        setRing(t, pct);
        setFill(t, 100);
        setValue(t, `${temp.value}°${temp.unit || 'C'}`);
        t.classList.remove('t-freezing', 't-cold', 't-hot', 't-burning');
        if (temp.state && temp.state !== 'normal') t.classList.add(`t-${temp.state}`);
        t.classList.toggle('low', temp.state === 'freezing' || temp.state === 'burning');
    }

    /* ============================================================ text info */
    function formatMoney(value, currency) {
        const n = Number(value) || 0;
        return (currency || '$') + n.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }
    function updateInfo(info) {
        const set = (id, text) => { if (els[id]) $('.info-text', els[id]).textContent = text; };
        set('clock', info.clock || '');
        set('job', info.job || '');
        set('money', formatMoney(info.money, info.currency));
        set('playerId', `ID ${info.playerId ?? ''}`);
    }
    function tipOn(el, text, good) {
        const tip = document.createElement('div');
        tip.className = `tip ${good ? 'good' : 'bad'}`;
        tip.textContent = text;
        el.appendChild(tip);
        setTimeout(() => tip.remove(), 2300);
    }
    function moneyTip(amount, currency) {
        const el = els.money;
        if (!el || el.classList.contains('hide') || !amount) return;
        tipOn(el, (amount > 0 ? '+' : '-') + formatMoney(Math.abs(amount), currency), amount > 0);
    }
    function showTips(deltas) {
        for (const id in deltas) {
            const amount = Math.round(deltas[id]);
            const el = els[id];
            if (!amount || !el || el.classList.contains('hide')) continue;
            const good = id === 'stress' ? amount < 0 : amount > 0;
            tipOn(el, (amount > 0 ? '+' : '') + amount + (id === 'temperature' ? '°' : ''), good);
        }
    }

    /* ============================================================ dragging elements (edit mode) */
    let drag = null;
    function startDrag(e, id) {
        if (!editing) return;
        if (id === 'logo' && !cfg.editor.allowLogoEdit) return;
        e.preventDefault();
        const el = els[id];
        const rect = el.getBoundingClientRect();
        drag = { id, el, dx: e.clientX - rect.left, dy: e.clientY - rect.top };
        el.classList.add('dragging');
        select(id);
    }
    function onMove(e) {
        if (drag) {
            const rect = drag.el.getBoundingClientRect();
            const maxX = 100 - (rect.width / innerWidth) * 100;
            const maxY = 100 - (rect.height / innerHeight) * 100;
            let x = ((e.clientX - drag.dx) / innerWidth) * 100;
            let y = ((e.clientY - drag.dy) / innerHeight) * 100;
            if (layout.grid) {
                x = Math.round(x / 0.5) * 0.5;
                y = Math.round(y / 0.5) * 0.5;
            }
            const s = layout.elements[drag.id];
            s.x = +clamp(x, 0, maxX).toFixed(2);
            s.y = +clamp(y, 0, maxY).toFixed(2);
            drag.el.style.left = `${s.x}%`;
            drag.el.style.top = `${s.y}%`;
        }
        if (panelDrag) {
            D.panel.style.left = `${clamp(e.clientX - panelDrag.dx, 0, innerWidth - panelDrag.w)}px`;
            D.panel.style.top = `${clamp(e.clientY - panelDrag.dy, 0, innerHeight - panelDrag.h)}px`;
            D.panel.style.right = 'auto';
            D.panel.style.transform = 'none';
        }
    }
    function onUp() {
        if (drag) {
            drag.el.classList.remove('dragging');
            drag = null;
        }
        panelDrag = null;
    }

    /* ============================================================ /hudsettings panel (fks-core components) */
    let panelDrag = null;
    const ON_OFF = [{ value: true, icon: 'check' }, { value: false, icon: 'x' }];
    const pct = { format: 'percent', reset: null };
    const px = (min, max) => ({ min, max, step: 1, format: 'int', suffix: 'px', reset: null });

    // id = layout key; target = 'layout' (general) or 'el' (the selected element)
    function bodyFor(id) {
        const ed = cfg.editor;
        const list = [{ type: 'section', label: L(id) }];
        const slider = (key, label, value, opts) => ({ type: 'slider', id: key, label, value, step: opts.step || 0.05, action: opts.target || 'el', ...opts });
        const toggle = (key, label, value, target = 'el') => ({ type: 'segmented', style: 'switch', id: key, label, value: !!value, options: ON_OFF, action: target });
        const color = (key, label, value) => ({ type: 'color', id: key, label, value: value || '#ffffff', action: 'el' });

        if (id === 'general') {
            list.push(slider('scale', L('scale'), layout.scale, { min: 0.5, max: 2, target: 'layout', ...pct }));
            list.push(slider('opacity', L('opacity'), layout.opacity, { min: 0.2, max: 1, target: 'layout', ...pct }));
            list.push(toggle('grid', L('grid'), layout.grid, 'layout'));
            if (ed.allowShape !== false) {
                list.push({ type: 'segmented', style: 'switch', id: 'shape', label: L('shape'), value: layout.shape || 'circle', action: 'layout',
                            options: SHAPES.map((s) => ({ value: s, label: L(`shape_${s}`) })) });
            }
            return list;
        }

        const s = layout.elements[id];
        if (!s) return list;
        if (ed.allowHide) list.push(toggle('visible', L('visible'), s.visible));

        if (INFO.includes(id)) {
            if (ed.allowSize) list.push(slider('size', L('size'), s.size, px(10, 48)));
            if (ed.allowColors) {
                list.push(color('color', L('textColor'), s.color));
                list.push(color('icon', L('icon'), s.icon));
            }
            return list;
        }
        if (id === 'logo') {
            list.push(slider('size', L('size'), s.size, { ...px(40, 600), step: 2 }));
            list.push(slider('opacity', L('logoOpacity'), s.opacity, { min: 0.05, max: 1, ...pct }));
            return list;
        }

        if (ed.allowSize) list.push(slider('size', L('size'), s.size, px(24, 140)));
        list.push(slider('thickness', L('thickness'), s.thickness || DEFAULT_THICKNESS, { min: 2, max: 16, step: 1, format: 'int', reset: null }));
        list.push(slider('segments', L('segments'), s.segments, { min: 0, max: 20, step: 1, format: 'int', reset: null }));
        list.push(toggle('showValue', L('showValue'), s.showValue));
        if (ed.allowColors) {
            list.push(color('ring', L('ring'), s.ring));
            list.push(color('icon', L('icon'), s.icon));
        }
        return list;
    }

    function onPanelAction(action, d) {
        if (action === 'layout') layout[d.id] = d.value;
        else if (action === 'el' && layout.elements[selected]) layout.elements[selected][d.id] = d.value;
        applyLayout();
    }

    function renderTabs() {
        D.tabs.innerHTML = '';
        const ids = ['general', ...CORES.filter((id) => els[id] && els[id].style.display !== 'none'), ...INFO.filter((id) => els[id])];
        if (els.logo && cfg.editor.allowLogoEdit) ids.push('logo');
        for (const id of ids) {
            const b = document.createElement('button');
            b.className = `chip${selected === id ? ' on' : ''}`;
            b.textContent = L(id);
            b.addEventListener('click', () => select(id));
            D.tabs.appendChild(b);
        }
    }

    function select(id) {
        selected = id;
        renderTabs();
        api.render(bodyFor(id), D.body, onPanelAction);
        applyLayout();
    }

    function buildPanel() {
        D.panel = document.createElement('section');
        D.panel.className = 'fh-panel hidden';
        D.panel.style.backgroundImage = 'url(img/panel.png)';   // fks-core panel art (resolved against the core page)

        const head = document.createElement('header');
        head.className = 'ui-head fh-head';
        head.innerHTML = `<div class="eyebrow">FKS · HUD</div><h1></h1>
            <svg class="rule" viewBox="0 0 300 12" preserveAspectRatio="none" aria-hidden="true">
                <path d="M2 6 Q75 3 146 6" /><path d="M154 6 Q225 9 298 6" /><path class="gem" d="M150 1 L155 6 L150 11 L145 6 Z" />
            </svg><p class="ui-desc"></p>`;
        $('h1', head).textContent = L('title');
        $('p', head).textContent = L('subtitle');
        head.addEventListener('pointerdown', (e) => {
            const r = D.panel.getBoundingClientRect();
            panelDrag = { dx: e.clientX - r.left, dy: e.clientY - r.top, w: r.width, h: r.height };
            e.preventDefault();
        });

        D.tabs = document.createElement('div');
        D.tabs.className = 'chips fh-tabs';
        D.body = document.createElement('div');
        D.body.className = 'fh-body';

        const foot = document.createElement('footer');
        foot.className = 'fh-foot';
        const btn = (label, cls, fn) => {
            const b = document.createElement('button');
            b.className = `btn small ${cls}`;
            b.textContent = label;
            b.addEventListener('click', fn);
            return b;
        };
        const left = document.createElement('div');
        left.className = 'fh-foot-row';
        left.append(btn(L('reset'), 'ghost', resetLayout));
        if (cfg.editor.allowExport) left.append(btn(L('export'), 'ghost', exportLua));
        const right = document.createElement('div');
        right.className = 'fh-foot-row';
        right.append(btn(L('cancel'), 'ghost', () => closeEditor(false)), btn(L('save'), '', () => closeEditor(true)));
        foot.append(left, right);

        D.panel.append(head, D.tabs, D.body, foot);
        D.root.appendChild(D.panel);
    }

    function openEditor() {
        editing = true;
        layout = clone(savedLayout);
        D.root.classList.add('editing');
        D.panel.classList.remove('hidden');
        select('general');
        if (values.health) update(values);
    }

    function closeEditor(save) {
        if (save) {
            savedLayout = clone(layout);
            api.call('saveLayout', { layout: savedLayout });
        } else {
            layout = clone(savedLayout);
        }
        editing = false;
        D.root.classList.remove('editing');
        D.panel.classList.add('hidden');
        applyLayout();
        if (values.health) update(values);
        api.call('closeEditor');
    }

    function resetLayout() {
        layout = clone(cfg.defaults);
        savedLayout = clone(cfg.defaults);
        api.call('resetLayout');
        select(selected);
    }

    // Config.DefaultLayout block to paste into config.lua
    function exportLua() {
        const lua = (v) => (typeof v === 'string' ? `'${v}'` : String(v));
        const lines = [
            'Config.DefaultLayout = {',
            `    scale   = ${layout.scale},`,
            `    opacity = ${layout.opacity},`,
            `    grid    = ${layout.grid},`,
            `    shape   = '${layout.shape || 'circle'}',`,
            '    elements = {',
        ];
        for (const id in layout.elements) {
            const fields = Object.entries(layout.elements[id]).map(([k, v]) => `${k} = ${lua(v)}`).join(', ');
            lines.push(`        ${id.padEnd(11)} = { ${fields} },`);
        }
        lines.push('    },', '}');
        const ta = document.createElement('textarea');
        ta.value = lines.join('\n');
        document.body.appendChild(ta);
        ta.select();
        document.execCommand('copy');
        ta.remove();
        FKS.toast(L('exported'), 'success');
    }

    function onKey(e) {
        if (editing && e.key === 'Escape' && !FKS.modal.isOpen()) closeEditor(false);
    }

    return {
        mount(a) {
            api = a;
            D.root = document.createElement('div');
            D.root.className = 'fh';
            D.root.style.cssText = 'position:fixed;inset:0;overflow:hidden;pointer-events:none';
            D.grid = document.createElement('div');
            D.grid.className = 'fh-grid';
            D.hud = document.createElement('div');
            D.hud.className = 'fh-hud off';
            D.root.append(D.grid, D.hud);
            api.root.appendChild(D.root);
            window.addEventListener('pointermove', onMove);
            window.addEventListener('pointerup', onUp);
            document.addEventListener('keydown', onKey);
        },
        unmount() {
            window.removeEventListener('pointermove', onMove);
            window.removeEventListener('pointerup', onUp);
            document.removeEventListener('keydown', onKey);
        },
        messages: {
            init(d) {
                cfg = d;
                savedLayout = mergeLayout(cfg.defaults, cfg.layout);
                layout = clone(savedLayout);
                if (D.panel) D.panel.remove();
                editing = false;
                D.root.classList.remove('editing');
                build();
                buildPanel();
                applyLayout();
                if (values.health) update(values);
            },
            tick: (d) => { if (cfg) update(d.data); },
            editor: (d) => { if (cfg && d.open) openEditor(); },
            consumed: (d) => { if (cfg) showTips(d.deltas || {}); },
            info: (d) => { if (cfg) updateInfo(d.data || {}); },
            moneyTip: (d) => { if (cfg) moneyTip(d.amount, d.currency); },
        },
    };
})());
