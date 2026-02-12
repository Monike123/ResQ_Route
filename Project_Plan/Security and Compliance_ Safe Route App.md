# Security and Compliance: Safe Route App

This document outlines the comprehensive security and compliance framework for the Safe Route App. Given the sensitive nature of the data handled (user identity, location, emergency contacts), a robust security posture is paramount. The framework covers data encryption, authentication strategies, PII handling, compliance with Indian regulations, logging and redaction rules, access control, threat modeling, and secure coding practices.

## 1. Data Encryption Model

Data is protected at all stages of its lifecycle through a multi-layered encryption model.

### 1.1. Encryption in Transit

*   **HTTPS/WSS**: All communication between the mobile app and the backend services (API Gateway, WebSocket Service) is encrypted using Transport Layer Security (TLS) 1.2 or higher. This ensures that data transmitted over the network is protected from eavesdropping and man-in-the-middle attacks.
*   **SSL Termination**: SSL termination is handled at the API Gateway (e.g., NGINX, Cloudflare), which then communicates with backend services over a secure private network.

### 1.2. Encryption at Rest

*   **Database Encryption**: The PostgreSQL database is configured with Transparent Data Encryption (TDE) to encrypt the entire database at rest. This protects data even if the physical storage is compromised.
*   **S3 Encryption**: All generated Safe Route Reports (SRRs) and other files stored in AWS S3 are encrypted using Server-Side Encryption with Amazon S3-Managed Keys (SSE-S3) or AWS Key Management Service (SSE-KMS).
*   **Mobile App Storage**: Sensitive data stored on the mobile device, such as authentication tokens and user ID, is encrypted using `expo-secure-store`, which leverages native secure storage mechanisms (iOS Keychain, Android Keystore).

## 2. JWT Strategy

JSON Web Tokens (JWT) are used for stateless authentication and authorization.

*   **Access Tokens**: Short-lived access tokens (e.g., 15-minute expiry) are issued upon successful login. These tokens are used to authenticate API requests.
*   **Refresh Tokens**: Long-lived refresh tokens (e.g., 30-day expiry) are also issued and stored securely on the mobile device. They are used to obtain new access tokens without requiring the user to log in again.
*   **Refresh Token Rotation**: For enhanced security, refresh tokens are rotated upon each use. When a refresh token is used to obtain a new access token, a new refresh token is also issued, and the old one is invalidated.
*   **Token Invalidation**: Upon logout, both access and refresh tokens are invalidated on the server-side (e.g., by adding them to a denylist in Redis) to prevent their reuse.

## 3. PII Handling Policy

Personal Identifiable Information (PII) is handled with utmost care, adhering to the principles of data minimization and purpose limitation.

*   **Data Minimization**: Only the necessary PII is collected. For example, Aadhaar/PAN numbers are used for verification but not stored directly; only a verification status and a hashed reference are retained.
*   **Purpose Limitation**: PII is used only for the specific purposes for which it was collected (e.g., identity verification, emergency contact notification).
*   **Anonymization/Pseudonymization**: Where possible, data is anonymized or pseudonymized for analytics and research purposes.
*   **User Consent**: Explicit user consent is obtained for the collection and processing of PII, with clear explanations of how the data will be used.

## 4. Aadhaar Compliance Notes

Compliance with Indian regulations regarding Aadhaar data is strictly enforced.

*   **No Storage of Aadhaar Number**: The actual Aadhaar number is not stored in the database. It is used only for the one-time verification process via a secure, authorized API.
*   **Secure API Integration**: The app integrates with a licensed Application User Agency (AUA) or KYC User Agency (KUA) to perform Aadhaar verification, ensuring compliance with UIDAI guidelines.
*   **Data Masking**: Any display of Aadhaar-related information is masked to prevent exposure of the full number.

## 5. Logging Redaction Rules

To prevent sensitive data from being exposed in logs, automatic redaction rules are applied.

