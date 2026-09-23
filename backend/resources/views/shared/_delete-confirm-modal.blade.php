{{-- Shared delete confirmation modal + helper. Include once in the admin layout. --}}
<div id="deleteConfirmModal" class="hidden fixed inset-0 z-50 items-center justify-center p-4">
    <div id="deleteConfirmBackdrop" class="fixed inset-0 bg-gray-900/60"></div>
    <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-md p-6">
        <div class="flex items-start gap-4">
            <div class="flex-shrink-0 w-12 h-12 rounded-full bg-red-100 flex items-center justify-center">
                <svg class="h-6 w-6 text-red-600" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" /></svg>
            </div>
            <div class="flex-1 min-w-0">
                <h3 id="deleteConfirmTitle" class="text-base font-semibold text-gray-900">Hapus Data</h3>
                <p id="deleteConfirmMessage" class="mt-1 text-sm text-gray-500">Yakin ingin menghapus data ini?</p>
                <p class="mt-3 text-xs text-red-700 bg-red-50 border border-red-100 rounded-lg px-3 py-2">Tindakan ini tidak dapat dibatalkan.</p>
            </div>
            <button type="button" id="deleteConfirmClose" class="text-gray-400 hover:text-gray-600 transition">
                <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
            </button>
        </div>
        <div class="mt-6 flex items-center justify-end gap-3">
            <button type="button" id="deleteConfirmCancel" class="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 transition">Batal</button>
            <button type="button" id="deleteConfirmOk" class="rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700 transition shadow-sm">Hapus</button>
        </div>
    </div>
</div>

<script>
    (function () {
        const modal = document.getElementById('deleteConfirmModal');
        if (!modal || window._deleteConfirmInit) return;
        window._deleteConfirmInit = true;

        const titleEl = document.getElementById('deleteConfirmTitle');
        const messageEl = document.getElementById('deleteConfirmMessage');
        const okBtn = document.getElementById('deleteConfirmOk');
        const cancelBtn = document.getElementById('deleteConfirmCancel');
        const closeBtn = document.getElementById('deleteConfirmClose');
        const backdrop = document.getElementById('deleteConfirmBackdrop');

        let pendingResolver = null;

        function show() {
            modal.classList.remove('hidden');
            modal.classList.add('flex');
            okBtn.focus();
        }

        function hide() {
            modal.classList.add('hidden');
            modal.classList.remove('flex');
        }

        function open(opts) {
            titleEl.textContent = opts.title || 'Hapus Data';
            messageEl.textContent = opts.message || 'Yakin ingin menghapus data ini?';
            okBtn.textContent = opts.confirmText || 'Hapus';
            show();
        }

        function close(resolveValue) {
            hide();
            const resolver = pendingResolver;
            pendingResolver = null;
            if (resolver) resolver(resolveValue);
        }

        function confirmAction(opts) {
            return new Promise(function (resolve) {
                pendingResolver = resolve;
                open(opts || {});
            });
        }

        okBtn.addEventListener('click', function () { close(true); });
        cancelBtn.addEventListener('click', function () { close(false); });
        closeBtn.addEventListener('click', function () { close(false); });
        backdrop.addEventListener('click', function () { close(false); });
        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape' && pendingResolver) {
                close(false);
            }
        });

        window.deleteConfirm = {
            confirm: confirmAction,
            openForm: function (event, opts) {
                event.preventDefault();
                const form = event.target;
                confirmAction(opts || {}).then(function (ok) {
                    if (ok) form.submit();
                });
            }
        };
    })();
</script>