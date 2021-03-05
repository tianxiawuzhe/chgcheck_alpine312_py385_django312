#!/bin/bash

today=$(date +"%Y%m%d")

echo "**********  START[${today}]  **********"
exec "$@"
