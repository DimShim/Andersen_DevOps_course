#!/usr/bin/env bash

clear

function get_open_pr_info() {
  FIRST_PAGE=$(curl -sb -H "Accept: application/json" "$1/pulls" | jq '.[]')
  if [[ $(echo "$FIRST_PAGE") =~ "Not Found" ]]; then
    echo "Repository is not existed"
    exit
  fi
  
  if [[ $(echo "$FIRST_PAGE") =~ "API rate" ]]; then
    echo "API rate limit exceeded"
    exit
  fi
  
  PAGE=1
  OPEN_PR_NUM=0
  OPEN_PR_NUM_PAGE=1
  PR_REQUESTS=()
  
  while [[ $OPEN_PR_NUM_PAGE -gt 0 ]]; do
    PR_REQUESTS_PAGE=$(curl -sb -H "Accept: application/json" "$1/pulls?page=$PAGE")
    OPEN_PR_NUM_PAGE=$(echo "$PR_REQUESTS_PAGE" | jq '. | length')
    PR_REQUESTS+=("$PR_REQUESTS_PAGE")
    ((PAGE++))
    ((OPEN_PR_NUM+=$OPEN_PR_NUM_PAGE))
  done
  
  if [ "$OPEN_PR_NUM" -eq "0" ]; then
    echo "There is no open pull requests"
  else
    if [ "$OPEN_PR_NUM" -eq "1" ]; then
      echo "There is 1 open pull request"
    else
      echo "There are $OPEN_PR_NUM open pull requests"
      echo " "
    fi

    echo "Who contributes the most?"
    echo "$PR_REQUESTS" | jq -r '.[].user.login' | sort | uniq -c | sort -gr | awk '$1 > 1 {print $2" has "$1" open PR"}'
    
    echo " "
    echo "Author and name of PRs:"
    JSON_RESULT=$(echo "$PR_REQUESTS" | jq -cr 'group_by(.user.login)[] | [{ (.[0].user.login): {"titles": ([.[] | .title] | join("; ")), "count": ([.[] | .title] | length ) }}]')
    echo $JSON_RESULT | jq -nr '[inputs] | add | sort_by(.[].count) | reverse[] | keys[] as $k | "- \($k): \(.[$k].titles)"'
    echo " "
  fi
}

BASE_API_URL=$(echo $1 | awk -F/ '{api_url="https://api.github.com/repos/"$4"/"$5; print api_url}')

get_open_pr_info "$BASE_API_URL"
