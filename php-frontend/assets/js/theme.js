/**
 * 主题切换系统
 * 支持明暗模式切换和系统主题跟随
 */

class ThemeManager {
    constructor() {
        this.themeKey = "ipv6wgm_theme";
        this.currentTheme = this.getStoredTheme() || this.getSystemTheme();
        this.init();
    }
    
    /**
     * 初始化主题系统
     */
    init() {
        this.applyTheme(this.currentTheme);
        this.createThemeToggle();
        this.setupSystemThemeListener();
        this.addPageTransition();
    }
    
    /**
     * 获取存储的主题
     */
    getStoredTheme() {
        try {
            return localStorage.getItem(this.themeKey);
        } catch (e) {
            console.warn('无法访问localStorage:', e);
            return null;
        }
    }
    
    /**
     * 获取系统主题
     */
    getSystemTheme() {
        if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
            return 'dark';
        }
        return 'light';
    }
    
    /**
     * 存储主题设置
     */
    storeTheme(theme) {
        try {
            localStorage.setItem(this.themeKey, theme);
        } catch (e) {
            console.warn('无法存储主题设置:', e);
        }
    }
    
    /**
     * 应用主题
     */
    applyTheme(theme) {
        document.documentElement.setAttribute('data-theme', theme);
        this.currentTheme = theme;
        this.storeTheme(theme);
        
        // 更新主题切换按钮图标
        this.updateThemeToggleIcon(theme);
        
        // 触发主题变更事件
        this.dispatchThemeChangeEvent(theme);
    }
    
    /**
     * 切换主题
     */
    toggleTheme() {
        const newTheme = this.currentTheme === 'light' ? 'dark' : 'light';
        this.applyTheme(newTheme);
        
        // 添加切换动画
        this.addThemeTransition();
    }
    
    /**
     * 创建主题切换按钮
     */
    createThemeToggle() {
        // 检查是否已存在按钮
        if (document.querySelector('.theme-toggle')) {
            return;
        }
        
        const toggle = document.createElement('button');
        toggle.className = 'theme-toggle';
        toggle.setAttribute('aria-label', '切换主题');
        toggle.setAttribute('title', '切换主题');
        
        const icon = document.createElement('i');
        icon.className = this.getThemeIcon(this.currentTheme);
        toggle.appendChild(icon);
        
        toggle.addEventListener('click', () => {
            this.toggleTheme();
        });
        
        document.body.appendChild(toggle);
    }
    
    /**
     * 检查Bootstrap Icons依赖
     */
    checkBootstrapIcons() {
        if (!document.querySelector('link[href*="bootstrap-icons"]') && 
            !document.querySelector('link[href*="bootstrap-icons.css"]')) {
            console.warn('Bootstrap Icons未加载，主题图标可能无法正确显示');
            return false;
        }
        return true;
    }
    
    /**
     * 获取主题图标
     */
    getThemeIcon(theme) {
        // 检查Bootstrap Icons是否可用
        if (!this.checkBootstrapIcons()) {
            // 回退到Unicode图标
            return theme === 'light' ? '🌙' : '☀️';
        }
        return theme === 'light' ? 'bi bi-moon-fill' : 'bi bi-sun-fill';
    }
    
    /**
     * 更新主题切换按钮图标
     */
    updateThemeToggleIcon(theme) {
        const toggle = document.querySelector('.theme-toggle i');
        if (toggle) {
            const icon = this.getThemeIcon(theme);
            if (icon.includes('bi ')) {
                // Bootstrap Icons 可用，设置类名
                toggle.className = icon;
            } else {
                // 回退到字符图标，设置文本内容
                toggle.textContent = icon;
                toggle.className = '';
            }
        }
    }
    
    /**
     * 设置系统主题监听器
     */
    setupSystemThemeListener() {
        if (window.matchMedia) {
            const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
            mediaQuery.addEventListener('change', (e) => {
                // 只有在用户没有手动设置主题时才跟随系统
                if (!this.getStoredTheme()) {
                    const systemTheme = e.matches ? 'dark' : 'light';
                    this.applyTheme(systemTheme);
                }
            });
        }
    }
    
    /**
     * 添加主题切换动画
     */
    addThemeTransition() {
        document.body.style.transition = 'background-color 0.3s ease, color 0.3s ease';
        
        setTimeout(() => {
            document.body.style.transition = '';
        }, 300);
    }
    
    /**
     * 添加页面切换动画
     */
    addPageTransition() {
        document.body.classList.add('page-transition');
        
        window.addEventListener('load', () => {
            setTimeout(() => {
                document.body.classList.add('loaded');
            }, 100);
        });
    }
    
    /**
     * 触发主题变更事件
     */
    dispatchThemeChangeEvent(theme) {
        const event = new CustomEvent('themechange', {
            detail: { theme: theme }
        });
        document.dispatchEvent(event);
    }
    
    /**
     * 获取当前主题
     */
    getCurrentTheme() {
        return this.currentTheme;
    }
    
    /**
     * 设置主题
     */
    setTheme(theme) {
        if (['light', 'dark'].includes(theme)) {
            this.applyTheme(theme);
        }
    }
    
    /**
     * 重置为系统主题
     */
    resetToSystemTheme() {
        try {
            localStorage.removeItem(this.themeKey);
        } catch (e) {
            console.warn('无法清除主题设置:', e);
        }
        
        const systemTheme = this.getSystemTheme();
        this.applyTheme(systemTheme);
    }
}

/**
 * 动画增强类
 */
class AnimationEnhancer {
    constructor() {
        this.init();
    }
    
