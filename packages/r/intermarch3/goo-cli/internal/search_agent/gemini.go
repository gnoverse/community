package search_agent

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"
)

// OracleResponse represents the structured output from the AI oracle
type OracleResponse struct {
	Value   string   `json:"value"`
	Sources []string `json:"sources"`
	Why     string   `json:"why"`
}

// GeminiClient wraps the Gemini API client for oracle queries
type GeminiClient struct {
	apiKey     string
	apiURL     string
	httpClient *http.Client
	verbose    bool
}

// API Request/Response structures for Gemini REST API
type geminiRequest struct {
	Contents         []geminiContent  `json:"contents"`
	Tools            []geminiTool     `json:"tools,omitempty"`
	SystemInstruction *geminiContent  `json:"system_instruction,omitempty"`
}

type geminiContent struct {
	Parts []geminiPart `json:"parts"`
	Role  string       `json:"role,omitempty"`
}

type geminiPart struct {
	Text string `json:"text"`
}

type geminiTool struct {
	GoogleSearch *struct{} `json:"google_search,omitempty"`
}

type geminiResponse struct {
	Candidates []geminiCandidate `json:"candidates"`
}

type geminiCandidate struct {
	Content           geminiContent       `json:"content"`
	GroundingMetadata *groundingMetadata  `json:"groundingMetadata,omitempty"`
}

type groundingMetadata struct {
	GroundingChunks []groundingChunk `json:"groundingChunks,omitempty"`
}

type groundingChunk struct {
	Web *webChunk `json:"web,omitempty"`
}

type webChunk struct {
	URI   string `json:"uri"`
	Title string `json:"title"`
}

// NewGeminiClient creates a new Gemini client for oracle queries using REST API
func NewGeminiClient(apiKey string, verbose bool) (*GeminiClient, error) {
	if apiKey == "" {
		return nil, fmt.Errorf("API key cannot be empty")
	}

	// Use gemini-2.5-flash which supports google_search
	apiURL := "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

	httpClient := &http.Client{
		Timeout: 60 * time.Second,
	}

	return &GeminiClient{
		apiKey:     apiKey,
		apiURL:     apiURL,
		httpClient: httpClient,
		verbose:    verbose,
	}, nil
}

// Close closes the Gemini client connection
func (c *GeminiClient) Close() error {
	// Nothing to close for HTTP client
	return nil
}

// QueryQuestion queries the AI with web search to answer the oracle question
func (c *GeminiClient) QueryQuestion(question string) (*OracleResponse, error) {
	if question == "" {
		return nil, fmt.Errorf("question cannot be empty")
	}

	// Generate system prompt with current date
	currentDate := time.Now().Format("January 2, 2006")
	systemPrompt := getSystemPrompt(currentDate)

	if c.verbose {
		fmt.Fprintf(os.Stderr, "\n🔍 Querying Gemini AI with Google Search...\n")
		fmt.Fprintf(os.Stderr, "   Model: gemini-2.5-flash\n")
		fmt.Fprintf(os.Stderr, "   Question: %s\n", question)
		fmt.Fprintf(os.Stderr, "   Date: %s\n\n", currentDate)
	}

	// Prepare the request body
	reqBody := geminiRequest{
		SystemInstruction: &geminiContent{
			Parts: []geminiPart{
				{Text: systemPrompt},
			},
		},
		Contents: []geminiContent{
			{
				Parts: []geminiPart{
					{Text: question},
				},
			},
		},
		Tools: []geminiTool{
			{
				GoogleSearch: &struct{}{},
			},
		},
	}

	// Marshal to JSON
	jsonData, err := json.Marshal(reqBody)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	if c.verbose {
		fmt.Fprintf(os.Stderr, "📤 Request body:\n%s\n\n", string(jsonData))
	}

	// Create HTTP request
	req, err := http.NewRequest("POST", c.apiURL, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	// Set headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("x-goog-api-key", c.apiKey)

	// Send request
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	// Read response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if c.verbose {
		fmt.Fprintf(os.Stderr, "📥 Response status: %d\n", resp.StatusCode)
		fmt.Fprintf(os.Stderr, "📥 Response body:\n%s\n\n", string(body))
	}

	// Check for errors
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("API error (status %d): %s", resp.StatusCode, string(body))
	}

	// Parse response
	var geminiResp geminiResponse
	if err := json.Unmarshal(body, &geminiResp); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	// Extract text from response
	if len(geminiResp.Candidates) == 0 || len(geminiResp.Candidates[0].Content.Parts) == 0 {
		return nil, fmt.Errorf("no response from Gemini")
	}

	responseText := geminiResp.Candidates[0].Content.Parts[0].Text

	if c.verbose {
		fmt.Fprintf(os.Stderr, "📝 Response text:\n%s\n\n", responseText)
	}

	// Try to parse as JSON
	oracleResp, err := parseJSONResponse(responseText)
	if err == nil {
		// Successfully parsed JSON
		if c.verbose {
			fmt.Fprintf(os.Stderr, "✓ Parsed JSON response\n")
			fmt.Fprintf(os.Stderr, "  Sources in JSON: %d\n", len(oracleResp.Sources))
		}
		
		// If sources are empty in JSON, try to extract from grounding metadata
		if len(oracleResp.Sources) == 0 {
			metadataSources := extractSourcesFromMetadata(&geminiResp)
			if c.verbose {
				fmt.Fprintf(os.Stderr, "  Sources from metadata: %d\n", len(metadataSources))
			}
			oracleResp.Sources = metadataSources
		}
		
		// Validate and filter sources
		if len(oracleResp.Sources) > 0 {
			oracleResp.Sources = filterAndValidateSources(oracleResp.Sources, 5, c.verbose)
		}
		
		return oracleResp, nil
	}

	// Not JSON - treat as plain text response
	if c.verbose {
		fmt.Fprintf(os.Stderr, "⚠ Response is not JSON, extracting from plain text...\n\n")
	}

	// Extract sources from grounding metadata
	sources := extractSourcesFromMetadata(&geminiResp)
	if len(sources) > 0 {
		sources = filterAndValidateSources(sources, 5, c.verbose)
	}

	// Extract value from first sentence or line
	value := responseText
	if idx := strings.Index(responseText, "."); idx != -1 && idx < 200 {
		value = strings.TrimSpace(responseText[:idx])
	} else if lines := strings.Split(responseText, "\n"); len(lines) > 0 {
		value = strings.TrimSpace(lines[0])
		if len(value) > 200 {
			value = value[:200]
		}
	}

	return &OracleResponse{
		Value:   value,
		Sources: sources,
		Why:     strings.TrimSpace(responseText),
	}, nil
}

