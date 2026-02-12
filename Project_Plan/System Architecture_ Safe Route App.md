# System Architecture: Safe Route App

## 1. Full Service Interaction Diagram (Textual)

The Safe Route App employs a robust, layered architecture designed for scalability, security, and real-time performance. The primary interaction flows are depicted below, illustrating how various components communicate to deliver the application's core functionalities.

```mermaid
graph TD
    A[Mobile App (Flutter/React Native)] -- HTTPS/WSS --> B(API Gateway)
    B -- HTTPS --> C{FastAPI Backend}
    B -- WSS --> D[WebSocket Service]

    C -- DB Queries --> E[PostgreSQL + PostGIS]
    C -- Cache Reads/Writes --> F[Redis Cache]
    C -- Task Queue --> G[Celery Task Queue]
    C -- External API Calls --> H(External Services)

    D -- DB Writes --> E
    D -- Cache Reads/Writes --> F
    D -- Task Queue --> G

    G -- External API Calls --> H
    G -- DB Writes --> E

    H -- Identity Verification --> I[Aadhaar/PAN API]
    H -- Mapping/Places --> J[Google Maps API]
    H -- SMS --> K[Twilio]
    H -- AI Analysis --> L[Google Gemini AI]

    E -- Geospatial Queries --> E

    SubGraph External Services
        I
        J
        K
        L
    End

    SubGraph Backend Services
        C
        D
        G
    End

    SubGraph Data Stores
        E
        F
    End

    style A fill:#f9f,stroke:#333,stroke-width:2px
    style B fill:#bbf,stroke:#333,stroke-width:2px
    style C fill:#ccf,stroke:#333,stroke-width:2px
    style D fill:#cfc,stroke:#333,stroke-width:2px
    style E fill:#ffc,stroke:#333,stroke-width:2px
    style F fill:#fcf,stroke:#333,stroke-width:2px
    style G fill:#fcc,stroke:#333,stroke-width:2px
    style H fill:#cff,stroke:#333,stroke-width:2px
    style I fill:#eee,stroke:#333,stroke-width:1px
    style J fill:#eee,stroke:#333,stroke-width:1px
    style K fill:#eee,stroke:#333,stroke-width:1px
    style L fill:#eee,stroke:#333,stroke-width:1px
```

## 2. Request Lifecycle

### 2.1. Login Request Lifecycle

1.  **User Action**: Mobile app sends user credentials (phone, password) to the API Gateway via HTTPS.
2.  **API Gateway**: Performs rate limiting, SSL termination, and forwards the request to the FastAPI Backend.
3.  **FastAPI Backend (`/auth/login`)**:
    *   Receives credentials.
    *   Queries PostgreSQL to retrieve user record based on phone number.
    *   Verifies password hash using `bcrypt.checkpw`.
    *   If successful, generates a JSON Web Token (JWT) using `AuthService.create_access_token`.
    *   Stores the JWT in Redis cache for session management.
    *   Returns the JWT and user ID to the mobile app.
4.  **Mobile App**: Stores the JWT securely (e.g., Expo SecureStore) for subsequent authenticated requests.

### 2.2. Journey Request Lifecycle (Route Calculation)

1.  **User Action**: User inputs destination on the mobile app, triggering a route calculation request to the API Gateway.
2.  **API Gateway**: Forwards the request to the FastAPI Backend (`/routes/calculate`).
3.  **FastAPI Backend (`/routes/calculate`)**:
    *   Authenticates the user via JWT.
    *   Calls `RouteService.get_google_routes` to fetch 3-5 base routes from Google Maps Directions API.
    *   Creates a unique `task_id` for the background safety analysis.
    *   Adds a `calculate_safe_routes` task to the Celery Task Queue, passing the Google routes, user ID, and `task_id`.
    *   Immediately returns the basic Google routes to the mobile app with a `status: 'calculating'` and `safety_score: null`.
4.  **Celery Task Queue (`calculate_safe_routes`)**:
    *   For each route:
        *   Extracts detailed waypoints (e.g., every 100m).
        *   Queries PostGIS for crime data within a radius (e.g., 500m) around each waypoint.
        *   Queries the database for user-flagged unsafe zones.
        *   Uses Google Places API to identify commercial points (shops, ATMs, police stations).
        *   Sends aggregated crime data to Google Gemini AI for detailed severity analysis and risk assessment.
        *   Calculates a comprehensive safety score based on weighted factors (crime data, user flags, commercial points, lighting).
        *   Updates the route record in PostgreSQL with the calculated safety score and detailed safety diagnostics.
        *   Optionally, pushes updates to Redis for real-time status retrieval by the mobile app.
5.  **Mobile App**: Displays preliminary routes. Periodically polls the FastAPI Backend (`/routes/status/{task_id}`) or listens for WebSocket updates to retrieve the final safety scores and detailed route information.

### 2.3. Emergency Request Lifecycle (SOS Trigger)

