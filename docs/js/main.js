/**
 * Event Calendar OAuth Helper Logic
 */
(function () {
    'use strict';

    // Configuration
    const CONSTANTS = {
        localEndpoint: "http://127.0.0.1:53682/",
        statusWait: "Paste the address to get the code.",
        statusExtracted: "Code found. Send it to the widget, or copy it into the widget's settings.",
        statusSending: "Sending the code to the widget...",
        statusSent: "Sent. Go back to the widget's settings.",
        statusError: "The widget isn't listening. Copy the code and paste it into the widget's settings.",
        statusNoCode: "There's no code to send yet. Paste the address first.",
        statusNoCopy: "There's no code to copy yet. Paste the address first.",
        statusCopied: "Copied. Paste it into the widget's settings."
    };

    // Elements
    const elements = {
        urlInput: document.getElementById("redirectUrl"),
        codeOutput: document.getElementById("authCode"),
        status: document.getElementById("status"),
        extractBtn: document.getElementById("extractBtn"),
        copyBtn: document.getElementById("copyBtn"),
        clearBtn: document.getElementById("clearBtn"),
        sendBtn: document.getElementById("sendBtn"),
        helper: document.getElementById("oauth-helper")
    };

    // Utility to safely get elements (in case script runs on a page without them)
    if (!elements.urlInput || !elements.codeOutput) {
        // We might be on a page that doesn't use this script (like privacy.html), 
        // but this file is intended for index.html. 
        // If we want to be safe, we can check.
        return;
    }

    function extractParam(value, name) {
        if (!value) return "";

        const trimmed = value.trim();

        const matcher = new RegExp("[?&]" + name + "=([^&]+)");
        const match = matcher.exec(trimmed);
        if (match && match[1]) {
            return decodeURIComponent(match[1].replace(/\+/g, " "));
        }

        // Try URL parsing
        try {
            const parsed = new URL(trimmed);
            const param = parsed.searchParams.get(name);
            if (param) return param;
        } catch (err) {
            // Not a valid URL, fall back to returning the raw input only for the code field.
        }

        return name === "code" ? trimmed : "";
    }

    function updateFromInput() {
        const code = extractParam(elements.urlInput.value, "code");
        const state = extractParam(elements.urlInput.value, "state");
        elements.codeOutput.value = code;
        elements.codeOutput.dataset.state = state;

        if (code) {
            elements.status.textContent = CONSTANTS.statusExtracted;
            if (elements.sendBtn) elements.sendBtn.disabled = false;
            if (elements.copyBtn) elements.copyBtn.disabled = false;
        } else {
            elements.status.textContent = CONSTANTS.statusWait;
        }
    }

    async function sendToWidget(code, state) {
        if (!code) {
            elements.status.textContent = CONSTANTS.statusNoCode;
            return;
        }

        elements.status.textContent = CONSTANTS.statusSending;

        try {
            const response = await fetch(CONSTANTS.localEndpoint, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ code, state }),
                mode: "cors",
            });

            if (!response.ok) throw new Error("Local listener returned error");

            elements.status.textContent = CONSTANTS.statusSent;

            // Add visual feedback
            if (elements.sendBtn) {
                const originalText = elements.sendBtn.innerText;
                elements.sendBtn.innerText = "Sent";
                setTimeout(() => elements.sendBtn.innerText = originalText, 2000);
            }

        } catch (err) {
            console.warn("Widget connection failed:", err);
            elements.status.textContent = CONSTANTS.statusError;
        }
    }

    async function copyToClipboard() {
        if (!elements.codeOutput.value) {
            elements.status.textContent = CONSTANTS.statusNoCopy;
            return;
        }

        try {
            await navigator.clipboard.writeText(elements.codeOutput.value);
            elements.status.textContent = CONSTANTS.statusCopied;
        } catch (err) {
            // Fallback
            try {
                elements.codeOutput.select();
                document.execCommand("copy");
                elements.status.textContent = CONSTANTS.statusCopied;
            } catch (e) {
                elements.status.textContent = "Couldn't copy. Select the code and press Ctrl+C.";
            }
        }
    }

    // Event Listeners
    if (elements.extractBtn) elements.extractBtn.addEventListener("click", updateFromInput);
    if (elements.urlInput) elements.urlInput.addEventListener("input", updateFromInput);

    if (elements.clearBtn) {
        elements.clearBtn.addEventListener("click", () => {
            elements.urlInput.value = "";
            elements.codeOutput.value = "";
            elements.codeOutput.dataset.state = "";
            elements.status.textContent = CONSTANTS.statusWait;
        });
    }

    if (elements.copyBtn) elements.copyBtn.addEventListener("click", copyToClipboard);

    if (elements.sendBtn) {
        elements.sendBtn.addEventListener("click", () => {
            sendToWidget(elements.codeOutput.value, elements.codeOutput.dataset.state || "");
        });
    }

    // Init from URL params (OAuth callback flow)
    function initFromPage() {
        const params = new URLSearchParams(window.location.search);
        const code = params.get("code");
        const state = params.get("state") || "";
        if (code) {
            // Google sent the browser here with a sign-in code: show the
            // helper and pass the code to the widget straight away.
            if (elements.helper) {
                elements.helper.open = true;
                elements.helper.scrollIntoView({ block: "start" });
            }
            elements.urlInput.value = window.location.href;
            updateFromInput();
            sendToWidget(code, state);
        }
    }

    initFromPage();

})();
