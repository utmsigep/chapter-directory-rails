# Chapter Directory

[![Run CI Tasks](https://github.com/stephenyeargin/chapter-directory-rails/actions/workflows/ci.yml/badge.svg)](https://github.com/stephenyeargin/chapter-directory-rails/actions/workflows/ci.yml) [![CodeQL](https://github.com/utmsigep/chapter-directory-rails/actions/workflows/codeql-analysis.yml/badge.svg)](https://github.com/utmsigep/chapter-directory-rails/actions/workflows/codeql-analysis.yml)

[![screenshot](screenshot.png)](https://chapters.sigep.network)

[Demo](https://chapters.sigep.network)

[Developer Quick Start](https://github.com/utmsigep/chapter-directory-rails/wiki/Developer-Quick-Start)

## Weekly Report Email

`rake report:weekly_summary` emails a copy of the `/admin` dashboard (same stats, comparisons, and rankings) to the addresses in `EMAIL_REPORT_RECIPIENTS` (comma-separated). It only sends on Sundays unless `FORCE=1` is set.

Required environment variables:

- `EMAIL_REPORT_RECIPIENTS` - comma-separated recipient email addresses
- `SMTP_HOSTNAME`, `SMTP_PORT`, `SMTP_DOMAIN`, `SMTP_USERNAME`, `SMTP_PASSWORD` - outbound mail server (falls back to Rails' default `:smtp` config if `SMTP_HOSTNAME` is unset)
- `APP_HOST` - hostname used to build links in the email (defaults to `chapters.sigep.network`)
- `MAIL_FROM_ADDRESS` - the `From` address (defaults to `reports@sigep.network`)

Production runs this via the `chapters.sigep.network - Weekly Report` Jenkins pipeline, which SSHes to the deploy host and runs the task on a Sunday morning cron trigger (`H 7 * * 0`). The rake task also guards against non-Sunday runs on its own (`FORCE=1` overrides this for manual testing), so it's safe to trigger by hand.
