const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  HeadingLevel, AlignmentType, BorderStyle, WidthType, ShadingType,
  LevelFormat, PageBreak, PageNumber, NumberFormat
} = require('docx');
const fs = require('fs');

// ─── COLOURS ───────────────────────────────────────────────────────────────
const C = {
  accent: "1A1A2E",   // deep navy
  accent2: "16213E",
  green: "0F7A55",
  orange: "D4641A",
  purple: "5B2D8E",
  blue: "1565C0",
  lightBg: "F0F4FF",
  headerBg: "1A1A2E",
  altRow: "F5F7FF",
  border: "CBD5E1",
  white: "FFFFFF",
  text: "1E293B",
  muted: "64748B",
};

// ─── HELPERS ───────────────────────────────────────────────────────────────
const border = (color = C.border) => ({ style: BorderStyle.SINGLE, size: 1, color });
const borders = (color = C.border) => ({ top: border(color), bottom: border(color), left: border(color), right: border(color) });
const noBorder = () => ({ style: BorderStyle.NONE, size: 0, color: "FFFFFF" });
const noBorders = () => ({ top: noBorder(), bottom: noBorder(), left: noBorder(), right: noBorder() });

const sp = (before = 0, after = 0) => ({ spacing: { before, after } });

const h1 = (text) => new Paragraph({
  heading: HeadingLevel.HEADING_1,
  children: [new TextRun({ text, bold: true, size: 36, color: C.white, font: "Arial" })],
  shading: { fill: C.headerBg, type: ShadingType.CLEAR },
  spacing: { before: 360, after: 180 },
  indent: { left: 160 },
  border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: C.green, space: 1 } }
});

const h2 = (text, color = C.accent) => new Paragraph({
  heading: HeadingLevel.HEADING_2,
  children: [new TextRun({ text, bold: true, size: 28, color, font: "Arial" })],
  spacing: { before: 300, after: 120 },
  border: { bottom: { style: BorderStyle.SINGLE, size: 3, color, space: 1 } }
});

const h3 = (text, color = C.green) => new Paragraph({
  heading: HeadingLevel.HEADING_3,
  children: [new TextRun({ text, bold: true, size: 24, color, font: "Arial" })],
  spacing: { before: 200, after: 80 },
});

const body = (text, opts = {}) => new Paragraph({
  children: [new TextRun({ text, size: 22, color: C.text, font: "Arial", ...opts })],
  spacing: { before: 60, after: 60 },
});

const bullet = (text, bold = false, color = C.text) => new Paragraph({
  numbering: { reference: "bullets", level: 0 },
  children: [new TextRun({ text, size: 22, font: "Arial", bold, color })],
  spacing: { before: 40, after: 40 },
});

const sub_bullet = (text) => new Paragraph({
  numbering: { reference: "sub_bullets", level: 0 },
  children: [new TextRun({ text, size: 20, font: "Arial", color: C.muted })],
  spacing: { before: 20, after: 20 },
});

const pageBreak = () => new Paragraph({ children: [new PageBreak()] });

const badge = (label, fill, textColor = C.white) => new Paragraph({
  children: [new TextRun({
    text: `  ${label}  `, size: 18, bold: true, color: textColor, font: "Arial",
    shading: { fill, type: ShadingType.CLEAR }
  })],
  spacing: { before: 40, after: 40 },
});

// ─── TABLE HELPERS ─────────────────────────────────────────────────────────
const cell = (text, opts = {}) => {
  const { fill = C.white, bold = false, color = C.text, width = 2340, align = AlignmentType.LEFT, isHeader = false } = opts;
  return new TableCell({
    width: { size: width, type: WidthType.DXA },
    borders: borders(C.border),
    shading: { fill, type: ShadingType.CLEAR },
    margins: { top: 80, bottom: 80, left: 140, right: 140 },
    children: [new Paragraph({
      alignment: align,
      children: [new TextRun({ text, size: isHeader ? 20 : 20, bold: isHeader || bold, color, font: "Arial" })]
    })]
  });
};

const tableRow = (cells, isHeader = false) => new TableRow({
  tableHeader: isHeader,
  children: cells,
});

// ─── TECH STACK TABLE ──────────────────────────────────────────────────────
const makeTable = (headers, rows, colWidths) => {
  const totalWidth = colWidths.reduce((a, b) => a + b, 0);
  return new Table({
    width: { size: totalWidth, type: WidthType.DXA },
    columnWidths: colWidths,
    rows: [
      tableRow(headers.map((h, i) => cell(h, { fill: C.headerBg, bold: true, color: C.white, width: colWidths[i], isHeader: true })), true),
      ...rows.map((row, ri) => tableRow(row.map((t, i) => cell(t, { fill: ri % 2 === 0 ? C.white : C.altRow, width: colWidths[i] }))))
    ]
  });
};

// ─── TASK TABLE ────────────────────────────────────────────────────────────
const taskRow = (task, owner, priority, effort, deps) => new TableRow({
  children: [
    cell(task, { width: 3600, color: C.text }),
    cell(owner, { width: 1800, color: C.muted }),
    cell(priority, { width: 1440, color: priority === "P0" ? C.orange : priority === "P1" ? C.blue : C.muted, bold: priority === "P0" }),
    cell(effort, { width: 1200, color: C.text }),
    cell(deps, { width: 1320, color: C.muted }),
  ]
});

// ═══════════════════════════════════════════════════════════════════════════
// DOCUMENT BUILD
// ═══════════════════════════════════════════════════════════════════════════
const children = [];

// ─── COVER ─────────────────────────────────────────────────────────────────
children.push(
  new Paragraph({ spacing: { before: 1200, after: 200 } }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "🏍  Activa Tracker", size: 60, bold: true, color: C.accent, font: "Arial" })],
    spacing: { before: 0, after: 160 },
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "Smart Personal Vehicle Companion", size: 32, color: C.green, font: "Arial", italics: true })],
    spacing: { before: 0, after: 80 },
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "Complete Product Specification & Implementation Plan", size: 24, color: C.muted, font: "Arial" })],
    spacing: { before: 0, after: 80 },
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: C.green, space: 1 } },
    children: [new TextRun({ text: " ", size: 24, font: "Arial" })],
    spacing: { before: 0, after: 400 },
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "For: Avishkar Anand  |  Platform: Android-first (Flutter)  |  Version: 1.0", size: 20, color: C.muted, font: "Arial" })],
    spacing: { before: 200, after: 80 },
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "AI Engine: Qwen2.5 0.5B Instruct (On-Device)  |  Target: Mid-range Android (6–8 GB RAM)", size: 20, color: C.muted, font: "Arial" })],
    spacing: { before: 0, after: 80 },
  }),
  pageBreak(),
);

// ─── 1. OVERVIEW ───────────────────────────────────────────────────────────
children.push(
  h1("1. Product Overview"),
  body("Activa Tracker is a fully offline, AI-enhanced personal vehicle companion built specifically for a single rider with fixed daily routes. The app requires near-zero manual input on most days (two taps for commute logging), while automatically computing fuel consumption, mileage, costs, service schedules, and personalized riding insights — all without any cloud dependency."),
  body(""),
  h2("1.1  Design Philosophy"),
  bullet("Offline-first: 100% of core features work without internet"),
  bullet("Minimal friction: daily use in ≤ 2 taps"),
  bullet("Personal, not generic: routes, reminders and AI context are pre-configured for the rider"),
  bullet("No account required, no data leaves the device"),
  bullet("AI is additive, not gating — the app is fully functional without LLM responses"),
  body(""),
  h2("1.2  Target Device"),
  makeTable(
    ["Parameter", "Specification"],
    [
      ["OS", "Android 10+ (API 29+); iOS future phase"],
      ["RAM", "6–8 GB (mid-range target)"],
      ["Storage budget (app)", "~60 MB APK + ~450 MB Qwen2.5 model (downloadable on first launch)"],
      ["Offline capability", "Full — including AI assistant"],
      ["Network use", "Petrol price fetch only (optional, fallback to manual)"],
    ],
    [4680, 4680]
  ),
  body(""),
  pageBreak(),
);

