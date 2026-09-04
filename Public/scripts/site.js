(() => {
  const root = document.documentElement;
  const button = document.querySelector('[data-theme-toggle]');
  const preferred = () => window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  const current = () => root.dataset.theme || preferred();

  const syncGiscus = (theme) => {
    document.querySelectorAll('iframe.giscus-frame').forEach((frame) => {
      frame.contentWindow?.postMessage({ giscus: { setConfig: { theme } } }, 'https://giscus.app');
    });
  };

  const setTheme = (theme) => {
    root.dataset.theme = theme;
    try { localStorage.setItem('theme', theme); } catch (_) {}
    if (button) button.setAttribute('aria-label', `${theme === 'dark' ? '밝은' : '어두운'} 색상 모드로 전환`);
    syncGiscus(theme === 'dark' ? 'dark' : 'light');
  };

  if (button) {
    button.addEventListener('click', () => setTheme(current() === 'dark' ? 'light' : 'dark'));
    button.setAttribute('aria-label', `${current() === 'dark' ? '밝은' : '어두운'} 색상 모드로 전환`);
  }

  if (document.querySelector('script[src="https://giscus.app/client.js"]')) {
    const observer = new MutationObserver(() => {
      if (document.querySelector('iframe.giscus-frame')) {
        syncGiscus(current() === 'dark' ? 'dark' : 'light');
        observer.disconnect();
      }
    });
    observer.observe(document.body, { childList: true, subtree: true });
    syncGiscus(current() === 'dark' ? 'dark' : 'light');
  }
})();
