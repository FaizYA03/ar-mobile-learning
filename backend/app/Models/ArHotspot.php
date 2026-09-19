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
        'position_x',
        'position_y',
        'position_z',
        'rotation_x',
        'rotation_y',
        'rotation_z',
        'scale',
        'image_path',
        'is_active',
        'sort_order',
    ];

    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
        'position_x' => 'float',
        'position_y' => 'float',
        'position_z' => 'float',
        'rotation_x' => 'float',
        'rotation_y' => 'float',
        'rotation_z' => 'float',
        'scale' => 'float',
        'is_active' => 'boolean',
        'sort_order' => 'integer',
    ];

    public function arModel(): BelongsTo
    {
        return $this->belongsTo(ArModel::class, 'ar_model_id');
    }
}
