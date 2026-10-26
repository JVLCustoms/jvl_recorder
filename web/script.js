// JVL Recorder - panel without focus: everything is driven from client.lua (keys / commands).
const $ = (s) => document.querySelector(s);
let T = {};

function mmss(s) { return `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`; }

window.addEventListener('message', ({ data: m }) => {
    switch (m.action) {
        case 'open':
            T = m.texts || {};
            document.querySelectorAll('[data-t]').forEach((el) => { el.textContent = T[el.dataset.t] || ''; });
            $('#unidad').className = m.position || 'bottom-right';
            if (m.logo) { $('#logo').src = m.logo; $('#logo').classList.remove('oculto'); }
            $('#version').textContent = m.version ? `v${m.version}` : '';
            Object.entries(m.keys || {}).forEach(([k, v]) => { $(`#k-${k}`).textContent = v; });
            document.querySelector('[data-a="editor"]').classList.toggle('oculto', !m.editor);
            $('#nota').classList.toggle('oculto', !m.editor);
            break;
        case 'close':
            $('#unidad').classList.add('oculto');
            break;
        case 'state':
            $('#visor').classList.toggle('grabando', !!m.recording);
            $('#estado').textContent = m.recording ? T.ui_recording : T.ui_ready;
            $('#tiempo').textContent = mmss(m.recording ? m.seconds : 0);
            break;
        case 'flash': {
            const el = $('#aviso');
            el.className = 'aviso';
            void el.offsetWidth; // restart the animation
            el.className = `aviso ${m.kind}`;
            el.textContent = m.kind === 'save' ? T.ui_save : T.ui_discard;
            break;
        }
    }
});
