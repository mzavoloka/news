function refreshTG() {
  fetch('http://localhost/news/allitems')
    .then((res) => res.json())
    .then((json) => refreshItems(json))
}

const tgdiv = document.getElementById('tg');
const ytdiv = document.getElementById('yt');
const sldiv = document.getElementById('sl');
const otdiv = document.getElementById('ot');

function refreshItems(allitems) {
  tgdiv.replaceChildren();
  for ( var tgitem of allitems.tg_news ) {
    tgdiv.append(createTgItemDiv(tgitem));
  }
  ytdiv.replaceChildren();
  for ( var ytitem of allitems.yt_news ) {
    ytdiv.append(createYtItemDiv(ytitem));
  }
  sldiv.replaceChildren();
  for ( var slitem of allitems.sl_news ) {
    sldiv.append(createSlItemDiv(slitem));
  }
  otdiv.replaceChildren();
  for ( var otitem of allitems.ot_news ) {
    otdiv.append(createOtItemDiv(otitem));
  }
}

function createTgItemDiv(tgitem) {
  tgitemdiv = document.createElement('div');
  tgitemdiv.classList.add('tgitem');
  tgitemdiv.classList.add(tgitem.recency);
  tgitemdiv.insertAdjacentHTML('beforeend', tgitem.content);
  return tgitemdiv;
}

function createYtItemDiv(ytitem) {
  ytitemdiv = document.createElement('div');
  ytitemdiv.classList.add('ytitem');
  ytitemdiv.classList.add(ytitem.recency);

  var s = document.createElement('small');

  var a = document.createElement('a');
  a.setAttribute('href', ytitem.url);
  a.innerHTML = ytitem.title;

  s.append(a);
  s.insertAdjacentHTML('beforeend', ytitem.hdate + ytitem.author);

  ytitemdiv.append(s);
  return ytitemdiv;
}

function createSlItemDiv(slitem) {
  slitemdiv = document.createElement('div');
  slitemdiv.classList.add('slitem');
  slitemdiv.classList.add(slitem.recency);

  var a = document.createElement('a');
  a.setAttribute('href', slitem.url);
  a.innerHTML = slitem.title;

  slitemdiv.append(a);

  slitemdiv.insertAdjacentHTML(
    'beforeend',
    '<small><b>' + slitem.author + '</b> ' + slitem.hdate + '</small></br>' +
    '<small>'+slitem.content+'</small>'
  );

  return slitemdiv;
}

function createOtItemDiv(otitem) {
  otitemdiv = document.createElement('div');
  otitemdiv.classList.add('otitem');
  otitemdiv.classList.add(otitem.recency);

  var a = document.createElement('a');
  a.setAttribute('href', otitem.url);
  a.innerHTML = otitem.title;

  otitemdiv.append(a);

  otitemdiv.insertAdjacentHTML(
    'beforeend',
    ' ' + otitem.hdate + '</br>' +
    '<small>'+otitem.content+'</small>'
  );

  return otitemdiv;
}

refreshTG();
setInterval(() => refreshTG(), 5000);
