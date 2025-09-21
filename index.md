---
layout: splash
permalink: /
title: "Welcome to Tech Blog"
header:
  overlay_color: "#000"
  overlay_filter: "0.45"
  overlay_image: /assets/images/hero2.png
  actions:
    - label: "Read the blog"
      url: "#latest-posts"
excerpt: "Hey there! This is my little corner on the web where I share my journey with Java, Python, Node.js, AWS, and whatever cool tech I stumble upon while working. I’ll be posting about challenges I face, neat tricks I discover, and updates from my personal projects. Think of it as a mix of tech notes, experiments, and personal growth stories — all in one place!"
---

<div class="page__lead">
Welcome! Glad you’re here dive in, explore the blogs, and enjoy the read! 
</div>

<!-- Latest posts as horizontal cards -->
<h2 id="latest-posts">Latest posts</h2>
<div class="feature__wrapper">
  {% assign posts_list = site.posts %}
  {% for post in posts_list limit:3  %}
    {% include post-card.html post=post %}
  {% endfor %}
</div>