// ─── 2. COMPLETE FEATURE SET ────────────────────────────────────────────────
children.push(
  h1("2. Complete Feature Set"),
  body(""),

  h2("2.1  Onboarding & Vehicle Setup (One-Time)"),
  bullet("Vehicle name, model, registration number (optional)"),
  bullet("Fuel tank capacity (L) and reserve estimate (L)"),
  bullet("Initial odometer reading (optional)"),
  bullet("Service interval in km (default: 3,000 km)"),
  bullet("Route distances — pre-loaded with ability to edit:"),
  sub_bullet("College Route – Going: Home → Madavara Metro (7.2 km)"),
  sub_bullet("College Route – Return: Madavara Metro → BP Pump → Home (8.4 km)"),
  sub_bullet("Nearby Town – One way: 7.4 km"),
  sub_bullet("Short Ride – One way: 2 km"),
  bullet("Notification schedule preferences (morning: 7:30 AM, evening: 6:00 PM)"),
  body(""),

  h2("2.2  Trip Logging"),
  bullet("One-tap quick actions: Going to College, Returned Home, Nearby Town (Go/Return), Short Ride (Go/Return)"),
  bullet("Custom Ride — enter distance + optional reason/note"),
  bullet("Each trip records: timestamp, route type, distance, direction, optional notes"),
  bullet("Manual edit or undo of last entry"),
  bullet("Anomaly detection: flags trips significantly longer than usual pattern"),
  bullet("Calendar heatmap view (GitHub-style) — colour intensity = distance"),
  bullet("Full searchable/filterable ride history"),
  body(""),

  h2("2.3  Fuel Management"),
  bullet("One-tap fuel entry from dashboard"),
  bullet("Entry mode A: enter ₹ amount → app fetches live petrol price → auto-calculates litres"),
  bullet("Entry mode B: enter litres directly (from pump receipt)"),
  bullet("Fallback: if price fetch fails → prompt user to enter today's rate manually"),
  bullet("Optional: mark 'Tank Full' for high-accuracy mileage calculation"),
  bullet("Each refill records: date, amount (₹), litres, price/L, distance since last refill, calculated mileage, cost/km"),
  bullet("Full refill history timeline"),
  bullet("One-tap navigation to BP Makali via Google Maps / url_launcher"),
  body(""),

  h2("2.4  Fuel Level Estimation (Rule-Based Engine)"),
  bullet("Post-refill: estimated fuel = litres added − (distance × 1/mileage)"),
  bullet("Live display: Estimated Fuel Remaining (L) + Approx. km remaining"),
  bullet("Fuel gauge widget on dashboard and home screen widget"),
  bullet("Low fuel alert when estimated range < 40 km"),
  body(""),

  h2("2.5  Mileage Calculation Engine"),
  bullet("Calculated per refill interval: km_since_last_refill ÷ litres_added"),
  bullet("Running average (last 5 refills) for smoothed mileage display"),
  bullet("Mileage trend graph (per-refill line chart)"),
  bullet("Mileage drop detection: if current fill mileage < 90% of 5-fill average → AI flag"),
  body(""),

  h2("2.6  Dashboard — AI Garage Home Screen"),
  body("Every app open shows a personalized greeting card:"),
  bullet("Good Morning / Afternoon / Evening, Avishkar!"),
  bullet("Today's expected commute distance"),
  bullet("Estimated fuel remaining (L + km range)"),
  bullet("Projected petrol spend this month"),
  bullet("Month-over-month mileage delta (e.g., +2.1% better than last month)"),
  bullet("One proactive AI tip (tyre pressure, service due, fuel efficiency, etc.)"),
  body(""),
  body("Quick Action Buttons (always visible):"),
  bullet("🟢  Going to College"),
  bullet("🔵  Returned Home"),
  bullet("🟡  Fuel Filled"),
  bullet("🟣  Nearby Town (Going / Return sub-menu)"),
  bullet("⚪  Short Ride (Going / Return sub-menu)"),
  bullet("➕  Custom Ride"),
  body(""),

  h2("2.7  Analytics & Graphs (18 Visualizations)"),
  makeTable(
    ["#", "Chart", "Type", "What It Shows"],
    [
      ["1", "Daily Distance", "Line", "Distance logged each day"],
      ["2", "Monthly Distance", "Bar", "Month-wise comparison"],
      ["3", "Mileage Trend", "Line", "km/L per refill interval"],
      ["4", "Fuel Consumption", "Area", "Litres used over time"],
      ["5", "Petrol Price Trend", "Line", "₹/L at each refill"],
      ["6", "Cost per km", "Line", "Most useful efficiency graph"],
      ["7", "Monthly Fuel Spend", "Bar", "₹ total per month"],
      ["8", "Fuel Tank Level", "Gauge", "Current estimated fuel %"],
      ["9", "Vehicle Health Score", "Gauge", "Composite health score /100"],
      ["10", "Route Distribution", "Pie", "College / Town / Short / Custom split"],
      ["11", "Weekly Riding Pattern", "Bar", "Avg km by day of week (Mon–Sun)"],
      ["12", "Calendar Heatmap", "Heatmap", "GitHub-style, colour = daily km"],
      ["13", "Cumulative Distance", "Line", "Lifetime odometer progression"],
      ["14", "Fuel Economy Distribution", "Histogram", "Frequency of mileage ranges"],
      ["15", "Expense Breakdown", "Pie", "Cost split by trip type"],
      ["16", "Refill History Timeline", "Timeline", "Each refill event"],
      ["17", "AI Insights Cards", "Card grid", "Smart insight chips"],
      ["18", "Monthly Expense Forecast", "Area", "Projected vs actual spend"],
    ],
    [480, 2400, 1440, 5040]
  ),
  body(""),

  h2("2.8  Smart Statistics"),
  body("Daily Stats: morning distance, evening distance, other trips, total, fuel used, average mileage."),
  body("Monthly Stats: total distance, money spent, litres filled, average mileage, avg cost/km, trip count, refill count, longest ride, shortest ride."),
  body(""),

  h2("2.9  Smart Notifications"),
  bullet("Morning (7:30 AM): 'Going to college today? Tap to start your trip.' — only on weekdays, skips if trip already logged"),
  bullet("Evening (6:00 PM): if Going logged but Return not logged — 'Did you return home?'"),
  bullet("Evening escalation: repeats every 10 min if not dismissed, auto-stops at 10:00 PM"),
  bullet("Low fuel alert: when estimated range < 40 km — shows nearest petrol pump"),
  bullet("Service alerts: engine oil, air filter, brake, tyre pressure — triggered by km thresholds"),
  body(""),

  h2("2.10  Service Reminder Engine"),
  makeTable(
    ["Service Item", "Default Interval", "Notification Lead"],
    [
      ["Engine Oil", "Every 3,000 km", "200 km before due"],
      ["General Service", "Every 6,000 km", "300 km before due"],
      ["Air Filter", "Every 6,000 km", "300 km before due"],
      ["Brake Inspection", "Every 6,000 km", "300 km before due"],
      ["Tyre Pressure", "Monthly reminder", "1st of each month"],
    ],
    [3120, 3120, 3120]
  ),
  body("All intervals configurable per vehicle in Settings."),
  body(""),

  h2("2.11  Export"),
  bullet("Monthly PDF Report — styled, includes all stats, graphs (screenshot-based), refill history, trip log"),
  bullet("CSV Spreadsheet — full raw data export for trips and fuel entries"),
  body(""),

  h2("2.12  Settings & Data Management"),
  bullet("Edit vehicle profile, route distances, service intervals"),
  bullet("Notification schedule toggle and time customisation"),
  bullet("Dark mode / system theme follow"),
  bullet("Backup to local file (JSON) + restore"),
  bullet("Manual edit of any trip or fuel entry"),
  bullet("Attach photo of fuel receipt to any refill entry"),
  bullet("Data wipe option"),
  body(""),

  pageBreak(),
);

