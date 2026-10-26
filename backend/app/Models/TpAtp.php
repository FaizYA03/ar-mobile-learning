<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class TpAtp extends Model
{
    use HasFactory;

    protected $table = 'tp_atp';

    protected $fillable = [
        'created_by',
        'kode',
        'fase',
        'elemen',
        'judul',
        'deskripsi',
        'order',
        'is_active',
    ];

    protected $casts = [
        'order' => 'integer',
        'is_active' => 'boolean',
    ];

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function materi(): HasMany
    {
        return $this->hasMany(Materi::class, 'tp_atp_id')->orderBy('order', 'asc');
    }
}
