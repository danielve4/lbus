# LBus App
A real-time Chicago Transit Authority (CTA) bus and train tracker. The application allows users to browse transit routes, view stops, check real-time vehicle arrival predictions, and manage favorite stops. 

# TODOs
Read TODOS.md for a comprehensive list of features and improvements planned for the app.

# Planning mode
While planning, ask any questions using the tool you have access to (e.g. AskUserQuestion, #tool:vscode/askQuestions) regarding the implementation of the TODO you are planning.

# API Host
https://cta.danielvega.dev

## API Endpoints

### Bus
- `GET /busroutes` — All CTA bus routes
- `GET /busroutedirections?route={id}` — Directions for a route
- `GET /busroutestops?route={id}&direction={dir}` — Stops for a route/direction
- `GET /busstoparrivals?stopId={id}` — Real-time arrival predictions for a stop
- `GET /busfollow?vehicleId={id}` — Track a specific bus

### Train
- `GET /trainstoparrivals?stopId={id}` — Real-time train arrivals
- `GET /trainfollow?vehicleId={id}` — Track a specific train
- `GET /traindata` - Comprehensive train data including routes, directions, and stops

### Favorites
- `POST /savefavorites` — Save favorites (body: `{ id: phone, favorites: [...] }`)
- `POST /myfavorites` — Retrieve favorites (body: `{ id: phone }`)

# Notes
After implementation of a feature, update the corresponding TODO item in TODOS.md with a checkmark and a brief note on completion. This helps track progress and ensures all acceptance criteria are met. Then, summarize the changes in a list (not in TODOS.md).