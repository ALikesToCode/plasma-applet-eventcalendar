/*
 * The desktop at the top of the homepage: a live panel clock, the popup's
 * month grid and agenda dates for today, and the clock button that opens and
 * closes the popup like the real widget. The events are placeholders.
 */
(function () {
  'use strict';

  // Which calendar sources have events on a given day of the month. Purely
  // decorative, so the grid looks lived in.
  function sourcesFor(day) {
    var sources = [];
    if (day % 3 === 1 || day % 7 === 2) sources.push('google');
    if (day % 5 === 3) sources.push('ical');
    if (day % 9 === 4) sources.push('plasma');
    return sources;
  }

  function sameDay(a, b) {
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
  }

  // Month grid for the month containing `today`: weekday names, then six weeks
  // starting on Sunday, as the widget shows by default.
  function buildMonth(today, locale) {
    var weekdayFormat = new Intl.DateTimeFormat(locale, { weekday: 'short' });
    var html = '';
    for (var w = 0; w < 7; w++) {
      var name = weekdayFormat.format(new Date(2023, 0, 1 + w));
      html += '<li class="weekday">' + name + '</li>';
    }
    var first = new Date(today.getFullYear(), today.getMonth(), 1);
    var start = new Date(first);
    start.setDate(1 - first.getDay());
    for (var i = 0; i < 42; i++) {
      var day = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
      var classes = ['day'];
      if (day.getMonth() !== today.getMonth()) classes.push('is-other');
      if (sameDay(day, today)) classes.push('is-today');
      var stripes = sourcesFor(day.getDate()).map(function (source) {
        return '<i class="src-' + source + '"></i>';
      }).join('');
      html += '<li class="' + classes.join(' ') + '">' + day.getDate()
        + (stripes ? '<span class="stripes">' + stripes + '</span>' : '') + '</li>';
    }
    return html;
  }

  if (typeof module !== 'undefined') {
    module.exports = { buildMonth: buildMonth };
    return;
  }

  var popup = document.getElementById('demo-popup');
  var clock = document.getElementById('panel-clock');
  if (!popup || !clock) return;

  var locale; // undefined: the visitor's own locale
  var timeFormat = new Intl.DateTimeFormat(locale, { hour: 'numeric', minute: '2-digit' });

  function renderClock(now) {
    // The widget's default clock shows "Sun 1" before the time.
    clock.querySelector('.clock-date').textContent =
      new Intl.DateTimeFormat(locale, { weekday: 'short' }).format(now) + ' ' + now.getDate();
    clock.querySelector('.clock-time').textContent = timeFormat.format(now);
  }

  function renderPopup(now) {
    var heading = popup.querySelector('.month-head h2');
    if (heading) heading.textContent = new Intl.DateTimeFormat(locale, { dateStyle: 'long' }).format(now);

    var grid = popup.querySelector('.month-grid');
    if (grid) grid.innerHTML = buildMonth(now, locale);

    var dayFormat = new Intl.DateTimeFormat(locale, { month: 'short', day: 'numeric' });
    var weekdayFormat = new Intl.DateTimeFormat(locale, { weekday: 'short' });
    popup.querySelectorAll('[data-offset]').forEach(function (el) {
      var date = new Date(now.getFullYear(), now.getMonth(), now.getDate() + Number(el.dataset.offset));
      el.querySelector('b').textContent = dayFormat.format(date);
      el.querySelector('span').textContent = weekdayFormat.format(date);
    });

    popup.querySelectorAll('[data-start]').forEach(function (el) {
      var parts = function (value) {
        var hm = value.split(':');
        return new Date(2000, 0, 1, Number(hm[0]), Number(hm[1]));
      };
      var text = timeFormat.format(parts(el.dataset.start));
      if (el.dataset.end) text += ' – ' + timeFormat.format(parts(el.dataset.end));
      el.textContent = text;
    });
  }

  function tick() {
    var now = new Date();
    renderClock(now);
    if (now.getHours() === 0 && now.getMinutes() === 0) renderPopup(now);
    setTimeout(tick, 60000 - (now.getSeconds() * 1000 + now.getMilliseconds()) + 20);
  }

  function setOpen(open) {
    popup.classList.toggle('is-closed', !open);
    clock.setAttribute('aria-expanded', String(open));
  }

  clock.addEventListener('click', function () {
    setOpen(popup.classList.contains('is-closed'));
  });

  clock.addEventListener('keydown', function (event) {
    if (event.key === 'Escape' && !popup.classList.contains('is-closed')) setOpen(false);
  });

  renderPopup(new Date());
  tick();
})();
