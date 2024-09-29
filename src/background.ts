chrome.runtime.onInstalled.addListener(() => {
  chrome.storage.sync.get(['proxyType', 'proxyHost', 'proxyPort', 'proxyEnabled'], (items) => {
    if (items.proxyHost && items.proxyPort && items.proxyEnabled) {
      setProxy(items.proxyType, items.proxyHost, parseInt(items.proxyPort));
    } else {
      clearProxy()
    }
  });
});

function setProxy(proxyType: string, proxyHost: string, proxyPort: number): void {
  const config: chrome.types.ChromeSettingSetDetails = {
    value: {
      mode: 'fixed_servers',
      rules: {
        singleProxy: {
          scheme: proxyType,
          host: proxyHost,
          port: proxyPort
        },
        bypassList: ['<local>']
      }
    },
    scope: 'regular'
  };

  chrome.proxy.settings.set(config, () => {
    console.log('Proxy settings applied.');
  });
}

function clearProxy(): void {
  chrome.proxy.settings.clear({ scope: 'regular' }, () => {
    console.log('Proxy settings cleared.');
  });
}

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === 'setProxy') {
    setProxy(message.proxyType, message.proxyHost, parseInt(message.proxyPort));
    sendResponse({ status: 'Proxy settings applied.' });
  } else if (message.action === 'clearProxy') {
    clearProxy();
    sendResponse({ status: 'Proxy settings cleared.' });
  }
});
