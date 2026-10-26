<?php

namespace App\Policies;

use App\Models\ArHotspot;
use App\Models\User;
use App\Policies\Concerns\ChecksContentOwnership;

class ArHotspotPolicy
{
    use ChecksContentOwnership;

    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, ArHotspot $arHotspot): bool
    {
        return true;
    }

    public function create(User $user): bool
    {
        return in_array($user->role, ['guru', 'admin'], true);
    }

    public function update(User $user, ArHotspot $arHotspot): bool
    {
        return $this->canManage($user, $arHotspot->arModel?->created_by);
    }

    public function delete(User $user, ArHotspot $arHotspot): bool
    {
        return $this->canManage($user, $arHotspot->arModel?->created_by);
    }
}
