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

### TODO 1.5 -- App navigation refactor
- [x] Complete

Refactor the root `TabView` to have 3 Tabs instead of 4: Favorites, Settings, and a 3rd one with the role as .search that contains the Routes screen as the root of its NavigationStack. The Home tab is removed, and the Favorites is now the landing screen when the app opens. The Routes screen is still accessible via the .search tab, and the Settings screen is still accessible via the Settings tab.

**Acceptance Criteria:**
- [x] `TabView` with three tabs: Favorites (landing), Settings, and Search (with Routes as root)
- [x] Home tab removed and logic updated so Favorites is the initial screen on app launch
- [x] If user does not have any favorites, the Favorites tab shows a welcome message and prompts them to explore routes to add favorites
- [x] Routes screen still accessible via Search tab, Settings still accessible via Settings tab
- [x] No existing navigation tests reference AppTab or placeholder views; no test updates needed

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
- [x] Complete

Show stops for a selected route+direction. Each stop shows name, stop ID, and a favorite toggle. List is searchable. Tapping a stop navigates to bus arrivals.

**Acceptance Criteria:**
- [x] Route and direction context in header
- [x] Stop rows with name, stop ID, and favorite toggle
- [x] Search field filters the stop list
- [x] Tapping a stop pushes bus arrivals screen
- [x] ~~Favorite toggle~~ Removed from stops screen; favorites managed on arrivals screen instead
- [x] Loading, error, and empty states handled
- [x] While loading, a shimmer effect is shown in place of the lists

### TODO 4.31 -- Bus directions and stops screens modal presentation
- [x] Complete

Present the bus directions and bus stops flow in a single modal sheet instead of pushing both screens on the app's main navigation stack. The routes screen opens a sheet whose root is the bus directions screen. The bus stops screen pushes within the sheet's own `NavigationStack`. When a stop is selected, the sheet dismisses and the bus arrivals screen is pushed onto the main navigation stack.

> **Note:** Sheet ↔ navigation handoff is coordinated by `BusRouteSheetCoordinator` (extracted for testability). The search tab's `NavigationStack` now uses an explicit `NavigationPath` for programmatic navigation after sheet dismissal.

**Acceptance Criteria:**
- [x] Tapping a bus route from Routes presents a modal sheet whose root is the bus directions screen
- [x] The modal sheet contains its own `NavigationStack`, and selecting a direction pushes the bus stops screen within that sheet
- [x] The bus directions and bus stops screens each provide a clear "Close" button that dismisses the sheet
- [x] Selecting a stop dismisses the sheet and then pushes the bus arrivals screen on the main navigation stack
- [x] Dismissing the sheet via Close button or swipe does not push bus arrivals or otherwise alter the main navigation path

### TODO 4.4 -- Bus arrivals screen
- [x] Complete

Show real-time arrivals for a bus stop. Header with stop info and favorite control. Arrival list with timing/delay info. Auto-refresh, manual refresh, last-updated display.

> **Note:** `RootView.makeFavoritesRepository()` was fixed — now uses `@State` for a single shared instance.

**Acceptance Criteria:**
- [x] Header: stop name, stop ID, favorite control
- [x] Each arrival: route number, direction, destination, distance (if available), countdown, clock time, day context, delayed badge
- [x] "Due" when imminent; "X min" countdown otherwise
- [x] Empty state when no arrivals
- [x] Auto-refresh every 30s, manual refresh, last-updated timestamp
- [x] Tapping an arrival pushes bus follow screen for that vehicle
- [x] While loading, a shimmer effect is shown in place of the lists

### TODO 4.41 -- Bus arrivals screen
- [x] Complete

Address the following issues in the bus arrivals screen:
- [x] Under the stop name, add a subtitle showing the direction for the stop. And next to it, the last udpated timestamp. So it would be like:

```Stop Name
Direction | Last refreshed at HH:mm:ss PM/AM
```
- [x] The shimmer loading effect should only be visible on the initial load, not during subsequent auto-refreshes or manual refreshes. However, to indicate a refresh ocurred, the arrival rows should shimmer without hiding the list. It is only to show the refresh happened, not to indicate loading. To indicate loading, the refresh button should show a ProgressView while the refresh is in-flight.

### TODO 4.41.1 -- Bus arrivals layout refresh
- [x] Complete

Refresh the visual layout of the bus arrivals screen to move away from the default `List` presentation. Use a custom scrolling layout with a more editorial header, full-width arrival rows, clearer row separation, and a matching skeleton state so loading and loaded layouts feel consistent.

> **Note:** Completed by switching the arrivals content and skeleton to `ScrollView`-based layouts, emphasizing the direction in the header, keeping the last refreshed timestamp visible, and adding custom row spacing/dividers plus a trailing disclosure chevron for each arrival row.

**Acceptance Criteria:**
- [x] Bus arrivals content uses a custom scrolling layout instead of the previous default list presentation
- [x] Header layout is refreshed while still surfacing direction and last refreshed context
- [x] Arrival rows use custom spacing and separators for a cleaner visual rhythm
- [x] The loading skeleton mirrors the refreshed arrivals layout

### TODO 4.42 -- Bus arrivals refresh behavior
- [x] Complete

Instead of showing a refresh button, implement pull-to-refresh on the bus arrivals list. The refresh button is removed from the header. The user can pull down on the list to trigger a manual refresh.

**Acceptance Criteria:**
- [x] Remove refresh button from the header
- [x] Implement pull-to-refresh on the arrivals list
- [x] While a manual refresh is in-flight, the native pull-to-refresh spinner is shown; skeleton is limited to initial load only

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

> **Note:** Ensure `RootView` uses a single shared `FavoritesRepository` instance rather than calling `makeFavoritesRepository()` inside `body` (see TODO 4.4 note).

> **Note:** `FavoritesView` shell with empty-state welcome message and read-only minimal list was introduced in TODO 1.5. This TODO builds on that foundation — adding row removal, clear-all, NavigationLinks to arrivals, and reactive data updates.

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
- [x] Cancelled — superseded by TODO 1.5

The Home tab was removed in the navigation refactor (TODO 1.5). Favorites is now the landing screen. This TODO is no longer applicable.

~~Build the Home tab as the app's landing screen. Displays app title and welcome context. Handles loading, success, and retry states if startup data loading is needed.~~

**Acceptance Criteria:**
- ~~Displays "CTA Tracker" title and welcome/landing content~~
- ~~Loading state and retry on failure if pre-loading startup data~~
- ~~Success state presents the landing experience~~

---

## Suggested Implementation Order

| Phase | TODOs | Rationale |
|-------|-------|-----------|
| 1 | 0.1, 1.1, 1.2 | Clean slate, networking, DTOs -- everything else depends on these |
| 2 | 1.3, 1.4 | Domain models, navigation skeleton |
| 3 | 2.1, 2.2, 2.3, 3.1, 3.2 | Repositories and shared infrastructure |
| 4 | 4.1, 4.2, 4.3, 4.4, 4.5 | Full bus flow -- validates the full stack |
| 5 | 5.1, 5.2, 5.3 | Full train flow -- builds on bus patterns |
| 6 | 6.1 | Favorites (Home removed in 1.5) |
