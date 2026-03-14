import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

supabase = create_client(
    os.environ["VITE_SUPABASE_URL"],
    os.environ["VITE_SUPABASE_SERVICE_ROLE_KEY"]
)

result = supabase.table("pattern_content").select("pattern_no, layer, question_type", count="exact").in_("pattern_no", ["P001","P002","P003","P004","P005"]).in_("layer", [2, 3]).execute()

print(f"Total rows: {result.count}")
for row in (result.data or []):
    print(row)
