@extends('layouts.admin')
@section('title', 'TP / ATP')
@section('page-title', 'TP / ATP')

@section('content')
<div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
    <form method="GET" action="{{ route('admin.tp-atp.index') }}" class="flex flex-col sm:flex-row gap-3 w-full sm:w-auto">
        <div class="flex gap-2">
            <input type="text" name="search" value="{{ request('search') }}" placeholder="Cari kode, judul, elemen..." class="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 w-full sm:w-64">
            <select name="fase" class="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                <option value="">Semua Fase</option>
                @foreach(['A','B','C','D','E','F'] as $f)
                    <option value="{{ $f }}" {{ request('fase') === $f ? 'selected' : '' }}>Fase {{ $f }}</option>
                @endforeach
            </select>
            <button type="submit" class="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">Filter</button>
        </div>
    </form>
    <a href="{{ route('admin.tp-atp.create') }}" class="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">
        <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
        Tambah TP/ATP
    </a>
</div>

<div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
    <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
                <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">#</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Kode</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Fase</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Elemen</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Judul</th>
                    <th class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">Materi</th>
                    <th class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                    <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Aksi</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
                @forelse($tpAtps as $tp)
                    <tr class="hover:bg-gray-50">
                        <td class="px-6 py-4 text-sm text-gray-500">{{ $tpAtps->firstItem() + $loop->index }}</td>
                        <td class="px-6 py-4 text-sm font-medium text-gray-900">{{ $tp->kode }}</td>
                        <td class="px-6 py-4 text-sm text-gray-600">{{ $tp->fase }}</td>
                        <td class="px-6 py-4 text-sm text-gray-600">{{ $tp->elemen }}</td>
                        <td class="px-6 py-4 text-sm text-gray-900 max-w-xs truncate">{{ $tp->judul }}</td>
                        <td class="px-6 py-4 text-sm text-center text-gray-600">{{ $tp->materi_count }}</td>
                        <td class="px-6 py-4 text-center">
                            @if($tp->is_active)
                                <span class="inline-flex rounded-full px-2 py-1 text-xs font-medium bg-emerald-100 text-emerald-700">Aktif</span>
                            @else
                                <span class="inline-flex rounded-full px-2 py-1 text-xs font-medium bg-gray-100 text-gray-500">Nonaktif</span>
                            @endif
                        </td>
                        <td class="px-6 py-4 text-right">
                            <div class="flex items-center justify-end gap-2">
                                <a href="{{ route('admin.tp-atp.edit', $tp) }}" class="text-emerald-600 hover:text-emerald-700 text-sm font-medium">Edit</a>
                                <form method="POST" action="{{ route('admin.tp-atp.destroy', $tp) }}" onsubmit="deleteConfirm.openForm(event, { title: 'Hapus TP/ATP', message: 'Yakin ingin menghapus TP/ATP ini?' })">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="text-red-500 hover:text-red-600 text-sm font-medium">Hapus</button>
                                </form>
                            </div>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="8" class="px-6 py-12 text-center text-sm text-gray-400">Tidak ada data TP/ATP.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
    <div class="border-t border-gray-100 px-6 py-3">
        {{ $tpAtps->links() }}
    </div>
</div>
@endsection
