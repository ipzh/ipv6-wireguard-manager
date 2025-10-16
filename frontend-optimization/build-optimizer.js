/**
 * 前端构建优化器
 * 提供资源压缩、CDN支持、PWA功能等优化
 */
const fs = require('fs');
const path = require('path');
const { minify } = require('terser');
const CleanCSS = require('clean-css');
const imagemin = require('imagemin');
const imageminMozjpeg = require('imagemin-mozjpeg');
const imageminPngquant = require('imagemin-pngquant');
const imageminSvgo = require('imagemin-svgo');
const { gzipSync, brotliCompressSync } = require('zlib');
const crypto = require('crypto');

class FrontendOptimizer {
    constructor(config = {}) {
        this.config = {
            // 基础配置
            inputDir: config.inputDir || './php-frontend',
            outputDir: config.outputDir || './dist',
            publicPath: config.publicPath || '/',
            
            // 压缩配置
            minifyJS: config.minifyJS !== false,
            minifyCSS: config.minifyCSS !== false,
            minifyHTML: config.minifyHTML !== false,
            optimizeImages: config.optimizeImages !== false,
            
            // CDN配置
            enableCDN: config.enableCDN || false,
            cdnUrl: config.cdnUrl || '',
            cdnAssets: config.cdnAssets || ['css', 'js', 'images'],
            
            // 缓存配置
            enableCache: config.enableCache !== false,
            cacheVersion: config.cacheVersion || Date.now(),
            
            // PWA配置
            enablePWA: config.enablePWA || false,
            pwaConfig: {
                name: config.pwaName || 'IPv6 WireGuard Manager',
                shortName: config.pwaShortName || 'IPv6WGM',
                description: config.pwaDescription || 'IPv6 WireGuard Manager',
                themeColor: config.pwaThemeColor || '#1890ff',
                backgroundColor: config.pwaBackgroundColor || '#ffffff',
                display: config.pwaDisplay || 'standalone',
                orientation: config.pwaOrientation || 'portrait',
                startUrl: config.pwaStartUrl || '/',
                scope: config.pwaScope || '/',
                ...config.pwaConfig
            },
            
            // 压缩配置
            compression: {
                gzip: config.gzip !== false,
                brotli: config.brotli !== false,
                level: config.compressionLevel || 6
            },
            
            // 资源内联配置
            inlineAssets: {
                css: config.inlineCSS || false,
                js: config.inlineJS || false,
                images: config.inlineImages || false,
                maxSize: config.inlineMaxSize || 8192 // 8KB
            }
        };
        
        this.manifest = {
            name: this.config.pwaConfig.name,
            short_name: this.config.pwaConfig.shortName,
            description: this.config.pwaConfig.description,
            start_url: this.config.pwaConfig.startUrl,
            display: this.config.pwaConfig.display,
            orientation: this.config.pwaConfig.orientation,
            theme_color: this.config.pwaConfig.themeColor,
            background_color: this.config.pwaConfig.backgroundColor,
            scope: this.config.pwaConfig.scope,
            icons: [],
            categories: ['productivity', 'utilities'],
            lang: 'zh-CN',
            dir: 'ltr'
        };
        
        this.assetHashes = new Map();
        this.processedAssets = new Set();
    }
    
    async optimize() {
        console.log('🚀 开始前端优化...');
        
        try {
            // 创建输出目录
            await this.ensureOutputDir();
            
            // 处理HTML文件
            await this.processHTMLFiles();
            
            // 处理CSS文件
            await this.processCSSFiles();
            
            // 处理JavaScript文件
            await this.processJSFiles();
            
            // 处理图片文件
            if (this.config.optimizeImages) {
                await this.processImageFiles();
            }
            
            // 生成资源清单
            await this.generateAssetManifest();
            
            // 生成PWA文件
            if (this.config.enablePWA) {
                await this.generatePWAFiles();
            }
            
            // 生成压缩文件
            if (this.config.compression.gzip || this.config.compression.brotli) {
                await this.generateCompressedFiles();
            }
            
            // 生成CDN配置
            if (this.config.enableCDN) {
                await this.generateCDNConfig();
            }
            
            console.log('✅ 前端优化完成!');
            this.printOptimizationReport();
            
        } catch (error) {
            console.error('❌ 前端优化失败:', error);
            throw error;
        }
    }
    
