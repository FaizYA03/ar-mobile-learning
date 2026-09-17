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
        Schema::create('ar_hotspots', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ar_model_id')->constrained()->onDelete('cascade');
            $table->string('title'); // Hotspot title/explanation
            $table->string('description'); // Detailed explanation
            $table->double('latitude')->nullable(); // For geolocation hotspots
            $table->double('longitude')->nullable(); // For geolocation hotspots
            $table->string('image_path'); // Hotspot image
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ar_hotspots');
    }
};