# Security Policy

## Supported versions

Security fixes are applied to the current development branch. Until the
package has multiple released branches, only the latest public release
is supported.

| Version  | Supported |
|----------|-----------|
| 1.1.x    | Yes       |
| \< 1.1.0 | No        |

## Reporting a vulnerability

Please do not open a public issue for a suspected vulnerability.

Report security concerns by email to:

``` text
a.sofimahmudi@gmail.com
```

Include:

- a description of the issue,
- steps to reproduce it,
- the affected version or commit,
- whether the issue involves unsafe file handling, XML parsing, external
  command invocation, or disclosure of sensitive data.

You should receive an initial response within 7 days. If the report is
accepted, the maintainer will coordinate a fix and release timeline with
you.

## Scope

Relevant security issues include, but are not limited to:

- unsafe handling of local paths passed to
  [`rt_read_pdf()`](https://choxos.github.io/rtransparency/reference/rt_read_pdf.md)
  or XML readers,
- XML parsing behavior that could expose users to unsafe input handling,
- shell invocation problems around external tools such as `pdftotext`,
- accidental exposure of private article text, paths, or metadata in
  logs.

Detector accuracy disagreements and general methodological limitations
are not security vulnerabilities. Please report those as ordinary
issues.
