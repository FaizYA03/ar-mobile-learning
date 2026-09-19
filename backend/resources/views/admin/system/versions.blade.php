@extends('layouts.admin')
@section('title', 'App Versions')
@section('page-title', 'App Versions')

@section('content')
<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
    <div class="lg:col-span-2">
        <div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
            <div class="px-5 py-4 border-b border-gray-100">
                <h2 class="text-sm font-semibold text-gray-900">Daftar Versi</h2>
            </div>
            <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                        <tr>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Platform</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Versi</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Build</th>
                            <th class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Aksi</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100">
                        @forelse($versions as $version)
                            <tr class="hover:bg-gray-50" x-data="{ editing: false }">
                                <td class="px-6 py-4">
                                    @if($version->platform === 'android')
                                        <span class="inline-flex rounded-full px-2 py-1 text-xs font-medium bg-green-100 text-green-700">Android</span>
                                    @else
                                        <span class="inline-flex rounded-full px-2 py-1 text-xs font-medium bg-blue-100 text-blue-700">iOS</span>
                                    @endif
                                </td>
                                <td class="px-6 py-4 text-sm font-medium text-gray-900">{{ $version->version }}</td>
                                <td class="px-6 py-4 text-sm text-gray-600">{{ $version->build_number ?? '-' }}</td>
                                <td class="px-6 py-4 text-center">
                                    @if($version->is_active)
                                        <span class="inline-flex rounded-full px-2 py-1 text-xs font-medium bg-emerald-100 text-emerald-700">Aktif</span>
                                    @else
                                        <span class="inline-flex rounded-full px-2 py-1 text-xs font-medium bg-gray-100 text-gray-500">Nonaktif</span>
                                    @endif
                                </td>
                                <td class="px-6 py-4 text-right">
                                    <div class="flex items-center justify-end gap-2">
                                        <button @click="editing = !editing" class="text-blue-600 hover:text-blue-700 text-sm font-medium">Edit</button>
                                        <form method="POST" action="{{ route('admin.system.versions.destroy', $version) }}" onsubmit="return confirm('Yakin ingin menghapus versi ini?')">
                                            @csrf
                                            @method('DELETE')
                                            <button type="submit" class="text-red-500 hover:text-red-600 text-sm font-medium">Hapus</button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                            <tr x-show="editing" x-cloak>
                                <td colspan="5" class="px-6 py-4 bg-gray-50">
                                    <form method="POST" action="{{ route('admin.system.versions.update', $version) }}" class="space-y-3">
                                        @csrf
                                        @method('PUT')
                                        <div class="grid grid-cols-2 gap-3">
                                            <div>
                                                <label class="block text-xs font-medium text-gray-600 mb-1">Platform</label>
                                                <select name="platform" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                                                    <option value="android" {{ $version->platform === 'android' ? 'selected' : '' }}>Android</option>
                                                    <option value="ios" {{ $version->platform === 'ios' ? 'selected' : '' }}>iOS</option>
                                                </select>
                                            </div>
                                            <div>
                                                <label class="block text-xs font-medium text-gray-600 mb-1">Versi</label>
                                                <input type="text" name="version" value="{{ $version->version }}" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                                            </div>
                                            <div>
                                                <label class="block text-xs font-medium text-gray-600 mb-1">Build Number</label>
                                                <input type="text" name="build_number" value="{{ $version->build_number }}" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                                            </div>
                                            <div>
                                                <label class="block text-xs font-medium text-gray-600 mb-1">Min Supported Version</label>
                                                <input type="text" name="minimum_supported_version" value="{{ $version->minimum_supported_version }}" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                                            </div>
                                        </div>
                                        <div>
                                            <label class="block text-xs font-medium text-gray-600 mb-1">Release Notes</label>
                                            <textarea name="release_notes" rows="2" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">{{ $version->release_notes }}</textarea>
                                        </div>
                                        <div>
                                            <label class="block text-xs font-medium text-gray-600 mb-1">Download URL</label>
                                            <input type="url" name="download_url" value="{{ $version->download_url }}" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                                        </div>
                                        <div class="flex items-center gap-2">
                                            <input type="hidden" name="is_active" value="0">
                                            <input type="checkbox" name="is_active" value="1" {{ $version->is_active ? 'checked' : '' }} class="h-4 w-4 rounded border-gray-300 text-emerald-600 focus:ring-emerald-500">
                                            <label class="text-sm text-gray-700">Aktif</label>
                                        </div>
                                        <div class="flex justify-end">
                                            <button type="submit" class="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">Update</button>
                                        </div>
                                    </form>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="5" class="px-6 py-12 text-center text-sm text-gray-400">Belum ada versi.</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <div class="lg:col-span-1">
        <div class="bg-white rounded-xl border border-gray-200 p-5">
            <h3 class="text-sm font-semibold text-gray-900 mb-4">Tambah Versi</h3>
            @if($errors->any())
                <div class="mb-4 rounded-md bg-red-50 p-3 text-xs text-red-700 border border-red-200">
                    <ul class="list-disc list-inside">
                        @foreach($errors->all() as $error)
                            <li>{{ $error }}</li>
                        @endforeach
                    </ul>
                </div>
            @endif
            <form method="POST" action="{{ route('admin.system.versions.store') }}" class="space-y-3">
                @csrf
                <div>
                    <label class="block text-xs font-medium text-gray-600 mb-1">Platform</label>
                    <select name="platform" required class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                        <option value="android">Android</option>
                        <option value="ios">iOS</option>
                    </select>
                </div>
                <div>
                    <label class="block text-xs font-medium text-gray-600 mb-1">Versi</label>
                    <input type="text" name="version" required placeholder="1.0.0" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                </div>
                <div>
                    <label class="block text-xs font-medium text-gray-600 mb-1">Build Number</label>
                    <input type="text" name="build_number" placeholder="1" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                </div>
                <div>
                    <label class="block text-xs font-medium text-gray-600 mb-1">Min Supported Version</label>
                    <input type="text" name="minimum_supported_version" placeholder="1.0.0" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                </div>
                <div>
                    <label class="block text-xs font-medium text-gray-600 mb-1">Release Notes</label>
                    <textarea name="release_notes" rows="3" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"></textarea>
                </div>
                <div>
                    <label class="block text-xs font-medium text-gray-600 mb-1">Download URL</label>
                    <input type="url" name="download_url" placeholder="https://..." class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                </div>
                <div class="flex items-center gap-2">
                    <input type="hidden" name="is_active" value="0">
                    <input type="checkbox" name="is_active" value="1" checked class="h-4 w-4 rounded border-gray-300 text-emerald-600 focus:ring-emerald-500">
                    <label class="text-sm text-gray-700">Aktif</label>
                </div>
                <button type="submit" class="w-full rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">Simpan Versi</button>
            </form>
        </div>
    </div>
</div>
@endsection