// ─── 3. AI ARCHITECTURE ────────────────────────────────────────────────────
children.push(
  h1("3. AI Architecture — Two-Layer Design"),
  body(""),

  h2("3.1  Layer 1 — Built-in Analytics Engine (Dart, No LLM)"),
  body("Handles ~95% of all intelligence. Runs instantly, uses negligible battery, fully offline. Implemented as a pure Dart service layer in Flutter."),
  body(""),
  makeTable(
    ["Feature", "Algorithm / Approach"],
    [
      ["Mileage calculation", "km / litres per interval; rolling 5-fill average"],
      ["Fuel remaining estimate", "Litres on hand − (distance × 1/avg_mileage)"],
      ["Next refill prediction", "Projected daily km (from weekly pattern) extrapolated to tank empty"],
      ["Monthly expense forecast", "Running daily spend rate × days remaining in month"],
      ["Mileage drop detection", "Current fill vs 5-fill average; threshold < 90% triggers alert"],
      ["Riding pattern analysis", "Day-of-week averages from rolling 8-week history"],
      ["Vehicle Health Score", "Composite of: mileage stability (30%), service compliance (40%), fuel efficiency trend (30%)"],
      ["Service prediction", "Odometer delta since last service vs configurable interval"],
      ["Trip anomaly detection", "Current trip distance > 2× day-of-week average → flag"],
      ["Smart notification suppression", "Skip morning if trip already logged; skip evening after 10 PM"],
      ["Cost per km", "Total ₹ spend / total km for configurable window"],
      ["Fuel price trend", "Stored ₹/L per refill; simple moving average"],
    ],
    [3600, 5760]
  ),
  body(""),

  h2("3.2  Layer 2 — Offline LLM: Qwen2.5 0.5B Instruct"),
  body("Powers the natural language AI chat assistant and generates human-readable summaries. The model is downloaded once (~450 MB) on first launch with user consent."),
  body(""),
  bullet("Integration framework: flutter_llm_inference or ONNX Runtime Mobile (flutter_onnxruntime)"),
  bullet("Model format: GGUF Q4_K_M quantization for optimal speed/quality on mid-range Android"),
  bullet("Expected inference speed: 8–15 tokens/sec on Snapdragon 7-series / Dimensity 8-series"),
  bullet("RAM footprint: ~600–700 MB during inference (model + KV cache)"),
  bullet("Model loaded lazily — only when chat screen is opened"),
  bullet("System prompt pre-loaded with rider's full data context for each query"),
  body(""),
  body("Example chat queries the LLM handles:"),
  bullet("'How much did I spend on petrol last month?'"),
  bullet("'Compare this month's mileage to last month.'"),
  bullet("'Why might my mileage have dropped this week?'"),
  bullet("'When should I refill based on my riding this week?'"),
  bullet("'Summarize my riding habits in 3 lines.'"),
  bullet("'How many college trips did I make in June?'"),
  body(""),
  body("Data injected into LLM context on each query: last 30 days of trips, last 5 refills, current stats, vehicle health score, service status."),
  body(""),

  h2("3.3  AI Garage Home Screen — Insight Generation"),
  body("Insights on the home screen are generated by Layer 1 (rule-based), not the LLM, to ensure instant rendering. The LLM is only invoked when the user explicitly opens the chat."),
  body(""),
  body("Morning greeting card fields (all rule-based):"),
  bullet("Expected commute: from day-of-week average"),
  bullet("Fuel remaining: from estimation engine"),
  bullet("Monthly projection: from expense forecast"),
  bullet("Mileage delta: current month avg vs previous month avg"),
  bullet("Proactive tip: rotating from a curated set of rule-triggered tips (tyre check, service due, mileage milestone, fuel price spike)"),
  body(""),

  pageBreak(),
);

// ─── 4. TECH STACK ─────────────────────────────────────────────────────────
children.push(
  h1("4. Complete Technology Stack"),
  body(""),
  makeTable(
    ["Layer", "Technology", "Purpose", "Why This Choice"],
    [
      ["UI Framework", "Flutter 3.x (Dart)", "Cross-platform UI", "Single codebase for Android-first + future iOS"],
      ["State Management", "Riverpod 2.x", "Reactive state, DI, async", "Best-in-class for Flutter; testable, composable"],
      ["Local Database", "Isar 3.x", "Structured offline storage", "Fastest Flutter DB; full ACID; no-sql flexibility; Dart-native"],
      ["Graphs & Charts", "fl_chart 0.x", "All 18 visualisations", "Most capable open-source Flutter chart library"],
      ["Notifications", "flutter_local_notifications", "Morning/evening/service alerts", "Standard, reliable, supports Android exact alarms"],
      ["Background Tasks", "workmanager", "Periodic prediction recalculation", "Works in background without UI; battery-efficient"],
      ["Navigation to Pump", "url_launcher", "Open Google Maps to BP Makali", "Lightweight; no Maps SDK needed"],
      ["Petrol Price Fetch", "http + html package", "Scrape/parse Indian fuel price", "Lightweight; no third-party API cost"],
      ["PDF Export", "pdf (dart pdf library)", "Monthly report generation", "Pure Dart; no native dependencies"],
      ["CSV Export", "csv package", "Raw data export", "Tiny, no-dependency solution"],
      ["Photo Receipts", "image_picker + path_provider", "Attach fuel receipt photos", "Standard Flutter approach"],
      ["Offline LLM", "ONNX Runtime Mobile / GGUF", "Qwen2.5 0.5B inference", "Best balance of size and quality on mid-range"],
      ["LLM Integration", "flutter_llm_inference", "Chat UI + model loading", "Designed for on-device Flutter LLM apps"],
      ["Model Format", "GGUF Q4_K_M", "Qwen2.5 0.5B quantized", "~450 MB; best quality-per-MB at this size"],
      ["Home Screen Widget", "home_widget package", "Distance + fuel gauge widget", "Supports both Android widget APIs"],
      ["Shared Preferences", "shared_preferences", "App settings, onboarding flag", "Standard lightweight key-value store"],
      ["Dark Mode", "Flutter ThemeData", "System-adaptive theming", "Built into Flutter; no extra package"],
      ["Backup / Restore", "path_provider + share_plus", "JSON export/import", "No cloud; fully local backup"],
    ],
    [2340, 2520, 2160, 2340]
  ),
  body(""),
  pageBreak(),
);

