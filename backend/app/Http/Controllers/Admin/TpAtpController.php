<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\TpAtp;
use Illuminate\Http\Request;

class TpAtpController extends Controller
{
    public function index(Request $request)
    {
        $query = TpAtp::withCount('materi');

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('kode', 'like', "%{$search}%")
                  ->orWhere('judul', 'like', "%{$search}%")
                  ->orWhere('elemen', 'like', "%{$search}%");
            });
        }

        if ($request->filled('fase')) {
            $query->where('fase', $request->fase);
        }

        $tpAtps = $query->orderBy('order')->paginate(15)->withQueryString();
        return view('admin.tp-atp.index', compact('tpAtps'));
    }

    public function create()
    {
        return view('admin.tp-atp.create');
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
        $validated['is_active'] = $validated['is_active'] ?? true;

        $tpAtp = TpAtp::create($validated);

        \App\Services\ActivityLogger::created('tp_atp', $tpAtp->id, "TP/ATP '{$validated['judul']}' created via admin");

        return redirect()->route('admin.tp-atp.index')->with('success', 'TP/ATP berhasil ditambahkan.');
    }

    public function edit(TpAtp $tpAtp)
    {
        return view('admin.tp-atp.edit', compact('tpAtp'));
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

        \App\Services\ActivityLogger::updated('tp_atp', $tpAtp->id, "TP/ATP '{$tpAtp->judul}' updated via admin");

        return redirect()->route('admin.tp-atp.index')->with('success', 'TP/ATP berhasil diperbarui.');
    }

    public function destroy(TpAtp $tpAtp)
    {
        \App\Services\ActivityLogger::deleted('tp_atp', $tpAtp->id, "TP/ATP '{$tpAtp->judul}' deleted via admin");
        $tpAtp->delete();

        return redirect()->route('admin.tp-atp.index')->with('success', 'TP/ATP berhasil dihapus.');
    }
}
