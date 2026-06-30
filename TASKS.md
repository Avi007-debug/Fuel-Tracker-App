# Activa Tracker — Development Tasks

> Smart Personal Vehicle Companion | For: Avishkar Anand  
> Platform: Android-first (Flutter) | AI Engine: Qwen2.5 0.5B (v2.0)

---

## Version 1.0 — Core Engine & Dashboard

### Phase 0: Foundation (Week 1–2) — ~19h
- [x] Flutter project init + pubspec setup [P0] (2h)
- [x] Define all 4 data models — VehicleProfile, Trip, FuelEntry, ServiceRecord [P0] (4h)
- [x] Setup Riverpod providers skeleton [P0] (3h)
- [x] 5-screen bottom nav shell with GoRouter [P0] (2h)
- [x] Onboarding flow UI + VehicleProfile save [P0] (5h)
- [x] Define route constants — College 7.2/8.4 km, Town 7.4 km, Short 2.0 km [P0] (1h)
- [x] Dark mode theme setup (ThemeData) [P1] (2h)

### Phase 1: Core Trip & Fuel Logging (Week 3–5) — ~43h
- [x] Quick action buttons (6 actions) on dashboard [P0] (4h)
- [x] Trip logging logic (all route types) [P0] (5h)
- [x] Custom ride bottom sheet (distance + note) [P0] (3h)
- [x] Trip history list + swipe-to-delete [P0] (6h)
- [x] Edit / delete / undo last trip [P1] (3h)
- [x] Fuel entry flow — Amount mode (₹) [P0] (4h)
- [x] Petrol price HTTP fetch + HTML parser [P0] (5h)
- [x] Fuel entry — manual price fallback UI [P0] (2h)
- [x] Fuel entry — Litres direct mode (bottom sheet) [P0] (2h)
- [x] Tank Full checkbox + flag in FuelEntry model [P1] (1h)
- [x] Attach receipt photo to fuel entry [P2] (3h)
- [x] Fuel entry history timeline view [P1] (4h)
- [x] Navigate to BP Makali (url_launcher) [P2] (1h)

### Phase 2: Analytics Engine (Week 6–8) — ~41h
- [x] Mileage calculation engine (per fill + rolling 5-fill avg) [P0] (5h)
- [x] Fuel remaining estimator (litres + km range) [P0] (4h)
- [x] Monthly expense forecaster [P0] (3h)
- [x] Day-of-week riding pattern analyser (8-week history) [P1] (4h)
- [x] Next refill predictor [P1] (3h)
- [x] Mileage drop detector (< 90% of 5-fill avg) [P0] (3h)
- [x] Trip anomaly detector (2× day-of-week avg) [P1] (2h)
- [x] Vehicle Health Score composite calculator [P1] (5h)
- [x] Service reminder engine (km tracking per 5 types) [P0] (4h)
- [x] Cost per km calculator [P0] (2h)
- [x] Petrol price trend & moving average [P1] (2h)
- [x] All Riverpod providers wired to analytics [P0] (4h)

### Phase 3: Dashboard & Charts (Week 9–10) — ~42h
- [x] AI Garage flagship greeting card [P0] (4h)
  - Greeting, expected commute (15.6 km weekdays), fuel remaining, range, month spend
- [x] Fuel gauge circular widget (color-coded levels) [P0] (3h)
- [x] Today's stats strip on dashboard [P0] (2h)
- [x] AI insight/suggestion card (rule-based) [P0] (4h)
- [x] Implement all 18 charts (fl_chart) [P0] (16h)
  - [x] Daily Distance (Line)
  - [x] Monthly Distance (Bar)
  - [x] Mileage Trend (Line)
  - [x] Fuel Consumption (Area)
  - [x] Petrol Price Trend (Line)
  - [x] Cost per km (Line)
  - [x] Monthly Fuel Spend (Bar)
  - [x] Fuel Tank Level (Gauge)
  - [x] Vehicle Health Score (Gauge)
  - [x] Route Distribution (Pie)
  - [x] Weekly Riding Pattern (Bar)
  - [x] Calendar Heatmap
  - [x] Cumulative Distance (Line)
  - [x] Fuel Economy Distribution (Histogram)
  - [x] Expense Breakdown (Pie)
  - [x] Refill History Timeline
  - [x] AI Insights Cards (grid)
  - [x] Monthly Expense Forecast (Area)
