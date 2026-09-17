<?php

namespace App\Http\Controllers;

use App\Models\Materi;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class MateriController extends Controller
{
    public function index(Request $request)
    {
        $query = Materi::with(['tpAtp:id,kode,judul', 'arModel:id,model_name,thumbnail_path'])
            ->orderBy('order', 'asc');

        if ($request->has('tp_atp_id')) {
            $query->where('tp_atp_id', $request->query('tp_atp_id'));
        }

        if (!$request->user() || $request->user()->role === 'siswa') {
            $query->where('is_published', true);
        }

        $materi = $query->get();

        return response()->json([
            'success' => true,
            'data' => $materi,
        ]);
    }

    public function show(Request $request, Materi $materi)
    {
        $materi->load([
            'tpAtp',
            'arModel.hotspots',
        ]);

        return response()->json([
            'success' => true,
            'data' => $materi,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'tp_atp_id' => 'required|exists:tp_atp,id',
            'ar_model_id' => 'nullable|exists:ar_models,id',
            'judul' => 'required|string|max:255',
            'ringkasan' => 'nullable|string',
            'konten' => 'required|string',
            'estimasi_menit' => 'nullable|integer|min:1',
            'order' => 'nullable|integer',
            'is_published' => 'nullable|boolean',
            'gambar_cover' => 'nullable',
        ]);

        $validated['slug'] = Str::slug($validated['judul']) . '-' . Str::random(5);

        if ($request->hasFile('gambar_cover')) {
            $request->validate(['gambar_cover' => 'image|max:5120']);
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

        return response()->json([
            'success' => true,
            'message' => 'Materi berhasil dibuat',
            'data' => $materi,
        ], 201);
    }

    public function update(Request $request, Materi $materi)
    {
        $validated = $request->validate([
            'tp_atp_id' => 'sometimes|exists:tp_atp,id',
            'ar_model_id' => 'nullable|exists:ar_models,id',
            'judul' => 'sometimes|string|max:255',
            'ringkasan' => 'nullable|string',
            'konten' => 'sometimes|string',
            'estimasi_menit' => 'nullable|integer|min:1',
            'order' => 'nullable|integer',
            'is_published' => 'nullable|boolean',
            'gambar_cover' => 'nullable',
        ]);

        if (isset($validated['judul'])) {
            $validated['slug'] = Str::slug($validated['judul']) . '-' . Str::random(5);
        }

        if ($request->hasFile('gambar_cover')) {
            $request->validate(['gambar_cover' => 'image|max:5120']);
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

        return response()->json([
            'success' => true,
            'message' => 'Materi berhasil diperbarui',
            'data' => $materi,
        ]);
    }

    public function destroy(Materi $materi)
    {
        if ($materi->gambar_cover && Storage::disk('public')->exists($materi->gambar_cover)) {
            Storage::disk('public')->delete($materi->gambar_cover);
        }

        $materi->delete();

        return response()->json([
            'success' => true,
            'message' => 'Materi berhasil dihapus',
        ]);
    }
}
