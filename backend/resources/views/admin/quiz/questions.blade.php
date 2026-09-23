@extends('layouts.admin')
@section('title', 'Kelola Soal - ' . $quiz->title)
@section('page-title', 'Soal: ' . $quiz->title)

@section('content')
<div class="mb-6">
    <a href="{{ route('admin.quiz.index') }}" class="text-sm text-emerald-600 hover:text-emerald-700 font-medium">&larr; Kembali ke Quiz</a>
</div>

<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
    <div class="lg:col-span-2">
        <div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
            <div class="px-5 py-4 border-b border-gray-100">
                <h2 class="text-sm font-semibold text-gray-900">Daftar Soal ({{ $quiz->questions->count() }})</h2>
            </div>
            <div class="divide-y divide-gray-100">
                @forelse($quiz->questions->sortBy('order') as $question)
                    <div class="px-5 py-4">
                        <div class="flex items-start justify-between gap-3">
                            <div class="min-w-0 flex-1">
                                <div class="flex items-center gap-2 mb-2">
                                    <span class="inline-flex h-6 w-6 items-center justify-center rounded-full bg-gray-100 text-xs font-medium text-gray-600">{{ $question->order }}</span>
                                    <span class="text-sm font-medium text-gray-900">{{ $question->text }}</span>
                                </div>
                                <div class="ml-8 space-y-1">
                                    @foreach($question->options->sortBy('order') as $option)
                                        <div class="flex items-center gap-2 text-sm">
                                            @if($option->is_correct)
                                                <span class="inline-flex h-4 w-4 items-center justify-center rounded-full bg-emerald-100 text-emerald-600">
                                                    <svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" /></svg>
                                                </span>
                                            @else
                                                <span class="inline-flex h-4 w-4 items-center justify-center rounded-full bg-gray-100 text-gray-400">
                                                    <span class="h-1.5 w-1.5 rounded-full bg-gray-300"></span>
                                                </span>
                                            @endif
                                            <span class="{{ $option->is_correct ? 'text-emerald-700 font-medium' : 'text-gray-600' }}">{{ $option->text }}</span>
                                        </div>
                                    @endforeach
                                </div>
                            </div>
                            <form method="POST" action="{{ route('admin.quiz.delete-question', $question) }}" onsubmit="deleteConfirm.openForm(event, { title: 'Hapus Soal', message: 'Yakin ingin menghapus soal ini?' })">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="text-red-500 hover:text-red-600 text-xs font-medium shrink-0">Hapus</button>
                            </form>
                        </div>
                    </div>
                @empty
                    <div class="px-5 py-12 text-center text-sm text-gray-400">Belum ada soal.</div>
                @endforelse
            </div>
        </div>
    </div>

    <div class="lg:col-span-1">
        <div class="bg-white rounded-xl border border-gray-200 p-5">
            <h3 class="text-sm font-semibold text-gray-900 mb-4">Tambah Soal</h3>
            @if($errors->any())
                <div class="mb-4 rounded-md bg-red-50 p-3 text-xs text-red-700 border border-red-200">
                    <ul class="list-disc list-inside">
                        @foreach($errors->all() as $error)
                            <li>{{ $error }}</li>
                        @endforeach
                    </ul>
                </div>
            @endif
            <form method="POST" action="{{ route('admin.quiz.store-question', $quiz) }}" class="space-y-4" x-data="questionForm()">
                @csrf
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Pertanyaan</label>
                    <textarea name="text" x-model="text" rows="3" required class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"></textarea>
                </div>
                <div>
                    <div class="flex items-center justify-between mb-2">
                        <label class="block text-sm font-medium text-gray-700">Pilihan Jawaban</label>
                        <button type="button" @click="addOption()" class="text-xs text-emerald-600 hover:text-emerald-700 font-medium">+ Tambah</button>
                    </div>
                    <template x-for="(option, index) in options" :key="index">
                        <div class="flex items-center gap-2 mb-2">
                            <input type="checkbox" :name="'options[' + index + '][is_correct]'" :value="1" x-model="option.is_correct" class="h-4 w-4 rounded border-gray-300 text-emerald-600 focus:ring-emerald-500" title="Benar?">
                            <input type="text" :name="'options[' + index + '][text]'" x-model="option.text" required placeholder="Pilihan jawaban..." class="flex-1 rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
                            <button type="button" @click="removeOption(index)" x-show="options.length > 2" class="text-red-400 hover:text-red-500">
                                <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
                            </button>
                        </div>
                    </template>
                    <p class="text-xs text-gray-400 mt-1">Centang checkbox untuk menandai jawaban benar.</p>
                </div>
                <button type="submit" class="w-full rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">Simpan Soal</button>
            </form>
        </div>
    </div>
</div>

@push('scripts')
<script>
function questionForm() {
    return {
        text: '',
        options: [
            { text: '', is_correct: false },
            { text: '', is_correct: false },
        ],
        addOption() {
            this.options.push({ text: '', is_correct: false });
        },
        removeOption(index) {
            this.options.splice(index, 1);
        }
    }
}
</script>
@endpush
@endsection