// getSystemPrompt generates the system prompt with current date
func getSystemPrompt(currentDate string) string {
	return fmt.Sprintf(`You are an AI research agent designed to answer questions for an optimistic oracle proposer.

CRITICAL CONTEXT:
- TODAY'S DATE: %s
- You MUST use this date to determine if questions are about the past or future.

Your job is to perform real web research, find reliable factual information, extract a final numeric or factual value, and return:

1. THE PROPOSED VALUE (the answer to the question)
2. THE SOURCES (real URLs only, no hallucinated links)
3. THE JUSTIFICATION (short reasoning + quotes from sources)

TEMPORAL REASONING (VERY IMPORTANT):
- Determine if the FACTUAL INFORMATION being asked about exists NOW or only in the future.
- Questions about PAST EVENTS are answerable even if they mention future dates (e.g., "Who was elected for the 2025-2029 term?" - the election happened in the past, so this is answerable)
- Questions about FUTURE EVENTS that haven't happened yet are NOT answerable (e.g., "Who will win the 2026 election?" - this hasn't happened yet)

KEY DISTINCTION:
- "Who is/was elected mayor for 2025-2029?" → PAST/PRESENT (election happened, result exists)
- "What was the price on [past date]?" → PAST (data exists)
- "Who will be elected in 2026?" → FUTURE (event hasn't happened, no data exists)
- "What will the price be on [future date]?" → FUTURE (data doesn't exist yet)

REQUIREMENTS:
- FIRST, determine if the FACTUAL DATA being asked about exists as of %s.
- Ask yourself: "Has the event/data point this question refers to already occurred/been determined?"
- If the answer is NO (future event, no data exists yet), return FUTURE_QUESTION_ERROR:
  {
    "value": "FUTURE_QUESTION_ERROR",
    "sources": [],
    "why": "This question asks about a future event that hasn't occurred yet as of %s. Oracle cannot answer questions about the future as no factual data exists yet."
  }
- If the answer is YES (past/present event, data exists), proceed with research.
- YOU HAVE ACCESS TO GOOGLE SEARCH. Use it to find current, factual information.
- Extract REAL URLs from your search results. The "sources" field MUST contain actual URLs you found through Google Search.
- Never fabricate or invent URLs. Only include URLs that appear in your search results.
- When reading sources from search results, extract exact quotes that support your answer.
- If multiple sources disagree, explain the discrepancy and choose the most credible one.
- If no definitive answer exists for a PAST question after searching, return "INSUFFICIENT DATA".
- The "value" must be as precise and unambiguous as possible.

CRITICAL VALUE FORMAT RULES:
For NUMERIC questions, the "value" field must contain ONLY a pure number:
  - Format: integer or decimal with period (.) as decimal separator
  - Examples of CORRECT formats: "3874" or "3874.50" or "-42" or "0.5"
  - Examples of WRONG formats: "$3,874" or "3.874 USD" or "approximately 3874" or "three thousand"
  - NO currency symbols ($, €, £, ¥)
  - NO thousand separators (no commas)
  - NO units or text (USD, dollars, approximately, etc.)
  - NO leading/trailing text, just the raw number

For YES/NO questions, the "value" field must contain ONLY:
  - "Yes" or "No" (exactly these words, nothing else)
  - NOT "yes, because..." or "The answer is yes" - just "Yes" or "No"

The "value" field is parsed programmatically. Any extra text will cause an error.
Put explanations in the "why" field, not in "value".

Output must ALWAYS follow the JSON template:

{
  "value": "...",
  "sources": ["url1", "url2", ...],
  "why": "explanation with quotes"
}

CRITICAL OUTPUT FORMAT:
- Your response MUST be ONLY valid JSON. 
- Do NOT include any text before or after the JSON object.
- Do NOT write explanatory sentences or commentary.
- ONLY output the JSON object starting with { and ending with }.
- The very first character of your response must be { and the very last must be }.
- Example format:
{"value": "Yes", "sources": ["https://example.com"], "why": "Based on..."}`, currentDate, currentDate, currentDate)
}

