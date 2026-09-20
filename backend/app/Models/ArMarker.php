<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ArMarker extends Model
{
    use HasFactory;

    protected $table = 'ar_markers';

    protected $fillable = [
        'marker_id',
        'marker_type',
        'image_path',
        'status',
        'ar_uco_id',
    ];

    public function models(): BelongsToMany
    {
        return $this->belongsToMany(ArModel::class, 'ar_marker_models', 'ar_marker_id', 'ar_model_id');
    }

    public function mappings(): HasMany
    {
        return $this->hasMany(ArMarker3dMapping::class, 'ar_marker_id');
    }
}
