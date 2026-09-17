<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('ar_markers', function (Blueprint $table) {
            $table->id();
            $table->string('marker_id'); // Unique marker identifier
            $table->string('marker_type'); // Type/pattern of marker
            $table->string('image_path'); // Path to marker image
            $table->string('status')->default('active'); // active, inactive
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ar_markers');
    }
};