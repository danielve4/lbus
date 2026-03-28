# CTA Tracker iOS Functional Specification

## Document Purpose

This document describes the existing front-end product behavior that shall be represented in an iOS application. It is written as a functional product specification rather than a technical implementation plan.

The scope of this document focuses on the current user-facing transit flows already present in the project:

- Viewing bus routes, directions, stops, and arrivals
- Viewing train lines, stations, and arrivals
- Favoriting bus stops and train stations
- Viewing a favorites list and returning to arrivals from that list
- Following a bus or train from an arrival result
- Manual refresh and automatic refresh every 30 seconds on arrival and follow views
- Displaying user-facing delay and arrival timing information
- Providing a native settings surface for appearance and refresh behavior

This document does not introduce net-new transit features beyond those flows.

---

## Product Summary

CTA Tracker is a mobile transit application for viewing real-time Chicago Transit Authority bus and train information.

The app supports two primary transit modes:

- Bus
- Train

The app allows a user to:

- Browse available bus and train routes
- Move from route selection to stop or station selection
- View upcoming arrivals for a selected stop or station
- Favorite a stop or station for quick return access
- Open a follow view for a specific bus or train from an arrival result
- Refresh live information manually and automatically

---

## Primary Navigation

The current product behavior includes the following top-level sections:

- Home
- Routes
- Favorites

For iOS, these same functional areas shall be represented as first-class app sections, with a native settings section also available to expose app preferences.

### Home

The Home screen acts as the landing screen of the app.

The Home screen shall:

- Present the app as CTA Tracker
- Serve as the main entry point into the transit browsing experience
- Support the general app state of loading, success, and retry when startup transit data cannot be loaded

This specification intentionally does not define any expanded dashboard content beyond the landing purpose above.

### Routes

The Routes section is the main transit browsing surface.

It shall allow a user to:

- Search available train routes
- Search available bus routes
- Select a train route to view stations
- Select a bus route to view directions

### Favorites

The Favorites section is the saved-stop surface.

It shall allow a user to:

- View all saved favorites
- Open arrivals from a saved favorite
- Remove an individual favorite
- Clear all favorites

### Settings

The iOS app shall include a Settings section for app-level preferences related to the current product behavior.

At minimum, the Settings section shall provide:

- Theme selection
- Auto-refresh preference
- Refresh interval display and control for live screens
- Data and saved-item management actions relevant to the app experience

The settings content shall remain limited to app preferences and shall not introduce unrelated account or social features.

---

## Transit Mode Coverage

## Bus

The bus experience shall support:

- Route list
- Direction selection for a route
- Stop list for a selected route and direction
- Stop search within the stop list
- Upcoming arrivals for a stop
- Follow view for a specific vehicle from an arrival result
- Favoriting a stop

## Train

The train experience shall support:

- Train line list
- Station list for a selected line
- Station search within the station list
- Upcoming arrivals for a station
- Route-filtered train arrivals when the user came from a specific train line
- Follow view for a specific train run from an arrival result
- Favoriting a station

---

## Core User Flows

## 1. Bus route to bus arrivals

The bus flow shall be:

1. User opens Routes
2. User searches or browses the available bus routes
3. User selects a bus route
4. User selects one of that route's directions
5. User views the stops for that route and direction
6. User may search within the stop list
7. User selects a stop
8. User is taken to the bus arrivals screen for that stop

### Bus stop list requirements

The bus stop list shall:

- Show the stop name
- Show the stop identifier as part of the stop information
- Allow each stop to be favorited directly from the list
- Allow the user to open arrivals for a stop

## 2. Train line to train arrivals

The train flow shall be:

1. User opens Routes
2. User searches or browses the available train lines
3. User selects a train line
4. User views the stations served by that line
5. User may search within the station list
6. User selects a station
7. User is taken to the train arrivals screen for that station

When the user entered the station from a specific line, the train arrivals screen shall preserve that line context.

### Train station list requirements

The train station list shall:

- Show station names
- Allow station search
- Allow the user to open arrivals for a station

## 3. Favoriting a stop or station

The user shall be able to favorite:

- A bus stop
- A train station

A favorite action shall be available from:

- The bus stop list
- The bus arrivals screen
- The train arrivals screen

A favorite shall preserve enough context to let the user return to the relevant arrivals experience later.

For user-facing behavior, favoriting shall support:

- Add favorite
- Remove favorite
- Clear all favorites
- Persist favorites between app launches

## 4. Using Favorites

The favorites flow shall be:

1. User opens Favorites
2. User views all saved favorites
3. User selects a favorite
4. User is taken directly to the arrivals screen associated with that favorite

For a saved bus favorite, the destination is the bus arrivals view for that stop.

