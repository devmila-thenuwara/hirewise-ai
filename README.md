# HireWise

HireWise is a Jac driver decision workspace for Sri Lanka. The map, district positions, regional routes, demand, traffic, offers, fares, and driver movement are all simulated and clearly labelled. The app uses an interactive SVG island diagram, not Google Maps, GPS, or live traffic/provider services.

## Jac and Jaseci features

- **Graph nodes:** `Zone`, `RoadLink`, `DriverSetup`, `SimOffer`, and `DecisionRecord` model the simulated nationwide district network, road links, trips, setup, and driver activity.
- **Graph initialization:** the service idempotently adds simulated districts across Sri Lanka and their route links, including when an existing graph already contains the original city-area zones.
- **by llm:** `parseGoals` structures shift-goal text and `getOfferExplanation` explains deterministic evaluations using `gemini/gemini-3.8-flash`. Add `GEMINI_API_KEY` in JacHammer Settings. No key is in source.
- **Deterministic calculations:** petrol/EV energy cost per km, trip net, return potential, empty-return cost, deadline feasibility, and full-shift comparisons run in Jac code, not through the LLM.
- **Jac client:** select district points in the SVG map or district buttons, inspect the simulated region/demand, review offer alternatives, and see the simulated marker at the current position. Accepting an offer updates the tracker to its destination.
- **Authentication:** not included in Phase 1.

## Simulation notice

District placement is schematic and not geospatially precise. Routes, road lengths, traffic multipliers, demand scores, sample offers, energy prices, and tracker movement are illustrative. Do not use as real navigation, fare guidance, traffic prediction, or safety advice. The driver makes the final choice. No live maps, GPS, external provider, or real-time prediction feed is integrated.
