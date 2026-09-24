<?php

use App\Models\ArMarker3dMapping;
use Illuminate\Database\Migrations\Migration;

/**
 * Backfill: mapping berstatus 'mapped' yang dibuat sebelum sinkronisasi
 * pivot otomatis harus ikut mengisi ar_marker_models agar count CMS
 * dan resolver aplikasi tidak 0. Idempoten (syncWithoutDetaching).
 */
return new class extends Migration
{
    public function up(): void
    {
        ArMarker3dMapping::where('mapping_status', 'mapped')
            ->get(['ar_marker_id', 'ar_model_id'])
            ->each(fn ($m) => ArMarker3dMapping::syncPivot($m->ar_marker_id, $m->ar_model_id));
    }

    public function down(): void
    {
        // Sengaja tidak menghapus pivot: data koneksi milik admin.
    }
};