For a saved train favorite, the destination is the train arrivals view for that station. If the favorite was saved in the context of a specific train line, that line context shall be preserved when reopening the favorite.

## 5. Following a bus from an arrival result

The bus follow flow shall be:

1. User opens the bus arrivals screen for a stop
2. User selects one arrival result associated with a vehicle
3. User is taken to the follow view for that specific bus vehicle

The follow view shall represent the upcoming stop progression for that bus vehicle.

## 6. Following a train from an arrival result

The train follow flow shall be:

1. User opens the train arrivals screen for a station
2. User selects one arrival result associated with a train run
3. User is taken to the follow view for that specific train run

The follow view shall represent the upcoming stations and current train movement details for that train run.

---

## Screen Specifications

## Home Screen

The Home screen shall:

- Display the app title and welcome context
- Provide the app landing experience
- Support loading, success, and retry states if startup transit data cannot be loaded

The Home screen is not required to function as the main live arrivals surface.

## Routes Screen

The Routes screen shall:

- Present both train lines and bus routes
- Support a search field that filters the visible route lists
- Allow selection of:
  - A train line to move into train stations
  - A bus route to move into bus directions

The search shall support matching route identifiers and route names where applicable.

## Bus Direction Screen

The Bus Direction screen shall:

- Show the selected bus route
- Show the directions available for that route
- Allow the user to select a direction
- Provide a way to return to the route list

## Bus Stops Screen

The Bus Stops screen shall:

- Show the selected route and direction
- Show the list of stops for that route-direction combination
- Support searching the stop list
- Allow each stop to be opened
- Allow each stop to be favorited from the list
- Provide a way to return to the direction list

Each stop entry shall present:

- Stop name
- Stop identifier
- Favorite control

## Train Stations Screen

The Train Stations screen shall:

- Show the selected train line
- Show the list of stations served by that line
- Support station search
- Allow each station to be opened
- Provide a way to return to the route list

Each station entry shall present:

- Station name

## Favorites Screen

The Favorites screen shall:

- Show all saved favorites in one list
- Support an empty state when no favorites exist
- Support individual favorite removal
- Support clearing all favorites
- Allow tapping a saved favorite to open arrivals

Each favorite entry shall present:

- Favorite name
- Transit type, bus or train
- Route or line context when available
- Direction when available
- A removal control

The empty state shall communicate that no favorite stops have been saved yet.

## Bus Arrivals Screen

The Bus Arrivals screen shall present upcoming arrivals for a selected bus stop.

### Header content

The header shall show:

- Stop name, when available
- Stop identifier
- Favorite control for the stop

### Refresh behavior

The screen shall support:

- Automatic refresh every 30 seconds
- Manual refresh initiated by the user
- A visible last-updated time

### Arrival list content

Each bus arrival entry shall show:

- Route number
- Route direction
- Destination
- Distance from the stop when available
- Countdown until arrival
- Clock time of the predicted arrival
- Day context for the arrival time, such as today or tomorrow
- Delayed status when applicable

### Bus arrival state presentation

The bus arrivals screen shall support the following user-visible timing states:

- Due now
- X minutes until arrival
- No upcoming arrivals for this stop

If a bus arrival is delayed, the screen shall show a visible delayed indicator for that arrival.

If a separate scheduled label is not available for the current user-facing state, the screen shall continue to present the arrival time and countdown without introducing a distinct scheduled badge.

### Bus arrival navigation

Selecting a bus arrival entry shall open the bus follow view for the vehicle associated with that arrival.

## Train Arrivals Screen

The Train Arrivals screen shall present upcoming train arrivals for a selected station.

### Header content

The header shall show:

- Station name, when available
- Station identifier
- Favorite control for the station
- The train lines serving the station, when available

### Refresh behavior

The screen shall support:

- Automatic refresh every 30 seconds
- Manual refresh initiated by the user
- A visible last-updated time

### Arrival list organization

The train arrivals screen shall group results by:

- Train line
- Direction or destination grouping

### Train arrival content

Each train arrival entry shall show:

- Train line
- Destination
- Run number
- Countdown until arrival
- Clock time of the predicted arrival
- Day context for the arrival time, such as today or tomorrow
- Approaching status when applicable
- Delayed status when applicable
- Service alert status when applicable

### Train arrival state presentation

The train arrivals screen shall support the following user-visible timing states:

- Due now
- X minutes until arrival
- No upcoming train arrivals for this station

If a train is delayed, the screen shall show a visible delayed indicator for that arrival.

If a separate scheduled label is not surfaced in the current user-facing view, the screen shall continue to present the arrival time and countdown without introducing a distinct scheduled badge.

### Train arrival navigation

Selecting a train arrival entry shall open the train follow view for the run associated with that arrival.

## Bus Follow Screen

