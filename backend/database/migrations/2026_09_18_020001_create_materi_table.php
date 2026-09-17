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
        Schema::create('materi', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tp_atp_id')->constrained('tp_atp')->onDelete('cascade');
            $table->foreignId('ar_model_id')->nullable()->constrained('ar_models')->nullOnDelete();
            $table->string('judul', 255);
            $table->string('slug', 255)->nullable();
            $table->text('ringkasan')->nullable();
            $table->longText('konten');
            $table->string('gambar_cover', 255)->nullable();
            $table->integer('estimasi_menit')->default(15);
            $table->integer('order')->default(1);
            $table->boolean('is_published')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('materi');
    }
};
