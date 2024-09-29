#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define the project name
PROJECT_NAME="open-proxy-browser-ext"


# Initialize a new Yarn project
yarn init -y

# Install dependencies
yarn add react react-dom

# Install development dependencies
yarn add -D typescript webpack webpack-cli ts-loader css-loader style-loader @types/react @types/react-dom @types/chrome copy-webpack-plugin html-webpack-plugin

# Create tsconfig.json
cat <<EOL > tsconfig.json
{
  "compilerOptions": {
    "target": "ES6",
    "lib": ["ES6", "DOM"],
    "module": "ESNext",
    "moduleResolution": "node",
    "strict": true,
    "jsx": "react",
    "outDir": "dist",
    "sourceMap": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src"]
}
EOL

# Create webpack.config.js
cat <<EOL > webpack.config.js
const path = require('path');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = {
  entry: {
    background: './src/background.ts',
    options: './src/options/index.tsx'
  },
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: '[name].js' // Generates background.js and options.js
  },
  module: {
    rules: [
      {
        test: /\\.tsx?$/,
        use: 'ts-loader',
        exclude: /node_modules/
      },
      {
        test: /\\.css$/,
        use: ['style-loader', 'css-loader']
      },
      {
        test: /\\.(png|jpg|gif|woff|woff2|eot|ttf|svg)$/,
        type: 'asset/resource',
        generator: {
          filename: 'assets/[name][ext]'
        }
      }
    ]
  },
  resolve: {
    extensions: ['.tsx', '.ts', '.js']
  },
  plugins: [
    new CopyWebpackPlugin({
      patterns: [
        { from: 'src/manifest.json', to: '.' },
        { from: 'src/assets', to: 'assets' }
      ]
    }),
    new HtmlWebpackPlugin({
      template: 'src/options/index.html',
      filename: 'options/index.html',
      chunks: ['options']
    })
  ]
};
EOL

# Update package.json scripts
cat <<EOL > package.json
{
  "name": "$PROJECT_NAME",
  "version": "1.0.0",
  "description": "Sets HTTP or SOCKS5 proxy globally for the browser.",
  "scripts": {
    "build": "webpack --mode production",
    "start": "webpack --watch"
  },
  "author": "",
  "license": "MIT",
  "dependencies": {
    "react": "^17.0.0",
    "react-dom": "^17.0.0"
  },
  "devDependencies": {
    "@types/chrome": "^0.0.145",
    "@types/react": "^17.0.0",
    "@types/react-dom": "^17.0.0",
    "copy-webpack-plugin": "^11.0.0",
    "css-loader": "^6.0.0",
    "html-webpack-plugin": "^5.3.2",
    "style-loader": "^3.0.0",
    "ts-loader": "^9.0.0",
    "typescript": "^4.0.0",
    "webpack": "^5.0.0",
    "webpack-cli": "^4.0.0"
  }
}
EOL

# Create directory structure
mkdir -p src/options
mkdir -p src/assets

# Create src/manifest.json
cat <<EOL > src/manifest.json
{
  "manifest_version": 3,
  "name": "Open Proxy Browser Ext",
  "version": "1.0",
  "description": "Sets HTTP or SOCKS5 proxy globally for the browser.",
  "permissions": ["proxy", "storage"],
  "icons": {
    "16": "assets/icon16.png",
    "48": "assets/icon48.png",
    "128": "assets/icon128.png"
  },
  "action": {
    "default_title": "Open Proxy Browser Ext",
    "default_popup": "options/index.html"
  },
  "background": {
    "service_worker": "background.js"
  },
  "options_ui": {
    "page": "options/index.html",
    "open_in_tab": true
  }
}
EOL