    async ensureOutputDir() {
        const outputDir = this.config.outputDir;
        if (!fs.existsSync(outputDir)) {
            fs.mkdirSync(outputDir, { recursive: true });
        }
        
        // 创建子目录
        const subdirs = ['css', 'js', 'images', 'fonts', 'assets'];
        for (const subdir of subdirs) {
            const subdirPath = path.join(outputDir, subdir);
            if (!fs.existsSync(subdirPath)) {
                fs.mkdirSync(subdirPath, { recursive: true });
            }
        }
    }
    
    async processHTMLFiles() {
        console.log('📄 处理HTML文件...');
        
        const htmlFiles = this.findFiles(this.config.inputDir, '.html');
        
        for (const file of htmlFiles) {
            const content = fs.readFileSync(file, 'utf8');
            const relativePath = path.relative(this.config.inputDir, file);
            const outputPath = path.join(this.config.outputDir, relativePath);
            
            let optimizedContent = content;
            
            // 内联小资源
            if (this.config.inlineAssets.css) {
                optimizedContent = await this.inlineCSS(optimizedContent, file);
            }
            
            if (this.config.inlineAssets.js) {
                optimizedContent = await this.inlineJS(optimizedContent, file);
            }
            
            if (this.config.inlineAssets.images) {
                optimizedContent = await this.inlineImages(optimizedContent, file);
            }
            
            // 添加资源版本号
            if (this.config.enableCache) {
                optimizedContent = this.addCacheBusting(optimizedContent);
            }
            
            // 添加CDN支持
            if (this.config.enableCDN) {
                optimizedContent = this.addCDNSupport(optimizedContent);
            }
            
            // 压缩HTML
            if (this.config.minifyHTML) {
                optimizedContent = this.minifyHTML(optimizedContent);
            }
            
            // 确保输出目录存在
            const outputDir = path.dirname(outputPath);
            if (!fs.existsSync(outputDir)) {
                fs.mkdirSync(outputDir, { recursive: true });
            }
            
            fs.writeFileSync(outputPath, optimizedContent);
            console.log(`  ✓ ${relativePath}`);
        }
    }
    
    async processCSSFiles() {
        console.log('🎨 处理CSS文件...');
        
        const cssFiles = this.findFiles(this.config.inputDir, '.css');
        
        for (const file of cssFiles) {
            const content = fs.readFileSync(file, 'utf8');
            const relativePath = path.relative(this.config.inputDir, file);
            const outputPath = path.join(this.config.outputDir, relativePath);
            
            let optimizedContent = content;
            
            // 压缩CSS
            if (this.config.minifyCSS) {
                optimizedContent = await this.minifyCSS(optimizedContent);
            }
            
            // 添加资源版本号
            if (this.config.enableCache) {
                const hash = this.generateHash(optimizedContent);
                this.assetHashes.set(relativePath, hash);
                const hashedPath = this.addHashToFilename(relativePath, hash);
                const hashedOutputPath = path.join(this.config.outputDir, hashedPath);
                
                fs.writeFileSync(hashedOutputPath, optimizedContent);
                console.log(`  ✓ ${hashedPath}`);
            } else {
                fs.writeFileSync(outputPath, optimizedContent);
                console.log(`  ✓ ${relativePath}`);
            }
        }
    }
    
    async processJSFiles() {
        console.log('⚡ 处理JavaScript文件...');
        
        const jsFiles = this.findFiles(this.config.inputDir, '.js');
        
        for (const file of jsFiles) {
            const content = fs.readFileSync(file, 'utf8');
            const relativePath = path.relative(this.config.inputDir, file);
            const outputPath = path.join(this.config.outputDir, relativePath);
            
            let optimizedContent = content;
            
            // 压缩JavaScript
            if (this.config.minifyJS) {
                optimizedContent = await this.minifyJS(optimizedContent);
            }
            
            // 添加资源版本号
            if (this.config.enableCache) {
                const hash = this.generateHash(optimizedContent);
                this.assetHashes.set(relativePath, hash);
                const hashedPath = this.addHashToFilename(relativePath, hash);
                const hashedOutputPath = path.join(this.config.outputDir, hashedPath);
                
                fs.writeFileSync(hashedOutputPath, optimizedContent);
                console.log(`  ✓ ${hashedPath}`);
            } else {
                fs.writeFileSync(outputPath, optimizedContent);
                console.log(`  ✓ ${relativePath}`);
            }
        }
    }
    
