import React, { useState, useEffect, useCallback, useRef } from "react";
import ReactDOM from "react-dom";
import "./styles.css";

const OptionsApp: React.FC = () => {
  const [proxyType, setProxyType] = useState<string>("http");
  const [proxyHost, setProxyHost] = useState<string>("");
  const [proxyPort, setProxyPort] = useState<string>("");
  const [proxyEnabled, setProxyEnabled] = useState<boolean>(false);
  const [buttonsEnabled, setButtonsEnabled] = useState<boolean>(false);
  const [showLoader, setShowLoader] = useState<boolean>(false);

  useEffect(() => {
    chrome.storage.sync.get(
      ["proxyType", "proxyHost", "proxyPort", "proxyEnabled"],
      (items) => {
        setProxyType(items.proxyType || "http");
        setProxyHost(items.proxyHost || "");
        setProxyPort(items.proxyPort || "");
        setProxyEnabled(items.proxyEnabled || false);
        setButtonsEnabled(false);
      }
    );
  }, []);

  useEffect(() => {
    setButtonsEnabled(true);
  }, [proxyHost, proxyPort, proxyType]);

  const swictchProxyHandler = useCallback(
    (enable: boolean) => {
      setShowLoader(true);
      try {
        chrome.storage.sync.set(
          {
            proxyEnabled: enable,
          },
          () => {
            if (enable) {
              chrome.runtime.sendMessage(
                {
                  action: "setProxy",
                  proxyType,
                  proxyHost,
                  proxyPort,
                },
                (response) => {
                  alert(response.status);
                  setProxyEnabled(enable);
                  setShowLoader(false);
                }
              );
            } else {
              chrome.runtime.sendMessage(
                { action: "clearProxy" },
                (response) => {
                  alert(response.status);
                  setProxyEnabled(enable);
                  setShowLoader(false);
                }
              );
            }
          }
        );
      } catch (error) {
        setShowLoader(false);
        throw error;
      }
    },
    [proxyEnabled, proxyType, proxyHost, proxyPort]
  );

  const saveSettings = (): void => {
    chrome.storage.sync.set(
      {
        proxyType,
        proxyHost,
        proxyPort,
      },
      () => {
        setButtonsEnabled(false);
        if (proxyEnabled) {
          swictchProxyHandler(true);
        }
      }
    );
  };

  const clearSettings = (): void => {
    chrome.storage.sync.remove(["proxyType", "proxyHost", "proxyPort"], () => {
      setProxyType("http");
      setProxyHost("");
      setProxyPort("");
      alert("Cleared");
    });
  };

  return (
    <div className="container">
      <div className="header">
        <h1>Proxy Settings</h1>
        {showLoader ? (
          <div className="loader"></div>
        ) : (
          <label className="switch">
            <input
              checked={proxyEnabled}
              onChange={(e) => swictchProxyHandler(e.target.checked)}
              type="checkbox"
            />
            <span className="slider round"></span>
          </label>
        )}
      </div>
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
        <button disabled={!buttonsEnabled} onClick={saveSettings}>
          Save
        </button>
      </div>
    </div>
  );
};

ReactDOM.render(<OptionsApp />, document.getElementById("root"));
