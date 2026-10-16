#!/usr/bin/env python3
"""
调用物流智能体 API 的测试脚本
Handler that invokes the agent to process logistics queries.
"""

import os
import sys
import json
import requests

# Configuration from environment or command line
API_ENDPOINT = os.environ.get("API_ENDPOINT", "")
API_KEY = os.environ.get("API_KEY", "")

def invoke_agent(query: str) -> dict:
    """Invoke the logistics agent with a query."""
    if not API_ENDPOINT:
        print("Error: API_ENDPOINT not set")
        print("Usage: export API_ENDPOINT='https://<your-api-endpoint>/query'")
        sys.exit(1)
    
    headers = {
        "Content-Type": "application/json",
    }
    if API_KEY:
        headers["Authorization"] = f"Bearer {API_KEY}"
    
    payload = {"query": query}
    
    try:
        response = requests.post(
            API_ENDPOINT,
            headers=headers,
            json=payload,
            timeout=30
        )
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        sys.exit(1)

def main():
    if len(sys.argv) < 2:
        # Interactive mode
        print("Logistics Agent Query CLI")
        print("=" * 40)
        print("Enter your query (or 'quit' to exit)")
        while True:
            query = input("\nQuery> ")
            if query.lower() in ["quit", "exit", "q"]:
                break
            if not query.strip():
                continue
            
            result = invoke_agent(query)
            print("\nResult:")
            print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        # Command line mode
        query = " ".join(sys.argv[1:])
        result = invoke_agent(query)
        print(json.dumps(result, indent=2, ensure_ascii=False))

if __name__ == "__main__":
    main()
