<?php

namespace App\Policies;

use App\Models\ArMarker;
use App\Models\User;
use App\Policies\Concerns\ChecksContentOwnership;

class ArMarkerPolicy
{
    use ChecksContentOwnership;

    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, ArMarker $arMarker): bool
    {
        return true;
    }

    public function create(User $user): bool
    {
        return in_array($user->role, ['guru', 'admin'], true);
    }

    public function update(User $user, ArMarker $arMarker): bool
    {
        return $this->canManage($user, $arMarker->created_by);
    }

    public function delete(User $user, ArMarker $arMarker): bool
    {
        return $this->canManage($user, $arMarker->created_by);
    }
}
