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
        Schema::create('tp_atp', function (Blueprint $table) {
            $table->id();
            $table->string('kode', 50)->unique();
            $table->string('fase', 10)->default('E');
            $table->string('elemen', 100);
            $table->string('judul', 255);
            $table->text('deskripsi')->nullable();
            $table->integer('order')->default(1);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tp_atp');
    }
};
