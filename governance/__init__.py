# WOW AI × Traccia — Governance & Observability
# This package contains the OpenAI API proxy that intercepts all OpenClaw
# agent calls and records real-time traces to the Traccia dashboard.
#
# Architecture:
#   OpenClaw (Node.js) → localhost:8001/v1 → proxy.py → api.openai.com
#                                                ↕
#                                         api.traccia.ai
