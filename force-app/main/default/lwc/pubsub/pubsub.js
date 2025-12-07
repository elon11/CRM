/**
 * @Description: Simple pub/sub module for communication between sibling LWC components.
 * @Created by: Elon Ifrach
 * @Created Date: 2025-12-06
 */

const events = {};
const componentEventMap = new WeakMap();

/**
 * Registers a callback for a given event name.
 */
const registerListener = (eventName, callback, thisArg) => {
    if (!events[eventName]) {
        events[eventName] = [];
    }

    const boundCallback = callback.bind(thisArg);

    events[eventName].push({
        callback: boundCallback,
        component: thisArg
    });

    if (!componentEventMap.has(thisArg)) {
        componentEventMap.set(thisArg, []);
    }
    componentEventMap.get(thisArg).push({
        eventName,
        callback: boundCallback
    });
};

/**
 * Unregisters a callback from a given component
 */
const unregisterListener = (eventName, callback, thisArg) => {
    if (!events[eventName]) return;

    events[eventName] = events[eventName].filter(
        listener => listener.component !== thisArg
    );
};

/**
 * Fires an event
 */
const fireEvent = (eventName, payload) => {
    if (events[eventName]) {
        events[eventName].forEach(listener => {
            try {
                listener.callback(payload);
            } catch (e) {
                console.error("Error firing event:", e);
            }
        });
    }
};

export { registerListener, unregisterListener, fireEvent };
