<script setup>
  import { ref, onMounted } from 'vue'

  const slitems = ref([])
  const ytitems = ref([])
  const tgitems = ref([])
  const otitems = ref([])

  onMounted(() => {
    refreshTG()
    setInterval(() => refreshTG(), 5000)
  })

  function refreshTG() {
    fetch('/news/allitems')
      .then((res) => res.json())
      .then((json) => refreshItems(json))
  }

  function refreshItems(allitems) {
    tgitems.value = allitems.tg_news;
    ytitems.value = allitems.yt_news;
    slitems.value = allitems.sl_news;
    otitems.value = allitems.ot_news;
  }
</script>

<template>
  <div class="wrapper">
    <div class="tg">
      <div v-for="tg in tgitems" :key="tg.id" class="tgitem" :class="tg.recency" v-html="tg.content"></div>
      <!--<p style="display: none;">{{tg.hdate}} <a :href="tg.url">{{tg.url}}></a></p>-->
    </div>
    <div class="yt">
      <div v-for="yt in ytitems" :key="yt.id" class="ytitem" :class="yt.recency">
        <small><a :href="yt.url">{{yt.title}}</a>{{yt.hdate}} {{yt.author}}</small>
        <p style="display: none;">{{yt.content}}</p>
      </div>
    </div>

    <div class="sl">
      <div v-for="sl in slitems" :key="sl.id" class="slitem" :class="sl.recency">
        <a :href="sl.url">{{sl.title}}</a>
        <small><b>{{sl.author}}</b>&nbsp;{{sl.hdate}}</small></br>
        <small v-html="sl.content"></small>
      </div>
    </div>

    <div class="ot">
      <h4 style="display: none;">Others</h4>
      <div v-for="ot in otitems" :key="ot.id" class="otitem" :class="ot.recency">
        <a :href="ot.url">{{ot.title}}</a>{{ot.hdate}}</br>
        <small v-html="ot.content"></small>
      </div>
    </div>
  </div>
</template>
