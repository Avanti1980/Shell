#!/usr/bin/env bash

git add *
git commit -m "$1"
git push github main
git push gitee main
