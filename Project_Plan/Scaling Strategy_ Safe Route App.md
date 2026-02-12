# Scaling Strategy: Safe Route App

This document outlines the scaling strategy for the Safe Route App, focusing on ensuring high availability, performance, and cost-effectiveness as the user base grows. It covers horizontal scaling logic, WebSocket scaling, database replication, partitioning, Redis clustering, rate limiting, AI usage scaling, and cost/traffic estimation models.

## 1. Horizontal Scaling Logic

The application is designed for horizontal scalability across all stateless components, allowing for increased capacity by adding more instances of services.

*   **FastAPI Backend**: Multiple instances of the FastAPI application can be run behind a load balancer (e.g., NGINX, AWS ALB). Each instance is stateless, processing incoming requests independently.
*   **Celery Workers**: The Celery task queue can be scaled by deploying additional worker instances. This allows for parallel processing of background tasks like route safety calculations, SMS sending, and report generation.
*   **API Gateway**: The API Gateway (e.g., NGINX, Cloudflare) itself is designed to scale horizontally to handle increasing request volumes and distribute traffic efficiently across backend instances.

## 2. WebSocket Scaling Plan

Scaling WebSocket connections requires careful consideration due to their stateful nature. The plan involves using a distributed WebSocket solution.

*   **Sticky Sessions**: The load balancer is configured to use sticky sessions (session affinity) to ensure that a client's WebSocket connection is consistently routed to the same WebSocket server instance. This maintains session state.
*   **Distributed Pub/Sub**: A distributed publish/subscribe (Pub/Sub) system (e.g., Redis Pub/Sub, Apache Kafka) is used to broadcast messages across multiple WebSocket server instances. For example, if an SOS alert is triggered on one server, the Pub/Sub system ensures all relevant emergency contacts connected to any server instance receive the update.
*   **Horizontal Scaling of WebSocket Servers**: Multiple WebSocket server instances (e.g., using `socket.io` with a Redis adapter) can be deployed, each handling a subset of active connections. This distributes the load and increases fault tolerance.

## 3. DB Read Replicas

To offload read traffic from the primary database and improve read performance, read replicas are utilized.

*   **PostgreSQL Read Replicas**: One or more read-only replicas of the PostgreSQL database are maintained. The FastAPI backend is configured to direct read-heavy queries (e.g., fetching route data, journey history) to these replicas.
*   **Asynchronous Replication**: Data is asynchronously replicated from the primary database to the replicas, ensuring eventual consistency.
*   **Automatic Failover**: In case of primary database failure, one of the read replicas can be promoted to become the new primary, minimizing downtime.

## 4. Partitioning Plan

Database partitioning is employed to manage large tables, improve query performance, and facilitate data retention policies.

*   **Table Partitioning**: Large tables such as `journey_points` (which will accumulate high volumes of granular location data) and `crime_data` are partitioned.
*   **Partitioning Key**: For `journey_points`, partitioning can be done by `journey_id` or by `timestamp` (e.g., monthly or yearly partitions). For `crime_data`, partitioning by `location` (geospatial partitioning) or `timestamp` is considered.
*   **Benefits**: Reduces index size, improves query performance by scanning smaller data sets, and simplifies data archival/deletion for compliance (e.g., purging `journey_points` older than 30 days).

## 5. Redis Clustering

Redis is a critical component for caching and real-time data. To ensure high availability and scalability, Redis is deployed in a clustered configuration.

*   **Redis Cluster**: A Redis Cluster setup distributes data across multiple Redis nodes, providing automatic sharding and high availability through replication.
*   **Use Cases**: This cluster supports session management, live GPS tracking data, task queue brokers (for Celery), and API rate limiting counters.
*   **Benefits**: Enhanced fault tolerance (if one node fails, others continue operating) and improved performance by distributing read/write operations.

## 6. Rate Limiting Model

Rate limiting is implemented at multiple layers to protect the system from abuse, DoS attacks, and to manage external API costs.

*   **API Gateway Rate Limiting**: Initial rate limits are enforced at the API Gateway level (e.g., NGINX, Cloudflare) based on IP address or API key.
*   **Backend Rate Limiting**: More granular rate limiting is applied within the FastAPI backend for specific endpoints (e.g., login attempts, route calculation requests) using Redis to store and track request counts per user.
*   **External API Rate Limiting**: The AI Crime Analysis Service and Route Service implement internal rate limiting and exponential backoff when interacting with external APIs (Google Maps, Gemini, Twilio) to respect their usage policies.

## 7. AI Usage Scaling

Scaling AI usage involves optimizing calls to external AI providers and managing associated costs.

*   **Caching AI Responses**: As detailed in `ai_crime_analysis_spec.md`, caching AI analysis results for frequently queried route segments significantly reduces redundant API calls.
*   **Batch Processing**: For certain AI tasks, batching multiple requests into a single API call (if supported by the provider) can improve efficiency and reduce overhead.
*   **Model Selection**: Utilizing different AI models based on the criticality and complexity of the task (e.g., a lighter model for initial screening, a more powerful one for deep analysis) can optimize cost and performance.
*   **Cost Monitoring**: Continuous monitoring of AI API costs and usage patterns to identify and address inefficiencies.

## 8. Cost Projection

Cost projection involves estimating infrastructure and service costs based on anticipated user growth and feature usage.

*   **Key Cost Drivers**: Primary cost drivers include cloud infrastructure (compute, storage, networking), external API usage (Google Maps, Gemini, Twilio), and database services.
*   **Tiered Model**: Projections are often based on a tiered user model (e.g., 1k, 10k, 100k, 1M active users), estimating resource consumption at each tier.
*   **Optimization**: Identifying areas for cost optimization, such as reserved instances for stable workloads, serverless functions for intermittent tasks, and efficient data storage strategies.

## 9. Traffic Estimation Model

Traffic estimation models predict the load on various system components based on expected user behavior.

*   **User Activity Patterns**: Modeling typical user journeys, including frequency of route calculations, duration of active monitoring, and likelihood of SOS triggers.
*   **Peak vs. Average Load**: Differentiating between average daily usage and peak hour/event-driven spikes in traffic.
*   **Concurrency**: Estimating the number of concurrent users for WebSocket connections and API requests.
*   **Data Volume**: Projecting the volume of data generated (e.g., GPS points, crime data, reports) to plan for storage and processing capacity.
*   **Scenario Analysis**: Running 
