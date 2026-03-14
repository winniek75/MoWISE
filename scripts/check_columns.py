import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

supabase = create_client(
    os.environ["VITE_SUPABASE_URL"],
    os.environ["VITE_SUPABASE_SERVICE_ROLE_KEY"]
)

# Try inserting a dummy and see what columns exist by checking error or schema
# Instead, let's just try a select with limit 0
result = supabase.table("pattern_content").select("*").limit(1).execute()
print("Columns:", list(result.data[0].keys()) if result.data else "No data - checking via insert test")

# Check table exists
from postgrest import SyncRequestBuilder
# Just try to get column info
result2 = supabase.rpc("", {}).execute()
