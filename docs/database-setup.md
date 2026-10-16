# Database Setup Guide

In Huawei Cloud, the database schema can be applied directly without a helper
instance:

### Option 1: GaussDB Console (Recommended)
1. Log in to GaussDB console
2. Navigate to your instance
3. Use "Database Management" → "SQL Editor" to execute:
   - `src/schema.sql`
   - `src/seed_data.sql`

### Option 2: FunctionGraph
Create a one-time function to execute SQL:

```python
import pg8000

def handler(event, context):
    conn = pg8000.connect(
        host=os.environ['RDS_ENDPOINT'],
        database=os.environ['RDS_DATABASE'],
        user=os.environ['RDS_USER'],
        password=os.environ['RDS_PASSWORD']
    )
    
    # Read and execute schema.sql
    with open('schema.sql', 'r') as f:
        conn.run(f.read())
    
    # Read and execute seed_data.sql
    with open('seed_data.sql', 'r') as f:
        conn.run(f.read())
    
    conn.close()
    return {"status": "Schema applied"}
```

### Option 3: DMS (Data Admin Service)
Use DMS SQL console in Huawei Cloud management console.
