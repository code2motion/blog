git filter-branch --env-filter '
OLD_NAME="nuwan-sherpal"
NEW_NAME="Nuwan Samarasinghe"
NEW_EMAIL="nuwansamarasinghe100@gmail.com"

if [ "$GIT_COMMITTER_NAME" = "$OLD_NAME" ]; then
  export GIT_COMMITTER_NAME="$NEW_NAME"
  export GIT_COMMITTER_EMAIL="$NEW_EMAIL"
fi
if [ "$GIT_AUTHOR_NAME" = "$OLD_NAME" ]; then
  export GIT_AUTHOR_NAME="$NEW_NAME"
  export GIT_AUTHOR_EMAIL="$NEW_EMAIL"
fi
' --tag-name-filter cat -- --branches --tags