import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'myHouses',
      component: () => import('../views/MyHousesView.vue')
    },
    {
      path: '/market',
      name: 'market',
      component: () => import('../views/MarketView.vue')
    }
  ]
})

export default router
