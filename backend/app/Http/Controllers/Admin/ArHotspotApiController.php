<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ArHotspot;
use App\Models\ArModel;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ArHotspotApiController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $modelId = $request->input('ar_model_id');
        $query = ArHotspot::orderBy('sort_order');

        if ($modelId) {
            $query->where('ar_model_id', $modelId);
        }

        $hotspots = $query->get();

        return response()->json([
            'success' => true,
            'data' => $hotspots,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'ar_model_id' => 'required|exists:ar_models,id',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'position_x' => 'required|numeric',
            'position_y' => 'required|numeric',
            'position_z' => 'required|numeric',
            'rotation_x' => 'nullable|numeric',
            'rotation_y' => 'nullable|numeric',
            'rotation_z' => 'nullable|numeric',
            'scale' => 'nullable|numeric|min:0.1',
            'image_path' => 'nullable|image|max:2048',
            'sort_order' => 'nullable|integer',
        ]);

        $validated['rotation_x'] = $validated['rotation_x'] ?? 0;
        $validated['rotation_y'] = $validated['rotation_y'] ?? 0;
        $validated['rotation_z'] = $validated['rotation_z'] ?? 0;
        $validated['scale'] = $validated['scale'] ?? 1.0;
        $validated['is_active'] = true;
        $validated['sort_order'] = $validated['sort_order'] ?? 0;
        $validated['image_path'] = $validated['image_path'] ?? null;

        if ($request->hasFile('image_path')) {
            $imageFile = $request->file('image_path');
            $stored = $imageFile->storeAs(
                'hotspots',
                Str::uuid() . '.' . $imageFile->getClientOriginalExtension(),
                'public'
            );
            $validated['image_path'] = $stored ? $stored : '';
        }

        $hotspot = ArHotspot::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Hotspot berhasil ditambahkan',
            'data' => $hotspot,
        ], 201);
    }

    public function show(ArHotspot $hotspot): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => $hotspot,
        ]);
    }

    public function update(Request $request, ArHotspot $hotspot): JsonResponse
    {
        $validated = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
            'position_x' => 'sometimes|numeric',
            'position_y' => 'sometimes|numeric',
            'position_z' => 'sometimes|numeric',
            'rotation_x' => 'nullable|numeric',
            'rotation_y' => 'nullable|numeric',
            'rotation_z' => 'nullable|numeric',
            'scale' => 'nullable|numeric|min:0.1',
            'image_path' => 'nullable|image|max:2048',
            'is_active' => 'nullable|boolean',
            'sort_order' => 'nullable|integer',
        ]);

        if ($request->hasFile('image_path')) {
            if ($hotspot->image_path) {
                Storage::disk('public')->delete($hotspot->image_path);
            }
            $imageFile = $request->file('image_path');
            $stored = $imageFile->storeAs(
                'hotspots',
                Str::uuid() . '.' . $imageFile->getClientOriginalExtension(),
                'public'
            );
            $validated['image_path'] = $stored ? $stored : '';
        }

        $hotspot->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Hotspot berhasil diperbarui',
            'data' => $hotspot,
        ]);
    }

    public function destroy(ArHotspot $hotspot): JsonResponse
    {
        if ($hotspot->image_path) {
            Storage::disk('public')->delete($hotspot->image_path);
        }
        $hotspot->delete();

        return response()->json([
            'success' => true,
            'message' => 'Hotspot berhasil dihapus',
        ]);
    }

    public function reorder(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'hotspots' => 'required|array',
            'hotspots.*.id' => 'required|exists:ar_hotspots,id',
            'hotspots.*.sort_order' => 'required|integer',
        ]);

        foreach ($validated['hotspots'] as $item) {
            ArHotspot::where('id', $item['id'])->update(['sort_order' => $item['sort_order']]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Urutan hotspot berhasil diperbarui',
        ]);
    }
}
