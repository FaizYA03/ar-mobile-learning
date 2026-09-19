<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('ar_hotspots', function (Blueprint $table) {
            $table->float('position_x')->default(0)->after('longitude');
            $table->float('position_y')->default(0)->after('position_x');
            $table->float('position_z')->default(0)->after('position_y');
            $table->float('rotation_x')->default(0)->after('position_z');
            $table->float('rotation_y')->default(0)->after('rotation_x');
            $table->float('rotation_z')->default(0)->after('rotation_y');
            $table->float('scale')->default(1.0)->after('rotation_z');
            $table->integer('sort_order')->default(0)->after('scale');
        });
    }

    public function down(): void
    {
        Schema::table('ar_hotspots', function (Blueprint $table) {
            $table->dropColumn([
                'position_x', 'position_y', 'position_z',
                'rotation_x', 'rotation_y', 'rotation_z',
                'scale', 'sort_order',
            ]);
        });
    }
};
