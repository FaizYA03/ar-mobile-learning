@extends('layouts.admin')
@section('title', 'Generate Marker ArUco')
@section('page-title', 'Generate Marker ArUco')

@section('content')
<div class="max-w-2xl">
    @if(!$available)
        <div class="mb-4 rounded-lg bg-amber-50 border border-amber-200 px-4 py-3 text-sm text-amber-700">
            Generator belum tersedia di server (butuh <code>opencv-python-headless</code> + <code>numpy</code>).
            Minta developer menjalankan: <code>pip3 install --break-system-packages opencv-python-headless numpy</code>
        </div>
    @endif

    <form method="POST" action="{{ route('admin.ar.markers.generate.store') }}">
        @csrf
        <div class="bg-white rounded-xl border border-gray-200 p-6">
            <p class="text-xs text-gray-500 mb-5">Marker ArUco <strong>asli</strong> digenerate via OpenCV — langsung terdeteksi aplikasi, tanpa upload file.</p>
            <div class="space-y-4">
                <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Nama Marker (label di CMS)</label>
                    <input type="text" name="marker_id" value="{{ old('marker_id') }}" required maxlength="100" placeholder="mis. MARKER-KELAS-7A" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                </div>
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-medium text-gray-700 mb-1">Pattern Dictionary</label>
                        <select name="aruco_dictionary" id="aruco_dictionary" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                            @foreach($dictionaries as $dict => $count)
                                <option value="{{ $dict }}" {{ old('aruco_dictionary') === $dict ? 'selected' : '' }}>{{ $dict }} ({{ $count }} pola)</option>
                            @endforeach
                        </select>
                        <p class="text-xs text-gray-400 mt-1">Aplikasi memakai <strong>DICT_4X4_50</strong> — pilih itu kecuali paham risikonya.</p>
                    </div>
                    <div>
                        <label class="block text-xs font-medium text-gray-700 mb-1">ID Pola (angka)</label>
                        <input type="number" name="ar_uco_id" value="{{ old('ar_uco_id') }}" required min="0" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                        <p class="text-xs text-gray-400 mt-1" id="id_hint">ID 0–49 untuk DICT_4X4_50.</p>
                    </div>
                </div>
                <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Status</label>
                    <select name="status" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                        <option value="active" selected>Aktif</option>
                        <option value="inactive">Nonaktif</option>
                    </select>
                </div>
                <div class="rounded-lg bg-gray-50 border border-gray-200 p-3 text-xs text-gray-500">
                    ID yang sudah dipakai: <span id="used_list">—</span>
                </div>
            </div>

            @if($errors->any())
                <div class="mt-4 rounded-md bg-red-50 p-4 text-sm text-red-700 border border-red-200">
                    <ul class="list-disc list-inside">
                        @foreach($errors->all() as $error)
                            <li>{{ $error }}</li>
                        @endforeach
                    </ul>
                </div>
            @endif

            <div class="mt-5 flex justify-end gap-2">
                <a href="{{ route('admin.ar.markers.index') }}" class="rounded-lg px-5 py-2 text-sm font-medium text-gray-600 hover:text-gray-800">Batal</a>
                <button type="submit" class="rounded-lg bg-emerald-600 px-5 py-2 text-sm font-medium text-white hover:bg-emerald-700">Generate Marker</button>
            </div>
        </div>
    </form>
</div>

<script>
const dictSizes = @json($dictionaries);
const usedIds = @json($usedIds);
const dictSelect = document.getElementById('aruco_dictionary');
function refreshHint() {
    const dict = dictSelect.value;
    const max = (dictSizes[dict] || 1) - 1;
    document.getElementById('id_hint').textContent = `ID 0–${max} untuk ${dict}.`;
    const used = (usedIds[dict] || []).slice().sort((a, b) => a - b);
    document.getElementById('used_list').textContent = used.length ? used.join(', ') : 'belum ada';
}
dictSelect.addEventListener('change', refreshHint);
refreshHint();
</script>
@endsection
