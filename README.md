# HireWise

HireWise is a Sri Lanka driver decision workspace built in Jac. All zone, road, demand, fare, traffic, time and energy-price examples are simulated. The app does not connect to live maps, traffic services, or ride providers.

## Jac and Jaseci features

- **Nodes and graph:** `Zone`, `RoadLink`, `DriverSetup`, `SimOffer`, and `DecisionRecord` are Jac graph nodes attached to the request root. `SeedWorkspace` initializes the illustrative Sri Lanka dataset.
- **Walker:** `SeedWorkspace` is a graph walker that seeds zones, road links, and sample offers once.
- **by llm:** `parseGoals` structures driver goal text and `getOfferExplanation` phrases deterministic recommendation results. The model is `gemini/gemini-3.8-flash`; supply the key as `GEMINI_API_KEY` in the JacHammer Settings environment panel. No API key is embedded in source.
- **Deterministic calculations:** Energy cost per kilometre, trip net, return-ride potential, empty-return expense, deadline feasibility, and shift simulation are computed by Jac code, not by the LLM.
- **Client frontend:** A Jac component provides editable goals, petrol/EV calibration, profit/shortest-ETA preference, an SVG zone graph, offer decisions, tracker, and full-shift comparison.
- **Authentication:** Not included in Phase 1.

## Launch

The JacHammer preview runs the project. Add `GEMINI_API_KEY` in JacHammer Settings and restart the preview to enable Gemini goal parsing and explanations. Manual goal editing and deterministic offer decisions remain usable without the key.

## Model assumptions

Values are illustrative simulated assumptions, not actual fuel/electricity prices, fares, road conditions, demand probabilities, or travel-time promises. The driver makes all final accept/decline choices. The naive comparison selects highest fare first and skips only when its simulated return-to-home estimate misses the deadline. HireWise never advises declining solely because of traffic or cancelling an accepted trip.
