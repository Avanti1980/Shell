#!/usr/bin/env bash

echo $(echo "https://people.orie.cornell.edu/dpw/orie6300/ProblemSets/ps" | sed -n "s/.*\/\(.*\)/\1/p")
