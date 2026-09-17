<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ArHotspot extends Model
{
    use HasFactory;

    protected $table = 'ar_hotspots';

    protected $fillable = [
        'ar_model_id',
        'title',
        'description',
        'latitude',
        'longitude',
        'image_path',
        'is_active',
    ];

    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
        'is_active' => 'boolean',
    ];

    public function arModel(): BelongsTo
    {
        return $this->belongsTo(ArModel::class, 'ar_model_id');
    }
}
