@extends('layouts.admin')
@section('title', 'Edit 3D Model')
@section('page-title', 'Edit 3D Model')

@section('content')
<script type="module" src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.5.0/model-viewer.min.js"></script>

<div class="max-w-7xl mx-auto">
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

                            @foreach($model->hotspots()->where('is_active', true)->orderBy('sort_order')->get() as $hotspot)
                                <button
                                    class="hotspot-btn existing-hotspot"
                                    slot="hotspot-{{ $hotspot->id }}"
                                    data-position="{{ $hotspot->position_x }} {{ $hotspot->position_y }} {{ $hotspot->position_z }}"
                                    data-normal="{{ $hotspot->rotation_x }} {{ $hotspot->rotation_y }} {{ $hotspot->rotation_z }}"
                                    data-visibility-attribute="visible"
                                    style="--min-hotspot-opacity: 0;"
                                    data-existing-id="{{ $hotspot->id }}"
                                >
                                    <div class="hotspot-dot" data-hotspot-id="{{ $hotspot->id }}"></div>
                                </button>
                            @endforeach

                            <button
                                id="tempHotspot"
                                class="hotspot-btn"
                                slot="hotspot-temp"
                                data-position="0 0 0"
                                data-normal="0 1 0"
                                data-visibility-attribute="visible"
                                style="--min-hotspot-opacity: 0; display: none;"
                            >
                                <div class="hotspot-dot hotspot-dot-temp"></div>
                            </button>

                            <div id="poster" slot="poster" style="display:none;"></div>
                        </model-viewer>

                        {{-- Hotspot Info Panel (view mode) --}}
                        <div id="hotspotPanel" class="hidden absolute top-4 right-4 w-80 bg-white rounded-xl shadow-lg border border-gray-200 z-20">
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
                                <button onclick="editFromPanel()" class="flex-1 text-xs font-medium text-emerald-700 bg-emerald-50 hover:bg-emerald-100 rounded-lg px-3 py-2 transition">Edit</button>
                                <button onclick="deleteFromPanel()" class="flex-1 text-xs font-medium text-red-700 bg-red-50 hover:bg-red-100 rounded-lg px-3 py-2 transition">Hapus</button>
                            </div>
                        </div>

                        {{-- Positioning Overlay --}}
                        <div id="positioningOverlay" class="hidden absolute inset-0 z-10 pointer-events-none">
                            <div class="absolute bottom-4 left-4 right-4 flex items-center justify-between pointer-events-auto">
                                <div id="positioningStatus" class="px-3 py-2 rounded-lg text-xs font-medium bg-amber-100 text-amber-800 shadow-sm">
                                    Klik pada bagian model untuk menempatkan titik
                                </div>
                                <div class="flex gap-2">
                                    <button id="btnUnlockPosition" onclick="unlockPosition()" class="hidden px-3 py-2 rounded-lg text-xs font-medium bg-white text-gray-700 border border-gray-300 hover:bg-gray-50 shadow-sm transition">
                                        <svg class="h-3.5 w-3.5 inline mr-1" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M13.5 10.5V6.75a4.5 4.5 0 1 1 9 0v3.75M3.75 21.75h10.5a2.25 2.25 0 0 0 2.25-2.25v-6.75a2.25 2.25 0 0 0-2.25-2.25H3.75a2.25 2.25 0 0 0-2.25 2.25v6.75a2.25 2.25 0 0 0 2.25 2.25Z" /></svg>
                                        Ubah Posisi
                                    </button>
                                    <button id="btnLockPosition" onclick="lockPosition()" class="hidden px-3 py-2 rounded-lg text-xs font-medium bg-emerald-600 text-white hover:bg-emerald-700 shadow-sm transition">
                                        <svg class="h-3.5 w-3.5 inline mr-1" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 1 0-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 0 0 2.25-2.25v-6.75a2.25 2.25 0 0 0-2.25-2.25H3.75a2.25 2.25 0 0 0-2.25 2.25v6.75a2.25 2.25 0 0 0 2.25 2.25Z" /></svg>
                                        Kunci Posisi
                                    </button>
                                    <button id="btnCancelPlacement" onclick="cancelPlacement()" class="px-3 py-2 rounded-lg text-xs font-medium bg-white text-red-600 border border-red-300 hover:bg-red-50 shadow-sm transition">
                                        Batal
                                    </button>
                                </div>
                            </div>
                        </div>

                        {{-- Mode Indicator --}}
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
                    <div class="flex items-center gap-3">
                        <span id="hotspotCount" class="text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded-full">{{ $model->hotspots()->count() }} penjelasan</span>
                        <button id="btnAddExplanation" onclick="startAddPlacement()" class="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-medium bg-emerald-600 text-white hover:bg-emerald-700 transition shadow-sm">
                            <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
                            Tambah Penjelasan
                        </button>
                    </div>
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
                            <div class="flex items-center gap-1 text-xs text-gray-400 font-mono">
                                <span>x:{{ number_format($hotspot->position_x, 2) }}</span>
                                <span>y:{{ number_format($hotspot->position_y, 2) }}</span>
                                <span>z:{{ number_format($hotspot->position_z, 2) }}</span>
                            </div>
                            <div class="flex items-center gap-2">
                                @if($hotspot->is_active)
                                    <span class="inline-flex rounded-full px-2 py-0.5 text-xs font-medium bg-emerald-100 text-emerald-700">Aktif</span>
                                @else
                                    <span class="inline-flex rounded-full px-2 py-0.5 text-xs font-medium bg-gray-100 text-gray-500">Nonaktif</span>
                                @endif
                                <button onclick="startEditPlacement({{ $hotspot->id }})" class="text-gray-400 hover:text-emerald-600 p-1">
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

        {{-- RIGHT: Panel --}}
        <div class="lg:col-span-1">
            {{-- Model Edit Form --}}
            <div id="modelFormPanel" class="bg-white rounded-xl border border-gray-200 p-6 sticky top-6">
                <h3 class="text-sm font-semibold text-gray-900 mb-4">Edit Model 3D</h3>
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

            {{-- Explanation Form (hidden by default) --}}
            <div id="explanationFormPanel" class="hidden bg-white rounded-xl border border-gray-200 p-6 sticky top-6">
                <div class="flex items-center justify-between mb-4">
                    <h3 id="explanationFormTitle" class="text-sm font-semibold text-gray-900">Tambah Penjelasan</h3>
                    <button onclick="cancelPlacement()" class="text-gray-400 hover:text-gray-600">
                        <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
                    </button>
                </div>

                <form id="explanationForm" class="space-y-4">
                    <input type="hidden" id="hs_id" value="">
                    <input type="hidden" id="hs_position_x" value="0">
                    <input type="hidden" id="hs_position_y" value="0">
                    <input type="hidden" id="hs_position_z" value="0">
                    <input type="hidden" id="hs_rotation_x" value="0">
                    <input type="hidden" id="hs_rotation_y" value="0">
                    <input type="hidden" id="hs_rotation_z" value="0">

                    <div>
                        <label class="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Judul Penjelasan <span class="text-red-500">*</span></label>
                        <input type="text" id="hs_title" required placeholder="Contoh: ALU (Arithmetic Logic Unit)" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                    </div>

                    <div>
                        <label class="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Deskripsi / Penjelasan</label>
                        <textarea id="hs_description" rows="4" placeholder="Jelaskan fungsi dan kegunaan komponen ini..." class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"></textarea>
                    </div>

                    <div>
                        <label class="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Posisi (otomatis dari model)</label>
                        <div class="grid grid-cols-3 gap-2">
                            <div class="rounded-lg border border-gray-200 bg-gray-50 px-3 py-2">
                                <span class="block text-[10px] text-gray-400 uppercase">X</span>
                                <span id="hs_pos_x_display" class="block text-sm font-mono text-gray-700">0.00</span>
                            </div>
                            <div class="rounded-lg border border-gray-200 bg-gray-50 px-3 py-2">
                                <span class="block text-[10px] text-gray-400 uppercase">Y</span>
                                <span id="hs_pos_y_display" class="block text-sm font-mono text-gray-700">0.00</span>
                            </div>
                            <div class="rounded-lg border border-gray-200 bg-gray-50 px-3 py-2">
                                <span class="block text-[10px] text-gray-400 uppercase">Z</span>
                                <span id="hs_pos_z_display" class="block text-sm font-mono text-gray-700">0.00</span>
                            </div>
                        </div>
                    </div>

                    <div class="grid grid-cols-2 gap-3">
                        <div>
                            <label class="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Urutan</label>
                            <input type="number" id="hs_sort_order" min="0" value="0" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm font-mono focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                        </div>
                        <div>
                            <label class="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Ikon (opsional)</label>
                            <input type="file" id="hs_image" accept="image/*" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                        </div>
                    </div>

                    <div class="flex items-center gap-2">
                        <input type="checkbox" id="hs_is_active" checked class="h-4 w-4 rounded border-gray-300 text-emerald-600 focus:ring-emerald-500">
                        <label class="text-sm text-gray-700">Aktif</label>
                    </div>

                    <div class="flex gap-3 pt-2">
                        <button type="button" onclick="cancelPlacement()" class="flex-1 rounded-lg border border-gray-300 px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50">Batal</button>
                        <button type="submit" class="flex-1 rounded-lg bg-emerald-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-emerald-700">Simpan</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<style>
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

    .hotspot-dot-temp {
        background: #f59e0b;
        border-color: white;
        animation: hotspot-pulse 1.5s ease-in-out infinite;
    }
    .hotspot-dot-temp::after { background: white; }

    @keyframes hotspot-pulse {
        0%, 100% { box-shadow: 0 0 0 0 rgba(245, 158, 11, 0.4), 0 2px 8px rgba(0,0,0,0.3); }
        50% { box-shadow: 0 0 0 8px rgba(245, 158, 11, 0), 0 2px 8px rgba(0,0,0,0.3); }
    }

    .hotspot-dot-locked {
        background: #0A8477;
        border-color: white;
        animation: none;
    }

    model-viewer { --progress-bar-color: #0A8477; }
    model-viewer::part(default-progress-bar) { display: none; }
</style>

<script>
    const MODEL_ID = {{ $model->id }};
    const CSRF_TOKEN = '{{ csrf_token() }}';
    const HOTSPOT_API = '{{ route("admin.ar.hotspots-api.index") }}';

    let placementState = {
        mode: 'idle',
        hotspotId: null,
        position: { x: 0, y: 0, z: 0 },
        normal: { x: 0, y: 0, z: 0 },
        isEditing: false,
        hasPosition: false,
        editingExistingElement: null
    };

    const CLICK_THRESHOLD = 5;

    let pointerSession = null;

    function enterPlacementUi(viewer) {
        if (!viewer) return;
        viewer.disableTap = true;
        viewer.autoRotate = false;
        viewer.style.cursor = 'crosshair';
        try {
            const input = viewer.shadowRoot && viewer.shadowRoot.querySelector('.userInput');
            const canvas = viewer.shadowRoot && viewer.shadowRoot.querySelector('canvas');
            if (input) input.style.cursor = 'crosshair';
            if (canvas) canvas.style.cursor = 'crosshair';
        } catch (err) {}
    }

    function leavePlacementUi(viewer) {
        if (!viewer) return;
        viewer.disableTap = false;
        viewer.autoRotate = true;
        viewer.style.cursor = '';
        try {
            const input = viewer.shadowRoot && viewer.shadowRoot.querySelector('.userInput');
            const canvas = viewer.shadowRoot && viewer.shadowRoot.querySelector('canvas');
            if (input) input.style.cursor = '';
            if (canvas) canvas.style.cursor = '';
        } catch (err) {}
    }

    function enforcePlacementCursor() {
        if (placementState.mode !== 'placing') return;
        const viewer = document.getElementById('modelViewer');
        if (!viewer) return;
        try {
            const input = viewer.shadowRoot && viewer.shadowRoot.querySelector('.userInput');
            const canvas = viewer.shadowRoot && viewer.shadowRoot.querySelector('canvas');
            if (input) input.style.cursor = 'crosshair';
            if (canvas) canvas.style.cursor = 'crosshair';
        } catch (err) {}
    }

    function placeTemporaryPoint(e) {
        const viewer = document.getElementById('modelViewer');
        if (!viewer || placementState.mode !== 'placing') return;

        const result = viewer.positionAndNormalFromPoint(e.clientX, e.clientY);
        const status = document.getElementById('positioningStatus');

        if (!result || !result.position) {
            if (status) {
                status.textContent = 'Klik pada permukaan model 3D.';
                status.className = 'px-3 py-2 rounded-lg text-xs font-medium bg-amber-100 text-amber-800 shadow-sm';
            }
            return;
        }

        const pos = result.position;
        const nor = result.normal;
        placementState.position = { x: pos.x, y: pos.y, z: pos.z };
        placementState.normal = { x: nor.x, y: nor.y, z: nor.z };
        placementState.hasPosition = true;
        updateTempHotspot(pos.x, pos.y, pos.z, nor.x, nor.y, nor.z);
        updatePositionDisplay(pos.x, pos.y, pos.z);
        showPositioningUI();
        updateModeIndicator('Mode: Penempatan Titik', 'amber');
    }

    function onViewerPointerDown(e) {
        if (placementState.mode !== 'placing') return;
        if (e.pointerType === 'mouse' && e.button !== 0) return;
        if (e.target && e.target.closest && e.target.closest('.hotspot-btn')) return;

        if (pointerSession == null) {
            pointerSession = {
                pointerId: e.pointerId,
                startX: e.clientX,
                startY: e.clientY,
                startTime: performance.now(),
                moved: false,
                valid: true
            };
        } else if (pointerSession.pointerId !== e.pointerId) {
            pointerSession.valid = false;
        }
        enforcePlacementCursor();
    }

    function onViewerPointerMove(e) {
        if (!pointerSession || pointerSession.pointerId !== e.pointerId) return;
        const dx = e.clientX - pointerSession.startX;
        const dy = e.clientY - pointerSession.startY;
        if (Math.sqrt(dx * dx + dy * dy) > CLICK_THRESHOLD) {
            pointerSession.moved = true;
        }
    }

    function onViewerPointerUp(e) {
        if (!pointerSession || pointerSession.pointerId !== e.pointerId) return;
        const session = pointerSession;
        pointerSession = null;
        enforcePlacementCursor();
        if (placementState.mode !== 'placing') return;
        if (!session.valid) return;
        if (session.moved) return;

        placeTemporaryPoint(e);
    }

    function onViewerPointerCancel(e) {
        if (pointerSession && pointerSession.pointerId === e.pointerId) {
            pointerSession = null;
        }
    }

    function initModelViewer() {
        const viewer = document.getElementById('modelViewer');
        if (!viewer) return;

        viewer.addEventListener('pointerdown', onViewerPointerDown);
        viewer.addEventListener('pointermove', onViewerPointerMove);
        viewer.addEventListener('pointerup', onViewerPointerUp);
        viewer.addEventListener('pointercancel', onViewerPointerCancel);

        viewer.addEventListener('load', () => {
            console.log('3D Model loaded successfully');
        });

        document.querySelectorAll('.hotspot-dot').forEach(dot => {
            dot.addEventListener('click', (e) => {
                e.stopPropagation();
                if (placementState.mode === 'placing') return;
                const id = dot.dataset.hotspotId;
                if (id) showHotspotInfo(id);
            });
        });
    }

    function updateTempHotspot(x, y, z, nx, ny, nz) {
        const temp = document.getElementById('tempHotspot');
        if (!temp) return;
        temp.style.display = '';
        temp.setAttribute('data-position', `${x} ${y} ${z}`);
        temp.setAttribute('data-normal', `${nx} ${ny} ${nz}`);

        const viewer = document.getElementById('modelViewer');
        if (viewer && typeof viewer.updateHotspot === 'function') {
            viewer.updateHotspot({
                name: 'hotspot-temp',
                position: `${x}m ${y}m ${z}m`,
                normal: `${nx}m ${ny}m ${nz}m`
            });
        }

        const dot = temp.querySelector('.hotspot-dot-temp');
        if (dot && placementState.mode === 'locked') {
            dot.classList.add('hotspot-dot-locked');
        } else if (dot) {
            dot.classList.remove('hotspot-dot-locked');
        }
    }

    function hideTempHotspot() {
        const temp = document.getElementById('tempHotspot');
        if (temp) {
            temp.style.display = 'none';
            const dot = temp.querySelector('.hotspot-dot-temp');
            if (dot) dot.classList.remove('hotspot-dot-locked');
        }
    }

    function showPositioningUI() {
        document.getElementById('btnLockPosition').classList.remove('hidden');
        document.getElementById('btnUnlockPosition').classList.add('hidden');
        const status = document.getElementById('positioningStatus');
        status.textContent = 'Titik dipilih — klik untuk memindahkan, atau kunci posisi';
        status.className = 'px-3 py-2 rounded-lg text-xs font-medium bg-emerald-100 text-emerald-800 shadow-sm';
    }

    function updateModeIndicator(text, color) {
        const indicator = document.getElementById('modeIndicator');
        if (!indicator) return;
        indicator.textContent = text;
        if (color === 'emerald') {
            indicator.className = 'absolute top-4 left-4 z-10 px-3 py-2 rounded-lg text-xs font-medium bg-emerald-100 text-emerald-800 shadow-sm';
        } else if (color === 'amber') {
            indicator.className = 'absolute top-4 left-4 z-10 px-3 py-2 rounded-lg text-xs font-medium bg-amber-100 text-amber-800 shadow-sm';
        } else if (color === 'blue') {
            indicator.className = 'absolute top-4 left-4 z-10 px-3 py-2 rounded-lg text-xs font-medium bg-blue-100 text-blue-800 shadow-sm';
        }
    }

    function startAddPlacement() {
        const viewer = document.getElementById('modelViewer');
        if (viewer) {
            enterPlacementUi(viewer);
        }

        placementState = {
            mode: 'placing',
            hotspotId: null,
            position: { x: 0, y: 0, z: 0 },
            normal: { x: 0, y: 0, z: 0 },
            isEditing: false,
            hasPosition: false,
            editingExistingElement: null
        };

        hideTempHotspot();
        document.getElementById('btnLockPosition').classList.add('hidden');
        document.getElementById('btnUnlockPosition').classList.add('hidden');
        document.getElementById('positioningOverlay').classList.remove('hidden');
        document.getElementById('positioningStatus').textContent = 'Klik pada bagian model untuk menempatkan titik';
        document.getElementById('positioningStatus').className = 'px-3 py-2 rounded-lg text-xs font-medium bg-amber-100 text-amber-800 shadow-sm';

        document.getElementById('modelFormPanel').classList.add('hidden');
        document.getElementById('explanationFormPanel').classList.remove('hidden');
        document.getElementById('explanationFormTitle').textContent = 'Tambah Penjelasan';
        document.getElementById('hs_id').value = '';
        document.getElementById('hs_title').value = '';
        document.getElementById('hs_description').value = '';
        document.getElementById('hs_sort_order').value = '0';
        document.getElementById('hs_is_active').checked = true;
        document.getElementById('hs_image').value = '';
        updatePositionDisplay(0, 0, 0);

        updateModeIndicator('Mode: Penempatan Titik', 'amber');
    }

    async function startEditPlacement(id) {
        try {
            const res = await fetch(`${HOTSPOT_API}/${id}`);
            const json = await res.json();
            if (!json.success) return;

            const h = json.data;

            const existingBtn = document.querySelector(`[data-existing-id="${id}"]`);
            if (existingBtn) {
                existingBtn.style.display = 'none';
                placementState.editingExistingElement = existingBtn;
            }

            const viewer = document.getElementById('modelViewer');
            if (viewer) {
                enterPlacementUi(viewer);
            }

            placementState = {
                mode: 'placing',
                hotspotId: h.id,
                position: { x: h.position_x, y: h.position_y, z: h.position_z },
                normal: { x: h.rotation_x || 0, y: h.rotation_y || 0, z: h.rotation_z || 0 },
                isEditing: true,
                hasPosition: true,
                editingExistingElement: existingBtn || null
            };

            updateTempHotspot(h.position_x, h.position_y, h.position_z, h.rotation_x || 0, h.rotation_y || 0, h.rotation_z || 0);

            document.getElementById('positioningOverlay').classList.remove('hidden');

            document.getElementById('modelFormPanel').classList.add('hidden');
            document.getElementById('explanationFormPanel').classList.remove('hidden');
            document.getElementById('explanationFormTitle').textContent = 'Edit Penjelasan';
            document.getElementById('hs_id').value = h.id;
            document.getElementById('hs_title').value = h.title;
            document.getElementById('hs_description').value = h.description || '';
            document.getElementById('hs_sort_order').value = h.sort_order || 0;
            document.getElementById('hs_is_active').checked = h.is_active;
            document.getElementById('hs_image').value = '';

            lockPosition();

            updateModeIndicator('Mode: Edit Penjelasan', 'blue');
        } catch (e) {
            console.error('Failed to load hotspot:', e);
        }
    }

    function lockPosition() {
        if (!placementState.hasPosition) return;

        placementState.mode = 'locked';

        const temp = document.getElementById('tempHotspot');
        if (temp) {
            const dot = temp.querySelector('.hotspot-dot-temp');
            if (dot) dot.classList.add('hotspot-dot-locked');
        }

        document.getElementById('btnLockPosition').classList.add('hidden');
        document.getElementById('btnUnlockPosition').classList.remove('hidden');
        const status = document.getElementById('positioningStatus');
        status.textContent = 'Posisi terkunci — isi informasi penjelasan di panel sebelah kanan';
        status.className = 'px-3 py-2 rounded-lg text-xs font-medium bg-blue-100 text-blue-800 shadow-sm';

        document.getElementById('hs_position_x').value = placementState.position.x;
        document.getElementById('hs_position_y').value = placementState.position.y;
        document.getElementById('hs_position_z').value = placementState.position.z;
        document.getElementById('hs_rotation_x').value = placementState.normal.x;
        document.getElementById('hs_rotation_y').value = placementState.normal.y;
        document.getElementById('hs_rotation_z').value = placementState.normal.z;

        updatePositionDisplay(placementState.position.x, placementState.position.y, placementState.position.z);
        updateModeIndicator('Mode: Posisi Terkunci', 'blue');
    }

    function unlockPosition() {
        placementState.mode = 'placing';

        const temp = document.getElementById('tempHotspot');
        if (temp) {
            const dot = temp.querySelector('.hotspot-dot-temp');
            if (dot) dot.classList.remove('hotspot-dot-locked');
        }

        document.getElementById('btnLockPosition').classList.remove('hidden');
        document.getElementById('btnUnlockPosition').classList.add('hidden');
        const status = document.getElementById('positioningStatus');
        status.textContent = 'Klik pada bagian model untuk memindahkan titik';
        status.className = 'px-3 py-2 rounded-lg text-xs font-medium bg-amber-100 text-amber-800 shadow-sm';

        updateModeIndicator('Mode: Penempatan Titik', 'amber');
    }

    function cancelPlacement() {
        const viewer = document.getElementById('modelViewer');
        if (viewer) {
            leavePlacementUi(viewer);
        }

        if (placementState.editingExistingElement) {
            placementState.editingExistingElement.style.display = '';
        }

        hideTempHotspot();
        document.getElementById('positioningOverlay').classList.add('hidden');
        document.getElementById('modelFormPanel').classList.remove('hidden');
        document.getElementById('explanationFormPanel').classList.add('hidden');

        placementState = {
            mode: 'idle',
            hotspotId: null,
            position: { x: 0, y: 0, z: 0 },
            normal: { x: 0, y: 0, z: 0 },
            isEditing: false,
            hasPosition: false,
            editingExistingElement: null
        };

        updateModeIndicator('Mode: Lihat', 'emerald');
    }

    function updatePositionDisplay(x, y, z) {
        document.getElementById('hs_pos_x_display').textContent = parseFloat(x).toFixed(2);
        document.getElementById('hs_pos_y_display').textContent = parseFloat(y).toFixed(2);
        document.getElementById('hs_pos_z_display').textContent = parseFloat(z).toFixed(2);
    }

    document.getElementById('explanationForm').addEventListener('submit', async (e) => {
        e.preventDefault();

        if (!placementState.hasPosition) {
            alert('Silakan klik bagian model untuk menentukan posisi titik.');
            return;
        }

        if (placementState.mode !== 'locked') {
            alert('Silakan kunci posisi titik.');
            return;
        }

        const title = document.getElementById('hs_title').value.trim();
        if (!title) {
            alert('Judul penjelasan wajib diisi.');
            return;
        }

        const id = document.getElementById('hs_id').value;
        const isEdit = id !== '';

        const formData = new FormData();
        formData.append('ar_model_id', MODEL_ID);
        formData.append('title', title);
        formData.append('description', document.getElementById('hs_description').value);
        formData.append('position_x', placementState.position.x);
        formData.append('position_y', placementState.position.y);
        formData.append('position_z', placementState.position.z);
        formData.append('rotation_x', placementState.normal.x || 0);
        formData.append('rotation_y', placementState.normal.y || 0);
        formData.append('rotation_z', placementState.normal.z || 0);
        formData.append('scale', '1');
        formData.append('sort_order', document.getElementById('hs_sort_order').value);
        formData.append('is_active', document.getElementById('hs_is_active').checked ? '1' : '0');

        const imageFile = document.getElementById('hs_image').files[0];
        if (imageFile) {
            formData.append('image_path', imageFile);
        }

        try {
            const url = isEdit ? `${HOTSPOT_API}/${id}` : HOTSPOT_API;
            const headers = { 'X-CSRF-TOKEN': CSRF_TOKEN, 'Accept': 'application/json' };

            if (isEdit) {
                formData.append('_method', 'PUT');
            }

            const res = await fetch(url, {
                method: 'POST',
                headers: headers,
                body: formData
            });
            const json = await res.json();
            if (json.success) {
                location.reload();
            } else {
                alert('Error: ' + (json.message || 'Terjadi kesalahan'));
            }
        } catch (e) {
            console.error('Failed to save explanation:', e);
            alert('Gagal menyimpan penjelasan');
        }
    });

    function closeHotspotPanel() {
        document.getElementById('hotspotPanel')?.classList.add('hidden');
    }

    async function showHotspotInfo(id) {
        try {
            const res = await fetch(`${HOTSPOT_API}/${id}`);
            const json = await res.json();
            if (json.success) {
                const h = json.data;
                const panel = document.getElementById('hotspotPanel');
                if (!panel) return;
                document.getElementById('hotspotTitle').textContent = h.title;
                document.getElementById('hotspotDescription').textContent = h.description || 'Tanpa deskripsi';
                panel.dataset.currentId = h.id;
                panel.classList.remove('hidden');
            }
        } catch (e) {
            console.error('Failed to load hotspot:', e);
        }
    }

    function editFromPanel() {
        const panel = document.getElementById('hotspotPanel');
        if (panel && panel.dataset.currentId) {
            panel.classList.add('hidden');
            startEditPlacement(parseInt(panel.dataset.currentId));
        }
    }

    function deleteFromPanel() {
        const panel = document.getElementById('hotspotPanel');
        if (panel && panel.dataset.currentId) {
            deleteHotspotById(parseInt(panel.dataset.currentId));
            panel.classList.add('hidden');
        }
    }

    async function deleteHotspotById(id) {
        const confirmed = await window.deleteConfirm.confirm({
            title: 'Hapus Penjelasan',
            message: 'Yakin ingin menghapus penjelasan ini?'
        });
        if (!confirmed) return;
        try {
            const res = await fetch(`${HOTSPOT_API}/${id}`, {
                method: 'DELETE',
                headers: { 'X-CSRF-TOKEN': CSRF_TOKEN, 'Accept': 'application/json' }
            });
            const json = await res.json();
            if (json.success) {
                location.reload();
            }
        } catch (e) {
            console.error('Failed to delete hotspot:', e);
            alert('Gagal menghapus hotspot');
        }
    }

    document.addEventListener('DOMContentLoaded', initModelViewer);
</script>
@endsection
