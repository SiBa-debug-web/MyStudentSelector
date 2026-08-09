(() => {
  "use strict";

  const STORAGE_KEY = "mss.rosters.v1";

  /** @typedef {{id:string,name:string,absent:boolean,timesCalled:number,calledThisRound:boolean,lastCalledAt:number|null}} Student */
  /** @typedef {{id:string,name:string,createdAt:number,students:Student[]}} Roster */

  /** @type {Roster[]} */
  let rosters = [];
  let currentRosterId = null;
  let sheetTargetRosterId = null;

  // ---------- persistence ----------
  function load() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      rosters = raw ? JSON.parse(raw) : [];
    } catch (e) {
      rosters = [];
    }
  }
  function save() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(rosters));
  }

  function uid() {
    return Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
  }

  function getRoster(id) {
    return rosters.find((r) => r.id === id) || null;
  }

  // ---------- toast ----------
  let toastTimer = null;
  function toast(msg) {
    const el = document.getElementById("toast");
    el.textContent = msg;
    el.hidden = false;
    el.style.animation = "none";
    // restart animation
    void el.offsetWidth;
    el.style.animation = "";
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => {
      el.hidden = true;
    }, 2200);
  }

  // ---------- navigation ----------
  function showRosterListView() {
    currentRosterId = null;
    document.getElementById("view-roster").hidden = true;
    document.getElementById("view-rosters").hidden = false;
    renderRosterList();
  }

  function showRosterDetailView(id, opts = {}) {
    const roster = getRoster(id);
    if (!roster) return showRosterListView();
    currentRosterId = id;
    document.getElementById("view-rosters").hidden = true;
    document.getElementById("view-roster").hidden = false;
    resetPickerStage();
    renderRosterDetail();
    if (!opts.skipHistory) {
      history.pushState({ rosterId: id }, "", "#roster=" + id);
    }
  }

  window.addEventListener("popstate", (e) => {
    const rid = e.state && e.state.rosterId;
    if (rid) {
      showRosterDetailView(rid, { skipHistory: true });
    } else {
      showRosterListView();
    }
  });

  // ---------- rendering: roster list ----------
  function initials(name) {
    const parts = name.trim().split(/\s+/).filter(Boolean);
    if (parts.length === 0) return "?";
    if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  function renderRosterList() {
    const listEl = document.getElementById("roster-list");
    const emptyEl = document.getElementById("roster-empty");
    listEl.innerHTML = "";

    if (rosters.length === 0) {
      emptyEl.hidden = false;
      return;
    }
    emptyEl.hidden = true;

    const sorted = [...rosters].sort((a, b) => a.name.localeCompare(b.name));
    for (const roster of sorted) {
      const total = roster.students.length;
      const active = roster.students.filter((s) => !s.absent).length;
      const li = document.createElement("li");
      li.className = "roster-card";
      li.innerHTML = `
        <div class="roster-avatar">${escapeHtml(initials(roster.name))}</div>
        <div class="roster-info">
          <div class="roster-name">${escapeHtml(roster.name)}</div>
          <div class="roster-meta">${total} student${total === 1 ? "" : "s"}${
        total !== active ? ` · ${active} present` : ""
      }</div>
        </div>
        <div class="roster-chevron">
          <svg viewBox="0 0 24 24" width="20" height="20"><path fill="currentColor" d="m9 6 6 6-6 6"/></svg>
        </div>
      `;
      li.addEventListener("click", () => showRosterDetailView(roster.id));
      listEl.appendChild(li);
    }
  }

  function escapeHtml(str) {
    const div = document.createElement("div");
    div.textContent = str;
    return div.innerHTML;
  }

  // ---------- rendering: roster detail ----------
  function resetPickerStage() {
    const placeholder = document.getElementById("picker-placeholder");
    const nameEl = document.getElementById("picker-name");
    placeholder.hidden = false;
    nameEl.hidden = true;
    nameEl.classList.remove("animate");
    nameEl.innerHTML = "";
  }

  function renderRosterDetail() {
    const roster = getRoster(currentRosterId);
    if (!roster) return;

    document.getElementById("roster-title").textContent = roster.name;

    const total = roster.students.filter((s) => !s.absent).length;
    const calledCount = roster.students.filter((s) => !s.absent && s.calledThisRound).length;
    document.getElementById("picker-progress").textContent =
      total === 0 ? "No students yet" : `${calledCount} of ${total} called this round`;

    document.getElementById("reset-round-btn").hidden = calledCount === 0;

    const listEl = document.getElementById("student-list");
    const emptyEl = document.getElementById("students-empty");
    listEl.innerHTML = "";

    if (roster.students.length === 0) {
      emptyEl.hidden = false;
    } else {
      emptyEl.hidden = true;
      const sorted = [...roster.students].sort((a, b) => a.name.localeCompare(b.name));
      for (const s of sorted) {
        listEl.appendChild(renderStudentRow(roster, s));
      }
    }
  }

  function renderStudentRow(roster, student) {
    const li = document.createElement("li");
    li.className =
      "student-row" +
      (student.absent ? " absent" : "") +
      (student.calledThisRound ? " called-this-round" : "");

    const sub = student.absent
      ? "Marked absent"
      : student.timesCalled === 0
      ? "Not called yet"
      : `Called ${student.timesCalled} time${student.timesCalled === 1 ? "" : "s"}`;

    li.innerHTML = `
      <div class="student-check">
        <svg viewBox="0 0 24 24" width="13" height="13"><path fill="currentColor" d="M9 16.2 4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4z"/></svg>
      </div>
      <div class="student-name-wrap">
        <div class="student-name">${escapeHtml(student.name)}</div>
        <div class="student-sub">${sub}</div>
      </div>
      <div class="student-actions">
        <button class="mini-btn toggle-absent-btn ${student.absent ? "active-toggle" : ""}" aria-label="Toggle absent" title="Mark ${student.absent ? "present" : "absent"}">
          <svg viewBox="0 0 24 24" width="16" height="16"><path fill="currentColor" d="M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8Zm0 2c-4 0-8 2-8 5v1h16v-1c0-3-4-5-8-5Z"/></svg>
        </button>
        <button class="mini-btn danger delete-student-btn" aria-label="Delete student" title="Delete">
          <svg viewBox="0 0 24 24" width="16" height="16"><path fill="currentColor" d="M6 7h12l-1 13H7L6 7Zm3-3h6l1 2H8l1-2Z"/></svg>
        </button>
      </div>
    `;

    li.querySelector(".toggle-absent-btn").addEventListener("click", (e) => {
      e.stopPropagation();
      student.absent = !student.absent;
      if (student.absent) student.calledThisRound = false;
      save();
      renderRosterDetail();
    });
    li.querySelector(".delete-student-btn").addEventListener("click", (e) => {
      e.stopPropagation();
      if (confirm(`Remove ${student.name} from this class?`)) {
        roster.students = roster.students.filter((s) => s.id !== student.id);
        save();
        renderRosterDetail();
      }
    });

    return li;
  }

  // ---------- picking logic ----------
  let picking = false;

  function pickStudent() {
    if (picking) return;
    const roster = getRoster(currentRosterId);
    if (!roster) return;

    const present = roster.students.filter((s) => !s.absent);
    if (present.length === 0) {
      toast(present.length === 0 && roster.students.length > 0 ? "Everyone is marked absent" : "Add some students first");
      return;
    }

    let eligible = present.filter((s) => !s.calledThisRound);
    let startedNewRound = false;
    if (eligible.length === 0) {
      // everyone in this round has been called — start a fresh round automatically
      present.forEach((s) => (s.calledThisRound = false));
      eligible = present.slice();
      startedNewRound = true;
    }

    const chosen = eligible[Math.floor(Math.random() * eligible.length)];

    picking = true;
    const btn = document.getElementById("pick-btn");
    btn.classList.add("picking");
    btn.disabled = true;

    const nameEl = document.getElementById("picker-name");
    const placeholder = document.getElementById("picker-placeholder");
    placeholder.hidden = true;
    nameEl.hidden = false;
    nameEl.classList.remove("animate");

    const shuffleNames = present.length > 1 ? present : eligible;
    let ticks = 0;
    const maxTicks = 12;
    const interval = setInterval(() => {
      const r = shuffleNames[Math.floor(Math.random() * shuffleNames.length)];
      nameEl.textContent = r.name;
      ticks++;
      if (ticks >= maxTicks) {
        clearInterval(interval);
        finishPick(roster, chosen, startedNewRound);
      }
    }, 55);
  }

  function finishPick(roster, chosen, startedNewRound) {
    chosen.calledThisRound = true;
    chosen.timesCalled += 1;
    chosen.lastCalledAt = Date.now();
    save();

    const nameEl = document.getElementById("picker-name");
    nameEl.innerHTML = escapeHtml(chosen.name);
    if (chosen.timesCalled > 1) {
      const badge = document.createElement("span");
      badge.className = "repeat-badge";
      badge.textContent = `Called ${chosen.timesCalled} times total`;
      nameEl.appendChild(badge);
    }
    nameEl.classList.add("animate");

    if (navigator.vibrate) {
      try {
        navigator.vibrate(15);
      } catch (e) {}
    }

    const btn = document.getElementById("pick-btn");
    btn.classList.remove("picking");
    btn.disabled = false;
    picking = false;

    if (startedNewRound) {
      toast("New round started — everyone had been called!");
    }

    renderRosterDetail();
  }

  function startNewRound() {
    const roster = getRoster(currentRosterId);
    if (!roster) return;
    roster.students.forEach((s) => (s.calledThisRound = false));
    save();
    renderRosterDetail();
    resetPickerStage();
    toast("New round started");
  }

  function resetStats() {
    const roster = getRoster(currentRosterId);
    if (!roster) return;
    roster.students.forEach((s) => {
      s.timesCalled = 0;
      s.calledThisRound = false;
      s.lastCalledAt = null;
    });
    save();
    renderRosterDetail();
    resetPickerStage();
    toast("Call counts reset");
  }

  // ---------- roster CRUD ----------
  let rosterModalMode = "create"; // "create" | "rename"

  function openRosterModal(mode) {
    rosterModalMode = mode;
    const backdrop = document.getElementById("roster-modal-backdrop");
    const title = document.getElementById("roster-modal-title");
    const input = document.getElementById("roster-name-input");
    if (mode === "create") {
      title.textContent = "New class";
      input.value = "";
    } else {
      const roster = getRoster(currentRosterId);
      title.textContent = "Rename class";
      input.value = roster ? roster.name : "";
    }
    backdrop.hidden = false;
    setTimeout(() => input.focus(), 50);
  }

  function closeRosterModal() {
    document.getElementById("roster-modal-backdrop").hidden = true;
  }

  function saveRosterModal() {
    const input = document.getElementById("roster-name-input");
    const name = input.value.trim();
    if (!name) {
      toast("Please enter a class name");
      return;
    }
    if (rosterModalMode === "create") {
      const roster = { id: uid(), name, createdAt: Date.now(), students: [] };
      rosters.push(roster);
      save();
      closeRosterModal();
      showRosterDetailView(roster.id);
    } else {
      const roster = getRoster(currentRosterId);
      if (roster) {
        roster.name = name;
        save();
        renderRosterDetail();
      }
      closeRosterModal();
    }
  }

  function deleteCurrentRoster() {
    const roster = getRoster(currentRosterId);
    if (!roster) return;
    if (confirm(`Delete "${roster.name}"? This can't be undone.`)) {
      rosters = rosters.filter((r) => r.id !== roster.id);
      save();
      history.back();
    }
  }

  // ---------- add students ----------
  function openStudentsModal() {
    document.getElementById("single-student-input").value = "";
    document.getElementById("bulk-student-input").value = "";
    document.getElementById("students-modal-backdrop").hidden = false;
    setTimeout(() => document.getElementById("single-student-input").focus(), 50);
  }
  function closeStudentsModal() {
    document.getElementById("students-modal-backdrop").hidden = true;
  }
  function saveStudentsModal() {
    const roster = getRoster(currentRosterId);
    if (!roster) return;

    const names = new Set();
    const single = document.getElementById("single-student-input").value.trim();
    if (single) names.add(single);

    const bulk = document.getElementById("bulk-student-input").value;
    bulk
      .split(/[\n,]/)
      .map((s) => s.trim())
      .filter(Boolean)
      .forEach((n) => names.add(n));

    if (names.size === 0) {
      toast("Enter at least one name");
      return;
    }

    const existingLower = new Set(roster.students.map((s) => s.name.toLowerCase()));
    let added = 0;
    for (const name of names) {
      if (existingLower.has(name.toLowerCase())) continue;
      roster.students.push({
        id: uid(),
        name,
        absent: false,
        timesCalled: 0,
        calledThisRound: false,
        lastCalledAt: null,
      });
      existingLower.add(name.toLowerCase());
      added++;
    }
    save();
    closeStudentsModal();
    renderRosterDetail();
    toast(added > 0 ? `Added ${added} student${added === 1 ? "" : "s"}` : "Those students are already on the list");
  }

  // ---------- roster options sheet ----------
  function openRosterSheet() {
    sheetTargetRosterId = currentRosterId;
    document.getElementById("roster-sheet-backdrop").hidden = false;
  }
  function closeRosterSheet() {
    document.getElementById("roster-sheet-backdrop").hidden = true;
  }

  // ---------- wire up events ----------
  function init() {
    load();

    document.getElementById("add-roster-fab").addEventListener("click", () => openRosterModal("create"));
    document.getElementById("empty-add-roster-btn").addEventListener("click", () => openRosterModal("create"));

    document.getElementById("back-btn").addEventListener("click", () => history.back());
    document.getElementById("roster-menu-btn").addEventListener("click", openRosterSheet);

    document.getElementById("pick-btn").addEventListener("click", pickStudent);
    document.getElementById("reset-round-btn").addEventListener("click", startNewRound);

    document.getElementById("add-students-btn").addEventListener("click", openStudentsModal);
    document.getElementById("empty-add-students-btn").addEventListener("click", openStudentsModal);

    document.getElementById("roster-modal-cancel").addEventListener("click", closeRosterModal);
    document.getElementById("roster-modal-save").addEventListener("click", saveRosterModal);
    document.getElementById("roster-modal-backdrop").addEventListener("click", (e) => {
      if (e.target.id === "roster-modal-backdrop") closeRosterModal();
    });
    document.getElementById("roster-name-input").addEventListener("keydown", (e) => {
      if (e.key === "Enter") saveRosterModal();
    });

    document.getElementById("students-modal-cancel").addEventListener("click", closeStudentsModal);
    document.getElementById("students-modal-save").addEventListener("click", saveStudentsModal);
    document.getElementById("students-modal-backdrop").addEventListener("click", (e) => {
      if (e.target.id === "students-modal-backdrop") closeStudentsModal();
    });

    document.getElementById("roster-sheet-backdrop").addEventListener("click", (e) => {
      if (e.target.id === "roster-sheet-backdrop") closeRosterSheet();
    });
    document.getElementById("sheet-cancel").addEventListener("click", closeRosterSheet);
    document.getElementById("sheet-rename").addEventListener("click", () => {
      closeRosterSheet();
      openRosterModal("rename");
    });
    document.getElementById("sheet-reset-round").addEventListener("click", () => {
      closeRosterSheet();
      startNewRound();
    });
    document.getElementById("sheet-reset-stats").addEventListener("click", () => {
      closeRosterSheet();
      if (confirm("Reset all call counts for this class?")) resetStats();
    });
    document.getElementById("sheet-delete").addEventListener("click", () => {
      closeRosterSheet();
      deleteCurrentRoster();
    });

    // initial route
    const hash = location.hash;
    const match = hash.match(/^#roster=(.+)$/);
    if (match && getRoster(match[1])) {
      history.replaceState({ rosterId: match[1] }, "", hash);
      showRosterDetailView(match[1], { skipHistory: true });
    } else {
      history.replaceState({}, "", location.pathname + location.search);
      showRosterListView();
    }

    if ("serviceWorker" in navigator) {
      navigator.serviceWorker.register("sw.js").catch(() => {});
    }
  }

  document.addEventListener("DOMContentLoaded", init);
})();
