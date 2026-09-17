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
        Schema::create('ar_models', function (Blueprint $table) {
            $table->id();
            $table->string('model_name'); // Name of the 3D model
            $table->string('glb_path'); // Path to GLB file
            $table->string('thumbnail_path'); // Path to thumbnail image
            $table->string('description'); // Model description
            $table->string('category'); // Category (e.g., molecule, structure)
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ar_models');
    }
};