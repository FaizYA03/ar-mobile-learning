@extends('layouts.admin')
@section('title', 'Edit TP/ATP')
@section('page-title', 'Edit TP/ATP')

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

        <form method="POST" action="{{ route('admin.tp-atp.update', $tpAtp) }}" class="space-y-5">
            @csrf
            @method('PUT')
            <div>
                <label for="kode" class="block text-sm font-medium text-gray-700 mb-1">Kode</label>
                <input type="text" name="kode" id="kode" value="{{ old('kode', $tpAtp->kode) }}" required class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
            </div>
            <div>
                <label for="fase" class="block text-sm font-medium text-gray-700 mb-1">Fase</label>
                <input type="text" name="fase" id="fase" value="{{ old('fase', $tpAtp->fase) }}" required class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
            </div>
            <div>
                <label for="elemen" class="block text-sm font-medium text-gray-700 mb-1">Elemen</label>
                <input type="text" name="elemen" id="elemen" value="{{ old('elemen', $tpAtp->elemen) }}" required class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
            </div>
            <div>
                <label for="judul" class="block text-sm font-medium text-gray-700 mb-1">Judul</label>
                <input type="text" name="judul" id="judul" value="{{ old('judul', $tpAtp->judul) }}" required class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
            </div>
            <div>
                <label for="deskripsi" class="block text-sm font-medium text-gray-700 mb-1">Deskripsi</label>
                <textarea name="deskripsi" id="deskripsi" rows="4" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">{{ old('deskripsi', $tpAtp->deskripsi) }}</textarea>
            </div>
            <div>
                <label for="order" class="block text-sm font-medium text-gray-700 mb-1">Urutan</label>
                <input type="number" name="order" id="order" value="{{ old('order', $tpAtp->order) }}" min="1" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
            </div>
            <div class="flex items-center gap-2">
                <input type="hidden" name="is_active" value="0">
                <input type="checkbox" name="is_active" id="is_active" value="1" {{ old('is_active', $tpAtp->is_active) ? 'checked' : '' }} class="h-4 w-4 rounded border-gray-300 text-emerald-600 focus:ring-emerald-500">
                <label for="is_active" class="text-sm text-gray-700">Aktif</label>
            </div>
            <div class="flex items-center gap-3 pt-2">
                <a href="{{ route('admin.tp-atp.index') }}" class="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">Batal</a>
                <button type="submit" class="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">Perbarui</button>
            </div>
        </form>
    </div>
</div>
@endsection