// ─── 5. APP STRUCTURE ───────────────────────────────────────────────────────
children.push(
  h1("5. App Structure — 5 Screens"),
  body(""),
  h2("Screen 1 — 🏠 AI Garage (Dashboard)"),
  bullet("Personalized morning greeting card with AI insights"),
  bullet("Fuel gauge widget (visual)"),
  bullet("Today's stats strip (distance, trips, estimated fuel)"),
  bullet("Quick action buttons (6 primary actions)"),
  bullet("Pinned AI suggestion card"),
  body(""),
  h2("Screen 2 — 🚗 Trips"),
  bullet("Calendar heatmap view (top)"),
  bullet("Today's trip list"),
  bullet("Full ride history — filterable by route type, date range"),
  bullet("Add custom ride FAB"),
  bullet("Tap any trip to edit / add note / delete"),
  body(""),
  h2("Screen 3 — ⛽ Fuel"),
  bullet("Current estimated fuel + range (large visual gauge)"),
  bullet("'Fuel Filled' primary action button"),
  bullet("Refill history timeline (most recent first)"),
  bullet("Petrol price trend mini-chart"),
  bullet("Navigate to BP Makali button"),
  body(""),
  h2("Screen 4 — 📊 Insights"),
  bullet("Monthly summary card (distance, spend, avg mileage)"),
  bullet("AI Insights chip grid (18 insight cards)"),
  bullet("Graph browser — all 18 charts, scrollable"),
  bullet("Vehicle Health Score gauge"),
  bullet("Service status panel (upcoming service items with km remaining)"),
  bullet("Export buttons (PDF / CSV)"),
  body(""),
  h2("Screen 5 — ⚙️ Settings"),
  bullet("Vehicle profile editor"),
  bullet("Route distance editor (all 4 routes)"),
  bullet("Notification schedule controls"),
  bullet("Service interval configuration"),
  bullet("AI model management (download / delete Qwen2.5 model)"),
  bullet("Backup & restore"),
  bullet("Dark mode toggle"),
  bullet("About / data wipe"),
  body(""),
  h2("Floating: 🤖 AI Chat"),
  bullet("Accessible via FAB from any screen"),
  bullet("Full-screen chat overlay"),
  bullet("Context auto-injected (last 30 days data + vehicle profile)"),
  bullet("Model loading indicator on first open"),
  bullet("Conversation is session-only (not persisted)"),
  body(""),
  pageBreak(),
);

// ─── 6. DATA MODELS ────────────────────────────────────────────────────────
children.push(
  h1("6. Data Models (Isar Schema)"),
  body(""),

  h2("VehicleProfile"),
  makeTable(
    ["Field", "Type", "Notes"],
    [
      ["name", "String", "e.g. 'Activa'"],
      ["model", "String", "e.g. 'Honda Activa 6G'"],
      ["registrationNo", "String?", "Optional"],
      ["tankCapacityL", "double", "e.g. 5.3"],
      ["reserveL", "double", "e.g. 0.8"],
      ["initialOdometer", "double?", "Optional"],
      ["serviceIntervalKm", "double", "e.g. 3000"],
      ["lastServiceKm", "double", "Odometer at last service"],
    ],
    [2700, 1800, 4860]
  ),
  body(""),

  h2("Trip"),
  makeTable(
    ["Field", "Type", "Notes"],
    [
      ["id", "int (auto)", "Isar auto-id"],
      ["timestamp", "DateTime", "Local device time"],
      ["routeType", "enum", "college_go, college_return, town_go, town_return, short_go, short_return, custom"],
      ["distanceKm", "double", "Pre-populated for fixed routes; manual for custom"],
      ["notes", "String?", "Optional rider note"],
      ["isAnomaly", "bool", "Flagged by analytics engine"],
    ],
    [2160, 1800, 5400]
  ),
  body(""),

  h2("FuelEntry"),
  makeTable(
    ["Field", "Type", "Notes"],
    [
      ["id", "int (auto)", ""],
      ["timestamp", "DateTime", ""],
      ["amountPaid", "double?", "₹ spent (if entered)"],
      ["litresFilled", "double", "Calculated or entered directly"],
      ["pricePerLitre", "double", "₹/L at time of refill"],
      ["isTankFull", "bool", "Used for accurate mileage calc"],
      ["odometerAtFill", "double?", "Optional"],
      ["kmSinceLastFill", "double", "Computed at entry time"],
      ["calculatedMileage", "double", "km/L for this interval"],
      ["costPerKm", "double", "₹/km for this interval"],
      ["receiptPhotoPath", "String?", "Local file path to photo"],
    ],
    [2520, 1800, 5040]
  ),
  body(""),

  h2("ServiceRecord"),
  makeTable(
    ["Field", "Type", "Notes"],
    [
      ["serviceType", "enum", "engine_oil, general, air_filter, brake, tyre_pressure"],
      ["completedAt", "DateTime", ""],
      ["odometerKm", "double", "Odometer when service was done"],
      ["notes", "String?", ""],
    ],
    [2160, 1800, 5400]
  ),
  body(""),
  pageBreak(),
);

// ─── 7. FOLDER STRUCTURE ───────────────────────────────────────────────────
children.push(
  h1("7. Project Folder Structure"),
  body(""),
  new Paragraph({
    children: [new TextRun({
      text: [
        "activa_tracker/",
        "├── lib/",
        "│   ├── main.dart",
        "│   ├── app.dart                         # Root widget, theme, router",
        "│   ├── core/",
        "│   │   ├── database/",
        "│   │   │   ├── isar_service.dart         # DB init, singleton",
        "│   │   │   └── models/                   # Isar schema: trip, fuel, vehicle, service",
        "│   │   ├── analytics/",
        "│   │   │   ├── mileage_engine.dart",
        "│   │   │   ├── fuel_estimator.dart",
        "│   │   │   ├── expense_forecaster.dart",
        "│   │   │   ├── pattern_analyser.dart",
        "│   │   │   ├── anomaly_detector.dart",
        "│   │   │   └── health_score.dart",
        "│   │   ├── ai/",
        "│   │   │   ├── llm_service.dart          # Qwen2.5 loading + inference",
        "│   │   │   ├── context_builder.dart      # Injects rider data into prompt",
        "│   │   │   └── model_manager.dart        # Download, cache, delete model",
        "│   │   ├── notifications/",
        "│   │   │   ├── notification_service.dart",
        "│   │   │   └── notification_scheduler.dart",
        "│   │   ├── fuel_price/",
        "│   │   │   ├── fuel_price_service.dart   # Fetch + fallback to manual",
        "│   │   │   └── fuel_price_parser.dart",
        "│   │   ├── export/",
        "│   │   │   ├── pdf_exporter.dart",
        "│   │   │   └── csv_exporter.dart",
        "│   │   └── constants.dart                # Route distances, defaults",
        "│   ├── features/",
        "│   │   ├── dashboard/                    # AI Garage screen",
        "│   │   ├── trips/                        # Trip log + history",
        "│   │   ├── fuel/                         # Fuel entry + history",
        "│   │   ├── insights/                     # Analytics + graphs",
        "│   │   ├── chat/                         # LLM chat overlay",
        "│   │   └── settings/                     # All settings screens",
        "│   ├── widgets/",
        "│   │   ├── fuel_gauge.dart",
        "│   │   ├── health_score_gauge.dart",
        "│   │   ├── insight_chip.dart",
        "│   │   ├── quick_action_button.dart",
        "│   │   └── chart_card.dart               # Wraps fl_chart charts",
        "│   └── providers/                        # Riverpod providers for all features",
        "├── android/",
        "│   └── app/src/main/",
        "│       ├── AndroidManifest.xml           # EXACT_ALARM, RECEIVE_BOOT_COMPLETED perms",
        "│       └── res/xml/                      # Home screen widget XML",
        "├── assets/",
        "│   ├── models/                           # Qwen2.5 GGUF (downloaded, not bundled)",
        "│   └── fonts/",
        "├── pubspec.yaml",
        "└── TASKS.md",
      ].join("\n"),
      size: 18,
      font: "Courier New",
      color: C.text,
    })],
    shading: { fill: "F8FAFC", type: ShadingType.CLEAR },
    spacing: { before: 120, after: 120 },
    indent: { left: 200 },
  }),
  body(""),
  pageBreak(),
);

