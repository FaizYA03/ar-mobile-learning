@extends('layouts.admin')
@section('title', 'Upload 3D Model')
@section('page-title', 'Upload 3D Model')

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

        <form method="POST" action="{{ route('admin.ar.models.store') }}" enctype="multipart/form-data" class="space-y-5">
            @csrf
            <div>
                <label for="model_name" class="block text-sm font-medium text-gray-700 mb-1">Nama Model</label>
                <input type="text" name="model_name" id="model_name" value="{{ old('model_name') }}" required class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
            </div>
            <div>
                <label for="glb_path" class="block text-sm font-medium text-gray-700 mb-1">File GLB</label>
                <input type="file" name="glb_path" id="glb_path" accept=".glb,.gltf" required class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                <p class="text-xs text-gray-400 mt-1">Format: .glb atau .gltf. Maks 100MB.</p>
            </div>
            <div>
                <label for="thumbnail_path" class="block text-sm font-medium text-gray-700 mb-1">Thumbnail</label>
                <input type="file" name="thumbnail_path" id="thumbnail_path" accept="image/*" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                <p class="text-xs text-gray-400 mt-1">Gambar preview model. Maks 5MB.</p>
            </div>
            <div>
                <label for="description" class="block text-sm font-medium text-gray-700 mb-1">Deskripsi</label>
                <textarea name="description" id="description" rows="3" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">{{ old('description') }}</textarea>
            </div>
            <div>
                <label for="category" class="block text-sm font-medium text-gray-700 mb-1">Kategori</label>
                <input type="text" name="category" id="category" value="{{ old('category') }}" placeholder="Contoh: Pemrograman, Jaringan..." class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
            </div>
            <div class="flex items-center gap-2">
                <input type="hidden" name="is_active" value="0">
                <input type="checkbox" name="is_active" id="is_active" value="1" {{ old('is_active', '1') == '1' ? 'checked' : '' }} class="h-4 w-4 rounded border-gray-300 text-emerald-600 focus:ring-emerald-500">
                <label for="is_active" class="text-sm text-gray-700">Aktif</label>
            </div>
            <div class="flex items-center gap-3 pt-2">
                <a href="{{ route('admin.ar.models.index') }}" class="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">Batal</a>
                <button type="submit" class="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">Simpan</button>
            </div>
        </form>
    </div>
</div>
@endsection
