<?php

namespace App\Services;

use App\Models\ActivityLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ActivityLogger
{
    public static function log(
        string $action,
        ?string $entityType = null,
        ?int $entityId = null,
        ?string $description = null,
        ?array $metadata = null,
        ?Request $request = null,
        ?\App\Models\User $user = null,
    ): ActivityLog {
        $user = $user ?? Auth::user();
        $request = $request ?? request();

        return ActivityLog::create([
            'user_id' => $user?->id,
            'action' => $action,
            'entity_type' => $entityType,
            'entity_id' => $entityId,
            'description' => $description,
            'metadata' => $metadata,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);
    }

    public static function login(?Request $request = null, ?\App\Models\User $user = null): ActivityLog
    {
        return static::log('login', 'user', $user?->id ?? Auth::id(), 'User logged in', request: $request, user: $user);
    }

    public static function logout(?Request $request = null, ?\App\Models\User $user = null): ActivityLog
    {
        return static::log('logout', 'user', $user?->id ?? Auth::id(), 'User logged out', request: $request, user: $user);
    }

    public static function created(string $entityType, int $entityId, ?string $description = null, ?array $metadata = null): ActivityLog
    {
        return static::log("{$entityType}.created", $entityType, $entityId, $description, $metadata);
    }

    public static function updated(string $entityType, int $entityId, ?string $description = null, ?array $metadata = null): ActivityLog
    {
        return static::log("{$entityType}.updated", $entityType, $entityId, $description, $metadata);
    }

    public static function deleted(string $entityType, int $entityId, ?string $description = null, ?array $metadata = null): ActivityLog
    {
        return static::log("{$entityType}.deleted", $entityType, $entityId, $description, $metadata);
    }

    public static function uploaded(string $entityType, int $entityId, string $fileName, ?string $description = null): ActivityLog
    {
        return static::log("{$entityType}.uploaded", $entityType, $entityId, $description, ['file_name' => $fileName]);
    }
}
