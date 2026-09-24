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

    /**
     * Sinkronkan pivot ar_marker_models dengan status mapping.
     * Pivot inilah yang dibaca count + resolver aplikasi, jadi setiap
     * tulis mapping (create/update/destroy, API maupun CMS) wajib
     * memanggil ini agar angka tidak pernah 0 padahal terhubung.
     */
    public static function syncPivot(int $markerId, int $modelId): void
    {
        $marker = ArMarker::find($markerId);
        if (!$marker) {
            return;
        }

        $hasMapped = static::where('ar_marker_id', $markerId)
            ->where('ar_model_id', $modelId)
            ->where('mapping_status', 'mapped')
            ->exists();

        if ($hasMapped) {
            $marker->models()->syncWithoutDetaching([$modelId]);
        } else {
            $marker->models()->detach($modelId);
        }
    }
}