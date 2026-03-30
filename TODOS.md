# CTA Tracker iOS -- TODOs

Tracks all feature work derived from `cta_tracker_ios_functional_spec.md`. Each TODO includes a brief description and acceptance criteria. Testing is part of each TODO.

---

## Group 0: Project Scaffolding

### TODO 0.1 -- Project cleanup and folder structure
- [x] Complete

Remove Xcode boilerplate (`Item.swift`, template `ContentView.swift`). Establish the project's folder organization for Models, Networking, Repositories, ViewModels, Views, Utilities, etc. Update `LBusApp.swift` to remove the `Item`-based `ModelContainer`.

**Acceptance Criteria:**
- [x] Boilerplate files removed or replaced
- [x] `LBusApp.swift` no longer references `Item`
- [x] Folder structure established
- [x] Project builds cleanly

---

## Group 1: Foundation

### TODO 1.1 -- API client and networking layer
- [x] Complete

Build a reusable HTTP client targeting `https://cta.danielvega.dev`. Handle GET and POST requests, JSON decoding, and typed errors. Use async/await with URLSession.

**Acceptance Criteria:**
- [x] Generic API client performs GET and POST requests against the base URL
- [x] Typed error enum covers network failure, decoding failure, and server error cases
- [x] JSON decoding uses `Codable` with appropriate strategies
- [x] Covered by unit tests with sample payloads

### TODO 1.2 -- API response models (DTOs)
- [x] Complete

Define `Codable` structs mapping to JSON responses for all endpoints: bus routes, bus directions, bus stops, bus arrivals, bus follow, train data, train arrivals, train follow, and favorites request/response models.

**Acceptance Criteria:**
- [x] One DTO struct per endpoint response shape
- [x] Favorites request body models for `/savefavorites` and `/myfavorites`
- [x] All DTOs are `Codable`
- [x] Decoding tests against representative JSON samples

### TODO 1.3 -- Domain models
- [x] Complete

Define the app's domain model types consumed by the UI, distinct from DTOs. Includes `BusRoute`, `BusDirection`, `BusStop`, `BusArrival`, `TrainLine`, `TrainStation`, `TrainArrival`, `Favorite`, and follow-screen models. Include DTO-to-domain mapping.

**Acceptance Criteria:**
- [x] Domain types defined with properties matching the spec's display requirements (arrival time, delay status, approaching status, etc.)
- [x] Mapping from each DTO to its domain model
- [x] Enum or type distinguishes bus favorites from train favorites
- [x] Unit tests verify mapping including edge cases (delayed, due now, etc.)

### TODO 1.4 -- App navigation structure
- [x] Complete

Set up the root `TabView` with four tabs: Home, Routes, Favorites, Settings. Each tab owns a `NavigationStack`. Define navigation destination types for the bus and train flows.

**Acceptance Criteria:**
- [x] `TabView` with four tabs using SF Symbol icons and labels
- [x] Each tab wraps content in a `NavigationStack`
- [x] Navigation destination types defined for: bus directions, bus stops, bus arrivals, bus follow, train stations, train arrivals, train follow
- [x] App launches and displays the tab bar with placeholder screens

---

## Group 2: Data Layer

### TODO 2.1 -- BusRepository
- [x] Complete

Create a repository wrapping the API client for all bus endpoints: fetch routes, fetch directions for a route, fetch stops for a route+direction, fetch arrivals for a stop, and fetch follow data for a vehicle.

**Acceptance Criteria:**
- [x] Methods: `getRoutes()`, `getDirections(route:)`, `getStops(route:direction:)`, `getArrivals(stopId:)`, `getFollow(vehicleId:)`
- [x] Returns domain models (not DTOs)
- [x] Errors propagate as typed errors
- [x] Protocol-based for testability

### TODO 2.2 -- TrainRepository
- [x] Complete

Create a repository for train data. Fetches comprehensive train data (lines, directions, stations) from `/traindata`, and arrivals/follow data from their respective endpoints.

**Acceptance Criteria:**
- [x] Methods: `getTrainData()`, `getArrivals(stopId:)`, `getFollow(vehicleId:)`
- [x] Returns domain models
- [x] Protocol-based for testability

### TODO 2.3 -- FavoritesRepository
- [x] Complete

Create a repository managing favorites with SwiftData for local persistence and manual remote sync via `/savefavorites` and `/myfavorites`. Favorites must persist across launches and include enough context to reopen the correct arrivals screen (type, name, stop/station ID, route, direction).

**Acceptance Criteria:**
- [x] SwiftData `@Model` for persisted favorites
- [x] Add, remove, and clear-all operations on local store
- [x] Manual sync to push local favorites to the remote API
- [x] Manual sync to pull remote favorites to local store
- [x] Device identifier strategy for the API `id` field
- [x] Protocol-based for testability

