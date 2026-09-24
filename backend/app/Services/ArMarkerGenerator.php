<?php

namespace App\Services;

use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use RuntimeException;
use Symfony\Component\Process\Process;

/**
 * Generate marker ArUco ASLI (bukan pola asal) memakai OpenCV
 * via script Python backend/scripts/generate_aruco.py.
 *
 * Hasilnya langsung bisa dideteksi aplikasi (scanner ArUco DICT_4X4_50).
 */
class ArMarkerGenerator
{
    /**
     * Dictionary yang didukung => jumlah marker per dictionary.
     */
    public const DICTIONARIES = [
        'DICT_4X4_50' => 50,
        'DICT_5X5_100' => 100,
        'DICT_6X6_250' => 250,
        'DICT_7X7_1000' => 1000,
    ];

    public static function isAvailable(): bool
    {
        $process = new Process(['python3', base_path('scripts/generate_aruco.py'), '--help']);
        $process->setTimeout(15);
        $process->run();

        if (!$process->isSuccessful()) {
            return false;
        }

        $check = new Process(['python3', '-c', 'import cv2, sys; sys.exit(0 if hasattr(cv2, "aruco") else 1)']);
        $check->setTimeout(15);
        $check->run();

        return $check->isSuccessful();
    }

    public static function maxId(string $dictionary): int
    {
        if (!isset(self::DICTIONARIES[$dictionary])) {
            throw new RuntimeException("Dictionary {$dictionary} tidak didukung.");
        }

        return self::DICTIONARIES[$dictionary] - 1;
    }

    /**
     * Generate PNG marker, simpan ke disk public/markers.
     * Return path relatif, mis. markers/aruco-DICT_4X4_50-007.png
     */
    public static function generate(string $dictionary, int $markerId, int $sizePx = 800): string
    {
        $max = self::maxId($dictionary);

        if ($markerId < 0 || $markerId > $max) {
            throw new RuntimeException("ID {$markerId} di luar rentang 0–{$max} untuk {$dictionary}.");
        }

        if (!self::isAvailable()) {
            throw new RuntimeException('Generator tidak tersedia: instal opencv-python-headless + numpy di server (lihat docs/DEPLOY.md).');
        }

        $tmp = sys_get_temp_dir() . '/aruco-' . Str::uuid() . '.png';
        $process = new Process([
            'python3',
            base_path('scripts/generate_aruco.py'),
            '--dictionary', $dictionary,
            '--id', (string) $markerId,
            '--size', (string) max(200, min($sizePx, 2000)),
            '--output', $tmp,
        ]);
        $process->setTimeout(60);
        $process->run();

        if (!$process->isSuccessful() || !is_file($tmp)) {
            @unlink($tmp);
            throw new RuntimeException('Gagal generate marker: ' . trim($process->getErrorOutput() ?: $process->getOutput()));
        }

        // Pastikan benar PNG sebelum disimpan permanen.
        $handle = fopen($tmp, 'rb');
        $magic = $handle ? fread($handle, 8) : '';
        if ($handle) {
            fclose($handle);
        }
        if ($magic !== "\x89PNG\r\n\x1a\n") {
            @unlink($tmp);
            throw new RuntimeException('Output generator bukan PNG yang valid.');
        }

        $filename = sprintf('markers/aruco-%s-%03d.png', $dictionary, $markerId);
        Storage::disk('public')->put($filename, file_get_contents($tmp));
        @unlink($tmp);

        return $filename;
    }
}