// ─── 8. IMPLEMENTATION PLAN ─────────────────────────────────────────────────
children.push(
  h1("8. Implementation Plan — Multi-Version Strategy"),
  body("Development is divided into three distinct milestones, allowing for incremental delivery and user feedback."),
  body(""),

  // Version Overview
  h2("Version Overview", C.accent),
  makeTable(
    ["Version", "Focus", "Key Deliverables", "Timeline"],
    [
      ["v1.0", "Core Engine & Dashboard", "AI Garage, Fuel Timeline, Health Dashboard, Achievements", "Weeks 1–11"],
      ["v1.5", "Advanced Insights & Polish", "Enhanced AI, Advanced Charts, Widgets, PDF Export", "Weeks 12–14"],
      ["v2.0", "Conversational LLM", "Offline Qwen2.5, Voice Queries, Smart Summaries", "Weeks 15–18"],
    ],
    [1800, 2700, 3600, 1260]
  ),
  body(""),
  pageBreak(),

  // ═══════════════════════════════════════════════════════════════════════════
  // VERSION 1.0 — CORE ENGINE & DASHBOARD
  // ═══════════════════════════════════════════════════════════════════════════
  h1("VERSION 1.0 — Core Engine & Dashboard"),
  body("Focuses on delivering a fully polished, robust fuel tracking and analytics experience without the LLM overhead."),
  body(""),
  bullet("AI Garage Home Screen: Immersive greeting, commute estimates, weather, actionable tips"),
  bullet("Predictive Fuel Timeline: Intuitive visual timelines replacing basic fuel levels"),
  bullet("Vehicle Health Dashboard: Categorized metrics (Fuel Efficiency, Maintenance, Ride Consistency, Tyres)"),
  bullet("Achievement System: Motivational milestones (1000 km, Best Mileage, 30-day streaks)"),
  bullet("Core Framework: Flutter, Isar DB, Notifications, and core graphs"),
  body(""),

  // Phase 0
  h2("Phase 0 — Foundation (Week 1–2)", C.purple),
  body("Goal: project skeleton, DB working, basic navigation."),
  body(""),
  new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [3600, 1800, 1440, 1200, 1320],
    rows: [
      tableRow([
        cell("Task", { fill: C.headerBg, bold: true, color: C.white, width: 3600, isHeader: true }),
        cell("Owner", { fill: C.headerBg, bold: true, color: C.white, width: 1800, isHeader: true }),
        cell("Priority", { fill: C.headerBg, bold: true, color: C.white, width: 1440, isHeader: true }),
        cell("Effort", { fill: C.headerBg, bold: true, color: C.white, width: 1200, isHeader: true }),
        cell("Depends On", { fill: C.headerBg, bold: true, color: C.white, width: 1320, isHeader: true }),
      ], true),
      taskRow("Flutter project init + pubspec setup", "Dev", "P0", "2h", "—"),
      taskRow("Configure Isar + define 4 data models", "Dev", "P0", "4h", "pubspec"),
      taskRow("Setup Riverpod providers skeleton", "Dev", "P0", "3h", "Isar"),
      taskRow("5-screen bottom nav shell (empty screens)", "Dev", "P0", "2h", "Riverpod"),
      taskRow("Onboarding flow UI + VehicleProfile save", "Dev", "P0", "5h", "Isar"),
      taskRow("Define route constants (all 4 routes)", "Dev", "P0", "1h", "onboarding"),
      taskRow("Dark mode theme setup (ThemeData)", "Dev", "P1", "2h", "project init"),
    ]
  }),
  body(""),

  // Phase 1
  h2("Phase 1 — Core Trip & Fuel Logging (Week 3–5)", C.blue),
  body("Goal: daily ride logging and fuel entry fully working."),
  body(""),
  new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [3600, 1800, 1440, 1200, 1320],
    rows: [
      tableRow([
        cell("Task", { fill: C.headerBg, bold: true, color: C.white, width: 3600, isHeader: true }),
        cell("Owner", { fill: C.headerBg, bold: true, color: C.white, width: 1800, isHeader: true }),
        cell("Priority", { fill: C.headerBg, bold: true, color: C.white, width: 1440, isHeader: true }),
        cell("Effort", { fill: C.headerBg, bold: true, color: C.white, width: 1200, isHeader: true }),
        cell("Depends On", { fill: C.headerBg, bold: true, color: C.white, width: 1320, isHeader: true }),
      ], true),
      taskRow("Quick action buttons (6 actions) on dashboard", "Dev", "P0", "4h", "Phase 0"),
      taskRow("Trip logging logic (all route types)", "Dev", "P0", "5h", "Isar models"),
      taskRow("Custom ride bottom sheet (distance + note)", "Dev", "P0", "3h", "trip logic"),
      taskRow("Trip history list + filter by type/date", "Dev", "P0", "6h", "trip logic"),
      taskRow("Edit / delete / undo last trip", "Dev", "P1", "3h", "trip history"),
      taskRow("Fuel entry flow — Amount mode (₹)", "Dev", "P0", "4h", "Phase 0"),
      taskRow("Petrol price HTTP fetch + HTML parser", "Dev", "P0", "5h", "http package"),
      taskRow("Fuel entry — manual price fallback UI", "Dev", "P0", "2h", "price fetch"),
      taskRow("Fuel entry — Litres direct mode", "Dev", "P0", "2h", "fuel entry ₹"),
      taskRow("Tank Full checkbox + flag in FuelEntry model", "Dev", "P1", "1h", "fuel entry"),
      taskRow("Attach receipt photo to fuel entry", "Dev", "P2", "3h", "image_picker"),
      taskRow("Fuel entry history timeline view", "Dev", "P1", "4h", "fuel entry"),
      taskRow("Navigate to BP Makali (url_launcher)", "Dev", "P2", "1h", "—"),
    ]
  }),
  body(""),

  // Phase 2
  h2("Phase 2 — Analytics Engine (Week 6–8)", C.green),
  body("Goal: all rule-based AI, mileage calculations, predictions fully working."),
  body(""),
  new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [3600, 1800, 1440, 1200, 1320],
    rows: [
      tableRow([
        cell("Task", { fill: C.headerBg, bold: true, color: C.white, width: 3600, isHeader: true }),
        cell("Owner", { fill: C.headerBg, bold: true, color: C.white, width: 1800, isHeader: true }),
        cell("Priority", { fill: C.headerBg, bold: true, color: C.white, width: 1440, isHeader: true }),
        cell("Effort", { fill: C.headerBg, bold: true, color: C.white, width: 1200, isHeader: true }),
        cell("Depends On", { fill: C.headerBg, bold: true, color: C.white, width: 1320, isHeader: true }),
      ], true),
      taskRow("Mileage calculation engine (per fill + rolling avg)", "Dev", "P0", "5h", "Phase 1"),
      taskRow("Fuel remaining estimator (litres + km range)", "Dev", "P0", "4h", "mileage engine"),
      taskRow("Monthly expense forecaster", "Dev", "P0", "3h", "trip + fuel data"),
      taskRow("Day-of-week riding pattern analyser", "Dev", "P1", "4h", "trip history"),
      taskRow("Next refill predictor", "Dev", "P1", "3h", "pattern + fuel"),
      taskRow("Mileage drop detector (< 90% of 5-fill avg)", "Dev", "P0", "3h", "mileage engine"),
      taskRow("Trip anomaly detector (2× day-of-week avg)", "Dev", "P1", "2h", "pattern analyser"),
      taskRow("Vehicle Health Score composite calculator", "Dev", "P1", "5h", "all above"),
      taskRow("Service reminder engine (km tracking per type)", "Dev", "P0", "4h", "trip data"),
      taskRow("Cost per km calculator", "Dev", "P0", "2h", "fuel entries"),
      taskRow("Petrol price trend & moving average", "Dev", "P1", "2h", "fuel entries"),
      taskRow("All Riverpod providers wired to analytics engine", "Dev", "P0", "4h", "all above"),
    ]
  }),
  body(""),

  // Phase 3
  h2("Phase 3 — Dashboard & Charts (Week 9–10)", C.orange),
  body("Goal: AI Garage home screen polished, all 18 charts implemented."),
  body(""),
  new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [3600, 1800, 1440, 1200, 1320],
    rows: [
      tableRow([
        cell("Task", { fill: C.headerBg, bold: true, color: C.white, width: 3600, isHeader: true }),
        cell("Owner", { fill: C.headerBg, bold: true, color: C.white, width: 1800, isHeader: true }),
        cell("Priority", { fill: C.headerBg, bold: true, color: C.white, width: 1440, isHeader: true }),
        cell("Effort", { fill: C.headerBg, bold: true, color: C.white, width: 1200, isHeader: true }),
        cell("Depends On", { fill: C.headerBg, bold: true, color: C.white, width: 1320, isHeader: true }),
      ], true),
      taskRow("AI Garage greeting card widget", "Dev", "P0", "4h", "analytics engine"),
      taskRow("Fuel gauge circular widget (fl_chart)", "Dev", "P0", "3h", "fuel estimator"),
      taskRow("Today's stats strip on dashboard", "Dev", "P0", "2h", "analytics engine"),
      taskRow("AI insight chip grid (rule-based content)", "Dev", "P0", "4h", "analytics engine"),
      taskRow("Implement all 18 charts (fl_chart)", "Dev", "P0", "16h", "analytics data"),
      taskRow("Calendar heatmap (custom painter or fl_chart)", "Dev", "P1", "5h", "trip history"),
      taskRow("Vehicle Health Score gauge (animated)", "Dev", "P1", "3h", "health score"),
      taskRow("Service status panel on Insights screen", "Dev", "P1", "3h", "service engine"),
      taskRow("Monthly summary card", "Dev", "P0", "2h", "analytics engine"),
    ]
  }),
  body(""),

  // Phase 4
  h2("Phase 4 — Notifications & Background Work (Week 11)", C.purple),
  body(""),
  new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [3600, 1800, 1440, 1200, 1320],
    rows: [
      tableRow([
        cell("Task", { fill: C.headerBg, bold: true, color: C.white, width: 3600, isHeader: true }),
        cell("Owner", { fill: C.headerBg, bold: true, color: C.white, width: 1800, isHeader: true }),
        cell("Priority", { fill: C.headerBg, bold: true, color: C.white, width: 1440, isHeader: true }),
        cell("Effort", { fill: C.headerBg, bold: true, color: C.white, width: 1200, isHeader: true }),
        cell("Depends On", { fill: C.headerBg, bold: true, color: C.white, width: 1320, isHeader: true }),
      ], true),
      taskRow("Morning trip reminder (7:30 AM, skip if logged)", "Dev", "P0", "3h", "flutter_local_notif"),
      taskRow("Evening return reminder (6:00 PM)", "Dev", "P0", "2h", "morning notif"),
      taskRow("Evening escalation (every 10 min until 10 PM)", "Dev", "P1", "3h", "evening notif"),
      taskRow("Low fuel alert notification", "Dev", "P0", "2h", "fuel estimator"),
      taskRow("Service due alerts (all 5 types)", "Dev", "P0", "3h", "service engine"),
      taskRow("Workmanager periodic analytics recalculation", "Dev", "P1", "3h", "analytics engine"),
      taskRow("Boot receiver (reschedule notifications on boot)", "Dev", "P1", "2h", "notification setup"),
    ]
  }),
  body(""),
  badge("✓ VERSION 1.0 COMPLETE — Core Engine Ready for Release", C.green),
  body(""),
  pageBreak(),

  // ═══════════════════════════════════════════════════════════════════════════
  // VERSION 1.5 — ADVANCED INSIGHTS & POLISH
  // ═══════════════════════════════════════════════════════════════════════════
  h1("VERSION 1.5 — Advanced Insights & Polish"),
  body("Focuses on deepening the analytics capabilities and enriching rule-based AI."),
  body(""),
  bullet("Advanced AI Insights: Multi-line insights with root causes and recommendations"),
  bullet("AI Timeline: Google Photos-style memory feed for riding milestones"),
  bullet("AI Confidence Score: Confidence percentage attached to predictions"),
  bullet("Expanded Analytics: Scatter plots, Radar charts, Sankey diagrams, Stacked charts, prediction overlays"),
  bullet("Widgets & Reports: Home widgets and PDF generation"),
  body(""),

  // Phase 5
  h2("Phase 5 — Enhanced AI Insights & Predictions (Week 12–13)", C.accent),
  body("Goal: Deeper analytics with confidence scoring and advanced visualizations."),
  body(""),
  new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [3600, 1800, 1440, 1200, 1320],
    rows: [
      tableRow([
        cell("Task", { fill: C.headerBg, bold: true, color: C.white, width: 3600, isHeader: true }),
        cell("Owner", { fill: C.headerBg, bold: true, color: C.white, width: 1800, isHeader: true }),
        cell("Priority", { fill: C.headerBg, bold: true, color: C.white, width: 1440, isHeader: true }),
        cell("Effort", { fill: C.headerBg, bold: true, color: C.white, width: 1200, isHeader: true }),
        cell("Depends On", { fill: C.headerBg, bold: true, color: C.white, width: 1320, isHeader: true }),
      ], true),
      taskRow("Predictive Fuel Timeline (day-by-day bar forecast)", "Dev", "P1", "4h", "fuel estimator"),
      taskRow("AI Confidence Score for mileage predictions", "Dev", "P1", "3h", "analytics engine"),
      taskRow("Advanced AI Insights (multi-line causes + recommendations)", "Dev", "P1", "5h", "analytics engine"),
      taskRow("AI Timeline (Google Photos style milestones feed)", "Dev", "P1", "6h", "trip history"),
      taskRow("Achievement System (1000 km, Best mileage, streaks)", "Dev", "P1", "5h", "trip + fuel data"),
      taskRow("Scatter plot: Petrol price vs cost per km", "Dev", "P2", "3h", "fl_chart"),
      taskRow("Radar chart: Vehicle health metrics breakdown", "Dev", "P2", "3h", "health score"),
      taskRow("Sankey diagram: Fuel → Distance → Cost flow", "Dev", "P2", "4h", "analytics engine"),
      taskRow("Stacked monthly comparison chart", "Dev", "P2", "2h", "fl_chart"),
      taskRow("AI prediction overlay (actual vs predicted)", "Dev", "P2", "3h", "analytics engine"),
    ]
  }),
  body(""),

  // Phase 6
  h2("Phase 6 — Export, Widgets & Polish (Week 14)", C.green),
  body(""),
  new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [3600, 1800, 1440, 1200, 1320],
    rows: [
      tableRow([
        cell("Task", { fill: C.headerBg, bold: true, color: C.white, width: 3600, isHeader: true }),
        cell("Owner", { fill: C.headerBg, bold: true, color: C.white, width: 1800, isHeader: true }),
        cell("Priority", { fill: C.headerBg, bold: true, color: C.white, width: 1440, isHeader: true }),
        cell("Effort", { fill: C.headerBg, bold: true, color: C.white, width: 1200, isHeader: true }),
        cell("Depends On", { fill: C.headerBg, bold: true, color: C.white, width: 1320, isHeader: true }),
      ], true),
      taskRow("PDF monthly report (dart pdf library)", "Dev", "P1", "8h", "analytics engine"),
      taskRow("CSV export (all trips + all fuel entries)", "Dev", "P1", "3h", "Isar models"),
      taskRow("Home screen widget (fuel + daily distance)", "Dev", "P1", "6h", "home_widget pkg"),
      taskRow("Backup to JSON file + restore flow", "Dev", "P1", "5h", "Isar models"),
      taskRow("Settings screen — full implementation", "Dev", "P0", "6h", "all features"),
      taskRow("Accessibility audit (font sizes, contrast)", "Dev", "P2", "3h", "all UI"),
      taskRow("Full app dark mode polish pass", "Dev", "P1", "4h", "all UI"),
      taskRow("Performance profiling (Dart DevTools)", "Dev", "P1", "3h", "all features"),
    ]
  }),
  body(""),
  badge("✓ VERSION 1.5 COMPLETE — Enhanced Analytics Ready", C.green),
  body(""),
  pageBreak(),

  // ═══════════════════════════════════════════════════════════════════════════
  // VERSION 2.0 — CONVERSATIONAL LLM
  // ═══════════════════════════════════════════════════════════════════════════
  h1("VERSION 2.0 — Conversational AI (Offline LLM)"),
  body("Introduces the offline LLM model for natural language interaction."),
  body(""),
  bullet("Offline Qwen2.5 Assistant: Full offline inference running locally on device"),
  bullet("Conversational Memory: LLM maintains context across sessions"),
  bullet("AI Chat Suggestions: One-tap action chips to bootstrap conversations"),
  bullet("Voice Queries: Speech-to-text integration for hands-free usage"),
  bullet("Smart Summaries: Natural language summaries of rider behavior"),
  body(""),

  // Phase 7
  h2("Phase 7 — Offline LLM Integration (Week 15–16)", C.accent),
  body("Goal: Qwen2.5 0.5B running on-device, chat UI complete."),
  body(""),
  new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [3600, 1800, 1440, 1200, 1320],
    rows: [
      tableRow([
        cell("Task", { fill: C.headerBg, bold: true, color: C.white, width: 3600, isHeader: true }),
        cell("Owner", { fill: C.headerBg, bold: true, color: C.white, width: 1800, isHeader: true }),
        cell("Priority", { fill: C.headerBg, bold: true, color: C.white, width: 1440, isHeader: true }),
        cell("Effort", { fill: C.headerBg, bold: true, color: C.white, width: 1200, isHeader: true }),
        cell("Depends On", { fill: C.headerBg, bold: true, color: C.white, width: 1320, isHeader: true }),
      ], true),
      taskRow("Evaluate flutter_llm_inference vs ONNX Runtime Mobile", "Dev", "P0", "4h", "—"),
      taskRow("Integrate chosen inference framework", "Dev", "P0", "6h", "evaluation"),
      taskRow("Model download manager (resumable, progress bar)", "Dev", "P0", "5h", "framework"),
      taskRow("Model cache + delete flow in Settings", "Dev", "P1", "2h", "model manager"),
      taskRow("Context builder — serialize 30-day rider data", "Dev", "P0", "4h", "analytics engine"),
      taskRow("System prompt engineering for Qwen2.5", "Dev", "P0", "3h", "context builder"),
      taskRow("Chat UI (message bubbles, typing indicator, FAB)", "Dev", "P0", "5h", "llm service"),
      taskRow("Streaming token output in chat UI", "Dev", "P1", "4h", "chat UI"),
      taskRow("Model loading state management (lazy load on open)", "Dev", "P1", "3h", "llm service"),
      taskRow("Inference performance tuning (thread count, etc.)", "Dev", "P1", "3h", "integration"),
    ]
  }),
  body(""),

  // Phase 8
  h2("Phase 8 — Chat UX, Voice & Final Polish (Week 17–18)", C.purple),
  body(""),
  new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [3600, 1800, 1440, 1200, 1320],
    rows: [
      tableRow([
        cell("Task", { fill: C.headerBg, bold: true, color: C.white, width: 3600, isHeader: true }),
        cell("Owner", { fill: C.headerBg, bold: true, color: C.white, width: 1800, isHeader: true }),
        cell("Priority", { fill: C.headerBg, bold: true, color: C.white, width: 1440, isHeader: true }),
        cell("Effort", { fill: C.headerBg, bold: true, color: C.white, width: 1200, isHeader: true }),
        cell("Depends On", { fill: C.headerBg, bold: true, color: C.white, width: 1320, isHeader: true }),
      ], true),
      taskRow("AI Chat Suggestion chips (Avg Mileage, Fuel Left, Compare)", "Dev", "P1", "3h", "chat UI"),
      taskRow("AI Assistant with Memory (session context preservation)", "Dev", "P0", "4h", "chat UI"),
      taskRow("Voice queries (speech-to-text integration)", "Dev", "P1", "4h", "chat UI"),
      taskRow("Smart summaries generation via LLM", "Dev", "P1", "3h", "llm service"),
      taskRow("Memory leak audit (esp. LLM inference)", "Dev", "P0", "3h", "LLM integration"),
      taskRow("Edge case testing (no data, etc.)", "Dev", "P0", "4h", "all features"),
      taskRow("APK build + signing + install on test device", "Dev", "P0", "2h", "all phases"),
    ]
  }),
  body(""),
  badge("✓ VERSION 2.0 COMPLETE — Full AI Assistant Ready", C.green),
  body(""),
  pageBreak(),
);

