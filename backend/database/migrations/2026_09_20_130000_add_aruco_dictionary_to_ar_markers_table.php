<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('ar_markers', function (Blueprint $table) {
            $table->string('aruco_dictionary', 50)->nullable()->after('ar_uco_id');
        });
    }

    public function down(): void
    {
        Schema::table('ar_markers', function (Blueprint $table) {
            $table->dropColumn('aruco_dictionary');
        });
    }
};
