@extends('layouts.admin')
@section('title', 'Materi')
@section('page-title', 'Materi')

@section('content')
<div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
    <form method="GET" action="{{ route('admin.materi.index') }}" class="flex flex-col sm:flex-row gap-3 w-full sm:w-auto">
        <div class="flex gap-2 flex-wrap">
            <input type="text" name="search" value="{{ request('search') }}" placeholder="Cari judul atau ringkasan..." class="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 w-full sm:w-64">
            <select name="tp_atp_id" class="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                <option value="">Semua TP/ATP</option>
                @foreach($tpAtps as $tp)
                    <option value="{{ $tp->id }}" {{ request('tp_atp_id') == $tp->id ? 'selected' : '' }}>[{{ $tp->kode }}] {{ $tp->judul }}</option>
                @endforeach
            </select>
            <button type="submit" class="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">Filter</button>
        </div>
    </form>
    <a href="{{ route('admin.materi.create') }}" class="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">
        <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
        Tambah Materi
    </a>
</div>

<div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
    <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
                <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">#</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Judul</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">TP/ATP</th>
                    <th class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">Estimasi</th>
                    <th class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                    <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Aksi</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
                @forelse($materi as $m)
                    <tr class="hover:bg-gray-50">
                        <td class="px-6 py-4 text-sm text-gray-500">{{ $materi->firstItem() + $loop->index }}</td>
                        <td class="px-6 py-4">
                            <div class="text-sm font-medium text-gray-900 max-w-xs truncate">{{ $m->judul }}</div>
                            @if($m->ringkasan)
                                <div class="text-xs text-gray-400 max-w-xs truncate mt-0.5">{{ $m->ringkasan }}</div>
                            @endif
                        </td>
                        <td class="px-6 py-4 text-sm text-gray-600">
                            @if($m->tpAtp)
                                <span class="text-xs">[{{ $m->tpAtp->kode }}] {{ $m->tpAtp->judul }}</span>
                            @else
                                <span class="text-xs text-gray-400">-</span>
                            @endif
                        </td>
                        <td class="px-6 py-4 text-sm text-center text-gray-600">{{ $m->estimasi_menit ?? '-' }} menit</td>
                        <td class="px-6 py-4 text-center">
                            @if($m->is_published)
                                <span class="inline-flex rounded-full px-2 py-1 text-xs font-medium bg-emerald-100 text-emerald-700">Published</span>
                            @else
                                <span class="inline-flex rounded-full px-2 py-1 text-xs font-medium bg-yellow-100 text-yellow-700">Draft</span>
                            @endif
                        </td>
                        <td class="px-6 py-4 text-right">
                            <div class="flex items-center justify-end gap-2">
                                <a href="{{ route('admin.materi.edit', $m) }}" class="text-emerald-600 hover:text-emerald-700 text-sm font-medium">Edit</a>
                                <form method="POST" action="{{ route('admin.materi.destroy', $m) }}" onsubmit="deleteConfirm.openForm(event, { title: 'Hapus Materi', message: 'Yakin ingin menghapus materi ini?' })">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="text-red-500 hover:text-red-600 text-sm font-medium">Hapus</button>
                                </form>
                            </div>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="6" class="px-6 py-12 text-center text-sm text-gray-400">Tidak ada data materi.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
    <div class="border-t border-gray-100 px-6 py-3">
        {{ $materi->links() }}
    </div>
</div>
@endsection
