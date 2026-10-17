# HireWise

HireWise is a Jac driver decision workspace and passenger route-request prototype. **All fares, offers, zone distances, demand values, route ETAs, and weather/time-band effects are simulated.** TomTom's basemap is live only when `MAPS_API_KEYS` is configured; route options and quoted estimates remain illustrative. Browser location is opt-in and controlled by the device/browser.

## Jac features

- Jac graph `node` archetypes store per-account driver setup, zones, offers, and decisions. Passenger requests are limited trip-detail records in the shared graph; passenger identity/contact data is never published to drivers.
- Authenticated Jac functions isolate private profiles and driver state by user's graph. Ride-request records are explicitly granted read-only visibility to authenticated drivers.
- Deterministic Jac functions calculate estimated vehicle costs, offer net, deadline feasibility, simulated scenario impacts, and route estimates. `by llm` parses shift-goal text, writes short offer explanations, and gives brief passenger route descriptions; the LLM does not calculate fares or recommendations.
- The Jac client provides account capture, role-based Driver/Passenger destinations, a driver offer workspace, the passenger route comparison screen, and the TomTom map with opt-in browser geolocation.
- Jac's built-in authentication manages passwords; the app stores no passwords.

## Try it

1. Add `MAPS_API_KEYS` and `GEMINI_API_KEY` in JacHammer Settings. The TomTom basemap requires the first; `by llm` explanations/goals require the second.
2. Sign up at `/account` as Driver or Passenger. Existing accounts created before role selection default to Driver; new Passenger accounts are labeled at signup.
3. Driver: inspect Sri Lanka zones and sample offers, try the Clear/Rain and time-band what-if, and review incoming passenger requests.
4. Passenger: choose two Sri Lanka zones and a time band, compare all three simulated route options with displayed fares and ETAs, then request a ride.
5. Rain scenario is explicitly a simulation assumption of a 1.25 traffic multiplier. No live weather feed or real traffic conditions are represented.

## Admin account

Jac's built-in platform admin is provisioned by the server/bootstrap environment; it is not a HireWise Driver or Passenger role and cannot be reached by choosing either role on the public sign-in page. Use the JacHammer platform's administrator-provided credentials and the platform admin interface at `/admin` (on the app host) only if your account is provisioned as a platform administrator. Do not guess or reuse a driver account as an admin. If you do not have admin credentials, ask the JacHammer project/platform owner to provision or reset an admin account through the secure platform process. No admin password is stored in this repository.

## Scope

Sri Lanka is the active simulated region. The UK/USA selector values remain visible for continuity, but their datasets/routes are paused. Optional voice commands were not included. Passenger estimates are not booking guarantees or live route guidance; drivers make final accept/decline decisions and the app does not encourage cancelling accepted rides.
