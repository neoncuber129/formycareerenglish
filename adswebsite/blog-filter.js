(function () {
  var grid = document.querySelector("[data-blog-grid]");
  var searchInput = document.querySelector("[data-blog-search]");
  var tagContainer = document.querySelector("[data-blog-tags]");
  if (!grid) return;

  var LANG_STORAGE = "formycareer-site-lang";
  var activeTag = "all";
  var activeKeyword = "";
  var posts = [];

  function getLang() {
    try {
      var v = localStorage.getItem(LANG_STORAGE);
      if (v === "vi" || v === "zh") return v;
    } catch (e) {}
    return "en";
  }

  function t(key, fallback) {
    var lang = getLang();
    var pack =
      window.FormyCareerStrings && window.FormyCareerStrings[lang]
        ? window.FormyCareerStrings[lang]
        : null;
    if (pack && pack[key]) return pack[key];
    return fallback;
  }

  function pickLocalized(post, baseKey) {
    var lang = getLang();
    if (lang === "vi") {
      var tv = post[baseKey + "Vi"];
      return tv != null && tv !== "" ? tv : post[baseKey];
    }
    if (lang === "zh") {
      var tz = post[baseKey + "Zh"];
      return tz != null && tz !== "" ? tz : post[baseKey];
    }
    return post[baseKey];
  }

  function escapeHtml(text) {
    return String(text || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  function cardMarkup(post) {
    var title = pickLocalized(post, "title");
    var description = pickLocalized(post, "description");
    var date = pickLocalized(post, "date");
    var pub = t("blog.publishedPrefix", "Published");
    return (
      '<a class="blog-card" href="' +
      escapeHtml(post.url) +
      '">' +
      '<img src="' +
      escapeHtml(post.image) +
      '" alt="' +
      escapeHtml(post.imageAlt || title) +
      '" loading="lazy" decoding="async" />' +
      "<h2>" +
      escapeHtml(title) +
      "</h2>" +
      '<p class="meta">' +
      escapeHtml(pub) +
      " " +
      escapeHtml(date) +
      "</p>" +
      "<p>" +
      escapeHtml(description) +
      "</p>" +
      "</a>"
    );
  }

  function tagLabel(tag) {
    var key = tag === "all" ? "tag.all" : "tag." + tag;
    var fallback =
      tag === "all"
        ? "All"
        : tag.charAt(0).toUpperCase() + tag.slice(1);
    return t(key, fallback);
  }

  function renderTags(items) {
    if (!tagContainer) return;
    var unique = { all: true };
    items.forEach(function (post) {
      (post.tags || []).forEach(function (tag) {
        unique[tag] = true;
      });
    });
    tagContainer.innerHTML = Object.keys(unique)
      .map(function (tag) {
        var label = tagLabel(tag);
        var activeClass = tag === activeTag ? " is-active" : "";
        return (
          '<button type="button" class="tag-chip' +
          activeClass +
          '" data-tag="' +
          escapeHtml(tag) +
          '">' +
          escapeHtml(label) +
          "</button>"
        );
      })
      .join("");
  }

  function filterAndRender() {
    var keyword = activeKeyword.trim().toLowerCase();
    var filtered = posts.filter(function (post) {
      var tagMatch =
        activeTag === "all" || (post.tags || []).indexOf(activeTag) !== -1;
      var title = pickLocalized(post, "title");
      var description = pickLocalized(post, "description");
      var text = (
        title +
        " " +
        description +
        " " +
        (post.tags || []).join(" ")
      ).toLowerCase();
      var keywordMatch = !keyword || text.indexOf(keyword) !== -1;
      return tagMatch && keywordMatch;
    });

    if (!filtered.length) {
      grid.innerHTML =
        '<p class="muted">' +
        escapeHtml(t("blog.noMatch", "No matching posts found.")) +
        "</p>";
      return;
    }
    grid.innerHTML = filtered.map(cardMarkup).join("");
  }

  fetch("/posts.json")
    .then(function (res) {
      return res.json();
    })
    .then(function (data) {
      posts = Array.isArray(data) ? data : [];
      renderTags(posts);
      filterAndRender();
    })
    .catch(function () {
      grid.innerHTML =
        '<p class="muted">' +
        escapeHtml(
          t("blog.loadFail", "Could not load blog posts right now."),
        ) +
        "</p>";
    });

  if (searchInput) {
    searchInput.addEventListener("input", function () {
      activeKeyword = searchInput.value || "";
      filterAndRender();
    });
  }

  if (tagContainer) {
    tagContainer.addEventListener("click", function (event) {
      var target = event.target;
      if (!(target instanceof HTMLElement)) return;
      var tag = target.getAttribute("data-tag");
      if (!tag) return;
      activeTag = tag;
      renderTags(posts);
      filterAndRender();
    });
  }

  window.addEventListener("formycareer-langchange", function () {
    if (!posts.length) return;
    renderTags(posts);
    filterAndRender();
  });
})();
