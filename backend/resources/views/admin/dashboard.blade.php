@extends('layouts.admin')
@section('title', 'Dashboard')
@section('page-title', 'Dashboard')

@section('content')
<div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4 mb-8">
    <div class="bg-white rounded-xl border border-gray-200 p-5">
        <div class="flex items-center gap-3">
            <div class="h-10 w-10 rounded-lg bg-blue-50 flex items-center justify-center">
                <svg class="h-5 w-5 text-blue-600" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" /></svg>
            </div>
            <div>
                <p class="text-sm text-gray-500">Total Users</p>
                <p class="text-2xl font-bold text-gray-900">{{ $stats['total_users'] }}</p>
            </div>
        </div>
        <div class="mt-3 flex gap-3 text-xs text-gray-500">
            <span>{{ $stats['total_siswa'] }} siswa</span>
            <span>{{ $stats['total_guru'] }} guru</span>
            <span>{{ $stats['total_admin'] }} admin</span>
        </div>
    </div>

    <div class="bg-white rounded-xl border border-gray-200 p-5">
        <div class="flex items-center gap-3">
            <div class="h-10 w-10 rounded-lg bg-emerald-50 flex items-center justify-center">
                <svg class="h-5 w-5 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M12 6.042A8.967 8.967 0 0 0 6 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 0 1 6 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 0 1 6-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0 0 18 18a8.967 8.967 0 0 0-6 2.292m0-14.25v14.25" /></svg>
            </div>
            <div>
                <p class="text-sm text-gray-500">Materi</p>
                <p class="text-2xl font-bold text-gray-900">{{ $stats['total_materi'] }}</p>
            </div>
        </div>
        <div class="mt-3 text-xs text-gray-500">{{ $stats['total_tp_atp'] }} TP/ATP</div>
    </div>

    <div class="bg-white rounded-xl border border-gray-200 p-5">
        <div class="flex items-center gap-3">
            <div class="h-10 w-10 rounded-lg bg-amber-50 flex items-center justify-center">
                <svg class="h-5 w-5 text-amber-600" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M9.879 7.519c1.171-1.025 3.071-1.025 4.242 0 1.172 1.025 1.172 2.687 0 3.712-.203.179-.43.326-.67.442-.745.361-1.45.999-1.45 1.827v.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9 5.25h.008v.008H12v-.008Z" /></svg>
            </div>
            <div>
                <p class="text-sm text-gray-500">Quiz</p>
                <p class="text-2xl font-bold text-gray-900">{{ $stats['total_quiz'] }}</p>
            </div>
        </div>
        <div class="mt-3 text-xs text-gray-500">{{ $stats['total_quiz_attempts'] }} attempts</div>
    </div>

    <div class="bg-white rounded-xl border border-gray-200 p-5">
        <div class="flex items-center gap-3">
            <div class="h-10 w-10 rounded-lg bg-purple-50 flex items-center justify-center">
                <svg class="h-5 w-5 text-purple-600" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M21 7.5l-2.25-1.313M21 7.5v2.25m0-2.25l-2.25 1.313M3 7.5l2.25-1.313M3 7.5l2.25 1.313M3 7.5v2.25m9 3l2.25-1.313M12 12.75l-2.25-1.313M12 12.75V15m0 6.75l2.25-1.313M12 21.75V19.5m0 2.25l-2.25-1.313m0-16.875L12 2.25l2.25 1.313M21 14.25v2.25l-2.25 1.313m-13.5 0L3 16.5v-2.25" /></svg>
            </div>
            <div>
                <p class="text-sm text-gray-500">AR Content</p>
                <p class="text-2xl font-bold text-gray-900">{{ $stats['total_ar_models'] }}</p>
            </div>
        </div>
        <div class="mt-3 text-xs text-gray-500">{{ $stats['total_ar_markers'] }} markers</div>
    </div>
</div>

<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
    <div class="lg:col-span-2 bg-white rounded-xl border border-gray-200">
        <div class="px-5 py-4 border-b border-gray-100">
            <h2 class="text-sm font-semibold text-gray-900">Recent Activity</h2>
        </div>
        <div class="divide-y divide-gray-100">
            @forelse($recentActivity as $log)
                <div class="px-5 py-3 flex items-center gap-3">
                    <div class="h-8 w-8 rounded-full bg-gray-100 flex items-center justify-center shrink-0">
                        <span class="text-xs font-medium text-gray-600">{{ strtoupper(substr($log->user->name ?? 'S', 0, 1)) }}</span>
                    </div>
                    <div class="min-w-0 flex-1">
                        <p class="text-sm text-gray-700 truncate">{{ $log->description ?? $log->action }}</p>
                        <p class="text-xs text-gray-400">{{ $log->created_at->diffForHumans() }} · {{ $log->user->name ?? 'System' }}</p>
                    </div>
                </div>
            @empty
                <div class="px-5 py-8 text-center text-sm text-gray-400">No activity yet</div>
            @endforelse
        </div>
    </div>

    <div class="bg-white rounded-xl border border-gray-200 p-5">
        <h2 class="text-sm font-semibold text-gray-900 mb-4">System Status</h2>
        <div class="space-y-3">
            <div class="flex items-center justify-between">
                <span class="text-sm text-gray-600">Database</span>
                <span class="inline-flex items-center gap-1 text-xs font-medium {{ $dbOk ? 'text-emerald-600' : 'text-red-600' }}">
                    <span class="h-1.5 w-1.5 rounded-full {{ $dbOk ? 'bg-emerald-500' : 'bg-red-500' }}"></span>
                    {{ $dbOk ? 'Online' : 'Offline' }}
                </span>
            </div>
            <div class="flex items-center justify-between">
                <span class="text-sm text-gray-600">Storage</span>
                <span class="inline-flex items-center gap-1 text-xs font-medium {{ $storageExists ? 'text-emerald-600' : 'text-red-600' }}">
                    <span class="h-1.5 w-1.5 rounded-full {{ $storageExists ? 'bg-emerald-500' : 'bg-red-500' }}"></span>
                    {{ $storageExists ? 'Ready' : 'Missing' }}
                </span>
            </div>
            <div class="flex items-center justify-between">
                <span class="text-sm text-gray-600">Application</span>
                <span class="inline-flex items-center gap-1 text-xs font-medium text-emerald-600">
                    <span class="h-1.5 w-1.5 rounded-full bg-emerald-500"></span>
                    Running
                </span>
            </div>
        </div>
    </div>
</div>
@endsection