The Bus Follow screen shall present the upcoming stop progression for a selected bus vehicle.

### Bus follow header

The screen shall show:

- Vehicle identifier
- Context that the user is viewing real-time predictions for that vehicle

### Refresh behavior

The screen shall support:

- Automatic refresh every 30 seconds
- Manual refresh initiated by the user

### Bus follow list content

The follow list shall show upcoming stops for the selected vehicle.

Each upcoming stop entry shall show:

- Stop name
- Stop identifier
- Route number
- Destination
- Countdown until arrival
- Delay status when applicable
- Route direction

### Highlighted stop behavior

If the follow view was opened from a specific stop, that stop shall be visually identifiable in the follow list as the stop the vehicle is approaching relative to the user's prior context.

### Bus follow empty and error states

The screen shall support:

- Loading state
- Error state
- Empty state when no predictions are available for the selected vehicle

## Train Follow Screen

The Train Follow screen shall present live tracking details for a selected train run.

### Train follow header

The screen shall show:

- Train run number
- Context that the user is following a specific train

### Refresh behavior

The screen shall support:

- Automatic refresh every 30 seconds
- Manual refresh initiated by the user

### Upcoming station list content

The follow list shall show upcoming stations for the selected train run.

Each upcoming station entry shall show:

- Station name
- Platform or stop description when available
- Train line
- Destination
- Travel direction
- Countdown until arrival
- Clock time of arrival
- Day context for the arrival time, such as today or tomorrow
- Approaching status when applicable
- Delayed status when applicable
- Service alert status when applicable

### Highlighted station behavior

If the follow view was opened from a specific station, that station shall be visually identifiable in the follow list as the station relevant to the user's prior context.

### Train follow empty and error states

The screen shall support:

- Loading state
- Error state
- Empty state when no arrival information is available for the selected train

---

## Refresh Behavior

Live screens shall refresh automatically every 30 seconds.

This applies to:

- Bus arrivals
- Train arrivals
- Bus follow
- Train follow

Live screens shall also support manual refresh initiated by the user.

The user shall be able to see when the data was last refreshed on arrival screens.

If a refresh is in progress, the screen shall show that the content is refreshing.

---

## Favorites Behavior

Favorites are stop-based and station-based saved items.

A favorite shall include the user-facing context needed to make the saved item meaningful later, including where applicable:

- Name
- Transit type
- Route or line context
- Direction context

Favorites shall support:

- Add
- Remove
- Clear all
- Reopen

A saved favorite shall reopen the correct arrivals destination directly.

---

## User-Facing Status and Timing Language

## Bus timing and status

The bus experience shall communicate:

- Due now
- Countdown in minutes
- Predicted arrival clock time
- Day context for the arrival
- Delayed status when applicable

If distance information is available, the bus arrival shall also communicate how far away the bus is from the stop.

## Train timing and status

The train experience shall communicate:

- Due now
- Countdown in minutes
- Predicted arrival clock time
- Day context for the arrival
- Delayed status when applicable
- Service alert status when applicable

The train follow experience shall also communicate movement-related details such as direction, destination, and current heading when available.

## Scheduled versus delayed presentation

Where the current product explicitly surfaces a delay state, the iOS app shall show a visible delayed indicator.

Where the current product presents countdown and arrival-time information without a distinct scheduled badge, the iOS app shall preserve that same presentation rather than inventing a separate scheduled-only state treatment.

---

## Search Behavior

Search shall be supported in the following areas:

- Route list
- Bus stop list
- Train station list

Search shall filter visible items in the current list and shall not require leaving the screen.

---

## Empty, Loading, and Error States

The iOS app shall preserve the existing product behavior of explicitly handling:

- Loading states
- Error states
- Empty states

Examples include:

- No favorites saved
- No routes available
- No stops available for a selected route and direction
- No stations available for a selected train line
- No upcoming arrivals for a selected stop or station
- No follow data available for a selected vehicle or train

Where retry is available in the current product flow, the iOS app shall provide an equivalent retry action.

---

## Settings Screen Requirements

The iOS app shall provide a settings screen that exposes app-level preferences related to existing app behavior.

### Settings content

The Settings screen shall include:

- Theme
  - System default
  - Light
  - Dark
- Auto-refresh preference
  - On
  - Off
- Refresh interval information for live transit screens
- App data management actions for saved content, including favorites-related management

### Settings intent

The purpose of Settings is to let the user control how the existing live transit experience behaves on device, without changing the core transit flows described elsewhere in this specification.

---

## Out of Scope for This Specification

This document does not define:

- Back-end or API implementation details
- Persistence technology choices
- Native architectural patterns
- Push notifications
- Account systems
- Social features
- Trip planning beyond the route, stop, arrivals, favorite, and follow flows already described
