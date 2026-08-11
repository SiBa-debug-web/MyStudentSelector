(() => {
  "use strict";

  const STORAGE_KEY = "convonotes.people.v1";
  const FOLLOW_UP_DAYS = 30;
  const DAY_MS = 24 * 60 * 60 * 1000;

  const CATEGORY_LABELS = { man: "Man", woman: "Woman", child: "Child" };

  /**
   * @typedef {{id:string, at:string, kind:"initial"|"followup", location:string, notes:string}} Conversation
   * @typedef {{id:string, name:string, category:"man"|"woman"|"child", suburb:string,
   *            shortlisted:boolean, archived:boolean, createdAt:string,
   *            conversations:Conversation[]}} Person
   */

  /** @type {Person[]} */
  let people = [];
  let currentPersonId = null;

  const filters = { search: "", suburb: "all", scope: "active" };

  // Modal editing state
  let personModalEditingId = null;
  let personModalCategory = "man";
  let convoModalEditingId = null;
  let convoModalKind = "initial";
  // The datetime-local value we pre-filled, so we can tell whether the user
  // actually changed it (that input only has minute precision, which would
  // otherwise collapse the order of entries logged in the same minute).
  let convoModalDefaultDateValue = "";

  // ---------------------------------------------------------------- storage
  function load() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      people = raw ? JSON.parse(raw) : [];
    } catch (e) {
      people = [];
    }
  }

  function save() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(people));
  }

  function uid() {
    return Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
  }

  function getPerson(id) {
    return people.find((p) => p.id === id) || null;
  }

  // ---------------------------------------------------------------- helpers
  function escapeHtml(str) {
    const div = document.createElement("div");
    div.textContent = str == null ? "" : String(str);
    return div.innerHTML;
  }

  function initialsOf(name) {
    const parts = String(name).trim().split(/\s+/).filter(Boolean);
    if (parts.length === 0) return "?";
    if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  /** Most recent conversation time, falling back to when the person was added. */
  function lastActivityMs(person) {
    let latest = 0;
    for (const c of person.conversations) {
      const t = new Date(c.at).getTime();
      if (!isNaN(t) && t > latest) latest = t;
    }
    if (latest === 0) {
      const created = new Date(person.createdAt).getTime();
      latest = isNaN(created) ? 0 : created;
    }
    return latest;
  }

  function daysSinceActivity(person) {
    const last = lastActivityMs(person);
    if (!last) return 0;
    return Math.floor((Date.now() - last) / DAY_MS);
  }

  function isOverdue(person) {
    if (person.archived) return false;
    return daysSinceActivity(person) >= FOLLOW_UP_DAYS;
  }

  function formatDateTime(iso) {
    const d = new Date(iso);
    if (isNaN(d.getTime())) return "";
    const opts = {
      day: "numeric",
      month: "short",
      hour: "numeric",
      minute: "2-digit",
    };
    // Only spell out the year when it isn't the current one.
    if (d.getFullYear() !== new Date().getFullYear()) opts.year = "numeric";
    return d.toLocaleString(undefined, opts);
  }

  function describeGap(days) {
    if (days <= 0) return "today";
    if (days === 1) return "yesterday";
    if (days < 30) return `${days} days ago`;
    const months = Math.floor(days / 30);
    return months === 1 ? "over a month ago" : `${months} months ago`;
  }

  function toLocalInputValue(date) {
    const pad = (n) => String(n).padStart(2, "0");
    return (
      date.getFullYear() +
      "-" + pad(date.getMonth() + 1) +
      "-" + pad(date.getDate()) +
      "T" + pad(date.getHours()) +
      ":" + pad(date.getMinutes())
    );
  }

  // ------------------------------------------------------------------ toast
  let toastTimer = null;
  function toast(msg) {
    const el = document.getElementById("toast");
    el.textContent = msg;
    el.hidden = false;
    el.style.animation = "none";
    void el.offsetWidth;
    el.style.animation = "";
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => { el.hidden = true; }, 2400);
  }

  // ------------------------------------------------------------- navigation
  function showPeopleView() {
    currentPersonId = null;
    document.getElementById("view-person").hidden = true;
    document.getElementById("view-people").hidden = false;
    renderPeople();
  }

  function showPersonView(id, opts = {}) {
    if (!getPerson(id)) return showPeopleView();
    currentPersonId = id;
    document.getElementById("view-people").hidden = true;
    document.getElementById("view-person").hidden = false;
    renderPerson();
    if (!opts.skipHistory) {
      history.pushState({ personId: id }, "", "#person=" + id);
    }
  }

  window.addEventListener("popstate", (e) => {
    const pid = e.state && e.state.personId;
    if (pid && getPerson(pid)) showPersonView(pid, { skipHistory: true });
    else showPeopleView();
  });

  // ------------------------------------------------------- render: people
  function visiblePeople() {
    const search = filters.search.trim().toLowerCase();
    let list = people.filter((p) => {
      switch (filters.scope) {
        case "archived": if (!p.archived) return false; break;
        case "shortlist": if (p.archived || !p.shortlisted) return false; break;
        case "overdue": if (!isOverdue(p)) return false; break;
        default: if (p.archived) return false;
      }
      if (filters.suburb !== "all") {
        if ((p.suburb || "").toLowerCase() !== filters.suburb.toLowerCase()) return false;
      }
      if (search && !p.name.toLowerCase().includes(search)) return false;
      return true;
    });

    if (filters.scope === "overdue") {
      list.sort((a, b) => lastActivityMs(a) - lastActivityMs(b));
    } else {
      list.sort((a, b) => a.name.localeCompare(b.name));
    }
    return list;
  }

  function renderSuburbFilter() {
    const select = document.getElementById("suburb-filter");
    const suburbs = [...new Set(
      people.map((p) => (p.suburb || "").trim()).filter(Boolean)
    )].sort((a, b) => a.localeCompare(b));

    const previous = filters.suburb;
    select.innerHTML = '<option value="all">All suburbs</option>';
    for (const s of suburbs) {
      const opt = document.createElement("option");
      opt.value = s;
      opt.textContent = s;
      select.appendChild(opt);
    }
    // Keep the current selection if that suburb still exists.
    if (previous !== "all" && !suburbs.some((s) => s.toLowerCase() === previous.toLowerCase())) {
      filters.suburb = "all";
    }
    select.value = filters.suburb;

    const datalist = document.getElementById("suburb-suggestions");
    datalist.innerHTML = "";
    for (const s of suburbs) {
      const opt = document.createElement("option");
      opt.value = s;
      datalist.appendChild(opt);
    }
  }

  function renderCounts() {
    const shortlist = people.filter((p) => !p.archived && p.shortlisted).length;
    const overdue = people.filter((p) => isOverdue(p)).length;
    document.getElementById("count-shortlist").textContent = shortlist > 0 ? String(shortlist) : "";
    document.getElementById("count-overdue").textContent = overdue > 0 ? String(overdue) : "";
  }

  function renderPeople() {
    renderSuburbFilter();
    renderCounts();

    const listEl = document.getElementById("people-list");
    const emptyEl = document.getElementById("people-empty");
    const titleEl = document.getElementById("people-empty-title");
    const textEl = document.getElementById("people-empty-text");
    const emptyBtn = document.getElementById("empty-add-person-btn");

    listEl.innerHTML = "";
    const list = visiblePeople();

    if (list.length === 0) {
      emptyEl.hidden = false;
      const noneAtAll = people.length === 0;
      emptyBtn.hidden = !noneAtAll;
      if (noneAtAll) {
        titleEl.textContent = "No people yet";
        textEl.textContent = "Add someone to start recording your conversations with them.";
      } else {
        const labels = {
          active: "No active people match",
          shortlist: "Nobody shortlisted",
          overdue: "Nothing overdue",
          archived: "Nothing archived",
        };
        const texts = {
          active: "Try clearing the search or suburb filter.",
          shortlist: "Star someone to keep them handy for a quick follow-up.",
          overdue: `Everyone has been followed up within ${FOLLOW_UP_DAYS} days.`,
          archived: "Archived people are paused conversations you can resume later.",
        };
        titleEl.textContent = labels[filters.scope];
        textEl.textContent = texts[filters.scope];
      }
      return;
    }

    emptyEl.hidden = true;
    for (const person of list) {
      listEl.appendChild(renderPersonRow(person));
    }
  }

  function renderPersonRow(person) {
    const li = document.createElement("li");
    li.className = "person-row" + (person.archived ? " is-archived" : "");

    const count = person.conversations.length;
    const overdue = isOverdue(person);
    const gap = describeGap(daysSinceActivity(person));
    const sub = count === 0
      ? `No conversations yet · added ${gap}`
      : `${count} conversation${count === 1 ? "" : "s"} · last ${gap}`;

    const tags = [];
    if (overdue) tags.push('<span class="tag tag-overdue">Follow up</span>');
    if (person.archived) tags.push('<span class="tag tag-archived">Archived</span>');

    li.innerHTML = `
      <div class="avatar cat-${escapeHtml(person.category)}">${escapeHtml(initialsOf(person.name))}</div>
      <div class="person-info">
        <div class="person-name-line">
          <span class="person-name">${escapeHtml(person.name)}</span>
          ${person.shortlisted && !person.archived ? '<span class="star-inline"><svg viewBox="0 0 24 24" width="14" height="14"><path fill="currentColor" d="m12 17.3-6.2 3.7 1.7-7L2 9.2l7.1-.6L12 2l2.9 6.6 7.1.6-5.5 4.8 1.7 7z"/></svg></span>' : ""}
          ${tags.join("")}
        </div>
        <div class="person-sub">${escapeHtml(CATEGORY_LABELS[person.category] || "")}${person.suburb ? " · " + escapeHtml(person.suburb) : ""}</div>
        <div class="person-sub">${escapeHtml(sub)}</div>
      </div>
    `;
    li.addEventListener("click", () => showPersonView(person.id));
    return li;
  }

  // ------------------------------------------------------- render: person
  function renderPerson() {
    const person = getPerson(currentPersonId);
    if (!person) return;

    document.getElementById("person-title").textContent = person.name;

    const avatar = document.getElementById("person-avatar");
    avatar.textContent = initialsOf(person.name);
    avatar.className = "avatar cat-" + person.category;

    document.getElementById("person-card-name").textContent = person.name;
    const metaBits = [CATEGORY_LABELS[person.category] || ""];
    if (person.suburb) metaBits.push(person.suburb);
    document.getElementById("person-card-meta").textContent = metaBits.filter(Boolean).join(" · ");

    const starBtn = document.getElementById("shortlist-btn");
    starBtn.classList.toggle("is-on", !!person.shortlisted);

    const banner = document.getElementById("person-banner");
    if (person.archived) {
      banner.hidden = false;
      banner.className = "person-banner muted-banner";
      banner.textContent = "📦 Archived — this conversation is paused. Reminders are off.";
    } else if (isOverdue(person)) {
      banner.hidden = false;
      banner.className = "person-banner warn";
      const days = daysSinceActivity(person);
      banner.textContent = `⏰ No follow-up in ${days} days — time to check in.`;
    } else {
      banner.hidden = true;
    }

    const count = person.conversations.length;
    document.getElementById("convo-count").textContent = count > 0 ? `(${count})` : "";

    const listEl = document.getElementById("convo-list");
    const emptyEl = document.getElementById("convos-empty");
    listEl.innerHTML = "";

    if (count === 0) {
      emptyEl.hidden = false;
      return;
    }
    emptyEl.hidden = true;

    // Newest first; ids are time-prefixed so they break ties deterministically.
    const sorted = [...person.conversations].sort((a, b) => {
      const diff = new Date(b.at).getTime() - new Date(a.at).getTime();
      return diff !== 0 ? diff : b.id.localeCompare(a.id);
    });
    for (const convo of sorted) {
      listEl.appendChild(renderConvoItem(person, convo));
    }
  }

  function renderConvoItem(person, convo) {
    const li = document.createElement("li");
    li.className = "convo-item";
    const kindLabel = convo.kind === "initial" ? "Initial" : "Follow-up";

    li.innerHTML = `
      <div class="convo-head">
        <span class="kind-pill kind-${escapeHtml(convo.kind)}">${kindLabel}</span>
        <span class="convo-date">${escapeHtml(formatDateTime(convo.at))}</span>
        <span class="convo-actions">
          <button class="mini-btn edit-convo-btn" aria-label="Edit conversation">
            <svg viewBox="0 0 24 24" width="15" height="15"><path fill="currentColor" d="M4 17.2V20h2.8l8.5-8.5-2.8-2.8L4 17.2ZM19.7 7.3a1 1 0 0 0 0-1.4l-1.6-1.6a1 1 0 0 0-1.4 0l-1.4 1.4 2.8 2.8 1.6-1.2Z"/></svg>
          </button>
          <button class="mini-btn danger delete-convo-btn" aria-label="Delete conversation">
            <svg viewBox="0 0 24 24" width="15" height="15"><path fill="currentColor" d="M6 7h12l-1 13H7L6 7Zm3-3h6l1 2H8l1-2Z"/></svg>
          </button>
        </span>
      </div>
      ${convo.location ? `<div class="convo-location">📍 ${escapeHtml(convo.location)}</div>` : ""}
      <div class="convo-notes">${escapeHtml(convo.notes)}</div>
    `;

    li.querySelector(".edit-convo-btn").addEventListener("click", (e) => {
      e.stopPropagation();
      openConvoModal(convo.id);
    });
    li.querySelector(".delete-convo-btn").addEventListener("click", (e) => {
      e.stopPropagation();
      if (confirm("Delete this conversation entry?")) {
        person.conversations = person.conversations.filter((c) => c.id !== convo.id);
        save();
        renderPerson();
        toast("Conversation deleted");
      }
    });
    return li;
  }

  // --------------------------------------------------------- person modal
  function setSegmented(containerId, value) {
    const container = document.getElementById(containerId);
    for (const btn of container.querySelectorAll("button")) {
      btn.classList.toggle("is-on", btn.dataset.value === value);
    }
  }

  function openPersonModal(editingId) {
    personModalEditingId = editingId || null;
    const person = editingId ? getPerson(editingId) : null;

    document.getElementById("person-modal-title").textContent = person ? "Edit person" : "Add person";
    document.getElementById("person-name-input").value = person ? person.name : "";
    document.getElementById("person-suburb-input").value = person ? person.suburb : "";
    personModalCategory = person ? person.category : "man";
    setSegmented("person-category-seg", personModalCategory);

    document.getElementById("person-modal-backdrop").hidden = false;
    setTimeout(() => document.getElementById("person-name-input").focus(), 60);
  }

  function closePersonModal() {
    document.getElementById("person-modal-backdrop").hidden = true;
  }

  function savePersonModal() {
    const name = document.getElementById("person-name-input").value.trim();
    const suburb = document.getElementById("person-suburb-input").value.trim();
    if (!name) {
      toast("Please enter a name");
      return;
    }

    if (personModalEditingId) {
      const person = getPerson(personModalEditingId);
      if (person) {
        person.name = name;
        person.suburb = suburb;
        person.category = personModalCategory;
      }
      save();
      closePersonModal();
      if (currentPersonId) renderPerson(); else renderPeople();
      toast("Details updated");
    } else {
      const person = {
        id: uid(),
        name,
        category: personModalCategory,
        suburb,
        shortlisted: false,
        archived: false,
        createdAt: new Date().toISOString(),
        conversations: [],
      };
      people.push(person);
      save();
      closePersonModal();
      showPersonView(person.id);
      toast("Person added — log your first conversation");
    }
  }

  // ----------------------------------------------------- conversation modal
  function renderLocationSuggestions() {
    const locations = [...new Set(
      people.flatMap((p) => p.conversations.map((c) => (c.location || "").trim())).filter(Boolean)
    )].sort((a, b) => a.localeCompare(b));
    const datalist = document.getElementById("location-suggestions");
    datalist.innerHTML = "";
    for (const loc of locations) {
      const opt = document.createElement("option");
      opt.value = loc;
      datalist.appendChild(opt);
    }
  }

  function openConvoModal(editingId) {
    const person = getPerson(currentPersonId);
    if (!person) return;

    convoModalEditingId = editingId || null;
    const convo = editingId ? person.conversations.find((c) => c.id === editingId) : null;

    document.getElementById("convo-modal-title").textContent = convo ? "Edit conversation" : "Log conversation";

    // A person's very first entry defaults to "initial"; everything after is a follow-up.
    convoModalKind = convo ? convo.kind : (person.conversations.length === 0 ? "initial" : "followup");
    setSegmented("convo-kind-seg", convoModalKind);

    convoModalDefaultDateValue = toLocalInputValue(convo ? new Date(convo.at) : new Date());
    document.getElementById("convo-datetime-input").value = convoModalDefaultDateValue;
    document.getElementById("convo-location-input").value = convo ? convo.location : "";
    document.getElementById("convo-notes-input").value = convo ? convo.notes : "";

    renderLocationSuggestions();
    document.getElementById("convo-modal-backdrop").hidden = false;
    setTimeout(() => document.getElementById("convo-notes-input").focus(), 60);
  }

  function closeConvoModal() {
    document.getElementById("convo-modal-backdrop").hidden = true;
  }

  function saveConvoModal() {
    const person = getPerson(currentPersonId);
    if (!person) return;

    const rawDate = document.getElementById("convo-datetime-input").value;
    let parsed;
    if (!rawDate || rawDate === convoModalDefaultDateValue) {
      // Untouched: keep full second precision so entries logged moments apart
      // still sort in the order they were made.
      parsed = convoModalEditingId
        ? new Date(person.conversations.find((c) => c.id === convoModalEditingId).at)
        : new Date();
    } else {
      parsed = new Date(rawDate);
    }
    if (isNaN(parsed.getTime())) {
      toast("Please pick a valid date and time");
      return;
    }

    const location = document.getElementById("convo-location-input").value.trim();
    const notes = document.getElementById("convo-notes-input").value.trim();

    if (convoModalEditingId) {
      const convo = person.conversations.find((c) => c.id === convoModalEditingId);
      if (convo) {
        convo.at = parsed.toISOString();
        convo.kind = convoModalKind;
        convo.location = location;
        convo.notes = notes;
      }
      save();
      closeConvoModal();
      renderPerson();
      toast("Conversation updated");
    } else {
      person.conversations.push({
        id: uid(),
        at: parsed.toISOString(),
        kind: convoModalKind,
        location,
        notes,
      });
      save();
      closeConvoModal();
      renderPerson();
      toast("Conversation logged");
    }
  }

  // --------------------------------------------------------- options sheet
  function openPersonSheet() {
    const person = getPerson(currentPersonId);
    if (!person) return;
    document.getElementById("sheet-shortlist").textContent =
      person.shortlisted ? "Remove from shortlist" : "Add to shortlist";
    document.getElementById("sheet-archive").textContent =
      person.archived ? "Unarchive (resume)" : "Archive (pause)";
    document.getElementById("person-sheet-backdrop").hidden = false;
  }

  function closePersonSheet() {
    document.getElementById("person-sheet-backdrop").hidden = true;
  }

  function toggleShortlist() {
    const person = getPerson(currentPersonId);
    if (!person) return;
    person.shortlisted = !person.shortlisted;
    save();
    renderPerson();
    toast(person.shortlisted ? "Added to shortlist" : "Removed from shortlist");
  }

  function toggleArchive() {
    const person = getPerson(currentPersonId);
    if (!person) return;
    person.archived = !person.archived;
    save();
    renderPerson();
    toast(person.archived ? "Archived — reminders paused" : "Unarchived — reminders back on");
  }

  function deletePerson() {
    const person = getPerson(currentPersonId);
    if (!person) return;
    if (!confirm(`Delete ${person.name} and all their conversations? This can't be undone.`)) return;
    people = people.filter((p) => p.id !== person.id);
    save();
    history.back();
  }

  // ------------------------------------------------------------------ init
  function init() {
    load();

    // People view
    document.getElementById("add-person-fab").addEventListener("click", () => openPersonModal(null));
    document.getElementById("add-person-top-btn").addEventListener("click", () => openPersonModal(null));
    document.getElementById("empty-add-person-btn").addEventListener("click", () => openPersonModal(null));

    document.getElementById("search-input").addEventListener("input", (e) => {
      filters.search = e.target.value;
      renderPeople();
    });

    document.getElementById("suburb-filter").addEventListener("change", (e) => {
      filters.suburb = e.target.value;
      renderPeople();
    });

    document.getElementById("chip-row").addEventListener("click", (e) => {
      const chip = e.target.closest(".chip");
      if (!chip) return;
      filters.scope = chip.dataset.scope;
      for (const c of document.querySelectorAll("#chip-row .chip")) {
        c.classList.toggle("is-active", c === chip);
      }
      renderPeople();
    });

    // Person view
    document.getElementById("back-btn").addEventListener("click", () => history.back());
    document.getElementById("person-menu-btn").addEventListener("click", openPersonSheet);
    document.getElementById("shortlist-btn").addEventListener("click", toggleShortlist);
    document.getElementById("add-convo-btn").addEventListener("click", () => openConvoModal(null));
    document.getElementById("add-convo-fab").addEventListener("click", () => openConvoModal(null));
    document.getElementById("empty-add-convo-btn").addEventListener("click", () => openConvoModal(null));

    // Person modal
    document.getElementById("person-modal-cancel").addEventListener("click", closePersonModal);
    document.getElementById("person-modal-save").addEventListener("click", savePersonModal);
    document.getElementById("person-modal-backdrop").addEventListener("click", (e) => {
      if (e.target.id === "person-modal-backdrop") closePersonModal();
    });
    document.getElementById("person-category-seg").addEventListener("click", (e) => {
      const btn = e.target.closest("button");
      if (!btn) return;
      personModalCategory = btn.dataset.value;
      setSegmented("person-category-seg", personModalCategory);
    });
    document.getElementById("person-name-input").addEventListener("keydown", (e) => {
      if (e.key === "Enter") savePersonModal();
    });

    // Conversation modal
    document.getElementById("convo-modal-cancel").addEventListener("click", closeConvoModal);
    document.getElementById("convo-modal-save").addEventListener("click", saveConvoModal);
    document.getElementById("convo-modal-backdrop").addEventListener("click", (e) => {
      if (e.target.id === "convo-modal-backdrop") closeConvoModal();
    });
    document.getElementById("convo-kind-seg").addEventListener("click", (e) => {
      const btn = e.target.closest("button");
      if (!btn) return;
      convoModalKind = btn.dataset.value;
      setSegmented("convo-kind-seg", convoModalKind);
    });

    // Options sheet
    document.getElementById("person-sheet-backdrop").addEventListener("click", (e) => {
      if (e.target.id === "person-sheet-backdrop") closePersonSheet();
    });
    document.getElementById("sheet-cancel").addEventListener("click", closePersonSheet);
    document.getElementById("sheet-edit").addEventListener("click", () => {
      closePersonSheet();
      openPersonModal(currentPersonId);
    });
    document.getElementById("sheet-shortlist").addEventListener("click", () => {
      closePersonSheet();
      toggleShortlist();
    });
    document.getElementById("sheet-archive").addEventListener("click", () => {
      closePersonSheet();
      toggleArchive();
    });
    document.getElementById("sheet-delete").addEventListener("click", () => {
      closePersonSheet();
      deletePerson();
    });

    // Routing
    const match = location.hash.match(/^#person=(.+)$/);
    if (match && getPerson(match[1])) {
      history.replaceState({ personId: match[1] }, "", location.hash);
      showPersonView(match[1], { skipHistory: true });
    } else {
      history.replaceState({}, "", location.pathname + location.search);
      showPeopleView();
    }

    if ("serviceWorker" in navigator) {
      navigator.serviceWorker.register("sw.js").catch(() => {});
    }
  }

  document.addEventListener("DOMContentLoaded", init);
})();
