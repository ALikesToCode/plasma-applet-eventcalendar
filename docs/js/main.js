/**
 * Event Calendar OAuth Helper Logic
 */
(function () {
    'use strict';

    // Configuration
    const CONSTANTS = {
        localEndpoint: "http://127.0.0.1:53682/",
        statusWait: "Waiting for input.",
        statusExtracted: "Code extracted. Copy it into the widget or send it automatically.",
        statusSending: "Sending code to the widget...",
        statusSent: "Sent to widget. You can return to the settings window.",
        statusError: "Could not reach the widget. Copy the code manually.",
        statusNoCode: "No code to send yet.",
        statusNoCopy: "No code to copy yet.",
        statusCopied: "Copied. Paste into the widget."
    };

    // Elements
    const elements = {
        urlInput: document.getElementById("redirectUrl"),
        codeOutput: document.getElementById("authCode"),
        status: document.getElementById("status"),
        extractBtn: document.getElementById("extractBtn"),
        copyBtn: document.getElementById("copyBtn"),
        clearBtn: document.getElementById("clearBtn"),
        sendBtn: document.getElementById("sendBtn")
    };

    // Utility to safely get elements (in case script runs on a page without them)
    if (!elements.urlInput || !elements.codeOutput) {
        // We might be on a page that doesn't use this script (like privacy.html), 
        // but this file is intended for index.html. 
        // If we want to be safe, we can check.
        return;
    }

    function extractCode(value) {
        if (!value) return "";

        const trimmed = value.trim();

        // Try regex match for ?code=... or &code=...
        const match = /[?&]code=([^&]+)/.exec(trimmed);
        if (match && match[1]) {
            return decodeURIComponent(match[1].replace(/\+/g, " "));
        }

        // Try URL parsing
        try {
            const parsed = new URL(trimmed);
            const code = parsed.searchParams.get("code");
            if (code) return code;
        } catch (err) {
            // Not a valid URL, treat entire string as potential code if it looks like one?
            // For now, fall back to returning trimmed value as the original script did.
        }

        return trimmed;
    }

    function updateFromInput() {
        const code = extractCode(elements.urlInput.value);
        elements.codeOutput.value = code;

        if (code) {
            elements.status.innerHTML = CONSTANTS.statusExtracted;
            if (elements.sendBtn) elements.sendBtn.disabled = false;
            if (elements.copyBtn) elements.copyBtn.disabled = false;
        } else {
            elements.status.textContent = CONSTANTS.statusWait;
        }
    }

    async function sendToWidget(code) {
        if (!code) {
            elements.status.textContent = CONSTANTS.statusNoCode;
            return;
        }

        elements.status.textContent = CONSTANTS.statusSending;

        try {
            const response = await fetch(CONSTANTS.localEndpoint, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ code }),
                mode: "cors",
            });

            if (!response.ok) throw new Error("Local listener returned error");

            elements.status.textContent = CONSTANTS.statusSent;

            // Add visual feedback
            if (elements.sendBtn) {
                const originalText = elements.sendBtn.innerText;
                elements.sendBtn.innerText = "Sent!";
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
                elements.status.textContent = "Failed to copy.";
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
            elements.status.textContent = CONSTANTS.statusWait;
        });
    }

    if (elements.copyBtn) elements.copyBtn.addEventListener("click", copyToClipboard);

    if (elements.sendBtn) {
        elements.sendBtn.addEventListener("click", () => {
            sendToWidget(elements.codeOutput.value);
        });
    }

    // Init from URL params (OAuth callback flow)
    function initFromPage() {
        const params = new URLSearchParams(window.location.search);
        const code = params.get("code");
        if (code) {
            // Start flow automatically
            elements.urlInput.value = window.location.href;
            updateFromInput();
            sendToWidget(code);
        }
    }

    initFromPage();

})();
