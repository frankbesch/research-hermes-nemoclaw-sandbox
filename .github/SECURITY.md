# Security

This repo holds prompts, a bash harness, a sandbox policy, and redacted logs.
It contains no credentials: the harness never reads the NVIDIA API key, and
`runtask.sh` redacts any `nvapi-` string from each log. If you find a secret
or personal data in this repo, open a private security advisory on GitHub
instead of an issue.