// ─── 9. TIMELINE SUMMARY ───────────────────────────────────────────────────
children.push(
  h1("9. Timeline Summary — Multi-Version Roadmap"),
  body(""),
  h2("Version 1.0 — Core Engine & Dashboard", C.green),
  makeTable(
    ["Phase", "Weeks", "Deliverable", "Effort Est."],
    [
      ["Phase 0 — Foundation", "1–2", "Project skeleton, Isar, Riverpod, Onboarding", "~19h"],
      ["Phase 1 — Trip & Fuel Logging", "3–5", "Core daily use working end-to-end", "~43h"],
      ["Phase 2 — Analytics Engine", "6–8", "All rule-based AI + predictions live", "~41h"],
      ["Phase 3 — Dashboard & Charts", "9–10", "AI Garage + all 18 charts", "~42h"],
      ["Phase 4 — Notifications", "11", "Smart reminders + background tasks", "~18h"],
    ],
    [2700, 1200, 3600, 1860]
  ),
  body(""),
  body("Version 1.0 Total: ~163 hours | 11 weeks"),
  body(""),

  h2("Version 1.5 — Advanced Insights & Polish", C.blue),
  makeTable(
    ["Phase", "Weeks", "Deliverable", "Effort Est."],
    [
      ["Phase 5 — Enhanced AI", "12–13", "Confidence scores, timeline, achievements, advanced charts", "~38h"],
      ["Phase 6 — Export & Polish", "14", "PDF/CSV, widgets, settings, polish", "~38h"],
    ],
    [2700, 1200, 3600, 1860]
  ),
  body(""),
  body("Version 1.5 Total: ~76 hours | 3 weeks"),
  body(""),

  h2("Version 2.0 — Conversational LLM", C.purple),
  makeTable(
    ["Phase", "Weeks", "Deliverable", "Effort Est."],
    [
      ["Phase 7 — LLM Integration", "15–16", "Qwen2.5 on-device, chat UI, model management", "~39h"],
      ["Phase 8 — Chat UX & Voice", "17–18", "Voice queries, smart summaries, final testing", "~23h"],
    ],
    [2700, 1200, 3600, 1860]
  ),
  body(""),
  body("Version 2.0 Total: ~62 hours | 4 weeks"),
  body(""),

  h2("Grand Total", C.accent),
  makeTable(
    ["Version", "Timeline", "Total Effort", "Release Status"],
    [
      ["v1.0 — Core Engine", "Weeks 1–11", "~163h", "Production Ready"],
      ["v1.5 — Advanced", "Weeks 12–14", "~76h", "Production Ready"],
      ["v2.0 — LLM", "Weeks 15–18", "~62h", "Production Ready"],
      ["TOTAL", "18 weeks", "~301h", "—"],
    ],
    [2700, 1800, 1800, 1860]
  ),
  body(""),
  body("At 15–20 hours/week solo development, the complete roadmap spans ~18 weeks for all three versions."),
  body(""),
  pageBreak(),
);