# Create src/background.ts
cat <<EOL > src/background.ts
chrome.runtime.onInstalled.addListener(() => {
  chrome.storage.sync.get(['proxyType', 'proxyHost', 'proxyPort'], (items) => {
    if (items.proxyHost && items.proxyPort) {
      setProxy(items.proxyType, items.proxyHost, parseInt(items.proxyPort));
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
EOL

# Create src/options/index.tsx
cat <<EOL > src/options/index.tsx
import React, { useState, useEffect } from 'react';
import ReactDOM from 'react-dom';
import './styles.css';

const OptionsApp: React.FC = () => {
  const [proxyType, setProxyType] = useState<string>('http');
  const [proxyHost, setProxyHost] = useState<string>('');
  const [proxyPort, setProxyPort] = useState<string>('');

  useEffect(() => {
    chrome.storage.sync.get(['proxyType', 'proxyHost', 'proxyPort'], (items) => {
      setProxyType(items.proxyType || 'http');
      setProxyHost(items.proxyHost || '');
      setProxyPort(items.proxyPort || '');
    });
  }, []);

  const saveSettings = (): void => {
    chrome.storage.sync.set(
      {
        proxyType,
        proxyHost,
        proxyPort
      },
      () => {
        chrome.runtime.sendMessage(
          {
            action: 'setProxy',
            proxyType,
            proxyHost,
            proxyPort
          },
          (response) => {
            alert(response.status);
          }
        );
      }
    );
  };

  const clearSettings = (): void => {
    chrome.storage.sync.remove(['proxyType', 'proxyHost', 'proxyPort'], () => {
      chrome.runtime.sendMessage({ action: 'clearProxy' }, (response) => {
        setProxyType('http');
        setProxyHost('');
        setProxyPort('');
        alert(response.status);
      });
    });
  };

  return (
    <div className="container">
      <h1>Proxy Settings</h1>
      <div className="form-group">
        <label htmlFor="proxyType">Proxy Type:</label>
        <select
          id="proxyType"
          value={proxyType}
          onChange={(e) => setProxyType(e.target.value)}
        >
          <option value="http">HTTP</option>
          <option value="socks5">SOCKS5</option>
        </select>
      </div>
      <div className="form-group">
        <label htmlFor="proxyHost">Proxy Host:</label>
        <input
          type="text"
          id="proxyHost"
          value={proxyHost}
          onChange={(e) => setProxyHost(e.target.value)}
        />
      </div>
      <div className="form-group">
        <label htmlFor="proxyPort">Proxy Port:</label>
        <input
          type="number"
          id="proxyPort"
          value={proxyPort}
          onChange={(e) => setProxyPort(e.target.value)}
        />
      </div>
      <div className="button-group">
        <button onClick={saveSettings}>Save</button>
        <button onClick={clearSettings}>Clear Proxy</button>
      </div>
    </div>
  );
};

ReactDOM.render(<OptionsApp />, document.getElementById('root'));
EOL

# Create src/options/index.html
cat <<EOL > src/options/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Proxy Settings</title>
</head>
<body>
  <div id="root"></div>
</body>
</html>
EOL

# Create src/options/styles.css
cat <<EOL > src/options/styles.css
body {
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  background-color: #f5f5f5;
  margin: 0;
  padding: 0;
}

.container {
  max-width: 400px;
  margin: 50px auto;
  background: #fff;
  padding: 30px;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

h1 {
  margin-bottom: 20px;
  text-align: center;
  color: #333;
}

.form-group {
  margin-bottom: 15px;
}

label {
  display: block;
  font-weight: 600;
  margin-bottom: 5px;
  color: #555;
}

input[type='text'],
input[type='number'],
select {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  box-sizing: border-box;
  font-size: 14px;
}

input[type='text']:focus,
input[type='number']:focus,
select:focus {
  border-color: #007bff;
  outline: none;
}

.button-group {
  display: flex;
  justify-content: space-between;
}

button {
  width: 48%;
  padding: 10px;
  font-size: 16px;
  background-color: #007bff;
  color: #fff;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

button:last-child {
  background-color: #dc3545;
}

button:hover {
  opacity: 0.9;
}
EOL

# Create placeholder icons in src/assets
echo "Creating placeholder icons..."
mkdir -p src/assets

# Generate placeholder icons (solid color images)
# This step requires ImageMagick to be installed
if command -v convert &> /dev/null
then
    convert -size 16x16 xc:#007bff src/assets/icon16.png
    convert -size 48x48 xc:#007bff src/assets/icon48.png
    convert -size 128x128 xc:#007bff src/assets/icon128.png
else
    echo "ImageMagick 'convert' command not found. Please install ImageMagick or add your own icons to 'src/assets/'."
fi

echo "Project setup complete. To build the project, run 'yarn build'."

