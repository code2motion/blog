---
title: "Posts by Collection"
permalink: /posts
layout: archive
author_profile: true
---

<div>
  {% for post in site.posts %}
    {% assign teaser = post.header.teaser | default: post.teaser | default: post.image %}
    <div class="list__item">
    <article class="archive__item">
      <a class="archive__item-teaser" href="{{ post.url | relative_url }}">
        {% if teaser %}
          <img src="{{ teaser | relative_url }}" alt="{{ post.title | escape }}">
        {% else %}
          <img src="{{ '/assets/images/default-teaser.jpg' | relative_url }}" alt="">
        {% endif %}
      </a>

      <h2 class="archive__item-title no_toc">
        <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
      </h2>

      <p class="page__meta">
        <p>
        {{ post.excerpt }}
        </p>
        <time datetime="{{ post.date | date_to_xmlschema }}">
          {{ post.date | date: "%b %-d, %Y" }}
        </time>
      </p>
    </article>
    </div>
  {% endfor %}
</div>