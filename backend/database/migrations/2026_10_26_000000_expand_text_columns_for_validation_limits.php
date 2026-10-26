<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('questions', function (Blueprint $table) {
            $table->text('text')->change();
        });

        Schema::table('question_options', function (Blueprint $table) {
            $table->text('text')->change();
        });

        Schema::table('quizzes', function (Blueprint $table) {
            $table->text('description')->nullable()->change();
        });

        Schema::table('ar_models', function (Blueprint $table) {
            $table->text('description')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('questions', function (Blueprint $table) {
            $table->string('text', 255)->change();
        });

        Schema::table('question_options', function (Blueprint $table) {
            $table->string('text', 255)->change();
        });

        Schema::table('quizzes', function (Blueprint $table) {
            $table->string('description', 255)->nullable()->change();
        });

        Schema::table('ar_models', function (Blueprint $table) {
            $table->string('description', 255)->nullable()->change();
        });
    }
};
