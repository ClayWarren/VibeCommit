import sys
from transformers import pipeline

# Load model (assumes downloaded)
summarizer = pipeline("summarization", model="openai/gpt-oss-20b")

# Read commits from stdin
commits = sys.stdin.read().strip()

# Prompt for dev-friendly summary
prompt = f"Summarize these Git commits into a concise, human-readable changelog entry: {commits}"

# Generate summary (tune params for speed/quality)
summary = summarizer(prompt, max_length=200, min_length=50, do_sample=False)[0]['summary_text']

print(summary)