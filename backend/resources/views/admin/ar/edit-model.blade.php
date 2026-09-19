@extends('layouts.admin')
@section('title', 'Edit 3D Model')
@section('page-title', 'Edit 3D Model')

@section('content')
<script type="module" src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.5.0/model-viewer.min.js"></script>

<div class="max-w-6xl mx-auto">
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {{-- LEFT: 3D Viewer --}}
        <div class="lg:col-span-2">
            <div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
                <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
                    <h3 class="text-sm font-semibold text-gray-900">Preview 3D Model</h3>
                    <div class="flex items-center gap-2">
                        <span class="inline-flex items-center gap-1 text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded-full">
                            <svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M15 15l-2 5L9 9l11 4-5 2zm0 0l5 5M7.188 2.239l.777 2.897M5.136 7.965l-2.898-.777M13.95 4.05l-2.122 2.122m-5.657 5.656l-2.12 2.122" /></svg>
                            Geser & zoom
                        </span>
                    </div>
                </div>

                <div class="relative" style="height: 500px; background: #f8f9fa;">
                    @if($model->glb_path)
                        <model-viewer
                            id="modelViewer"
                            src="{{ asset('storage/' . $model->glb_path) }}"
                            alt="{{ $model->model_name }}"
                            camera-controls
                            touch-action="pan-y"
                            auto-rotate
                            auto-rotate-delay="3000"
                            rotation-per-second="30deg"
                            camera-orbit="45deg 55deg 105%"
                            min-camera-orbit="auto auto 50%"
                            max-camera-orbit="Infinity Infinity 200%"
                            field-of-view="30deg"
                            shadow-intensity="1"
                            shadow-softness="0.5"
                            environment-image="neutral"
                            exposure="1"
                            style="width: 100%; height: 100%; background: #f8f9fa;"
                            poster="{{ $model->thumbnail_path ? asset('storage/' . $model->thumbnail_path) : '' }}"
                        >
                            <div id="loading-overlay" slot="progress-bar" style="display:none;"></div>

                            {{-- Hotspot slots will be injected via JS --}}
                            @foreach($model->hotspots()->where('is_active', true)->orderBy('sort_order')->get() as $hotspot)
                                <button
                                    class="hotspot-btn"
                                    slot="hotspot-{{ $hotspot->id }}"
                                    data-position="{{ $hotspot->position_x }} {{ $hotspot->position_y }} {{ $hotspot->position_z }}"
                                    data-normal="{{ $hotspot->rotation_x }} {{ $hotspot->rotation_y }} {{ $hotspot->rotation_z }}"
                                    data-visibility-attribute="visible"
                                    style="--min-hotspot-opacity: 0;"
                                >
                                    <div class="hotspot-dot" data-hotspot-id="{{ $hotspot->id }}"></div>
                                </button>
                            @endforeach

                            <div id="poster" slot="poster" style="display:none;"></div>
                        </model-viewer>

                        {{-- Hotspot Info Panel --}}
                        <div id="hotspotPanel" class="hidden absolute top-4 right-4 w-80 bg-white rounded-xl shadow-lg border border-gray-200 z-10">
                            <div class="px-4 py-3 border-b border-gray-100 flex items-center justify-between">
                                <h4 id="hotspotTitle" class="text-sm font-semibold text-gray-900"></h4>
                                <button onclick="closeHotspotPanel()" class="text-gray-400 hover:text-gray-600">
                                    <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
                                </button>
                            </div>
                            <div class="p-4">
                                <p id="hotspotDescription" class="text-sm text-gray-600 leading-relaxed"></p>
                            </div>
                            <div class="px-4 pb-3 flex gap-2">
                                <button onclick="editHotspot()" class="flex-1 text-xs font-medium text-emerald-700 bg-emerald-50 hover:bg-emerald-100 rounded-lg px-3 py-2 transition">Edit</button>
                                <button onclick="deleteHotspot()" class="flex-1 text-xs font-medium text-red-700 bg-red-50 hover:bg-red-100 rounded-lg px-3 py-2 transition">Hapus</button>
                            </div>
                        </div>

                        {{-- Mode Toggle --}}
                        <div class="absolute bottom-4 left-4 z-10 flex gap-2">
                            <button id="btnViewMode" onclick="setMode('view')" class="mode-btn active px-3 py-2 rounded-lg text-xs font-medium transition shadow-sm">
                                <svg class="h-4 w-4 inline mr-1" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" /><path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /></svg>
                                Lihat
                            </button>
                            <button id="btnAddMode" onclick="setMode('add')" class="mode-btn px-3 py-2 rounded-lg text-xs font-medium transition shadow-sm">
                                <svg class="h-4 w-4 inline mr-1" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
                                Tambah Penjelasan
                            </button>
                        </div>

                        {{-- Status bar --}}
                        <div id="modeIndicator" class="absolute top-4 left-4 z-10 px-3 py-2 rounded-lg text-xs font-medium bg-emerald-100 text-emerald-800 shadow-sm">
                            Mode: Lihat
                        </div>
                    @else
                        <div class="flex flex-col items-center justify-center h-full text-gray-400">
                            <svg class="h-16 w-16 mb-4" fill="none" viewBox="0 0 24 24" stroke-width="1" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909M3.75 21h16.5A2.25 2.25 0 0 0 22.5 18.75V5.25A2.25 2.25 0 0 0 20.25 3H3.75A2.25 2.25 0 0 0 1.5 5.25v13.5A2.25 2.25 0 0 0 3.75 21Z" /></svg>
                            <p class="text-sm font-medium">Belum ada file GLB</p>
                            <p class="text-xs mt-1">Upload model GLB terlebih dahulu</p>
                        </div>
                    @endif
                </div>
            </div>

            {{-- Hotspot List --}}
            <div class="bg-white rounded-xl border border-gray-200 mt-6">
                <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
                    <h3 class="text-sm font-semibold text-gray-900">Penjelasan pada Model 3D</h3>
                    <span id="hotspotCount" class="text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded-full">{{ $model->hotspots()->count() }} penjelasan</span>
                </div>
                <div id="hotspotList" class="divide-y divide-gray-100">
                    @forelse($model->hotspots()->orderBy('sort_order')->get() as $hotspot)
                        <div class="px-6 py-3 flex items-center gap-4 hover:bg-gray-50" id="hotspot-item-{{ $hotspot->id }}">
                            <div class="flex-shrink-0 w-8 h-8 rounded-full bg-emerald-100 flex items-center justify-center text-emerald-700 text-xs font-bold">
                                {{ $hotspot->sort_order + 1 }}
                            </div>
                            <div class="flex-1 min-w-0">
                                <p class="text-sm font-medium text-gray-900 truncate">{{ $hotspot->title }}</p>
                                <p class="text-xs text-gray-500 truncate">{{ $hotspot->description ?? 'Tanpa deskripsi' }}</p>
                            </div>
                            <div class="flex items-center gap-1 text-xs text-gray-400">
                                <span>x:{{ number_format($hotspot->position_x, 1) }}</span>
                                <span>y:{{ number_format($hotspot->position_y, 1) }}</span>
                                <span>z:{{ number_format($hotspot->position_z, 1) }}</span>
                            </div>
                            <div class="flex items-center gap-2">
                                @if($hotspot->is_active)
                                    <span class="inline-flex rounded-full px-2 py-0.5 text-xs font-medium bg-emerald-100 text-emerald-700">Aktif</span>
                                @else
                                    <span class="inline-flex rounded-full px-2 py-0.5 text-xs font-medium bg-gray-100 text-gray-500">Nonaktif</span>
                                @endif
                                <button onclick="editHotspotById({{ $hotspot->id }})" class="text-gray-400 hover:text-emerald-600 p-1">
                                    <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Z" /></svg>
                                </button>
                                <button onclick="deleteHotspotById({{ $hotspot->id }})" class="text-gray-400 hover:text-red-600 p-1">
                                    <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" /></svg>
                                </button>
                            </div>
                        </div>
                    @empty
                        <div class="px-6 py-8 text-center text-sm text-gray-400">
                            <svg class="h-10 w-10 mx-auto mb-2 text-gray-300" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M11.25 11.25l.041-.02a.75.75 0 0 1 1.063.852l-.708 2.836a.75.75 0 0 0 1.063.853l.041-.021M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z" /></svg>
                            <p class="font-medium">Belum ada penjelasan</p>
                            <p class="text-xs mt-1">Klik "Tambah Penjelasan" lalu klik pada model 3D</p>
                        </div>
                    @endforelse
                </div>
            </div>
        </div>

        {{-- RIGHT: Edit Form --}}
        <div class="lg:col-span-1">
            <div class="bg-white rounded-xl border border-gray-200 p-6 sticky top-6">
                <form method="POST" action="{{ route('admin.ar.models.update', $model) }}" enctype="multipart/form-data" class="space-y-5">
                    @csrf
                    @method('PUT')

                    @if($errors->any())
                        <div class="rounded-md bg-red-50 p-3 text-sm text-red-700 border border-red-200">
                            @foreach($errors->all() as $error)
                                <p>{{ $error }}</p>
                            @endforeach
                        </div>
                    @endif

                    <div>
                        <label class="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Nama Model</label>
                        <input type="text" name="model_name" value="{{ old('model_name', $model->model_name) }}" required class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                    </div>

                    <div>
                        <label class="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">File GLB Saat Ini</label>
                        <div class="rounded-lg border border-gray-200 bg-gray-50 p-3 text-sm text-gray-600">
                            <p class="truncate font-mono text-xs" title="{{ $model->glb_path }}">{{ $model->glb_path ?? '-' }}</p>
                            <p class="text-xs text-gray-400 mt-1">Versi: v{{ $model->version }}</p>
                        </div>
                    </div>

                    <div>
                        <label class="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Ganti File GLB <span class="text-gray-400 font-normal">(opsional)</span></label>
                        <input type="file" name="glb_path" accept=".glb,.gltf" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                        <p class="text-xs text-gray-400 mt-1">Upload baru akan menambah versi otomatis.</p>
                    </div>

                    <div>
                        <label class="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Thumbnail <span class="text-gray-400 font-normal">(opsional)</span></label>
                        @if($model->thumbnail_path)
                            <div class="mb-2">
                                <img src="{{ asset('storage/' . $model->thumbnail_path) }}" alt="Thumbnail" class="h-20 w-auto rounded-lg border border-gray-200 object-cover">
                            </div>
                        @endif
                        <input type="file" name="thumbnail_path" accept="image/*" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                    </div>

                    <div>
                        <label class="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Deskripsi</label>
                        <textarea name="description" rows="3" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">{{ old('description', $model->description) }}</textarea>
                    </div>

                    <div>
                        <label class="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Kategori</label>
                        <input type="text" name="category" value="{{ old('category', $model->category) }}" placeholder="Contoh: Hardware Komputer" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                    </div>

                    <div class="flex items-center gap-2">
                        <input type="hidden" name="is_active" value="0">
                        <input type="checkbox" name="is_active" value="1" {{ old('is_active', $model->is_active) ? 'checked' : '' }} class="h-4 w-4 rounded border-gray-300 text-emerald-600 focus:ring-emerald-500">
                        <label class="text-sm text-gray-700">Aktif</label>
                    </div>

                    <div class="flex items-center gap-3 pt-2">
                        <a href="{{ route('admin.ar.models.index') }}" class="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">Batal</a>
                        <button type="submit" class="flex-1 rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">Perbarui Model</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

