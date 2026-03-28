# LBus App
A real-time Chicago Transit Authority (CTA) bus and train tracker. The application allows users to browse transit routes, view stops, check real-time vehicle arrival predictions, and manage favorite stops. 

# TODOs
Read TODOS.md for a comprehensive list of features and improvements planned for the app.

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
