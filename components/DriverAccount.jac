sv import from ..services.accountService { saveDriverProfile, getCurrentAccount, DriverProfileView }
import from .ui.button { Button }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.input { Input }
import from .ui.badge { Badge }
import from "@jac/runtime" { jacLogin, jacSignup, jacIsLoggedIn, useNavigate }

def:pub DriverAccount() -> JsxElement {
    has email: str = "";
    has phone: str = "";
    has password: str = "";
    has mode: str = "login";
    has role: str = "driver";
    has error_message: str = "";
    has loading: bool = False;
    nav = useNavigate();

    def handle_email(e: ChangeEvent) { email = e.target.value; }
    def handle_phone(e: ChangeEvent) { phone = e.target.value; }
    def handle_password(e: ChangeEvent) { password = e.target.value; }
    def handle_role(e: ChangeEvent) { role = e.target.value; }
    def toggle_mode(e: MouseEvent) { mode = "signup" if mode == "login" else "login"; error_message = ""; }

    async def destination -> None {
        account: DriverProfileView | None = None;
        try {
            account = await getCurrentAccount();
            nav("/passenger" if account is not None and account.role == "passenger" else "/");
        } except Exception { nav("/"); }
    }

    async def handle_login -> None {
        if mode == "signup" { await handle_signup(); return; }
        loading = True; error_message = "";
        ok: bool = False;
        try {
            ok = await jacLogin(email, password);
            if ok { await destination(); }
            else { error_message = "Sign-in failed. Check your email and password."; }
        } except Exception { error_message = "Sign-in failed. Check your details and try again."; }
        loading = False;
    }

    async def handle_signup -> None {
        loading = True; error_message = "";
        signup_result: dict | None = None;
        login_ok: bool = False;
        profile_result: DriverProfileView | None = None;
        try {
            if not email.strip() or (role == "driver" and not phone.strip()) or len(password) < 8 {
                error_message = "Enter a valid email, required contact details, and a password of at least 8 characters.";
                loading = False; return;
            }
            signup_result = await jacSignup(email, password);
            if not (signup_result["success"] as bool) { error_message = str(signup_result["error"] or "Account registration failed."); loading = False; return; }
            login_ok = await jacLogin(email, password);
            if not login_ok { error_message = "Account created. Sign in with your new password to continue."; mode = "login"; loading = False; return; }
            profile_result = await saveDriverProfile(email, phone, role);
            await destination();
        } except Exception { error_message = "Could not complete registration. If the account already exists, sign in instead."; }
        loading = False;
    }

    async can with entry {
        if jacIsLoggedIn() { await destination(); }
    }

    title_text = "Welcome back" if mode == "login" else ("Create a driver account" if role == "driver" else "Create a passenger account");
    subtitle_text = "Sign in to continue." if mode == "login" else "Your password is handled by Jac authentication.";
    password_hint = "Your password" if mode == "login" else "At least 8 characters";
    submit_text = "Sign in" if mode == "login" else "Create account";
    switch_text = "New to HireWise? Create an account" if mode == "login" else "Already registered? Sign in";

    return <main className="relative isolate flex min-h-svh w-full items-center justify-center overflow-hidden bg-slate-950 px-4 py-8 text-white sm:px-8">
        <div className="absolute inset-0 -z-20 bg-[linear-gradient(180deg,#728a9a_0%,#566c7d_28%,#334859_51%,#152938_72%,#07141f_100%)]" />
        <div className="absolute inset-0 -z-10 bg-[radial-gradient(ellipse_at_52%_34%,rgba(244,172,137,0.30),transparent_34%),linear-gradient(90deg,rgba(3,12,21,0.62),transparent_58%,rgba(3,12,21,0.18))]" />
        <div className="absolute left-5 top-5 flex items-center gap-3 sm:left-8 sm:top-7"><div className="flex size-11 items-center justify-center rounded-2xl border border-white/35 bg-white/15 text-lg font-bold backdrop-blur-xl">H</div><div><p className="text-lg font-semibold">HireWise</p><p className="text-xs text-white/70">Sri Lanka trip and shift planning</p></div></div>
        <div className="relative z-10 grid w-full max-w-6xl items-center gap-10 pt-16 lg:grid-cols-[1.1fr_0.9fr] lg:pt-0">
            <section className="hidden max-w-xl flex-col gap-6 text-white lg:flex"><h1 className="text-balance text-5xl font-semibold leading-tight tracking-tight">Find a better way through every shift.</h1><p className="max-w-lg text-lg leading-relaxed text-white/75">Plan around costs and deadlines, or compare a ride before requesting.</p><p className="text-sm text-white/60">All offers, routes, prices, and traffic scenarios are simulated.</p></section>
            <Card className="mx-auto w-full max-w-md overflow-hidden rounded-3xl border border-white/35 bg-white/15 text-white shadow-[0_28px_90px_rgba(4,12,22,0.42)] backdrop-blur-2xl">
                <CardHeader className="gap-2 px-7 pt-7 sm:px-8"><div className="mb-2"><Badge variant="secondary">Simulated data</Badge></div><CardTitle className="text-2xl font-semibold text-white">{title_text}</CardTitle><CardDescription className="text-white/70">{subtitle_text}</CardDescription></CardHeader>
                <CardContent className="flex flex-col gap-4 px-7 pb-7 sm:px-8">
                    {error_message and <p role="alert" className="rounded-xl border border-red-200/35 bg-red-950/35 px-4 py-3 text-sm">{error_message}</p>}
                    {mode == "signup" and <label className="flex flex-col gap-1.5 text-sm">Account type<select value={role} onChange={handle_role} className="h-11 rounded-xl border border-white/30 bg-slate-950/30 px-3 text-white"><option value="driver">Driver</option><option value="passenger">Passenger</option></select></label>}
                    <label className="flex flex-col gap-1.5 text-sm">Email<Input type="email" autoComplete="email" placeholder="you@example.com" value={email} onChange={handle_email} className="h-11 rounded-xl border-white/30 bg-slate-950/20 text-white placeholder:text-white/45"/></label>
                    {mode == "signup" and role == "driver" and <label className="flex flex-col gap-1.5 text-sm">Phone number<Input type="tel" autoComplete="tel" placeholder="Your phone number" value={phone} onChange={handle_phone} className="h-11 rounded-xl border-white/30 bg-slate-950/20 text-white placeholder:text-white/45"/></label>}
                    <label className="flex flex-col gap-1.5 text-sm">Password<Input type="password" autoComplete="current-password" placeholder={password_hint} value={password} onChange={handle_password} className="h-11 rounded-xl border-white/30 bg-slate-950/20 text-white placeholder:text-white/45"/></label>
                    <Button disabled={loading} className="h-11 w-full" onClick={handle_login}>{submit_text}</Button><button type="button" className="py-1 text-sm text-white/85 underline-offset-4 hover:underline" onClick={toggle_mode}>{switch_text}</button>
                    <p className="border-t border-white/20 pt-4 text-xs leading-relaxed text-white/60">Jac’s built-in authentication manages passwords. Driver and passenger profiles remain private to their own accounts. UK/USA data development is paused.</p>
                </CardContent>
            </Card>
        </div>
    </main>;
}
