<?php

namespace App\Console\Commands;

use App\Models\ArHotspot;
use App\Models\ArMarker;
use App\Models\ArModel;
use App\Models\Materi;
use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

class CleanOrphanMedia extends Command
{
    protected $signature = 'media:clean-orphans
                            {--force : Hapus file yatim (default hanya tampilkan daftar)}';

    protected $description = 'Hapus file media di storage/public yang tidak lagi direferensikan database';

    public function handle(): int
    {
        $disk = Storage::disk('public');
        $referenced = $this->referencedPaths();

        $orphans = [];
        foreach (['avatars', 'covers', 'models', 'thumbnails', 'markers', 'hotspots'] as $dir) {
            if (!$disk->directoryExists($dir)) {
                continue;
            }
            foreach ($disk->allFiles($dir) as $file) {
                if (!in_array($file, $referenced, true)) {
                    $orphans[] = $file;
                }
            }
        }

        if (empty($orphans)) {
            $this->info('Bersih: tidak ada file yatim.');
            return self::SUCCESS;
        }

        $totalBytes = 0;
        foreach ($orphans as $file) {
            $totalBytes += $disk->size($file);
        }

        if (!$this->option('force')) {
            $this->warn(count($orphans) . ' file yatim (' . $this->formatBytes($totalBytes) . ') — jalankan dengan --force untuk menghapus:');
            foreach ($orphans as $file) {
                $this->line("  - {$file}");
            }
            return self::SUCCESS;
        }

        $deleted = 0;
        foreach ($orphans as $file) {
            if ($disk->delete($file)) {
                $deleted++;
            }
        }

        $this->info("Selesai: {$deleted}/" . count($orphans) . ' file yatim dihapus (' . $this->formatBytes($totalBytes) . ').');

        return self::SUCCESS;
    }

    /**
     * Kumpulkan semua path file yang masih direferensikan DB,
     * dinormalisasi ke format relatif disk public (tanpa prefix storage/).
     *
     * @return string[]
     */
    private function referencedPaths(): array
    {
        $raw = [
            ...User::whereNotNull('avatar')->pluck('avatar')->all(),
            ...Materi::whereNotNull('gambar_cover')->pluck('gambar_cover')->all(),
            ...ArModel::whereNotNull('glb_path')->pluck('glb_path')->all(),
            ...ArModel::whereNotNull('thumbnail_path')->pluck('thumbnail_path')->all(),
            ...ArMarker::whereNotNull('image_path')->pluck('image_path')->all(),
            ...ArHotspot::whereNotNull('image_path')->pluck('image_path')->all(),
        ];

        $normalized = [];
        foreach ($raw as $path) {
            $path = trim((string) $path);
            if ($path === '' || str_starts_with($path, 'http')) {
                continue;
            }
            if (str_starts_with($path, 'storage/')) {
                $path = substr($path, 8);
            }
            $normalized[] = ltrim($path, '/');
        }

        return array_unique($normalized);
    }

    private function formatBytes(int $bytes): string
    {
        if ($bytes < 1024) {
            return $bytes . ' B';
        }
        if ($bytes < 1024 * 1024) {
            return round($bytes / 1024, 1) . ' KB';
        }

        return round($bytes / 1024 / 1024, 2) . ' MB';
    }
}
