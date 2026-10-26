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

  const quote = document.querySelector('[data-quote]');
  if (quote) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 4000);
    fetch('https://korean-advice-open-api.vercel.app/api/advice', { signal: controller.signal })
      .then((response) => (response.ok ? response.json() : Promise.reject(new Error(String(response.status)))))
      .then(({ message, author }) => {
        if (typeof message !== 'string' || !message.trim()) return;
        quote.querySelector('.hero__quote-text').textContent = message.trim();
        const source = quote.querySelector('.hero__quote-source');
        if (typeof author === 'string' && author.trim()) {
          source.querySelector('cite').textContent = author.trim();
        } else {
          source.remove();
        }
        quote.hidden = false;
      })
      .catch(() => {})
      .finally(() => clearTimeout(timer));
  }
})();