// ─── 10. PERMISSIONS ────────────────────────────────────────────────────────
children.push(
  h1("10. Android Permissions Required"),
  body(""),
  makeTable(
    ["Permission", "Why Needed"],
    [
      ["RECEIVE_BOOT_COMPLETED", "Reschedule notifications after device reboot"],
      ["SCHEDULE_EXACT_ALARM", "Morning and evening reminders at precise times"],
      ["POST_NOTIFICATIONS", "Android 13+ — show all notifications"],
      ["INTERNET", "Petrol price fetch (optional, graceful fallback)"],
      ["READ_MEDIA_IMAGES", "Attach fuel receipt photo from gallery"],
      ["CAMERA", "Capture fuel receipt photo in-app"],
      ["READ_EXTERNAL_STORAGE (API < 33)", "Backup restore from storage"],
      ["WRITE_EXTERNAL_STORAGE (API < 29)", "Save CSV/PDF export to Downloads"],
    ],
    [3600, 5760]
  ),
  body(""),
  pageBreak(),
);

// ─── 11. PUBSPEC ─────────────────────────────────────────────────────────────
children.push(
  h1("11. pubspec.yaml — Dependencies"),
  body(""),
  new Paragraph({
    children: [new TextRun({
      text: [
        "dependencies:",
        "  flutter:",
        "    sdk: flutter",
        "",
        "  # State Management",
        "  flutter_riverpod: ^2.5.1",
        "  riverpod_annotation: ^2.3.5",
        "",
        "  # Database",
        "  isar: ^3.1.0",
        "  isar_flutter_libs: ^3.1.0  # platform binaries",
        "  path_provider: ^2.1.3",
        "",
        "  # Charts",
        "  fl_chart: ^0.68.0",
        "",
        "  # Notifications",
        "  flutter_local_notifications: ^17.2.2",
        "  workmanager: ^0.5.2",
        "",
        "  # Navigation",
        "  go_router: ^14.2.7",
        "",
        "  # Networking",
        "  http: ^1.2.2",
        "  html: ^0.15.4           # Parse petrol price pages",
        "",
        "  # Export",
        "  pdf: ^3.10.8",
        "  csv: ^6.0.0",
        "  share_plus: ^10.0.0",
        "",
        "  # Media",
        "  image_picker: ^1.1.2",
        "",
        "  # Maps / Navigation",
        "  url_launcher: ^6.3.1",
        "",
        "  # Home Screen Widget",
        "  home_widget: ^0.5.0",
        "",
        "  # Shared Preferences",
        "  shared_preferences: ^2.3.2",
        "",
        "  # Offline LLM",
        "  flutter_llm_inference: ^1.0.0   # or onnxruntime: ^1.18.0",
        "",
        "dev_dependencies:",
        "  flutter_test:",
        "    sdk: flutter",
        "  isar_generator: ^3.1.0",
        "  build_runner: ^2.4.11",
        "  riverpod_generator: ^2.4.0",
        "  flutter_lints: ^4.0.0",
      ].join("\n"),
      size: 18,
      font: "Courier New",
      color: C.text,
    })],
    shading: { fill: "F8FAFC", type: ShadingType.CLEAR },
    spacing: { before: 120, after: 120 },
    indent: { left: 200 },
  }),
  body(""),
  pageBreak(),
);