1.  **User Action**: SOS is triggered via button (5s press), voice command ("HELP SAFE APP"), or stationary deadman switch timeout on the mobile app.
2.  **Mobile App**:
    *   Switches journey state to `EMERGENCY`.
    *   Increases GPS update frequency (e.g., to 1 second).
    *   Vibrates the phone (3 short bursts).
    *   Sends an immediate SOS alert via WebSocket to the WebSocket Service (`/ws/journey/{journey_id}`).
    *   Sends an HTTP POST request to the FastAPI Backend (`/emergency/sos`) with `journeyId`, `triggerType`, and `currentLocation`.
3.  **WebSocket Service**:
    *   Receives the SOS alert.
    *   Broadcasts the emergency status and high-frequency location updates to all connected emergency contacts (if sharing is enabled).
4.  **FastAPI Backend (`/emergency/sos`)**:
    *   Locks the journey state to `EMERGENCY` in PostgreSQL.
    *   Logs a forensic snapshot containing critical details (last 10 locations, speed, trigger source, device state, battery level) immutably in PostgreSQL.
    *   Triggers a Celery task to:
        *   Send SMS alerts to the user's 3 emergency contacts via Twilio, including a live tracking link.
        *   Notify local emergency services (e.g., 112/police) via an integrated API.
5.  **Emergency Contacts**: Receive SMS with tracking link, allowing them to monitor the user's live location.

## 3. WebSocket Lifecycle

WebSockets are critical for real-time communication, particularly for live journey tracking and emergency alerts.

1.  **Connection Establishment**: When a user starts a journey, the mobile app establishes a WebSocket connection to the `/ws/journey/{journey_id}` endpoint on the WebSocket Service.
2.  **Location Updates**: During an active journey, the mobile app continuously sends GPS location updates (e.g., every 5 seconds) via the WebSocket to the server.
3.  **Server-Side Processing**: The WebSocket Service receives these updates, logs them to PostgreSQL (`LocationLog` table), and stores the latest location in Redis with a short TTL for quick retrieval.
4.  **Emergency Broadcast**: In an emergency, the WebSocket Service broadcasts the high-frequency location updates to all connected clients associated with that `journey_id` (i.e., emergency contacts viewing the tracking link).
5.  **Disconnection**: The WebSocket connection is gracefully closed when the journey is completed or cancelled, or if the client explicitly disconnects.

## 4. Background Task Execution Logic

Celery, with Redis as a broker, is used for asynchronous and computationally intensive tasks to prevent blocking the main API thread and improve responsiveness.

*   **Route Safety Analysis**: The `calculate_safe_routes` task, as detailed in the Journey Request Lifecycle, is the primary background task. It involves multiple external API calls (Google Maps, Gemini AI, Google Places) and complex geospatial queries against PostGIS.
*   **SMS Notifications**: Sending SMS to emergency contacts via Twilio is offloaded to a background task to ensure non-blocking execution and retry mechanisms in case of external service failures.
*   **Report Generation**: Complex report generation, especially PDF creation with map rendering, can be a background task to avoid user waiting times.
*   **Data Aggregation/Recalibration**: Tasks related to aggregating user flags, recalibrating safety scores, and AI model retraining are executed asynchronously.

## 5. Redis State Management

Redis is strategically used for high-speed data access and temporary state management:

*   **Session Management**: Stores JWT tokens and user session data for quick authentication and authorization checks.
*   **Live GPS Tracking**: Temporarily stores the latest GPS coordinates for active journeys, enabling rapid retrieval for WebSocket broadcasts to emergency contacts.
*   **Task Status**: Stores the status and intermediate results of long-running Celery tasks (e.g., route safety calculation status) to allow the mobile app to poll for updates.
*   **Rate Limiting**: Implements API rate limiting by tracking request counts per user/IP address.
*   **Caching**: Caches frequently accessed data, such as base Google Maps routes, to reduce API calls and improve response times.

## 6. Failure Fallback Strategies

*   **External API Failures**: If a third-party API (e.g., Google Maps, Aadhaar, Gemini) fails, the system will:
    *   **Retry**: Implement exponential backoff for transient errors.
    *   **Fallback**: Use cached data if available (e.g., for route information). For critical services like Aadhaar verification, inform the user and prompt for manual verification or re-attempt later.
    *   **Graceful Degradation**: For non-critical features (e.g., detailed AI crime analysis), proceed with available data and inform the user of partial results.
*   **Database/Cache Outages**: 
    *   **Database**: Implement connection pooling and automatic failover for PostgreSQL. Critical writes (e.g., emergency logs) might be temporarily queued and retried.
    *   **Redis**: If Redis is unavailable, the system will fall back to direct database queries for session data (with performance degradation) or temporarily disable caching.
*   **Network Connectivity (Mobile App)**: The mobile app queues location updates and other critical data when offline, syncing them with the backend once connectivity is restored.

## 7. Retry Policies

Retry mechanisms are implemented for external API calls and background tasks to enhance system resilience:

*   **API Calls**: A decorator-based retry logic (e.g., `tenacity` library in Python) is applied to external API calls with configurable retries and exponential backoff.
*   **Celery Tasks**: Celery tasks are configured with `max_retries` and `countdown` (delay between retries) to handle transient failures, ensuring critical operations like SMS sending eventually succeed.

