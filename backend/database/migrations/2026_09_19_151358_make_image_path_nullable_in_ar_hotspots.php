<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $driver = DB::getDriverName();
        if ($driver === 'sqlite') {
            return;
        }
        DB::statement('ALTER TABLE ar_hotspots MODIFY COLUMN image_path VARCHAR(1024) NULL');
        DB::statement('ALTER TABLE ar_hotspots MODIFY COLUMN description TEXT NULL');
    }

    public function down(): void
    {
        $driver = DB::getDriverName();
        if ($driver === 'sqlite') {
            return;
        }
        DB::statement('ALTER TABLE ar_hotspots MODIFY COLUMN image_path VARCHAR(1024) NOT NULL');
        DB::statement('ALTER TABLE ar_hotspots MODIFY COLUMN description TEXT NOT NULL');
    }
};
