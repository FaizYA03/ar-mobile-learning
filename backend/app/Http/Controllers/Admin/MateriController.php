<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Materi;
use App\Models\TpAtp;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class MateriController extends Controller
{
    public function index(Request $request)
    {
        $query = Materi::with(['tpAtp:id,kode,judul', 'arModel:id,model_name']);

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('judul', 'like', "%{$search}%")
                  ->orWhere('ringkasan', 'like', "%{$search}%");
            });
        }

        if ($request->filled('tp_atp_id')) {
            $query->where('tp_atp_id', $request->tp_atp_id);
        }

        $materi = $query->orderBy('order')->paginate(15)->withQueryString();
        $tpAtps = TpAtp::orderBy('order')->get();

        return view('admin.materi.index', compact('materi', 'tpAtps'));
    }

    public function create()
    {
        $tpAtps = TpAtp::orderBy('order')->get();
        return view('admin.materi.create', compact('tpAtps'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'tp_atp_id' => 'required|exists:tp_atp,id',
            'judul' => 'required|string|max:255',
            'ringkasan' => 'nullable|string',
            'konten' => 'required|string',
            'estimasi_menit' => 'nullable|integer|min:1',
            'is_published' => 'nullable|boolean',
            'gambar_cover' => 'nullable|image|max:5120',
        ]);

        $validated['slug'] = Str::slug($validated['judul']) . '-' . Str::random(5);
        $validated['order'] = Materi::where('tp_atp_id', $validated['tp_atp_id'])->max('order') + 1 ?? 1;
        $validated['is_published'] = $validated['is_published'] ?? true;

        if ($request->hasFile('gambar_cover')) {
            $validated['gambar_cover'] = $request->file('gambar_cover')->store('covers', 'public');
        }

        Materi::create($validated);

        \App\Services\ActivityLogger::created('materi', null, "Materi '{$validated['judul']}' created via admin");

        return redirect()->route('admin.materi.index')->with('success', 'Materi berhasil ditambahkan.');
    }

    public function edit(Materi $materi)
    {
        $tpAtps = TpAtp::orderBy('order')->get();
        return view('admin.materi.edit', compact('materi', 'tpAtps'));
    }

    public function update(Request $request, Materi $materi)
    {
        $validated = $request->validate([
            'tp_atp_id' => 'sometimes|exists:tp_atp,id',
            'judul' => 'sometimes|string|max:255',
            'ringkasan' => 'nullable|string',
            'konten' => 'sometimes|string',
            'estimasi_menit' => 'nullable|integer|min:1',
            'is_published' => 'nullable|boolean',
            'gambar_cover' => 'nullable|image|max:5120',
        ]);

        if (isset($validated['judul'])) {
            $validated['slug'] = Str::slug($validated['judul']) . '-' . Str::random(5);
        }

        if ($request->hasFile('gambar_cover')) {
            if ($materi->gambar_cover && Storage::disk('public')->exists($materi->gambar_cover)) {
                Storage::disk('public')->delete($materi->gambar_cover);
            }
            $validated['gambar_cover'] = $request->file('gambar_cover')->store('covers', 'public');
        }

        $materi->update($validated);

        \App\Services\ActivityLogger::updated('materi', $materi->id, "Materi '{$materi->judul}' updated via admin");

        return redirect()->route('admin.materi.index')->with('success', 'Materi berhasil diperbarui.');
    }

    public function destroy(Materi $materi)
    {
        if ($materi->gambar_cover && Storage::disk('public')->exists($materi->gambar_cover)) {
            Storage::disk('public')->delete($materi->gambar_cover);
        }

        \App\Services\ActivityLogger::deleted('materi', $materi->id, "Materi '{$materi->judul}' deleted via admin");
        $materi->delete();

        return redirect()->route('admin.materi.index')->with('success', 'Materi berhasil dihapus.');
    }
}
