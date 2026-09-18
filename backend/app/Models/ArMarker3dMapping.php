<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ArMarker3dMapping extends Model
{
    use HasFactory;

    protected $table = 'marker_3d_mappings';

    protected $fillable = [
        'ar_marker_id',
        'ar_model_id',
        'mapping_method',
        'mapping_status',
        'mapping_notes',
    ];

    public function arMarker(): BelongsTo
    {
        return $this->belongsTo(ArMarker::class, 'ar_marker_id');
    }

    public function arModel(): BelongsTo
    {
        return $this->belongsTo(ArModel::class, 'ar_model_id');
    }
}