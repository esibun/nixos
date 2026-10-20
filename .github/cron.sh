ACCESS_TOKEN=setme
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  [https://api.github.com/repos/esibun/nixos/actions/workflows/daily.yml/dispatches](https://api.github.com/repos/esibun/nixos/actions/workflows/daily.yml/dispatches) \
  -d '{"ref":"main"}'