{{-- Add/Edit Hotspot Modal --}}
<div id="hotspotModal" class="hidden fixed inset-0 z-50 overflow-y-auto" aria-modal="true">
    <div class="flex items-center justify-center min-h-screen px-4">
        <div class="fixed inset-0 bg-gray-900/50 backdrop-blur-sm" onclick="closeHotspotModal()"></div>
        <div class="relative bg-white rounded-2xl shadow-xl w-full max-w-md z-10">
            <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
                <h3 id="modalTitle" class="text-base font-semibold text-gray-900">Tambah Penjelasan</h3>
                <button onclick="closeHotspotModal()" class="text-gray-400 hover:text-gray-600">
                    <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
                </button>
            </div>
            <form id="hotspotForm" class="p-6 space-y-4">
                <input type="hidden" id="hs_id" value="">
                <input type="hidden" id="hs_position_x" value="0">
                <input type="hidden" id="hs_position_y" value="0">
                <input type="hidden" id="hs_position_z" value="0">

                <div>
                    <label class="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Judul Penjelasan <span class="text-red-500">*</span></label>
                    <input type="text" id="hs_title" required placeholder="Contoh: ALU (Arithmetic Logic Unit)" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                </div>

                <div>
                    <label class="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Deskripsi / Penjelasan</label>
                    <textarea id="hs_description" rows="4" placeholder="Jelaskan fungsi dan kegunaan komponen ini..." class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"></textarea>
                </div>

                <div class="grid grid-cols-3 gap-3">
                    <div>
                        <label class="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Posisi X</label>
                        <input type="number" id="hs_pos_x" step="0.01" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm font-mono focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                    </div>
                    <div>
                        <label class="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Posisi Y</label>
                        <input type="number" id="hs_pos_y" step="0.01" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm font-mono focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                    </div>
                    <div>
                        <label class="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Posisi Z</label>
                        <input type="number" id="hs_pos_z" step="0.01" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm font-mono focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                    </div>
                </div>

                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Ukuran</label>
                        <input type="number" id="hs_scale" step="0.1" min="0.1" value="1" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm font-mono focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                    </div>
                    <div>
                        <label class="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Urutan</label>
                        <input type="number" id="hs_sort_order" min="0" value="0" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm font-mono focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                    </div>
                </div>

                <div>
                    <label class="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Ikon Hotspot (opsional)</label>
                    <input type="file" id="hs_image" accept="image/*" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                </div>

                <div class="flex items-center gap-2">
                    <input type="checkbox" id="hs_is_active" checked class="h-4 w-4 rounded border-gray-300 text-emerald-600 focus:ring-emerald-500">
                    <label class="text-sm text-gray-700">Aktif</label>
                </div>

                <div class="flex gap-3 pt-2">
                    <button type="button" onclick="closeHotspotModal()" class="flex-1 rounded-lg border border-gray-300 px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50">Batal</button>
                    <button type="submit" class="flex-1 rounded-lg bg-emerald-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-emerald-700">Simpan</button>
                </div>
            </form>
        </div>
    </div>
