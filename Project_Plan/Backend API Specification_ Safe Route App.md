# Backend API Specification: Safe Route App

This document details the API endpoints for the Safe Route App backend, built using FastAPI. It serves as a contract for frontend developers and other interacting services, specifying routes, HTTP methods, request/response schemas, validation rules, error codes, rate limits, edge cases, and example payloads. WebSocket message formats are also included.

## 1. Authentication Endpoints (`/auth`)

### 1.1. User Signup (`POST /auth/signup`)

**Description**: Registers a new user, performs identity verification, and creates emergency contacts.

**HTTP Method**: `POST`

**Route**: `/auth/signup`

**Request Schema (`UserSignup`)**:
```json
{
  "phone": "string",
  "email": "string",
  "password": "string",
  "aadhar_number": "string",
  "pan_number": "string",
  "emergency_contacts": [
    {
      "name": "string",
      "phone": "string",
      "priority": 1
    }
  ]
}
```

**Validation Rules**:
*   `phone`: Required, valid Indian phone number format (`^[6-9]\d{9}$`).
*   `email`: Optional, valid email format.
*   `password`: Required, strong policy enforced (min 8 chars, includes uppercase, lowercase, number, special char).
*   `aadhar_number` or `pan_number`: One of them is required. Valid format for each.
*   `emergency_contacts`: List of 3 contacts required. Each contact must have `name`, `phone` (valid format), and `priority` (1-3).

**Response Schema (`TokenResponse`)**:
```json
{
  "token": "string",
  "user_id": "string"
}
```

**Error Codes**:
*   `400 Bad Request`: "Phone number already registered", "Aadhar verification failed", "PAN verification failed", "Aadhar or PAN required", "Invalid emergency contacts".
*   `500 Internal Server Error`: Generic server error.

**Edge Cases**:
*   Aadhar/PAN verification API downtime: User is informed, and signup can be retried later.
*   Duplicate phone number/email.

**Example Payload**:
```json
{
  "phone": "9876543210",
  "email": "user@example.com",
  "password": "StrongP@ssw0rd",
  "aadhar_number": "123456789012",
  "emergency_contacts": [
    {"name": "Mom", "phone": "9988776655", "priority": 1},
    {"name": "Dad", "phone": "9977665544", "priority": 2},
    {"name": "Friend", "phone": "9966554433", "priority": 3}
  ]
}
```

### 1.2. User Login (`POST /auth/login`)

**Description**: Authenticates an existing user and returns a JWT token.

**HTTP Method**: `POST`

**Route**: `/auth/login`

**Request Schema (`UserLogin`)**:
```json
{
  "phone": "string",
  "password": "string"
}
```

**Validation Rules**:
*   `phone`: Required, valid phone number format.
*   `password`: Required.

**Response Schema (`TokenResponse`)**:
```json
{
  "token": "string",
  "user_id": "string"
}
```

**Error Codes**:
*   `401 Unauthorized`: "Invalid credentials".
*   `403 Forbidden`: "Account deactivated".

**Edge Cases**:
*   Incorrect password attempts trigger rate limiting and account lockout.

**Example Payload**:
```json
{
  "phone": "9876543210",
  "password": "StrongP@ssw0rd"
}
```

## 2. Route Endpoints (`/routes`)

### 2.1. Calculate Routes (`POST /routes/calculate`)

**Description**: Initiates the calculation of safe routes between an origin and destination. Returns preliminary routes immediately, with safety scores calculated asynchronously.

**HTTP Method**: `POST`

**Route**: `/routes/calculate`

**Request Schema (`RouteRequest`)**:
```json
{
  "origin": {"lat": 12.9716, "lng": 77.5946},
  "destination": {"lat": 13.0827, "lng": 80.2707}
}
```

**Validation Rules**:
*   `origin`, `destination`: Required, valid latitude and longitude.

**Response Schema (`list[RouteResponse]`)**:
```json
[
  {
    "id": "string",
    "waypoints": [{"lat": 12.9716, "lng": 77.5946}],
    "distance": 25.5,
    "duration": 30,
    "safety_score": null, // Will be updated asynchronously
    "status": "calculating"
  }
]
```

**Error Codes**:
*   `400 Bad Request`: "Invalid coordinates", "Route not found".
*   `401 Unauthorized`: Invalid or missing JWT token.

**Rate Limits**: 10 requests per minute per user.

**Edge Cases**:
*   Google Maps API downtime: Fallback to cached routes or inform user.
*   No routes found between origin and destination.

**Example Payload**:
```json
{
  "origin": {"lat": 12.9716, "lng": 77.5946},
  "destination": {"lat": 13.0827, "lng": 80.2707}
}
```

### 2.2. Get Route Status (`GET /routes/status/{task_id}`)

**Description**: Checks the status of a route safety calculation task and returns updated route details if available.

**HTTP Method**: `GET`

**Route**: `/routes/status/{task_id}`