    async processImageFiles() {
        console.log('🖼️ 优化图片文件...');
        
        const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.svg', '.webp'];
        const imageFiles = [];
        
        for (const ext of imageExtensions) {
            imageFiles.push(...this.findFiles(this.config.inputDir, ext));
        }
        
        for (const file of imageFiles) {
            const relativePath = path.relative(this.config.inputDir, file);
            const outputPath = path.join(this.config.outputDir, relativePath);
            
            try {
                // 确保输出目录存在
                const outputDir = path.dirname(outputPath);
                if (!fs.existsSync(outputDir)) {
                    fs.mkdirSync(outputDir, { recursive: true });
                }
                
                // 优化图片
                const ext = path.extname(file).toLowerCase();
                let plugins = [];
                
                if (ext === '.jpg' || ext === '.jpeg') {
                    plugins.push(imageminMozjpeg({ quality: 85 }));
                } else if (ext === '.png') {
                    plugins.push(imageminPngquant({ quality: [0.6, 0.8] }));
                } else if (ext === '.svg') {
                    plugins.push(imageminSvgo());
                }
                
                if (plugins.length > 0) {
                    const files = await imagemin([file], {
                        destination: outputDir,
                        plugins: plugins
                    });
                    
                    if (files.length > 0) {
                        console.log(`  ✓ ${relativePath}`);
                    }
                } else {
                    // 直接复制文件
                    fs.copyFileSync(file, outputPath);
                    console.log(`  ✓ ${relativePath}`);
                }
                
            } catch (error) {
                console.warn(`  ⚠️ 图片优化失败: ${relativePath}`, error.message);
                // 直接复制原文件
                fs.copyFileSync(file, outputPath);
            }
        }
    }
    
