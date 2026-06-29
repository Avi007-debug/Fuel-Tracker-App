# Activa Tracker - Implementation Tasks

## Version 1.0 - Core Engine & Dashboard
### Phase 0: Foundation
- [ ] Flutter project init + pubspec setup (P0)
- [ ] Configure Isar + define core models (VehicleProfile, Trip, FuelEntry, ServiceRecord) (P0)
- [ ] Setup Riverpod providers skeleton (P0)
- [ ] 5-screen bottom nav shell (P0)
- [ ] Onboarding flow UI + VehicleProfile save (P0)
- [ ] Define route constants (P0)
- [ ] Dark mode theme setup (P1)

### Phase 1: Core Trip & Fuel Logging
- [ ] Quick action buttons on dashboard (P0)
- [ ] Trip logging logic (P0)
- [ ] Custom ride bottom sheet (P0)
- [ ] Trip history list + filters (P0)
- [ ] Edit / delete / undo last trip (P1)
- [ ] Fuel entry flow (₹ and Litres) (P0)
- [ ] Petrol price HTTP fetch + parser (P0)
- [ ] Fuel entry history timeline (P1)
- [ ] Attach receipt photo to fuel entry (P2)
- [ ] Navigate to BP Makali via url_launcher (P2)

### Phase 2: Analytics Engine (Rule-based)
- [ ] Mileage calculation engine (P0)
- [ ] Monthly expense forecaster (P0)
- [ ] Day-of-week riding pattern analyser (P1)
- [ ] Next refill predictor (P1)
- [ ] Mileage drop detector & trip anomaly detector (P1)
- [ ] Cost per km calculator & price trend (P1)
- [ ] Service reminder engine (P0)

### Phase 3: Dashboard (AI Garage) & Graphs
- [ ] AI Garage flagship greeting card (Expected commute, range, weather, expected fuel) (P0)
- [ ] Predictive Fuel Timeline (Visual timeline instead of raw L) (P1)
- [ ] Vehicle Health Dashboard (Categorized: Fuel Efficiency, Maintenance, Consistency, Service, Tyres) (P0)
- [ ] Achievement System UI & Engine (1000 km, Best mileage, Lowest expense, 30-day streak) (P1)
- [ ] Today's stats strip (P0)
- [ ] Implement core charts (Line, Bar, Area, Pie) (P0)

### Phase 4: Notifications & Background Tasks
- [ ] Morning trip reminder & Evening return reminder (P0)
- [ ] Low fuel alert & Service due alerts (P0)
- [ ] Workmanager periodic analytics recalculation (P1)
- [ ] Boot receiver for rescheduling (P1)

---

## Version 1.5 - Enhanced Intelligence & Polish
### Phase 5: Better Predictions & Enhanced AI Insights
- [ ] Better prediction engine (Enhanced accuracy) (P1)
- [ ] AI Confidence Score (percentage for predictions) (P1)
- [ ] Advanced AI Insights (Multi-line causes and recommendations) (P1)
- [ ] AI Timeline (Google Photos style milestones/memories) (P1)

### Phase 6: Advanced Analytics & Polish
- [ ] Scatter plot: Petrol price vs cost per km (P2)
- [ ] Radar chart: Vehicle health metrics (P2)
- [ ] Sankey diagram: Fuel → Distance → Cost (P2)
- [ ] Stacked monthly comparison (P2)
- [ ] AI prediction overlay (actual vs predicted mileage) (P2)
- [ ] PDF monthly report & CSV export (P1)
- [ ] Home screen widget (P1)
- [ ] Full app polish, accessibility, profiling (P1)

---

## Version 2.0 - Conversational AI (Offline LLM)
### Phase 7: Offline LLM Integration
- [ ] Integrate flutter_llm_inference / ONNX Runtime (P0)
- [ ] Model download manager (GGUF Q4_K_M) (P0)
- [ ] Context builder (Serialize 30-day rider data) (P0)
- [ ] System prompt engineering (P0)

### Phase 8: Chat UI & Voice
- [ ] Full-screen chat overlay UI (P0)
- [ ] AI Assistant with Memory (Session context preservation) (P0)
- [ ] AI Chat Suggestions (Chips: Avg Mileage, Fuel Left, Compare Months, etc.) (P1)
- [ ] Voice queries integration (Speech-to-text) (P1)
- [ ] Smart summaries generation via LLM (P1)