---

## Group 3: Shared Infrastructure

### TODO 3.1 -- Settings screen and storage
- [x] Complete

Implement the settings screen with theme selection (system/light/dark), auto-refresh toggle, refresh interval display, and a clear-favorites data management action. Persist preferences. Apply the selected theme app-wide.

**Acceptance Criteria:**
- [x] Theme picker applies system/light/dark via `preferredColorScheme`
- [x] Auto-refresh toggle persisted
- [x] Refresh interval displayed
- [x] "Clear all favorites" action with confirmation
- [x] Settings screen accessible from the Settings tab

### TODO 3.2 -- Auto-refresh timer utility
- [x] Complete

Build a shared refresh policy. Usable by any ViewModel needing periodic refresh. Respects the auto-refresh on/off setting.

**Acceptance Criteria:**
- [x] Policy that ViewModels can adopt for periodic refresh
- [x] Respects auto-refresh on/off setting
- [x] Pauses on view disappear, resumes on view appear
- [x] Provides a `lastUpdated` timestamp for the UI
- [x] Supports manual refresh alongside automatic

---

## Group 4: Bus Feature Screens

### TODO 4.0 -- Persistent cache for routes, directions, and stops
- [x] Complete

Build a persistent cache for route-browsing metadata. Cache bus routes from `/busroutes`, train route-browsing data from `/traindata`, bus directions from `/busroutedirections`, and bus stops from `/busroutestops`. The cache must survive app quits and device restarts. Cached entries expire after 1 week. When expired cached data exists, the app should display the cached data immediately, then refresh it in the background so the next visit uses the newest available data. Do not cache any live arrival or follow data.

**Acceptance Criteria:**
- [x] Bus routes are cached persistently after a successful fetch
- [x] Train route-browsing data from `/traindata` is cached persistently after a successful fetch
- [x] Bus directions are cached persistently per route
- [x] Bus stops are cached persistently per route + direction
- [x] Cached route-browsing data remains available after app quit/relaunch and device restart
- [x] Cached route-browsing entries expire after 1 week
- [x] If expired cached route-browsing data exists, the app displays the cached data immediately and refreshes in the background
- [x] Background refresh updates the stored cache for the next visit
- [x] Bus arrivals are never read from or written to cache
- [x] Train arrivals are never read from or written to cache
- [x] Bus follow data is never read from or written to cache
- [x] Train follow data is never read from or written to cache
- [x] Unit tests cover cache hits, persistence across launches, expiry behavior, stale-while-revalidate behavior, and no-arrivals-caching rules

### TODO 4.1 -- Routes screen (bus routes + train lines with search)
- [x] Complete

Build the Routes screen displaying both bus routes and train lines in a searchable list. Bus routes from the API, train lines from `/traindata`. Tapping a bus route navigates to bus directions; tapping a train line navigates to train stations.

**Acceptance Criteria:**
- [x] Displays train lines section and bus routes section
- [x] Search field filters both lists by route ID and name
- [x] Selecting a bus route pushes bus direction screen
- [x] Selecting a train line pushes train stations screen
- [x] Loading, error, and empty states handled
- [x] While loading, a shimmer effect is shown in place of the lists

### TODO 4.2 -- Bus directions screen
- [x] Complete

Show available directions for a selected bus route. Selecting a direction proceeds to the stops screen.

**Acceptance Criteria:**
- [x] Displays selected route name/number in header
- [x] Lists directions fetched from the API
- [x] Selecting a direction pushes bus stops screen
- [x] Loading, error, and empty states handled
- [x] Back navigation returns to routes
- [x] While loading, a shimmer effect is shown in place of the lists

### TODO 4.3 -- Bus stops screen (with search and favorite)
- [ ] Complete

Show stops for a selected route+direction. Each stop shows name, stop ID, and a favorite toggle. List is searchable. Tapping a stop navigates to bus arrivals.

**Acceptance Criteria:**
- [ ] Route and direction context in header
- [ ] Stop rows with name, stop ID, and favorite toggle
- [ ] Search field filters the stop list
- [ ] Tapping a stop pushes bus arrivals screen
- [ ] Favorite toggle adds/removes with correct context (route, direction, name, stop ID)
- [ ] Loading, error, and empty states handled
- [ ] While loading, a shimmer effect is shown in place of the lists
  
### TODO 4.4 -- Bus arrivals screen
- [ ] Complete

Show real-time arrivals for a bus stop. Header with stop info and favorite control. Arrival list with timing/delay info. Auto-refresh, manual refresh, last-updated display.

