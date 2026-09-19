@extends('layouts.admin')
@section('title', 'AR Hotspots')
@section('page-title', 'AR Hotspots')

@section('content')
<div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
    <form method="GET" action="{{ route('admin.ar.hotspots.index') }}" class="flex gap-2 w-full sm:w-auto">
        <input type="text" name="search" value="{{ request('search') }}" placeholder="Cari judul hotspot..." class="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 w-full sm:w-64">
        <button type="submit" class="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">Filter</button>
    </form>
    <a href="{{ route('admin.ar.hotspots.create') }}" class="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">
        <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
        Tambah Hotspot
    </a>
</div>

<div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
    <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
                <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">#</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Judul</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Model</th>
                    <th class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">Koordinat</th>
                    <th class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                    <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Aksi</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
                @forelse($hotspots as $hotspot)
                    <tr class="hover:bg-gray-50">
                        <td class="px-6 py-4 text-sm text-gray-500">{{ $hotspots->firstItem() + $loop->index }}</td>
                        <td class="px-6 py-4 text-sm font-medium text-gray-900">{{ $hotspot->title }}</td>
                        <td class="px-6 py-4 text-sm text-gray-600">{{ $hotspot->arModel->model_name ?? '-' }}</td>
                        <td class="px-6 py-4 text-sm text-center text-gray-500">
                            @if($hotspot->latitude && $hotspot->longitude)
                                <span class="text-xs">{{ number_format($hotspot->latitude, 4) }}, {{ number_format($hotspot->longitude, 4) }}</span>
                            @else
                                <span class="text-xs text-gray-400">-</span>
                            @endif
                        </td>
                        <td class="px-6 py-4 text-center">
                            @if($hotspot->is_active)
                                <span class="inline-flex rounded-full px-2 py-1 text-xs font-medium bg-emerald-100 text-emerald-700">Aktif</span>
                            @else
                                <span class="inline-flex rounded-full px-2 py-1 text-xs font-medium bg-gray-100 text-gray-500">Nonaktif</span>
                            @endif
                        </td>
                        <td class="px-6 py-4 text-right">
                            <div class="flex items-center justify-end gap-2">
                                <a href="{{ route('admin.ar.hotspots.edit', $hotspot) }}" class="text-emerald-600 hover:text-emerald-700 text-sm font-medium">Edit</a>
                                <form method="POST" action="{{ route('admin.ar.hotspots.destroy', $hotspot) }}" onsubmit="return confirm('Yakin ingin menghapus hotspot ini?')">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="text-red-500 hover:text-red-600 text-sm font-medium">Hapus</button>
                                </form>
                            </div>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="6" class="px-6 py-12 text-center text-sm text-gray-400">Tidak ada data hotspot.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
    <div class="border-t border-gray-100 px-6 py-3">
        {{ $hotspots->links() }}
    </div>
</div>
@endsection
