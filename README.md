# HireWise

HireWise is a Jac driver decision workspace. Phase 1 includes driver accounts and simulated offers across Sri Lanka, the UK and the USA. **All ride offers, fares, demand, route distances, traffic multipliers, and displayed driver position are simulated.** The map is an in-app schematic, not a live map.

## Accounts and privacy

- Drivers register with email, phone and a password they choose. Passwords are handled by Jac's built-in authentication; HireWise does not store passwords in its graph.
- Driver profile and shift data are stored on the authenticated user's isolated Jac graph.
- The admin account is provisioned separately; admin analytics is a later phase.

## Regions

Region selector: Sri Lanka (LKR/km), United Kingdom (GBP/miles), United States (USD/miles). Offers, zones, illustrative energy prices, time-zone labels and maps are regional simulations. No live geolocation or tracking is enabled in Phase 1.

## AI

Goal parsing and concise offer explanations use Jac `by llm` with `gemini/gemini-3.8-flash`. Add `GEMINI_API_KEY` through JacHammer Settings. Deterministic Jac code calculates vehicle energy cost, offer net, return-ride potential, deadline feasibility and shift comparison. AI does not calculate recommendations.

## Later approved phases

TomTom Maps SDK, live traffic-aware routes and opt-in location tracking are later work; use `TOMTOM_API_KEY` in JacHammer Settings when that phase begins. Traffic-history uploads or a prediction API, admin analytics, and a driver-help chatbot also remain later phases. Prediction accuracy will not be claimed until its data source is supplied and validated.

## Model assumptions

All fares, offers, energy prices, demand and route samples are illustrative, not real market facts. Drivers make final accept/decline decisions. The naive comparison chooses highest fare first and skips only if projected return home misses the configured deadline. HireWise does not recommend declining solely due to traffic or encourage cancelling accepted rides.