**Acceptance Criteria:**
- [ ] Header: stop name, stop ID, favorite control
- [ ] Each arrival: route number, direction, destination, distance (if available), countdown, clock time, day context, delayed badge
- [ ] "Due" when imminent; "X min" countdown otherwise
- [ ] Empty state when no arrivals
- [ ] Auto-refresh every 30s, manual refresh, last-updated timestamp
- [ ] Tapping an arrival pushes bus follow screen for that vehicle
- [ ] While loading, a shimmer effect is shown in place of the lists

### TODO 4.5 -- Bus follow screen
- [ ] Complete

Show upcoming stops for a tracked bus vehicle. Highlight the originating stop. Auto-refresh and manual refresh.

**Acceptance Criteria:**
- [ ] Header: vehicle ID and follow context
- [ ] Upcoming stops: stop name, stop ID, route, destination, countdown, delay status, direction
- [ ] Originating stop visually highlighted
- [ ] Auto-refresh every 30s, manual refresh
- [ ] Loading, error, and empty states handled
- [ ] While loading, a shimmer effect is shown in place of the lists

---

## Group 5: Train Feature Screens

### TODO 5.1 -- Train stations screen (with search)
- [ ] Complete

Show stations for a selected train line from `/traindata`. List is searchable. Tapping a station navigates to train arrivals with line context.

**Acceptance Criteria:**
- [ ] Displays selected train line in header
- [ ] Lists stations with name
- [ ] Search field filters the station list
- [ ] Tapping a station pushes train arrivals screen with line context
- [ ] Empty state handled

### TODO 5.2 -- Train arrivals screen
- [ ] Complete

Show real-time arrivals for a station, grouped by line and direction. Header with station info, favorite control, serving lines. When opened from a specific line, filter to that line. Auto-refresh, manual refresh, last-updated display.

**Acceptance Criteria:**
- [ ] Header: station name, station ID, favorite control, serving lines
- [ ] Arrivals grouped by train line and direction/destination
- [ ] Each arrival: line, destination, run number, countdown, clock time, day context, approaching badge, delayed badge, service alert badge
- [ ] "Due" for imminent; "X min" countdown otherwise
- [ ] Line context filtering when opened from a specific line
- [ ] Auto-refresh every 30s, manual refresh, last-updated timestamp
- [ ] Tapping an arrival pushes train follow screen
- [ ] Empty state when no arrivals
- [ ] While loading, a shimmer effect is shown in place of the lists

### TODO 5.3 -- Train follow screen
- [ ] Complete

Show upcoming stations for a tracked train run. Highlight the originating station. Auto-refresh and manual refresh.

**Acceptance Criteria:**
- [ ] Header: run number and follow context
- [ ] Upcoming stations: station name, platform/description, line, destination, direction, countdown, clock time, day context, approaching/delayed/alert badges
- [ ] Originating station visually highlighted
- [ ] Auto-refresh every 30s, manual refresh
- [ ] Loading, error, and empty states handled
- [ ] While loading, a shimmer effect is shown in place of the lists

---

## Group 6: Favorites

### TODO 6.1 -- Favorites screen
- [ ] Complete

Show all saved favorites with remove/clear-all, empty state, and navigation to the correct arrivals screen. Bus favorites open bus arrivals; train favorites open train arrivals (with line context if saved).

**Acceptance Criteria:**
- [ ] Lists favorites showing: name, transit type (bus/train), route/line context, direction when available
- [ ] Remove control per row
- [ ] "Clear all" action with confirmation
- [ ] Tapping a bus favorite navigates to bus arrivals for that stop
- [ ] Tapping a train favorite navigates to train arrivals for that station (with line context if saved)
- [ ] Empty state when no favorites saved
- [ ] List updates reactively when favorites change

---

## Group 7: Home

### TODO 7.1 -- Home screen
- [ ] Complete

Build the Home tab as the app's landing screen. Displays app title and welcome context. Handles loading, success, and retry states if startup data loading is needed.

**Acceptance Criteria:**
- [ ] Displays "CTA Tracker" title and welcome/landing content
- [ ] Loading state and retry on failure if pre-loading startup data
- [ ] Success state presents the landing experience

---

## Suggested Implementation Order

| Phase | TODOs | Rationale |
|-------|-------|-----------|
| 1 | 0.1, 1.1, 1.2 | Clean slate, networking, DTOs -- everything else depends on these |
| 2 | 1.3, 1.4 | Domain models, navigation skeleton |
| 3 | 2.1, 2.2, 2.3, 3.1, 3.2 | Repositories and shared infrastructure |
| 4 | 4.1, 4.2, 4.3, 4.4, 4.5 | Full bus flow -- validates the full stack |
| 5 | 5.1, 5.2, 5.3 | Full train flow -- builds on bus patterns |
| 6 | 6.1, 7.1 | Favorites and Home |
