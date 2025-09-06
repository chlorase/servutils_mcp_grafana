#!/bin/bash
# Common helper to load all .env vars to local environment. Call this before referencing any of the variables in other scripts.

export $(grep -v '^#' ".env" | xargs)