@extends('layouts.admin')
@section('title', 'System Settings')
@section('page-title', 'System Settings')

@section('content')
<div class="max-w-3xl">
    <form method="POST" action="{{ route('admin.system.settings.update') }}" x-data="settingsForm()">
        @csrf
        <div class="bg-white rounded-xl border border-gray-200 p-6">
            <div class="flex items-center justify-between mb-5">
                <h2 class="text-sm font-semibold text-gray-900">Application Settings</h2>
                <button type="button" @click="addSetting()" class="inline-flex items-center gap-1 text-xs font-medium text-emerald-600 hover:text-emerald-700">
                    <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
                    Tambah Baris
                </button>
            </div>

            <div class="space-y-4">
                <template x-for="(item, index) in settings" :key="index">
                    <div class="grid grid-cols-12 gap-3 items-start">
                        <div class="col-span-12 sm:col-span-3">
                            <input type="text" :name="'settings[' + index + '][key]'" x-model="item.key" placeholder="Key" required class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                        </div>
                        <div class="col-span-10 sm:col-span-7">
                            <input type="text" :name="'settings[' + index + '][value]'" x-model="item.value" placeholder="Value" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                        </div>
                        <div class="col-span-2 flex items-center gap-2">
                            <button type="button" @click="removeSetting(index)" class="text-red-400 hover:text-red-500 p-1">
                                <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
                            </button>
                        </div>
                        <div class="col-span-12">
                            <input type="text" :name="'settings[' + index + '][description]'" x-model="item.description" placeholder="Deskripsi (opsional)" class="w-full rounded-lg border border-gray-200 px-3 py-1.5 text-xs text-gray-500 focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                        </div>
                    </div>
                </template>
            </div>

            @if($errors->any())
                <div class="mt-4 rounded-md bg-red-50 p-4 text-sm text-red-700 border border-red-200">
                    <ul class="list-disc list-inside">
                        @foreach($errors->all() as $error)
                            <li>{{ $error }}</li>
                        @endforeach
                    </ul>
                </div>
            @endif

            <div class="mt-6 flex justify-end">
                <button type="submit" class="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">Simpan Settings</button>
            </div>
        </div>
    </form>
</div>

@push('scripts')
<script>
function settingsForm() {
    return {
        settings: @json($settings->map(fn($s) => ['key' => $s->key, 'value' => $s->value, 'description' => $s->description])),
        addSetting() {
            this.settings.push({ key: '', value: '', description: '' });
        },
        removeSetting(index) {
            this.settings.splice(index, 1);
        }
    }
}
</script>
@endpush
@endsection
