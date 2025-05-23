<script setup>
  import { ref, onMounted, toRaw } from 'vue'

  const slitems = ref([])
  const ytitems = ref([])
  const tgitems = ref([])
  const otitems = ref([])

  onMounted(() => {
    refreshAllItems()
    setInterval(() => refreshAllItems(), 5000)
  })

  function refreshAllItems() {
    fetch('/news/allitems')
      .then((res) => res.json())
      .then((json) => setAllItems(json))
  }

  function setAllItems(allitems) {
    tgitems.value = allitems.tg_news.map( x => ({ ...x, marked_as_read: localStorage.getItem(x.id) }) )
    ytitems.value = allitems.yt_news.map( x => ({ ...x, marked_as_read: localStorage.getItem(x.id) }) )
    slitems.value = allitems.sl_news.map( x => ({ ...x, marked_as_read: localStorage.getItem(x.id) }) )
    otitems.value = allitems.ot_news.map( x => ({ ...x, marked_as_read: localStorage.getItem(x.id) }) )
  }

  function mark_all_as_read() {
    const mark = (el) => {
      localStorage.setItem(el.id, true)
      if ( !el.marked_as_read ) { el.marked_as_read = true }
    }
    tgitems.value.forEach(el => mark(el))
    ytitems.value.forEach(el => mark(el))
    slitems.value.forEach(el => mark(el))
    otitems.value.forEach(el => mark(el))
  }
</script>

<template>
  <div class="wrapper">
    <div class="tg">
      <div v-for="tg in tgitems" :key="tg.id" class="tgitem" :class="{ marked_as_read: tg.marked_as_read }" v-html="tg.content"></div>
      <!--<p style="display: none;">{{tg.hdate}} <a :href="tg.url">{{tg.url}}></a></p>-->
    </div>
    <div class="yt">
      <button id="mark_all_as_read" @click="mark_all_as_read">Mark all as read</button>
      <div v-for="yt in ytitems" :key="yt.id" class="ytitem" :class="{ marked_as_read: yt.marked_as_read }">
        <small>{{yt.author}}</small><br/>
        <small>{{yt.hdate}}</small><br/>
        <a :href="yt.url">{{yt.title}}</a>
        <p style="display: none;">{{yt.content}}</p>
      </div>
    </div>

    <div class="sl">
      <div v-for="sl in slitems" :key="sl.id" class="slitem" :class="{ marked_as_read: sl.marked_as_read }">
        <small><b>{{sl.author}}</b> &nbsp; {{sl.hdate}}</small><br/>
        <a :href="sl.url">{{sl.title}}</a><br/>
        <span v-html="sl.content"></span>
      </div>
    </div>

    <div class="ot">
      <h4 style="display: none;">Others</h4>
      <div v-for="ot in otitems" :key="ot.id" class="otitem" :class="{ marked_as_read: ot.marked_as_read }">
        <small>{{ot.url.match(/:\/\/(.[^\/]+)(.*)/)[1]}} &nbsp; {{ot.hdate}}</small><br/>
        <a :href="ot.url">{{ot.title}}</a><br/>
        <span v-html="ot.content"></span>
      </div>
    </div>
  </div>
</template>