*   **PII Redaction**: Fields containing PII (e.g., phone numbers, email addresses, names, Aadhaar/PAN numbers) are automatically masked or redacted from logs before they are stored.
*   **Location Data Redaction**: While location data is essential for debugging, it is handled with care. In non-production environments, location data may be obfuscated or generalized.
*   **Password Redaction**: Passwords and other credentials are never logged.

## 6. Data Retention Schedule

A clear data retention schedule is implemented to comply with legal requirements and privacy best practices.

*   **Location Data**: Granular location data (`journey_points`) is purged after 30 days.
*   **Journey Data**: Journey summaries (`journeys` table) are retained for a longer period (e.g., 1 year) for user history and analytics, but with sensitive details anonymized.
*   **Emergency Logs**: Forensic snapshots and emergency logs are retained for a legally mandated period (e.g., 7 years) to support potential investigations.
*   **User Data Deletion**: Upon user request for account deletion, all associated PII is permanently deleted from the system within 24 hours, in compliance with the right to be forgotten.

## 7. Access Control Matrix

Role-Based Access Control (RBAC) is implemented to enforce the principle of least privilege.

| Role              | Permissions                                                                                                                                                           | Description                                                                                                                            | MFA Required | Access Logging | Review Frequency |
| :---------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------- | :----------- | :------------- | :--------------- |
| **Super Admin**   | Full access to all system functionalities, including user management, admin role management, and system configuration.                                                | Highest level of access, reserved for a very limited number of trusted individuals.                                                    | Yes          | Full           | Quarterly        |
| **Admin**         | Access to the admin dashboard for managing unsafe zones, resolving flag disputes, reviewing reports, and monitoring system health.                                    | Standard administrative access for day-to-day platform management.                                                                     | Yes          | Full           | Quarterly        |
| **Support Staff** | Read-only access to user journey data and reports to assist with user support queries. No modification rights.                                                         | Limited access for customer support purposes.                                                                                          | Yes          | Full           | Annually         |
| **Developer**     | Access to development and staging environments. No direct access to production data.                                                                                  | Access for development and testing purposes only.                                                                                      | Yes          | Full           | Annually         |
| **User**          | Access to their own data via the mobile app. No access to other users' data except through shared tracking links.                                                      | Standard user access.                                                                                                                  | No           | Key Actions    | N/A              |

## 8. Threat Model

A threat model is maintained to identify and mitigate potential security risks.

*   **Spoofing**: Risk of fake user profiles. Mitigation: Mandatory Aadhaar/PAN verification.
*   **Tampering**: Risk of data modification (e.g., journey logs, reports). Mitigation: Immutable logging, digital integrity hashes, and strict access controls.
*   **Repudiation**: Risk of users denying actions (e.g., triggering an SOS). Mitigation: Detailed audit logs and forensic snapshots.
*   **Information Disclosure**: Risk of unauthorized access to PII. Mitigation: Encryption, access controls, and data redaction.
*   **Denial of Service (DoS)**: Risk of system unavailability due to attacks. Mitigation: API Gateway with DDoS protection, rate limiting, and scalable infrastructure.
*   **Elevation of Privilege**: Risk of users or attackers gaining unauthorized administrative access. Mitigation: Strong authentication, RBAC, and regular security audits.

## 9. Secure Coding Checklist

Secure coding practices are integrated into the development lifecycle.

*   **Input Validation**: All user input is validated on both the client and server sides to prevent injection attacks (SQLi, XSS).
*   **Parameterized Queries**: Use of parameterized queries (e.g., via SQLAlchemy) to prevent SQL injection.
*   **Dependency Scanning**: Regular scanning of third-party libraries for known vulnerabilities.
*   **Static and Dynamic Analysis**: Use of SAST and DAST tools to identify security flaws in the codebase.
*   **Secrets Management**: No hardcoded secrets. All API keys, passwords, and other secrets are managed through a secure secrets management system (e.g., AWS Secrets Manager, HashiCorp Vault).
*   **Security Headers**: Implementation of security headers (e.g., CSP, HSTS, X-Frame-Options) in web-facing components.
*   **Regular Code Reviews**: Security-focused code reviews are part of the development process.
