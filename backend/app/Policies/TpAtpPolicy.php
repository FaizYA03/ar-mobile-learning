<?php

namespace App\Policies;

use App\Models\TpAtp;
use App\Models\User;
use App\Policies\Concerns\ChecksContentOwnership;

class TpAtpPolicy
{
    use ChecksContentOwnership;

    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, TpAtp $tpAtp): bool
    {
        return $user->role !== 'siswa' || $tpAtp->is_active;
    }

    public function create(User $user): bool
    {
        return in_array($user->role, ['guru', 'admin'], true);
    }

    public function update(User $user, TpAtp $tpAtp): bool
    {
        return $this->canManage($user, $tpAtp->created_by);
    }

    public function delete(User $user, TpAtp $tpAtp): bool
    {
        return $this->canManage($user, $tpAtp->created_by);
    }
}
