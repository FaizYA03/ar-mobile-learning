<?php

namespace App\Http\Controllers;

use App\Http\Requests\MateriStoreRequest;
use App\Http\Requests\MateriUpdateRequest;
use App\Http\Resources\MateriResource;
use App\Http\Traits\ApiResponse;
use App\Models\Materi;
use App\Services\ActivityLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class MateriController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $query = Materi::with(['tpAtp:id,kode,fase,elemen,judul', 'arModel:id,model_name,thumbnail_path,glb_path'])
            ->orderBy('order', 'asc');

        if ($request->has('tp_atp_id')) {
            $query->where('tp_atp_id', $request->query('tp_atp_id'));
        }

        if (!$request->user() || $request->user()->role === 'siswa') {
            $query->where('is_published', true);
        }

        if ($perPage = $this->requestedPerPage($request)) {
            $paginator = $query->paginate($perPage);
            return $this->paginatedResources(
                $paginator,
                MateriResource::collection($paginator->items()),
                'Berhasil mengambil daftar materi'
            );
        }

        $materi = $query->get();

        return response()->json([
            'success' => true,
            'message' => 'Berhasil mengambil daftar materi',
            'data' => MateriResource::collection($materi),
        ]);
    }

    public function show(Request $request, Materi $materi): JsonResponse
    {
        $materi->load([
            'tpAtp',
            'arModel.hotspots',
            'quiz.questions',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Berhasil mengambil detail materi',
            'data' => new MateriResource($materi),
        ]);
    }

    public function store(MateriStoreRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $validated['slug'] = Str::slug($validated['judul']) . '-' . Str::random(5);

        if ($request->hasFile('gambar_cover')) {
            $path = $request->file('gambar_cover')->store('covers', 'public');
            $validated['gambar_cover'] = $path;
        } elseif (is_string($request->input('gambar_cover'))) {
            $validated['gambar_cover'] = $request->input('gambar_cover');
        }

        if (!isset($validated['order'])) {
            $maxOrder = Materi::where('tp_atp_id', $validated['tp_atp_id'])->max('order') ?? 0;
            $validated['order'] = $maxOrder + 1;
        }

        $materi = Materi::create($validated);
        $materi->load(['tpAtp', 'arModel']);

        ActivityLogger::created('materi', $materi->id, "Materi '{$materi->judul}' created");

        return response()->json([
            'success' => true,
            'message' => 'Materi berhasil dibuat',
            'data' => new MateriResource($materi),
        ], 201);
    }

    public function update(MateriUpdateRequest $request, Materi $materi): JsonResponse
    {
        $validated = $request->validated();

        if (isset($validated['judul'])) {
            $validated['slug'] = Str::slug($validated['judul']) . '-' . Str::random(5);
        }

        if ($request->hasFile('gambar_cover')) {
            if ($materi->gambar_cover && Storage::disk('public')->exists($materi->gambar_cover)) {
                Storage::disk('public')->delete($materi->gambar_cover);
            }
            $path = $request->file('gambar_cover')->store('covers', 'public');
            $validated['gambar_cover'] = $path;
        } elseif (is_string($request->input('gambar_cover'))) {
            $validated['gambar_cover'] = $request->input('gambar_cover');
        }

        $materi->update($validated);
        $materi->load(['tpAtp', 'arModel']);

        ActivityLogger::updated('materi', $materi->id, "Materi '{$materi->judul}' updated");

        return response()->json([
            'success' => true,
            'message' => 'Materi berhasil diperbarui',
            'data' => new MateriResource($materi),
        ]);
    }

    public function destroy(Materi $materi): JsonResponse
    {
        if ($materi->gambar_cover && Storage::disk('public')->exists($materi->gambar_cover)) {
            Storage::disk('public')->delete($materi->gambar_cover);
        }

        ActivityLogger::deleted('materi', $materi->id, "Materi '{$materi->judul}' deleted");

        $materi->delete();

        return response()->json([
            'success' => true,
            'message' => 'Materi berhasil dihapus',
        ]);
    }
}
