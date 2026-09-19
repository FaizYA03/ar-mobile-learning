@extends('layouts.admin')
@section('title', 'Edit Hotspot')
@section('page-title', 'Edit Hotspot')

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

        <form method="POST" action="{{ route('admin.ar.hotspots.update', $hotspot) }}" enctype="multipart/form-data" class="space-y-5">
            @csrf
            @method('PUT')
            <div>
                <label for="ar_model_id" class="block text-sm font-medium text-gray-700 mb-1">3D Model</label>
                <select name="ar_model_id" id="ar_model_id" required class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                    <option value="">Pilih Model</option>
                    @foreach($models as $model)
                        <option value="{{ $model->id }}" {{ old('ar_model_id', $hotspot->ar_model_id) == $model->id ? 'selected' : '' }}>{{ $model->model_name }}</option>
                    @endforeach
                </select>
            </div>
            <div>
                <label for="title" class="block text-sm font-medium text-gray-700 mb-1">Judul</label>
                <input type="text" name="title" id="title" value="{{ old('title', $hotspot->title) }}" required class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
            </div>
            <div>
                <label for="description" class="block text-sm font-medium text-gray-700 mb-1">Deskripsi</label>
                <textarea name="description" id="description" rows="3" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">{{ old('description', $hotspot->description) }}</textarea>
            </div>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
                <div>
                    <label for="latitude" class="block text-sm font-medium text-gray-700 mb-1">Latitude</label>
                    <input type="number" name="latitude" id="latitude" value="{{ old('latitude', $hotspot->latitude) }}" step="any" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                </div>
                <div>
                    <label for="longitude" class="block text-sm font-medium text-gray-700 mb-1">Longitude</label>
                    <input type="number" name="longitude" id="longitude" value="{{ old('longitude', $hotspot->longitude) }}" step="any" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                </div>
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Gambar Saat Ini</label>
                @if($hotspot->image_path)
                    <div class="mb-3">
                        <img src="{{ asset($hotspot->image_path) }}" alt="Hotspot" class="h-24 w-auto rounded-lg border border-gray-200 object-cover">
                    </div>
                @endif
                <input type="file" name="image_path" id="image_path" accept="image/*" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                <p class="text-xs text-gray-400 mt-1">Upload baru untuk mengganti gambar.</p>
            </div>
            <div class="flex items-center gap-2">
                <input type="hidden" name="is_active" value="0">
                <input type="checkbox" name="is_active" id="is_active" value="1" {{ old('is_active', $hotspot->is_active) ? 'checked' : '' }} class="h-4 w-4 rounded border-gray-300 text-emerald-600 focus:ring-emerald-500">
                <label for="is_active" class="text-sm text-gray-700">Aktif</label>
            </div>
            <div class="flex items-center gap-3 pt-2">
                <a href="{{ route('admin.ar.hotspots.index') }}" class="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">Batal</a>
                <button type="submit" class="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">Perbarui</button>
            </div>
        </form>
    </div>
</div>
@endsection
