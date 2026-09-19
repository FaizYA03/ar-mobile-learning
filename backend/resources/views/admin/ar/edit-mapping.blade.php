@extends('layouts.admin')
@section('title', 'Edit Mapping')
@section('page-title', 'Edit Mapping')

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

        <form method="POST" action="{{ route('admin.ar.mappings.update', $mapping) }}" class="space-y-5">
            @csrf
            @method('PUT')
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Marker</label>
                <div class="rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-sm text-gray-700">
                    {{ $mapping->arMarker->marker_id ?? '-' }} ({{ $mapping->arMarker->marker_type ?? '-' }})
                </div>
                <p class="text-xs text-gray-400 mt-1">Marker tidak dapat diubah setelah dibuat.</p>
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">3D Model</label>
                <div class="rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-sm text-gray-700">
                    {{ $mapping->arModel->model_name ?? '-' }}
                </div>
                <p class="text-xs text-gray-400 mt-1">Model tidak dapat diubah setelah dibuat.</p>
            </div>
            <div>
                <label for="mapping_method" class="block text-sm font-medium text-gray-700 mb-1">Metode Mapping</label>
                <select name="mapping_method" id="mapping_method" required class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                    <option value="image_tracking" {{ old('mapping_method', $mapping->mapping_method) === 'image_tracking' ? 'selected' : '' }}>Image Tracking</option>
                    <option value="marker_id" {{ old('mapping_method', $mapping->mapping_method) === 'marker_id' ? 'selected' : '' }}>Marker ID</option>
                </select>
            </div>
            <div>
                <label for="mapping_status" class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                <select name="mapping_status" id="mapping_status" required class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                    <option value="pending" {{ old('mapping_status', $mapping->mapping_status) === 'pending' ? 'selected' : '' }}>Pending</option>
                    <option value="mapped" {{ old('mapping_status', $mapping->mapping_status) === 'mapped' ? 'selected' : '' }}>Mapped</option>
                    <option value="failed" {{ old('mapping_status', $mapping->mapping_status) === 'failed' ? 'selected' : '' }}>Failed</option>
                </select>
            </div>
            <div>
                <label for="mapping_notes" class="block text-sm font-medium text-gray-700 mb-1">Catatan</label>
                <textarea name="mapping_notes" id="mapping_notes" rows="3" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">{{ old('mapping_notes', $mapping->mapping_notes) }}</textarea>
            </div>
            <div class="flex items-center gap-3 pt-2">
                <a href="{{ route('admin.ar.mappings.index') }}" class="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">Batal</a>
                <button type="submit" class="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">Perbarui</button>
            </div>
        </form>
    </div>
</div>
@endsection