- [x] Vehicle Health Score gauge (categorised: Efficiency, Maintenance, Consistency) [P1] (3h)
- [x] Service status panel on Insights screen [P1] (3h)
- [x] Monthly summary card [P0] (2h)

### Phase 4: Notifications & Background (Week 11) — ~18h
- [x] Morning trip reminder (7:30 AM, weekdays, skip if logged) [P0] (3h)
- [x] Evening return reminder (6:00 PM) [P0] (2h)
- [x] Evening escalation (every 10 min until 10 PM) [P1] (3h)
- [x] Low fuel alert notification (range < 40 km) [P0] (2h)
- [x] Service due alerts (all 5 types) [P0] (3h)
- [x] Workmanager periodic analytics recalculation [P1] (3h)
- [x] Boot receiver (reschedule notifications on boot) [P1] (2h)

---

## Version 1.5 — Enhanced Intelligence & Polish

### Phase 5: Better Predictions & Enhanced AI Insights
- [ ] Predictive Fuel Timeline (visual day-by-day bar forecast) [P1]
- [ ] AI Confidence Score (percentage for mileage predictions) [P1]
- [ ] Advanced AI Insights (multi-line causes + recommendations) [P1]
- [ ] AI Timeline (Google Photos style milestones) [P1]
- [ ] Achievement System (1000 km, Best mileage, Lowest expense, 30-day streak) [P1]

### Phase 6: Advanced Analytics & Export
- [ ] Scatter plot: Petrol price vs cost per km [P2]
- [ ] Radar chart: Vehicle health metrics [P2]
- [ ] Sankey diagram: Fuel → Distance → Cost [P2]
- [ ] Stacked monthly comparison [P2]
- [ ] AI prediction overlay (actual vs predicted mileage) [P2]
- [ ] PDF monthly report (dart pdf library) [P1] (8h)
- [ ] CSV export (trips + fuel entries) [P1] (3h)
- [ ] Home screen widget (fuel + daily distance) [P1] (6h)
- [ ] Backup to JSON + restore flow [P1] (5h)
- [ ] Settings screen — full implementation (edit flows) [P0] (6h)
- [ ] Accessibility audit (font sizes, contrast) [P2] (3h)
- [ ] Full app dark mode polish pass [P1] (4h)
- [ ] Performance profiling (Dart DevTools) [P1] (3h)

---

## Version 2.0 — Conversational AI (Offline LLM)

### Phase 7: Offline LLM Integration (Week 12–13)
- [ ] Evaluate flutter_llm_inference vs ONNX Runtime Mobile [P0] (4h)
- [ ] Integrate chosen inference framework [P0] (6h)
- [ ] Model download manager (resumable, progress bar) [P0] (5h)
- [ ] Model cache + delete flow in Settings [P1] (2h)
- [ ] Context builder — serialize 30-day rider data [P0] (4h)
- [ ] System prompt engineering for Qwen2.5 [P0] (3h)

### Phase 8: Chat UI & Voice
- [ ] Full-screen chat overlay with message bubbles [P0] (5h)
- [ ] AI Assistant with Memory (session context preservation) [P0] (4h)
- [ ] AI Chat Suggestion chips (Avg Mileage, Fuel Left, Compare Months, etc.) [P1] (3h)
- [ ] Streaming token output in chat UI [P1] (4h)
- [ ] Voice queries (speech-to-text integration) [P1] (4h)
- [ ] Smart summaries generation via LLM [P1] (3h)
- [ ] Model loading state management (lazy load on open) [P1] (3h)
- [ ] Inference performance tuning (thread count, etc.) [P1] (3h)
- [ ] Memory leak audit (esp. LLM inference) [P0] (3h)
- [ ] Edge case testing (no data, etc.) [P0] (4h)
- [ ] APK build + signing + install on test device [P0] (2h)

---

## Route Reference

| Route | Distance | Description |
|-------|----------|-------------|
| College — Going | 7.2 km | Home → Madavara Metro |
| College — Return | 8.4 km | Madavara Metro → BP Pump → Home |
| Nearby Town | 7.4 km | One way |
| Short Ride | 2.0 km | One way |

## Vehicle Defaults

| Parameter | Value |
|-----------|-------|
| Vehicle | Honda Activa 6G |
| Tank Capacity | 5.3 L |
| Reserve | 0.8 L |
| Service Interval | 3,000 km |
| BP Pump | BP Makali |

## Priority Legend
- **P0** — Must have, app broken without it
- **P1** — Should have, significant feature
- **P2** — Nice to have, polish layer
