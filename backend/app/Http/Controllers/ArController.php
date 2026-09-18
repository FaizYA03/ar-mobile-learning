<?php

namespace App\Http\Controllers;

use App\Models\ArModel;
use App\Models\ArMarker;
use App\Models\ArHotspot;
use App\Models\ArMarker3dMapping;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ArController extends Controller
{
    // ========== AR MODELS ==========

    public function modelIndex(): JsonResponse
    {
        $models = ArModel::withCount('hotspots', 'markers')
            ->with('markers')
            ->orderByDesc('is_active')
            ->orderBy('model_name')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Data AR models berhasil diambil',
            'data' => $models,
        ]);
    }

    public function modelShow(ArModel $arModel): JsonResponse
    {
        $arModel->load(['hotspots', 'markers', 'materi']);
        return response()->json([
            'success' => true,
            'message' => 'Detail AR model berhasil diambil',
            'data' => $arModel,
        ]);
    }

    public function modelStore(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'model_name' => 'required|string|max:255',
            'glb_path' => 'required|max:102400',
            'thumbnail_path' => 'nullable|image|max:5120',
            'description' => 'nullable|string',
            'category' => 'nullable|string|max:100',
            'is_active' => 'nullable|boolean',
        ]);

        if ($request->hasFile('glb_path')) {
            $glbFile = $request->file('glb_path');
            $filename = 'models/' . Str::uuid() . '.' . $glbFile->getClientOriginalExtension();
            $validated['glb_path'] = $glbFile->storeAs('public', $filename) ? 'storage/' . $filename : '';
        }

        if ($request->hasFile('thumbnail_path')) {
            $thumbFile = $request->file('thumbnail_path');
            $filename = 'thumbnails/' . Str::uuid() . '.' . $thumbFile->getClientOriginalExtension();
            $validated['thumbnail_path'] = $thumbFile->storeAs('public', $filename) ? 'storage/' . $filename : '';
        }

        $model = ArModel::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'AR model berhasil dibuat',
            'data' => $model,
        ], 201);
    }

    public function modelUpdate(Request $request, ArModel $arModel): JsonResponse
    {
        $validated = $request->validate([
            'model_name' => 'sometimes|required|string|max:255',
            'glb_path' => 'sometimes|max:102400',
            'thumbnail_path' => 'sometimes|image|max:5120',
            'description' => 'nullable|string',
            'category' => 'nullable|string|max:100',
            'is_active' => 'nullable|boolean',
        ]);

        if ($request->hasFile('glb_path')) {
            if ($arModel->glb_path && str_starts_with($arModel->glb_path, 'storage/')) {
                Storage::disk('public')->delete(str_replace('storage/', '', $arModel->glb_path));
            }
            $glbFile = $request->file('glb_path');
            $filename = 'models/' . Str::uuid() . '.' . $glbFile->getClientOriginalExtension();
            $validated['glb_path'] = $glbFile->storeAs('public', $filename) ? 'storage/' . $filename : '';
        }

        if ($request->hasFile('thumbnail_path')) {
            if ($arModel->thumbnail_path && str_starts_with($arModel->thumbnail_path, 'storage/')) {
                Storage::disk('public')->delete(str_replace('storage/', '', $arModel->thumbnail_path));
            }
            $thumbFile = $request->file('thumbnail_path');
            $filename = 'thumbnails/' . Str::uuid() . '.' . $thumbFile->getClientOriginalExtension();
            $validated['thumbnail_path'] = $thumbFile->storeAs('public', $filename) ? 'storage/' . $filename : '';
        }

        $arModel->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'AR model berhasil diperbarui',
            'data' => $arModel,
        ]);
    }

    public function modelDestroy(ArModel $arModel): JsonResponse
    {
        if ($arModel->glb_path && str_starts_with($arModel->glb_path, 'storage/')) {
            Storage::disk('public')->delete(str_replace('storage/', '', $arModel->glb_path));
        }
        if ($arModel->thumbnail_path && str_starts_with($arModel->thumbnail_path, 'storage/')) {
            Storage::disk('public')->delete(str_replace('storage/', '', $arModel->thumbnail_path));
        }
        $arModel->markers()->detach();
        $arModel->delete();
        return response()->json([
            'success' => true,
            'message' => 'AR model berhasil dihapus',
        ]);
    }

    // ========== AR MARKERS ==========

    public function markerIndex(): JsonResponse
    {
        $markers = ArMarker::withCount('models')->get();
        return response()->json([
            'success' => true,
            'message' => 'Data AR markers berhasil diambil',
            'data' => $markers,
        ]);
    }

    public function markerShow(ArMarker $arMarker): JsonResponse
    {
        $arMarker->load('models');
        return response()->json([
            'success' => true,
            'message' => 'Detail AR marker berhasil diambil',
            'data' => $arMarker,
        ]);
    }

    public function markerStore(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'marker_id' => 'required|string|max:100|unique:ar_markers,marker_id',
            'marker_type' => 'required|string|in:pattern,image',
            'image_path' => 'required|image|max:10240',
            'status' => 'nullable|string|in:active,inactive',
        ]);

        if ($request->hasFile('image_path')) {
            $imageFile = $request->file('image_path');
            $filename = 'markers/' . Str::uuid() . '.' . $imageFile->getClientOriginalExtension();
            $validated['image_path'] = $imageFile->storeAs('public', $filename) ? 'storage/' . $filename : '';
        }

        $marker = ArMarker::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'AR marker berhasil dibuat',
            'data' => $marker,
        ], 201);
    }

    public function markerUpdate(Request $request, ArMarker $arMarker): JsonResponse
    {
        $validated = $request->validate([
            'marker_id' => 'sometimes|required|string|max:100|unique:ar_markers,marker_id,' . $arMarker->id,
            'marker_type' => 'sometimes|required|string|in:pattern,image',
            'image_path' => 'sometimes|max:10240',
            'status' => 'nullable|string|in:active,inactive',
        ]);

        if ($request->hasFile('image_path')) {
            if ($arMarker->image_path && str_starts_with($arMarker->image_path, 'storage/')) {
                Storage::disk('public')->delete(str_replace('storage/', '', $arMarker->image_path));
            }
            $imageFile = $request->file('image_path');
            $filename = 'markers/' . Str::uuid() . '.' . $imageFile->getClientOriginalExtension();
            $validated['image_path'] = $imageFile->storeAs('public', $filename) ? 'storage/' . $filename : '';
        }

        $arMarker->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'AR marker berhasil diperbarui',
            'data' => $arMarker,
        ]);
    }

    public function markerDestroy(ArMarker $arMarker): JsonResponse
    {
        if ($arMarker->image_path && str_starts_with($arMarker->image_path, 'storage/')) {
            Storage::disk('public')->delete(str_replace('storage/', '', $arMarker->image_path));
        }
        $arMarker->models()->detach();
        $arMarker->delete();
        return response()->json([
            'success' => true,
            'message' => 'AR marker berhasil dihapus',
        ]);
    }

    // ========== AR HOTSPOTS ==========

    public function hotspotIndex(): JsonResponse
    {
        $hotspots = ArHotspot::with('arModel:id,model_name')->get();
        return response()->json([
            'success' => true,
            'message' => 'Data AR hotspots berhasil diambil',
            'data' => $hotspots,
        ]);
    }

    public function hotspotShow(ArHotspot $arHotspot): JsonResponse
    {
        $arHotspot->load('arModel');
        return response()->json([
            'success' => true,
            'message' => 'Detail AR hotspot berhasil diambil',
            'data' => $arHotspot,
        ]);
    }

    public function hotspotStore(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'ar_model_id' => 'required|exists:ar_models,id',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'image_path' => 'nullable|image|max:5120',
            'is_active' => 'nullable|boolean',
        ]);

        if ($request->hasFile('image_path')) {
            $imageFile = $request->file('image_path');
            $filename = 'hotspots/' . Str::uuid() . '.' . $imageFile->getClientOriginalExtension();
            $validated['image_path'] = $imageFile->storeAs('public', $filename) ? 'storage/' . $filename : '';
        }

        $hotspot = ArHotspot::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'AR hotspot berhasil dibuat',
            'data' => $hotspot,
        ], 201);
    }

    public function hotspotUpdate(Request $request, ArHotspot $arHotspot): JsonResponse
    {
        $validated = $request->validate([
            'ar_model_id' => 'sometimes|required|exists:ar_models,id',
            'title' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'image_path' => 'sometimes|max:5120',
            'is_active' => 'nullable|boolean',
        ]);

        if ($request->hasFile('image_path')) {
            if ($arHotspot->image_path && str_starts_with($arHotspot->image_path, 'storage/')) {
                Storage::disk('public')->delete(str_replace('storage/', '', $arHotspot->image_path));
            }
            $imageFile = $request->file('image_path');
            $filename = 'hotspots/' . Str::uuid() . '.' . $imageFile->getClientOriginalExtension();
            $validated['image_path'] = $imageFile->storeAs('public', $filename) ? 'storage/' . $filename : '';
        }

        $arHotspot->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'AR hotspot berhasil diperbarui',
            'data' => $arHotspot,
        ]);
    }

    public function hotspotDestroy(ArHotspot $arHotspot): JsonResponse
    {
        if ($arHotspot->image_path && str_starts_with($arHotspot->image_path, 'storage/')) {
            Storage::disk('public')->delete(str_replace('storage/', '', $arHotspot->image_path));
        }
        $arHotspot->delete();
        return response()->json([
            'success' => true,
            'message' => 'AR hotspot berhasil dihapus',
        ]);
    }

    // ========== MARKER <-> MODEL MAPPING ==========

    public function getMarkerModels(ArMarker $arMarker): JsonResponse
    {
        $arMarker->load('models');
        return response()->json([
            'success' => true,
            'message' => 'Model untuk marker berhasil diambil',
            'data' => $arMarker->models,
        ]);
    }

    public function attachModel(Request $request, ArMarker $arMarker): JsonResponse
    {
        $validated = $request->validate([
            'ar_model_id' => 'required|exists:ar_models,id',
        ]);

        $exists = $arMarker->models()->where('ar_model_id', $validated['ar_model_id'])->exists();
        if ($exists) {
            return response()->json([
                'success' => false,
                'message' => 'Model sudah terhubung ke marker ini',
            ], 409);
        }

        $arMarker->models()->attach($validated['ar_model_id']);

        return response()->json([
            'success' => true,
            'message' => 'Model berhasil dihubungkan ke marker',
            'data' => $arMarker->load('models')->models,
        ]);
    }

    public function detachModel(ArMarker $arMarker, ArModel $arModel): JsonResponse
    {
        $arMarker->models()->detach($arModel->id);
        return response()->json([
            'success' => true,
            'message' => 'Model berhasil dipisahkan dari marker',
        ]);
    }

    public function allMappings(): JsonResponse
    {
        $markers = ArMarker::with(['models', 'mappings'])->get();
        $models = ArModel::withCount('markers')->get();
        return response()->json([
            'success' => true,
            'message' => 'Semua mapping marker-model berhasil diambil',
            'data' => [
                'markers' => $markers->map(function ($marker) {
                    return [
                        'id' => $marker->id,
                        'marker_id' => $marker->marker_id,
                        'marker_type' => $marker->marker_type,
                        'image_path' => $marker->image_path,
                        'status' => $marker->status,
                        'models' => $marker->models->map(function ($model) use ($marker) {
                            $mapping = $marker->mappings->firstWhere('ar_model_id', $model->id);
                            return [
                                'id' => $model->id,
                                'model_name' => $model->model_name,
                                'glb_path' => $model->glb_path,
                                'thumbnail_path' => $model->thumbnail_path,
                                'mapping_method' => $mapping?->mapping_method,
                                'mapping_status' => $mapping?->mapping_status,
                                'mapping_notes' => $mapping?->mapping_notes,
                            ];
                        }),
                    ];
                }),
                'models' => $models,
            ],
        ]);
    }

    public function arCreateMapping(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'ar_marker_id' => 'required|exists:ar_markers,id',
            'ar_model_id' => 'required|exists:ar_models,id',
            'mapping_method' => 'required|string|in:image_tracking,marker_id',
            'mapping_status' => 'required|string|in:pending,mapped,failed',
            'mapping_notes' => 'nullable|string',
        ]);

        $mapping = ArMarker3dMapping::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Mapping marker-model berhasil dibuat',
            'data' => $mapping,
        ], 201);
    }

    public function arUpdateMapping(Request $request, ArMarker3dMapping $arMarker3dMapping): JsonResponse
    {
        $validated = $request->validate([
            'mapping_method' => 'sometimes|required|string|in:image_tracking,marker_id',
            'mapping_status' => 'sometimes|required|string|in:pending,mapped,failed',
            'mapping_notes' => 'nullable|string',
        ]);

        $arMarker3dMapping->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Mapping marker-model berhasil diperbarui',
            'data' => $arMarker3dMapping,
        ]);
    }

    // ========== PUBLIC AR ENDPOINTS (untuk siswa) ==========

    public function publicModels(): JsonResponse
    {
        $models = ArModel::where('is_active', true)
            ->withCount('markers')
            ->with('markers', function ($q) {
                $q->wherePivot('id', '!=', null);
            })
            ->orderBy('model_name')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Data AR models berhasil diambil',
            'data' => $models,
        ]);
    }

    public function publicModelShow(ArModel $arModel): JsonResponse
    {
        $arModel->load(['hotspots', 'markers']);
        return response()->json([
            'success' => true,
            'message' => 'Detail AR model berhasil diambil',
            'data' => $arModel,
        ]);
    }

    public function markerByModel(ArModel $arModel): JsonResponse
    {
        $markers = $arModel->markers()->where('status', 'active')->get();
        return response()->json([
            'success' => true,
            'message' => 'Marker untuk model berhasil diambil',
            'data' => $markers,
        ]);
    }
}
