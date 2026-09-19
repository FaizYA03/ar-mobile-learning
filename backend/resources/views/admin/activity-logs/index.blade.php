@extends('layouts.admin')
@section('title', 'Activity Logs')
@section('page-title', 'Activity Logs')

@section('content')
<div class="mb-6">
    <form method="GET" action="{{ route('admin.activity-logs.index') }}" class="flex flex-col sm:flex-row gap-3">
        <input type="text" name="search" value="{{ request('search') }}" placeholder="Cari action, deskripsi..." class="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 w-full sm:w-64">
        <select name="action" class="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500">
            <option value="">Semua Action</option>
            @foreach($actions as $act)
                <option value="{{ $act }}" {{ request('action') === $act ? 'selected' : '' }}>{{ $act }}</option>
            @endforeach
        </select>
        <button type="submit" class="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">Filter</button>
    </form>
</div>

<div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
    <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
                <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Waktu</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Action</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Entity</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Deskripsi</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">IP</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
                @forelse($logs as $log)
                    <tr class="hover:bg-gray-50">
                        <td class="px-6 py-4 text-xs text-gray-500 whitespace-nowrap">{{ $log->created_at->format('d M Y H:i:s') }}</td>
                        <td class="px-6 py-4 text-sm text-gray-700">{{ $log->user->name ?? 'System' }}</td>
                        <td class="px-6 py-4">
                            @php
                                $actionColors = [
                                    'created' => 'bg-emerald-100 text-emerald-700',
                                    'updated' => 'bg-blue-100 text-blue-700',
                                    'deleted' => 'bg-red-100 text-red-700',
                                    'uploaded' => 'bg-purple-100 text-purple-700',
                                    'login' => 'bg-amber-100 text-amber-700',
                                ];
                            @endphp
                            <span class="inline-flex rounded-full px-2 py-1 text-xs font-medium {{ $actionColors[$log->action] ?? 'bg-gray-100 text-gray-700' }}">{{ $log->action }}</span>
                        </td>
                        <td class="px-6 py-4 text-sm text-gray-600">{{ $log->entity_type ?? '-' }}{{ $log->entity_id ? ' #' . $log->entity_id : '' }}</td>
                        <td class="px-6 py-4 text-sm text-gray-600 max-w-xs truncate">{{ $log->description ?? '-' }}</td>
                        <td class="px-6 py-4 text-xs text-gray-400">{{ $log->ip_address ?? '-' }}</td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="6" class="px-6 py-12 text-center text-sm text-gray-400">Tidak ada log aktivitas.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
    <div class="border-t border-gray-100 px-6 py-3">
        {{ $logs->links() }}
    </div>
</div>
@endsection
