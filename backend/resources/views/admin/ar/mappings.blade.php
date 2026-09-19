@extends('layouts.admin')
@section('title', 'Marker-Model Mappings')
@section('page-title', 'Marker-Model Mappings')

@section('content')
<div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
    <form method="GET" action="{{ route('admin.ar.mappings.index') }}" class="flex gap-2 w-full sm:w-auto">
        <input type="text" name="search" value="{{ request('search') }}" placeholder="Cari marker atau model..." class="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 w-full sm:w-64">
        <button type="submit" class="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">Filter</button>
    </form>
    <a href="{{ route('admin.ar.mappings.create') }}" class="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">
        <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
        Tambah Mapping
    </a>
</div>

<div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
    <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
                <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">#</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Marker</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Model</th>
                    <th class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">Metode</th>
                    <th class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                    <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Aksi</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
                @forelse($mappings as $mapping)
                    <tr class="hover:bg-gray-50">
                        <td class="px-6 py-4 text-sm text-gray-500">{{ $mappings->firstItem() + $loop->index }}</td>
                        <td class="px-6 py-4 text-sm font-medium text-gray-900">{{ $mapping->arMarker->marker_id ?? '-' }}</td>
                        <td class="px-6 py-4 text-sm text-gray-600">{{ $mapping->arModel->model_name ?? '-' }}</td>
                        <td class="px-6 py-4 text-center">
                            @php
                                $methodColors = [
                                    'image_tracking' => 'bg-blue-100 text-blue-700',
                                    'marker_id' => 'bg-amber-100 text-amber-700',
                                ];
                            @endphp
                            <span class="inline-flex rounded-full px-2 py-1 text-xs font-medium {{ $methodColors[$mapping->mapping_method] ?? 'bg-gray-100 text-gray-700' }}">{{ $mapping->mapping_method }}</span>
                        </td>
                        <td class="px-6 py-4 text-center">
                            @php
                                $statusColors = [
                                    'mapped' => 'bg-emerald-100 text-emerald-700',
                                    'pending' => 'bg-yellow-100 text-yellow-700',
                                    'failed' => 'bg-red-100 text-red-700',
                                ];
                            @endphp
                            <span class="inline-flex rounded-full px-2 py-1 text-xs font-medium {{ $statusColors[$mapping->mapping_status] ?? 'bg-gray-100 text-gray-700' }}">{{ $mapping->mapping_status }}</span>
                        </td>
                        <td class="px-6 py-4 text-right">
                            <div class="flex items-center justify-end gap-2">
                                <a href="{{ route('admin.ar.mappings.edit', $mapping) }}" class="text-emerald-600 hover:text-emerald-700 text-sm font-medium">Edit</a>
                                <form method="POST" action="{{ route('admin.ar.mappings.destroy', $mapping) }}" onsubmit="return confirm('Yakin ingin menghapus mapping ini?')">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="text-red-500 hover:text-red-600 text-sm font-medium">Hapus</button>
                                </form>
                            </div>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="6" class="px-6 py-12 text-center text-sm text-gray-400">Tidak ada data mapping.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
    <div class="border-t border-gray-100 px-6 py-3">
        {{ $mappings->links() }}
    </div>
</div>
@endsection