    async generateAssetManifest() {
        console.log('📋 生成资源清单...');
        
        const manifest = {
            version: this.config.cacheVersion,
            timestamp: new Date().toISOString(),
            assets: {},
            hashes: Object.fromEntries(this.assetHashes)
        };
        
        // 扫描所有资源文件
        const assetExtensions = ['.css', '.js', '.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp', '.woff', '.woff2', '.ttf', '.eot'];
        
        for (const ext of assetExtensions) {
            const files = this.findFiles(this.config.outputDir, ext);
            for (const file of files) {
                const relativePath = path.relative(this.config.outputDir, file);
                const stats = fs.statSync(file);
                
                manifest.assets[relativePath] = {
                    size: stats.size,
                    mtime: stats.mtime.toISOString(),
                    hash: this.assetHashes.get(relativePath) || this.generateHash(fs.readFileSync(file))
                };
            }
        }
        
        const manifestPath = path.join(this.config.outputDir, 'asset-manifest.json');
        fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));
        console.log('  ✓ asset-manifest.json');
    }
    
    async generatePWAFiles() {
        console.log('📱 生成PWA文件...');
        
        // 生成manifest.json
        const manifestPath = path.join(this.config.outputDir, 'manifest.json');
        fs.writeFileSync(manifestPath, JSON.stringify(this.manifest, null, 2));
        console.log('  ✓ manifest.json');
        
        // 生成service worker
        const swContent = this.generateServiceWorker();
        const swPath = path.join(this.config.outputDir, 'sw.js');
        fs.writeFileSync(swPath, swContent);
        console.log('  ✓ sw.js');
        
        // 生成离线页面
        const offlineContent = this.generateOfflinePage();
        const offlinePath = path.join(this.config.outputDir, 'offline.html');
        fs.writeFileSync(offlinePath, offlineContent);
        console.log('  ✓ offline.html');
    }
    
    async generateCompressedFiles() {
        console.log('🗜️ 生成压缩文件...');
        
        const compressibleExtensions = ['.html', '.css', '.js', '.json', '.xml', '.txt'];
        
        for (const ext of compressibleExtensions) {
            const files = this.findFiles(this.config.outputDir, ext);
            
            for (const file of files) {
                const content = fs.readFileSync(file);
                
                if (this.config.compression.gzip) {
                    const gzipContent = gzipSync(content, { level: this.config.compression.level });
                    fs.writeFileSync(file + '.gz', gzipContent);
                }
                
                if (this.config.compression.brotli) {
                    const brotliContent = brotliCompressSync(content, {
                        params: {
                            [require('zlib').constants.BROTLI_PARAM_QUALITY]: this.config.compression.level
                        }
                    });
                    fs.writeFileSync(file + '.br', brotliContent);
                }
            }
        }
        
        console.log('  ✓ 压缩文件生成完成');
    }
    
    async generateCDNConfig() {
        console.log('🌐 生成CDN配置...');
        
        const cdnConfig = {
            enabled: this.config.enableCDN,
            baseUrl: this.config.cdnUrl,
            assets: this.config.cdnAssets,
            version: this.config.cacheVersion,
            timestamp: new Date().toISOString()
        };
        
        const configPath = path.join(this.config.outputDir, 'cdn-config.json');
        fs.writeFileSync(configPath, JSON.stringify(cdnConfig, null, 2));
        console.log('  ✓ cdn-config.json');
    }
    
    // 工具方法
    findFiles(dir, extension) {
        const files = [];
        
        function traverse(currentDir) {
            const items = fs.readdirSync(currentDir);
            
            for (const item of items) {
                const fullPath = path.join(currentDir, item);
                const stat = fs.statSync(fullPath);
                
                if (stat.isDirectory()) {
                    traverse(fullPath);
                } else if (path.extname(item) === extension) {
                    files.push(fullPath);
                }
            }
        }
        
        traverse(dir);
        return files;
    }
    
    generateHash(content) {
        return crypto.createHash('md5').update(content).digest('hex').substring(0, 8);
    }
    
    addHashToFilename(filepath, hash) {
        const ext = path.extname(filepath);
        const basename = path.basename(filepath, ext);
        const dirname = path.dirname(filepath);
        return path.join(dirname, `${basename}.${hash}${ext}`);
    }
    
    async minifyCSS(css) {
        const result = await new CleanCSS({
            level: 2,
            returnPromise: true
        }).minify(css);
        
        return result.styles;
    }
    
    async minifyJS(js) {
        const result = await minify(js, {
            compress: {
                drop_console: true,
                drop_debugger: true,
                pure_funcs: ['console.log', 'console.info', 'console.debug']
            },
            mangle: {
                toplevel: true
            }
        });
        
        return result.code;
    }
    
    minifyHTML(html) {
        return html
            .replace(/\s+/g, ' ')
            .replace(/>\s+</g, '><')
            .replace(/\s+>/g, '>')
            .replace(/<\s+/g, '<')
            .trim();
    }
    
    addCacheBusting(content) {
        // 为CSS和JS文件添加版本号
        return content.replace(
            /(href|src)=["']([^"']*\.(css|js))["']/g,
            (match, attr, url) => {
                const hash = this.assetHashes.get(url) || this.config.cacheVersion;
                return `${attr}="${url}?v=${hash}"`;
            }
        );
    }
    
    addCDNSupport(content) {
        if (!this.config.enableCDN) return content;
        
        const cdnUrl = this.config.cdnUrl;
        const cdnAssets = this.config.cdnAssets;
        
        return content.replace(
            /(href|src)=["']([^"']*\.(css|js|png|jpg|jpeg|gif|svg|webp|woff|woff2|ttf|eot))["']/g,
            (match, attr, url) => {
                const ext = path.extname(url).substring(1);
                if (cdnAssets.includes(ext)) {
                    const fullUrl = url.startsWith('/') ? url.substring(1) : url;
                    return `${attr}="${cdnUrl}/${fullUrl}"`;
                }
                return match;
            }
        );
    }
    
    async inlineCSS(content, filePath) {
        return content.replace(
            /<link[^>]+href=["']([^"']*\.css)["'][^>]*>/g,
            async (match, cssPath) => {
                const fullPath = path.resolve(path.dirname(filePath), cssPath);
                if (fs.existsSync(fullPath)) {
                    const cssContent = fs.readFileSync(fullPath, 'utf8');
                    const minifiedCSS = await this.minifyCSS(cssContent);
                    return `<style>${minifiedCSS}</style>`;
                }
                return match;
            }
        );
    }
    
    async inlineJS(content, filePath) {
        return content.replace(
            /<script[^>]+src=["']([^"']*\.js)["'][^>]*><\/script>/g,
            async (match, jsPath) => {
                const fullPath = path.resolve(path.dirname(filePath), jsPath);
                if (fs.existsSync(fullPath)) {
                    const jsContent = fs.readFileSync(fullPath, 'utf8');
                    const minifiedJS = await this.minifyJS(jsContent);
                    return `<script>${minifiedJS}</script>`;
                }
                return match;
            }
        );
    }
    
    async inlineImages(content, filePath) {
        return content.replace(
            /<img[^>]+src=["']([^"']*\.(png|jpg|jpeg|gif|svg))["'][^>]*>/g,
            async (match, imgPath) => {
                const fullPath = path.resolve(path.dirname(filePath), imgPath);
                if (fs.existsSync(fullPath)) {
                    const stats = fs.statSync(fullPath);
                    if (stats.size <= this.config.inlineAssets.maxSize) {
                        const ext = path.extname(imgPath).substring(1);
                        const imgContent = fs.readFileSync(fullPath);
                        const base64 = imgContent.toString('base64');
                        const dataUrl = `data:image/${ext};base64,${base64}`;
                        return match.replace(imgPath, dataUrl);
                    }
                }
                return match;
            }
        );
    }
    
    generateServiceWorker() {
        return `
const CACHE_NAME = 'ipv6-wireguard-manager-v${this.config.cacheVersion}';
const urlsToCache = [
    '/',
    '/offline.html',
    '/manifest.json'
];

// 安装事件
self.addEventListener('install', event => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => cache.addAll(urlsToCache))
    );
});

// 激活事件
self.addEventListener('activate', event => {
    event.waitUntil(
        caches.keys().then(cacheNames => {
            return Promise.all(
                cacheNames.map(cacheName => {
                    if (cacheName !== CACHE_NAME) {
                        return caches.delete(cacheName);
                    }
                })
            );
        })
    );
});

// 获取事件
self.addEventListener('fetch', event => {
    event.respondWith(
        caches.match(event.request)
            .then(response => {
                if (response) {
                    return response;
                }
                return fetch(event.request).catch(() => {
                    return caches.match('/offline.html');
                });
            })
    );
});
        `.trim();
    }
    
    generateOfflinePage() {
        return `
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>离线 - IPv6 WireGuard Manager</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            text-align: center;
            color: white;
            max-width: 500px;
            padding: 2rem;
        }
        .icon {
            font-size: 4rem;
            margin-bottom: 1rem;
        }
        h1 {
            font-size: 2rem;
            margin-bottom: 1rem;
        }
        p {
            font-size: 1.1rem;
            line-height: 1.6;
            margin-bottom: 2rem;
        }
        .btn {
            display: inline-block;
            padding: 12px 24px;
            background: rgba(255, 255, 255, 0.2);
            color: white;
            text-decoration: none;
            border-radius: 6px;
            border: 1px solid rgba(255, 255, 255, 0.3);
            transition: all 0.3s ease;
        }
        .btn:hover {
            background: rgba(255, 255, 255, 0.3);
            transform: translateY(-2px);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">📡</div>
        <h1>网络连接不可用</h1>
        <p>您当前处于离线状态，无法访问IPv6 WireGuard Manager。请检查您的网络连接后重试。</p>
        <a href="/" class="btn">重新加载</a>
    </div>
</body>
</html>
        `.trim();
    }
    
    printOptimizationReport() {
        console.log('\n📊 优化报告:');
        console.log(`  📁 输出目录: ${this.config.outputDir}`);
        console.log(`  🗜️ 资源压缩: ${this.config.minifyJS ? '✓' : '✗'} JS, ${this.config.minifyCSS ? '✓' : '✗'} CSS, ${this.config.minifyHTML ? '✓' : '✗'} HTML`);
        console.log(`  🖼️ 图片优化: ${this.config.optimizeImages ? '✓' : '✗'}`);
        console.log(`  🌐 CDN支持: ${this.config.enableCDN ? '✓' : '✗'}`);
        console.log(`  📱 PWA功能: ${this.config.enablePWA ? '✓' : '✗'}`);
        console.log(`  🗜️ 压缩文件: ${this.config.compression.gzip ? '✓' : '✗'} Gzip, ${this.config.compression.brotli ? '✓' : '✗'} Brotli`);
        console.log(`  📋 资源清单: ✓ asset-manifest.json`);
        console.log(`  🔢 资源版本: ${this.assetHashes.size} 个文件`);
    }
}

// 如果直接运行此脚本
if (require.main === module) {
    const config = {
        inputDir: './php-frontend',
        outputDir: './dist',
        enableCDN: true,
        cdnUrl: 'https://cdn.example.com',
        enablePWA: true,
        minifyJS: true,
        minifyCSS: true,
        minifyHTML: true,
        optimizeImages: true,
        compression: {
            gzip: true,
            brotli: true
        }
    };
    
    const optimizer = new FrontendOptimizer(config);
    optimizer.optimize().catch(console.error);
}

module.exports = FrontendOptimizer;
