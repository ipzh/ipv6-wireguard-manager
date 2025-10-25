/**
 * Service Worker for IPv6 WireGuard Manager PWA
 * 提供离线支持、缓存管理、后台同步等功能
 */

const CACHE_NAME = 'ipv6-wireguard-manager-v1.0.0';
const STATIC_CACHE_NAME = 'ipv6-wireguard-manager-static-v1.0.0';
const DYNAMIC_CACHE_NAME = 'ipv6-wireguard-manager-dynamic-v1.0.0';
const API_CACHE_NAME = 'ipv6-wireguard-manager-api-v1.0.0';

// 需要缓存的静态资源
const STATIC_ASSETS = [
    '/',
    '/offline.html',
    '/manifest.json',
    '/css/bootstrap.min.css',
    '/css/app.css',
    '/js/bootstrap.bundle.min.js',
    '/js/app.js',
    '/images/logo.png',
    '/images/icon-192.png',
    '/images/icon-512.png'
];

// 需要缓存的API端点
const API_ENDPOINTS = [
    '/api/v1/status/health',
    '/api/v1/auth/me',
    '/api/v1/wireguard/servers',
    '/api/v1/wireguard/clients',
    '/api/v1/bgp/sessions',
    '/api/v1/ipv6/pools',
    '/api/v1/monitoring/dashboard'
];

// 缓存策略配置
const CACHE_STRATEGIES = {
    // 静态资源 - 缓存优先
    static: {
        strategy: 'cache-first',
        cacheName: STATIC_CACHE_NAME,
        maxAge: 86400000, // 24小时
        maxEntries: 100
    },
    // API数据 - 网络优先
    api: {
        strategy: 'network-first',
        cacheName: API_CACHE_NAME,
        maxAge: 300000, // 5分钟
        maxEntries: 50
    },
    // 图片资源 - 缓存优先
    images: {
        strategy: 'cache-first',
        cacheName: DYNAMIC_CACHE_NAME,
        maxAge: 2592000000, // 30天
        maxEntries: 200
    },
    // HTML页面 - 网络优先
    pages: {
        strategy: 'network-first',
        cacheName: DYNAMIC_CACHE_NAME,
        maxAge: 3600000, // 1小时
        maxEntries: 50
    }
};

// 安装事件
self.addEventListener('install', event => {
    console.log('Service Worker: 安装中...');
    
    event.waitUntil(
        Promise.all([
            // 缓存静态资源
            caches.open(STATIC_CACHE_NAME).then(cache => {
                console.log('Service Worker: 缓存静态资源');
                return cache.addAll(STATIC_ASSETS);
            }),
            // 跳过等待，立即激活
            self.skipWaiting()
        ])
    );
});

// 激活事件
self.addEventListener('activate', event => {
    console.log('Service Worker: 激活中...');
    
    event.waitUntil(
        Promise.all([
            // 清理旧缓存
            cleanupOldCaches(),
            // 声明控制权
            self.clients.claim()
        ])
    );
});

// 获取事件
self.addEventListener('fetch', event => {
    const { request } = event;
    const url = new URL(request.url);
    
    // 跳过非HTTP请求
    if (!request.url.startsWith('http')) {
        return;
    }
    
    // 根据请求类型选择缓存策略
    if (isStaticAsset(request)) {
        event.respondWith(handleStaticAsset(request));
    } else if (isAPIRequest(request)) {
        event.respondWith(handleAPIRequest(request));
    } else if (isImageRequest(request)) {
        event.respondWith(handleImageRequest(request));
    } else if (isPageRequest(request)) {
        event.respondWith(handlePageRequest(request));
    } else {
        event.respondWith(handleDefaultRequest(request));
    }
});

// 后台同步事件
self.addEventListener('sync', event => {
    console.log('Service Worker: 后台同步', event.tag);
    
    if (event.tag === 'background-sync') {
        event.waitUntil(doBackgroundSync());
    }
});

// 推送事件
self.addEventListener('push', event => {
    console.log('Service Worker: 收到推送消息');
    
    const options = {
        body: event.data ? event.data.text() : '您有新的通知',
        icon: '/images/icon-192.png',
        badge: '/images/badge-72.png',
        vibrate: [100, 50, 100],
        data: {
            dateOfArrival: Date.now(),
            primaryKey: 1
        },
        actions: [
            {
                action: 'explore',
                title: '查看详情',
                icon: '/images/checkmark.png'
            },
            {
                action: 'close',
                title: '关闭',
                icon: '/images/xmark.png'
            }
        ]
    };
    
    event.waitUntil(
        self.registration.showNotification('IPv6 WireGuard Manager', options)
    );
});

