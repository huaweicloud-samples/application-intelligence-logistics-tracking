"""
Logistics Agent - Main Module
Agent implementation for logistics query handling.

This module implements the logistics tracking agent using Strands Agents SDK
and connects to Huawei Cloud MaaS via OpenAI-compatible interface.
"""

import json
import logging
import os
import pg8000
from strands import Agent, tool
from strands.models.openai import OpenAIModel

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration from environment
MODEL_API_KEY = os.environ.get('MODEL_API_KEY', '')
MODEL_ENDPOINT = os.environ.get('MODEL_ENDPOINT', 'https://api.modelarts-maas.com')
MODEL_ID = os.environ.get('MODEL_ID', 'DeepSeek-V4')
RDS_ENDPOINT = os.environ.get('RDS_ENDPOINT', '')
RDS_USER = os.environ.get('RDS_USER', 'root')
RDS_PASSWORD = os.environ.get('RDS_PASSWORD', '')
RDS_DATABASE = os.environ.get('RDS_DATABASE', 'company_logistics_db')

# Database configuration - cached after first load within a session
_db_connection = None


def get_db_connection():
    """Get or create a cached database connection."""
    global _db_connection
    
    # Check if we have a cached connection and if it's still alive
    if _db_connection is not None:
        return _db_connection
    
    # Create new connection
    try:
        _db_connection = pg8000.native.Connection(
            host=RDS_ENDPOINT,
            database=RDS_DATABASE,
            user=RDS_USER,
            password=RDS_PASSWORD,
            timeout=30
        )
        return _db_connection
    except Exception as e:
        logger.error(f"Database connection failed: {type(e).__name__}: {str(e)}")
        raise


@tool
def get_shipment_status(reference_no: str) -> str:
    """
    Get the current status and latest event for a shipment.
    
    Args:
        reference_no: Shipment reference number (e.g., 'ACME-REF-1001')
    
    Returns:
        Current status, location, and latest event details
    """
    try:
        conn = get_db_connection()
        
        query = """
        SELECT 
            s.reference_no,
            s.status,
            le.event,
            loc.name AS current_location,
            loc.unlocode,
            le.occurred_at,
            le.details
        FROM logistics.shipments s
        JOIN logistics.v_shipment_latest_event le ON le.shipment_id = s.shipment_id
        LEFT JOIN logistics.locations loc ON loc.location_id = le.location_id
        WHERE s.reference_no = :reference_no
        """
        
        result = conn.run(query, reference_no=reference_no)
        
        if result:
            return json.dumps(result[0], default=str, indent=2)
        else:
            return f"Shipment {reference_no} not found"
            
    except Exception as e:
        logger.error(f"Error in get_shipment_status: {type(e).__name__}: {str(e)}", exc_info=True)
        return f"Error retrieving shipment status: {str(e)}"


@tool
def find_delayed_shipments() -> str:
    """
    Find all shipments that are at risk of being delayed based on ETA.
    
    Returns:
        List of shipments with at-risk status
    """
    try:
        conn = get_db_connection()
        
        query = """
        SELECT 
            r.reference_no,
            r.eta,
            r.eta_final,
            r.eta_status
        FROM logistics.mv_eta_risk r
        WHERE r.eta_status = 'AT_RISK'
        ORDER BY r.eta DESC NULLS LAST
        """
        
        results = conn.run(query)
        
        if results:
            return json.dumps(results, default=str, indent=2)
        else:
            return "No delayed shipments found"
            
    except Exception as e:
        logger.error(f"Error in find_delayed_shipments: {type(e).__name__}: {str(e)}", exc_info=True)
        return f"Error finding delayed shipments: {str(e)}"


SYSTEM_PROMPT = """You are a logistics tracking assistant with access to a real-time shipment database.

You can help users:
- Track shipment status and location
- View complete shipment routes
- Identify delayed shipments
- Check container history
- Monitor customs holds

When answering questions:
- Be concise and focus on the most relevant information
- Include reference numbers, locations, and timestamps
- Explain any issues or delays clearly
- Suggest next steps when appropriate"""


_agent = None
_openai_model = None


def _get_openai_model():
    """Create and configure the model for Huawei Cloud MaaS."""
    global _openai_model
    
    if _openai_model is not None:
        return _openai_model
    
    try:
        # Get API key from environment variable
        api_key = MODEL_API_KEY
        
        # Create OpenAI-compatible model
        _openai_model = OpenAIModel(
            client_args={
                "api_key": api_key,
                "api_base": f"{MODEL_ENDPOINT}/v1"
            },
            model_id=MODEL_ID,
            params={
                "max_tokens": 2000,
                "temperature": 0.7,
            }
        )
        logger.info("OpenAI model initialized successfully")
        return _openai_model
        
    except Exception as e:
        logger.error(f"Failed to initialize OpenAI model: {e}", exc_info=True)
        raise


def _initialize_agent():
    """Initialize the agent with database tools."""
    global _agent
    if _agent is None:
        # Get model
        openai_model = _get_openai_model()
        
        # Tools are passed directly as Python functions
        _agent = Agent(
            name="logistics_agent",
            model=openai_model,
            tools=[
                get_shipment_status,
                find_delayed_shipments
            ],
            system_prompt=SYSTEM_PROMPT,
            callback_handler=None,
        )
    return _agent


def handler(event, context):
    """
    FunctionGraph handler function.
    
    Args:
        event: FunctionGraph event (dict with 'body' key for HTTP trigger)
        context: FunctionGraph context
    
    Returns:
        dict with statusCode and body
    """
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        user_query = body.get('query')
        
        if not user_query:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Please provide a query in the format: {"query": "your question here"}'})
            }
        
        # Initialize agent lazily on first request
        agent = _initialize_agent()
        
        # Execute the agent
        result = agent(user_query)
        
        # Return the response
        return {
            'statusCode': 200,
            'body': json.dumps({'result': result.message['content'][0]['text']})
        }
    except Exception as e:
        logger.error(f"Query failed: {type(e).__name__}: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': f"Query failed: {str(e)}"})
        }


# For local testing
if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1:
        query = " ".join(sys.argv[1:])
        print(f"Query: {query}")
        
        agent = _initialize_agent()
        result = agent(query)
        print(f"Result: {result.message['content'][0]['text']}")
    else:
        print("Logistics Agent CLI")
        print("=" * 40)
        print("Enter your query (or 'quit' to exit)")
        while True:
            query = input("\nQuery> ")
            if query.lower() in ["quit", "exit", "q"]:
                break
            if not query.strip():
                continue
            
            agent = _initialize_agent()
            result = agent(query)
            print(f"\nResult: {result.message['content'][0]['text']}")
