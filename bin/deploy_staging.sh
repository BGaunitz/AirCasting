#!/bin/bash

set -ex

git fetch --all
git checkout -b deploy
git cherry-pick origin/cap3
git push --set-upstream origin deploy
bundle exec cap staging deploy BRANCH=deploy
git push origin :deploy
git checkout -
git branch -D deploy