// 通知点击事件
self.addEventListener('notificationclick', event => {
    console.log('Service Worker: 通知被点击', event.notification.tag);
    
    event.notification.close();
    
    if (event.action === 'explore') {
        event.waitUntil(
            clients.openWindow('/')
        );
    } else if (event.action === 'close') {
        // 关闭通知
        return;
    } else {
        // 默认行为
        event.waitUntil(
            clients.openWindow('/')
        );
    }
});

// 工具函数
function isStaticAsset(request) {
    const url = new URL(request.url);
    return url.pathname.match(/\.(css|js|woff|woff2|ttf|eot)$/);
}

function isAPIRequest(request) {
    const url = new URL(request.url);
    return url.pathname.startsWith('/api/');
}

function isImageRequest(request) {
    const url = new URL(request.url);
    return url.pathname.match(/\.(png|jpg|jpeg|gif|svg|webp|ico)$/);
}

function isPageRequest(request) {
    const url = new URL(request.url);
    return request.method === 'GET' && 
           !url.pathname.includes('.') && 
           !url.pathname.startsWith('/api/');
}

// 缓存策略实现
async function handleStaticAsset(request) {
    const strategy = CACHE_STRATEGIES.static;
    
    try {
        // 缓存优先策略
        const cachedResponse = await caches.match(request);
        if (cachedResponse) {
            return cachedResponse;
        }
        
        // 从网络获取
        const networkResponse = await fetch(request);
        if (networkResponse.ok) {
            const cache = await caches.open(strategy.cacheName);
            cache.put(request, networkResponse.clone());
        }
        
        return networkResponse;
    } catch (error) {
        console.error('静态资源获取失败:', error);
        return new Response('资源不可用', { status: 404 });
    }
}

async function handleAPIRequest(request) {
    const strategy = CACHE_STRATEGIES.api;
    
    try {
        // 网络优先策略
        const networkResponse = await fetch(request);
        
        if (networkResponse.ok) {
            const cache = await caches.open(strategy.cacheName);
            cache.put(request, networkResponse.clone());
        }
        
        return networkResponse;
    } catch (error) {
        console.log('网络请求失败，尝试从缓存获取:', error);
        
        // 网络失败时从缓存获取
        const cachedResponse = await caches.match(request);
        if (cachedResponse) {
            return cachedResponse;
        }
        
        // 返回离线响应
        return new Response(
            JSON.stringify({ 
                error: '网络不可用', 
                offline: true,
                message: '请检查网络连接后重试'
            }),
            { 
                status: 503,
                headers: { 'Content-Type': 'application/json' }
            }
        );
    }
}

async function handleImageRequest(request) {
    const strategy = CACHE_STRATEGIES.images;
    
    try {
        // 缓存优先策略
        const cachedResponse = await caches.match(request);
        if (cachedResponse) {
            return cachedResponse;
        }
        
        // 从网络获取
        const networkResponse = await fetch(request);
        if (networkResponse.ok) {
            const cache = await caches.open(strategy.cacheName);
            cache.put(request, networkResponse.clone());
        }
        
        return networkResponse;
    } catch (error) {
        console.error('图片获取失败:', error);
        return new Response('图片不可用', { status: 404 });
    }
}

async function handlePageRequest(request) {
    const strategy = CACHE_STRATEGIES.pages;
    
    try {
        // 网络优先策略
        const networkResponse = await fetch(request);
        
        if (networkResponse.ok) {
            const cache = await caches.open(strategy.cacheName);
            cache.put(request, networkResponse.clone());
        }
        
        return networkResponse;
    } catch (error) {
        console.log('页面请求失败，尝试从缓存获取:', error);
        
        // 网络失败时从缓存获取
        const cachedResponse = await caches.match(request);
        if (cachedResponse) {
            return cachedResponse;
        }
        
        // 返回离线页面
        const offlineResponse = await caches.match('/offline.html');
        if (offlineResponse) {
            return offlineResponse;
        }
        
        return new Response('页面不可用', { status: 404 });
    }
}