// ─── 12. RISKS ────────────────────────────────────────────────────────────
children.push(
  h1("12. Risks & Mitigations"),
  body(""),
  makeTable(
    ["Risk", "Likelihood", "Impact", "Mitigation"],
    [
      ["Qwen2.5 inference too slow on target device", "Medium", "High", "Benchmark early in Phase 5; fallback to SmolLM2 360M if needed"],
      ["Petrol price scraping breaks (site changes)", "High", "Low", "Graceful fallback to manual entry is P0; scraping is enhancement only"],
      ["Isar major version breaking change", "Low", "Medium", "Pin version; migration scripts for schema changes"],
      ["flutter_llm_inference package immaturity", "Medium", "High", "Evaluate ONNX Runtime Mobile as fallback in Phase 5 spike"],
      ["Home widget API changes across Android versions", "Medium", "Low", "Test on API 29, 33, 34; use home_widget abstraction layer"],
      ["Model download size (450 MB) on slow connections", "High", "Medium", "Resumable download; progress UI; allow skip and use rule-based only"],
      ["Exact alarms restricted on Android 14+", "Medium", "Medium", "Request SCHEDULE_EXACT_ALARM; fallback to inexact if denied"],
    ],
    [2700, 1200, 1200, 4260]
  ),
  body(""),
  pageBreak(),
);

// ─── 13. TASKS.MD SUMMARY ───────────────────────────────────────────────────
children.push(
  h1("13. TASKS.md Reference (Copy to Repo)"),
  body("A markdown task file is included separately for use in your repository. It contains all tasks from Phases 0–6 as GitHub-style checkboxes, grouped by phase, with priorities and effort estimates inline. Use this alongside Linear, Notion, or GitHub Issues to track progress."),
  body(""),
  body("Key tracking conventions used in TASKS.md:"),
  bullet("[P0] — Must have, app broken without it"),
  bullet("[P1] — Should have, significant feature"),
  bullet("[P2] — Nice to have, polish layer"),
  bullet("Effort in hours is a solo-developer estimate; add 30% buffer for unfamiliar packages"),
  body(""),
);

// ─── FINAL BUILD ───────────────────────────────────────────────────────────
const doc = new Document({
  numbering: {
    config: [
      {
        reference: "bullets", levels: [{
          level: 0, format: LevelFormat.BULLET, text: "•",
          alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } }
        }]
      },
      {
        reference: "sub_bullets", levels: [{
          level: 0, format: LevelFormat.BULLET, text: "◦",
          alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 1080, hanging: 360 } } }
        }]
      },
    ]
  },
  styles: {
    default: { document: { run: { font: "Arial", size: 22, color: C.text } } },
    paragraphStyles: [
      {
        id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 36, bold: true, font: "Arial", color: C.white },
        paragraph: { spacing: { before: 360, after: 180 }, outlineLevel: 0 }
      },
      {
        id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 28, bold: true, font: "Arial", color: C.accent },
        paragraph: { spacing: { before: 280, after: 120 }, outlineLevel: 1 }
      },
      {
        id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 24, bold: true, font: "Arial", color: C.green },
        paragraph: { spacing: { before: 200, after: 80 }, outlineLevel: 2 }
      },
    ]
  },
  sections: [{
    properties: {
      page: {
        size: { width: 12240, height: 15840 },
        margin: { top: 1080, right: 1080, bottom: 1080, left: 1080 }
      }
    },
    children,
  }]
});

Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync("ActivaTracker_Plan_v2.docx", buf);
  console.log("Done - Generated ActivaTracker_Plan_v2.docx");
});
