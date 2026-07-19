.pragma library

function findBridge(item) {
    var current = item;
    while (current) {
        if (current.configBridge) {
            return current.configBridge;
        }
        current = current.parent;
    }
    return null;
}
