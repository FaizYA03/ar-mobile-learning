<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Materi extends Model
{
    use HasFactory;

    protected $table = 'materi';

    protected $fillable = [
        'tp_atp_id',
        'ar_model_id',
        'quiz_id',
        'judul',
        'slug',
        'ringkasan',
        'konten',
        'gambar_cover',
        'estimasi_menit',
        'order',
        'is_published',
    ];

    protected $casts = [
        'estimasi_menit' => 'integer',
        'order' => 'integer',
        'is_published' => 'boolean',
    ];

    public function tpAtp(): BelongsTo
    {
        return $this->belongsTo(TpAtp::class, 'tp_atp_id');
    }

    public function arModel(): BelongsTo
    {
        return $this->belongsTo(ArModel::class, 'ar_model_id');
    }

    public function quiz(): BelongsTo
    {
        return $this->belongsTo(Quiz::class, 'quiz_id');
    }
}
