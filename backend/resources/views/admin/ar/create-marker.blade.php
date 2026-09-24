@extends('layouts.admin')
@section('title', 'Upload Marker')
@section('page-title', 'Upload Marker')

@section('content')
<div class="max-w-xl">
    <div class="bg-white rounded-xl border border-gray-200 p-6">
        @if($errors->any())
            <div class="mb-4 rounded-md bg-red-50 p-4 text-sm text-red-700 border border-red-200">
                <ul class="list-disc list-inside">
                    @foreach($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form method="POST" action="{{ route('admin.ar.markers.store') }}" enctype="multipart/form-data" class="space-y-5">
            @csrf
            <div>
                <label for="marker_id" class="block text-sm font-medium text-gray-700 mb-1">Marker ID</label>
                <input type="text" name="marker_id" id="marker_id" value="{{ old('marker_id') }}" required placeholder="Contoh: MARKER_001" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
            </div>
            <div>
                <label for="marker_type" class="block text-sm font-medium text-gray-700 mb-1">Tipe Marker</label>
                <select name="marker_type" id="marker_type" required class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                    <option value="pattern" {{ old('marker_type') === 'pattern' ? 'selected' : '' }}>Pattern</option>
                    <option value="image" {{ old('marker_type') === 'image' ? 'selected' : '' }}>Image</option>
                </select>
            </div>
            <div>
                <label for="image_path" class="block text-sm font-medium text-gray-700 mb-1">Gambar Marker</label>
                <input type="file" name="image_path" id="image_path" accept="image/*" required class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                <p class="text-xs text-gray-400 mt-1">Maks 10MB. Format: jpg, png.</p>
            </div>
            <div class="rounded-lg bg-gray-50 border border-gray-200 p-4">
                <div class="text-xs font-semibold text-gray-500 mb-3">IDENTITAS ARUCO (agar terdeteksi aplikasi — kosongkan bila belum tahu)</div>
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                        <label for="aruco_dictionary" class="block text-sm font-medium text-gray-700 mb-1">Dictionary</label>
                        <select name="aruco_dictionary" id="aruco_dictionary" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                            <option value="">— Tanpa ArUco —</option>
                            @foreach(\App\Services\ArMarkerGenerator::DICTIONARIES as $dict => $count)
                                <option value="{{ $dict }}" {{ old('aruco_dictionary') === $dict ? 'selected' : '' }}>{{ $dict }} ({{ $count }})</option>
                            @endforeach
                        </select>
                    </div>
                    <div>
                        <label for="ar_uco_id" class="block text-sm font-medium text-gray-700 mb-1">ID Pola</label>
                        <input type="number" name="ar_uco_id" id="ar_uco_id" value="{{ old('ar_uco_id') }}" min="0" placeholder="mis. 7" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                    </div>
                </div>
            </div>
            <div>
                <label for="status" class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                <select name="status" id="status" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                    <option value="active" {{ old('status', 'active') === 'active' ? 'selected' : '' }}>Active</option>
                    <option value="inactive" {{ old('status') === 'inactive' ? 'selected' : '' }}>Inactive</option>
                </select>
            </div>
            <div class="flex items-center gap-3 pt-2">
                <a href="{{ route('admin.ar.markers.index') }}" class="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">Batal</a>
                <button type="submit" class="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">Simpan</button>
            </div>
        </form>
    </div>
</div>
@endsection
