<?php

namespace App\Http\Controllers;

use App\Models\TpAtp;
use App\Services\ActivityLogger;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class TpAtpController extends Controller
{
    public function index(Request $request)
    {
        $query = TpAtp::withCount('materi')->orderBy('order', 'asc');

        if (!$request->user() || $request->user()->role === 'siswa') {
            $query->where('is_active', true);
        }

        $tpAtp = $query->get();

        return response()->json([
            'success' => true,
            'data' => $tpAtp,
        ]);
    }

    public function show(Request $request, TpAtp $tpAtp)
    {
        $tpAtp->load(['materi' => function ($q) use ($request) {
            if (!$request->user() || $request->user()->role === 'siswa') {
                $q->where('is_published', true);
            }
            $q->orderBy('order', 'asc');
        }]);

        return response()->json([
            'success' => true,
            'data' => $tpAtp,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'kode' => 'required|string|max:50|unique:tp_atp,kode',
            'fase' => 'required|string|max:10',
            'elemen' => 'required|string|max:100',
            'judul' => 'required|string|max:255',
            'deskripsi' => 'nullable|string',
            'order' => 'nullable|integer',
            'is_active' => 'nullable|boolean',
        ]);

        if (!isset($validated['order'])) {
            $validated['order'] = (TpAtp::max('order') ?? 0) + 1;
        }

        $tpAtp = TpAtp::create($validated);

        ActivityLogger::created('tp_atp', $tpAtp->id, "TP/ATP '{$tpAtp->judul}' created");

        return response()->json([
            'success' => true,
            'message' => 'TP/ATP berhasil dibuat',
            'data' => $tpAtp,
        ], 201);
    }

    public function update(Request $request, TpAtp $tpAtp)
    {
        $validated = $request->validate([
            'kode' => 'sometimes|string|max:50|unique:tp_atp,kode,' . $tpAtp->id,
            'fase' => 'sometimes|string|max:10',
            'elemen' => 'sometimes|string|max:100',
            'judul' => 'sometimes|string|max:255',
            'deskripsi' => 'nullable|string',
            'order' => 'nullable|integer',
            'is_active' => 'nullable|boolean',
        ]);

        $tpAtp->update($validated);

        ActivityLogger::updated('tp_atp', $tpAtp->id, "TP/ATP '{$tpAtp->judul}' updated");

        return response()->json([
            'success' => true,
            'message' => 'TP/ATP berhasil diperbarui',
            'data' => $tpAtp,
        ]);
    }

    public function destroy(TpAtp $tpAtp)
    {
        ActivityLogger::deleted('tp_atp', $tpAtp->id, "TP/ATP '{$tpAtp->judul}' deleted");
        $tpAtp->delete();

        return response()->json([
            'success' => true,
            'message' => 'TP/ATP berhasil dihapus',
        ]);
    }
}