async function handleDefaultRequest(request) {
    try {
        return await fetch(request);
    } catch (error) {
        console.error('请求失败:', error);
        return new Response('请求失败', { status: 503 });
    }
}

// 清理旧缓存
async function cleanupOldCaches() {
    const cacheNames = await caches.keys();
    const validCaches = [
        STATIC_CACHE_NAME,
        DYNAMIC_CACHE_NAME,
        API_CACHE_NAME
    ];
    
    const deletePromises = cacheNames
        .filter(cacheName => !validCaches.includes(cacheName))
        .map(cacheName => {
            console.log('Service Worker: 删除旧缓存', cacheName);
            return caches.delete(cacheName);
        });
    
    await Promise.all(deletePromises);
    
    // 清理过期缓存条目
    await cleanupExpiredEntries();
}

// 清理过期缓存条目
async function cleanupExpiredEntries() {
    const cacheNames = [STATIC_CACHE_NAME, DYNAMIC_CACHE_NAME, API_CACHE_NAME];
    
    for (const cacheName of cacheNames) {
        const cache = await caches.open(cacheName);
        const requests = await cache.keys();
        
        for (const request of requests) {
            const response = await cache.match(request);
            if (response) {
                const dateHeader = response.headers.get('date');
                if (dateHeader) {
                    const responseDate = new Date(dateHeader);
                    const now = new Date();
                    const age = now - responseDate;
                    
                    // 根据缓存策略清理过期条目
                    let maxAge = 86400000; // 默认24小时
                    if (cacheName === API_CACHE_NAME) {
                        maxAge = 300000; // API缓存5分钟
                    } else if (cacheName === DYNAMIC_CACHE_NAME) {
                        maxAge = 3600000; // 动态缓存1小时
                    }
                    
                    if (age > maxAge) {
                        await cache.delete(request);
                        console.log('Service Worker: 删除过期缓存条目', request.url);
                    }
                }
            }
        }
    }
}

// 后台同步
async function doBackgroundSync() {
    console.log('Service Worker: 执行后台同步');
    
    try {
        // 同步离线数据
        await syncOfflineData();
        
        // 更新缓存
        await updateCache();
        
        console.log('Service Worker: 后台同步完成');
    } catch (error) {
        console.error('Service Worker: 后台同步失败', error);
    }
}

// 同步离线数据
async function syncOfflineData() {
    // 这里可以实现离线数据的同步逻辑
    // 例如：同步离线时创建的数据到服务器
    console.log('Service Worker: 同步离线数据');
}

// 更新缓存
async function updateCache() {
    console.log('Service Worker: 更新缓存');
    
    // 更新静态资源缓存
    try {
        const cache = await caches.open(STATIC_CACHE_NAME);
        const requests = await cache.keys();
        
        for (const request of requests) {
            try {
                const networkResponse = await fetch(request);
                if (networkResponse.ok) {
                    await cache.put(request, networkResponse);
                }
            } catch (error) {
                console.log('更新缓存失败:', request.url, error);
            }
        }
    } catch (error) {
        console.error('更新缓存失败:', error);
    }
}

// 消息处理
self.addEventListener('message', event => {
    const { type, payload } = event.data;
    
    switch (type) {
        case 'SKIP_WAITING':
            self.skipWaiting();
            break;
        case 'GET_VERSION':
            event.ports[0].postMessage({ version: CACHE_NAME });
            break;
        case 'CLEAR_CACHE':
            clearAllCaches().then(() => {
                event.ports[0].postMessage({ success: true });
            });
            break;
        case 'UPDATE_CACHE':
            updateCache().then(() => {
                event.ports[0].postMessage({ success: true });
            });
            break;
    }
});

// 清理所有缓存
async function clearAllCaches() {
    const cacheNames = await caches.keys();
    const deletePromises = cacheNames.map(cacheName => caches.delete(cacheName));
    await Promise.all(deletePromises);
    console.log('Service Worker: 所有缓存已清理');
}

// 错误处理
self.addEventListener('error', event => {
    console.error('Service Worker: 发生错误', event.error);
});

self.addEventListener('unhandledrejection', event => {
    console.error('Service Worker: 未处理的Promise拒绝', event.reason);
});

console.log('Service Worker: 已加载');
