<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AppVersion extends Model
{
    use HasFactory;

    protected $table = 'app_versions';

    protected $fillable = [
        'platform',
        'version',
        'build_number',
        'minimum_supported_version',
        'release_notes',
        'download_url',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeForPlatform($query, string $platform)
    {
        return $query->where('platform', $platform);
    }

    public static function getLatest(string $platform = 'android'): ?static
    {
        return static::active()
            ->forPlatform($platform)
            ->orderByDesc('created_at')
            ->first();
    }
}
