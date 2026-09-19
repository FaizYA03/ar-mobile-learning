@extends('layouts.admin')
@section('title', 'Tambah Materi')
@section('page-title', 'Tambah Materi')

@section('content')
<div class="max-w-2xl">
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

        <form method="POST" action="{{ route('admin.materi.store') }}" enctype="multipart/form-data" class="space-y-5">
            @csrf
            <div>
                <label for="tp_atp_id" class="block text-sm font-medium text-gray-700 mb-1">TP/ATP</label>
                <select name="tp_atp_id" id="tp_atp_id" required class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                    <option value="">Pilih TP/ATP</option>
                    @foreach($tpAtps as $tp)
                        <option value="{{ $tp->id }}" {{ old('tp_atp_id') == $tp->id ? 'selected' : '' }}>[{{ $tp->kode }}] {{ $tp->judul }}</option>
                    @endforeach
                </select>
            </div>
            <div>
                <label for="judul" class="block text-sm font-medium text-gray-700 mb-1">Judul</label>
                <input type="text" name="judul" id="judul" value="{{ old('judul') }}" required class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
            </div>
            <div>
                <label for="ringkasan" class="block text-sm font-medium text-gray-700 mb-1">Ringkasan</label>
                <textarea name="ringkasan" id="ringkasan" rows="3" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">{{ old('ringkasan') }}</textarea>
            </div>
            <div>
                <label for="konten" class="block text-sm font-medium text-gray-700 mb-1">Konten</label>
                <textarea name="konten" id="konten" rows="10" required class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">{{ old('konten') }}</textarea>
            </div>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
                <div>
                    <label for="estimasi_menit" class="block text-sm font-medium text-gray-700 mb-1">Estimasi (menit)</label>
                    <input type="number" name="estimasi_menit" id="estimasi_menit" value="{{ old('estimasi_menit') }}" min="1" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                </div>
                <div class="flex items-center gap-2 pt-6">
                    <input type="hidden" name="is_published" value="0">
                    <input type="checkbox" name="is_published" id="is_published" value="1" {{ old('is_published', '1') == '1' ? 'checked' : '' }} class="h-4 w-4 rounded border-gray-300 text-emerald-600 focus:ring-emerald-500">
                    <label for="is_published" class="text-sm text-gray-700">Published</label>
                </div>
            </div>
            <div>
                <label for="gambar_cover" class="block text-sm font-medium text-gray-700 mb-1">Gambar Cover</label>
                <input type="file" name="gambar_cover" id="gambar_cover" accept="image/*" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                <p class="text-xs text-gray-400 mt-1">Maks 5MB. Format: jpg, png, webp.</p>
            </div>
            <div class="flex items-center gap-3 pt-2">
                <a href="{{ route('admin.materi.index') }}" class="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">Batal</a>
                <button type="submit" class="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">Simpan</button>
            </div>
        </form>
    </div>
</div>
@endsection
