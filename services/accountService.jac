node DriverProfile {
    has email: str = "";
    has phone: str = "";
    has role: str = "driver";
}

obj DriverProfileView {
    has email: str;
    has phone: str;
    has role: str;
}

# User profile and role are stored only under the authenticated user's private root.
def:protect saveDriverProfile(email: str, phone: str, role: str = "driver") -> DriverProfileView {
    if not email.strip() or (role != "driver" and role != "passenger") { raise ValueError("Email and a valid account role are required."); }
    profiles = [root -->][?:DriverProfile];
    profile = profiles[0] if len(profiles) > 0 else (root ++> DriverProfile());
    profile.email = email.strip();
    profile.phone = phone.strip();
    profile.role = role;
    return DriverProfileView(email=profile.email, phone=profile.phone, role=profile.role);
}

def:protect getDriverProfile() -> DriverProfileView | None {
    profiles = [root -->][?:DriverProfile];
    if len(profiles) == 0 { return None; }
    return DriverProfileView(email=profiles[0].email, phone=profiles[0].phone, role=profiles[0].role);
}

def:protect getCurrentAccount() -> DriverProfileView | None {
    profiles = [root -->][?:DriverProfile];
    if len(profiles) == 0 { return None; }
    return DriverProfileView(email=profiles[0].email, phone=profiles[0].phone, role=profiles[0].role);
}
