# SRR Reporting Engine: Safe Route App

This document details the functionality and implementation of the Safe Route Report (SRR) Engine, which is responsible for generating legally defensible travel reports. It covers the report schema, PDF generation logic, map snapshot rendering, hashing and integrity checks, share link expiry logic, data aggregation queries, and tamper prevention strategies.

## 1. Purpose

The primary purpose of the SRR Engine is to generate comprehensive and legally defensible travel reports for users. These reports serve multiple functions, including:

*   **Documentation**: Providing a detailed record of a journey, including safety metrics and any incidents.
*   **Legal Evidence**: Serving as potential evidence for police complaints, insurance claims, or other legal proceedings.
*   **Accountability**: Offering transparency into the app's safety assessments and monitoring during a trip.
*   **User Confidence**: Reassuring users of the app's commitment to their safety by providing verifiable journey summaries.

## 2. Report Schema

Each Safe Route Report is structured to include a wide array of data points, ensuring completeness and legal defensibility. The report schema encompasses user identity, journey specifics, safety diagnostics, and incident logs.

### 2.1. Report Includes:

*   **User Verified Identity**:
    *   User Name
    *   Verification Type (Aadhaar/PAN)
    *   Verification ID (masked)
*   **Journey ID**: Unique identifier for the specific journey.
*   **Route Selected**: Details of the route chosen by the user, including its initial safety score.
*   **Start & End Time**: Precise timestamps for the beginning and conclusion of the journey.
*   **Distance**: Total distance covered during the journey.
*   **Duration**: Actual duration of the journey.
*   **Safety Score**: The final calculated safety score for the actual path taken, reflecting real-time conditions and events.
*   **Crime Heat Summary**: Overview of crime incidents detected along the route, including severity and type.
*   **Commercial Exposure**: Number and types of commercial points (e.g., shops, ATMs, police stations) encountered, indicating areas of potential public presence.
*   **Route Map Image**: A visual representation of the actual route taken, with risk hotspots highlighted.
*   **SOS Logs (if any)**: Detailed records of any SOS triggers, including trigger source, timestamps, and location.
*   **Emergency Timestamps**: Specific timestamps related to emergency events (e.g., SOS activation, emergency contact notification).
*   **Report Generation Timestamp**: Date and time the report was generated.
*   **Unique Report ID**: A unique identifier for the report itself.
*   **Digital Integrity Hash**: A cryptographic hash to ensure the report's tamper-proof nature.

## 3. Output Options

Users have several options for accessing and sharing their Safe Route Reports:

*   **PDF Download**: The primary output format, allowing users to download a high-quality, printable PDF document directly to their device.
*   **Shareable Link**: A secure, time-limited web link that can be shared with others (e.g., family, authorities) to view the report online.
*   **Email Export**: Option to directly email the PDF report to a specified email address.
*   **Admin Copy**: An encrypted copy of the report is stored on the server for administrative access and auditing purposes.

## 4. PDF Generation Logic

PDF generation is a critical component, requiring the assembly of various data points and visual elements into a professional document.

*   **Backend Service**: PDF generation is handled by a dedicated backend service, likely a Celery task, to avoid blocking the main API thread due to its potentially resource-intensive nature.
*   **Templating**: A templating engine (e.g., Jinja2 for Python) is used to dynamically populate a pre-designed report template with journey-specific data.
*   **Libraries**: Libraries like `WeasyPrint` (for HTML to PDF conversion) or `ReportLab` (for direct PDF generation) in Python are suitable choices.
*   **Content Assembly**: The service aggregates all necessary data from PostgreSQL (journeys, routes, location logs, flags, crime data) and external services (e.g., map images).
*   **Map Snapshot Rendering**: A static image of the route map, highlighting risk hotspots, is generated and embedded into the PDF. This involves using a mapping API (e.g., Google Static Maps API) to render the route geometry and overlay relevant data.

## 5. Map Snapshot Rendering Logic

To visually represent the journey and its safety context, a static map image is generated for inclusion in the SRR.

*   **Route Geometry**: The `GEOMETRY(LINESTRING, 4326)` data from the `routes` table is used to draw the actual path taken by the user.
*   **Risk Hotspots**: Locations of crime incidents and user-flagged unsafe zones are overlaid on the map, potentially with color-coding to indicate severity.
*   **API Integration**: The backend service integrates with a static map API (e.g., Google Static Maps API) to generate a high-resolution image of the map with the route and hotspots.
*   **Custom Styling**: The map can be styled to match the app's branding and to clearly emphasize safety-related information.

## 6. Hashing & Integrity Check

To ensure the tamper-proof nature of the SRR, a digital integrity hash is included.

*   **SHA-256 Hashing**: After the PDF report is finalized, its entire content is subjected to a SHA-256 cryptographic hash function.
*   **Storage**: The resulting hash is stored alongside the report metadata in the `reports` table (`digital_hash` column).
*   **Verification**: Any future modification to the PDF will result in a different hash, allowing for easy detection of tampering. Users or authorities can verify the report's integrity by re-hashing the document and comparing it to the stored hash.

## 7. Share Link Expiry Logic

Shareable links for SRRs are designed with security and privacy in mind, incorporating expiration mechanisms.

*   **Unique Token**: A unique, cryptographically secure `share_link_token` is generated for each shareable report link.
*   **Time-Limited Access**: The `share_link_expires_at` timestamp in the `reports` table defines the validity period of the link (e.g., 7 days by default, configurable).
*   **Automatic Expiration**: After the expiration time, the link becomes invalid, and access to the report is denied.
*   **Manual Revocation**: Users or administrators can manually revoke a shareable link at any time, immediately invalidating it.
*   **Security**: The shareable link provides read-only access to the report and does not expose any other user data or system functionalities.

## 8. Data Aggregation Queries

Generating a comprehensive SRR requires aggregating data from multiple tables. Efficient PostGIS queries are crucial for this process.

*   **Journey Details**: Basic journey information is retrieved from the `journeys` table.
*   **Route Information**: Details of the selected route, including `path`, `distance`, `duration`, and initial `safety_score`, are fetched from the `routes` table.
*   **Location Logs**: The `journey_points` table is queried to reconstruct the actual path taken and calculate metrics like average speed and any deviations.
*   **Crime Data & Unsafe Zones**: Geospatial queries using PostGIS functions (e.g., `ST_Intersects`, `ST_DWithin`) are performed against the `crime_data` and `unsafe_zones` tables to identify incidents and flagged areas along the actual route taken.
*   **SOS Events**: Records from the `emergency_logs` (or similar) table are retrieved to include details of any SOS triggers.

## 9. Tamper Prevention Strategy

Beyond the digital integrity hash, several strategies are employed to prevent tampering with SRRs:

*   **Immutable Storage**: Generated PDF reports are stored in an immutable object storage service (e.g., AWS S3 with versioning enabled) to prevent unauthorized modification.
*   **Access Control**: Strict access control policies are applied to the storage location, limiting who can read, write, or delete reports.
*   **Audit Trails**: All actions related to report generation, access, and sharing are logged in an unalterable audit trail.
*   **Digital Signatures**: In a more advanced implementation, reports could be digitally signed using a private key, allowing for cryptographic verification of the report's origin and integrity by third parties.
