# ericwen229.github.io

A personal blog built with Jekyll and hosted on GitHub Pages.

## Key dependencies

| Dependency | Version | Purpose |
| --- | --- | --- |
| Ruby | 3.3.x (tested with 3.3.12) | Runtime |
| github-pages | 232 | GitHub Pages dependencies |
| Jekyll | 3.10.0 | Static site generator |
| Minima | 2.5.1 | Theme |
| jekyll-feed | 0.17.0 | Atom feed |
| jekyll-seo-tag | 2.8.0 | SEO metadata |
| WEBrick | 1.9.2 | Local preview server |

These are the tested versions; `Gemfile` defines the dependency constraints.
Bundler installs and runs the dependencies.

## Build and run

Install Ruby 3.3 with Homebrew on macOS:

```sh
brew install ruby@3.3
export PATH="$(brew --prefix ruby@3.3)/bin:$PATH"
```

From the repository root, install dependencies and start the preview server:

```sh
bundle config set --local path vendor/bundle
bundle install
bundle exec jekyll serve
```

Open http://localhost:4000. Press `Ctrl+C` to stop.
Restart the server after changing `_config.yml`.

Build for production (output: `_site/`):

```sh
JEKYLL_ENV=production bundle exec jekyll build
```

## Write articles

Create `_posts/YYYY-MM-DD-post-title.md` with YAML front matter followed by Markdown:

```markdown
---
layout: post
title: "POST-TITLE"
date: YYYY-MM-DD hh:mm:ss -0000
categories: CATEGORY-1 CATEGORY-2
---

Write your article here using **Markdown**.
```

Replace the placeholders with your title, publication date, and categories.
Use a numeric timezone offset, such as `+0800` for China Standard Time.

Historical articles are stored in `archive/_posts/` and excluded from the site.
