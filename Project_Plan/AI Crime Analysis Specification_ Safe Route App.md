# AI Crime Analysis Specification: Safe Route App

This document details the specifications for the AI Crime Analysis Service, a critical component of the Safe Route App responsible for processing, analyzing, and integrating crime-related data using artificial intelligence. The service primarily leverages the Google Gemini API (or Anthropic Claude) to enhance the accuracy and intelligence of the safety scoring engine.

## 1. AI Provider Integration Logic

The AI Crime Analysis Service acts as an intermediary between the Safe Route App backend and external AI providers. It handles API calls, data formatting, and response parsing.

*   **Primary Provider**: Google Gemini API (or Anthropic Claude).
*   **API Client**: A dedicated Python client (e.g., `anthropic` library for Claude, or Google's client library for Gemini) is used to interact with the AI provider.
*   **Authentication**: API keys are securely managed as environment variables and passed with each request.
*   **Rate Limiting**: The service implements client-side rate limiting and exponential backoff to comply with AI provider API usage policies and handle transient errors.
*   **Error Handling**: Robust error handling mechanisms are in place to manage API call failures, including retries and logging of errors.

## 2. Prompt Structure

The effectiveness of the AI analysis heavily relies on a well-structured and clear prompt. The prompt is dynamically constructed to provide the AI with all necessary context for accurate crime data analysis.

**Example Prompt Structure**:

```
"""Analyze the following crime data for a route:

Crimes encountered ({len(all_crimes)} incidents):
{all_crimes}  # List of dictionaries, each representing a crime incident

Provide:
1. Severity categorization (low/medium/high for each incident, if not already provided)
2. Overall risk assessment for the entire route segment
3. Time-based patterns (e.g., specific hours/days when incidents are more likely)
4. Recommendations for users traversing this route (e.g., 'be extra vigilant after dark', 'avoid this street')

Response format (JSON):
{{
    "severity_breakdown": {{"low": X, "medium": Y, "high": Z}},
    "overall_risk": "low/medium/high",
    "summary": "brief analysis",
    "recommendations": ["rec1", "rec2"]
}}
"""
```

**Key Elements of the Prompt**:
*   **Context**: Clearly states the purpose of the analysis (crime data for a route).
*   **Input Data**: Provides the raw crime incident data in a structured format (e.g., JSON array of objects).
*   **Required Outputs**: Explicitly lists the desired information from the AI.
*   **Output Format**: Specifies the expected JSON structure for the AI's response, ensuring parseability.

## 3. Input Schema

The input to the AI provider is a JSON object containing the prompt and other configuration parameters.

**Input to Gemini API (simplified)**:

```json
{
  "model": "gemini-pro", // Or other suitable model like 'claude-3-sonnet'
  "max_tokens": 1000,
  "messages": [
    {
      "role": "user",
      "content": "[Dynamically generated prompt as described above]"
    }
  ]
}
```

**`all_crimes` Structure (within the prompt)**:

```json
[
  {
    "type": "string",       // e.g., "theft", "assault"
    "date": "ISO 8601 string", // e.g., "2026-01-20T10:30:00Z"
    "severity": "string",   // e.g., "medium", "high" (if available from source)
    "description": "string" // e.g., "mugging reported near park"
  },
  // ... more crime incidents
]
```

## 4. Output Schema

The AI Crime Analysis Service expects a JSON response from the AI provider that conforms to a predefined schema, allowing for consistent parsing and integration into the safety scoring engine.

**Expected Output from Gemini API**:

```json
{
  "severity_breakdown": {
    "low": 0,
    "medium": 0,
    "high": 0
  },
  "overall_risk": "low" | "medium" | "high" | "very_high",
  "summary": "string", // Brief textual analysis
  "recommendations": [
    "string" // List of safety recommendations
  ]
}
```

## 5. Validation Rules

*   **Input Validation**: Ensures that the `all_crimes` data provided to the AI is well-formed and contains necessary fields.
*   **Output Validation**: The AI's response is validated against the expected JSON schema. Missing fields or incorrect data types will trigger an error.
*   **Content Validation**: Basic checks on the generated `summary` and `recommendations` to ensure they are coherent and relevant.

## 6. Fallback Strategy

In case the AI provider is unavailable or returns an invalid response, a fallback strategy ensures the route calculation process can still proceed.

*   **Default Scoring**: If AI analysis fails, the `CrimeFactor` in the safety scoring algorithm will use a default value or a simplified heuristic based on raw crime counts from the PostGIS database.
*   **Cached Responses**: For frequently queried areas, previous AI analysis results can be cached and served as a fallback.
*   **Human Review**: Critical AI analysis failures are flagged for human review by administrators.

## 7. Cost Estimation Model

AI API usage can incur significant costs. A cost estimation model is implemented to monitor and predict expenditure.

*   **Token Usage Tracking**: The service tracks the number of input and output tokens used per API call.
*   **Cost per Query**: Calculates the estimated cost for each AI analysis request based on the provider's pricing model.
*   **Budget Alerts**: Integrates with monitoring systems to trigger alerts if daily/monthly AI usage exceeds predefined budget thresholds.
*   **Optimization**: Strategies like prompt engineering to reduce token count and caching of common queries are employed to minimize costs.

## 8. Caching Strategy

To reduce latency and API costs, a caching mechanism is implemented for AI analysis results.

*   **Redis Cache**: AI analysis responses for specific route segments or crime data clusters are stored in Redis with a configurable Time-To-Live (TTL).
*   **Cache Key**: A hash of the input crime data and prompt is used as the cache key.
*   **Invalidation**: Cache entries are invalidated when underlying crime data is updated or after their TTL expires.

## 9. Human Override Mechanism

While AI provides powerful analytical capabilities, human oversight is crucial, especially in safety-critical applications.

*   **Admin Review Queue**: AI-flagged high-risk areas or unusual analysis results are automatically routed to an admin review queue.
*   **Manual Adjustment**: Administrators can manually adjust safety scores, override AI recommendations, or mark specific areas as unsafe, directly influencing the algorithm.
*   **Feedback Loop**: Human corrections and overrides are fed back into the AI training data to improve future analysis accuracy.
