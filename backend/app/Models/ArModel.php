<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class ArModel extends Model
{
    use HasFactory;

    protected $table = 'ar_models';

    protected $fillable = [
        'model_name',
        'glb_path',
        'thumbnail_path',
        'description',
        'category',
        'is_active',
        'version',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'version' => 'integer',
    ];

    public function hotspots(): HasMany
    {
        return $this->hasMany(ArHotspot::class, 'ar_model_id');
    }

    public function markers(): BelongsToMany
    {
        return $this->belongsToMany(ArMarker::class, 'ar_marker_models', 'ar_model_id', 'ar_marker_id');
    }

    public function materi(): HasMany
    {
        return $this->hasMany(Materi::class, 'ar_model_id');
    }
}
