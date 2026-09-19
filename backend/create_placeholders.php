<?php

require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->handle(new \Symfony\Component\Console\Input\ArgvInput());

use Illuminate\Support\Facades\Storage;

$img = imagecreatetruecolor(256, 256);
$green = imagecolorallocate($img, 0, 164, 119);
$white = imagecolorallocate($img, 255, 255, 255);
imagefill($img, 0, 0, $green);
imagefilledrectangle($img, 100, 20, 156, 236, $white);
imagefilledrectangle($img, 20, 100, 236, 156, $white);
imagefilledrectangle($img, 100, 100, 156, 156, $green);

$markers = [
    '9da1c2c4-5c00-4462-b4c0-a2a0effaa7e3',
    'c015b965-95b5-49b4-91e4-69fa53fde3fc',
];
foreach ($markers as $uuid) {
    $path = tempnam(sys_get_temp_dir(), 'png') . '.png';
    imagepng($img, $path);
    Storage::disk('public')->put('markers/' . $uuid . '.png', file_get_contents($path));
    echo "Created marker: markers/$uuid.png\n";
    unlink($path);
}

$path = tempnam(sys_get_temp_dir(), 'png') . '.png';
imagepng($img, $path);
Storage::disk('public')->put('markers/marker_router.png', file_get_contents($path));
echo "Created marker: markers/marker_router.png\n";
unlink($path);

$thumb = imagecreatetruecolor(256, 256);
$bg = imagecolorallocate($thumb, 232, 237, 242);
$blue = imagecolorallocate($thumb, 90, 106, 191);
imagefill($thumb, 0, 0, $bg);
imagefilledrectangle($thumb, 80, 60, 176, 200, $blue);
imagestring($thumb, 5, 95, 120, '3D', $white);

$thumbPath = tempnam(sys_get_temp_dir(), 'png') . '.png';
imagepng($thumb, $thumbPath);
Storage::disk('public')->put('thumbnails/cpu_thumb.png', file_get_contents($thumbPath));
echo "Created thumbnail: thumbnails/cpu_thumb.png\n";
unlink($thumbPath);

$thumbPath2 = tempnam(sys_get_temp_dir(), 'png') . '.png';
imagepng($thumb, $thumbPath2);
Storage::disk('public')->put('thumbnails/router_thumb.png', file_get_contents($thumbPath2));
echo "Created thumbnail: thumbnails/router_thumb.png\n";
unlink($thumbPath2);

imagedestroy($img);
imagedestroy($thumb);

Storage::disk('public')->put('models/wireless_router.glb', 'placeholder');
echo "Created placeholder: models/wireless_router.glb\n";

echo "\nAll placeholder files created!\n";

// Verify
echo "\n=== Verification ===\n";
$files = Storage::disk('public')->allFiles();
foreach ($files as $f) {
    $size = Storage::disk('public')->size($f);
    echo "  $f ($size bytes)\n";
}
