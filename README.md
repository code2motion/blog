# Minimal Mistakes Starter (Hero + Horizontal Post Cards)

This is a ready-to-run Jekyll site using the **Minimal Mistakes** theme with:
- Header nav (About + Logo)
- Hero/header image with title + lead text
- Posts shown as **horizontal cards** with an excerpt
- **Learn more** button to full posts
- Click-to-reveal **Quick summary** per card

## Get started

1. Install Ruby + Bundler.
2. From this folder, run:

```bash
bundle install
bundle exec jekyll serve
```

Visit: http://127.0.0.1:4000/blog/  (adjust if you change `baseurl` in `_config.yml`).

## Customize

- Replace `/assets/images/hero.jpg` and `/assets/images/logo.png` with your own.
- Edit `_data/navigation.yml` to change the masthead links.
- Add posts under `_posts/` with front matter including `excerpt:` or a `<!--more-->` tag.