**Response Schema (`list[RouteResponse]`)**:
```json
[
  {
    "id": "string",
    "waypoints": [{"lat": 12.9716, "lng": 77.5946}],
    "distance": 25.5,
    "duration": 30,
    "safety_score": 85.7,
    "status": "completed"
  }
]
```

**Error Codes**:
*   `404 Not Found`: "Task ID not found".

## 3. Journey Endpoints (`/journeys`)

### 3.1. Start Journey (`POST /journeys/start`)

**Description**: Initializes a new journey, records it in the database, and optionally sends SMS to emergency contacts.

**HTTP Method**: `POST`

**Route**: `/journeys/start`

**Request Schema (`JourneyStart`)**:
```json
{
  "origin": {"lat": 12.9716, "lng": 77.5946},
  "destination": {"lat": 13.0827, "lng": 80.2707},
  "route_id": "string",
  "share_location": true
}
```

**Response Schema**:
```json
{
  "journey_id": "string",
  "tracking_url": "string" // Optional, if share_location is true
}
```

**Edge Cases**:
*   Twilio API failure: SMS sending will be retried via Celery task.

### 3.2. Complete Journey (`POST /journeys/complete`)

**Description**: Marks a journey as completed and updates its status.

**HTTP Method**: `POST`

**Route**: `/journeys/complete`

**Request Schema (`JourneyComplete`)**:
```json
{
  "journey_id": "string"
}
```

**Error Codes**:
*   `404 Not Found`: "Journey not found".

## 4. Emergency Endpoints (`/emergency`)

### 4.1. Trigger SOS (`POST /emergency/sos`)

**Description**: Triggers an SOS alert, notifies emergency contacts and services, and logs a forensic snapshot.

**HTTP Method**: `POST`

**Route**: `/emergency/sos`

**Request Schema**:
```json
{
  "journey_id": "string",
  "trigger_type": "button_press" | "voice_activated" | "stationary_timeout",
  "location": {"lat": 12.9716, "lng": 77.5946}
}
```

**Response Schema**:
```json
{
  "message": "SOS triggered successfully"
}
```

**Edge Cases**:
*   Twilio API failure: SMS sending retried.
*   Emergency services API failure: Logged and retried if possible.

## 5. Report Endpoints (`/reports`)

### 5.1. Generate SRR (`GET /reports/srr/{journey_id}`)

**Description**: Generates a Safe Route Report (SRR) for a completed journey.

**HTTP Method**: `GET`

**Route**: `/reports/srr/{journey_id}`

**Response Schema**:
```json
{
  "report_url": "string", // URL to the generated PDF
  "share_link": "string" // Shareable link
}
```

**Error Codes**:
*   `404 Not Found`: "Journey not found".

## 6. Flag Endpoints (`/map`)

### 6.1. Flag Unsafe Area (`POST /map/flag-unsafe`)

**Description**: Allows users to flag an unsafe area on the map.

**HTTP Method**: `POST`

**Route**: `/map/flag-unsafe`

**Request Schema**:
```json
{
  "lat": 12.9716,
  "lng": 77.5946,
  "user_id": "string",
  "reason": "string",
  "photo_url": "string" // Optional
}
```

**Response Schema**:
```json
{
  "message": "Area flagged successfully"
}
```

## 7. Feedback Endpoints (`/journeys`)

### 7.1. Submit Feedback (`POST /journeys/feedback`)

**Description**: Allows users to submit feedback and rate a completed journey.

**HTTP Method**: `POST`

**Route**: `/journeys/feedback`

**Request Schema**:
```json
{
  "journey_id": "string",
  "rating": 4,
  "feedback": "string",
  "unsafe_zone_disputed": false
}
```

**Response Schema**:
```json
{
  "message": "Feedback submitted successfully"
}
```

## 8. WebSocket Message Formats

### 8.1. Location Update (`location_update`)

**Direction**: Mobile App -> WebSocket Service

**Description**: Sends real-time GPS location updates from the mobile app to the server.

**Payload**:
```json
{
  "type": "location_update",
  "lat": 12.9716,
  "lng": 77.5946,
  "speed": 1.5, // Optional, meters/second
  "timestamp": "ISO 8601 datetime string"
}
```

### 8.2. SOS Alert (`sos_alert`)

**Direction**: Mobile App -> WebSocket Service

**Description**: Notifies the server of an SOS trigger.

**Payload**:
```json
{
  "type": "sos_alert",
  "lat": 12.9716,
  "lng": 77.5946,
  "trigger_type": "button_press" | "voice_activated" | "stationary_timeout",
  "timestamp": "ISO 8601 datetime string"
}
```

### 8.3. Location Broadcast (`location_broadcast`)

**Direction**: WebSocket Service -> Connected Clients (e.g., emergency contacts viewing tracking link)

**Description**: Broadcasts live location updates to clients tracking a journey.

**Payload**:
```json
{
  "type": "location_broadcast",
  "lat": 12.9716,
  "lng": 77.5946,
  "speed": 1.5,
  "timestamp": "ISO 8601 datetime string",
  "journey_status": "active" | "emergency"
}
```
