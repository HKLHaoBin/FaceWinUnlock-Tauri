import { createRouter, createWebHashHistory } from 'vue-router'
import Init from '../views/Init.vue'
import MainLayout from '../layout/MainLayout.vue'
import Dashboard from '../views/Dashboard.vue'
import List from '../views/Faces/List.vue'
import Add from '../views/Faces/Add.vue'

const routes = [
	{ path: '/init', name: 'Init', component: Init, meta: { title: '系统初始化' }},
	{ 
		path: '/',
		component: MainLayout,
		children: [
			{
				path: '',
				name: 'Dashboard',
				component: Dashboard,
				meta: { title: '控制仪表盘' }
			},{
				path: 'faces',
				name: 'FaceList',
				component: List,
				meta: { title: '面容库管理' }
			},{
				path: 'faces/add',
				name: 'FaceAdd',
				component: Add,
				meta: { title: '录入/编辑面容' }
			}
		]
	}
]

const router = createRouter({
	history: createWebHashHistory(),
	routes
});

export default router