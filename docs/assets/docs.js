(() => {
  "use strict";
  const input = document.querySelector("[data-doc-search]");
  const sections = [...document.querySelectorAll("[data-doc-section]")];
  const empty = document.querySelector("[data-no-results]");
  if (!input || !sections.length) return;

  const normalize = value => String(value || "").toLocaleLowerCase().normalize("NFKC").trim();
  input.addEventListener("input", () => {
    const query = normalize(input.value);
    let visible = 0;
    for (const section of sections) {
      const match = !query || normalize(section.textContent).includes(query);
      section.hidden = !match;
      if (match) visible++;
    }
    if (empty) empty.hidden = visible !== 0;
  });
})();