</div>

<style>
    .mode-btn { background: rgba(255,255,255,0.9); color: #637080; border: 1px solid #e5e7eb; }
    .mode-btn.active { background: #0A8477; color: white; border-color: #0A8477; }
    .mode-btn:hover:not(.active) { background: #f3f4f6; }

    .hotspot-dot {
        width: 28px; height: 28px; border-radius: 50%;
        background: #0A8477; border: 3px solid white;
        box-shadow: 0 2px 8px rgba(0,0,0,0.3);
        cursor: pointer; transition: all 0.2s;
        display: flex; align-items: center; justify-content: center;
    }
    .hotspot-dot::after {
        content: ''; width: 8px; height: 8px; border-radius: 50%;
        background: white;
    }
    .hotspot-dot:hover { transform: scale(1.2); background: #065e53; }

    model-viewer { --progress-bar-color: #0A8477; }
    model-viewer::part(default-progress-bar) { display: none; }

    .hotspot-label {
        position: absolute; transform: translate(-50%, -100%);
        background: white; border-radius: 8px; padding: 4px 8px;
        font-size: 11px; font-weight: 600; color: #1a1a2e;
        box-shadow: 0 2px 8px rgba(0,0,0,0.15);
        white-space: nowrap; pointer-events: none;
        margin-bottom: 8px;
    }
</style>

<script>
    let currentMode = 'view';
    let currentHotspotId = null;
    const MODEL_ID = {{ $model->id }};
    const CSRF_TOKEN = '{{ csrf_token() }}';
    const HOTSPOT_API = '{{ route("admin.ar.hotspots-api.index") }}';

    function setMode(mode) {
        currentMode = mode;
        document.getElementById('btnViewMode').classList.toggle('active', mode === 'view');
        document.getElementById('btnAddMode').classList.toggle('active', mode === 'add');

        const indicator = document.getElementById('modeIndicator');
        if (mode === 'view') {
            indicator.textContent = 'Mode: Lihat';
            indicator.className = 'absolute top-4 left-4 z-10 px-3 py-2 rounded-lg text-xs font-medium bg-emerald-100 text-emerald-800 shadow-sm';
        } else {
            indicator.textContent = 'Mode: Klik model untuk tambah penjelasan';
            indicator.className = 'absolute top-4 left-4 z-10 px-3 py-2 rounded-lg text-xs font-medium bg-amber-100 text-amber-800 shadow-sm';
        }
    }

    function initModelViewer() {
        const viewer = document.getElementById('modelViewer');
        if (!viewer) return;

        viewer.addEventListener('click', (e) => {
            if (currentMode !== 'add') return;

            const rect = viewer.getBoundingClientRect();
            const x = ((e.clientX - rect.left) / rect.width) * 2 - 1;
            const y = -((e.clientY - rect.top) / rect.height) * 2 + 1;

            const position = viewer.positionAndNormalFromPoint(x, y);
            if (position) {
                const pos = position.position;
                openAddHotspotModal(pos.x, pos.y, pos.z);
            } else {
                openAddHotspotModal(
                    (Math.random() * 2 - 1).toFixed(2),
                    (Math.random() * 2 - 1).toFixed(2),
                    (Math.random() * 2 - 1).toFixed(2)
                );
            }
        });

        viewer.addEventListener('load', () => {
            console.log('3D Model loaded successfully');
        });

        // Setup existing hotspot buttons
        document.querySelectorAll('.hotspot-dot').forEach(dot => {
            dot.addEventListener('click', (e) => {
                e.stopPropagation();
                const id = dot.dataset.hotspotId;
                showHotspotInfo(id);
            });
        });
    }

    function openAddHotspotModal(x, y, z) {
        document.getElementById('hs_id').value = '';
        document.getElementById('hs_title').value = '';
        document.getElementById('hs_description').value = '';
        document.getElementById('hs_pos_x').value = parseFloat(x).toFixed(2);
        document.getElementById('hs_pos_y').value = parseFloat(y).toFixed(2);
        document.getElementById('hs_pos_z').value = parseFloat(z).toFixed(2);
        document.getElementById('hs_scale').value = '1';
        document.getElementById('hs_sort_order').value = '0';
        document.getElementById('hs_is_active').checked = true;
        document.getElementById('hs_image').value = '';
        document.getElementById('modalTitle').textContent = 'Tambah Penjelasan';
        document.getElementById('hotspotModal').classList.remove('hidden');
    }

    function closeHotspotModal() {
        document.getElementById('hotspotModal').classList.add('hidden');
    }

    function closeHotspotPanel() {
        document.getElementById('hotspotPanel').classList.add('hidden');
    }

    async function showHotspotInfo(id) {
        try {
            const res = await fetch(`${HOTSPOT_API}/${id}`);
            const json = await res.json();
            if (json.success) {
                const h = json.data;
                currentHotspotId = h.id;
                document.getElementById('hotspotTitle').textContent = h.title;
                document.getElementById('hotspotDescription').textContent = h.description || 'Tanpa deskripsi';
                document.getElementById('hotspotPanel').classList.remove('hidden');
            }
        } catch (e) {
            console.error('Failed to load hotspot:', e);
        }
    }

    function editHotspot() {
        if (!currentHotspotId) return;
        editHotspotById(currentHotspotId);
    }

    async function editHotspotById(id) {
        try {
            const res = await fetch(`${HOTSPOT_API}/${id}`);
            const json = await res.json();
            if (json.success) {
                const h = json.data;
                document.getElementById('hs_id').value = h.id;
                document.getElementById('hs_title').value = h.title;
                document.getElementById('hs_description').value = h.description || '';
                document.getElementById('hs_pos_x').value = h.position_x;
                document.getElementById('hs_pos_y').value = h.position_y;
                document.getElementById('hs_pos_z').value = h.position_z;
                document.getElementById('hs_scale').value = h.scale || 1;
                document.getElementById('hs_sort_order').value = h.sort_order || 0;
                document.getElementById('hs_is_active').checked = h.is_active;
                document.getElementById('hs_image').value = '';
                document.getElementById('modalTitle').textContent = 'Edit Penjelasan';
                closeHotspotPanel();
                document.getElementById('hotspotModal').classList.remove('hidden');
            }
        } catch (e) {
            console.error('Failed to load hotspot:', e);
        }
    }

    function deleteHotspot() {
        if (!currentHotspotId) return;
        deleteHotspotById(currentHotspotId);
    }

    async function deleteHotspotById(id) {
        if (!confirm('Yakin ingin menghapus penjelasan ini?')) return;
        try {
            const res = await fetch(`${HOTSPOT_API}/${id}`, {
                method: 'DELETE',
                headers: { 'X-CSRF-TOKEN': CSRF_TOKEN, 'Accept': 'application/json' }
            });
            const json = await res.json();
            if (json.success) {
                closeHotspotPanel();
                location.reload();
            }
        } catch (e) {
            console.error('Failed to delete hotspot:', e);
            alert('Gagal menghapus hotspot');
        }
    }

    document.getElementById('hotspotForm').addEventListener('submit', async (e) => {
        e.preventDefault();

        const id = document.getElementById('hs_id').value;
        const isEdit = id !== '';

        const formData = new FormData();
        formData.append('ar_model_id', MODEL_ID);
        formData.append('title', document.getElementById('hs_title').value);
        formData.append('description', document.getElementById('hs_description').value);
        formData.append('position_x', document.getElementById('hs_pos_x').value);
        formData.append('position_y', document.getElementById('hs_pos_y').value);
        formData.append('position_z', document.getElementById('hs_pos_z').value);
        formData.append('scale', document.getElementById('hs_scale').value);
        formData.append('sort_order', document.getElementById('hs_sort_order').value);
        formData.append('is_active', document.getElementById('hs_is_active').checked ? '1' : '0');

        const imageFile = document.getElementById('hs_image').files[0];
        if (imageFile) {
            formData.append('image_path', imageFile);
        }

        try {
            const url = isEdit ? `${HOTSPOT_API}/${id}` : HOTSPOT_API;
            const method = isEdit ? 'POST' : 'POST';
            const headers = { 'X-CSRF-TOKEN': CSRF_TOKEN, 'Accept': 'application/json' };

            if (isEdit) {
                formData.append('_method', 'PUT');
            }

            const res = await fetch(url, {
                method: method,
                headers: headers,
                body: formData
            });
            const json = await res.json();
            if (json.success) {
                closeHotspotModal();
                location.reload();
            } else {
                alert('Error: ' + (json.message || 'Terjadi kesalahan'));
            }
        } catch (e) {
            console.error('Failed to save hotspot:', e);
            alert('Gagal menyimpan hotspot');
        }
    });

    document.addEventListener('DOMContentLoaded', initModelViewer);
</script>
@endsection
