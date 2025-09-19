---
layout: splash
permalink: /
title: "Welcome to My Blog"
header:
overlay_color: "#000"
overlay_filter: "0.45" # darken the image
overlay_image: /assets/images/hero.jpg
caption: "Photo credit: Your Name"
actions:
- label: "Read the blog"
url: "#latest-posts"
excerpt: "A short lead about what you write. Replace this placeholder with a crisp, one- or two-sentence value proposition."
---


<div class="page__lead">
Replace this block with a friendly welcome paragraph. You can mention tech stacks, interests, or what readers will find here.
</div>


<!-- Latest posts as horizontal cards -->
<h2 id="latest-posts">Latest posts</h2>
<div class="cards cards--horizontal">
{% assign posts_list = paginator.posts | default: site.posts %}
{% for post in posts_list %}
{% include post-card.html post=post %}
{% endfor %}
</div>


<!-- Pagination (optional) -->
{% if paginator.total_pages > 1 %}
<nav class="pagination">
{% if paginator.previous_page %}
<a class="pagination--item" href="{{ paginator.previous_page_path | relative_url }}">← Newer</a>
{% endif %}
<span class="pagination--item">Page {{ paginator.page }} of {{ paginator.total_pages }}</span>
{% if paginator.next_page %}
<a class="pagination--item" href="{{ paginator.next_page_path | relative_url }}">Older →</a>
{% endif %}
</nav>
{% endif %}