## 8. Logging Strategy

A comprehensive logging strategy is crucial for debugging, auditing, and forensic analysis:

*   **Structured Logging**: All logs are generated in a structured format (e.g., JSON) to facilitate easy parsing and analysis by monitoring tools.
*   **Log Levels**: Utilize standard log levels (DEBUG, INFO, WARNING, ERROR, CRITICAL) to control verbosity.
*   **Centralized Logging**: Logs from all services (FastAPI, WebSocket, Celery, Mobile App) are aggregated into a centralized logging system (e.g., ELK stack, Datadog) for unified monitoring.
*   **Sensitive Data Redaction**: PII and other sensitive information are automatically redacted from logs before storage to comply with privacy regulations.
*   **Audit Logs**: Critical actions (e.g., user login, SOS trigger, admin actions) are recorded in immutable audit logs for compliance and forensic purposes.

## 9. Observability Hooks

Observability is built into the system to provide deep insights into its health and performance:

*   **Metrics**: Prometheus/Grafana are used to collect and visualize key metrics (e.g., API response times, error rates, CPU/memory usage, queue lengths, WebSocket connection counts).
*   **Tracing**: Distributed tracing (e.g., OpenTelemetry) is implemented to track requests across microservices, aiding in performance bottleneck identification.
*   **Alerting**: PagerDuty/Opsgenie are integrated to trigger alerts based on predefined thresholds for critical metrics or error rates.
*   **Health Checks**: Each service exposes health check endpoints (`/health`, `/ready`) for load balancers and orchestrators.

## 10. Security Boundaries

Security boundaries are established at multiple layers to protect the system and user data:

*   **API Gateway**: Acts as the first line of defense, handling SSL termination, DDoS protection, and initial rate limiting.
*   **Authentication/Authorization**: JWT-based authentication and role-based access control (RBAC) are enforced at the FastAPI backend for all API endpoints.
*   **Network Segmentation**: Backend services are deployed in private subnets, accessible only through the API Gateway. Databases are isolated.
*   **Data Encryption**: Data is encrypted both in transit (TLS/SSL for HTTPS/WSS) and at rest (database encryption, S3 encryption).
*   **Input Validation**: Strict input validation is performed at the API layer to prevent injection attacks and other vulnerabilities.
*   **Least Privilege**: Services and users are granted only the minimum necessary permissions to perform their functions.

## 11. Data Flow Diagrams

### 11.1. High-Level Data Flow

```mermaid
graph LR
    A[User (Mobile App)] -- Location, Destination, SOS --> B(API Gateway)
    B -- Forward Request --> C[FastAPI Backend]
    B -- Real-time Location/SOS --> D[WebSocket Service]
    C -- Store/Retrieve Data --> E[PostgreSQL/PostGIS]
    C -- Cache Data --> F[Redis Cache]
    C -- Queue Tasks --> G[Celery Task Queue]
    G -- Process Tasks --> C
    C -- External Data/Services --> H[External APIs (Google Maps, Gemini, Twilio, Aadhaar)]
    D -- Store Location --> E
    D -- Broadcast Location --> A
    E -- Geospatial Data --> C
    H -- Return Data --> C
```

### 11.2. Route Calculation Data Flow

```mermaid
graph LR
    A[Mobile App] -- Request Route (Origin, Destination) --> B(FastAPI Backend)
    B -- Get Base Routes --> C[Google Maps API]
    C -- Return Base Routes --> B
    B -- Queue Safety Analysis --> D[Celery Task Queue]
    D -- Process Route 1 --> E[PostGIS (Crime Data, Unsafe Zones)]
    D -- Process Route 2 --> E
    D -- Process Route 3 --> E
    E -- Return Geospatial Data --> D
    D -- Get Commercial Points --> F[Google Places API]
    F -- Return Places Data --> D
    D -- Analyze Crime Data --> G[Google Gemini AI]
    G -- Return AI Analysis --> D
    D -- Calculate Safety Score --> D
    D -- Store Final Route Data --> H[PostgreSQL (Routes Table)]
    H -- Update Mobile App (via polling/WS) --> A
```

### 11.3. Live Monitoring & SOS Data Flow

```mermaid
graph LR
    A[Mobile App] -- Start Journey --> B(FastAPI Backend)
    B -- Create Journey Record --> C[PostgreSQL]
    B -- Send SMS (Emergency Contacts) --> D[Twilio]
    A -- Establish WebSocket --> E[WebSocket Service]
    A -- Send Location Updates (5s) --> E
    E -- Store Location Log --> C
    E -- Cache Latest Location --> F[Redis Cache]
    A -- SOS Triggered (Button/Voice/Deadman) --> E
    E -- Broadcast SOS/High-Freq Location --> A[Emergency Contacts (via Web Portal)]
    E -- Notify FastAPI Backend --> B
    B -- Lock Journey State, Log Forensic Snapshot --> C
    B -- Send SMS (Emergency Contacts) --> D
    B -- Notify Emergency Services --> G[Emergency Services API]
```