    /**
     * 初始化动画增强
     */
    init() {
        this.addRippleEffect();
        this.addHoverEffects();
        this.addLoadingStates();
        this.addScrollAnimations();
    }
    
    /**
     * 添加涟漪效果
     */
    addRippleEffect() {
        document.addEventListener('click', (e) => {
            const button = e.target.closest('.btn, .card, .list-group-item');
            if (button && button.classList && !button.classList.contains('no-ripple')) {
                this.createRipple(e, button);
            }
        });
    }
    
    /**
     * 创建涟漪效果
     */
    createRipple(event, element) {
        const ripple = document.createElement('span');
        const rect = element.getBoundingClientRect();
        const size = Math.max(rect.width, rect.height);
        const x = event.clientX - rect.left - size / 2;
        const y = event.clientY - rect.top - size / 2;
        
        ripple.style.width = ripple.style.height = size + 'px';
        ripple.style.left = x + 'px';
        ripple.style.top = y + 'px';
        ripple.classList.add('ripple');
        
        element.style.position = 'relative';
        element.style.overflow = 'hidden';
        element.appendChild(ripple);
        
        setTimeout(() => {
            ripple.remove();
        }, 600);
    }
    
    /**
     * 添加悬停效果
     */
    addHoverEffects() {
        // 卡片悬停效果
        document.addEventListener('mouseenter', (e) => {
            if (e.target && e.target.classList && e.target.classList.contains('card')) {
                e.target.style.transform = 'translateY(-2px)';
            }
        }, true);
        
        document.addEventListener('mouseleave', (e) => {
            if (e.target && e.target.classList && e.target.classList.contains('card')) {
                e.target.style.transform = 'translateY(0)';
            }
        }, true);
    }
    
    /**
     * 添加加载状态
     */
    addLoadingStates() {
        // 表单提交加载状态
        document.addEventListener('submit', (e) => {
            const form = e.target;
            const submitBtn = form.querySelector('button[type="submit"]');
            
            if (submitBtn) {
                const originalText = submitBtn.innerHTML;
                submitBtn.innerHTML = '<span class="loading-spinner"></span> 处理中...';
                submitBtn.disabled = true;
                
                // 5秒后恢复（防止无限加载）
                setTimeout(() => {
                    submitBtn.innerHTML = originalText;
                    submitBtn.disabled = false;
                }, 5000);
            }
        });
    }
    
    /**
     * 添加滚动动画
     */
    addScrollAnimations() {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('animate-in');
                }
            });
        }, {
            threshold: 0.1
        });
        
        // 观察所有卡片和统计项
        document.querySelectorAll('.card, .stat-card, .feature-item').forEach(el => {
            observer.observe(el);
        });
    }
}

/**
 * 响应式增强类
 */
class ResponsiveEnhancer {
    constructor() {
        this.init();
    }
    
    /**
     * 初始化响应式增强
     */
    init() {
        this.setupTouchOptimizations();
        this.setupViewportHandling();
        this.setupOrientationChange();
    }
    
    /**
     * 设置触摸优化
     */
    setupTouchOptimizations() {
        // 增加触摸目标大小
        if ('ontouchstart' in window) {
            document.body.classList.add('touch-device');
            
            // 为小屏幕设备优化按钮大小
            const buttons = document.querySelectorAll('.btn');
            buttons.forEach(btn => {
                if (btn.offsetHeight < 44) {
                    btn.style.minHeight = '44px';
                    btn.style.minWidth = '44px';
                }
            });
        }
    }
    
    /**
     * 设置视口处理
     */
    setupViewportHandling() {
        // 动态调整视口高度
        const setViewportHeight = () => {
            const vh = window.innerHeight * 0.01;
            document.documentElement.style.setProperty('--vh', `${vh}px`);
        };
        
        setViewportHeight();
        window.addEventListener('resize', setViewportHeight);
        window.addEventListener('orientationchange', setViewportHeight);
    }
    
    /**
     * 设置方向变化处理
     */
    setupOrientationChange() {
        window.addEventListener('orientationchange', () => {
            setTimeout(() => {
                // 重新计算布局
                window.dispatchEvent(new Event('resize'));
            }, 100);
        });
    }
}

// 添加涟漪效果样式
const rippleStyle = document.createElement('style');
rippleStyle.textContent = `
    .ripple {
        position: absolute;
        border-radius: 50%;
        background-color: rgba(255, 255, 255, 0.3);
        transform: scale(0);
        animation: ripple-animation 0.6s linear;
        pointer-events: none;
    }
    
    @keyframes ripple-animation {
        to {
            transform: scale(4);
            opacity: 0;
        }
    }
    
    .animate-in {
        animation: slideInUp 0.6s ease-out;
    }
    
    @keyframes slideInUp {
        from {
            opacity: 0;
            transform: translateY(30px);
        }
        to {
            opacity: 1;
            transform: translateY(0);
        }
    }
    
    .touch-device .btn {
        min-height: 44px;
        min-width: 44px;
    }
    
    .touch-device .form-control {
        min-height: 44px;
    }
`;
document.head.appendChild(rippleStyle);

// 初始化所有增强功能
document.addEventListener('DOMContentLoaded', () => {
    window.themeManager = new ThemeManager();
    window.animationEnhancer = new AnimationEnhancer();
    window.responsiveEnhancer = new ResponsiveEnhancer();
});

// 导出供其他脚本使用
window.ThemeManager = ThemeManager;
window.AnimationEnhancer = AnimationEnhancer;
window.ResponsiveEnhancer = ResponsiveEnhancer;
