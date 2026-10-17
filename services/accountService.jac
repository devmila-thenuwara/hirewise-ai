node DriverProfile {
    has email: str = "";
    has phone: str = "";
}

obj DriverProfileView {
    has email: str;
    has phone: str;
}

def:protect saveDriverProfile(email: str, phone: str) -> DriverProfileView {
    if not email.strip() or not phone.strip() {
        raise ValueError("Email and phone are required.");
    }
    profiles = [root -->][?:DriverProfile];
    profile = profiles[0] if len(profiles) > 0 else (root ++> DriverProfile());
    profile.email = email.strip();
    profile.phone = phone.strip();
    return DriverProfileView(email=profile.email, phone=profile.phone);
}

def:protect getDriverProfile() -> DriverProfileView | None {
    profiles = [root -->][?:DriverProfile];
    if len(profiles) == 0 { return None; }
    return DriverProfileView(email=profiles[0].email, phone=profiles[0].phone);
}
