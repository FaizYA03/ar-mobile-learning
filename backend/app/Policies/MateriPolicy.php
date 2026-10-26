<?php

namespace App\Policies;

use App\Models\Materi;
use App\Models\User;
use App\Policies\Concerns\ChecksContentOwnership;

class MateriPolicy
{
    use ChecksContentOwnership;

    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, Materi $materi): bool
    {
        return $user->role !== 'siswa' || $materi->is_published;
    }

    public function create(User $user): bool
    {
        return in_array($user->role, ['guru', 'admin'], true);
    }

    public function update(User $user, Materi $materi): bool
    {
        return $this->canManage($user, $materi->created_by);
    }

    public function delete(User $user, Materi $materi): bool
    {
        return $this->canManage($user, $materi->created_by);
    }
}