// parseJSONResponse attempts to parse JSON from various response formats
func parseJSONResponse(rawResponse string) (*OracleResponse, error) {
	var response OracleResponse

	// Try direct parse
	err := json.Unmarshal([]byte(rawResponse), &response)
	if err == nil {
		return &response, nil
	}

	// Try extracting JSON from markdown code block
	if strings.Contains(rawResponse, "```json") {
		start := strings.Index(rawResponse, "```json") + 7
		remaining := rawResponse[start:]
		end := strings.Index(remaining, "```")
		if end != -1 {
			jsonStr := strings.TrimSpace(remaining[:end])
			err = json.Unmarshal([]byte(jsonStr), &response)
			if err == nil {
				return &response, nil
			}
		}
	}

	// Try extracting JSON boundaries
	start := strings.Index(rawResponse, "{")
	end := strings.LastIndex(rawResponse, "}")
	if start != -1 && end > start {
		jsonStr := rawResponse[start : end+1]
		err = json.Unmarshal([]byte(jsonStr), &response)
		if err == nil {
			return &response, nil
		}
	}

	return nil, fmt.Errorf("could not extract valid JSON from response")
}

// extractSourcesFromMetadata extracts URLs from grounding metadata
func extractSourcesFromMetadata(resp *geminiResponse) []string {
	sources := make([]string, 0)

	if len(resp.Candidates) == 0 {
		return sources
	}

	candidate := resp.Candidates[0]
	if candidate.GroundingMetadata == nil {
		return sources
	}

	metadata := candidate.GroundingMetadata
	if metadata.GroundingChunks == nil {
		return sources
	}

	for _, chunk := range metadata.GroundingChunks {
		if chunk.Web != nil && chunk.Web.URI != "" {
			sources = append(sources, chunk.Web.URI)
		}
	}

	return sources
}

// validateURL checks if a URL is accessible (doesn't return 404 or error)
// Reproduces the exact behavior from the Python PoC
func validateURL(url string, timeout time.Duration) bool {
	// Simple HTTP client with timeout
	client := &http.Client{
		Timeout: timeout,
	}

	// Create GET request with User-Agent header
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return false
	}

	// Set User-Agent to avoid being blocked (same as Python PoC)
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")

	// Send request
	resp, err := client.Do(req)
	if err != nil {
		return false
	}
	defer resp.Body.Close()

	// Check if status is 200 OK (same as Python PoC)
	return resp.StatusCode == 200
}

// filterAndValidateSources validates URLs and limits to maxSources
func filterAndValidateSources(sources []string, maxSources int, verbose bool) []string {
	if len(sources) == 0 {
		return []string{}
	}

	validated := make([]string, 0, maxSources)

	if verbose {
		fmt.Fprintf(os.Stderr, "\n🔍 Validating %d sources (checking for 404 errors)...\n", len(sources))
	}

	for i, url := range sources {
		if len(validated) >= maxSources {
			break
		}

		if verbose {
			fmt.Fprintf(os.Stderr, "  [%d/%d] Checking: %s\n", i+1, min(len(sources), maxSources), url)
		}

		if validateURL(url, 5*time.Second) {
			validated = append(validated, url)
			if verbose {
				fmt.Fprintf(os.Stderr, "    ✓ Valid\n")
			}
		} else {
			if verbose {
				fmt.Fprintf(os.Stderr, "    ✗ Error (404 or unreachable)\n")
			}
		}
	}

	if verbose {
		fmt.Fprintf(os.Stderr, "✓ %d valid sources found\n\n", len(validated))
	} else if len(sources) > 0 {
		// In non-verbose mode, show a summary
		fmt.Fprintf(os.Stderr, "✓ %d valid sources (out of %d found)\n", len(validated), len(sources))
	}

	return validated
}

// min returns the minimum of two integers
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

