@extends('layouts.admin')
@section('title', 'Hasil Quiz')
@section('page-title', 'Hasil Quiz Siswa')

@section('content')
<div class="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-6">
    <div class="bg-white rounded-xl border border-gray-200 p-4">
        <div class="text-2xl font-bold text-gray-900">{{ $total }}</div>
        <div class="text-xs text-gray-500 mt-1">Total Pengerjaan</div>
    </div>
    <div class="bg-white rounded-xl border border-gray-200 p-4">
        <div class="text-2xl font-bold text-emerald-600">{{ $passed }}</div>
        <div class="text-xs text-gray-500 mt-1">Lulus</div>
    </div>
    <div class="bg-white rounded-xl border border-gray-200 p-4">
        <div class="text-2xl font-bold text-red-600">{{ $total - $passed }}</div>
        <div class="text-xs text-gray-500 mt-1">Tidak Lulus</div>
    </div>
    <div class="bg-white rounded-xl border border-gray-200 p-4">
        <div class="text-2xl font-bold text-amber-600">{{ $avgScore }}</div>
        <div class="text-xs text-gray-500 mt-1">Rata-rata Skor</div>
    </div>
</div>

<div class="mb-6">
    <form method="GET" action="{{ route('admin.quiz-attempts.index') }}" class="flex flex-col sm:flex-row gap-3">
        <select name="quiz_id" class="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
            <option value="">Semua Quiz</option>
            @foreach($quizzes as $quiz)
                <option value="{{ $quiz->id }}" {{ (string) request('quiz_id') === (string) $quiz->id ? 'selected' : '' }}>{{ $quiz->title }}</option>
            @endforeach
        </select>
        <input type="text" name="search" value="{{ request('search') }}" placeholder="Cari nama/email siswa..." class="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 w-full sm:w-64">
        <button type="submit" class="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">Filter</button>
    </form>
</div>

<div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
    <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
                <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Waktu</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Siswa</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Quiz</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Skor</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
                @forelse($attempts as $attempt)
                    <tr class="hover:bg-gray-50">
                        <td class="px-6 py-4 text-xs text-gray-500 whitespace-nowrap">{{ $attempt->created_at->format('d M Y H:i') }}</td>
                        <td class="px-6 py-4 text-sm text-gray-700">
                            {{ $attempt->user->name ?? '-' }}
                            <div class="text-xs text-gray-400">{{ $attempt->user->email ?? '' }}</div>
                        </td>
                        <td class="px-6 py-4 text-sm text-gray-600">{{ $attempt->quiz->title ?? '-' }}</td>
                        <td class="px-6 py-4 text-sm font-bold {{ $attempt->passed ? 'text-emerald-600' : 'text-red-600' }}">{{ $attempt->score }}</td>
                        <td class="px-6 py-4">
                            <span class="inline-flex rounded-full px-2 py-1 text-xs font-medium {{ $attempt->passed ? 'bg-emerald-100 text-emerald-700' : 'bg-red-100 text-red-700' }}">{{ $attempt->passed ? 'Lulus' : 'Tidak Lulus' }}</span>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="5" class="px-6 py-12 text-center text-sm text-gray-400">Belum ada hasil quiz.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
    <div class="border-t border-gray-100 px-6 py-3">
        {{ $attempts->links() }}
    </div>
</div>
@endsection
