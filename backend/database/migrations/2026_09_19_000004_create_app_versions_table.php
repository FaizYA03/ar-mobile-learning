<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('app_versions', function (Blueprint $table) {
            $table->id();
            $table->string('platform');
            $table->string('version');
            $table->string('build_number')->nullable();
            $table->string('minimum_supported_version')->nullable();
            $table->text('release_notes')->nullable();
            $table->string('download_url')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index(['platform', 'is_active']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('app_versions');
    }
};
