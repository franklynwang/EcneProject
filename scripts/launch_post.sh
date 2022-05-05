#!/bin/sh

curl -X POST http://127.0.0.1:8000/verify -H 'Content-Type: application/json' -d '{"r1cs":"target/division.r1cs","sym":"target/division.sym", "id":"division"}'

