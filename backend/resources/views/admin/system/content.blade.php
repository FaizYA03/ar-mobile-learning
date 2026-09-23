@extends('layouts.admin')
@section('title', 'Konten Aplikasi')
@section('page-title', 'Konten Aplikasi')

@section('content')
<div class="max-w-3xl">
    @if(session('success'))
        <div class="mb-4 rounded-lg bg-emerald-50 border border-emerald-200 px-4 py-3 text-sm text-emerald-700">{{ session('success') }}</div>
    @endif

    <p class="text-xs text-gray-500 mb-6">Setiap bagian disimpan terpisah. Versi konten UI saat ini: <span class="font-semibold">v{{ $content['ui_content_version'] }}</span></p>

    @if($errors->any())
        <div class="mb-4 rounded-md bg-red-50 p-4 text-sm text-red-700 border border-red-200">
            <ul class="list-disc list-inside">
                @foreach($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <form id="branding" method="POST" action="{{ route('admin.system.content.branding') }}" enctype="multipart/form-data">
        @csrf
        <div class="bg-white rounded-xl border border-gray-200 p-6 mb-6">
            <h2 class="text-sm font-semibold text-gray-900 mb-1">Branding</h2>
            <p class="text-xs text-gray-500 mb-5">Logo & nama tampil di splash screen dan header aplikasi.</p>
            <div class="space-y-4">
                <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Nama Aplikasi</label>
                    <input type="text" name="app_name" value="{{ old('app_name', $content['app_name']) }}" required maxlength="100" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                </div>
                <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Tagline</label>
                    <input type="text" name="app_tagline" value="{{ old('app_tagline', $content['app_tagline']) }}" maxlength="255" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                </div>
                <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Logo Aplikasi (PNG/JPG/WebP, maks 2MB)</label>
                    @if(!empty($content['app_logo']))
                        <div class="flex items-center gap-3 mb-2">
                            <img src="{{ asset('storage/' . $content['app_logo']) }}" alt="Logo" class="h-12 w-12 rounded-lg object-contain bg-gray-50 border border-gray-200">
                            <label class="text-xs text-gray-600 flex items-center gap-1">
                                <input type="checkbox" name="remove_logo" value="1" class="rounded"> Hapus logo (kembali ke icon bawaan)
                            </label>
                        </div>
                    @endif
                    <input type="file" name="app_logo" accept=".png,.jpg,.jpeg,.webp" class="w-full text-sm text-gray-600">
                </div>
            </div>
            <div class="mt-5 flex justify-end">
                <button type="submit" class="rounded-lg bg-emerald-600 px-5 py-2 text-sm font-medium text-white hover:bg-emerald-700">Simpan Branding</button>
            </div>
        </div>
    </form>

    <form id="splash" method="POST" action="{{ route('admin.system.content.splash') }}">
        @csrf
        <div class="bg-white rounded-xl border border-gray-200 p-6 mb-6">
            <h2 class="text-sm font-semibold text-gray-900 mb-5">Splash Screen</h2>
            <div class="space-y-4">
                <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Judul</label>
                    <input type="text" name="splash_title" value="{{ old('splash_title', $content['splash_title']) }}" required maxlength="100" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                </div>
                <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Subjudul</label>
                    <input type="text" name="splash_subtitle" value="{{ old('splash_subtitle', $content['splash_subtitle']) }}" maxlength="255" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                </div>
            </div>
            <div class="mt-5 flex justify-end">
                <button type="submit" class="rounded-lg bg-emerald-600 px-5 py-2 text-sm font-medium text-white hover:bg-emerald-700">Simpan Splash</button>
            </div>
        </div>
    </form>

    <form id="greetings" method="POST" action="{{ route('admin.system.content.greetings') }}">
        @csrf
        <div class="bg-white rounded-xl border border-gray-200 p-6 mb-6">
            <h2 class="text-sm font-semibold text-gray-900 mb-1">Sapaan Dashboard</h2>
            <p class="text-xs text-gray-500 mb-5">Subjudul di bawah "Halo, Nama" tiap role.</p>
            <div class="space-y-4">
                <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Siswa</label>
                    <input type="text" name="greeting_siswa" value="{{ old('greeting_siswa', $content['greeting_siswa']) }}" maxlength="255" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                </div>
                <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Guru</label>
                    <input type="text" name="greeting_guru" value="{{ old('greeting_guru', $content['greeting_guru']) }}" maxlength="255" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                </div>
                <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Admin</label>
                    <input type="text" name="greeting_admin" value="{{ old('greeting_admin', $content['greeting_admin']) }}" maxlength="255" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                </div>
            </div>
            <div class="mt-5 flex justify-end">
                <button type="submit" class="rounded-lg bg-emerald-600 px-5 py-2 text-sm font-medium text-white hover:bg-emerald-700">Simpan Sapaan</button>
            </div>
        </div>
    </form>

    <form id="announcement" method="POST" action="{{ route('admin.system.content.announcement') }}">
        @csrf
        <div class="bg-white rounded-xl border border-gray-200 p-6 mb-6">
            <h2 class="text-sm font-semibold text-gray-900 mb-1">Pengumuman</h2>
            <p class="text-xs text-gray-500 mb-5">Banner di Home aplikasi. Kosongkan teks atau matikan untuk menyembunyikan.</p>
            <div class="space-y-4">
                <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Teks pengumuman</label>
                    <textarea name="announcement_text" rows="2" maxlength="1000" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">{{ old('announcement_text', $content['announcement_text']) }}</textarea>
                </div>
                <label class="text-sm text-gray-700 flex items-center gap-2">
                    <input type="checkbox" name="announcement_active" value="1" {{ old('announcement_active', $content['announcement_active']) ? 'checked' : '' }} class="rounded">
                    Tampilkan banner
                </label>
            </div>
            <div class="mt-5 flex justify-end">
                <button type="submit" class="rounded-lg bg-emerald-600 px-5 py-2 text-sm font-medium text-white hover:bg-emerald-700">Simpan Pengumuman</button>
            </div>
        </div>
    </form>

    <form id="help" method="POST" action="{{ route('admin.system.content.help') }}">
        @csrf
        <div class="bg-white rounded-xl border border-gray-200 p-6 mb-6">
            <h2 class="text-sm font-semibold text-gray-900 mb-1">Bantuan & Tentang</h2>
            <p class="text-xs text-gray-500 mb-5">Isi halaman Bantuan dan Tentang di aplikasi. Baris baru = paragraf baru.</p>
            <div class="space-y-4">
                <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Isi Bantuan</label>
                    <textarea name="help_content" rows="6" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">{{ old('help_content', $content['help_content']) }}</textarea>
                </div>
                <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Isi Tentang</label>
                    <textarea name="about_content" rows="4" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">{{ old('about_content', $content['about_content']) }}</textarea>
                </div>
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-medium text-gray-700 mb-1">Email bantuan</label>
                        <input type="email" name="contact_email" value="{{ old('contact_email', $content['contact_email']) }}" maxlength="255" placeholder="cs@sekolah.id" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                    </div>
                    <div>
                        <label class="block text-xs font-medium text-gray-700 mb-1">WhatsApp (format 628xx)</label>
                        <input type="text" name="contact_wa" value="{{ old('contact_wa', $content['contact_wa']) }}" maxlength="20" placeholder="6281234567890" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                    </div>
                </div>
            </div>
            <div class="mt-5 flex justify-end">
                <button type="submit" class="rounded-lg bg-emerald-600 px-5 py-2 text-sm font-medium text-white hover:bg-emerald-700">Simpan Bantuan</button>
            </div>
        </div>
    </form>

    <form id="onboarding" method="POST" action="{{ route('admin.system.content.onboarding') }}">
        @csrf
        <div class="bg-white rounded-xl border border-gray-200 p-6 mb-8">
            <h2 class="text-sm font-semibold text-gray-900 mb-1">Slide Onboarding</h2>
            <p class="text-xs text-gray-500 mb-5">Maksimal 5 slide. Gunakan baris baru untuk judul dua baris.</p>
            <div class="space-y-4">
                @php $slides = old('slides', $content['onboarding_slides'] ?? []); @endphp
                @for($i = 0; $i < 5; $i++)
                    <div class="rounded-lg border border-gray-200 p-4">
                        <div class="text-xs font-semibold text-gray-500 mb-2">Slide {{ $i + 1 }}</div>
                        <input type="text" name="slides[{{ $i }}][title]" value="{{ $slides[$i]['title'] ?? '' }}" placeholder="Judul slide" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm mb-2 focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                        <textarea name="slides[{{ $i }}][description]" rows="2" placeholder="Deskripsi slide" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">{{ $slides[$i]['description'] ?? '' }}</textarea>
                    </div>
                @endfor
            </div>
            <div class="mt-5 flex justify-end">
                <button type="submit" class="rounded-lg bg-emerald-600 px-5 py-2 text-sm font-medium text-white hover:bg-emerald-700">Simpan Onboarding</button>
            </div>
        </div>
    </form>
</div>
@endsection
